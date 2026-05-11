import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:muar_tourism_guide/theme/app_theme.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  String selectedState = '';
  File? newImage;
  String? existingImageUrl;
  bool loading = false;
  String errorMsg = '';

  final List<String> states = [
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Penang',
    'Perak',
    'Perlis',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
    'Kuala Lumpur',
    'Putrajaya',
    'Labuan'
  ];

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();

    if (data != null) {
      nameController.text = data['name'] ?? '';
      emailController.text = FirebaseAuth.instance.currentUser?.email ?? '';
      selectedState = data['location'] ?? '';
      existingImageUrl = data['imageUrl'];
      setState(() {});
    }
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => newImage = File(picked.path));
    }
  }

  Future<void> syncUserPosts(
      String uid, String newName, String? newPhotoUrl) async {
    final batch = FirebaseFirestore.instance.batch();

    // 1. Sync User's Posts
    final postsQuery = await FirebaseFirestore.instance
        .collection('community_posts')
        .where('userId', isEqualTo: uid)
        .get();

    for (final doc in postsQuery.docs) {
      batch.update(doc.reference, {
        'userNickname': newName,
        if (newPhotoUrl != null) 'userImageUrl': newPhotoUrl,
      });
    }

    // 2. Sync ALL Comments by this user (including on others' posts)
    // Note: This uses collectionGroup which might require a Firestore index
    final commentsQuery = await FirebaseFirestore.instance
        .collectionGroup('comments')
        .where('userId', isEqualTo: uid)
        .get();

    for (final doc in commentsQuery.docs) {
      batch.update(doc.reference, {
        'userNickname': newName,
        if (newPhotoUrl != null) 'userImageUrl': newPhotoUrl,
      });
    }

    await batch.commit();
  }

  Future<void> saveChanges() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      loading = true;
      errorMsg = '';
    });

    try {
      String? imageUrl;
      if (newImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('$uid.jpg');
        await ref.putFile(newImage!);
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': nameController.text.trim(),
        'location': selectedState,
        if (imageUrl != null) 'imageUrl': imageUrl,
      });

      await syncUserPosts(
          uid, nameController.text.trim(), imageUrl ?? existingImageUrl);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null && emailController.text.trim() != user.email) {
        await user.verifyBeforeUpdateEmail(emailController.text.trim());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "📧 Emel pengesahan telah dihantar. Emel akan dikemaskini selepas pengesahan.",
            ),
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Profil berjaya dikemaskini")),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => errorMsg = "❌ Gagal dikemaskini: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? avatarImage;
    if (newImage != null) {
      avatarImage = FileImage(newImage!);
    } else if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
      avatarImage = NetworkImage(existingImageUrl!);
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔷 HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryDarkColor,
                  ],
                ),
              ),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Back Button
                  Positioned(
                    top: 0,
                    left: 0,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  // Centered Avatar Column
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20), // Top spacing
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                )
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundImage: avatarImage,
                              child: avatarImage == null
                                  ? Icon(Icons.person,
                                      size: 50,
                                      color: Theme.of(context).iconTheme.color)
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Material(
                              elevation: 4,
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: pickImage,
                                customBorder: const CircleBorder(),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      size: 20, color: AppTheme.primaryColor),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Kemaskini Profil",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 🔷 FORM CARD
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: "Nama Pengguna",
                          prefixIcon: Icon(Icons.person,
                              color: Theme.of(context).iconTheme.color),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: "Emel",
                          prefixIcon: Icon(Icons.email,
                              color: Theme.of(context).iconTheme.color),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue:
                            selectedState.isNotEmpty ? selectedState : null,
                        items: states
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedState = val ?? ''),
                        decoration: InputDecoration(
                          labelText: "Negeri",
                          prefixIcon: Icon(Icons.location_on,
                              color: Theme.of(context).iconTheme.color),
                        ),
                      ),
                      const SizedBox(height: 24),
                      loading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: saveChanges,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: AppTheme.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "Simpan Perubahan",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                      if (errorMsg.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorMsg,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
