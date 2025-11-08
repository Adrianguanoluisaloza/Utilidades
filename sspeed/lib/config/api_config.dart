import 'dart:developer' as developer;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

// 1. Define los entornos de la aplicación
enum Environment {
  development,
  production,
}

// 2. Clase para la configuración de la API específica de cada entorno
class ApiSettings {
  final String baseUrl;
  final String geminiApiKey;

  const ApiSettings({required this.baseUrl, required this.geminiApiKey});

  // Configuración para el entorno de DESARROLLO (localhost, emuladores O NGROK)
  factory ApiSettings.forDevelopment() {
    // === CONFIGURACIÓN FLEXIBLE PARA DESARROLLO ===
    // Prioridad:
    // 1. Variable de entorno NGROK_URL (para túneles ngrok)
    // 2. Variable de entorno LOCAL_IP (para dispositivos físicos en la misma red)
    // 3. Detección automática según plataforma

    // Obtener ngrok URL desde variable de entorno (si existe)
    const String ngrokFromEnv =
        String.fromEnvironment('NGROK_URL', defaultValue: '');

    // Obtener IP local desde variable de entorno (para dispositivos físicos)
    const String localIp = String.fromEnvironment('LOCAL_IP', defaultValue: '');

    // Puerto por defecto del servidor
    const String defaultPort = '7070';

    // === ¡CLAVE DE GEMINI PARA PRUEBAS! ===
    const String geminiKeyForTesting = String.fromEnvironment(
      'GEMINI_API_KEY',
      defaultValue: 'PEGA-AQUI-TU-CLAVE-DE-GEMINI',
    );

    String finalBaseUrl;
    String detectionMethod;

    // Prioridad 1: Ngrok URL
    if (ngrokFromEnv.isNotEmpty) {
      finalBaseUrl = ngrokFromEnv;
      detectionMethod = '🌐 NGROK (variable de entorno)';
    }
    // Prioridad 2: IP local para dispositivos físicos
    else if (localIp.isNotEmpty) {
      finalBaseUrl = 'http://$localIp:$defaultPort';
      detectionMethod = '📱 IP Local (variable de entorno)';
    }
    // Prioridad 3: Detección automática por plataforma
    else {
      if (kIsWeb) {
        finalBaseUrl = 'http://localhost:$defaultPort';
        detectionMethod = '🌍 Web (localhost)';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        finalBaseUrl = 'http://10.0.2.2:$defaultPort';
        detectionMethod = '🤖 Android Emulator (10.0.2.2)';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        finalBaseUrl = 'http://localhost:$defaultPort';
        detectionMethod = '🍎 iOS Simulator (localhost)';
      } else {
        finalBaseUrl = 'http://localhost:$defaultPort';
        detectionMethod = '💻 Desktop (localhost)';
      }
    }

    // Log para debugging
    developer.log(
      '🔧 API Config - Development Mode\n'
      '   Método: $detectionMethod\n'
      '   Base URL: $finalBaseUrl',
      name: 'ApiConfig',
    );

    return ApiSettings(
      baseUrl: finalBaseUrl,
      geminiApiKey: geminiKeyForTesting,
    );
  }

  // Configuración para el entorno de PRODUCCIÓN (AWS/Dominio real)
  static const ApiSettings production = ApiSettings(
    baseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://18.217.51.221:7070',
    ),
    geminiApiKey: String.fromEnvironment(
      'GEMINI_API_KEY',
      defaultValue: 'PRODUCCION_REQUIERE_VARIABLE_ENV',
    ),
  );
}

// 3. Clase principal para gestionar la configuración de la API
class AppConfig {
  AppConfig._(); // Constructor privado para evitar instanciación

  // --- CONFIGURACIÓN PRINCIPAL ---
  static const String _envString =
      String.fromEnvironment('APP_ENV', defaultValue: 'development');

  static const String _compileTimeBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static final Environment _currentEnvironment =
      _envString.toLowerCase() == 'production'
          ? Environment.production
          : Environment.development;

  // -----------------------------

  static final Map<Environment, ApiSettings> _settings = {
    Environment.development: ApiSettings.forDevelopment(),
    Environment.production: ApiSettings.production,
  };

  static String? _runtimeOverrideBaseUrl;

  /// Permite sobrescribir la URL base manualmente en tiempo de ejecución.
  /// Útil para cambiar entre localhost/ngrok/AWS sin recompilar.
  static void overrideBaseUrl(String? baseUrl) {
    _runtimeOverrideBaseUrl =
        (baseUrl != null && baseUrl.trim().isNotEmpty) ? baseUrl.trim() : null;

    if (_runtimeOverrideBaseUrl != null) {
      developer.log(
        '⚡ API Config - Runtime Override\n'
        '   Nueva Base URL: $_runtimeOverrideBaseUrl',
        name: 'ApiConfig',
      );
    }
  }

  /// Devuelve la URL base que la aplicación debe usar.
  static String get baseUrl {
    // Prioridad 1: Override en tiempo de ejecución
    if (_runtimeOverrideBaseUrl != null) {
      return _runtimeOverrideBaseUrl!;
    }
    // Prioridad 2: Variable de entorno en compile-time
    if (_compileTimeBaseUrl.isNotEmpty) {
      return _compileTimeBaseUrl;
    }
    // Prioridad 3: Configuración del entorno actual
    return _settings[_currentEnvironment]!.baseUrl;
  }

  /// Devuelve la clave de API de Gemini para el entorno actual.
  static String get geminiApiKey {
    return _settings[_currentEnvironment]!.geminiApiKey;
  }

  /// Devuelve el entorno actual (development o production).
  static Environment get currentEnvironment => _currentEnvironment;

  /// Muestra la configuración actual en consola (útil para debugging).
  static void printCurrentConfig() {
    developer.log(
      '📋 Configuración Actual de API\n'
      '   Entorno: ${_currentEnvironment.name}\n'
      '   Base URL: $baseUrl\n'
      '   Override activo: ${_runtimeOverrideBaseUrl != null}\n'
      '   Compile-time URL: ${_compileTimeBaseUrl.isEmpty ? "(ninguna)" : _compileTimeBaseUrl}',
      name: 'ApiConfig',
    );
  }

  // -----------------------------
  // Control de logs de la app/HTTP
  // -----------------------------
  static bool _enableLogs = true; // por defecto sí en desarrollo

  static bool get enableLogs => _enableLogs;

  /// Permite activar/desactivar logs verbosos (HTTP, configuración, etc.) en runtime.
  static void setLogging(bool enabled) {
    _enableLogs = enabled;
    developer.log('📝 Logs ${enabled ? 'activados' : 'desactivados'}',
        name: 'ApiConfig');
  }

  // -----------------------------
  // Enlaces de la aplicación (sitio informativo)
  // -----------------------------
  static const String _siteUrl = String.fromEnvironment(
    'SITE_URL',
    defaultValue: 'https://d13frkv67psjik.cloudfront.net/',
  );

  /// URL del sitio/página informativa externa
  static String get siteUrl => _siteUrl;
}
