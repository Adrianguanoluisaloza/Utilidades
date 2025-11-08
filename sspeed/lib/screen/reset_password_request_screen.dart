import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../routes/app_routes.dart';

class ResetPasswordRequestScreen extends StatefulWidget {
  const ResetPasswordRequestScreen({super.key});

  @override
  State<ResetPasswordRequestScreen> createState() =>
      _ResetPasswordRequestScreenState();
}

class _ResetPasswordRequestScreenState
    extends State<ResetPasswordRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _codigo;
  int? _expiresIn;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _generar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _codigo = null;
      _expiresIn = null;
    });
    final db = context.read<DatabaseService>();
    try {
      final data = await db.generarReset(_emailCtrl.text.trim());
      setState(() {
        _codigo = data['codigo']?.toString();
        _expiresIn = (data['expiresInMinutes'] as num?)?.toInt();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código generado. Revisa el chat de soporte.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo generar el código: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  hintText: 'usuario@correo.com',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Correo inválido' : null,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _generar,
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Generar código'),
              ),
            ),
            const SizedBox(height: 16),
            if (_codigo != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Código de recuperación',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Row(children: [
                          SelectableText(_codigo!,
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _codigo!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Código copiado')));
                            },
                          ),
                        ]),
                        if (_expiresIn != null)
                          Text('Expira en ~$_expiresIn min'),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Abrir chat de soporte'),
                              onPressed: () => Navigator.of(context)
                                  .pushNamed(AppRoutes.chatHome),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Ya tengo el código'),
                              onPressed: () => Navigator.of(context)
                                  .pushNamed(AppRoutes.resetConfirm),
                            ),
                          ),
                        ]),
                      ]),
                ),
              )
            ],
            const Spacer(),
            Text(
              'Consejo: También te enviamos el código a tu chat de soporte dentro de la app.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            )
          ],
        ),
      ),
    );
  }
}
