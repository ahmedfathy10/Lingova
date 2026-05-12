import 'package:flutter/foundation.dart';

class ApiConfig {
  // For a real phone, replace this with your computer's LAN IP address.
  // Example: http://192.168.1.20:3000
  static const localNetworkBaseUrl = 'http://192.168.1.9:3000';

  static String get baseUrl {
    const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    if (localNetworkBaseUrl.isNotEmpty) {
      return localNetworkBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://localhost:3000';
  }
}
