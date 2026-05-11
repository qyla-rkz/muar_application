import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:muar_tourism_guide/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('notificationsEnabled') ?? true;
    if (!mounted) return;
    setState(() {
      notificationsEnabled = value;
    });
  }

  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
  }

  Future<void> _requestMerchantAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'requestedRole': 'merchant'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permohonan dihantar! Sila tunggu kelulusan.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting request: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount(String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Padam Akaun"),
        content: const Text(
            "Adakah anda pasti mahu memadamkan akaun anda secara kekal?\n\nTindakan ini akan membuang semua catatan, ulasan, dan baucar anda. Ia tidak boleh dibatalkan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Padam Selamanya"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _deleteAccount(uid);
    }
  }

  Future<void> _deleteAccount(String uid) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Delete Community Posts
      final postsSnapshot = await firestore
          .collection('community_posts')
          .where('userId', isEqualTo: uid)
          .get();
      for (var doc in postsSnapshot.docs) {
        // Retrieve comments for each post
        final commentsSnapshot =
            await doc.reference.collection('comments').get();
        for (var commentDoc in commentsSnapshot.docs) {
          await commentDoc.reference.delete();
        }
        await doc.reference.delete();
      }

      // 2. Delete User Vouchers
      final vouchersSnapshot = await firestore
          .collection('user_vouchers')
          .where('userId', isEqualTo: uid)
          .get();
      for (var doc in vouchersSnapshot.docs) {
        await doc.reference.delete();
      }

      // 3. Delete Reviews (Using Collection Group Query)
      try {
        final reviewsSnapshot = await firestore
            .collectionGroup('reviews')
            .where('userId', isEqualTo: uid)
            .get();
        for (var doc in reviewsSnapshot.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint("Error deleting reviews: $e");
      }

      // 5. Delete User Profile
      await firestore.collection('users').doc(uid).delete();

      // 6. Delete Shop if merchant
      await firestore.collection('shops').doc(uid).delete();

      // 7. Delete Auth Account
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
      }

      if (mounted) {
        Navigator.pop(context); // Remove loading dialog
        Navigator.pushReplacementNamed(context, '/'); // Go to welcome
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Akaun berjaya dipadamkan.")),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loading dialog
        if (e.toString().contains('requires-recent-login')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    "Keselamatan: Sila log keluar dan log masuk semula untuk memadamkan akaun anda.")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Ralat memadamkan akaun: $e")),
          );
        }
      }
    }
  }

  void _showCustomerServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Khidmat Pelanggan'),
        content: const Text(
          "Perlukan bantuan?\n\n📧 Emel: support@muartourism.app\n📞 Telefon: +60 123-456-789\n🕒 Waktu: Isnin–Jumaat, 9am–6pm",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // headerColor logic removed - now using default Theme colors
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Tetapan'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔷 Preferences Section
          const Text(
            'Pilihan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: SwitchListTile(
              title: const Text('Aktifkan Notifikasi'),
              value: notificationsEnabled,
              onChanged: (val) async {
                setState(() => notificationsEnabled = val);
                await _saveNotificationPreference(val);
              },
              secondary: Icon(Icons.notifications_active,
                  color: Theme.of(context).iconTheme.color),
            ),
          ),

          const SizedBox(height: 24),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Colors.grey),
          const SizedBox(height: 24),

          // 🔷 Merchant Section
          const Text(
            'Akaun Pedagang',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseAuth.instance.currentUser?.uid != null
                ? FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .snapshots()
                : null,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Card(
                    child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator())));
              }

              final data = snapshot.data!.data() as Map<String, dynamic>?;
              final role = data?['role'];
              final requestedRole = data?['requestedRole'];

              if (role == 'merchant') {
                return Card(
                  color: Colors.green.shade50,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.verified, color: Colors.green),
                    title: const Text('Anda adalah Pedagang yang Disahkan'),
                    subtitle: const Text(
                        'Log masuk ke Portal Pedagang untuk mengurus kedai anda'),
                    onTap: () {
                      Navigator.pushNamed(context, '/merchant_login');
                    },
                  ),
                );
              } else if (requestedRole == 'merchant') {
                return Card(
                  color: Colors.orange.shade50,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: const ListTile(
                    leading: Icon(Icons.hourglass_top, color: Colors.orange),
                    title: Text('Permohonan Sedang Diproses'),
                    subtitle: Text('Menunggu kelulusan...'),
                  ),
                );
              } else {
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.store, color: Colors.blueGrey),
                    title: const Text('Mohon Akaun Pedagang'),
                    subtitle: const Text('Jual produk dan perkhidmatan anda'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Menjadi Pedagang"),
                          content: const Text(
                              "Adakah anda ingin memohon akaun Pedagang? "
                              "Anda perlu disahkan."),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text("Batal")),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _requestMerchantAccess();
                              },
                              child: const Text("Mohon"),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 24),
          const Divider(height: 1, color: Colors.grey),
          const SizedBox(height: 24),

          // 🔷 Support Section
          const Text(
            'Sokongan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.support_agent, color: Colors.blue),
                  title: const Text('Khidmat Pelanggan'),
                  onTap: _showCustomerServiceDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.bug_report_rounded, color: Colors.purple),
                  title: const Text('Uji Notifikasi (Developer)'),
                  onTap: () => Navigator.pushNamed(context, '/test_notifications'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Colors.grey),
          const SizedBox(height: 24),

          // 🔷 Account Section
          const Text(
            'Akaun',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.red),
                  title: const Text('Log Keluar'),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_forever_rounded,
                      color: Colors.red.shade900),
                  title: const Text('Padam Akaun'),
                  onTap: () {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      _confirmDeleteAccount(uid);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
