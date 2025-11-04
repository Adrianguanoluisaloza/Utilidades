package com.mycompany.delivery.api.repository;


import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import org.mindrot.jbcrypt.BCrypt;

import com.mycompany.delivery.api.config.Database;
import com.mycompany.delivery.api.model.Usuario;

/**
 * Repositorio que maneja las operaciones CRUD de los usuarios. Implementa
 * autenticacion, registro y actualizacion con cifrado seguro.
 */
public class UsuarioRepository {

    // ===============================
    // AUTENTICAR (LOGIN)
    // ===============================
    public Optional<Usuario> autenticar(String correo, String contrasenaIngresada) throws SQLException {
        String sql = """
                SELECT u.*, r.nombre AS rol_nombre
                FROM usuarios u
                LEFT JOIN roles r ON r.id_rol = u.id_rol
                WHERE LOWER(u.correo) = LOWER(?)
                """;
        try (Connection conn = Database.getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, correo);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    Usuario usuario = mapRow(rs);
                    String hashActual = usuario.getContrasena();

                    if (hashActual == null || contrasenaIngresada == null) {
                        return Optional.empty();
                    }

                    if (hashActual.startsWith("$2")) {
                        if (BCrypt.checkpw(contrasenaIngresada, hashActual)) {
                            return Optional.of(usuario);
                        }
                    } else {
                        if (hashActual.equals(contrasenaIngresada)) {
                            String nuevoHash = BCrypt.hashpw(contrasenaIngresada, BCrypt.gensalt(6));
                            actualizarContrasenaHash(usuario.getIdUsuario(), nuevoHash);
                            usuario.setContrasena(nuevoHash);
                            return Optional.of(usuario);
                        }
                    }
                }
            }
        }
        return Optional.empty();
    }

    private void actualizarContrasenaHash(long idUsuario, String nuevoHash) throws SQLException {
        String updateSql = "UPDATE usuarios SET contrasena = ? WHERE id_usuario = ?";
        try (Connection conn = Database.getConnection(); PreparedStatement stmt = conn.prepareStatement(updateSql)) {
            stmt.setString(1, nuevoHash);
            stmt.setLong(2, idUsuario);
            stmt.executeUpdate();
        }
    }

    // ===============================
    // REGISTRAR NUEVO USUARIO
    // ===============================
    public boolean existeCorreo(String correo) throws SQLException {
        String sql = "SELECT 1 FROM usuarios WHERE LOWER(correo) = LOWER(?) LIMIT 1";
        try (Connection conn = Database.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, correo);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next();
            }
        }
    }

    public boolean registrar(Usuario usuario) throws SQLException {
        String sql = """
                    INSERT INTO usuarios (nombre, correo, contrasena, telefono, id_rol, activo, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, TRUE, NOW(), NOW())
                """;

        try (Connection conn = Database.getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {

            String nombre = usuario.getNombre() != null ? usuario.getNombre().trim() : null;
            String correoNormalizado = usuario.getCorreo() != null
                    ? usuario.getCorreo().trim().toLowerCase()
                    : null;
            String telefono = usuario.getTelefono() != null ? usuario.getTelefono().trim() : null;
            String rol = usuario.getRol() != null ? usuario.getRol().trim().toLowerCase() : "cliente";

            usuario.setCorreo(correoNormalizado);

            stmt.setString(1, nombre);
            stmt.setString(2, correoNormalizado);

            String contrasenaPlana = usuario.getContrasena();
            String hash = BCrypt.hashpw(contrasenaPlana, BCrypt.gensalt(6));
            stmt.setString(3, hash);
            stmt.setString(4, telefono);
            stmt.setInt(5, resolveRoleId(conn, rol));
            return stmt.executeUpdate() > 0;
        }
    }

    // ===============================
    // LISTAR TODOS LOS USUARIOS
    // ===============================
    public List<Usuario> listarUsuarios() throws SQLException {
        List<Usuario> lista = new ArrayList<>();
        String sql = """
                SELECT u.*, r.nombre AS rol_nombre
                FROM usuarios u
                LEFT JOIN roles r ON r.id_rol = u.id_rol
                ORDER BY u.id_usuario ASC
                """;
        try (Connection conn = Database.getConnection();
                PreparedStatement stmt = conn.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                lista.add(mapRow(rs));
            }
        }
        return lista;
    }

    // ===============================
    // OBTENER POR ID
    // ===============================
    public Optional<Usuario> obtenerPorId(long idUsuario) throws SQLException {
        String sql = """
                SELECT u.*, r.nombre AS rol_nombre
                FROM usuarios u
                LEFT JOIN roles r ON r.id_rol = u.id_rol
                WHERE u.id_usuario = ?
                """;
        try (Connection conn = Database.getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, idUsuario);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(mapRow(rs));
                }
            }
        }
        return Optional.empty();
    }

    // ===============================
    // ACTUALIZAR DATOS
    // ===============================
    public boolean actualizar(Usuario usuario) throws SQLException {
        try (Connection conn = Database.getConnection()) {
            // Construir SQL dinámicamente solo para campos no nulos
            StringBuilder sql = new StringBuilder("UPDATE usuarios SET updated_at = NOW()");
            List<Object> params = new ArrayList<>();
            
            if (usuario.getNombre() != null) {
                sql.append(", nombre = ?");
                params.add(usuario.getNombre());
            }
            if (usuario.getCorreo() != null) {
                sql.append(", correo = ?");
                params.add(usuario.getCorreo());
            }
            if (usuario.getTelefono() != null) {
                sql.append(", telefono = ?");
                params.add(usuario.getTelefono());
            }
            if (usuario.getContrasena() != null && !usuario.getContrasena().isBlank()) {
                sql.append(", contrasena = ?");
                String contrasena = usuario.getContrasena();
                if (!contrasena.startsWith("$2")) {
                    params.add(BCrypt.hashpw(contrasena, BCrypt.gensalt(6)));
                } else {
                    params.add(contrasena);
                }
            }
            if (usuario.getRol() != null) {
                sql.append(", id_rol = ?");
                params.add(resolveRoleId(conn, usuario.getRol()));
            }
            
            sql.append(" WHERE id_usuario = ?");
            params.add(usuario.getIdUsuario());
            
            try (PreparedStatement stmt = conn.prepareStatement(sql.toString())) {
                for (int i = 0; i < params.size(); i++) {
                    Object param = params.get(i);
                    if (param instanceof String) {
                        stmt.setString(i + 1, (String) param);
                    } else if (param instanceof Integer) {
                        stmt.setInt(i + 1, (Integer) param);
                    } else if (param instanceof Long) {
                        stmt.setLong(i + 1, (Long) param);
                    } else if (param instanceof Boolean) {
                        stmt.setBoolean(i + 1, (Boolean) param);
                    }
                }
                
                return stmt.executeUpdate() > 0;
            }
        }
    }

    // ===============================
    // ELIMINAR USUARIO
    // ===============================
    public boolean eliminar(long idUsuario) throws SQLException {
        String sql = "DELETE FROM usuarios WHERE id_usuario = ?";
        try (Connection conn = Database.getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setLong(1, idUsuario);
            return stmt.executeUpdate() > 0;
        }
    }

    // ===============================
    // ACTUALIZAR ROL DE USUARIO
    // ===============================
    public boolean updateRol(long idUsuario, String nuevoRol) throws SQLException {
        String sql = """
            UPDATE usuarios 
            SET id_rol = (SELECT id_rol FROM roles WHERE LOWER(nombre) = LOWER(?))
            WHERE id_usuario = ?
        """;
        try (Connection conn = Database.getConnection(); PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, nuevoRol);
            stmt.setLong(2, idUsuario);
            return stmt.executeUpdate() > 0;
        }
    }

    // ===============================
    // MAPEO RESULTSET A OBJETO
    // ===============================
    private Usuario mapRow(ResultSet rs) throws SQLException {
        Usuario u = new Usuario();
    u.setIdUsuario(rs.getLong("id_usuario"));
        u.setNombre(rs.getString("nombre"));
        u.setCorreo(rs.getString("correo"));
        u.setContrasena(rs.getString("contrasena"));
        u.setTelefono(rs.getString("telefono"));
        String rolNombre = null;
        try {
            rolNombre = rs.getString("rol_nombre");
        } catch (SQLException ignored) {
        }
        if (rolNombre == null) {
            int idRol = rs.getInt("id_rol");
            if (!rs.wasNull()) {
                rolNombre = resolveRoleName(idRol);
            }
        }
        u.setRol(rolNombre != null ? rolNombre : "cliente");
        u.setActivo(rs.getBoolean("activo"));
        // No incluir la contrasena en el mapeo por defecto por seguridad.
        // Se puede anadir un metodo especifico si se necesita explicitamente.
        return u;
    }

    private int resolveRoleId(Connection conn, String rol) throws SQLException {
        String roleName = (rol == null || rol.isBlank()) ? "cliente" : rol.trim().toLowerCase();
        String sql = "SELECT id_rol FROM roles WHERE LOWER(nombre) = LOWER(?)";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, roleName);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("id_rol");
                }
            }
        }
        // Fallback: intentar obtener id de 'cliente'
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, "cliente");
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("id_rol");
                }
            }
        }
        throw new SQLException("No se encontro el rol especificado: " + rol);
    }

    private String resolveRoleName(int idRol) {
        String sql = "SELECT nombre FROM roles WHERE id_rol = ?";
        try (Connection conn = Database.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, idRol);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getString("nombre");
                }
            }
        } catch (SQLException ignored) {
        }
        return "cliente";
    }
}




