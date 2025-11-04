import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/database_service.dart';
import '../models/opinion.dart';
import '../models/usuario.dart';

class OpinionesAdminScreen extends StatefulWidget {
  final Usuario adminUser;
  const OpinionesAdminScreen({super.key, required this.adminUser});

  @override
  State<OpinionesAdminScreen> createState() => _OpinionesAdminScreenState();
}

class _OpinionesAdminScreenState extends State<OpinionesAdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Future<List<Opinion>>? _fBuenas;
  Future<List<Opinion>>? _fRegulares;
  Future<List<Opinion>>? _fMalas;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  void _loadData() {
    final db = context.read<DatabaseService>();
    setState(() {
      _fBuenas = db
          .getOpinionesAdmin(clasificacion: 'buena', limit: 50)
          .then((list) => list.map((m) => Opinion.fromMap(m)).toList());
      _fRegulares = db
          .getOpinionesAdmin(clasificacion: 'regular', limit: 50)
          .then((list) => list.map((m) => Opinion.fromMap(m)).toList());
      _fMalas = db
          .getOpinionesAdmin(clasificacion: 'mala', limit: 50)
          .then((list) => list.map((m) => Opinion.fromMap(m)).toList());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opiniones de Clientes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Buenas'),
            Tab(text: 'Regulares'),
            Tab(text: 'Malas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OpinionesList(future: _fBuenas),
          _OpinionesList(future: _fRegulares),
          _OpinionesList(future: _fMalas),
        ],
      ),
    );
  }
}

class _OpinionesList extends StatelessWidget {
  final Future<List<Opinion>>? future;
  const _OpinionesList({required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Opinion>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar'));
        }
        final list = snapshot.data ?? const [];
        if (list.isEmpty) {
          return const Center(child: Text('Sin opiniones'));
        }
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final op = list[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withAlpha(38),
                child: Text(op.rating.toString()),
              ),
              title: Text(op.nombre ?? 'Anónimo'),
              subtitle: Text(op.comentario),
              trailing: Text(op.clasificacion ?? ''),
            );
          },
        );
      },
    );
  }
}
