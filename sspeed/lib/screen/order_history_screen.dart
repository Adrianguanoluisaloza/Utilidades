import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/pedido.dart';
import '../models/usuario.dart';
import '../services/database_service.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';
import '../widgets/adaptive_scroll_view.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  final Usuario usuario;
  const OrderHistoryScreen({super.key, required this.usuario});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<List<Pedido>> _pedidosFuture;

  @override
  void initState() {
    super.initState();
    if (widget.usuario.isAuthenticated) {
      _loadOrders();
    }
  }

  void _loadOrders() {
    setState(() {
      _pedidosFuture = Provider.of<DatabaseService>(context, listen: false)
          .getPedidos(widget.usuario.idUsuario);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
      ),
      body: widget.usuario.isGuest
          ? _buildLoggedOutView(context)
          : _buildOrderList(context),
    );
  }

  Widget _buildLoggedOutView(BuildContext context) {
    return const EmptyState(
      icon: Icons.receipt_long,
      title: 'Inicia sesión para ver tu historial',
      message: 'Aquí aparecerán todos tus pedidos completados y en curso.',
    );
  }

  Widget _buildOrderList(BuildContext context) {
    return FutureBuilder<List<Pedido>>(
      future: _pedidosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildErrorView(snapshot.error);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyView();
        }

        final pedidos = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => _loadOrders(),
          child: AdaptiveListViewBuilder(
            padding: const EdgeInsets.all(8.0),
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              return OrderCard(pedido: pedidos[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyView() {
    return const EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'Sin pedidos aún',
      message: 'Cuando realices compras, verás aquí su historial y estado.',
    );
  }

  Widget _buildErrorView(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          const Text('Error al Cargar Pedidos',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              onPressed: _loadOrders,
              label: const Text('Reintentar')),
        ]),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Pedido pedido;
  const OrderCard({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('dd MMM yyyy, hh:mm a').format(pedido.fechaPedido);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: AppCard(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) =>
                    OrderDetailScreen(idPedido: pedido.idPedido)),
          );
        },
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Pedido #${pedido.idPedido}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text('\$${pedido.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green)),
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(formattedDate,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              StatusBadge(status: pedido.estado),
            ]),
          ],
        ),
      ),
    );
  }
}
