import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/negocio.dart';
import '../models/usuario.dart';
import '../services/database_service.dart';
import '../routes/app_routes.dart';

class RegisterBusinessScreen extends StatefulWidget {
  final Usuario usuario;
  const RegisterBusinessScreen({super.key, required this.usuario});

  @override
  State<RegisterBusinessScreen> createState() => _RegisterBusinessScreenState();
}

class _RegisterBusinessScreenState extends State<RegisterBusinessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _rucCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();

  bool _isLoading = false;
  Negocio? _negocioActual;

  @override
  void initState() {
    super.initState();
    _cargarNegocio();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _rucCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarNegocio() async {
    setState(() => _isLoading = true);
    try {
      final service = context.read<DatabaseService>();
      final negocio =
          await service.getNegocioDeUsuario(widget.usuario.idUsuario);
      if (!mounted) return;
      if (negocio != null && negocio.idNegocio > 0) {
        _negocioActual = negocio;
        _nombreCtrl.text = negocio.nombreComercial;
        _rucCtrl.text = negocio.ruc;
        _direccionCtrl.text = negocio.direccion ?? '';
        _telefonoCtrl.text = negocio.telefono ?? '';
        _logoCtrl.text = negocio.logoUrl ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo cargar el negocio: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);
    try {
      final servicio = context.read<DatabaseService>();
      final negocio = Negocio(
        idNegocio: _negocioActual?.idNegocio ?? 0,
        idUsuario: widget.usuario.idUsuario,
        nombreComercial: _nombreCtrl.text.trim(),
        ruc: _rucCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim().isEmpty
            ? null
            : _direccionCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim().isEmpty
            ? null
            : _telefonoCtrl.text.trim(),
        logoUrl: _logoCtrl.text.trim().isEmpty ? null : _logoCtrl.text.trim(),
        activo: true,
      );

      final guardado = await servicio.registrarNegocioParaUsuario(
          widget.usuario.idUsuario, negocio);

      if (!mounted) return;

      if (guardado != null) {
        setState(() => _negocioActual = guardado);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Negocio registrado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navegar al panel de negocio después de guardar
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          navigator.pushNamedAndRemoveUntil(
            AppRoutes.negocioHome,
            (route) => false,
            arguments: widget.usuario,
          );
        }
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar el negocio.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al guardar el negocio: $e'),
          backgroundColor: Colors.red.shade600,
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
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA),
        appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0078D4), Color(0xFF106EBE)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.business, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Registro de Negocio',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0078D4),
        elevation: 0,
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
        body: _isLoading && _negocioActual == null
            ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0078D4), Color(0xFF106EBE)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Cargando información del negocio...',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 16,
                ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0078D4), Color(0xFF106EBE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0078D4).withAlpha(77),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(51),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(77),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.store_outlined,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '🏪 Registro de Negocio',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Completa los datos para acceder a herramientas administrativas avanzadas',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withAlpha(230),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(26),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Una vez registrado, podrás gestionar productos, pedidos y estadísticas',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withAlpha(204),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    _buildTextField(
                      controller: _nombreCtrl,
                      label: 'Nombre Comercial',
                      icon: Icons.business,
                      hint: 'Ej: Restaurante El Sabor',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre comercial es obligatorio';
                        }
                        return null;
                      },
                    ),

                    _buildTextField(
                      controller: _rucCtrl,
                      label: 'RUC',
                      icon: Icons.badge_outlined,
                      hint: 'Ingresa tu RUC (10-13 dígitos)',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return 'El RUC es obligatorio';
                        }
                        if (trimmed.length < 10 || trimmed.length > 13) {
                          return 'Debe tener entre 10 y 13 dígitos';
                        }
                        return null;
                      },
                    ),

                    _buildTextField(
                      controller: _direccionCtrl,
                      label: 'Dirección',
                      icon: Icons.location_on_outlined,
                      hint: 'Dirección completa de tu negocio',
                      maxLines: 2,
                    ),

                    _buildTextField(
                      controller: _telefonoCtrl,
                      label: 'Teléfono de Contacto',
                      icon: Icons.phone_outlined,
                      hint: 'Número de contacto',
                      keyboardType: TextInputType.phone,
                    ),

                    _buildTextField(
                      controller: _logoCtrl,
                      label: 'Logo (URL)',
                      icon: Icons.image_outlined,
                      hint: 'URL de la imagen del logo (opcional)',
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 32),

                    Container(
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
                        boxShadow: _isLoading ? null : [
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
                          onTap: _isLoading ? null : _guardar,
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
                                        'Guardando...',
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
                                          Icons.save_outlined, 
                                          size: 20, 
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        '🏪 Registrar Negocio',
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
                    ),
                  ],
                ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0078D4), Color(0xFF106EBE)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
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
              maxLines: maxLines,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF2D2D30) : Colors.white,
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.red.shade400),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              validator: validator,
            ),
          ),
        ],
      ),
    );
  }
}
