import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/database_service.dart';
import '../models/usuario.dart';
import '../routes/app_routes.dart';
import '../models/chat_entry.dart';

enum ChatSection {
  cliente,
  ciaBot,
  soporte,
  historial,
}

class ChatScreen extends StatefulWidget {
  final ChatSection initialSection;
  final Usuario currentUser;
  final int? idConversacion;

  const ChatScreen({
    super.key,
    required this.currentUser,
    this.idConversacion,
    this.initialSection = ChatSection.cliente,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  int? _idConversacion;
  List<ChatEntry> _messages = const [];
  bool _hasText =
      false; // Para rastrear si hay texto sin usar ValueListenableBuilder

  @override
  void initState() {
    super.initState();
    _idConversacion = widget.idConversacion;
    _controller.addListener(_onTextChanged);
    _loadMessages();
  }

  void _onTextChanged() {
    if (!mounted) return;
    final hasText = _controller.text.trim().isNotEmpty;
    if (_hasText != hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final initialMessages = await _loadInitialMessages();
      if (!mounted) return;
      setState(() {
        _messages = initialMessages;
        _isLoading = false;
        _error = null;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error al cargar mensajes iniciales.';
      });
    }
  }

  Future<List<ChatEntry>> _loadInitialMessages() async {
    // Primero intentar cargar historial si hay conversación
    if (_idConversacion != null && _idConversacion! > 0) {
      try {
        final historial = await _getHistorial(_idConversacion);
        if (historial.isNotEmpty) {
          return historial;
        }
      } catch (e) {
        print('Error cargando historial: $e');
      }
    }

    // Si no hay historial, mostrar mensaje inicial
    if (widget.initialSection == ChatSection.ciaBot ||
        widget.initialSection == ChatSection.soporte) {
      return [
        ChatEntry(
          text: _getInitialBotMessage(),
          isBot: true,
          time: DateTime.now(),
          senderName: widget.initialSection == ChatSection.soporte
              ? 'Soporte'
              : _botDisplayName,
        ),
      ];
    }

    return const [];
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Para soporte, bot o historial, permitimos crear conversación automáticamente
    // Solo requerimos conversación existente para chat cliente-delivery directo
    final requiresExistingConversation =
        widget.initialSection == ChatSection.cliente;
    if (requiresExistingConversation &&
        (_idConversacion == null || _idConversacion! <= 0)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No se encontro una conversacion activa. Regresa a la lista y selecciona un chat disponible.'),
        ),
      );
      return;
    }

    final outgoing = ChatEntry(
      text: text,
      isBot: false,
      time: DateTime.now(),
      senderName: widget.currentUser.nombre,
    );

    setState(() {
      _messages = [..._messages, outgoing];
      _isSending = true;
      _error = null;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final response = await _sendToBackend(
        text,
        widget.currentUser.idUsuario,
        _idConversacion,
      );

      if (response['id_conversacion'] != null) {
        final raw = response['id_conversacion'];
        if (raw is int) {
          _idConversacion = raw;
        } else if (raw is num) {
          _idConversacion = raw.toInt();
        } else if (raw is String) {
          _idConversacion = int.tryParse(raw);
        }
      }

      if (response['success'] == false) {
        if (!mounted) return;
        setState(() {
          _isSending = false;
          _error = response['message']?.toString() ??
              'El bot no pudo procesar tu mensaje. Intenta nuevamente.';
        });
        return;
      }

      // Agregar respuesta del bot
      final botReply = response['bot_reply'];
      
      if (botReply != null && botReply.toString().trim().isNotEmpty) {
        final replyEntry = ChatEntry(
          text: botReply.toString(),
          isBot: true,
          time: DateTime.now(),
          senderName: widget.initialSection == ChatSection.soporte
              ? 'Soporte'
              : _botDisplayName,
        );
        if (mounted) {
          setState(() {
            _messages = [..._messages, replyEntry];
            _isSending = false;
          });
          _scrollToBottom();
        }
      } else {
        if (mounted) {
          setState(() => _isSending = false);
        }
      }
    } catch (e) {
      if (!mounted) return;
      String errorMsg;
      if (e.toString().contains('SocketException')) {
        errorMsg = 'Sin conexión a internet. Verifica tu red.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMsg = 'Tiempo de espera agotado. Intenta nuevamente.';
      } else if (e.toString().contains('401')) {
        errorMsg = 'Error de autenticación. Intenta cerrar sesión y volver a entrar.';
      } else if (e.toString().contains('400')) {
        errorMsg = 'Datos inválidos. Verifica el mensaje e intenta nuevamente.';
      } else if (e.toString().contains('500')) {
        errorMsg = 'Error del servidor. Intenta más tarde.';
      } else {
        errorMsg = 'No se pudo enviar. ${e.toString()}';
      }
      setState(() {
        _isSending = false;
        _error = errorMsg;
      });
      debugPrint('[ChatScreen] Error enviando mensaje: $e');
    }
  }

  Future<Map<String, dynamic>> _sendToBackend(
    String userMessage,
    int idRemitente,
    int? idConversacion,
  ) async {
    final dbService = context.read<DatabaseService>();
    final response = await dbService.enviarMensaje(
      idConversacion: idConversacion ?? 0,
      idRemitente: idRemitente,
      mensaje: userMessage,
      chatSection: widget.initialSection.name,
      esBot: widget.initialSection == ChatSection.ciaBot,
    );

    final data = (response['data'] is Map)
        ? Map<String, dynamic>.from(response['data'] as Map)
        : <String, dynamic>{};

    final resolvedId = _parseConversationId(
      data['id_conversacion'] ?? response['id_conversacion'] ?? idConversacion,
    );

    // Unificar respuesta en 'bot_reply'
    final botReply = data['respuesta'] ?? 
                     data['bot_reply'] ?? 
                     response['respuesta'] ?? 
                     response['bot_reply'];

    return {
      'id_conversacion': resolvedId ?? idConversacion,
      if (botReply != null) 'bot_reply': botReply,
      'success': response['success'] ?? true,
      'message': response['message'],
    };
  }

  int? _parseConversationId(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  Future<List<ChatEntry>> _getHistorial(int? idConversacion) async {
    if (idConversacion == null) {
      return _messages;
    }

    // CORRECCIÓN: Se utiliza el DatabaseService centralizado.
    final dbService = context.read<DatabaseService>();
    final messageModels =
        await dbService.getMensajesDeConversacion(idConversacion);

    final entries = <ChatEntry>[];
    for (final msg in messageModels) {
      final isBot = msg.esBot || _isBotUser(msg.idRemitente);
      final senderName =
          (msg.remitenteNombre != null && msg.remitenteNombre!.isNotEmpty)
              ? msg.remitenteNombre
              : _resolveSenderName(msg.idRemitente, isBot: isBot);

      entries.add(
        ChatEntry(
          text: msg.mensaje,
          isBot: isBot,
          time: msg.fechaEnvio ?? DateTime.now(),
          senderName: senderName,
        ),
      );
    }
    return entries;
  }

  bool _isBotUser(int senderId) => senderId <= 0;

  bool _detectBotFallback(List<ChatEntry> mensajes) {
    if (mensajes.isEmpty) return false;
    final last = mensajes.last;
    if (!last.isBot) return false;
    final text = last.text.toLowerCase();
    const patterns = [
      'no esta conectado',
      'problema para procesar',
      'no pude conectarme',
      'no entendi la respuesta',
      'mi cerebro',
      'intentalo de nuevo',
    ];
    return patterns.any(text.contains);
  }

  String _resolveSenderName(int senderId, {bool isBot = false}) {
    if (isBot) return _botDisplayName;
    if (senderId == widget.currentUser.idUsuario) {
      return widget.currentUser.nombre;
    }

    switch (widget.initialSection) {
      case ChatSection.cliente:
        return 'Cliente';
      case ChatSection.soporte:
        return 'Soporte';
      case ChatSection.ciaBot:
        return _botDisplayName;
      case ChatSection.historial:
        return 'Contacto';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _getAppBarTitle() {
    switch (widget.initialSection) {
      case ChatSection.cliente:
        return 'Chat con Cliente';
      case ChatSection.soporte:
        return 'Chat con Soporte';
      case ChatSection.ciaBot:
        return 'Asistente Virtual (CIA Bot)';
      case ChatSection.historial:
        return 'Historial de Chat';
    }
  }

  String _getInitialBotMessage() {
    switch (widget.initialSection) {
      case ChatSection.cliente:
        return 'Hola! Estoy aqui para ayudarte con tu pedido. En que puedo asistirte?';
      case ChatSection.soporte:
        return 'Bienvenido al chat de soporte. Por favor, describe tu problema.';
      case ChatSection.ciaBot:
        return 'Hola! Soy tu Asistente Virtual. Tienes alguna pregunta sobre nuestros productos o servicios?';
      case ChatSection.historial:
        return 'Aqui puedes ver el historial de tu conversacion.';
    }
  }

  String get _botDisplayName => 'CIA Bot';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 🎨 Diseño ultra moderno tipo Copilot Windows 11
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.initialSection == ChatSection.soporte
                  ? [
                      const Color(0xFF16A34A),
                      const Color(0xFF15803D),
                      const Color(0xFF166534)
                    ] // Verde para soporte
                  : [
                      const Color(0xFF0078D4),
                      const Color(0xFF106EBE),
                      const Color(0xFF005A9E)
                    ], // Azul para bot
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.initialSection == ChatSection.soporte
                        ? const Color(0xFF16A34A)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (widget.initialSection == ChatSection.soporte
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF3B82F6))
                          .withAlpha(77),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.initialSection == ChatSection.soporte
                        ? const Icon(
                            Icons.headset_mic, // Ícono de soporte humano
                            size: 24,
                            color: Colors.white,
                          )
                        : Image.asset(
                            'assets/images/logo_de_Chat_bot_movimiento_pagina-removebg-preview.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.smart_toy, // Ícono de bot/IA
                                size: 24,
                                color: Color(0xFF3B82F6),
                              );
                            },
                          ),
                  ),
                ),
                if (_isSending)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00D4FF),
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getAppBarTitle(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (widget.initialSection == ChatSection.ciaBot) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'IA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isSending
                              ? const Color(0xFFFFD700)
                              : const Color(0xFF00FF88),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isSending
                                      ? const Color(0xFFFFD700)
                                      : const Color(0xFF00FF88))
                                  .withAlpha(153),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isSending ? '✨ Escribiendo...' : '💫 En línea',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_detectBotFallback(_messages) &&
              widget.initialSection == ChatSection.ciaBot)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                tooltip: 'Hablar con Soporte',
                icon: const Icon(Icons.support_agent, color: Colors.white),
                onPressed: () {
                  if (!mounted) return;
                  Navigator.of(context).pushNamed(
                    AppRoutes.supportHome,
                    arguments: widget.currentUser,
                  );
                },
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1E1E1E), const Color(0xFF252526)]
                : [const Color(0xFFF5F5F5), const Color(0xFFE8E8E8)],
          ),
        ),
        child: Column(
          children: [
            if (_detectBotFallback(_messages))
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade300, Colors.amber.shade400],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'El asistente no está disponible. Contacta a Soporte.',
                        style: TextStyle(fontSize: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00D4FF), Color(0xFF0078D4)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Cargando conversación...',
                            style:
                                TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(
                          top: 16, bottom: 16, left: 8, right: 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final showDateHeader = index == 0 ||
                            !_isSameDay(_messages[index - 1].time, msg.time);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (showDateHeader) _buildDateDivider(msg.time),
                            _buildMessageRow(msg),
                          ],
                        );
                      },
                    ),
            ),
            if (_isSending && widget.initialSection == ChatSection.ciaBot)
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0078D4), Color(0xFF106EBE)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0078D4).withAlpha(77),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🤖 UniBot está escribiendo...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Procesando tu consulta con IA',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withAlpha(77),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        if (mounted) {
                          setState(() => _error = null);
                        }
                      },
                    ),
                  ],
                ),
              ),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D30) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _hasText
                        ? const Color(0xFF0078D4)
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  enabled: !_isSending,
                  maxLines: null,
                  minLines: 1,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Escribe tu mensaje...',
                    hintStyle: TextStyle(
                      color:
                          isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    suffixIcon: _hasText
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                            onPressed: () {
                              if (mounted) {
                                _controller.clear();
                              }
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                  onSubmitted: (_) {
                    if (mounted && _hasText) _sendMessage();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            _isSending
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D4FF), Color(0xFF0078D4)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: _hasText
                          ? const LinearGradient(
                              colors: [Color(0xFF00D4FF), Color(0xFF0078D4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: _hasText ? null : Colors.grey.shade300,
                      shape: BoxShape.circle,
                      boxShadow: _hasText
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0078D4).withAlpha(102),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _hasText && mounted ? _sendMessage : null,
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageRow(ChatEntry msg) {
    final isUser = !msg.isBot;
    final bubble = _buildMessageBubble(msg, isUser: isUser);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(msg),
            const SizedBox(width: 6),
            Flexible(child: bubble),
            const SizedBox(width: 40), // balance spacing
          ] else ...[
            const SizedBox(width: 40), // balance spacing
            Flexible(child: bubble),
            const SizedBox(width: 6),
            _buildAvatar(msg),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatEntry msg, {required bool isUser}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 🎨 Colores futuristas tipo Copilot
    final botColor = isDark
        ? const Color(0xFF2D2D30) // Gris oscuro
        : Colors.white; // Blanco

    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return GestureDetector(
      onLongPress: () async {
        await Clipboard.setData(ClipboardData(text: msg.text));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Mensaje copiado'),
              ],
            ),
            backgroundColor: const Color(0xFF0078D4),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF0078D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser ? null : botColor,
          borderRadius: BorderRadius.circular(20).copyWith(
            topLeft:
                isUser ? const Radius.circular(20) : const Radius.circular(4),
            topRight:
                isUser ? const Radius.circular(4) : const Radius.circular(20),
          ),
          border: !isUser ? Border.all(color: borderColor, width: 1) : null,
          boxShadow: [
            BoxShadow(
              color: isUser
                  ? const Color(0xFF0078D4).withAlpha(77)
                  : Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (msg.senderName != null && msg.senderName!.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isUser)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D4FF), Color(0xFF0078D4)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  if (!isUser) const SizedBox(width: 6),
                  Text(
                    msg.senderName!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isUser
                          ? Colors.white.withAlpha(230)
                          : const Color(0xFF0078D4),
                    ),
                  ),
                ],
              ),
            if (msg.senderName != null && msg.senderName!.isNotEmpty)
              const SizedBox(height: 6),
            Text(
              msg.text,
              style: TextStyle(
                color: isUser
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 10,
                  color: isUser
                      ? Colors.white.withAlpha(179)
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(msg.time),
                  style: TextStyle(
                    fontSize: 11,
                    color: isUser
                        ? Colors.white.withAlpha(179)
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ChatEntry msg) {
    final isUser = !msg.isBot;
    final initial = (msg.senderName != null && msg.senderName!.isNotEmpty)
        ? msg.senderName!.trim().characters.first.toUpperCase()
        : (msg.isBot ? '🤖' : 'U');

    final isSoporte = widget.initialSection == ChatSection.soporte;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: isUser
            ? const LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF0078D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : isSoporte
                ? const LinearGradient(
                    colors: [
                      Color(0xFF16A34A),
                      Color(0xFF15803D),
                      Color(0xFF166534)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [
                      Color(0xFF0078D4),
                      Color(0xFF106EBE),
                      Color(0xFF005A9E)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isUser
                    ? const Color(0xFF0078D4)
                    : isSoporte
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF0078D4))
                .withAlpha(102),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: msg.isBot
            ? (isSoporte
                ? const Icon(
                    Icons.headset_mic,
                    size: 24,
                    color: Colors.white,
                  )
                : ClipOval(
                    child: Container(
                      width: 36,
                      height: 36,
                      color: Colors.white,
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        'assets/images/logo_de_Chat_bot_movimiento_pagina-removebg-preview.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.smart_toy,
                            size: 20,
                            color: Color(0xFF3B82F6),
                          );
                        },
                      ),
                    ),
                  ))
            : Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateDivider(DateTime date) {
    final label = _formatDate(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.grey.shade300,
                  ],
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF0078D4)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0078D4).withAlpha(77),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.shade300,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String _formatDate(DateTime time) {
    final now = DateTime.now();
    final isToday = _isSameDay(now, time);
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = _isSameDay(yesterday, time);
    if (isToday) return 'Hoy';
    if (isYesterday) return 'Ayer';
    final d = time.day.toString().padLeft(2, '0');
    final m = time.month.toString().padLeft(2, '0');
    final y = time.year.toString();
    return '$d/$m/$y';
  }
}
