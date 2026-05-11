import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:muar_tourism_guide/modules/user/explorer/explorer_page.dart';
import 'package:muar_tourism_guide/theme/app_theme.dart';

class MyFavoritesPage extends StatelessWidget {
  const MyFavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Sila log masuk")));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Tempat Kegemaran Saya"),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: AppTheme.textColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData ||
              (userSnapshot.data?.exists ?? false) == false) {
            return const Center(child: Text("Tiada kegemaran lagi"));
          }

          final userData =
              userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
          final List<dynamic> favoriteIds = userData['favorites'] ?? [];

          if (favoriteIds.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.place_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Anda belum menyimpan sebarang tempat lagi."),
                ],
              ),
            );
          }

          // Fetch places matching these IDs
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('places').snapshots(),
            builder: (context, placesSnapshot) {
              if (placesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allPlaces = placesSnapshot.data?.docs ?? [];
              final favPlaces = allPlaces
                  .where((doc) => favoriteIds.contains(doc.id))
                  .toList();

              if (favPlaces.isEmpty) {
                return const Center(child: Text("Memuatkan kegemaran anda..."));
              }

              return RefreshIndicator(
                onRefresh: () async {
                  if (context.mounted) (context as Element).markNeedsBuild();
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                color: AppTheme.primaryColor,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: favPlaces.length,
                  itemBuilder: (context, index) {
                    final place = favPlaces[index];
                    final data = place.data() as Map<String, dynamic>? ?? {};

                    return ModernPlaceTile(
                      key: ValueKey("fav_${place.id}"),
                      title: data['name'] ?? 'Tempat Tidak Diketahui',
                      subtitle: data['category'] ?? 'Kategori',
                      image: data['image'] ?? '',
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/placeDetail',
                        arguments: place.id,
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
