import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:muar_tourism_guide/services/notification_service.dart';

class MerchantScannerPage extends StatefulWidget {
  const MerchantScannerPage({super.key});

  @override
  State<MerchantScannerPage> createState() => _MerchantScannerPageState();
}

class _MerchantScannerPageState extends State<MerchantScannerPage> {
  bool _isProcessing = false;
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _processCode(String code) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // Slight delay to prevent double scans
    await _controller.stop();

    try {
      // Query Firestore for the voucher code
      // We search across all user_vouchers for now.
      // In a real app, we might check if this voucher belongs to THIS merchant.
      // Using FirebaseAuth directly:
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        if (mounted) {
          _showResultDialog(
              title: "Ralat",
              message: "Anda mesti log masuk sebagai pedagang.",
              isSuccess: false);
        }
        return;
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('user_vouchers')
          .where('code', isEqualTo: code)
          .where('merchantId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (!mounted) return;

      if (querySnapshot.docs.isEmpty) {
        _showResultDialog(
            title: "Baucar Tidak Sah",
            message: "Kod tidak dijumpai: $code",
            isSuccess: false);
      } else {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        final status = data['status'];
        // final discount = data['discount']; // Unused

        if (status == 'claimed') {
          await _redeemVoucher(doc.id, data);
        } else if (status == 'used') {
          _showResultDialog(
              title: "Telah Digunakan",
              message: "Baucar ini telah pun ditebus.",
              isSuccess: false);
        } else if (status == 'expired') {
          _showResultDialog(
              title: "Tamat Tempoh",
              message: "Baucar ini telah tamat tempoh.",
              isSuccess: false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showResultDialog(
            title: "Ralat",
            message: "Sesuatu yang tidak kena: $e",
            isSuccess: false);
      }
    }
  }

  Future<void> _redeemVoucher(String docId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('user_vouchers')
          .doc(docId)
          .update({
        'status': 'used',
        'usedAt': FieldValue.serverTimestamp(),
      });

      // Notify User
      final userId = data['userId'];
      if (userId != null && userId.toString().isNotEmpty) {
        NotificationService.sendNotification(
          receiverId: userId,
          title: 'Baucar Berjaya Digunakan!',
          body: 'Baucar ${data['code']} anda telah berjaya digunakan. Terima kasih!',
        );
      }
      if (mounted) {
        _showResultDialog(
            title: "Berjaya",
            message: "Baucar ditebus secara automatik!",
            isSuccess: true);
      }
    } catch (e) {
      _showResultDialog(
          title: "Ralat", message: e.toString(), isSuccess: false);
    }
  }

  void _showResultDialog(
      {required String title,
      required String message,
      required bool isSuccess}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title,
            style: TextStyle(color: isSuccess ? Colors.green : Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: const Text("Imbas Seterusnya"),
          )
        ],
      ),
    );
  }

  void _resetScanner() {
    setState(() => _isProcessing = false);
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Imbas Baucar")),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null && !_isProcessing) {
              _processCode(barcode.rawValue!);
              break;
            }
          }
        },
      ),
    );
  }
}
