import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_conversation.dart';
import '../models/session_state.dart';
import '../models/usuario.dart';
import '../services/database_service.dart';
import 'chat_screen.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  late Future<List<ChatConversation>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _conversationsFuture = Future.value(const []);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConversations());
  }

  void _loadConversations() {
    final usuario = context.read<SessionController>().usuario;
    setState(() {
      if (usuario != null && usuario.isAuthenticated) {
        _conversationsFuture = context
            .read<DatabaseService>()
            .getConversaciones(usuario.idUsuario);
      } else {
        _conversationsFuture = Future.value(const []);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<SessionController>().usuario;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Chats'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refrescar',
              onPressed: _loadConversations,
            ),
          ],
          bottom: (usuario != null && usuario.isAuthenticated)
              ? const TabBar(
                  tabs: [
                    Tab(text: 'Delivery'),
                    Tab(text: 'Soporte'),
                    Tab(text: 'CIA Bot'),
                  ],
                )
              : null,
        ),
        body: (usuario == null || !usuario.isAuthenticated)
            ? const EmptyState(
                icon: Icons.lock_open_outlined,
                title: 'Inicia sesi�n para ver tus chats',
                message:
                    'Accede para ver tus conversaciones con delivery, soporte y el asistente.',
              )
            : FutureBuilder<List<ChatConversation>>(
                future: _conversationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Error al cargar los chats: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final conversations = snapshot.data ?? const [];
                  final deliveryChats = conversations
                      .where((c) =>
                          !c.esChatbot &&
                          c.idAdminSoporte == null &&
                          (c.idDelivery != null || c.idCliente != null))
                      .toList();
                  final soporteChats = conversations
                      .where((c) => !c.esChatbot && c.idAdminSoporte != null)
                      .toList();
                  final botChats =
                      conversations.where((c) => c.esChatbot).toList();
                  final currentUser = usuario;

                  return TabBarView(
                    children: [
                      _buildConversationList(
                        context,
                        currentUser,
                        deliveryChats,
                        section: ChatSection.cliente,
                        emptyMessage:
                            'No tienes conversaciones con repartidores.',
                        icon: Icons.delivery_dining,
                        iconColor: Colors.deepOrange,
                      ),
                      _buildConversationList(
                        context,
                        currentUser,
                        soporteChats,
                        section: ChatSection.soporte,
                        emptyMessage:
                            'No hay conversaciones con el equipo de soporte.',
                        icon: Icons.headset_mic_outlined,
                        iconColor: Colors.indigo,
                      ),
                      _buildConversationList(
                        context,
                        currentUser,
                        botChats,
                        section: ChatSection.unibot,
                        emptyMessage:
                            'Aun no has hablado con el asistente virtual.',
                        icon: Icons.smart_toy_outlined,
                        iconColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildConversationList(
    BuildContext context,
    Usuario usuario,
    List<ChatConversation> conversations, {
    required ChatSection section,
    required String emptyMessage,
    required IconData icon,
    required Color iconColor,
  }) {
    if (conversations.isEmpty) {
      return EmptyState(
        icon: icon,
        title: 'Sin conversaciones',
        message: emptyMessage,
      );
    }

    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: AppCard(
            child: ListTile(
              leading: Icon(icon, color: iconColor, size: 28),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      _resolveTitle(conversation, section),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (!conversation.esChatbot)
                    StatusBadge(
                      status: conversation.activa ? 'Activa' : 'Cerrada',
                      showDot: true,
                    ),
                ],
              ),
              subtitle: Text(
                _buildSubtitle(conversation),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => ChatScreen(
                      currentUser: usuario,
                      idConversacion: conversation.idConversacion,
                      initialSection: section,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _resolveTitle(ChatConversation conversation, ChatSection section) {
    switch (section) {
      case ChatSection.unibot:
        return 'Unibot';
      case ChatSection.soporte:
        return 'Soporte y Ayuda';
      case ChatSection.cliente:
        if (conversation.idPedido != null) {
          return 'Pedido #${conversation.idPedido}';
        }
        return 'Chat con Repartidor';
      case ChatSection.delivery:
        if (conversation.idPedido != null) {
          return 'Pedido #${conversation.idPedido}';
        }
        return 'Chat con Cliente';
      case ChatSection.historial:
        return conversation.aDisplayTitle;
    }
  }

  String _buildSubtitle(ChatConversation conversation) {
    final created =
        conversation.fechaCreacion.toLocal().toString().split('.')[0];
    final details = <String>[];

    if (conversation.idPedido != null) {
      details.add('Pedido #${conversation.idPedido}');
    }
    if (conversation.idCliente != null) {
      details.add('Cliente ${conversation.idCliente}');
    }
    if (conversation.idDelivery != null) {
      details.add('Delivery ${conversation.idDelivery}');
    }
    if (conversation.idAdminSoporte != null) {
      details.add('Soporte ${conversation.idAdminSoporte}');
    }
    details.add('Creado: $created');

    return details.join(' � ');
  }
}
