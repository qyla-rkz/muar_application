import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:muar_tourism_guide/theme/app_theme.dart';
import 'package:muar_tourism_guide/modules/user/community/post_comments_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _userRole = 'user';
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _userRole = doc.data()?['role'] ?? 'user';
          _isLoadingRole = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingRole = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Sila log masuk.')));
    }

    if (_isLoadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // List of receiver IDs to watch
    List<String> receiverIds = [user.uid, 'all'];
    if (_userRole == 'admin') {
      receiverIds.add('admin');
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Notifikasi"),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
            color: AppTheme.getAdaptiveTextColor(context),
            fontSize: 22,
            fontWeight: FontWeight.bold),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('receiverId', whereIn: receiverIds)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Ralat: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const _EmptyState(
                icon: Icons.notifications_none_rounded,
                message: "Tiada notifikasi baharu.");
          }

          return RefreshIndicator(
              onRefresh: () async {
                await _fetchUserRole();
              },
              color: AppTheme.primaryColor,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final type = data['type'];

                  String title = data['title'] ?? "Notifikasi";
                  IconData icon;
                  Color color;

                  switch (type) {
                    case 'announcement':
                      icon = Icons.campaign_rounded;
                      color = Colors.orange;
                      break;
                    case 'new_post_alert':
                      icon = Icons.rss_feed_rounded;
                      color = Colors.blue;
                      break;
                    case 'reply':
                      icon = Icons.reply_rounded;
                      color = Colors.green;
                      break;
                    case 'alert':
                      icon = Icons.warning_amber_rounded;
                      color = Colors.red;
                      break;
                    default:
                      icon = Icons.notifications_rounded;
                      color = AppTheme.primaryColor;
                  }

                  return _ActivityCard(
                    title: title,
                    subtitle: data['message'] ?? "",
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 20,
                      ),
                    ),
                    onTap: () {
                      final postId = data['postId'] ?? data['relatedId'];
                      if (postId != null && postId.toString().isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostCommentsPage(postId: postId),
                          ),
                        );
                      }
                    },
                  );
                },
              ));
        },
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? leading;
  final VoidCallback onTap;

  const _ActivityCard(
      {required this.title,
      required this.subtitle,
      this.leading,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: leading,
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: AppTheme.getAdaptiveSubTextColor(context),
                  fontSize: 14)),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 64, color: AppTheme.subTextColor.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(
                  color: AppTheme.getAdaptiveSubTextColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
