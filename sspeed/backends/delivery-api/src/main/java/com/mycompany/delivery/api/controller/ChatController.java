package com.mycompany.delivery.api.controller;

import com.mycompany.delivery.api.model.Mensaje;
import com.mycompany.delivery.api.repository.ChatRepository;
import java.util.List;
import java.util.Map;

/**
 * Controlador para gestionar las operaciones relacionadas con el chat.
 */
public class ChatController {

    private final ChatRepository chatRepository;

    public ChatController() {
        this.chatRepository = new ChatRepository();
    }

    /**
     * Obtiene todos los mensajes de un pedido específico.
     *
     * @param idPedido El ID del pedido del cual obtener los mensajes
     * @return Una lista de mensajes en formato de Map
     */
    public List<Map<String, Object>> obtenerChatPorPedido(long idPedido) {
        return chatRepository.obtenerChatPorPedido(idPedido);
    }

    /**
     * Guarda un nuevo mensaje en el chat.
     *
     * @param mensaje El mensaje a guardar
     * @return Un Map con la información del mensaje guardado
     */
    public Map<String, Object> guardarMensaje(Mensaje mensaje) {
        return chatRepository.guardarMensaje(mensaje);
    }
}