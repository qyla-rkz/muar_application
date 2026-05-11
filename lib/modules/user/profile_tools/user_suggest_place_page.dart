import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:muar_tourism_guide/theme/app_theme.dart';
import '../../../widgets/image_slideshow.dart';
import 'package:muar_tourism_guide/services/notification_service.dart';

class UserSuggestPlacePage extends StatefulWidget {
  const UserSuggestPlacePage({super.key});

  @override
  State<UserSuggestPlacePage> createState() => _UserSuggestPlacePageState();
}

class _UserSuggestPlacePageState extends State<UserSuggestPlacePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final List<String> _galleryUrls = [];
  bool _isUploading = false;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory;
  final List<String> _categories = [
    'Permata Tersembunyi',
    'Alam Semulajadi',
    'Makanan',
    'Warisan',
    'Membeli-belah',
    'Lain-lain'
  ];

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      if (_galleryUrls.length >= 10) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maksimum 10 foto dibenarkan')),
          );
        }
        return;
      }

      setState(() => _isUploading = true);

      final file = File(image.path);
      final fileName =
          'suggestion_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref =
          FirebaseStorage.instance.ref().child('place_suggestions/$fileName');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      if (mounted) {
        setState(() {
          _galleryUrls.add(url);
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imej berjaya dimuat naik!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ralat memuat naik imej: $e')),
        );
      }
    }
  }

  Future<void> _submitSuggestion() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sila pilih kategori")),
      );
      return;
    }

    setState(() => _isSaving = true);

    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    final suggestionData = {
      'name': _nameController.text.trim(),
      'category': _selectedCategory,
      'description': _descController.text.trim(),
      'address': _addressController.text.trim(),
      'imageUrls': _galleryUrls,
      'status': 'pending',
      'submittedBy': uid,
      'submittedAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('places').add(suggestionData);

      // Notify Admin
      NotificationService.sendNotification(
        receiverId: 'admin',
        title: 'Cadangan Tempat Baharu',
        body: 'Seorang pengguna telah mencadangkan tempat baharu: ${_nameController.text.trim()}',
        type: 'alert',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cadangan dihantar untuk semakan!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ralat menghantar cadangan: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cadangkan Tempat",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Kongsi Permata Tersembunyi di Muar!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Cadangan anda akan disemak oleh pasukan kami sebelum ditambah ke halaman Peneroka.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: AppTheme.inputDecoration(
                  "Nama Tempat",
                  prefixIcon: Icons.place_rounded,
                ),
                validator: (v) => v!.isEmpty ? "Nama tempat diperlukan" : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                decoration: AppTheme.inputDecoration(
                  "Kategori",
                  prefixIcon: Icons.category_rounded,
                ),
                validator: (v) => v == null ? "Sila pilih kategori" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: AppTheme.inputDecoration(
                  "Penerangan",
                  prefixIcon: Icons.description_rounded,
                ),
                validator: (v) => v!.isEmpty ? "Penerangan diperlukan" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: AppTheme.inputDecoration(
                  "Lokasi/Alamat",
                  prefixIcon: Icons.location_on_rounded,
                ),
                validator: (v) =>
                    v!.isEmpty ? "Alamat/Lokasi diperlukan" : null,
              ),
              const SizedBox(height: 24),

              Text(
                "Foto (Pilihan) - ${_galleryUrls.length}/10",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              // Gallery Preview
              if (_galleryUrls.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ImageSlideshow(
                      imageUrls: _galleryUrls,
                      autoSlide: false,
                      showDots: true,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Nota: Leret untuk melihat semua foto yang dimuat naik.",
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _galleryUrls.asMap().entries.map((entry) {
                        int index = entry.key;
                        String url = entry.value;
                        return Stack(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(url),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _galleryUrls.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickAndUploadImage,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_a_photo_rounded),
                  label: const Text("Tambah Foto"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (_isSaving || _isUploading) ? null : _submitSuggestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    elevation: 4,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Hantar Cadangan",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
