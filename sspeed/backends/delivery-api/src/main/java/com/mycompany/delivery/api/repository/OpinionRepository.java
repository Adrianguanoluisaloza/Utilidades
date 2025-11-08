package com.mycompany.delivery.api.repository;

import com.mycompany.delivery.api.config.Database;
import java.sql.*;
import java.util.*;

public class OpinionRepository {

    public List<Map<String, Object>> listarOpinionesAprobadas(int limit) throws SQLException {
        String sql = """
            SELECT 
                id_opinion,
                nombre,
                rating,
                comentario,
                clasificacion,
                plataforma,
                created_at
            FROM opiniones 
            WHERE estado = 'aprobada' 
            ORDER BY created_at DESC 
            LIMIT ?
        """;
        
        List<Map<String, Object>> opiniones = new ArrayList<>();
        
        try (Connection conn = Database.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setInt(1, limit);
            
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> opinion = new HashMap<>();
                    opinion.put("id", rs.getInt("id_opinion"));
                    opinion.put("nombre", rs.getString("nombre"));
                    opinion.put("rating", rs.getInt("rating"));
                    opinion.put("comentario", rs.getString("comentario"));
                    opinion.put("clasificacion", rs.getString("clasificacion"));
                    opinion.put("plataforma", rs.getString("plataforma"));
                    opinion.put("fecha", rs.getTimestamp("created_at"));
                    opiniones.add(opinion);
                }
            }
        }
        
        return opiniones;
    }
    
    public boolean crearOpinion(Integer idUsuario, String nombre, String email, 
                               int rating, String comentario, String plataforma) throws SQLException {
        String sql = """
            INSERT INTO opiniones (id_usuario, nombre, email, rating, comentario, plataforma)
            VALUES (?, ?, ?, ?, ?, ?)
        """;
        
        try (Connection conn = Database.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            
            stmt.setObject(1, idUsuario);
            stmt.setString(2, nombre);
            stmt.setString(3, email);
            stmt.setInt(4, rating);
            stmt.setString(5, comentario);
            stmt.setString(6, plataforma);
            
            int rowsAffected = stmt.executeUpdate();
            return rowsAffected > 0;
        }
    }
    
    public List<Map<String, Object>> listarOpinionesAdmin(String clasificacion, int limit) throws SQLException {
        StringBuilder sql = new StringBuilder("""
            SELECT 
                id_opinion,
                id_usuario,
                nombre,
                email,
                rating,
                comentario,
                clasificacion,
                plataforma,
                estado,
                created_at,
                updated_at
            FROM opiniones
        """);
        
        List<Object> params = new ArrayList<>();
        
        if (clasificacion != null && !clasificacion.trim().isEmpty()) {
            sql.append(" WHERE clasificacion = ?");
            params.add(clasificacion.trim());
        }
        
        sql.append(" ORDER BY created_at DESC LIMIT ?");
        params.add(limit);
        
        List<Map<String, Object>> opiniones = new ArrayList<>();
        
        try (Connection conn = Database.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql.toString())) {
            
            for (int i = 0; i < params.size(); i++) {
                stmt.setObject(i + 1, params.get(i));
            }
            
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> opinion = new HashMap<>();
                    opinion.put("id", rs.getInt("id_opinion"));
                    opinion.put("id_usuario", rs.getObject("id_usuario"));
                    opinion.put("nombre", rs.getString("nombre"));
                    opinion.put("email", rs.getString("email"));
                    opinion.put("rating", rs.getInt("rating"));
                    opinion.put("comentario", rs.getString("comentario"));
                    opinion.put("clasificacion", rs.getString("clasificacion"));
                    opinion.put("plataforma", rs.getString("plataforma"));
                    opinion.put("estado", rs.getString("estado"));
                    opinion.put("created_at", rs.getTimestamp("created_at"));
                    opinion.put("updated_at", rs.getTimestamp("updated_at"));
                    opiniones.add(opinion);
                }
            }
        }
        
        return opiniones;
    }
}