import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:muar_tourism_guide/theme/app_theme.dart';
import 'package:muar_tourism_guide/modules/user/community/post_comments_page.dart';
import 'package:muar_tourism_guide/modules/user/community/edit_post_page.dart';

class MyPostsPage extends StatelessWidget {
  const MyPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Sila log masuk.')));
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text("Aktiviti Saya"),
          centerTitle: true,
          backgroundColor: AppTheme.backgroundColor,
          surfaceTintColor: Colors.transparent,
          bottom: const TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: [
              Tab(text: "Kiriman", icon: Icon(Icons.article_rounded)),
              Tab(text: "Suka", icon: Icon(Icons.favorite_rounded)),
              Tab(text: "Penanda Buku", icon: Icon(Icons.bookmark_rounded)),
              Tab(text: "Ulasan", icon: Icon(Icons.rate_review_rounded)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. My Posts
            _PostList(
              query: FirebaseFirestore.instance
                  .collection('community_posts')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true),
              emptyMessage: "Anda belum menghantar sebarang kiriman lagi.",
              icon: Icons.post_add_rounded,
            ),

            // 2. My Likes
            _PostList(
              query: FirebaseFirestore.instance
                  .collection('community_posts')
                  .where('likes', arrayContains: user.uid)
                  .orderBy('createdAt', descending: true),
              emptyMessage: "Anda belum menyukai sebarang kiriman lagi.",
              icon: Icons.favorite_border_rounded,
            ),

            // 3. My Bookmarks
            _BookmarkList(userId: user.uid),

            // 4. My Reviews
            _ReviewList(userId: user.uid),
          ],
        ),
      ),
    );
  }
}

class _ReviewList extends StatelessWidget {
  final String userId;
  const _ReviewList({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('reviews')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          if (snapshot.error.toString().contains('failed-precondition')) {
            return const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  "Mengindeks... Sila tunggu beberapa minit.",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return Center(child: Text('Ralat: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.rate_review_outlined,
            message: "Anda belum menulis sebarang ulasan lagi.",
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (context.mounted) (context as Element).markNeedsBuild();
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppTheme.primaryColor,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return _ReviewCard(review: docs[index]);
            },
          ),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final QueryDocumentSnapshot review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final data = review.data() as Map<String, dynamic>;
    final placeName = data['placeName'] ?? 'Unknown Place';
    final comment = data['comment'] ?? '';
    final rating = (data['rating'] ?? 0).toDouble();
    final createdAt = data['createdAt'] as Timestamp?;
    final dateStr = createdAt != null
        ? DateFormat('dd MMM yyyy').format(createdAt.toDate())
        : 'Baru-baru ini';

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
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(placeName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            _buildActionMenu(context, data),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateStr,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(comment,
                style: TextStyle(
                    color: AppTheme.getAdaptiveTextColor(context),
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenu(BuildContext context, Map<String, dynamic> data) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
      padding: EdgeInsets.zero,
      onSelected: (value) {
        if (value == 'edit') {
          _showEditDialog(context, data);
        } else if (value == 'delete') {
          _confirmDelete(context);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue, size: 18),
              SizedBox(width: 8),
              Text("Edit"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text("Padam", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> data) {
    final commentController = TextEditingController(text: data['comment']);
    double currentRating = (data['rating'] ?? 0).toDouble();
    final existingImageUrl = data['imageUrl'];
    XFile? pickedImage;
    bool imageDeleted = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Edit Ulasan"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display current or picked image
                if (pickedImage != null ||
                    (!imageDeleted &&
                        existingImageUrl != null &&
                        existingImageUrl.isNotEmpty))
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: pickedImage != null
                            ? Image.file(
                                File(pickedImage!.path),
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                existingImageUrl,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 16,
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                size: 16, color: Colors.white),
                            onPressed: () => setDialogState(() {
                              pickedImage = null;
                              imageDeleted = true;
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setDialogState(() {
                        pickedImage = picked;
                        imageDeleted = false;
                      });
                    }
                  },
                  icon: const Icon(Icons.add_a_photo_rounded),
                  label: Text(pickedImage != null ||
                          (!imageDeleted &&
                              existingImageUrl != null &&
                              existingImageUrl.isNotEmpty)
                      ? "Tukar Foto"
                      : "Tambah Foto"),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => currentRating = index + 1.0),
                      child: Icon(
                        index < currentRating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 32,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Fikiran anda...",
                    border: OutlineInputBorder(),
                  ),
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
                Navigator.pop(context); // Close dialog

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mengemas kini ulasan...')),
                );

                try {
                  String? updatedImageUrl = existingImageUrl;

                  if (imageDeleted) {
                    updatedImageUrl = null;
                  }

                  // Upload new image if picked
                  if (pickedImage != null) {
                    final ref = FirebaseStorage.instance.ref().child(
                        'review_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
                    await ref.putFile(File(pickedImage!.path));
                    updatedImageUrl = await ref.getDownloadURL();
                  }

                  await review.reference.update({
                    'rating': currentRating,
                    'comment': comment,
                    'imageUrl': updatedImageUrl,
                  });

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ulasan berjaya dikemas kini!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ralat mengemas kini ulasan: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text("Kemaskini"),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Padam Ulasan"),
        content: const Text("Adakah anda pasti mahu memadamkan ulasan ini?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              await review.reference.delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Padam", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _PostList extends StatelessWidget {
  final Query query;
  final String emptyMessage;
  final IconData icon;

  const _PostList(
      {required this.query, required this.emptyMessage, required this.icon});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _EmptyState(icon: icon, message: emptyMessage);
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (context.mounted) (context as Element).markNeedsBuild();
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppTheme.primaryColor,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final post = docs[index];
              final data = post.data() as Map<String, dynamic>? ?? {};
              return _ActivityCard(
                key: ValueKey(post.id),
                post: post,
                userInfo: "Dihantar oleh ${data['userNickname'] ?? 'Pengguna'}",
              );
            },
          ),
        );
      },
    );
  }
}

class _BookmarkList extends StatelessWidget {
  final String userId;
  const _BookmarkList({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookmarkedDocs = snapshot.data?.docs ?? [];
        if (bookmarkedDocs.isEmpty) {
          return const _EmptyState(
              icon: Icons.bookmark_border_rounded,
              message: "Anda belum menanda sebarang aktiviti lagi.");
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (context.mounted) (context as Element).markNeedsBuild();
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppTheme.primaryColor,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: bookmarkedDocs.length,
            itemBuilder: (context, index) {
              final entry =
                  bookmarkedDocs[index].data() as Map<String, dynamic>;
              final postId = entry['postId'];

              if (postId == null) return const SizedBox.shrink();

              // Fetch the actual post data for each bookmark
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('community_posts')
                    .doc(postId)
                    .snapshots(),
                builder: (context, postSnapshot) {
                  if (!postSnapshot.hasData ||
                      (postSnapshot.data?.exists ?? false) == false) {
                    return const SizedBox.shrink(); // Post might be deleted
                  }

                  final post = postSnapshot.data;
                  if (post == null) return const SizedBox.shrink();

                  final data = post.data() as Map<String, dynamic>? ?? {};

                  return _ActivityCard(
                    key: ValueKey("bookmark_${post.id}"),
                    post: post,
                    userInfo:
                        "Dihantar oleh ${data['userNickname'] ?? 'Pengguna'}",
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final DocumentSnapshot post;
  final String userInfo;

  const _ActivityCard({super.key, required this.post, required this.userInfo});

  @override
  Widget build(BuildContext context) {
    final data = post.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Kiriman Tanpa Tajuk';
    final subtitle = data['description'] ?? '';

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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostCommentsPage(postId: post.id),
          ),
        ),
        contentPadding: const EdgeInsets.all(12),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: AppTheme.getAdaptiveSubTextColor(context),
                    fontSize: 14)),
            const SizedBox(height: 4),
            if (data['location'] != null &&
                data['location'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 12, color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      data['location'],
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              ),
            Text(userInfo,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (value) async {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EditPostPage(postId: post.id, initialData: data),
                ),
              );
            } else if (value == 'delete') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Padam Kiriman"),
                  content: const Text(
                      "Adakah anda pasti mahu memadamkan kiriman ini?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Batal")),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Padam",
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await FirebaseFirestore.instance
                    .collection('community_posts')
                    .doc(post.id)
                    .delete();
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text("Edit"),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text("Padam", style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
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
