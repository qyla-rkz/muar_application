import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:muar_tourism_guide/theme/app_theme.dart';
import 'package:muar_tourism_guide/modules/user/explorer/search_page.dart';
import 'package:muar_tourism_guide/modules/user/event/event_page.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🏞️ WARM GRADIENT BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
          ),

          // ✨ DECORATIVE CIRCLES
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),

          // 🏛️ CONTENT OVERLAY
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // 🚩 LOGO CONTAINER
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Muar Flag
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    'assets/muar_flag.png',
                                    height: 80,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Vertical Divider
                                Container(
                                  height: 60,
                                  width: 1,
                                  color: Colors.grey.withValues(alpha: 0.3),
                                ),
                                const SizedBox(width: 20),
                                // Jom Muar Logo
                                Image.asset(
                                  'assets/icon.png',
                                  height: 80,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 🚩 APP TITLE
                        const Text(
                          "Jom MUAR",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const Text(
                          "Muar Lokasi Pelancongan Lengkap",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 🔍 JOM TEROKA GRID
                        const Text(
                          "Jom ke Muar hari ini!",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildCategoryGrid(context),
                        const SizedBox(height: 40),
                        const Spacer(),

                        // 🔐 ACTION PANEL (GLASSMORPHIC)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    "Pelawat",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pushNamed(
                                        context, '/tourist_login'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppTheme.primaryColor,
                                      elevation: 0,
                                      minimumSize:
                                          const Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    child: const Text(
                                      "Akses PELANCONG",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pushNamed(
                                        context, '/merchant_login'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppTheme.primaryColor,
                                      elevation: 0,
                                      minimumSize:
                                          const Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    child: const Text(
                                      "Portal BISNES",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _buildGridItem(
          context,
          label: "Jom WARISAN\nMUAR",
          icon: Icons.account_balance,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      const SearchPage(initialCategory: 'Jom WARISAN MUAR'))),
        ),
        _buildGridItem(
          context,
          label: "Jom RASA\nMUAR",
          icon: Icons.restaurant,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      const SearchPage(initialCategory: 'Jom RASA MUAR'))),
        ),
        _buildGridItem(
          context,
          label: "Jom ALAM\nMUAR",
          icon: Icons.forest,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      const SearchPage(initialCategory: 'Jom ALAM MUAR'))),
        ),
        _buildGridItem(
          context,
          label: "Jom SENI\nMUAR",
          icon: Icons.palette,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SearchPage(initialCategory: 'Jom SENI MUAR'))),
        ),
        _buildGridItem(
          context,
          label: "Jom BELI-BELAH\nMUAR",
          icon: Icons.shopping_bag,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      const SearchPage(initialCategory: 'Jom BELI-BELAH MUAR'))),
        ),
        _buildGridItem(
          context,
          label: "Jom ACARA\nMUAR",
          icon: Icons.event,
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const EventPage())),
        ),
        _buildGridItem(
          context,
          label: "Jom STAY\nMUAR",
          icon: Icons.hotel,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      const SearchPage(initialCategory: 'Jom STAY MUAR'))),
        ),
      ],
    );
  }

  Widget _buildGridItem(BuildContext context,
      {required String label,
      required IconData icon,
      required VoidCallback onTap}) {
    // Calculate width to fit 3 items per row with spacing
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - (24 * 2) - (12 * 2)) / 3.1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: itemWidth,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
