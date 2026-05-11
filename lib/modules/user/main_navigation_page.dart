import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:muar_tourism_guide/theme/app_theme.dart';

// Import your user modules
import 'explorer/explorer_page.dart';
import 'community/community_page.dart';
import 'event/event_page.dart';
import 'profile_tools/profile_page.dart';

class MainNavigationPage extends StatefulWidget {
  final int initialIndex;
  final DateTime? initialDate;
  const MainNavigationPage(
      {super.key, this.initialIndex = 0, this.initialDate});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  List<Widget> get _screens => [
        const ExplorerPage(),
        const CommunityPage(),
        EventPage(initialDate: widget.initialDate),
        const ProfilePage(),
      ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent system back-navigation to login
      child: Scaffold(
        extendBody: true, // 🚨 CRITICAL for floating bar
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                height: 75,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.explore_rounded, 'Teroka'),
                    _buildNavItem(1, Icons.forum_rounded, 'Komuniti'),
                    _buildNavItem(2, Icons.calendar_today_rounded, 'Acara'),
                    _buildNavItem(3, Icons.person_rounded, 'Profil'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onTabTapped(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.subTextColor,
              size: 26,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppTheme.primaryColor : AppTheme.subTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
