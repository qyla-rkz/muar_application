import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muar_tourism_guide/theme/app_theme.dart';

class EditPostPage extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> initialData;

  const EditPostPage({
    super.key,
    required this.postId,
    required this.initialData,
  });

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  late TextEditingController titleController;
  late TextEditingController descController;
  late TextEditingController locationController;
  // late TextEditingController tagsController; // Removed

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

  @override
  void initState() {
    super.initState();
    titleController =
        TextEditingController(text: widget.initialData['title'] ?? '');
    descController =
        TextEditingController(text: widget.initialData['description'] ?? '');
    locationController =
        TextEditingController(text: widget.initialData['location'] ?? '');

    // Pre-fill selected tags with mapping for legacy English tags
    final existingTags = widget.initialData['tags'] as String? ?? '';
    if (existingTags.isNotEmpty) {
      final tagMap = {
        'Food': 'Makanan',
        'Culture': 'Budaya',
        'Other': 'Lain-lain',
        'Nature': 'Alam Semulajadi',
        'Heritage': 'Warisan',
        'Shopping': 'Membeli-belah',
        'Hidden Gem': 'Permata Tersembunyi'
      };

      for (var t in existingTags.split(', ')) {
        final translated = tagMap[t] ?? t;
        if (availableTags.contains(translated)) {
          selectedTags.add(translated);
        }
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      labelStyle: const TextStyle(color: AppTheme.primaryColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => selectedImage = File(pickedFile.path));
    }
  }

  Future<void> updatePost() async {
    setState(() => loading = true);

    String? imageUrl = widget.initialData['imageUrl'];
    if (selectedImage != null) {
      final ref = FirebaseStorage.instance.ref().child(
          'community_posts/${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = ref.putFile(
        selectedImage!,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;

      // Retry logic for download URL
      int retries = 3;
      while (retries > 0) {
        try {
          imageUrl = await snapshot.ref.getDownloadURL();
          break;
        } catch (e) {
          retries--;
          if (retries == 0) rethrow;
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    await FirebaseFirestore.instance
        .collection('community_posts')
        .doc(widget.postId)
        .update({
      'title': titleController.text.trim(),
      'description': descController.text.trim(),
      'location': locationController.text.trim(),
      'tags': selectedTags.join(', '),
      'imageUrl': imageUrl,
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Kemas Kini Hantaran"),
        automaticallyImplyLeading: false, // Non-whitelisted: remove back button
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
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Pilih Imej Baharu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.buttonTextColor,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(selectedImage!,
                      width: double.infinity, fit: BoxFit.fitWidth),
                )
              else if (widget.initialData['imageUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(widget.initialData['imageUrl'],
                      width: double.infinity, fit: BoxFit.fitWidth),
                ),
              const SizedBox(height: 20),
              loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: updatePost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.buttonTextColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Kemas Kini Hantaran',
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
