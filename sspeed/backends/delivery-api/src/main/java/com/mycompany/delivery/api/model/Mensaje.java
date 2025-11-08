package com.mycompany.delivery.api.model;

import java.sql.Timestamp;

/**
 * Modelo que representa un mensaje dentro del sistema de pedidos o chat.
 * Puede ser enviado por el cliente, el delivery o el administrador.
 */
public class Mensaje {

    private long idMensaje;
    private long idPedido;
    private int idRemitente;
    private String mensaje;
    private Timestamp fechaEnvio;

    public Mensaje() {
    }

    public Mensaje(long idMensaje, long idPedido, int idRemitente, String mensaje, Timestamp fechaEnvio) {
        this.idMensaje = idMensaje;
        this.idPedido = idPedido;
        this.idRemitente = idRemitente;
        this.mensaje = mensaje;
        this.fechaEnvio = fechaEnvio;
    }

    public long getIdMensaje() {
        return idMensaje;
    }

    public void setIdMensaje(long idMensaje) {
        this.idMensaje = idMensaje;
    }

    public long getIdPedido() {
        return idPedido;
    }

    public void setIdPedido(long idPedido) {
        this.idPedido = idPedido;
    }

    public int getIdRemitente() {
        return idRemitente;
    }

    public void setIdRemitente(int idRemitente) {
        this.idRemitente = idRemitente;
    }

    public String getMensaje() {
        return mensaje;
    }

    public void setMensaje(String mensaje) {
        this.mensaje = mensaje;
    }

    public Timestamp getFechaEnvio() {
        return fechaEnvio;
    }

    public void setFechaEnvio(Timestamp fechaEnvio) {
        this.fechaEnvio = fechaEnvio;
    }

    @Override
    public String toString() {
        return "Mensaje{" +
                "idMensaje=" + idMensaje +
                ", idPedido=" + idPedido +
                ", idRemitente=" + idRemitente +
                ", mensaje='" + mensaje + '\'' +
                ", fechaEnvio=" + fechaEnvio +
                '}';
    }
}