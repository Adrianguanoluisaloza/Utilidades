import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';

class ResetPasswordConfirmScreen extends StatefulWidget {
  const ResetPasswordConfirmScreen({super.key});

  @override
  State<ResetPasswordConfirmScreen> createState() =>
      _ResetPasswordConfirmScreenState();
}

class _ResetPasswordConfirmScreenState
    extends State<ResetPasswordConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
    });
    final db = context.read<DatabaseService>();
    try {
      final ok = await db.confirmarReset(
        _emailCtrl.text.trim(),
        _codeCtrl.text.trim(),
        _passCtrl.text,
      );
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contraseña restablecida')));
        Navigator.of(context)
            .popUntil((route) => route.settings.name == '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo restablecer')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
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
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar código')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Correo inválido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeCtrl,
                decoration:
                    const InputDecoration(labelText: 'Código (6 dígitos)'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.length != 6) ? 'Código inválido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                decoration:
                    const InputDecoration(labelText: 'Nueva contraseña'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _confirmar,
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Restablecer'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
