import 'package:flutter/material.dart';
import '../models/usuario.dart';
import 'chat_screen.dart';

/// Pantalla que muestra las diferentes opciones de chat disponibles
class ChatListScreen extends StatelessWidget {
  final Usuario usuario;

  const ChatListScreen({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Mis Chats'),
        backgroundColor: const Color(0xFFF97316),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Chat con CIA Bot
          _buildChatOption(
            context,
            icon: Icons.smart_toy,
            iconColor: const Color(0xFF3B82F6),
            title: 'CIA Bot',
            subtitle: 'Asistente virtual con IA',
            onTap: () => _navigateToChat(context, ChatSection.ciaBot),
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

          // Historial de conversaciones - DISPONIBLE PARA TODOS
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
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
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

  void _navigateToChat(BuildContext context, ChatSection section) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          currentUser: usuario,
          initialSection: section,
        ),
      ),
    );
  }
}
