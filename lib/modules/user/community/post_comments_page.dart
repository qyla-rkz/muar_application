import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muar_tourism_guide/theme/app_theme.dart';
import 'package:muar_tourism_guide/services/notification_service.dart';
import 'package:muar_tourism_guide/modules/user/community/community_page.dart';

class PostCommentsPage extends StatefulWidget {
  final String postId;

  const PostCommentsPage({super.key, required this.postId});

  @override
  State<PostCommentsPage> createState() => _PostCommentsPageState();
}

class _PostCommentsPageState extends State<PostCommentsPage> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? editingCommentId;
  String? replyToId;
  String? replyToName;
  String? replyTargetId;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Comments", style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('community_posts')
            .doc(widget.postId)
            .snapshots(),
        builder: (context, postSnapshot) {
          if (!postSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!postSnapshot.data!.exists) {
            return const Center(child: Text("Post not found."));
          }

          final postDoc = postSnapshot.data!;
          final postData = postDoc.data() as Map<String, dynamic>;

          return Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('community_posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .orderBy('createdAt', descending: false)
                      .snapshots(),
                  builder: (context, commentsSnapshot) {
                    if (!commentsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final comments = commentsSnapshot.data!.docs;

                    return RefreshIndicator(
                        onRefresh: () async {
                          setState(() {});
                          await Future.delayed(
                              const Duration(milliseconds: 500));
                        },
                        color: AppTheme.primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: 1 + comments.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: SocialCard(
                                  post: postDoc,
                                  data: postData,
                                  showActions: false,
                                ),
                              );
                            }

                            if (index == comments.length + 1) {
                              return const SizedBox(height: 80);
                            }

                            final commentIndex = index - 1;
                            if (comments.isEmpty && commentIndex == 0) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Text(
                                    "No comments yet. Be the first to comment!",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              );
                            }

                            if (comments.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            final comment = comments[commentIndex];
                            final data = comment.data() as Map<String, dynamic>;

                            final isCommentOwner =
                                data['userId'] == currentUser?.uid;
                            final canDelete = isCommentOwner;
                            final commentId = comment.id;
                            final userNickname =
                                data['userNickname']?.toString() ?? 'Anonymous';
                            final commentText = data['text']?.toString() ?? '';
                            final replyToNameText =
                                data['replyToName']?.toString();

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primaryColor,
                                  backgroundImage: data['userImageUrl'] !=
                                              null &&
                                          data['userImageUrl']
                                              .toString()
                                              .isNotEmpty
                                      ? NetworkImage(
                                              data['userImageUrl'].toString())
                                          as ImageProvider
                                      : data['userPhotoBase64'] != null
                                          ? MemoryImage(
                                              base64Decode(
                                                  data['userPhotoBase64']),
                                            ) as ImageProvider
                                          : null,
                                  child: (data['userImageUrl'] == null ||
                                              data['userImageUrl']
                                                  .toString()
                                                  .isEmpty) &&
                                          data['userPhotoBase64'] == null
                                      ? Text(
                                          userNickname[0].toUpperCase(),
                                          style: const TextStyle(
                                              color: Colors.white),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  userNickname,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (data['replyTo'] != null &&
                                        replyToNameText != null)
                                      Text(
                                        "Reply to: $replyToNameText",
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(commentText),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd MMM yyyy, hh:mm a').format(
                                        (data['createdAt'] as Timestamp)
                                            .toDate(),
                                      ),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      setState(() {
                                        editingCommentId = commentId;
                                        _commentController.text = commentText;
                                      });
                                    } else if (value == 'delete') {
                                      await FirebaseFirestore.instance
                                          .collection('community_posts')
                                          .doc(widget.postId)
                                          .collection('comments')
                                          .doc(commentId)
                                          .delete();
                                    } else if (value == 'reply') {
                                      _prepareReply(commentId, userNickname,
                                          data['userId']);
                                    } else if (value == 'report') {
                                      _showReportDialog(commentId, commentText);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                        value: 'reply', child: Text("Reply")),
                                    if (isCommentOwner)
                                      const PopupMenuItem(
                                          value: 'edit', child: Text("Edit")),
                                    if (canDelete)
                                      const PopupMenuItem(
                                          value: 'delete',
                                          child: Text("Delete")),
                                    const PopupMenuItem(
                                        value: 'report', child: Text("Report")),
                                  ],
                                ),
                              ),
                            );
                          },
                        ));
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (replyToName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          color: AppTheme.lightPrimary,
                          child: Row(
                            children: [
                              const Icon(Icons.reply_rounded,
                                  size: 16, color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Replying to $replyToName",
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() {
                                  replyToId = null;
                                  replyToName = null;
                                  replyTargetId = null;
                                  _commentController.clear();
                                }),
                                child:
                                    const Icon(Icons.close_rounded, size: 18),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  hintText: replyToName != null
                                      ? "Write your reply..."
                                      : "Write a comment...",
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: const BorderSide(
                                        color: AppTheme.primaryColor, width: 1),
                                  ),
                                ),
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => _handleSendOrEdit(currentUser),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  editingCommentId != null
                                      ? Icons.check
                                      : Icons.send_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleSendOrEdit(User? currentUser) async {
    if (currentUser == null) return;

    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final data = userDoc.data();
      final nickname = data?['name']?.toString() ?? 'User';
      final photoBase64 = data?['photoBase64']?.toString();
      final userImageUrl = data?['imageUrl']?.toString();

      final bool wasEditing = editingCommentId != null;

      if (editingCommentId != null) {
        await FirebaseFirestore.instance
            .collection('community_posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(editingCommentId)
            .update({'text': text});
      } else {
        final postDoc = await FirebaseFirestore.instance
            .collection('community_posts')
            .doc(widget.postId)
            .get();
        final postOwnerId = postDoc.data()?['userId'];

        await FirebaseFirestore.instance
            .collection('community_posts')
            .doc(widget.postId)
            .collection('comments')
            .add({
          'text': text,
          'userId': currentUser.uid,
          'userNickname': nickname,
          'userPhotoBase64': photoBase64,
          'userImageUrl': userImageUrl,
          'createdAt': Timestamp.now(),
          'replyTo': replyToId,
          'replyToName': replyToName,
          'replyTargetId': replyTargetId,
        });

        if (replyToId != null &&
            replyTargetId != null &&
            replyTargetId != currentUser.uid) {
          FirebaseFirestore.instance.collection('notifications').add({
            'receiverId': replyTargetId,
            'senderId': currentUser.uid,
            'senderName': nickname,
            'type': 'reply',
            'message': 'replied to your comment: "$text"',
            'postId': widget.postId,
            'createdAt': Timestamp.now(),
            'isRead': false,
          });

          NotificationService.sendNotification(
            receiverId: replyTargetId!,
            title: "New Reply",
            body: "$nickname replied: $text",
          );
        } else if (postOwnerId != null && postOwnerId != currentUser.uid) {
          FirebaseFirestore.instance.collection('notifications').add({
            'receiverId': postOwnerId,
            'senderId': currentUser.uid,
            'senderName': nickname,
            'type': 'comment',
            'message': 'commented on your post: "$text"',
            'postId': widget.postId,
            'createdAt': Timestamp.now(),
            'isRead': false,
          });

          NotificationService.sendNotification(
            receiverId: postOwnerId,
            title: "New Comment",
            body: "$nickname commented: $text",
          );
        }
      }

      if (mounted) {
        setState(() {
          editingCommentId = null;
          replyToId = null;
          replyToName = null;
          replyTargetId = null;
        });
        _commentController.clear();
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(wasEditing ? "Comment updated!" : "Comment posted!"),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Action failed: $e")),
        );
      }
    }
  }

  void _prepareReply(
      String replyToCommentId, String nickname, String replyUserId) {
    setState(() {
      replyToId = replyToCommentId;
      replyToName = nickname;
      replyTargetId = replyUserId;
      _commentController.text = "@$nickname ";
    });
  }

  void _showReportDialog(String commentId, String commentText) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report Comment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Comment: $commentText"),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Explain why',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              Navigator.of(dialogContext).pop();

              await FirebaseFirestore.instance
                  .collection('reported_comments')
                  .add({
                'commentId': commentId,
                'postId': widget.postId,
                'reason': reason,
                'reportedBy': _auth.currentUser?.uid,
                'reportedAt': Timestamp.now(),
              });

              // Report created in 'reported_comments' collection

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Comment reported')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.buttonTextColor,
            ),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }
}
