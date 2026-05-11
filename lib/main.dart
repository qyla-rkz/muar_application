import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

// AUTH SCREENS
import 'auth/welcome_screen.dart';
import 'auth/tourist_login_page.dart';
import 'auth/tourist_signup_page.dart';
import 'auth/merchant_login_page.dart';
import 'auth/merchant_signup_page.dart';

// USER MODULES
import 'modules/user/main_navigation_page.dart';
import 'modules/user/explorer/search_page.dart';
import 'modules/user/explorer/explorer_page.dart';
import 'modules/user/explorer/place_detail_page.dart';
import 'modules/user/community/community_page.dart';
import 'modules/user/community/user_post_create.dart';
import 'modules/user/community/edit_post_page.dart';
import 'modules/user/event/event_page.dart';
import 'modules/user/profile_tools/edit_profile_page.dart';
import 'modules/user/profile_tools/settings_page.dart';
import 'modules/user/profile_tools/my_posts_page.dart';
import 'modules/user/profile_tools/notifications_page.dart';
import 'modules/user/profile_tools/my_favorites_page.dart';
import 'modules/user/profile_tools/user_suggest_place_page.dart';
import 'modules/user/profile_tools/notification_test_page.dart';

import 'modules/merchant/merchant_dashboard_page.dart';
import 'modules/user/shops/shop_directory_page.dart';
import 'modules/user/shops/shop_detail_page.dart';
import 'modules/user/vouchers/my_vouchers_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  // await ThemeController.loadTheme(); // Removed
  // Initialize Notifications
  await NotificationService().initialize();

  // Initialize Date Formatting for Malay
  await initializeDateFormatting('ms_MY', null);
  Intl.defaultLocale = 'ms_MY';

  runApp(const MuarTourismApp());
}

class MuarTourismApp extends StatelessWidget {
  const MuarTourismApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JomMuar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // darkTheme: AppTheme.darkTheme, // Removed per user request
      themeMode: ThemeMode.light, // Locked to Light Mode
      locale: const Locale('ms', 'MY'),
      supportedLocales: const [
        Locale('ms', 'MY'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/tourist_login': (context) => const TouristLoginPage(),
        '/tourist_signup': (context) => const TouristSignupPage(),
        '/merchant_login': (context) => const MerchantLoginPage(),
        '/merchant_signup': (context) => const MerchantSignupPage(),
        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            return MainNavigationPage(
              initialIndex: args['index'] ?? 0,
              initialDate: args['date'],
            );
          }
          return MainNavigationPage(initialIndex: args as int? ?? 0);
        },
        '/search': (context) => const SearchPage(),
        '/community': (context) => const CommunityPage(),
        '/create_post': (context) => const UserPostCreatePage(),
        '/editProfile': (context) => const EditProfilePage(),
        '/settingsPage': (context) => const SettingsPage(),
        '/myPosts': (context) => const MyPostsPage(),
        '/notifications': (context) => const NotificationsPage(),
        '/myFavorites': (context) => const MyFavoritesPage(),
        '/suggestPlace': (context) => const UserSuggestPlacePage(),
        '/events': (context) => const EventPage(),
        '/explorer': (context) => const ExplorerPage(),
        '/shops': (context) => const ShopDirectoryPage(),
        '/merchant_dashboard': (context) => const MerchantDashboardPage(),
        '/myVouchers': (context) => const MyVouchersPage(),
        '/test_notifications': (context) => const NotificationTestPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/edit_post') {
          final args = settings.arguments as Map<String, dynamic>?;

          if (args == null ||
              !args.containsKey('postId') ||
              !args.containsKey('data')) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('Invalid post data')),
              ),
            );
          }
          return MaterialPageRoute(
            builder: (_) => EditPostPage(
              postId: args['postId'],
              initialData: args['data'],
            ),
          );
        }

        if (settings.name == '/placeDetail') {
          final placeId = settings.arguments as String?;
          if (placeId == null) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('Invalid place ID')),
              ),
            );
          }
          return MaterialPageRoute(
            builder: (_) => PlaceDetailPage(placeId: placeId),
          );
        }

        if (settings.name == '/shopDetail') {
          final shopId = settings.arguments as String?;
          if (shopId == null) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('Invalid shop ID')),
              ),
            );
          }
          return MaterialPageRoute(
            builder: (_) => ShopDetailPage(shopId: shopId),
          );
        }

        return null; // Implicitly returns null if no match, invalid for route generator? No, onGenerateRoute can return null to use onUnknownRoute or throw error. But here signature is Route<dynamic>? so null is fine.
      },
    );
  }
}
