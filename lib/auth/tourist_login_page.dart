import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:muar_tourism_guide/services/notification_service.dart';
import 'package:muar_tourism_guide/theme/app_theme.dart';

class TouristLoginPage extends StatefulWidget {
  const TouristLoginPage({super.key});

  @override
  State<TouristLoginPage> createState() => _TouristLoginPageState();
}

class _TouristLoginPageState extends State<TouristLoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String errorMsg = '';
  bool loading = false;

  void loginUser() async {
    setState(() {
      loading = true;
      errorMsg = '';
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null || !user.emailVerified) {
        setState(() {
          errorMsg = "Sila sahkan emel anda sebelum log masuk.";
          loading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role = doc.data()?['role'];
      // Allow both 'user' and 'merchant' roles to access the Tourist side
      if (doc.exists && (role == 'user' || role == 'merchant')) {
        if (!mounted) return;
        await NotificationService().saveTokenToDatabase();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() => errorMsg = "Akses peranan tidak dibenarkan.");
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      setState(() => errorMsg = "Log masuk gagal: ${e.toString()}");
    }

    if (mounted) setState(() => loading = false);
  }

  void resetPassword() {
    if (emailController.text.isNotEmpty) {
      FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailController.text.trim())
          .then((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            const SnackBar(content: Text("Emel set semula dihantar.")));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Masukkan emel anda untuk set semula kata laluan.")),
      );
    }
  }

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: Icon(icon ?? Icons.person),
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.grey, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 6,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_pin_circle_rounded,
                      size: 60,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Log Masuk Pelancong",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    buildTextField("Emel", emailController, icon: Icons.email),
                    buildTextField(
                      "Kata Laluan",
                      passwordController,
                      obscure: true,
                      icon: Icons.lock,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: resetPassword,
                        child: const Text("Lupa Kata Laluan?"),
                      ),
                    ),
                    loading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: loginUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                "Log Masuk",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 10),
                    Text(
                      errorMsg,
                      style: TextStyle(
                        color: errorMsg.contains("failed")
                            ? Colors.red
                            : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/tourist_signup'),
                      child:
                          const Text("Tiada akaun? Daftar sebagai Pelancong"),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/'),
                      child: const Text(
                        "← Kembali ke Skrin Utama",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
