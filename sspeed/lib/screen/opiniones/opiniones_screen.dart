import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/opinion.dart';
import '../../models/usuario.dart';
import '../../services/database_service.dart';

class OpinionesScreen extends StatefulWidget {
  final Usuario usuario;
  const OpinionesScreen({super.key, required this.usuario});

  @override
  State<OpinionesScreen> createState() => _OpinionesScreenState();
}

class _OpinionesScreenState extends State<OpinionesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _comentarioController = TextEditingController();
  int _rating = 5;
  bool _isSending = false;
  String? _ultimoErrorEnvio;
  Future<List<Opinion>>? _opinionesFuture;

  @override
  void initState() {
    super.initState();
    _loadOpiniones();
  }

  void _loadOpiniones() {
    final db = context.read<DatabaseService>();
    setState(() {
      _opinionesFuture = db
          .getOpiniones(limit: 20)
          .then((list) => list.map((m) => Opinion.fromMap(m)).toList());
    });
  }

  Future<void> _enviarOpinion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSending = true;
      _ultimoErrorEnvio = null;
    });
    try {
      final db = context.read<DatabaseService>();
      final ok = await db.crearOpinion(
        idUsuario:
            widget.usuario.idUsuario > 0 ? widget.usuario.idUsuario : null,
        nombre: widget.usuario.nombre.isNotEmpty ? widget.usuario.nombre : null,
        email: widget.usuario.correo.isNotEmpty ? widget.usuario.correo : null,
        rating: _rating,
        comentario: _comentarioController.text.trim(),
        plataforma: 'app',
      );
      if (!mounted) return;
      setState(() => _isSending = false);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        if (ok) {
          messenger.showSnackBar(const SnackBar(
            content: Text('¡Gracias por tu opinión!'),
            backgroundColor: Colors.green,
          ));
          _comentarioController.clear();
          _loadOpiniones();
        } else {
          messenger.showSnackBar(const SnackBar(
            content: Text('No se pudo enviar tu opinión.'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _ultimoErrorEnvio = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Opiniones')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cuéntanos tu experiencia', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Calificación:'),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: _rating,
                        items: const [1, 2, 3, 4, 5]
                            .map((e) => DropdownMenuItem(
                                value: e, child: Text('⭐' * e)))
                            .toList(),
                        onChanged: (v) => setState(() => _rating = v ?? 5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _comentarioController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu comentario...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'El comentario es requerido'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _enviarOpinion,
                      icon: const Icon(Icons.send),
                      label:
                          Text(_isSending ? 'Enviando...' : 'Enviar opinión'),
                    ),
                  ),
                  if (_ultimoErrorEnvio != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _ultimoErrorEnvio!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Opiniones recientes', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Opinion>>(
                future: _opinionesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error al cargar opiniones'));
                  }
                  final list = snapshot.data ?? const [];
                  if (list.isEmpty) {
                    return const Center(child: Text('Aún no hay opiniones'));
                  }
                  return ListView.separated(
                    itemBuilder: (context, i) {
                      final op = list[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber.withAlpha(38),
                          child: Text(op.rating.toString()),
                        ),
                        title: Text(op.nombre ?? 'Anónimo'),
                        subtitle: Text(op.comentario),
                        trailing: Text(
                            '${op.createdAt.day}/${op.createdAt.month}/${op.createdAt.year}'),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemCount: list.length,
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
