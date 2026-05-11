import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muar_tourism_guide/theme/app_theme.dart';

class UserPostCreatePage extends StatefulWidget {
  const UserPostCreatePage({super.key});

  @override
  State<UserPostCreatePage> createState() => _UserPostCreatePageState();
}

class _UserPostCreatePageState extends State<UserPostCreatePage> {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final locationController = TextEditingController();

  File? selectedImage;
  bool loading = false;
  final List<String> availableTags = [
    'Makanan',
    'Budaya',
    'Lain-lain',
    'Alam Semulajadi',
    'Warisan',
    'Membeli-belah',
    'Permata Tersembunyi'
  ];
  final List<String> selectedTags = [];

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
    );
  }

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => selectedImage = File(pickedFile.path));
    }
  }

  Future<void> createPost() async {
    if (titleController.text.isEmpty &&
        descController.text.isEmpty &&
        selectedImage == null) {
      return;
    }
    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = userDoc.data();
      final nickname = data?['name'] ?? 'Anonymous';
      final userImageUrl = data?['imageUrl'];

      String? postImageUrl;
      if (selectedImage != null) {
        final ref = FirebaseStorage.instance.ref().child(
            'community_posts/${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = ref.putFile(
          selectedImage!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final snapshot = await uploadTask;

        // Retry logic for download URL - sometimes it's not ready instantly
        int retries = 3;
        while (retries > 0) {
          try {
            postImageUrl = await snapshot.ref.getDownloadURL();
            break;
          } catch (e) {
            retries--;
            if (retries == 0) rethrow;
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }

      final title = titleController.text.trim();
      final description = descController.text.trim();

      await FirebaseFirestore.instance.collection('community_posts').add({
        'userId': user.uid,
        'userNickname': nickname,
        'userImageUrl': userImageUrl,
        'title': title,
        'description': description,
        'imageUrl': postImageUrl,
        'tags': selectedTags.join(', '),
        'location': locationController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal menghantar: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Cipta Hantaran"),
        automaticallyImplyLeading: true, // Restored back button
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                  controller: titleController,
                  decoration: _inputDecoration('Tajuk')),
              const SizedBox(height: 12),
              TextField(
                  controller: descController,
                  maxLines: 4,
                  decoration: _inputDecoration('Penerangan')),
              const SizedBox(height: 12),
              TextField(
                  controller: locationController,
                  decoration: _inputDecoration('Lokasi')),
              const SizedBox(height: 20),
              const Text("Pilih Tag:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: availableTags.map((tag) {
                  final isSelected = selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (bool value) {
                      setState(() {
                        if (value) {
                          selectedTags.add(tag);
                        } else {
                          selectedTags.remove(tag);
                        }
                      });
                    },
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                    checkmarkColor: AppTheme.primaryColor,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Pilih Imej'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.buttonTextColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(selectedImage!,
                      width: double.infinity, fit: BoxFit.fitWidth),
                ),
              const SizedBox(height: 20),
              loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: createPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.buttonTextColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Hantar',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
