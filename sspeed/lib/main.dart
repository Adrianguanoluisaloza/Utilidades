import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' as rendering;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'models/cart_model.dart';
import 'config/app_theme.dart';
import 'config/api_config.dart';
import 'models/session_state.dart';
import 'services/database_service.dart';
import 'routes/app_routes.dart';
import 'routes/route_generator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'es_EC';
  await initializeDateFormatting('es_EC', null);

  // Desactiva overlays/efectos de depuración que pintan rejillas/arcoiris.
  assert(() {
    rendering.debugRepaintRainbowEnabled = false;
    rendering.debugPaintSizeEnabled = false;
    rendering.debugPaintPointersEnabled = false;
    rendering.debugPaintLayerBordersEnabled = false;
    return true;
  }());

  // 🔧 CONFIGURACIÓN DE API: Muestra en consola qué URL está usando
  // Útil para debugging cuando cambias entre localhost/ngrok/AWS
  AppConfig.printCurrentConfig();

  // 🌐 OVERRIDE MANUAL: Conectar directamente al backend en AWS EC2
  AppConfig.overrideBaseUrl('http://18.217.51.221:7070');

  // Silencia logs HTTP/diagnósticos en el emulador si molestan visualmente
  AppConfig.setLogging(false);

  // ⚠️ OTRAS OPCIONES (comentadas):
  // AppConfig.overrideBaseUrl(null); // Usar localhost (desarrollo)
  // AppConfig.overrideBaseUrl('https://tu-dominio-ngrok.ngrok-free.dev'); // Usar ngrok
  // AppConfig.overrideBaseUrl('http://192.168.1.100:7070'); // IP local para dispositivo físico

  // Inicializar SessionController y cargar sesión guardada
  final sessionController = SessionController();
  await sessionController.loadSession();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: sessionController),
        ChangeNotifierProvider(create: (_) => CartModel()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // CORRECCIÓN: Se ajusta el título para que sea más descriptivo.
      title: 'Unite Speed Delivery',
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: false,
      checkerboardRasterCacheImages: false,
      checkerboardOffscreenLayers: false,
      debugShowMaterialGrid: false,
      theme: AppTheme.theme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
