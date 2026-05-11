import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:muar_tourism_guide/modules/user/explorer/place_detail_page.dart';
import 'package:muar_tourism_guide/modules/user/explorer/near_places_page.dart';
import 'package:muar_tourism_guide/modules/user/event/event_page.dart';
import 'package:muar_tourism_guide/theme/app_theme.dart';
import 'search_page.dart';

class ExplorerPage extends StatelessWidget {
  const ExplorerPage({super.key});

  void _navigateToPlace(BuildContext context, String placeId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaceDetailPage(placeId: placeId)),
    );
  }

  void _navigateToSearch(BuildContext context, {String? category}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchPage(initialCategory: category)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 800));
          },
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            slivers: [
              // 🌄 PREMIUM SLIVER APP BAR (COLOUR ONLY)
              SliverAppBar(
                expandedHeight: 220.0,
                floating: false,
                pinned: true,
                stretch: true,
                backgroundColor: AppTheme.primaryColor,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                leading: FirebaseAuth.instance.currentUser == null
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: Stack(
                      children: [
                        // ✨ SUBTLE PATTERN/LOGOS (LIKE LOGIN)
                        Positioned(
                          top: -50,
                          right: -50,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 24,
                          bottom: 40,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Jom MUAR",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                              ),
                              Text(
                                "MUAR LOKASI PELANCONGAN LENGKAP",
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 🔍 SEARCH BAR (FIXED CLIPPING)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Hero(
                    tag: 'search_bar',
                    child: Material(
                      elevation: 6,
                      shadowColor: Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () => _navigateToSearch(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search_rounded,
                                  color: AppTheme.primaryColor),
                              SizedBox(width: 12),
                              Text(
                                "Ke mana kita?",
                                style: TextStyle(
                                    color: AppTheme.subTextColor, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 🧩 CATEGORIES (HORIZONTAL)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 125,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          CategoryCard(
                              label: "Lokasi\nAnda",
                              icon: Icons.near_me_rounded,
                              color: Colors.blueAccent,
                              onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const NearPlacesPage()),
                                  )),
                          CategoryCard(
                              label: "Jom WARISAN\nMUAR",
                              icon: Icons.account_balance,
                              color: Colors.brown,
                              onTap: () => _navigateToSearch(context,
                                  category: "Jom WARISAN MUAR")),
                          CategoryCard(
                              label: "Jom RASA\nMUAR",
                              icon: Icons.restaurant,
                              color: Colors.orange,
                              onTap: () => _navigateToSearch(context,
                                  category: "Jom RASA MUAR")),
                          CategoryCard(
                              label: "Jom ALAM\nMUAR",
                              icon: Icons.forest,
                              color: Colors.green,
                              onTap: () => _navigateToSearch(context,
                                  category: "Jom ALAM MUAR")),
                          CategoryCard(
                              label: "Jom SENI\nMUAR",
                              icon: Icons.palette,
                              color: Colors.purple,
                              onTap: () => _navigateToSearch(context,
                                  category: "Jom SENI MUAR")),
                          CategoryCard(
                              label: "Jom BELI-BELAH\nMUAR",
                              icon: Icons.shopping_bag,
                              color: Colors.pink,
                              onTap: () => _navigateToSearch(context,
                                  category: "Jom BELI-BELAH MUAR")),
                          CategoryCard(
                              label: "Jom ACARA\nMUAR",
                              icon: Icons.event,
                              color: Colors.red,
                              onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const EventPage()),
                                  )),
                          CategoryCard(
                              label: "Jom STAY\nMUAR",
                              icon: Icons.hotel,
                              color: Colors.indigo,
                              onTap: () => _navigateToSearch(context,
                                  category: "Jom STAY MUAR")),
                          CategoryCard(
                              label: "Jom AKTIVITI\nMUAR",
                              icon: Icons.directions_run_rounded,
                              color: Colors.cyan,
                              onTap: () => _navigateToSearch(context,
                                  category: "Jom AKTIVITI MUAR")),
                          CategoryCard(
                              label: "Jom PERMATA\nMUAR",
                              icon: Icons.diamond_rounded,
                              color: Colors.amber,
                              onTap: () => _navigateToSearch(context,
                                  category: "Jom PERMATA TERSEMBUNYI MUAR")),
                          CategoryCard(
                              label: "Jom LAIN-LAIN\nMUAR",
                              icon: Icons.more_horiz_rounded,
                              color: Colors.blueGrey,
                              onTap: () => _navigateToSearch(context,
                                  category: "Jom LAIN-LAIN MUAR")),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 💎 FEATURED BENTO SECTION
              const SliverToBoxAdapter(
                  child: SectionHeader(title: "Antara Tempat Menarik...")),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('places')
                    .where('status', isEqualTo: 'approved')
                    .where('isFeatured', isEqualTo: true)
                    .limit(2)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text("Error: ${snapshot.error}",
                              style: const TextStyle(color: Colors.red)),
                        ),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()));
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const SliverToBoxAdapter(
                        child: Center(child: Text("Tiada sorotan lagi")));
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final doc = docs[index];
                          final data =
                              doc.data() as Map<String, dynamic>? ?? {};
                          final List<dynamic> images = data['imageUrls'] ?? [];
                          final String mainImage =
                              images.isNotEmpty ? images.first : '';

                          return FeaturedBentoCard(
                            title: data['name'] ?? 'Tempat',
                            subtitle: data['category'] ?? 'Muar',
                            image: mainImage,
                            onTap: () => _navigateToPlace(context, doc.id),
                          );
                        },
                        childCount: docs.length,
                      ),
                    ),
                  );
                },
              ),

              // 🌳 ALL PLACES LIST
              const SliverToBoxAdapter(
                  child: SectionHeader(title: "Tempat Popular")),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('places')
                    .where('status', isEqualTo: 'approved')
                    .orderBy('approvedAt', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text("Error: ${snapshot.error}",
                              style: const TextStyle(color: Colors.red)),
                        ),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()));
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const SliverToBoxAdapter(
                        child: Center(child: Text("Tiada tempat dijumpai")));
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>? ?? {};
                        final List<dynamic> images = data['imageUrls'] ?? [];
                        final String mainImage =
                            images.isNotEmpty ? images.first : '';

                        return ModernPlaceTile(
                          title: data['name'] ?? 'Tempat',
                          subtitle: data['description'] ?? '',
                          image: mainImage,
                          onTap: () => _navigateToPlace(context, doc.id),
                        );
                      },
                      childCount: docs.length,
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(
                  child: SizedBox(height: 100)), // Space for floating bar
            ],
          ),
        ));
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;
  const SectionHeader({super.key, required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: color ?? AppTheme.primaryColor),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const CategoryCard(
      {super.key,
      required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 85,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor)),
        ],
      ),
    );
  }
}

class FeaturedBentoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  final VoidCallback onTap;

  const FeaturedBentoCard(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.image,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(image),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String img) {
    if (img.isEmpty) {
      return Container(color: Colors.grey.shade300);
    }
    if (img.startsWith('http')) {
      return Image.network(
        img,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.network(
            "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=800&q=80",
            fit: BoxFit.cover),
      );
    }
    return Image.asset(
      img,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.network(
          "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=800&q=80",
          fit: BoxFit.cover),
    );
  }
}

class ModernPlaceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  final VoidCallback onTap;

  const ModernPlaceTile(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.image,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildImage(image),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primaryColor)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.subTextColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppTheme.subTextColor.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String img) {
    if (img.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }
    if (img.startsWith('http')) {
      return Image.network(img,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ));
    }
    return Image.asset(img,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.network(
            "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=200&q=80",
            width: 80,
            height: 80,
            fit: BoxFit.cover));
  }
}
