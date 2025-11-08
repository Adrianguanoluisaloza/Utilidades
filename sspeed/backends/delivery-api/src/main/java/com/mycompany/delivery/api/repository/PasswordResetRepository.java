package com.mycompany.delivery.api.repository;

import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;

import org.mindrot.jbcrypt.BCrypt;

import com.mycompany.delivery.api.config.Database;
import com.mycompany.delivery.api.model.Usuario;
import com.mycompany.delivery.api.util.ApiException;

public class PasswordResetRepository {

    private static final SecureRandom RAND = new SecureRandom();

    public static class ResetCode {
        public final String code;
        public final Instant expiresAt;
        public final long userId;
        public ResetCode(String code, Instant expiresAt, long userId) {
            this.code = code; this.expiresAt = expiresAt; this.userId = userId;
        }
    }

    private String generate6DigitCode() {
        int n = 100000 + RAND.nextInt(900000); // 6 digits
        return Integer.toString(n);
    }

    public Optional<Usuario> findUserByEmail(String correo) throws SQLException {
        String sql = "SELECT u.*, r.nombre AS rol_nombre FROM usuarios u LEFT JOIN roles r ON r.id_rol = u.id_rol WHERE LOWER(u.correo)=LOWER(?)";
        try (Connection c = Database.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, correo);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Usuario u = new Usuario();
                    u.setIdUsuario(rs.getLong("id_usuario"));
                    u.setCorreo(rs.getString("correo"));
                    u.setNombre(rs.getString("nombre"));
                    String rolNombre = rs.getString("rol_nombre");
                    if (rolNombre == null) {
                        rolNombre = "cliente";
                    }
                    u.setRol(rolNombre);
                    u.setActivo(rs.getBoolean("activo"));
                    return Optional.of(u);
                }
            }
        }
        return Optional.empty();
    }

    public ResetCode generarCodigo(String correo, Long createdBy) throws SQLException {
        Optional<Usuario> userOpt = findUserByEmail(correo);
        if (userOpt.isEmpty()) {
            throw new ApiException(404, "Usuario no encontrado para ese correo");
        }
        long userId = userOpt.get().getIdUsuario();
        String code = generate6DigitCode();
        String hash = BCrypt.hashpw(code, BCrypt.gensalt(6));
        Instant now = Instant.now();
        Instant exp = now.plus(15, ChronoUnit.MINUTES);

        String ins = "INSERT INTO password_resets(user_id, code_hash, created_at, expires_at, created_by) VALUES (?,?,?,?,?)";
        try (Connection c = Database.getConnection(); PreparedStatement ps = c.prepareStatement(ins)) {
            ps.setLong(1, userId);
            ps.setString(2, hash);
            ps.setTimestamp(3, Timestamp.from(now));
            ps.setTimestamp(4, Timestamp.from(exp));
            if (createdBy != null) ps.setLong(5, createdBy); else ps.setNull(5, Types.INTEGER);
            ps.executeUpdate();
        }
        return new ResetCode(code, exp, userId);
    }

    public boolean confirmar(String correo, String codigo, String nuevaContrasena) throws SQLException {
        Optional<Usuario> userOpt = findUserByEmail(correo);
        if (userOpt.isEmpty()) {
            throw new ApiException(404, "Usuario no encontrado para ese correo");
        }
        long userId = userOpt.get().getIdUsuario();
        String sel = "SELECT id, code_hash, expires_at, used_at FROM password_resets WHERE user_id = ? AND used_at IS NULL ORDER BY created_at DESC LIMIT 1";
        try (Connection c = Database.getConnection(); PreparedStatement ps = c.prepareStatement(sel)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new ApiException(400, "No hay un código de recuperación activo. Genera uno nuevo.");
                }
                long resetId = rs.getLong("id");
                String hash = rs.getString("code_hash");
                Timestamp exp = rs.getTimestamp("expires_at");
                if (exp == null || exp.toInstant().isBefore(Instant.now())) {
                    throw new ApiException(400, "El código ha expirado. Genera uno nuevo.");
                }
                if (!BCrypt.checkpw(codigo, hash)) {
                    throw new ApiException(401, "Código inválido");
                }
                // Actualizar contraseña del usuario
                String nuevoHash = BCrypt.hashpw(nuevaContrasena, BCrypt.gensalt(6));
                try (PreparedStatement up = c.prepareStatement("UPDATE usuarios SET contrasena=?, updated_at=NOW() WHERE id_usuario=?")) {
                    up.setString(1, nuevoHash);
                    up.setLong(2, userId);
                    up.executeUpdate();
                }
                try (PreparedStatement up2 = c.prepareStatement("UPDATE password_resets SET used_at = NOW() WHERE id=?")) {
                    up2.setLong(1, resetId);
                    up2.executeUpdate();
                }
                return true;
            }
        }
    }
}
