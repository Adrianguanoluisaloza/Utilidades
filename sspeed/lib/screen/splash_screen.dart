import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../models/session_state.dart';

/// Splash Screen responsivo adaptado a móvil, tablet y desktop
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar animaciones fluidas
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Iniciar animaciones
    _controller.forward();

    // Navegación después del primer frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      // Intentar obtener usuario de sesión
      final sessionController = Provider.of<SessionController>(
        context,
        listen: false,
      );

      // Esperar mínimo 2.5 segundos para mostrar el splash
      await Future.delayed(const Duration(milliseconds: 2500));

      if (!mounted) return;

      // Navegar según estado de sesión
      final usuario = sessionController.usuario;
      if (usuario != null && sessionController.isAuthenticated) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.mainNavigator);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    } catch (e) {
      debugPrint('Error al inicializar: $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Diseño responsivo
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final isDesktop = size.width >= 1024;

    final logoSize = isDesktop ? 200.0 : (isTablet ? 160.0 : 120.0);
    final titleSize = isDesktop ? 48.0 : (isTablet ? 40.0 : 32.0);
    final subtitleSize = isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF97316), // Naranja
              const Color(0xFFFF6F3C), // Naranja más claro
              const Color(0xFF3B82F6), // Azul medio
              const Color(0xFF1E3A8A), // Azul oscuro
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo animado
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(logoSize * 0.25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF97316).withAlpha(77),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.black.withAlpha(51),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(logoSize * 0.25),
                        child: Padding(
                          padding: EdgeInsets.all(logoSize * 0.1),
                          child: Image.asset(
                            'assets/images/LOGO DE AP Y WEB.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.delivery_dining,
                                size: logoSize * 0.6,
                                color: const Color(0xFF1E3A8A),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: isDesktop ? 60 : (isTablet ? 50 : 40)),

                  // Título animado
                  SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Unite Speed',
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withAlpha(77),
                                offset: const Offset(0, 3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isDesktop ? 20 : (isTablet ? 16 : 12)),

                        Text(
                          '🚀 Delivery en minutos',
                          style: TextStyle(
                            fontSize: subtitleSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withAlpha(242),
                            letterSpacing: 0.5,
                          ),
                        ),

                        SizedBox(height: isDesktop ? 60 : (isTablet ? 50 : 40)),

                        // Loading indicator
                        SizedBox(
                          width: isDesktop ? 60 : (isTablet ? 50 : 40),
                          height: isDesktop ? 60 : (isTablet ? 50 : 40),
                          child: CircularProgressIndicator(
                            strokeWidth: isDesktop ? 5 : 4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withAlpha(230),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Footer
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: isDesktop ? 40 : (isTablet ? 30 : 20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Esmeraldas, Ecuador',
                          style: TextStyle(
                            fontSize: isDesktop ? 16 : 14,
                            color: Colors.white.withAlpha(204),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'v1.0.0',
                          style: TextStyle(
                            fontSize: isDesktop ? 14 : 12,
                            color: Colors.white.withAlpha(153),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
