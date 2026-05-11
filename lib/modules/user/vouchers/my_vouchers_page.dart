import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class MyVouchersPage extends StatelessWidget {
  const MyVouchersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Baucar Saya")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text("Sila log masuk untuk melihat ganjaran anda.",
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppTheme.primaryColor,
          title: Text("Ganjaran Saya",
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: "Ganjaran Aktif"),
              Tab(text: "Rekod"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _VoucherListTab(userId: user.uid, status: 'claimed'),
            _VoucherListTab(userId: user.uid, statuses: const [
              'used',
              'expired'
            ]), // History includes used & expired
          ],
        ),
      ),
    );
  }
}

class _VoucherListTab extends StatelessWidget {
  final String userId;
  final String? status;
  final List<String>? statuses;

  const _VoucherListTab({required this.userId, this.status, this.statuses});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('user_vouchers')
        .where('userId', isEqualTo: userId);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    } else if (statuses != null) {
      query = query.where('status', whereIn: statuses);
    }

    // Sort active by expiry date (soonest first)
    // if (status == 'claimed') {
    //   query = query.orderBy('expiryDate', descending: false);
    // } else {
    //   query = query.orderBy('usedAt', descending: true); // Show most recently used first
    // }
    // Note: To use orderBy with where, we need composite indexes.
    // Implementing client-side sort for now to avoid immediate index requirement if not set.

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Sesuatu yang tidak kena',
                    style: GoogleFonts.outfit(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        // Client-side filtering/sorting if needed can go here

        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Force rebuild to re-subscribe stream
            if (context.mounted) (context as Element).markNeedsBuild();
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppTheme.primaryColor,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            itemCount: docs.length,
            separatorBuilder: (c, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final voucherId = docs[index].id;
              return VoucherTicketCard(
                data: data,
                docId: voucherId,
                isHistory: status != 'claimed',
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    bool isActiveTab = status == 'claimed';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActiveTab
                ? Icons.local_activity_outlined
                : Icons.history_edu_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            isActiveTab ? "Tiada ganjaran aktif lagi" : "Tiada rekod ganjaran",
            style: GoogleFonts.outfit(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            isActiveTab
                ? "Terokai tempat untuk mencari permata tersembunyi!"
                : "Ganjaran yang telah anda gunakan akan muncul di sini.",
            style: GoogleFonts.outfit(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class VoucherTicketCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool isHistory;

  const VoucherTicketCard({
    super.key,
    required this.data,
    required this.docId,
    required this.isHistory,
  });

  @override
  Widget build(BuildContext context) {
    // Parsing Data
    final String title = data['discount']?.toString() ?? 'Ganjaran Khas';
    final String code = data['code']?.toString() ?? '----';
    final String status = data['status']?.toString() ?? 'tidak diketahui';
    // final Timestamp? expiry = data['expiryDate'] as Timestamp?;
    // final Timestamp? usedAt = data['usedAt'] as Timestamp?;

    // Safely handling timestamps
    DateTime? expiryDate;
    if (data['expiryDate'] != null && data['expiryDate'] is Timestamp) {
      expiryDate = (data['expiryDate'] as Timestamp).toDate();
    }

    DateTime? usedDate;
    if (data['usedAt'] != null && data['usedAt'] is Timestamp) {
      usedDate = (data['usedAt'] as Timestamp).toDate();
    }

    final bool isExpired = status == 'expired';
    final bool isUsed = status == 'used';

    Color primaryColor = isHistory ? Colors.grey : AppTheme.primaryColor;
    Color bgColor = isHistory ? Colors.grey[100]! : Colors.white;
    Color textColor = isHistory ? Colors.grey[600]! : Colors.black87;

    return GestureDetector(
      onTap: (!isHistory && !isExpired)
          ? () => _showRedemptionSheet(context, code, title, docId)
          : null,
      child: ClipPath(
        clipper: TicketClipper(),
        child: Container(
          height: 140, // Fixed height for ticket look
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: isHistory ? Border.all(color: Colors.grey[300]!) : null,
          ),
          child: Row(
            children: [
              // Left side: Icon/Brand
              Container(
                width: 100,
                decoration: BoxDecoration(
                  color: isHistory
                      ? Colors.grey[300]
                      : AppTheme.primaryColor.withValues(alpha: 0.1),
                  border: Border(
                      right: BorderSide(
                          color: Colors.grey[300]!,
                          style: BorderStyle.none)), // Visual separation
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isUsed
                          ? Icons.check_circle
                          : (isExpired ? Icons.cancel : Icons.stars),
                      color: primaryColor,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isUsed
                          ? "DIGUNAKAN"
                          : (isExpired ? "TAMAT TEMPOH" : "SAH"),
                      style: GoogleFonts.outfit(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // Dashed Line visual
              CustomPaint(
                size: const Size(1, 140),
                painter: DashedLinePainter(color: Colors.grey[300]!),
              ),

              // Right side: Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              isHistory ? Colors.grey[200] : Colors.orange[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: isHistory
                                  ? Colors.transparent
                                  : Colors.orange[200]!),
                        ),
                        child: Text(
                          "CODE: $code",
                          style: GoogleFonts.robotoMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isHistory ? Colors.grey : Colors.deepOrange,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            isUsed && usedDate != null
                                ? "Digunakan pada ${DateFormat('dd MMM yyyy').format(usedDate)}"
                                : (expiryDate != null
                                    ? "Tamat ${DateFormat('dd MMM yyyy').format(expiryDate)}"
                                    : "Tiada Tarikh Tamat"),
                            style: GoogleFonts.outfit(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRedemptionSheet(
      BuildContext context, String code, String title, String docId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Tebus Ganjaran",
                      style: GoogleFonts.outfit(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tunjukkan kod QR ini kepada pedagang",
                      style: GoogleFonts.outfit(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 20)
                        ],
                      ),
                      child: QrImageView(
                        data: code,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      code,
                      style: GoogleFonts.robotoMono(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4),
                    ),
                    const SizedBox(height: 8),
                    Text(title,
                        style: GoogleFonts.outfit(
                            fontSize: 18, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _confirmUsage(context, docId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme
                      .primaryColor, // Use generic green for action or keep theme
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  "Tanda sebagai Digunakan",
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text("Batal", style: GoogleFonts.outfit(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmUsage(BuildContext context, String docId) async {
    // Show confirmation dialog before actual commit
    bool? confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
              title: const Text("Sahkan Penebusan"),
              content: const Text(
                  "Adakah anda pasti mahu menanda baucar ini sebagai digunakan? Tindakan ini tidak boleh dibatalkan."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text("Batal")),
                TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text("Sahkan",
                        style: TextStyle(color: Colors.red))),
              ],
            ));

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('user_vouchers')
          .doc(docId)
          .update({
        'status': 'used',
        'usedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Baucar berjaya ditebus!"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ralat: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// --- Custom Painters for Ticket UI --- //

class TicketClipper extends CustomClipper<Path> {
  final double punchRadius;

  TicketClipper({this.punchRadius = 10.0});

  @override
  Path getClip(Size size) {
    Path path = Path();

    path.lineTo(0.0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0.0);

    path.addOval(Rect.fromCircle(
        center: Offset(0.0, size.height / 2), radius: punchRadius));
    path.addOval(Rect.fromCircle(
        center: Offset(size.width, size.height / 2), radius: punchRadius));

    return path..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 3, startY = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
