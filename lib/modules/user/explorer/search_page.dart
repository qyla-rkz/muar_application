import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:muar_tourism_guide/theme/app_theme.dart';
import 'package:muar_tourism_guide/modules/user/explorer/place_detail_page.dart';

class SearchPage extends StatefulWidget {
  final String? initialCategory;
  const SearchPage({super.key, this.initialCategory});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  late String selectedFilter;

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.initialCategory ?? "Semua";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Cari Tempat",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔍 SEARCH FIELD
          Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(30),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Cari tempat di Muar...",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                ),
                onChanged: (_) {
                  setState(() {}); // refresh results as user types
                },
              ),
            ),
          ),

          // 🧩 FILTER CHIPS
          SizedBox(
            height: 45,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (var filter in [
                  "Semua",
                  "Jom WARISAN MUAR",
                  "Jom RASA MUAR",
                  "Jom ALAM MUAR",
                  "Jom SENI MUAR",
                  "Jom BELI-BELAH MUAR",
                  "Jom ACARA MUAR",
                  "Jom STAY MUAR",
                  "Jom AKTIVITI MUAR",
                  "Jom PERMATA TERSEMBUNYI MUAR",
                  "Jom LAIN-LAIN MUAR"
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: selectedFilter == filter,
                      onSelected: (_) {
                        setState(() {
                          selectedFilter = filter;
                        });
                      },
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: selectedFilter == filter
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // 📍 RESULTS TITLE
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Keputusan Carian",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),

          // 🔹 RESULTS LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('places')
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Tiada keputusan ditemui",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final Map<String, List<String>> categoryMap = {
                  "Semua": [
                    "Food",
                    "Warisan",
                    "Alam",
                    "Budaya",
                    "Sukan",
                    "Aktiviti",
                    "Penginapan",
                    "Shopping"
                  ],
                  "Jom WARISAN MUAR": ["Jom WARISAN MUAR", "Warisan", "Heritage"],
                  "Jom ALAM MUAR": ["Jom ALAM MUAR", "Alam", "Nature"],
                  "Jom SENI MUAR": ["Jom SENI MUAR", "Seni", "Arts"],
                  "Jom RASA MUAR": ["Jom RASA MUAR", "Makanan", "Food"],
                  "Jom ACARA MUAR": [
                    "Jom ACARA MUAR",
                    "Acara",
                    "Event",
                    "Aktiviti",
                    "Activity"
                  ],
                  "Jom BELI-BELAH MUAR": ["Jom BELI-BELAH MUAR", "Membeli-belah", "Shopping"],
                  "Jom STAY MUAR": ["Jom STAY MUAR", "Penginapan", "Accommodation"],
                  "Jom AKTIVITI MUAR": ["Jom AKTIVITI MUAR", "Aktiviti", "Activity"],
                  "Jom PERMATA TERSEMBUNYI MUAR": [
                    "Jom PERMATA TERSEMBUNYI MUAR",
                    "Hidden Gems",
                    "Permata Tersembunyi"
                  ],
                  "Jom LAIN-LAIN MUAR": ["Jom LAIN-LAIN MUAR", "Other", "Lain-lain"],
                };

                // 1. Filter locally
                final String searchText = _searchController.text.toLowerCase();
                final List<DocumentSnapshot> validDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  if (data is! Map<String, dynamic>) return false;

                  final String name = (data['name'] ?? '').toString().toLowerCase();
                  final String category = (data['category'] ?? '').toString();

                  // Search text filter (Global)
                  if (searchText.isNotEmpty && !name.contains(searchText)) {
                    return false;
                  }

                  // Category filter logic:
                  // Strictly show items that match the selected category.
                  if (selectedFilter != 'Semua') {
                    final bool matchesCategory =
                        categoryMap[selectedFilter]?.contains(category) ?? false;
                    if (!matchesCategory) return false;
                  }

                  return true;
                }).toList();

                // 2. Sophisticated Sorting Logic
                validDocs.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;

                  // Priority 1: Category Match or Grouping
                  if (selectedFilter != "Semua") {
                    final bool matchesA =
                        categoryMap[selectedFilter]?.contains(dataA['category']) ??
                            false;
                    final bool matchesB =
                        categoryMap[selectedFilter]?.contains(dataB['category']) ??
                            false;
                    if (matchesA != matchesB) return matchesA ? -1 : 1;
                  } else {
                    // Group by category string when "Semua" is selected
                    final String catA = dataA['category']?.toString() ?? '';
                    final String catB = dataB['category']?.toString() ?? '';
                    if (catA != catB) return catA.compareTo(catB);
                  }

                  // Priority 2: Manual Ranking (within the category)
                  final int? rankingA = dataA['ranking'] as int?;
                  final int? rankingB = dataB['ranking'] as int?;

                  if (rankingA != null || rankingB != null) {
                    if (rankingA != null && rankingB != null) {
                      if (rankingA != rankingB) return rankingA.compareTo(rankingB);
                    } else {
                      return rankingA != null ? -1 : 1;
                    }
                  }

                  // Priority 3: Featured status
                  final bool isFeaturedA = dataA['isFeatured'] ?? false;
                  final bool isFeaturedB = dataB['isFeatured'] ?? false;
                  if (isFeaturedA != isFeaturedB) return isFeaturedA ? -1 : 1;

                  // Priority 4: Recency (approvedAt)
                  final dynamic timeA = dataA['approvedAt'];
                  final dynamic timeB = dataB['approvedAt'];
                  if (timeA is Timestamp && timeB is Timestamp) {
                    final int timeCompare = timeB.compareTo(timeA);
                    if (timeCompare != 0) return timeCompare;
                  }

                  // Priority 5: Alphabetical
                  return (dataA['name'] ?? '')
                      .toString()
                      .compareTo((dataB['name'] ?? '').toString());
                });

                if (validDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Tiada keputusan yang sepadan dengan carian anda",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  color: AppTheme.primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: validDocs.length,
                    itemBuilder: (context, index) {
                      final doc = validDocs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return SearchResultTile(
                        key: ValueKey(doc.id),
                        place: data,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaceDetailPage(placeId: doc.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SearchResultTile extends StatelessWidget {
  final Map<String, dynamic> place;
  final VoidCallback onTap;

  const SearchResultTile({super.key, required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImage(place['imageUrls']),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                place['name'] ?? 'Tiada Nama',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (place['isFeatured'] == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor, width: 0.5),
                ),
                child: const Text(
                  'Pilihan Utama',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(place['category'] ?? 'Tiada Kategori'),
        onTap: onTap,
      ),
    );
  }

  Widget _buildImage(dynamic image) {
    String imageUrl = '';
    if (image is String) {
      imageUrl = image;
    } else if (image is List && image.isNotEmpty) {
      imageUrl = image.first.toString();
    }

    if (imageUrl.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        color: Colors.grey[300],
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }

    return Image.network(
      imageUrl,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 60,
          height: 60,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );
  }
}
