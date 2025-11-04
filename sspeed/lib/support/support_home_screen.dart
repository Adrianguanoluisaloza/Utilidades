import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_conversation.dart';
import '../models/usuario.dart';
import '../screen/chat_screen.dart';
import '../services/database_service.dart';

class SupportHomeScreen extends StatefulWidget {
  final Usuario supportUser;

  const SupportHomeScreen({super.key, required this.supportUser});

  @override
  State<SupportHomeScreen> createState() => _SupportHomeScreenState();
}

class _SupportHomeScreenState extends State<SupportHomeScreen> {
  late Future<List<ChatConversation>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _conversationsFuture = _fetchConversations();
  }

  Future<List<ChatConversation>> _fetchConversations() {
    final database = context.read<DatabaseService>();
    return database.getConversaciones(widget.supportUser.idUsuario);
  }

  Future<void> _handleRefresh() async {
    final updatedFuture = _fetchConversations();
    setState(() {
      _conversationsFuture = updatedFuture;
    });
    await updatedFuture;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Centro de Soporte',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor,
                theme.primaryColor.withBlue(200),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_outlined),
            onPressed: () {
              context.read<DatabaseService>().setAuthToken(null);
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primaryColor.withAlpha(13),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.3],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: theme.primaryColor,
          child: FutureBuilder<List<ChatConversation>>(
            future: _conversationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: theme.primaryColor),
                          const SizedBox(height: 16),
                          Text(
                            'Cargando conversaciones...',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _SupportInfoMessage(
                      icon: Icons.error_outline,
                      iconColor: Colors.red.shade400,
                      message: 'Error al cargar conversaciones',
                      subtitle: snapshot.error.toString(),
                    ),
                  ],
                );
              }

              final conversations = snapshot.data ?? const [];

              if (conversations.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 40),
                    _SupportInfoMessage(
                      icon: Icons.headset_mic_outlined,
                      iconColor: theme.primaryColor,
                      message: '¡Todo tranquilo por ahora!',
                      subtitle:
                          'No hay conversaciones activas.\nDesliza hacia abajo para actualizar.',
                    ),
                  ],
                );
              }

              // Estadísticas rápidas
              final activeCount = conversations.length;
              final withDelivery =
                  conversations.where((c) => c.idDelivery != null).length;
              final withOrders =
                  conversations.where((c) => c.idPedido != null).length;

              return CustomScrollView(
                slivers: [
                  // Header con estadísticas
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor,
                            theme.primaryColor.withBlue(180),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withAlpha(51),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatCard(
                            icon: Icons.chat_bubble_outline,
                            value: '$activeCount',
                            label: 'Activas',
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withAlpha(77),
                          ),
                          _StatCard(
                            icon: Icons.delivery_dining,
                            value: '$withDelivery',
                            label: 'Repartidores',
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withAlpha(77),
                          ),
                          _StatCard(
                            icon: Icons.shopping_bag_outlined,
                            value: '$withOrders',
                            label: 'Pedidos',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Lista de conversaciones
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final conversation = conversations[index];
                          return _ConversationCard(
                            conversation: conversation,
                            supportUser: widget.supportUser,
                            theme: theme,
                          );
                        },
                        childCount: conversations.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(217),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final ChatConversation conversation;
  final Usuario supportUser;
  final ThemeData theme;

  const _ConversationCard({
    required this.conversation,
    required this.supportUser,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Map<String, dynamic>>[];

    if (conversation.idCliente != null) {
      chips.add({
        'label': 'Cliente #${conversation.idCliente}',
        'icon': Icons.person_outline,
        'color': Colors.blue,
      });
    }
    if (conversation.idDelivery != null) {
      chips.add({
        'label': 'Repartidor #${conversation.idDelivery}',
        'icon': Icons.delivery_dining,
        'color': Colors.orange,
      });
    }
    if (conversation.idPedido != null) {
      chips.add({
        'label': 'Pedido #${conversation.idPedido}',
        'icon': Icons.shopping_bag_outlined,
        'color': Colors.green,
      });
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  currentUser: supportUser,
                  initialSection: ChatSection.soporte,
                  idConversacion: conversation.idConversacion,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryColor.withAlpha(38),
                        theme.primaryColor.withAlpha(25),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.headset_mic,
                    color: theme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conversación #${conversation.idConversacion}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (chips.isEmpty)
                        Text(
                          'Sin detalles adicionales',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: chips.map((chip) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (chip['color'] as Color).withAlpha(26),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (chip['color'] as Color).withAlpha(77),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    chip['icon'] as IconData,
                                    size: 14,
                                    color: chip['color'] as Color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    chip['label'] as String,
                                    style: TextStyle(
                                      color: chip['color'] as Color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),

                // Flecha
                Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportInfoMessage extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String message;
  final String? subtitle;

  const _SupportInfoMessage({
    required this.icon,
    required this.iconColor,
    required this.message,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 64,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}
