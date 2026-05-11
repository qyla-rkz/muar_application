import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:muar_tourism_guide/modules/user/community/post_comments_page.dart';
import 'package:muar_tourism_guide/modules/user/community/user_post_create.dart';
import 'package:muar_tourism_guide/theme/app_theme.dart';
import 'package:muar_tourism_guide/modules/user/community/edit_post_page.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  String _searchQuery = "";
  String _selectedTag = "Semua";
  DateTimeRange? _selectedDateRange;
  final List<String> _tags = [
    "Semua",
    "Umum",
    "Event",
    "Makanan",
    "Membeli-belah",
    "Alam Semulajadi",
    "Warisan",
    "Budaya",
    "Lain-lain"
  ];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: AppTheme.lightTheme.copyWith(
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
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild/refetch
            await Future.delayed(const Duration(milliseconds: 800));
          },
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            slivers: [
              // 🛡️ COORDINATED APP BAR
              const SliverAppBar(
                title: Text("Komuniti"),
                centerTitle: true,
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: AppTheme.backgroundColor,
                surfaceTintColor: Colors.transparent,
                titleTextStyle: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),

              // 🔍 SEARCH & FILTER SECTION
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value.toLowerCase();
                                });
                              },
                              decoration: InputDecoration(
                                hintText: "Cari hantaran...",
                                prefixIcon: const Icon(Icons.search,
                                    color: AppTheme.subTextColor),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Date Picker Button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: IconButton(
                              icon: Icon(
                                _selectedDateRange != null
                                    ? Icons.calendar_month
                                    : Icons.calendar_today,
                                color: _selectedDateRange != null
                                    ? AppTheme.primaryColor
                                    : AppTheme.subTextColor,
                              ),
                              onPressed: _selectDateRange,
                              tooltip: "Tapis mengikut Tarikh",
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Show active date filter if selected
                    if (_selectedDateRange != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Chip(
                            label: Text(
                              "${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}",
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.primaryColor),
                            ),
                            onDeleted: () {
                              setState(() {
                                _selectedDateRange = null;
                              });
                            },
                            deleteIcon: const Icon(Icons.close, size: 16),
                            backgroundColor:
                                AppTheme.primaryColor.withValues(alpha: 0.1),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ),
                    // Tag Filters
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: _tags.map((tag) {
                          final isSelected = _selectedTag == tag;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(tag),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedTag = tag;
                                });
                              },
                              backgroundColor: Colors.white,
                              selectedColor:
                                  AppTheme.primaryColor.withValues(alpha: 0.2),
                              checkmarkColor: AppTheme.primaryColor,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.subTextColor,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // ✍️ CREATE POST HEADER
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: InkWell(
                    onTap: () {
                      if (FirebaseAuth.instance.currentUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Sila log masuk untuk menghantar")),
                        );
                        return;
                      }
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const UserPostCreatePage()));
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10)
                        ],
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppTheme.lightPrimary,
                            child: Icon(Icons.edit_note_rounded,
                                color: AppTheme.primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Text("Kongsi detik Muar anda...",
                              style: TextStyle(
                                  color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withValues(alpha: 0.6) ??
                                      Colors.grey,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 📜 POSTS STREAM
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('community_posts')
                    // ⚠️ DATE FILTER REMOVED per user request (Option B)
                    // .where('createdAt', isGreaterThan: ...)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                          child: Text(
                              "Tiada hantaran dijumpai. Mulakan perbualan!")),
                    );
                  }

                  // 🔍 CLIENT-SIDE FILTERING
                  final allPosts = snapshot.data!.docs;
                  final filteredPosts = allPosts.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title =
                        (data['title'] ?? '').toString().toLowerCase();
                    final description =
                        (data['description'] ?? '').toString().toLowerCase();
                    final tags = (data['tags'] ?? '').toString().toLowerCase();
                    final singleTag =
                        (data['tag'] ?? '').toString().toLowerCase();

                    // 1. Text Search
                    bool matchesSearch = _searchQuery.isEmpty ||
                        title.contains(_searchQuery) ||
                        description.contains(_searchQuery) ||
                        tags.contains(_searchQuery);

                    // 2. Tag Filter
                    final tagMap = {
                      "Warisan": "Heritage",
                      "Alam Semulajadi": "Nature",
                      "Makanan": "Makanan", // Same
                      "Membeli-belah": "Shopping",
                      "Budaya": "Culture",
                      "Lain-lain": "Other",
                      "Seni": "Arts",
                      "Aktiviti": "Activity",
                    };
                    final englishTag = tagMap[_selectedTag] ?? '';

                    bool matchesTag = _selectedTag == "Semua" ||
                        tags.contains(_selectedTag.toLowerCase()) ||
                        singleTag.contains(_selectedTag.toLowerCase()) ||
                        (englishTag.isNotEmpty &&
                            (tags.contains(englishTag.toLowerCase()) ||
                                singleTag.contains(englishTag.toLowerCase())));

                    // 3. Date Filter
                    final createdAt =
                        (data['createdAt'] as Timestamp?)?.toDate();
                    bool matchesDate = _selectedDateRange == null ||
                        (createdAt != null &&
                            createdAt.isAfter(_selectedDateRange!.start
                                .subtract(const Duration(seconds: 1))) &&
                            createdAt.isBefore(_selectedDateRange!.end
                                .add(const Duration(days: 1))));

                    return matchesSearch && matchesTag && matchesDate;
                  }).toList();

                  if (filteredPosts.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                          child: Text(
                              "Tiada hantaran yang sepadan dengan carian anda.")),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = filteredPosts[index];
                        final data = post.data() as Map<String, dynamic>;

                        return SocialCard(
                          post: post,
                          data: data,
                        );
                      },
                      childCount: filteredPosts.length,
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ));
  }
}

class SocialCard extends StatelessWidget {
  final DocumentSnapshot post;
  final Map<String, dynamic> data;
  final bool showActions;

  const SocialCard(
      {super.key,
      required this.post,
      required this.data,
      this.showActions = true});

  @override
  Widget build(BuildContext context) {
    final userNickname = data['userNickname'] ?? 'Tourist';
    final userPhotoBase64 = data['userPhotoBase64'];
    final userImageUrl = data['userImageUrl'];
    final description = data['description'] ?? '';
    final imageUrl = data['imageUrl'];
    final createdAt = data['createdAt'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  backgroundImage:
                      userImageUrl != null && userImageUrl.toString().isNotEmpty
                          ? NetworkImage(userImageUrl) as ImageProvider
                          : userPhotoBase64 != null
                              ? MemoryImage(base64Decode(userPhotoBase64))
                                  as ImageProvider
                              : null,
                  child: (userImageUrl == null ||
                              userImageUrl.toString().isEmpty) &&
                          userPhotoBase64 == null
                      ? Text(userNickname[0].toUpperCase(),
                          style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userNickname,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      if (createdAt != null)
                        Text(
                          "${createdAt.toDate().day} ${_getMonth(createdAt.toDate().month)} ${createdAt.toDate().year}",
                          style: TextStyle(
                              color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withValues(alpha: 0.6) ??
                                  Colors.grey,
                              fontSize: 12),
                        ),
                      if (data['location'] != null &&
                          data['location'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 14, color: AppTheme.primaryColor),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  data['location'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                _buildMoreMenu(context),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['title'] != null &&
                    data['title'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      data['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                Text(description,
                    style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: Theme.of(context).textTheme.bodyLarge?.color ??
                            Colors.black)),
              ],
            ),
          ),

          // Tags
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Wrap(
              spacing: 6,
              children: () {
                // Handle both 'tags' (from user posts, likely "Nature, Food")
                // and 'tag' (from admin posts, likely "News")
                String rawTags = data['tags'] as String? ?? '';
                String singleTag = data['tag'] as String? ?? '';

                final List<String> tagList = [];

                if (rawTags.isNotEmpty) {
                  tagList.addAll(rawTags.split(', '));
                }
                if (singleTag.isNotEmpty && !tagList.contains(singleTag)) {
                  tagList.add(singleTag);
                }

                return tagList
                    .map((tag) => Text("#$tag",
                        style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)))
                    .toList();
              }(),
            ),
          ),

          // Image
          if (imageUrl != null && imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: AppTheme.backgroundColor,
                      child: const Icon(Icons.broken_image_rounded)),
                ),
              ),
            ),

          // Actions
          if (showActions)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // LIKE BUTTON
                  _LikeButton(
                      post: post,
                      currentUserId: FirebaseAuth.instance.currentUser?.uid),
                  const SizedBox(width: 16),

                  // COMMENT BUTTON
                  _ActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: "Komen",
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PostCommentsPage(postId: post.id))),
                  ),
                  const Spacer(),

                  // BOOKMARK BUTTON
                  _BookmarkButton(
                      post: post,
                      currentUserId: FirebaseAuth.instance.currentUser?.uid),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMoreMenu(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserId != null && currentUserId == data['userId'];
    final canDelete = isOwner;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey),
      onSelected: (value) {
        if (value == 'edit') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditPostPage(postId: post.id, initialData: data),
            ),
          );
        } else if (value == 'delete') {
          _showDeleteConfirmation(context);
        } else if (value == 'report') {
          _showReportDialog(context);
        }
      },
      itemBuilder: (context) {
        final List<PopupMenuEntry<String>> items = [];

        if (isOwner) {
          items.add(const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, color: Colors.blue),
                SizedBox(width: 8),
                Text("Edit"),
              ],
            ),
          ));
        }

        if (canDelete) {
          items.add(const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 8),
                Text("Padam", style: TextStyle(color: Colors.red)),
              ],
            ),
          ));
        }

        if (!isOwner) {
          items.add(const PopupMenuItem(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.flag, color: Colors.black87),
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

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Padam Hantaran"),
        content: const Text(
            "Adakah anda pasti mahu memadam hantaran ini? Tindakan ini tidak boleh dibatalkan."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Delete all subcollections first
              final postRef = FirebaseFirestore.instance
                  .collection('community_posts')
                  .doc(post.id);

              // Delete all comments
              final comments = await postRef.collection('comments').get();
              for (var doc in comments.docs) {
                await doc.reference.delete();
              }

              // Delete the post itself
              await postRef.delete();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hantaran berjaya dipadam')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Padam", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Lapor Hantaran"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
              hintText: "Sebab melaporkan...", border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('reports').add({
                'postId': post.id,
                'reporterId': FirebaseAuth.instance.currentUser?.uid,
                'reason': reason,
                'createdAt': Timestamp.now(),
                'type': 'post'
              });

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Laporan dihantar. Terima kasih.")));
              }
            },
            child: const Text("Lapor"),
          ),
        ],
      ),
    );
  }

  String _getMonth(int m) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    if (m < 1 || m > 12) return "";
    return months[m - 1];
  }
}

class _LikeButton extends StatelessWidget {
  final DocumentSnapshot post;
  final String? currentUserId;

  const _LikeButton({required this.post, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final data = post.data() as Map<String, dynamic>;
    final likes = List<String>.from(data['likes'] ?? []);
    final isLiked = currentUserId != null && likes.contains(currentUserId);

    return InkWell(
      onTap: () async {
        if (currentUserId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Sila log masuk untuk menyukai hantaran")),
          );
          return;
        }
        final ref = FirebaseFirestore.instance
            .collection('community_posts')
            .doc(post.id);

        if (isLiked) {
          await ref.update({
            'likes': FieldValue.arrayRemove([currentUserId])
          });
        } else {
          await ref.update({
            'likes': FieldValue.arrayUnion([currentUserId])
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isLiked ? Colors.red : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              "${likes.length}",
              style: TextStyle(
                color: isLiked ? Colors.red : Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  final DocumentSnapshot post;
  final String? currentUserId;

  const _BookmarkButton({required this.post, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('bookmarks')
          .doc(post.id)
          .snapshots(),
      builder: (context, snapshot) {
        final isBookmarked = snapshot.hasData && snapshot.data!.exists;

        return IconButton(
          icon: Icon(
            isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: isBookmarked ? AppTheme.primaryColor : Colors.grey,
          ),
          onPressed: () async {
            if (currentUserId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text("Sila log masuk untuk menanda buku hantaran")),
              );
              return;
            }
            final ref = FirebaseFirestore.instance
                .collection('users')
                .doc(currentUserId)
                .collection('bookmarks')
                .doc(post.id);

            if (isBookmarked) {
              await ref.delete();
            } else {
              await ref.set({
                'postId': post.id,
                'createdAt': FieldValue.serverTimestamp(),
              });
            }
          },
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.6) ??
                    Colors.grey),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.6) ??
                        Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
