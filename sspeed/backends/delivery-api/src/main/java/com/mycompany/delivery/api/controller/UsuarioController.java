package com.mycompany.delivery.api.controller;

import java.util.List;
import java.util.Optional;

import com.mycompany.delivery.api.model.Usuario;
import com.mycompany.delivery.api.repository.UsuarioRepository;
import com.mycompany.delivery.api.util.ApiException;
import com.mycompany.delivery.api.util.ApiResponse;
import java.sql.SQLException;

/**
 * Controlador REST para la gestion de usuarios.
 * Contiene autenticacion, registro, edicion, listado y eliminacion.
 */
public class UsuarioController {

    private final UsuarioRepository repo = new UsuarioRepository();

    /**
     * Valida el token JWT y devuelve el usuario autenticado.
     */
    public Usuario validarToken(String token) throws ApiException {
        try {
            var jwt = com.mycompany.delivery.api.util.JwtUtil.verify(token);
            long idUsuario = com.mycompany.delivery.api.util.JwtUtil.getUserId(jwt);
            Optional<Usuario> usuarioOpt = repo.obtenerPorId(idUsuario);
            if (usuarioOpt.isEmpty()) {
                throw new ApiException(401, "Usuario no encontrado para el token");
            }
            Usuario usuario = usuarioOpt.get();
            if (!usuario.isActivo()) {
                throw new ApiException(403, "El usuario asociado a este token ha sido desactivado.");
            }
            if (usuario.getRol() == null || usuario.getRol().isBlank()) {
                throw new ApiException(403, "Usuario sin rol definido");
            }
            return usuario;
        } catch (SQLException e) {
            throw new ApiException(500, "Error de base de datos al validar token", e);
        }
    }

    // ===========================
    // CAMBIAR CONTRASEÑA (AUTENTICADO)
    // ===========================
    public ApiResponse<Void> cambiarContrasena(Usuario authUser, String actual, String nueva) {
        if (authUser == null || authUser.getIdUsuario() <= 0) {
            throw new ApiException(401, "No autorizado");
        }
        if (actual == null || actual.isBlank() || nueva == null || nueva.isBlank()) {
            throw new ApiException(400, "Contraseña actual y nueva son obligatorias");
        }
        try {
            // Reautenticar con la contraseña actual
            var loginOk = repo.autenticar(authUser.getCorreo(), actual);
            if (loginOk.isEmpty()) {
                throw new ApiException(401, "La contraseña actual no es válida");
            }
            // Actualizar
            String sql = "UPDATE usuarios SET contrasena = ?, updated_at = NOW() WHERE id_usuario = ?";
            String nuevoHash = org.mindrot.jbcrypt.BCrypt.hashpw(nueva, org.mindrot.jbcrypt.BCrypt.gensalt(6));
            try (var conn = com.mycompany.delivery.api.config.Database.getConnection();
                 var ps = conn.prepareStatement(sql)) {
                ps.setString(1, nuevoHash);
                ps.setLong(2, authUser.getIdUsuario());
                ps.executeUpdate();
            }
            return ApiResponse.success(200, "Contraseña actualizada correctamente", null);
        } catch (SQLException e) {
            throw new ApiException(500, "Error al cambiar la contraseña", e);
        }
    }

    // ===========================
    // LOGIN
    // ===========================
    public ApiResponse<java.util.Map<String, Object>> login(String correo, String contrasena) {
        if (correo == null || correo.isBlank() || contrasena == null || contrasena.isBlank()) {
            throw new ApiException(400, "Correo y contraseña son obligatorios");
        }
        try {
            String correoNormalizado = correo.trim().toLowerCase();
            Optional<Usuario> usuarioOpt = repo.autenticar(correoNormalizado, contrasena);
            if (usuarioOpt.isEmpty()) {
                throw new ApiException(401, "Usuario o contraseña incorrectos");
            }
            Usuario usuario = usuarioOpt.get();
            // Clear password before sending to client
            usuario.setContrasena(null);
            String jwt = com.mycompany.delivery.api.util.JwtUtil.generateToken(usuario);
            java.util.Map<String, Object> userMap = usuario.toMap();
            userMap.put("token", jwt);
            return ApiResponse.success(200, "Inicio de sesion exitoso", userMap);
        } catch (SQLException e) {
            throw new ApiException(500, "Error al autenticar usuario", e);
        }
    }

    // ===========================
    // CHECK EMAIL
    // ===========================
    public ApiResponse<java.util.Map<String, Object>> checkEmail(String correo) {
        if (correo == null || correo.isBlank()) {
            throw new ApiException(400, "El correo es obligatorio");
        }
        try {
            String correoNormalizado = correo.trim().toLowerCase();
            boolean exists = repo.existeCorreo(correoNormalizado);
            var data = new java.util.HashMap<String, Object>();
            data.put("correo", correoNormalizado);
            data.put("exists", exists);
            return ApiResponse.success(200, "Estado del correo", data);
        } catch (SQLException e) {
            throw new ApiException(500, "Error al verificar correo", e);
        }
    }

    // ===========================
    // REGISTRO
    // ===========================
    public ApiResponse<Void> registrar(Usuario usuario) {
        if (usuario == null)
            throw new ApiException(400, "Datos del usuario requeridos");
        if (usuario.getCorreo() == null || usuario.getCorreo().isBlank()) {
            throw new ApiException(400, "El correo es obligatorio");
        }
        if (usuario.getContrasena() == null || usuario.getContrasena().isBlank()) {
            throw new ApiException(400, "La contraseña es obligatoria");
        }
        try {
            String correoNormalizado = usuario.getCorreo().trim().toLowerCase();
            usuario.setCorreo(correoNormalizado);

            if (repo.existeCorreo(correoNormalizado)) {
                throw new ApiException(409, "El correo ya está registrado");
            }

            boolean creado = repo.registrar(usuario);
            if (!creado)
                throw new ApiException(500, "No se pudo registrar el usuario");
            return ApiResponse.created("Usuario registrado correctamente");
        } catch (SQLException e) {
            if ("23505".equals(e.getSQLState())) { // Unique violation
                throw new ApiException(409, "El correo ya está registrado.", e);
            }
            throw new ApiException(500, "Error interno al registrar el usuario", e);
        }
    }

    // ===========================
    // LISTAR USUARIOS
    // ===========================
    public ApiResponse<List<Usuario>> listarUsuarios() {
        try {
            List<Usuario> lista = repo.listarUsuarios();
            lista.forEach(u -> u.setContrasena(null));
            return ApiResponse.success(200, "Usuarios listados correctamente", lista);
        } catch (SQLException e) {
            throw new ApiException(500, "No se pudieron listar los usuarios", e);
        }
    }

    // ===========================
    // OBTENER POR ID
    // ===========================
    public ApiResponse<Usuario> obtenerPorId(long idUsuario) {
        if (idUsuario <= 0)
            throw new ApiException(400, "ID de usuario invalido");
        try {
            Optional<Usuario> usuario = repo.obtenerPorId(idUsuario);
            if (usuario.isEmpty())
                throw new ApiException(404, "Usuario no encontrado");
            Usuario user = usuario.get();
            user.setContrasena(null);
            return ApiResponse.success(200, "Usuario encontrado", user);
        } catch (SQLException e) {
            throw new ApiException(500, "Error al obtener el usuario", e);
        }
    }

    // ===========================
    // ACTUALIZAR DATOS
    // ===========================
    public ApiResponse<Void> actualizarUsuario(Usuario usuario) {
        if (usuario == null || usuario.getIdUsuario() <= 0) {
            throw new ApiException(400, "Datos de usuario invalidos");
        }
        try {
            boolean actualizado = repo.actualizar(usuario);
            if (!actualizado)
                throw new ApiException(404, "Usuario no encontrado para actualizar");
            return ApiResponse.success("Usuario actualizado correctamente");
        } catch (SQLException e) {
            throw new ApiException(500, "Error actualizando usuario", e);
        }
    }

    // ===========================
    // ELIMINAR USUARIO
    // ===========================
    public ApiResponse<Void> eliminarUsuario(long idUsuario) {
        if (idUsuario <= 0)
            throw new ApiException(400, "ID de usuario invalido");
        try {
            boolean eliminado = repo.eliminar(idUsuario);
            if (!eliminado)
                throw new ApiException(404, "Usuario no encontrado para eliminar");
            return ApiResponse.success(204, "Usuario eliminado correctamente", null);
        } catch (SQLException e) {
            throw new ApiException(500, "Error al eliminar usuario", e);
        }
    }
}
