import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:muar_tourism_guide/theme/app_theme.dart';
import 'package:muar_tourism_guide/modules/user/explorer/place_detail_page.dart';

class EventPage extends StatefulWidget {
  final DateTime? initialDate;
  const EventPage({super.key, this.initialDate});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate ?? DateTime.now();
    _selectedDay = _focusedDay;
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  Map<DateTime, List<Map<String, dynamic>>> _groupEventsAndTrips(
      List<QueryDocumentSnapshot> events, List<QueryDocumentSnapshot> trips) {
    Map<DateTime, List<Map<String, dynamic>>> data = {};

    // 1. Process Public Events
    for (var doc in events) {
      final event = doc.data() as Map<String, dynamic>;
      final dateStr = event['date'];
      if (dateStr != null) {
        try {
          final date = DateFormat('yyyy-MM-dd').parse(dateStr);
          final normalizedDate = DateTime.utc(date.year, date.month, date.day);
          if (data[normalizedDate] == null) data[normalizedDate] = [];
          data[normalizedDate]!.add(event);
        } catch (e) {
          debugPrint("Error parsing event date: $dateStr");
        }
      }
    }

    // 2. Process Personal Trips
    for (var doc in trips) {
      final trip = doc.data() as Map<String, dynamic>;
      final dateStr = trip['date'];
      if (dateStr != null) {
        try {
          final date = DateFormat('yyyy-MM-dd').parse(dateStr);
          final normalizedDate = DateTime.utc(date.year, date.month, date.day);
          if (data[normalizedDate] == null) data[normalizedDate] = [];

          // Create a synthetic event marker for the trip
          final todos = trip['todos'] as List? ?? [];
          if (todos.isEmpty) continue; // Don't show empty plans
          final notDoneCount = todos.where((t) => t['done'] != true).length;

          data[normalizedDate]!.add({
            'title': 'Pelan Perjalanan ($notDoneCount lokasi)',
            'date': dateStr,
            'type': 'trip',
            'docId': doc.id,
          });
        } catch (e) {
          debugPrint("Error parsing trip date: $dateStr");
        }
      }
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 800));
          },
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            slivers: [
              // 🛡️ PREMIUM HEADER
              SliverAppBar(
                title: const Text("Kalendar Acara"),
                centerTitle: true,
                pinned: true,
                backgroundColor: AppTheme.backgroundColor,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading:
                    false, // Core tab: remove back button
                titleTextStyle: TextStyle(
                    color: AppTheme.getAdaptiveTextColor(context),
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),

              // 📅 CALENDAR CARD
              SliverToBoxAdapter(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('events')
                      .snapshots(),
                  builder: (context, eventSnapshot) {
                    final user = FirebaseAuth.instance.currentUser;
                    // If user is logged in, listen to their trips too
                    Stream<QuerySnapshot> tripStream = user != null
                        ? FirebaseFirestore.instance
                            .collection('trip_plans')
                            .where('userId', isEqualTo: user.uid)
                            .snapshots()
                        : const Stream.empty();

                    return StreamBuilder<QuerySnapshot>(
                      stream: tripStream,
                      builder: (context, tripSnapshot) {
                        if (eventSnapshot.hasData || tripSnapshot.hasData) {
                          final eventDocs = eventSnapshot.data?.docs ?? [];
                          final tripDocs = tripSnapshot.data?.docs ?? [];
                          _events = _groupEventsAndTrips(eventDocs, tripDocs);
                        }

                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10))
                              ],
                            ),
                            child: TableCalendar(
                              locale: 'ms_MY',
                              firstDay: DateTime.utc(2023, 1, 1),
                              lastDay: DateTime.utc(2030, 12, 31),
                              focusedDay: _focusedDay,
                              selectedDayPredicate: (day) =>
                                  isSameDay(_selectedDay, day),
                              onDaySelected: (s, f) => setState(() {
                                _selectedDay = s;
                                _focusedDay = f;
                              }),
                              eventLoader: _getEventsForDay,
                              headerStyle: HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                                titleTextStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color:
                                        AppTheme.getAdaptiveTextColor(context)),
                                leftChevronIcon: const Icon(
                                    Icons.chevron_left_rounded,
                                    color: AppTheme.primaryColor),
                                rightChevronIcon: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppTheme.primaryColor),
                              ),
                              calendarStyle: CalendarStyle(
                                todayDecoration: BoxDecoration(
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle),
                                todayTextStyle: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold),
                                selectedDecoration: const BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle),
                                markerDecoration: const BoxDecoration(
                                    color: AppTheme.secondaryColor,
                                    shape: BoxShape.circle),
                                weekendTextStyle:
                                    const TextStyle(color: Colors.redAccent),
                                defaultTextStyle: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // 📜 EVENTS LIST
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                      "Acara untuk ${DateFormat('dd MMMM yyyy').format(_selectedDay!)}",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.getAdaptiveTextColor(context))),
                ),
              ),

              _buildEventsList(),

              // 📝 TRIP PLAN SECTION
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Row(
                    children: [
                      Text("Perancangan Perjalanan Anda",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.getAdaptiveTextColor(context))),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _showQuickAddBottomSheet(context),
                        icon: const Icon(Icons.add_location_alt_rounded,
                            color: AppTheme.primaryColor, size: 24),
                        tooltip: "Tambah lokasi pantas",
                      ),
                    ],
                  ),
                ),
              ),

              _buildTripPlanSection(),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ));
  }

  Widget _buildEventsList() {
    final events = _getEventsForDay(_selectedDay!);
    if (events.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
              child: Text("Tiada acara dijadualkan untuk hari ini.",
                  style: TextStyle(
                      color: AppTheme.getAdaptiveSubTextColor(context)))),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final event = events[index];
          final isTrip = event['type'] == 'trip';

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: isTrip
                        ? Colors.amber.withValues(alpha: 0.1)
                        : AppTheme.lightPrimary,
                    borderRadius: BorderRadius.circular(16)),
                child: Icon(
                    isTrip ? Icons.map_rounded : Icons.event_available_rounded,
                    color: isTrip ? Colors.amber : AppTheme.primaryColor),
              ),
              title: Text(event['title'] ?? 'Acara Menarik',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: AppTheme.getAdaptiveTextColor(context))),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  if (!isTrip) ...[
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 14, color: AppTheme.subTextColor),
                        const SizedBox(width: 4),
                        Text(event['time'] ?? 'Sepanjang Hari',
                            style: TextStyle(
                                color:
                                    AppTheme.getAdaptiveSubTextColor(context),
                                fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 14, color: AppTheme.subTextColor),
                        const SizedBox(width: 4),
                        Text(event['location'] ?? 'Muar',
                            style: TextStyle(
                                color:
                                    AppTheme.getAdaptiveSubTextColor(context),
                                fontSize: 13)),
                      ],
                    ),
                  ] else
                    Text("Skrol ke bawah untuk melihat pelan terperinci anda.",
                        style: TextStyle(
                            color: AppTheme.getAdaptiveSubTextColor(context),
                            fontSize: 13,
                            fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          );
        },
        childCount: events.length,
      ),
    );
  }

  Widget _buildTripPlanSection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);

    return SliverToBoxAdapter(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('trip_plans')
            .where('userId', isEqualTo: user.uid)
            .where('date', isEqualTo: dateStr)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          final plans = snapshot.data!.docs;
          if (plans.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: OutlinedButton.icon(
                onPressed: () => _showQuickAddBottomSheet(context),
                icon: const Icon(Icons.add_location_alt_rounded),
                label: const Text("Rancang lawatan anda ke Muar"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  foregroundColor: AppTheme.primaryColor,
                  side:
                      const BorderSide(color: AppTheme.primaryColor, width: 1),
                ),
              ),
            );
          }

          final planDoc = plans.first;
          final todos = List<Map<String, dynamic>>.from(planDoc['todos'] ?? []);

          return Column(
            children: [
              ...todos.asMap().entries.map((entry) {
                final index = entry.key;
                final todo = entry.value;
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4)
                    ],
                  ),
                  child: ListTile(
                    onTap: todo['placeId'] != null
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PlaceDetailPage(placeId: todo['placeId']),
                              ),
                            )
                        : null,
                    leading: Checkbox(
                      value: todo['done'] ?? false,
                      activeColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) =>
                          _toggleTask(planDoc.id, todos, index, val ?? false),
                    ),
                    title: Row(
                      children: [
                        if (todo['placeId'] != null)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.place_rounded,
                                size: 16, color: AppTheme.primaryColor),
                          ),
                        Expanded(
                          child: Text(todo['task'] ?? '',
                              style: TextStyle(
                                  decoration: (todo['done'] ?? false)
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: (todo['done'] ?? false)
                                      ? AppTheme.getAdaptiveSubTextColor(
                                          context)
                                      : AppTheme.getAdaptiveTextColor(
                                          context))),
                        ),
                      ],
                    ),
                    subtitle: todo['notes'] != null &&
                            (todo['notes'] as String).isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4, left: 24),
                            child: Text(todo['notes'],
                                style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.getAdaptiveSubTextColor(
                                        context))),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.note_alt_outlined,
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.7),
                              size: 20),
                          onPressed: () => _showNoteDialog(
                              context, planDoc.id, todos, index),
                          tooltip: "Add visit note",
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent, size: 20),
                          onPressed: () =>
                              _deleteTask(planDoc.id, todos, index),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  void _showNoteDialog(BuildContext context, String planId,
      List<Map<String, dynamic>> todos, int index) {
    final controller = TextEditingController(text: todos[index]['notes'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Nota untuk ${todos[index]['task']}"),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "cth. Cuba sate yang terkenal di sini!",
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              todos[index]['notes'] = controller.text.trim();
              await FirebaseFirestore.instance
                  .collection('trip_plans')
                  .doc(planId)
                  .update({"todos": todos});
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text("Simpan Nota"),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTask(String planId, List<Map<String, dynamic>> todos,
      int index, bool done) async {
    todos[index]['done'] = done;
    await FirebaseFirestore.instance
        .collection('trip_plans')
        .doc(planId)
        .update({"todos": todos});
  }

  Future<void> _deleteTask(
      String planId, List<Map<String, dynamic>> todos, int index) async {
    todos.removeAt(index);
    await FirebaseFirestore.instance
        .collection('trip_plans')
        .doc(planId)
        .update({"todos": todos});
  }

  void _showQuickAddBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
                  const SizedBox(width: 12),
                  const Text("Tambah Lokasi Pantas",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded))
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('places').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allDocs = snapshot.data!.docs;
                  final validPlaces = allDocs.where((doc) {
                    return doc.data() is Map<String, dynamic>;
                  }).toList();

                  if (validPlaces.isEmpty) {
                    return Center(
                      child: Text(
                        "Tiada tempat dijumpai.\n(Jumlah dok: ${allDocs.length})",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: validPlaces.length,
                    itemBuilder: (context, index) {
                      final place = validPlaces[index];
                      final data = place.data() as Map<String, dynamic>;

                      final name = data['name']?.toString() ?? 'Unknown Spot';
                      final category =
                          data['category']?.toString() ?? 'Tourist Spot';

                      String? imageUrl;
                      try {
                        final rawImages = data['imageUrls'];
                        if (rawImages is List && rawImages.isNotEmpty) {
                          imageUrl = rawImages.first?.toString();
                        }
                      } catch (_) {}

                      // Wrap in RepaintBoundary to isolate layout/paint/semantics
                      return RepaintBoundary(
                        key: ValueKey('quick_${place.id}'),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2))
                              ]),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(8),
                            leading: SizedBox(
                              width: 60,
                              height: 60,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                // Exclude image semantics to reduce noise during loading
                                child: ExcludeSemantics(
                                  child: imageUrl != null && imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                                Icons.broken_image,
                                                size: 20,
                                                color: Colors.grey),
                                          ),
                                        )
                                      : Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.image_rounded,
                                              color: Colors.grey),
                                        ),
                                ),
                              ),
                            ),
                            title: Text(name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            subtitle: Text(category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey)),
                            trailing: ElevatedButton(
                              onPressed: () {
                                _quickAddPlace(place.id, name);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  minimumSize: const Size(0,
                                      36), // Prevent infinite width crash in ListTile
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8))),
                              child: const Text("Tambah"),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _quickAddPlace(String placeId, String placeName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    final newTask = {
      "task": "Visit $placeName",
      "done": false,
      "placeId": placeId,
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
    } catch (e) {
      debugPrint("Error in quick add: $e");
    }
  }
}
