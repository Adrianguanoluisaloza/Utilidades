import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/usuario.dart';
import '../models/pedido.dart';
import '../services/database_service.dart';
import 'chat_screen.dart';

/// Pantalla que muestra las diferentes opciones de chat disponibles
class ChatListScreen extends StatefulWidget {
  final Usuario usuario;

  const ChatListScreen({super.key, required this.usuario});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _hasActiveDelivery = false;
  bool _isLoading = true;
  Pedido? _activePedido;

  @override
  void initState() {
    super.initState();
    _checkActiveDelivery();
  }

  Future<void> _checkActiveDelivery() async {
    try {
      final db = context.read<DatabaseService>();
      final pedidos = await db.getPedidos(widget.usuario.idUsuario);

      // Buscar pedidos activos con delivery asignado
      final activePedidoWithDelivery = pedidos
          .where((p) =>
              p.idDelivery != null &&
              p.idDelivery! > 0 &&
              (p.estado == 'en_camino' ||
                  p.estado == 'preparando' ||
                  p.estado == 'pendiente'))
          .toList();

      if (mounted) {
        setState(() {
          _hasActiveDelivery = activePedidoWithDelivery.isNotEmpty;
          _activePedido = activePedidoWithDelivery.isNotEmpty
              ? activePedidoWithDelivery.first
              : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Mis Chats'),
        backgroundColor: const Color(0xFFF97316),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Chat con Repartidor (solo si hay delivery asignado)
                if (_hasActiveDelivery && _activePedido != null) ...[
                  _buildChatOption(
                    context,
                    icon: Icons.delivery_dining,
                    iconColor: const Color(0xFFFF6B35),
                    title: 'Tu Repartidor',
                    subtitle:
                        'Chat con el repartidor de tu pedido #${_activePedido!.idPedido}',
                    onTap: () => _navigateToChat(context, ChatSection.delivery,
                        idPedido: _activePedido!.idPedido),
                    badge: 'Activo',
                  ),
                  const SizedBox(height: 12),
                ],

                // Chat con Unibot
                _buildChatOption(
                  context,
                  icon: Icons.smart_toy,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Unibot',
                  subtitle: 'Asistente virtual con IA',
                  onTap: () => _navigateToChat(context, ChatSection.unibot),
                ),
                const SizedBox(height: 12),

                // Chat con Soporte
                _buildChatOption(
                  context,
                  icon: Icons.support_agent,
                  iconColor: Colors.green,
                  title: 'Soporte',
                  subtitle: 'Contacta con nuestro equipo de ayuda',
                  onTap: () => _navigateToChat(context, ChatSection.soporte),
                ),
                const SizedBox(height: 12),

                // Historial de conversaciones
                _buildChatOption(
                  context,
                  icon: Icons.history,
                  iconColor: Colors.orange,
                  title: 'Historial',
                  subtitle: 'Ver todas tus conversaciones guardadas',
                  onTap: () => _navigateToChat(context, ChatSection.historial),
                ),
              ],
            ),
    );
  }

  Widget _buildChatOption(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _navigateToChat(BuildContext context, ChatSection section,
      {int? idPedido}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          currentUser: widget.usuario,
          initialSection: section,
          idConversacion: idPedido,
        ),
      ),
    );
  }
}
