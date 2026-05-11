import 'package:flutter/material.dart';
import 'package:muar_tourism_guide/services/notification_service.dart';
import 'package:muar_tourism_guide/theme/app_theme.dart';

class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  bool _isSending = false;

  Future<void> _sendTestNotification(String type) async {
    setState(() => _isSending = true);
    
    try {
      await NotificationService.sendNotification(
        receiverId: 'admin', // Testing as admin
        title: 'Ujian Notifikasi Real-time',
        body: 'Ini adalah notifikasi ujian untuk kategori $type.',
        type: type,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notifikasi $type telah dihantar!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ralat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ujian Notifikasi"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pilih jenis notifikasi untuk diuji:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildTestButton("Admin Alert", 'alert', Colors.red),
            const SizedBox(height: 12),
            _buildTestButton("Pengumuman", 'announcement', Colors.orange),
            const SizedBox(height: 12),
            _buildTestButton("Kiriman Baharu", 'new_post_alert', Colors.blue),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              "Nota: Notifikasi ini akan dihantar ke Firestore (koleksi 'notifications') dan juga melalui Push Notification (jika API aktif).",
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String label, String type, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSending ? null : () => _sendTestNotification(type),
        icon: const Icon(Icons.send_rounded),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
