import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/api_exception.dart';
import '../models/session_state.dart';
import '../models/chat_conversacion.dart';
import '../routes/app_routes.dart';
import '../config/app_theme.dart';
import '../widgets/app_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      // OPTIMIZACIÓN: Se reduce la duración para una sensación más rápida.
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final sessionController = context.read<SessionController>();
    final databaseService = context.read<DatabaseService>();

    setState(() => _isLoading = true);

    try {
      final future = databaseService.login(
          _emailController.text.trim(), _passwordController.text);
      final user = await future.timeout(const Duration(seconds: 15));

      if (user != null && user.isAuthenticated) {
        databaseService.setAuthToken(user.token);
        await sessionController.setUser(user); // Ahora guarda automáticamente

        // Precargar historial de chat en segundo plano
        databaseService.getConversaciones(user.idUsuario).catchError((_) => <ChatConversacion>[]);

        // Navega segun el rol normalizado
        final normalizedRole = () {
          final raw = user.rol.trim().toLowerCase();
          const roleMap = {
            'cliente': 'cliente',
            'delivery': 'delivery',
            'repartidor': 'delivery',
            'negocio': 'negocio',
            'admin': 'admin',
            'soporte': 'soporte',
          };
          return roleMap[raw] ?? 'cliente';
        }();

        switch (normalizedRole) {
          case 'admin':
            navigator.pushNamedAndRemoveUntil(
              AppRoutes.adminHome,
              (route) => false,
              arguments: user,
            );
            break;
          case 'negocio':
            // Verificar si el negocio ya está registrado
            final negocio =
                await databaseService.getNegocioDeUsuario(user.idUsuario);

            if (negocio == null || negocio.idNegocio == 0) {
              // El negocio NO está registrado, enviar a completar datos
              navigator.pushNamedAndRemoveUntil(
                AppRoutes.registerBusiness,
                (route) => false,
                arguments: user,
              );
            } else {
              // El negocio YA está registrado, enviar a su panel
              navigator.pushNamedAndRemoveUntil(
                AppRoutes.negocioHome,
                (route) => false,
                arguments: user,
              );
            }
            break;
          case 'delivery':
            navigator.pushNamedAndRemoveUntil(
              AppRoutes.deliveryHome,
              (route) => false,
              arguments: user,
            );
            break;
          case 'soporte':
            navigator.pushNamedAndRemoveUntil(
              AppRoutes.supportHome,
              (route) => false,
              arguments: user,
            );
            break;
          default:
            navigator.pushNamedAndRemoveUntil(
              AppRoutes.mainNavigator,
              (route) => false,
              arguments: user,
            );
        }
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Credenciales incorrectas.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } on ApiException catch (e) {
      // Manejo específico para 401 (credenciales incorrectas)
      if (e.statusCode == 401) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Correo o contraseña incorrectos.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Ocurrio un error inesperado.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        body: Stack(
        children: [
          // OPTIMIZACIÓN: Usar una imagen local para carga instantánea.
          // Asegúrate de agregar la imagen a tus assets en pubspec.yaml
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/fondo-login.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Capa de degradado
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withValues(alpha: 0.8),
                  theme.colorScheme.secondary.withValues(alpha: 0.6),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Contenido del login
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo animado (imagen oficial)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/LOGO DE AP Y WEB.png',
                          height: 110,
                          fit: BoxFit.contain,
                          semanticLabel: '7speed',
                        ),
                        const SizedBox(height: 8),
                        Text('Tu comida favorita a un clic',
                            style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimary
                                    .withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Formulario animado
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildInputField(
                              controller: _emailController,
                              hintText: 'Correo electrónico',
                              icon: Icons.mail_outline,
                              validator: (v) => (v == null || !v.contains('@'))
                                  ? 'Ingresa un correo válido'
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            _buildPasswordField(),
                            const SizedBox(height: 32),
                            _buildLoginButton(theme),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        _buildRegisterLink(context),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => Navigator.of(context)
                              .pushNamed('/auth/reset/request'),
                          child: Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              color: Colors.white.withAlpha(217),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Sección de versión (al final del login)
                        Text(
                          'Versión 1.0.0',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary), // Texto blanco
      decoration: _buildInputDecoration(hintText: hintText, icon: icon),
      keyboardType: TextInputType.emailAddress,
      validator: validator,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary), // Texto blanco
      decoration: _buildInputDecoration(
        hintText: 'Contraseña',
        icon: Icons.lock_outline,
      ).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
    );
  }

  Widget _buildLoginButton(ThemeData theme) {
    return AppButton(
      text: 'Iniciar Sesión',
      onPressed: _handleLogin,
      isLoading: _isLoading,
    );
  }

  Widget _buildRegisterLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('¿No tienes una cuenta? ',
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.7))),
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.register),
          child: Text(
            'Regístrate aquí',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
          color:
              Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7)),
      prefixIcon: Icon(icon,
          color:
              Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7)),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
    );
  }
}
