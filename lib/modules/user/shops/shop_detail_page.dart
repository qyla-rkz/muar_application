import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../widgets/image_slideshow.dart';
import 'package:muar_tourism_guide/services/notification_service.dart';

class ShopDetailPage extends StatefulWidget {
  final String shopId;
  const ShopDetailPage({super.key, required this.shopId});

  @override
  State<ShopDetailPage> createState() => _ShopDetailPageState();
}

class _ShopDetailPageState extends State<ShopDetailPage> {
  String? _claimingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil Kedai")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('shops')
            .doc(widget.shopId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || (snapshot.data?.exists ?? false) == false) {
            return const Scaffold(
                body: Center(child: Text("Kedai tidak dijumpai")));
          }

          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 800));
            },
            color: Colors.orange,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data['imageUrl'] != null)
                    ImageSlideshow(
                      imageUrls: [data['imageUrl'].toString()],
                      height: 200,
                      autoSlide: false,
                    ),
                  const SizedBox(height: 16),
                  Text(data['shopName'] ?? 'Kedai Tanpa Nama',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(data['description'] ?? 'Tiada penerangan disediakan.',
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  const Text("Produk",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .where('merchantId', isEqualTo: widget.shopId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final products = snapshot.data?.docs ?? [];
                      if (products.isEmpty) {
                        return const Text("No products listed yet.");
                      }
                      return Column(
                        children: products.map((doc) {
                          final p = doc.data() as Map<String, dynamic>? ?? {};
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (p['imageUrl'] != null)
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                    child: Image.network(
                                      p['imageUrl'],
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ListTile(
                                  title: Text(p['name'] ?? 'Item',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("RM ${p['price']}",
                                          style: const TextStyle(
                                              color: Colors.brown,
                                              fontWeight: FontWeight.bold)),
                                      if (p['details'] != null &&
                                          p['details'].isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4.0),
                                          child: Text(p['details'],
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text("App User Exclusive Rewards",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.orange)),
                  const Text(
                      "Claim your hidden gem rewards only through this app!",
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('vouchers')
                        .where('merchantId', isEqualTo: widget.shopId)
                        .where('isActive', isEqualTo: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final vouchers = snapshot.data?.docs ?? [];
                      if (vouchers.isEmpty) {
                        return const Text(
                            "Tiada kupon istimewa tersedia untuk kedai ini.");
                      }
                      return Column(
                        children: vouchers.map((doc) {
                          final rawData =
                              doc.data() as Map<String, dynamic>? ?? {};
                          final v = Map<String, dynamic>.from(rawData);
                          v['id'] = doc.id;

                          return Card(
                            key: ValueKey(doc.id),
                            elevation: 3,
                            shadowColor: Colors.orange.withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            color: Colors.orange.shade50,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                      backgroundColor: Colors.orange,
                                      child: Icon(Icons.confirmation_number,
                                          color: Colors.white)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(v['code'] ?? 'CODE',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.2,
                                                fontSize: 18,
                                                color: Colors.deepOrange)),
                                        Text(v['discount'] ?? 'Discount',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13)),
                                        if (v['expiryDate'] != null)
                                          Text(
                                            "Tamat: ${v['expiryDate'] is Timestamp ? DateFormat('yyyy-MM-dd').format((v['expiryDate'] as Timestamp).toDate()) : 'Mengemaskini...'}",
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                  ),
                                  _claimingId == v['id']
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.orange))
                                      : ElevatedButton(
                                          onPressed: () => _claimVoucher(v),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size(60, 36),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20)),
                                            textStyle: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          child: const Text("Claim"),
                                        ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _claimVoucher(Map<String, dynamic> voucher) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sila log masuk untuk menebus baucar")),
        );
      }
      return;
    }

    setState(() => _claimingId = voucher['id']);

    try {
      // 1. CHECK IF ALREADY CLAIMED
      final existing = await FirebaseFirestore.instance
          .collection('user_vouchers')
          .where('userId', isEqualTo: user.uid)
          .where('code', isEqualTo: voucher['code'])
          .get();

      if (existing.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Anda sudah menebus kupon ini!")),
          );
        }
        setState(() => _claimingId = null);
        return;
      }

      // 2. SAVE CLAIM
      debugPrint(
          "DEBUG: Saving voucher for user ${user.uid} with code ${voucher['code']}");

      final merchantId = voucher['merchantId'] ?? widget.shopId;
      final docRef =
          await FirebaseFirestore.instance.collection('user_vouchers').add({
        'userId': user.uid,
        'voucherId': voucher['id'] ?? 'unknown',
        'merchantId': merchantId,
        'code': voucher['code'] ?? 'N/A',
        'discount': voucher['discount'] ?? 'Special Reward',
        'expiryDate': voucher['expiryDate'],
        'status': 'claimed',
        'claimedAt': FieldValue.serverTimestamp(),
      });

      // Notify Merchant
      if (merchantId != null && merchantId.toString().isNotEmpty) {
        NotificationService.sendNotification(
          receiverId: merchantId,
          title: 'Baucar Ditebus!',
          body: 'Seorang pelanggan telah menebus baucar ${voucher['code']} anda.',
        );
      }

      debugPrint("DEBUG: Voucher saved with ID: ${docRef.id}");

      if (mounted) {
        // Show double confirmation for debug
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Claimed! ID: ${docRef.id}"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: "VIEW",
              textColor: Colors.white,
              onPressed: () => Navigator.pushNamed(context, '/myVouchers'),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("DEBUG: Error claiming: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error claiming: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _claimingId = null);
      }
    }
  }
}
