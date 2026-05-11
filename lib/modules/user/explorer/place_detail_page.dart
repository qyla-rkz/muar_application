import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:muar_tourism_guide/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shops/shop_detail_page.dart';
import '../../../utils/env.dart';
import '../../../widgets/image_slideshow.dart';

class PlaceDetailPage extends StatefulWidget {
  final String placeId;

  const PlaceDetailPage({super.key, required this.placeId});

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _openMap(BuildContext context, GeoPoint location) async {
    final lat = location.latitude;
    final lng = location.longitude;
    final Uri googleMapsUrl =
        Uri.parse("${Env.googleMapsDirUrl}$lat,$lng");

    try {
      if (!await launchUrl(googleMapsUrl,
          mode: LaunchMode.externalApplication)) {
        throw 'Tidak dapat melancarkan peta';
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka peta: $e')),
      );
    }
  }

  Future<void> _addToTrip(BuildContext context, String placeName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sila log masuk untuk merancang perjalanan anda')),
      );
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(picked);
      final newTask = {
        "task": "Melawat $placeName",
        "done": false,
        "placeId": widget.placeId,
        "type": "place"
      };

      try {
        final query = await FirebaseFirestore.instance
            .collection('trip_plans')
            .where('userId', isEqualTo: user.uid)
            .where('date', isEqualTo: dateStr)
            .get();

        if (query.docs.isEmpty) {
          await FirebaseFirestore.instance.collection('trip_plans').add({
            "userId": user.uid,
            "date": dateStr,
            "todos": [newTask],
            "createdAt": FieldValue.serverTimestamp(),
          });
        } else {
          final docId = query.docs.first.id;
          final existingTodos =
              List<Map<String, dynamic>>.from(query.docs.first['todos'] ?? []);
          existingTodos.add(newTask);
          await FirebaseFirestore.instance
              .collection('trip_plans')
              .doc(docId)
              .update({"todos": existingTodos});
        }

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Ditambah ke perjalanan anda pada ${DateFormat('dd MMM').format(picked)}!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Lihat Perjalanan',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                  arguments: {
                    'index': 2,
                    'date': picked,
                  },
                );
              },
            ),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ralat menambah ke perjalanan: $e')),
        );
      }
    }
  }

  Future<void> _toggleFavorite(BuildContext context, bool isFav) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sila log masuk untuk menambah kegemaran')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'favorites': isFav
            ? FieldValue.arrayRemove([widget.placeId])
            : FieldValue.arrayUnion([widget.placeId])
      });
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ralat mengemas kini kegemaran: $e')),
      );
    }
  }

  Future<void> _addReview(BuildContext context, String currentPlaceName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila log masuk untuk menambah ulasan')),
      );
      return;
    }

    double rating = 5.0;
    final commentController = TextEditingController();
    XFile? imageReview;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Tambah Ulasan"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => setDialogState(() => rating = index + 1.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                      ),
                    );
                  }),
                ),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    hintText: "Kongsi pengalaman anda...",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                if (imageReview != null)
                  Container(
                    height: 100,
                    width: 100,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(File(imageReview!.path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                TextButton.icon(
                  onPressed: () async {
                    final picked =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setDialogState(() => imageReview = picked);
                    }
                  },
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text("Tambah Foto"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                final comment = commentController.text.trim();
                if (comment.isEmpty) return;

                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Menghantar ulasan...')),
                );

                try {
                  String? reviewImageUrl;
                  if (imageReview != null) {
                    try {
                      final ref = FirebaseStorage.instance.ref().child(
                          'review_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
                      await ref.putFile(File(imageReview!.path));
                      reviewImageUrl = await ref.getDownloadURL();
                    } catch (storageError) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "Amaran: Foto gagal dimuat naik. Menghantar ulasan teks sahaja."),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                      reviewImageUrl = null;
                    }
                  }

                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get();
                  final userData = userDoc.data();

                  await FirebaseFirestore.instance
                      .collection('places')
                      .doc(widget.placeId)
                      .collection('reviews')
                      .add({
                    'userId': user.uid,
                    'userName': userData?['name'] ?? 'Tourist',
                    'userImageUrl': userData?['imageUrl'],
                    'placeId': widget.placeId,
                    'placeName': currentPlaceName,
                    'rating': rating,
                    'comment': comment,
                    'imageUrl': reviewImageUrl,
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Ulasan berjaya dihantar!'),
                          backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Ralat Menghantar Ulasan"),
                        content:
                            Text(e.toString().replaceAll("Exception: ", "")),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("OK"),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
              child: const Text("Post"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewMenu(String reviewId, Map<String, dynamic> reviewData) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner =
        currentUserId != null && currentUserId == reviewData['userId'];
    final canDelete = isOwner;
    final canReport = !isOwner;

    if (!canDelete && !canReport) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
      padding: EdgeInsets.zero,
      onSelected: (value) {
        if (value == 'edit') {
          _editReview(reviewId, reviewData);
        } else if (value == 'delete') {
          _showDeleteReviewConfirmation(reviewId);
        } else if (value == 'report') {
          _reportReview(
            reviewId,
            reviewData['comment'] ?? '',
            reviewData['userName'] ?? 'Tourist',
          );
        }
      },
      itemBuilder: (context) {
        final List<PopupMenuEntry<String>> items = [];

        if (isOwner) {
          items.add(const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text("Edit", style: TextStyle(color: Colors.blue)),
              ],
            ),
          ));
        }

        if (canDelete) {
          items.add(const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text("Padam", style: TextStyle(color: Colors.red)),
              ],
            ),
          ));
        }

        if (canReport) {
          items.add(const PopupMenuItem(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.flag, color: Colors.black87, size: 20),
                SizedBox(width: 8),
                Text("Lapor"),
              ],
            ),
          ));
        }

        return items;
      },
    );
  }

  void _showDeleteReviewConfirmation(String reviewId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Padam Ulasan"),
        content: const Text("Adakah anda pasti mahu memadam ulasan ini?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteReview(reviewId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Padam", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _editReview(
      String reviewId, Map<String, dynamic> reviewData) async {
    double rating = (reviewData['rating'] as num?)?.toDouble() ?? 5.0;
    final commentController =
        TextEditingController(text: reviewData['comment'] ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Edit Ulasan"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => setDialogState(() => rating = index + 1.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                      ),
                    );
                  }),
                ),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    hintText: "Kemaskini pengalaman anda...",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                if (reviewData['imageUrl'] != null) ...[
                  const SizedBox(height: 10),
                  const Text(
                      "Nota: Foto ulasan tidak boleh diubah melalui edit.",
                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                final comment = commentController.text.trim();
                if (comment.isEmpty) return;

                Navigator.pop(ctx);
                try {
                  await FirebaseFirestore.instance
                      .collection('places')
                      .doc(widget.placeId)
                      .collection('reviews')
                      .doc(reviewId)
                      .update({
                    'rating': rating,
                    'comment': comment,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  if (mounted && ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                          content: Text('Ulasan berjaya dikemaskini!'),
                          backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted && ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Ralat mengemas kini ulasan: $e')),
                    );
                  }
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteReview(String reviewId) async {
    try {
      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.placeId)
          .collection('reviews')
          .doc(reviewId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ulasan berjaya dipadam')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ralat memadam ulasan: $e')),
        );
      }
    }
  }

  Future<void> _reportReview(
      String reviewId, String comment, String reviewerName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Lapor Ulasan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Melaporkan ulasan oleh: $reviewerName",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            Text(
                "\"${comment.length > 50 ? '${comment.substring(0, 47)}...' : comment}\"",
                style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 11,
                    color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: "Sebab melaporkan...",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);

              try {
                await FirebaseFirestore.instance.collection('reports').add({
                  'reviewId': reviewId,
                  'placeId': widget.placeId,
                  'reporterId': user.uid,
                  'reason': reason,
                  'content': comment,
                  'reviewerName': reviewerName,
                  'createdAt': FieldValue.serverTimestamp(),
                  'type': 'review'
                });

                // Report created in 'reports' collection

                if (mounted && ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Laporan berjaya dihantar')),
                  );
                }
              } catch (e) {
                if (mounted && ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Ralat melaporkan ulasan: $e')),
                  );
                }
              }
            },
            child: const Text("Lapor"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // user check for favorite button stream
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Butiran Tempat",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (!isGuest)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final favorites =
                    snapshot.hasData && (snapshot.data?.exists ?? false)
                        ? List<String>.from((snapshot.data?.data()
                                as Map<String, dynamic>?)?['favorites'] ??
                            [])
                        : <String>[];
                final isFav = favorites.contains(widget.placeId);

                return IconButton(
                  icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.white),
                  onPressed: () => _toggleFavorite(context, isFav),
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('places')
            .doc(widget.placeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !(snapshot.data?.exists ?? false)) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 50, color: Colors.grey),
                    const SizedBox(height: 10),
                    const Text(
                      "Tempat tidak dijumpai",
                      style: TextStyle(color: Colors.grey, fontSize: 18),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Mencari ID: '${widget.placeId}'",
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Sila cipta dokumen di Firebase\n"
                      "collection: 'places'\n"
                      "document ID: (seperti dipaparkan di atas)",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

          final name = data['name'] ?? '';
          final description = data['description'] ?? '';
          final category = data['category'] ?? '';
          final images = List<String>.from(data['imageUrls'] ?? []);

          // Robust Location Parsing
          GeoPoint? location;
          try {
            final dynamic loc = data['location'];
            if (loc is GeoPoint) {
              location = loc;
            } else if (loc is Map) {
              final double? lat = double.tryParse(loc['latitude'].toString());
              final double? lng = double.tryParse(loc['longitude'].toString());
              if (lat != null && lng != null) {
                location = GeoPoint(lat, lng);
              }
            }
          } catch (_) {
            // Location malformed - will be treated as null
          }

          return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
                await Future.delayed(const Duration(milliseconds: 500));
              },
              color: AppTheme.primaryColor,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (images.isNotEmpty)
                      ImageSlideshow(imageUrls: images)
                    else
                      Container(
                        height: 250,
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 50),
                        ),
                      ),
                    const SizedBox(height: 16),

                    if (!isGuest)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Chip(
                          label: Text(category),
                          backgroundColor: AppTheme.primaryColor,
                          labelStyle: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // 📛 Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        name,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ✨ NEW BOXED LAYOUT SECTION
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          if (data['address'] != null)
                            _buildInfoBox(
                              context,
                              icon: Icons.location_on,
                              title: "Alamat",
                              content: data['address'],
                            ),
                          const SizedBox(height: 12),
                          _buildInfoBox(
                            context,
                            icon: Icons.access_time,
                            title: "Waktu Operasi",
                            content: data['operatingHours'] ?? 'N/A',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoBox(
                            context,
                            icon: Icons.phone,
                            title: "Telefon",
                            content: data['contactNumber'] ?? 'N/A',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 📖 ABOUT SECTION
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Tentang Tempat Ini",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        description,
                        style: const TextStyle(
                            fontSize: 16, height: 1.6, color: Colors.black54),
                      ),
                    ),

                    // Extra Details (Price, Best Time, etc.) only if not guest
                    if (!isGuest) ...[
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (data['ticketPrice'] != null)
                              _buildMiniDetailChip(Icons.confirmation_number,
                                  "Masuk: ${data['ticketPrice']}"),
                            if (data['bestTime'] != null)
                              _buildMiniDetailChip(Icons.wb_twilight,
                                  "Waktu Terbaik: ${data['bestTime']}"),
                            if (data['suitableWeather'] != null)
                              _buildMiniDetailChip(Icons.cloud,
                                  "Cuaca: ${data['suitableWeather']}"),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 30),

                    // 🖼️ Gallery Section
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Gallery",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('places')
                          .doc(widget.placeId)
                          .collection('reviews')
                          .snapshots(),
                      builder: (context, reviewSnapshot) {
                        final List<String> allImages =
                            List<String>.from(images);

                        if (reviewSnapshot.hasData) {
                          for (var doc in reviewSnapshot.data?.docs ?? []) {
                            final rData =
                                doc.data() as Map<String, dynamic>? ?? {};
                            if (rData['imageUrl'] != null) {
                              allImages.add(rData['imageUrl']);
                            }
                          }
                        }

                        if (allImages.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text("Tiada imej dalam galeri lagi.",
                                style: TextStyle(color: Colors.grey)),
                          );
                        }

                        return SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: allImages.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                key: ValueKey("gallery_$index"),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      insetPadding: EdgeInsets.zero,
                                      backgroundColor: Colors.black,
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: ImageSlideshow(
                                              imageUrls: allImages,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.8,
                                              autoSlide: false,
                                              initialPage: index,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          Positioned(
                                            top: 40,
                                            right: 20,
                                            child: IconButton(
                                              icon: const Icon(Icons.close,
                                                  color: Colors.white,
                                                  size: 30),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  width: 120,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      allImages[index],
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        final total =
                                            loadingProgress.expectedTotalBytes;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: total != null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    total
                                                : null,
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image,
                                            color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // 🗺️ Map Screenshot Section
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Location",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5))
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: data['mapScreenshotUrl'] != null &&
                                  data['mapScreenshotUrl'].toString().isNotEmpty
                              ? Image.network(
                                  data['mapScreenshotUrl'],
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image,
                                        size: 50, color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.map_outlined,
                                          size: 50, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text(
                                          "Tangkapan skrin peta tidak tersedia",
                                          style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            if (!isGuest) ...[
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _addToTrip(context, name),
                                  icon: const Icon(Icons.event_note_rounded,
                                      color: AppTheme.primaryColor),
                                  label: const Text(
                                    "Tambah ke Perjalanan",
                                    style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: const BorderSide(
                                            color: AppTheme.primaryColor,
                                            width: 2)),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: location != null
                                    ? () => _openMap(context, location!)
                                    : null,
                                icon: const Icon(Icons.directions_rounded,
                                    color: Colors.white),
                                label: const Text(
                                  "Arah",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 🛒 VERIFIED LOCAL MERCHANTS
                    _buildVerifiedMerchants(),

                    if (!isGuest) ...[
                      const SizedBox(height: 30),
                      // ⭐ Reviews Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Ulasan",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor),
                            ),
                            TextButton.icon(
                              onPressed: () => _addReview(context, name),
                              icon: const Icon(Icons.add_comment,
                                  color: AppTheme.primaryColor),
                              label: const Text("Tulis Ulasan",
                                  style:
                                      TextStyle(color: AppTheme.primaryColor)),
                            ),
                          ],
                        ),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('places')
                            .doc(widget.placeId)
                            .collection('reviews')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                  "Error loading reviews: ${snapshot.error}",
                                  style: const TextStyle(color: Colors.red)),
                            );
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData ||
                              (snapshot.data?.docs.isEmpty ?? true)) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                  "Tiada ulasan lagi. Jadi yang pertama untuk mengulas!",
                                  style: TextStyle(color: Colors.grey)),
                            );
                          }

                          final docs = snapshot.data?.docs ?? [];
                          // Separate local sorting to handle null timestamps and index issues
                          final List<QueryDocumentSnapshot> sortedDocs =
                              List.from(docs);
                          sortedDocs.sort((a, b) {
                            final aData =
                                a.data() as Map<String, dynamic>? ?? {};
                            final bData =
                                b.data() as Map<String, dynamic>? ?? {};
                            final aTime = aData['createdAt'] as Timestamp?;
                            final bTime = bData['createdAt'] as Timestamp?;
                            if (aTime == null) return -1; // Newest first
                            if (bTime == null) return 1;
                            return bTime.compareTo(aTime);
                          });

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sortedDocs.length,
                            itemBuilder: (context, index) {
                              final reviewDoc = sortedDocs[index];
                              final review =
                                  reviewDoc.data() as Map<String, dynamic>? ??
                                      {};
                              final reviewDate = review['createdAt'] != null
                                  ? (review['createdAt'] as Timestamp).toDate()
                                  : DateTime.now();

                              return Card(
                                key: ValueKey("review_${reviewDoc.id}"),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundImage:
                                                review['userImageUrl'] != null
                                                    ? NetworkImage(
                                                        review['userImageUrl'])
                                                    : null,
                                            child: review['userImageUrl'] ==
                                                    null
                                                ? Text(
                                                    (review['userName']
                                                                ?.toString()
                                                                .isNotEmpty ==
                                                            true
                                                        ? review['userName'][0]
                                                        : 'T'),
                                                    style: const TextStyle(
                                                        color: AppTheme
                                                            .primaryColor))
                                                : null,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(review['userName'],
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black87)),
                                                Text(
                                                    DateFormat('dd MMM yyyy')
                                                        .format(reviewDate),
                                                    style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.grey)),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children:
                                                List.generate(5, (starIndex) {
                                              return Icon(
                                                starIndex <
                                                        (review['rating'] ?? 0)
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: Colors.amber,
                                                size: 16,
                                              );
                                            }),
                                          ),
                                          const SizedBox(width: 4),
                                          _buildReviewMenu(
                                              docs[index].id, review),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(review['comment'] ?? '',
                                          style: const TextStyle(
                                              color: Colors.black87)),
                                      if (review['imageUrl'] != null) ...[
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            review['imageUrl'],
                                            height: 150,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ));
        },
      ),
    );
  }

  Widget _buildVerifiedMerchants() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "Pedagang Disahkan & Ganjaran Berdekatan",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, color: Colors.blue, size: 14),
                    SizedBox(width: 2),
                    Text("Disahkan",
                        style: TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('shops')
              .where('nearbyPlaceId', isEqualTo: widget.placeId)
              .where('status', isEqualTo: 'approved')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text("Tiada pedagang disahkan di kawasan ini lagi.",
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            return SizedBox(
              height: 180,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final shop = doc.data() as Map<String, dynamic>;
                  return Padding(
                    key: ValueKey(doc.id),
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShopDetailPage(shopId: doc.id),
                        ),
                      ),
                      child: Container(
                        width: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                    image: shop['imageUrl'] != null
                                        ? DecorationImage(
                                            image: NetworkImage(
                                                shop['imageUrl'].toString()),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: shop['imageUrl'] == null
                                      ? const Center(
                                          child: Icon(Icons.store,
                                              color: Colors.orange))
                                      : null,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shop['shopName']?.toString() ?? 'Shop',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        "🎁 Kupon Tersedia",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoBox(BuildContext context,
      {required IconData icon,
      required String title,
      required String content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniDetailChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(label),
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.8),
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
