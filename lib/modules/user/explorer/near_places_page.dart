import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:muar_tourism_guide/theme/app_theme.dart';
import 'package:muar_tourism_guide/modules/user/explorer/place_detail_page.dart';
import 'package:muar_tourism_guide/utils/env.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NearPlacesPage extends StatefulWidget {
  const NearPlacesPage({super.key});

  @override
  State<NearPlacesPage> createState() => _NearPlacesPageState();
}

class _NearPlacesPageState extends State<NearPlacesPage> {
  static String get _googleApiKey => Env.googleApiKey;

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  // Default to Muar location if permission denied or waiting
  static const CameraPosition _muarCamera = CameraPosition(
    target: LatLng(2.0461, 102.5694),
    zoom: 14.0,
    tilt: 0,
    bearing: 0,
  );

  // Define Muar Bounds (Tighter to focus on Muar District)
  final LatLngBounds _muarBounds = LatLngBounds(
    southwest: const LatLng(1.98, 102.45),
    northeast: const LatLng(2.15, 102.75),
  );

  Position? _currentPosition;
  Set<Marker> _markers = {};
  List<DocumentSnapshot> _allPlaces = [];
  List<dynamic> _externalPlaces = [];

  // Range settings
  double _rangeKm = 5.0; // Initial range 5km
  final double _minRange = 1.0;
  final double _maxRange = 100.0;

  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _initLocationAndData();
  }

  Future<void> _initLocationAndData() async {
    try {
      // 1. Check Permissions

      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Perkhidmatan lokasi dinyahaktifkan.';
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Keizinan lokasi dinafikan';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Keizinan lokasi dinafikan secara kekal, kami tidak dapat meminta keizinan.';
      }

      // 2. Get Current Location
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _currentPosition = position;
      });

      // 3. Move Camera (Only if in Muar, otherwise focus on Muar center)
      final GoogleMapController controller = await _controller.future;
      final userLatLng = LatLng(position.latitude, position.longitude);

      if (_muarBounds.contains(userLatLng)) {
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: userLatLng,
            zoom: 14.5,
          ),
        ));
      } else {
        controller.animateCamera(CameraUpdate.newCameraPosition(_muarCamera));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anda berada di luar Muar. Menunjukkan peta Muar.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      // 4. Fetch Data
      await _fetchPlaces();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _fetchPlaces() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('places')
          .where('status', isEqualTo: 'approved')
          .get();

      setState(() {
        _allPlaces = snapshot.docs;
      });
      debugPrint("DEBUG: Fetched ${_allPlaces.length} approved places");

      // 4b. Fetch External Google Places
      await _fetchExternalPlaces();

      setState(() => _isLoading = false);
      _filterPlaces();
    } catch (e) {
      debugPrint("Error fetching places: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchExternalPlaces() async {
    if (_currentPosition == null) return;
    try {
      final lat = _currentPosition!.latitude;
      final lng = _currentPosition!.longitude;
      // Convert km to meters for API
      final radius = (_rangeKm * 1000).toInt();

      // Using Places API (New) - v1
      final url = Uri.parse(Env.googlePlacesUrl);

      final body = jsonEncode({
        "includedTypes": [
          "tourist_attraction",
          "restaurant",
          "point_of_interest"
        ],
        "maxResultCount": 20,
        "locationRestriction": {
          "circle": {
            "center": {"latitude": lat, "longitude": lng},
            "radius": radius.toDouble()
          }
        }
      });

      final headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _googleApiKey,
        'X-Goog-FieldMask':
            'places.id,places.displayName,places.location,places.formattedAddress',
      };

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _externalPlaces = data['places'] ?? [];
        });
        debugPrint(
            "DEBUG: Fetched ${_externalPlaces.length} Google Places (New API)");
      } else {
        debugPrint(
            "DEBUG: HTTP Error ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("DEBUG: External Fetch Error: $e");
    }
  }

  void _filterPlaces() {
    if (_currentPosition == null) return;

    final Set<Marker> newMarkers = {};

    for (var doc in _allPlaces) {
      final data = doc.data() as Map<String, dynamic>;
      final GeoPoint? location = _parseLocation(data['location']);

      if (location != null) {
        final double distanceInMeters = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          location.latitude,
          location.longitude,
        );

        final double distanceInKm = distanceInMeters / 1000;
        final LatLng placeLocation =
            LatLng(location.latitude, location.longitude);

        // STRICT CHECK: Must be within Muar Bounds AND within range
        if (distanceInKm <= _rangeKm && _muarBounds.contains(placeLocation)) {
          final String placeId = doc.id;
          newMarkers.add(
            Marker(
              markerId: MarkerId(placeId),
              position: placeLocation,
              infoWindow: InfoWindow(
                  title: data['name'] ?? 'Tempat Tidak Diketahui',
                  snippet: '${distanceInKm.toStringAsFixed(1)}km jauhnya',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PlaceDetailPage(placeId: placeId)),
                    );
                  }),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed),
            ),
          );
        }
      }
    }

    // Add user marker
    newMarkers.add(
      Marker(
        markerId: const MarkerId('me'),
        position:
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        infoWindow: const InfoWindow(title: "Lokasi Saya"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        zIndexInt: 2,
      ),
    );

    // Add External Places
    for (var place in _externalPlaces) {
      if (place['location'] == null) continue;

      final lat = place['location']['latitude'];
      final lng = place['location']['longitude'];
      final name = place['displayName']?['text'] ?? 'Unknown';
      final String placeId = place['id'];
      final vicinity = place['formattedAddress'] ?? '';

      // Simple Distance Check
      final double distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        lat,
        lng,
      );
      final double distKm = distanceInMeters / 1000;
      final LatLng extLocation = LatLng(lat, lng);

      // STRICT CHECK: Must be within Muar Bounds AND within range
      if (distKm <= _rangeKm && _muarBounds.contains(extLocation)) {
        newMarkers.add(Marker(
            markerId: MarkerId(placeId),
            position: extLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet),
            infoWindow: InfoWindow(
                title: name,
                snippet: vicinity,
                onTap: () {
                  _showExternalPlaceDialog(name, vicinity, lat, lng);
                })));
      }
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  void _showExternalPlaceDialog(
      String name, String address, double lat, double lng) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(name),
              content: Text(address),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Tutup"),
                ),
                // We could add a 'View in Maps' button here later using url_launcher
              ],
            ));
  }

  GeoPoint? _parseLocation(dynamic loc) {
    if (loc is GeoPoint) return loc;
    if (loc is Map) {
      final lat = double.tryParse(loc['latitude'].toString());
      final lng = double.tryParse(loc['longitude'].toString());
      if (lat != null && lng != null) return GeoPoint(lat, lng);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMsg != null && _currentPosition == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Tempat Berdekatan"),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _initLocationAndData,
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              Text("Akses Dinafikan atau Ralat",
                  style: Theme.of(context).textTheme.titleLarge),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_errorMsg!, textAlign: TextAlign.center),
              ),
              ElevatedButton(
                onPressed: _initLocationAndData,
                child: const Text("Cuba Semula"),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _muarCamera,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            cameraTargetBounds: CameraTargetBounds(_muarBounds),
            minMaxZoomPreference: const MinMaxZoomPreference(12, 20),
            myLocationEnabled: _currentPosition != null &&
                _muarBounds.contains(LatLng(
                    _currentPosition!.latitude, _currentPosition!.longitude)),
            myLocationButtonEnabled: false, // custom button
            markers: _markers,
            padding:
                const EdgeInsets.only(bottom: 160), // Space for bottom sheet
          ),

          // Custom Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Re-center Button
          Positioned(
            right: 16,
            bottom: 250, // Above the panel
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              heroTag: 'recenter',
              onPressed: () async {
                final c = await _controller.future;
                if (_currentPosition != null) {
                  final userLatLng = LatLng(
                      _currentPosition!.latitude, _currentPosition!.longitude);
                  if (_muarBounds.contains(userLatLng)) {
                    c.animateCamera(CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: userLatLng,
                        zoom: 15,
                      ),
                    ));
                  } else {
                    c.animateCamera(
                        CameraUpdate.newCameraPosition(_muarCamera));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Lokasi anda di luar Muar')),
                      );
                    }
                  }
                } else {
                  _initLocationAndData();
                }
              },
              child:
                  const Icon(Icons.my_location, color: AppTheme.primaryColor),
            ),
          ),

          // Control Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Radius Carian",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${_rangeKm.toStringAsFixed(1)} KM",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primaryColor,
                      inactiveTrackColor: Colors.grey.shade200,
                      thumbColor: AppTheme.primaryColor,
                      overlayColor:
                          AppTheme.primaryColor.withValues(alpha: 0.2),
                      trackHeight: 4.0,
                    ),
                    child: Slider(
                      value: _rangeKm,
                      min: _minRange,
                      max: _maxRange,
                      divisions: 49,
                      label: "${_rangeKm.round()} KM",
                      onChanged: (value) {
                        setState(() => _rangeKm = value);
                        // Debounce: Only fetch new API results if released?
                        // For now, to save API calls, let's just re-filter the *existing* list
                        // unless the user explicitly drags a lot.
                        // Actually, to make it simple: We re-fetch when they STOP dragging (onChangeEnd) or just re-filter existing.
                        // Since API is costly, let's re-fetch only if necessary.
                        // For this demo: Just re-filter existing.
                        _filterPlaces();
                      },
                      onChangeEnd: (value) {
                        // Re-fetch from API when slider stops to get new range data
                        _fetchPlaces();
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Dijumpai ${_markers.length > 1 ? _markers.length - 1 : 0} tempat berdekatan",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (_isLoading) const LinearProgressIndicator(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
