package com.mycompany.delivery.api.util;

import com.auth0.jwt.JWT;
import com.auth0.jwt.JWTVerifier;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.interfaces.DecodedJWT;
import com.mycompany.delivery.api.model.Usuario;
import io.github.cdimascio.dotenv.Dotenv;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;
import java.util.Optional;

/**
 * Utilidad para generar y verificar JWT usando HMAC256.
 * Configuración por variables de entorno (.env):
 *  - JWT_SECRET (obligatorio en producción)
 *  - JWT_ISSUER (opcional, por defecto: delivery-api)
 *  - JWT_EXPIRES_HOURS (opcional, por defecto: 168 = 7 días)
 */
public final class JwtUtil {

    private static final String DEFAULT_ISSUER = "delivery-api";
    private static final int DEFAULT_EXP_HOURS = 168; // 7 días

    private static final String secret;
    private static final String issuer;
    private static final int expiresHours;
    private static final Algorithm algorithm;
    private static final JWTVerifier verifier;

    static {
        Dotenv env = Dotenv.configure().ignoreIfMissing().load();
        String envSecret = env.get("JWT_SECRET");

        // En dev, permitir un secreto por defecto; en prod se recomienda definir JWT_SECRET
        if (envSecret == null || envSecret.isBlank()) {
            envSecret = "dev-secret-change-me";
        }
        secret = envSecret;
        issuer = Optional.ofNullable(env.get("JWT_ISSUER")).filter(s -> !s.isBlank()).orElse(DEFAULT_ISSUER);
        int expH;
        try {
            expH = Integer.parseInt(Optional.ofNullable(env.get("JWT_EXPIRES_HOURS")).orElse("" + DEFAULT_EXP_HOURS));
        } catch (NumberFormatException e) {
            expH = DEFAULT_EXP_HOURS;
        }
        expiresHours = expH;
        algorithm = Algorithm.HMAC256(secret);
        verifier = JWT.require(algorithm).withIssuer(issuer).build();
    }

    private JwtUtil() {}

    public static String generateToken(Usuario user) {
        Instant now = Instant.now();
        Instant exp = now.plus(expiresHours, ChronoUnit.HOURS);
        return JWT.create()
                .withIssuer(issuer)
                .withIssuedAt(Date.from(now))
                .withExpiresAt(Date.from(exp))
                .withSubject(String.valueOf(user.getIdUsuario()))
                .withClaim("email", user.getCorreo())
                .withClaim("rol", user.getRol())
                .withClaim("nombre", user.getNombre())
                .sign(algorithm);
    }

    public static DecodedJWT verify(String token) throws ApiException {
        try {
            return verifier.verify(token);
        } catch (Exception e) {
            throw new ApiException(401, "Token inválido o expirado", e);
        }
    }

    public static long getUserId(DecodedJWT jwt) throws ApiException {
        try {
            return Long.parseLong(jwt.getSubject());
        } catch (NumberFormatException e) {
            throw new ApiException(401, "Sub del token inválido", e);
        }
    }
}
