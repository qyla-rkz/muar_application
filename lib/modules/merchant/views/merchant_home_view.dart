import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../scanner/merchant_scanner_page.dart';

class MerchantHomeView extends StatelessWidget {
  const MerchantHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text("Selamat kembali,",
                  style: GoogleFonts.outfit(
                      color: Colors.grey[600], fontSize: 16)),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('shops')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  String name = "Merchant";
                  if (snapshot.hasData &&
                      snapshot.data != null &&
                      snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    name = data?['shopName'] ?? "Pedagang";
                  }
                  return Text(name,
                      style: GoogleFonts.outfit(
                          fontSize: 28, fontWeight: FontWeight.bold));
                },
              ),
              const SizedBox(height: 24),

              // Quick Action - Scanner
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MerchantScannerPage())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange[800]!, Colors.orange[400]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8))
                      ]),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.qr_code_scanner,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Imbas Baucar",
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            Text("Ketik untuk menebus ganjaran",
                                style: GoogleFonts.outfit(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Text("Gambaran Keseluruhan",
                  style: GoogleFonts.outfit(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Analytics Grid
              Row(
                children: [
                  Expanded(
                      child: _AnalyticsCard(
                    title: "Ditebus",
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    stream: FirebaseFirestore.instance
                        .collection('user_vouchers')
                        .where('status', isEqualTo: 'used')
                        .where('merchantId', isEqualTo: user.uid)
                        .snapshots()
                        .map((s) => s.docs.length.toString()),
                  )),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _AnalyticsCard(
                    title: "Aktif",
                    icon: Icons.confirmation_number_outlined,
                    color: Colors.blue,
                    stream: FirebaseFirestore.instance
                        .collection('vouchers')
                        .where('merchantId', isEqualTo: user.uid)
                        .snapshots()
                        .map((s) => s.docs.length.toString()),
                  )),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _AnalyticsCard(
                    title: "Produk",
                    icon: Icons.shopping_bag_outlined,
                    color: Colors.purple,
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .where('merchantId', isEqualTo: user.uid)
                        .snapshots()
                        .map((s) => s.docs.length.toString()),
                  )),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()), // Placeholder for balance
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Stream<String> stream;

  const _AnalyticsCard(
      {required this.title,
      required this.icon,
      required this.color,
      required this.stream});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          StreamBuilder<String>(
              stream: stream,
              initialData: "-",
              builder: (context, snapshot) {
                return Text(snapshot.data ?? "-",
                    style: GoogleFonts.outfit(
                        fontSize: 24, fontWeight: FontWeight.bold));
              }),
          Text(title,
              style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }
}
