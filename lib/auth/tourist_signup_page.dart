import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:muar_tourism_guide/services/notification_service.dart';
import 'package:muar_tourism_guide/theme/app_theme.dart';

class TouristSignupPage extends StatefulWidget {
  const TouristSignupPage({super.key});

  @override
  State<TouristSignupPage> createState() => _TouristSignupPageState();
}

class _TouristSignupPageState extends State<TouristSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final nicknameController = TextEditingController();
  final passwordController = TextEditingController();
  File? profileImage;
  String errorMsg = '';
  bool loading = false;

  Future<void> pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => profileImage = File(pickedFile.path));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tiada imej dipilih.")),
        );
      }
    } catch (e) {
      debugPrint("Image Picker Error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memilih imej: $e")),
      );
    }
  }

  Future<void> signUp() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => loading = true);

      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;
      String? imageUrl;

      if (profileImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('$uid.jpg');
        await ref.putFile(profileImage!);
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'nickname': nicknameController.text.trim(),
        'role': 'user',
        'requestedRole': 'user',
        'createdAt': Timestamp.now(),
        'imageUrl': imageUrl,
      });

      await FirebaseAuth.instance.currentUser?.sendEmailVerification();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "✅ Akaun berjaya dicipta! Emel pengesahan telah dihantar.")),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (FirebaseAuth.instance.currentUser != null) {
        await NotificationService().saveTokenToDatabase();
      }
      if (mounted) Navigator.pushReplacementNamed(context, '/tourist_login');
    } catch (e) {
      debugPrint("SignUp Error: $e");
      if (mounted) {
        setState(() => errorMsg = "❌ Pendaftaran gagal: ${e.toString()}");
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
    String? Function(String?)? validator,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon ?? Icons.person),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.black),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 206, 33, 33),
                  Color.fromARGB(255, 214, 217, 20),
                  Color.fromARGB(255, 255, 255, 255),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: const Text("Daftar Akaun Pelancong",
              style: TextStyle(
                  color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: profileImage != null
                            ? FileImage(profileImage!)
                            : null,
                        child: profileImage == null
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.grey)
                            : null,
                      ),
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color.fromARGB(255, 113, 49, 49),
                        child: Icon(Icons.camera_alt,
                            size: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              buildTextField("Nama Penuh", nameController,
                  validator: (val) =>
                      val == null || val.isEmpty ? "Masukkan nama anda" : null),
              buildTextField("No. Telefon", phoneController,
                  icon: Icons.phone,
                  validator: (val) => val == null || val.length < 10
                      ? "Masukkan no. telefon yang sah"
                      : null),
              buildTextField("Emel", emailController,
                  icon: Icons.email,
                  validator: (val) => val == null || !val.contains("@")
                      ? "Masukkan emel yang sah"
                      : null),
              buildTextField("Nama Samaran", nicknameController,
                  validator: (val) => val == null || val.isEmpty
                      ? "Masukkan nama samaran"
                      : null),
              buildTextField("Kata Laluan", passwordController,
                  obscure: true,
                  icon: Icons.lock,
                  validator: (val) => val == null || val.length < 6
                      ? "Kata laluan mestilah sekurang-kurangnya 6 aksara"
                      : null),
              const SizedBox(height: 30),
              loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: signUp,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor:
                              const Color.fromARGB(255, 113, 49, 49),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          "Cipta Akaun Pelancong",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
              const SizedBox(height: 10),
              Text(
                errorMsg,
                style: TextStyle(
                  color:
                      errorMsg.contains("failed") ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
