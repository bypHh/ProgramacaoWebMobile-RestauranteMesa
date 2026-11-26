import 'package:flutter/foundation.dart';

/// Configuração de URL da API Back-end NestJS.
///
/// Permite integração simultânea com o Back-end (porta 3000) e Front-end Next.js (porta 3001):
/// - Web / Desktop / iOS Simulator: http://localhost:3000/api
/// - Emulador Android (AVD): http://10.0.2.2:3000/api
/// - Celular físico na mesma rede Wi-Fi: configure via --dart-define=API_URL=http://SEU_IP:3000/api
///   ou diretamente pelo botão de engrenagem dentro do aplicativo.
class ApiConfig {
  static const String _envApiUrl = String.fromEnvironment('API_URL');

  static String get defaultBaseUrl {
    if (_envApiUrl.isNotEmpty) {
      return normalizeBaseUrl(_envApiUrl);
    }

    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }

    return 'http://localhost:3000/api';
  }

  static String normalizeBaseUrl(String rawUrl) {
    var trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return defaultBaseUrl;
    }
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (!trimmed.endsWith('/api')) {
      trimmed = '$trimmed/api';
    }
    return trimmed;
  }
}
