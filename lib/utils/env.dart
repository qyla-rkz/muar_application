import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get googleApiKey => dotenv.env['GOOGLE_API_KEY'] ?? '';
  static String get googlePlacesUrl =>
      dotenv.env['GOOGLE_PLACES_URL'] ??
      'https://places.googleapis.com/v1/places:searchNearby';
  static String get googleMapsDirUrl =>
      dotenv.env['GOOGLE_MAPS_DIR_URL'] ??
      'https://www.google.com/maps/dir/?api=1&destination=';
}
