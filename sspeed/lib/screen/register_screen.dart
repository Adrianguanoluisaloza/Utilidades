import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/api_exception.dart';
import '../routes/app_routes.dart';
import '../config/app_theme.dart';
import '../models/negocio.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Campos comunes
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Campos específicos para Negocio
  final _nombreComercialController = TextEditingController();
  final _rucController = TextEditingController();
  final _direccionNegocioController = TextEditingController();
  final _logoUrlController = TextEditingController();

  // Campos específicos para Delivery
  final _vehiculoController = TextEditingController();
  final _placaController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _selectedRole = 'cliente'; // Rol por defecto alineado con la API

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nombreComercialController.dispose();
    _rucController.dispose();
    _direccionNegocioController.dispose();
    _logoUrlController.dispose();
    _vehiculoController.dispose();
    _placaController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final normalizedRole = _selectedRole.trim().toLowerCase();
    const roleMap = {
      'cliente': 'cliente',
      'delivery': 'delivery',
      'repartidor': 'delivery',
      'negocio': 'negocio',
      'soporte': 'soporte',
      'admin': 'admin',
    };
    final apiRole = roleMap[normalizedRole] ?? 'cliente';

    setState(() => _isLoading = true);

    try {
      // Validación proactiva: verificar si el email ya existe ANTES de enviar
      final emailTrimmed = _emailController.text.trim();
      final emailAlreadyExists = await dbService.emailExists(emailTrimmed);

      if (emailAlreadyExists) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: const Text('El correo ya está registrado.'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Ir a login',
              textColor: Colors.white,
              onPressed: () {
                if (mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
                }
              },
            ),
          ),
        );
        return; // Bloquear envío al backend
      }

      // Registro del usuario base
      final success = await dbService.register(
        _nameController.text.trim(),
        emailTrimmed,
        _passwordController.text,
        _phoneController.text.trim(),
        apiRole, // Rol normalizado compatible con el backend
      );

      if (success) {
        // Hacer login automático para obtener el usuario
        final usuario = await dbService.login(
          emailTrimmed,
          _passwordController.text,
        );

        if (usuario == null) {
          throw Exception('Error al obtener datos del usuario');
        }

        messenger.hideCurrentSnackBar();

        // Si el usuario se registró como negocio, crear el registro de negocio
        if (_selectedRole == 'negocio') {
          try {
            // Crear negocio con los datos adicionales
            final negocio = Negocio(
              idNegocio: 0, // Se genera en el backend
              idUsuario: usuario.idUsuario,
              nombreComercial: _nombreComercialController.text.trim(),
              ruc: _rucController.text.trim().isEmpty
                  ? ''
                  : _rucController.text.trim(),
              direccion: _direccionNegocioController.text.trim(),
              telefono: _phoneController.text.trim(),
              logoUrl: _logoUrlController.text.trim().isEmpty
                  ? null
                  : _logoUrlController.text.trim(),
              activo: true,
            );

            await dbService.registrarNegocioParaUsuario(
              usuario.idUsuario,
              negocio,
            );

            messenger.showSnackBar(
              const SnackBar(
                content: Text('¡Registro de negocio completado con éxito!'),
                backgroundColor: Colors.green,
                duration: Duration(milliseconds: 1500),
              ),
            );
          } catch (e) {
            messenger.showSnackBar(
              SnackBar(
                content:
                    Text('Usuario creado pero error en datos del negocio: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }

          if (!mounted) return;
          navigator.pushNamedAndRemoveUntil(
            AppRoutes.negocioHome,
            (route) => false,
          );
        } else if (_selectedRole == 'delivery') {
          // Para delivery, podrías guardar datos del vehículo si tienes tabla para ello
          // Por ahora solo mostramos mensaje y vamos al login
          messenger.showSnackBar(
            const SnackBar(
              content: Text('¡Registro exitoso! Ahora inicia sesión.'),
              backgroundColor: Colors.green,
              duration: Duration(milliseconds: 1200),
            ),
          );
          if (!mounted) return;
          navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        } else {
          // Para cliente, ir directo al login
          messenger.showSnackBar(
            const SnackBar(
              content: Text('¡Registro exitoso! Ahora inicia sesión.'),
              backgroundColor: Colors.green,
              duration: Duration(milliseconds: 1200),
            ),
          );
          if (!mounted) return;
          navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        }
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('El correo ya esta registrado.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } on ApiException catch (e) {
      // Manejo específico para duplicado (409) y genérico para otros errores
      if (e.statusCode == 409) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: const Text('El correo ya está registrado.'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Ir a login',
              textColor: Colors.white,
              onPressed: () {
                if (mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
                }
              },
            ),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(51),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0078D4), Color(0xFF106EBE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0078D4), Color(0xFF106EBE), Color(0xFFF8F9FA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.3, 1.0],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header moderno
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withAlpha(51),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00D4FF), Color(0xFF0078D4)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.person_add,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '🚀 Únete a Unite Speed',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crea tu cuenta en segundos',
                            style: TextStyle(
                              color: Colors.white.withAlpha(230),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Form(
                      key: _formKey,
                      child: Container(
                        padding: const EdgeInsets.all(32.0),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF2D2D30) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(26),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              hint: 'Nombre Completo',
                              icon: Icons.person_outline,
                              validator: (val) =>
                                  val!.isEmpty ? 'Ingresa tu nombre' : null,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _emailController,
                              hint: 'Correo electrónico',
                              icon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) => !val!.contains('@')
                                  ? 'Correo inválido'
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _phoneController,
                              hint: 'Teléfono',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (val) =>
                                  val!.isEmpty ? 'Ingresa tu teléfono' : null,
                            ),
                            const SizedBox(height: 20),
                            _buildPasswordField(
                              controller: _passwordController,
                              hint: 'Contraseña',
                              obscure: _obscurePassword,
                              toggle: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                              validator: (val) => val!.length < 6
                                  ? 'Mínimo 6 caracteres'
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            _buildPasswordField(
                              controller: _confirmPasswordController,
                              hint: 'Confirmar Contraseña',
                              obscure: _obscureConfirmPassword,
                              toggle: () => setState(() =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword),
                              validator: (val) =>
                                  val != _passwordController.text
                                      ? 'Las contraseñas no coinciden'
                                      : null,
                            ),
                            const SizedBox(height: 24),
                            _buildRoleSelector(theme),

                            // Campos específicos según el rol
                            if (_selectedRole == 'negocio') ...[
                              const SizedBox(height: 24),
                              _buildSectionTitle(theme, 'Datos del Negocio'),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _nombreComercialController,
                                hint: 'Nombre Comercial',
                                icon: Icons.store_outlined,
                                validator: (val) => val!.isEmpty
                                    ? 'Ingresa el nombre del negocio'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                controller: _rucController,
                                hint: 'RUC (opcional)',
                                icon: Icons.badge_outlined,
                                keyboardType: TextInputType.number,
                                validator: (val) => null, // Opcional
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                controller: _direccionNegocioController,
                                hint: 'Dirección del Negocio',
                                icon: Icons.location_on_outlined,
                                validator: (val) => val!.isEmpty
                                    ? 'Ingresa la dirección'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                controller: _logoUrlController,
                                hint: 'URL del Logo (opcional)',
                                icon: Icons.image_outlined,
                                keyboardType: TextInputType.url,
                                validator: (val) => null, // Opcional
                              ),
                            ],

                            if (_selectedRole == 'delivery') ...[
                              const SizedBox(height: 24),
                              _buildSectionTitle(theme, 'Datos del Vehículo'),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _vehiculoController,
                                hint: 'Tipo de Vehículo (opcional)',
                                icon: Icons.two_wheeler_outlined,
                                validator: (val) => null, // Opcional
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                controller: _placaController,
                                hint: 'Placa del Vehículo (opcional)',
                                icon: Icons.confirmation_number_outlined,
                                validator: (val) => null, // Opcional
                              ),
                            ],

                            const SizedBox(height: 32),
                            _buildRegisterButton(theme),
                          ],
                        ),
                      ),
                    ),
                  ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    required String? Function(String?) validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0078D4), Color(0xFF106EBE)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF0078D4),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback toggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
      decoration:
          _buildInputDecoration(hintText: hint, icon: Icons.lock_outline)
              .copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Theme.of(context)
                .colorScheme
                .onPrimary
                .withAlpha(179), // Corregido
          ),
          onPressed: toggle,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildRoleSelector(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0078D4).withAlpha(26),
            const Color(0xFF106EBE).withAlpha(13),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0078D4).withAlpha(51),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0078D4), Color(0xFF106EBE)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.how_to_reg, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                '👤 ¿Cómo quieres registrarte?',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Grid de roles
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildRoleChip(
                  theme, '👤 Cliente', 'cliente', Icons.person_outline),
              _buildRoleChip(theme, '🏍️ Repartidor', 'delivery',
                  Icons.delivery_dining_outlined),
            ],
          ),
          const SizedBox(height: 12),
          // Negocio ocupa todo el ancho
          _buildRoleChip(theme, '🏪 Negocio', 'negocio', Icons.store_outlined),
        ],
      ),
    );
  }

  Widget _buildRoleChip(
      ThemeData theme, String label, String roleValue, IconData icon) {
    final isSelected = _selectedRole == roleValue;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _selectedRole = roleValue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF0078D4), Color(0xFF106EBE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected
                ? null
                : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0078D4)
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0078D4).withAlpha(77),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isSelected)
                Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF0078D4),
                ),
              if (!isSelected) const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black87),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: _isLoading
            ? null
            : const LinearGradient(
                colors: [Color(0xFF0078D4), Color(0xFF106EBE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: _isLoading ? Colors.grey.shade300 : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _isLoading
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0078D4).withAlpha(102),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _isLoading ? null : _register,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Creando cuenta...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.rocket_launch,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        '🚀 CREAR MI CUENTA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary.withAlpha(179)),
      prefixIcon: Icon(icon,
          color: Theme.of(context).colorScheme.onPrimary.withAlpha(179)),
      filled: true,
      fillColor: Colors.black.withAlpha(77),
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

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.onPrimary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
