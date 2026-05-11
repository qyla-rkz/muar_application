import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:muar_tourism_guide/theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Stream<User?> _authStream;
  Stream<DocumentSnapshot>? _userStream;
  Stream<QuerySnapshot>? _statsStream;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
  }

  void _initUserStreams(String uid) {
    _userStream ??=
        FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
    _statsStream ??= FirebaseFirestore.instance
        .collection('community_posts')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: StreamBuilder<User?>(
        stream: _authStream,
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = authSnapshot.data;
          if (user == null) {
            return _buildGuestView(context);
          }

          final String uid = user.uid;
          _initUserStreams(uid);

          return StreamBuilder<DocumentSnapshot>(
            stream: _userStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('Tiada data profil dijumpai.'));
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final String name = userData['name'] ?? 'Pengembara Muar';
              final String role = userData['role'] ?? 'user';
              final String? photoBase64 = userData['photoBase64'];
              final String? imageUrl = userData['imageUrl'];

              return RefreshIndicator(
                onRefresh: () async {
                  if (uid.isNotEmpty) {
                    _initUserStreams(uid);
                    setState(() {});
                  }
                  await Future.delayed(const Duration(milliseconds: 800));
                },
                color: AppTheme.primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // --- 🌈 PREMIUM HEADER ---
                      Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(40),
                                bottomRight: Radius.circular(40),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -50,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 20)
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white,
                                backgroundImage: imageUrl != null &&
                                        imageUrl.isNotEmpty
                                    ? NetworkImage(imageUrl) as ImageProvider
                                    : photoBase64 != null
                                        ? MemoryImage(base64Decode(photoBase64))
                                            as ImageProvider
                                        : null,
                                child: (imageUrl == null || imageUrl.isEmpty) &&
                                        photoBase64 == null
                                    ? Text(name[0].toUpperCase(),
                                        style: const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor))
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 60),

                      // --- 📝 USER INFO ---
                      Text(name,
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textColor)),
                      Text(user.email ?? '',
                          style: TextStyle(
                              color: AppTheme.getAdaptiveSubTextColor(context),
                              fontSize: 14)),

                      const SizedBox(height: 24),

                      // --- 📊 GLASSMOBILE STATS ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 20,
                                  offset: const Offset(0, 5))
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatStream("Catatan"),
                              _buildVerticalDivider(),
                              _ProfileStat(
                                  "Kegemaran",
                                  (userData['favorites'] as List? ?? [])
                                      .length
                                      .toString()),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- 🧩 MENU ITEMS ---
                      _MenuSection(
                        title: "Aktiviti Saya",
                        children: [
                          if (role == 'merchant')
                            _MenuItem(
                              icon: Icons.store_rounded,
                              title: "Papan Pemuka Pedagang",
                              color: Colors.orange,
                              onTap: () => Navigator.pushNamed(
                                  context, '/merchant_dashboard'),
                            ),
                          _MenuItem(
                              icon: Icons.post_add_rounded,
                              title: "Aktiviti Saya",
                              color: AppTheme.primaryColor,
                              onTap: () =>
                                  Navigator.pushNamed(context, '/myPosts')),
                          _MenuItem(
                              icon: Icons.favorite_rounded,
                              title: "Tempat Kegemaran Saya",
                              color: Colors.pinkAccent,
                              onTap: () =>
                                  Navigator.pushNamed(context, '/myFavorites')),
                          _MenuItem(
                              icon: Icons.confirmation_number_rounded,
                              title: "Ganjaran & Baucar Saya",
                              color: Colors.orange,
                              onTap: () =>
                                  Navigator.pushNamed(context, '/myVouchers')),
                          _MenuItem(
                              icon: Icons.notifications_active_rounded,
                              title: "Notifikasi",
                              color: Colors.orange,
                              onTap: () => Navigator.pushNamed(
                                  context, '/notifications')),
                          _MenuItem(
                              icon: Icons.add_location_alt_rounded,
                              title: "Cadangkan Tempat",
                              color: Colors.teal,
                              onTap: () => Navigator.pushNamed(
                                  context, '/suggestPlace')),
                        ],
                      ),

                      _MenuSection(
                        title: "Akaun & Tetapan",
                        children: [
                          _MenuItem(
                              icon: Icons.person_outline_rounded,
                              title: "Kemaskini Profil",
                              color: Colors.indigo,
                              onTap: () =>
                                  Navigator.pushNamed(context, '/editProfile')),
                          _MenuItem(
                              icon: Icons.settings_outlined,
                              title: "Pilihan",
                              color: Colors.blueGrey,
                              onTap: () => Navigator.pushNamed(
                                  context, '/settingsPage')),
                        ],
                      ),

                      const SizedBox(height: 120), // Bottom bar padding
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // --- 🌈 PREMIUM HEADER ---
          Container(
            height: 250,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Tetamu Muar",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                const Text(
                  "Terokai Muar seperti tidak pernah sebelum ini!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Log masuk untuk mengakses kegemaran, sertai perbualan komuniti, dan rancang perjalanan sempurna anda.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.getAdaptiveSubTextColor(context),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Log Masuk atau Daftar",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Alami warisan Muar dengan semua ciri diaktifkan.",
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildStatStream(String label) {
    return StreamBuilder<QuerySnapshot>(
      stream: _statsStream,
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return _ProfileStat(label, count.toString());
      },
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
        height: 30, width: 1, color: Colors.grey.withValues(alpha: 0.2));
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: AppTheme.getAdaptiveSubTextColor(context),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _MenuSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.getAdaptiveSubTextColor(context),
                  letterSpacing: 1.2)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem(
      {required this.icon,
      required this.title,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: AppTheme.subTextColor.withValues(alpha: 0.4)),
    );
  }
}
