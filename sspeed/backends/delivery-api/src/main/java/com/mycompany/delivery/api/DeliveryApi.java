package com.mycompany.delivery.api;

import com.google.gson.Gson;
import com.google.gson.JsonSyntaxException;
import com.mycompany.delivery.api.controller.*;
import com.mycompany.delivery.api.model.*;
import com.mycompany.delivery.api.payloads.Payloads;
import com.mycompany.delivery.api.payloads.Payloads.PedidoPayload;
import com.mycompany.delivery.api.repository.ChatRepository;
import com.mycompany.delivery.api.repository.DashboardDAO;
import com.mycompany.delivery.api.repository.NegocioRepository;
import com.mycompany.delivery.api.repository.PedidoRepository;
import com.mycompany.delivery.api.repository.RespuestaSoporteRepository;
import com.mycompany.delivery.api.repository.SoporteRepository;
import com.mycompany.delivery.api.util.ApiException;
import com.mycompany.delivery.api.services.GeminiService;
import com.mycompany.delivery.api.util.ApiResponse;
import com.mycompany.delivery.api.config.Database;
import com.mycompany.delivery.api.util.FeatureFlags;

import io.github.cdimascio.dotenv.Dotenv;
import io.javalin.Javalin;
import io.javalin.http.BadRequestResponse;
import io.javalin.http.Context;
import io.javalin.json.JsonMapper;
import org.jetbrains.annotations.NotNull;

import java.lang.reflect.Type;
import java.sql.SQLException;
import java.util.*;

import static com.mycompany.delivery.api.payloads.Payloads.*;
import com.mycompany.delivery.api.payloads.Payloads.UbicacionesRequest;
import com.mycompany.delivery.api.util.ChatBotResponder;
import static com.mycompany.delivery.api.util.UbicacionValidator.*;
import com.mycompany.delivery.api.util.RequestValidator;

/**
 * API principal unificada, migrada a Javalin.
 */
public class DeliveryApi {

    private static final Gson GSON = new Gson();
    private static final long START_TIME = System.currentTimeMillis();
    private static final UsuarioController USUARIO_CONTROLLER = new UsuarioController();
    private static final ProductoController PRODUCTO_CONTROLLER = new ProductoController();
    private static final PedidoController PEDIDO_CONTROLLER = new PedidoController();
    private static final UbicacionController UBICACION_CONTROLLER = new UbicacionController();
    private static final RecomendacionController RECOMENDACION_CONTROLLER = new RecomendacionController();
    private static final NegocioController NEGOCIO_CONTROLLER = new NegocioController();
    private static final DashboardDAO DASHBOARD_DAO = new DashboardDAO();
    private static final SoporteRepository SOPORTE_REPO = new SoporteRepository();
    private static final RespuestaSoporteRepository RESPUESTA_SOPORTE_REPO = new RespuestaSoporteRepository();
    private static final ChatRepository CHAT_REPOSITORY = new ChatRepository();
    private static final GeminiService GEMINI_SERVICE = new GeminiService();
    private static final PedidoRepository PEDIDO_REPOSITORY = new PedidoRepository();
    private static final ChatBotResponder CHATBOT_RESPONDER = new ChatBotResponder(GEMINI_SERVICE, PEDIDO_REPOSITORY,
            CHAT_REPOSITORY);
    private static final NegocioRepository NEGOCIO_REPOSITORY = new NegocioRepository();

    public static void main(String[] args) {
        Dotenv.load();
        validateEnvironment(); // Validar variables críticas

        final int port = resolvePort();
        System.out.println("✅ Iniciando servidor en puerto " + port + "...");

        Javalin app = Javalin.create(config -> {
            config.jsonMapper(new JsonMapper() {
                @Override
                public @NotNull
                String toJsonString(@NotNull Object obj, @NotNull Type type) {
                    return GSON.toJson(obj, type);
                }

                @Override
                public <T> T fromJsonString(@NotNull String json, @NotNull Type targetType) throws JsonSyntaxException {
                    return GSON.fromJson(json, targetType);
                }
            });
            try {
                // Serve static files from classpath '/public' only if present to avoid startup
                // failure.
                java.net.URL res = DeliveryApi.class.getResource("/public");
                if (res != null) {
                    config.staticFiles.add(staticFiles -> {
                        staticFiles.hostedPath = "/";
                        staticFiles.directory = "public";
                        staticFiles.location = io.javalin.http.staticfiles.Location.CLASSPATH;
                    });
                }
            } catch (Exception e) {
                // Ignore missing static resources silently
            }
        }).start(port);

        // ============ CORS CONFIGURATION ============
        // Permitir requests desde S3 y cualquier origen (para desarrollo académico)
        app.before(ctx -> {
            ctx.header("Access-Control-Allow-Origin", "*");
            ctx.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS, PATCH");
            ctx.header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With");
            ctx.header("Access-Control-Max-Age", "3600");
        });

        // Manejar preflight requests OPTIONS
        app.options("/*", ctx -> {
            ctx.status(io.javalin.http.HttpStatus.OK);
        });

        // Logging básico de requests/responses
        app.before(ctx -> {
            ctx.attribute("__t0", System.nanoTime());
        });
        app.after(ctx -> {
            Long t0 = ctx.attribute("__t0");
            if (t0 != null) {
                long ms = (System.nanoTime() - t0) / 1_000_000L;
                // En Javalin 6.x, ctx.status() devuelve HttpStatus (no int). Usar %s.
                System.out.printf("%s %s -> %s (%d ms)%n", ctx.method(), ctx.path(), ctx.status(), ms);
            }
        });

        // Middleware global de manejo de errores
        app.exception(ApiException.class, (e, ctx) -> {
            ApiException apiEx = (ApiException) e;
            int status = apiEx.getStatus();
            Object details = apiEx.getDetails();

            // Log error para monitoreo
            System.err.printf("[ApiException] %d - %s%n", status, e.getMessage());
            if (apiEx.getCause() != null) {
                apiEx.getCause().printStackTrace();
            }

            ctx.status(io.javalin.http.HttpStatus.forStatus(status));
            ctx.json(ApiResponse.error(status, e.getMessage(), details));
        });

        // Handler para excepciones SQL no capturadas
        app.exception(SQLException.class, (e, ctx) -> {
            System.err.println("[SQLException] Error de base de datos:");
            e.printStackTrace();
            ctx.status(io.javalin.http.HttpStatus.INTERNAL_SERVER_ERROR);
            ctx.json(ApiResponse.error(500, "Error interno del servidor (BD)", null));
        });

        // Handler para NullPointerException
        app.exception(NullPointerException.class, (e, ctx) -> {
            System.err.println("[NullPointerException] Error inesperado:");
            e.printStackTrace();
            ctx.status(io.javalin.http.HttpStatus.INTERNAL_SERVER_ERROR);
            ctx.json(ApiResponse.error(500, "Error interno del servidor", null));
        });

        // Handler genérico para otras excepciones
        app.exception(Exception.class, (e, ctx) -> {
            System.err.println("[Exception] Error no manejado:");
            e.printStackTrace();
            ctx.status(io.javalin.http.HttpStatus.INTERNAL_SERVER_ERROR);
            ctx.json(ApiResponse.error(500, "Error interno del servidor", e.getMessage()));
        });

        // Auth opcional: registra el usuario autenticado en el contexto si viene Authorization: Bearer <token>
        app.before(ctx -> {
            String auth = ctx.header("Authorization");
            if (auth != null && auth.toLowerCase(Locale.ROOT).startsWith("bearer ")) {
                String token = auth.substring(7).trim();
                try {
                    Usuario user = USUARIO_CONTROLLER.validarToken(token);
                    ctx.attribute("authUser", user);
                } catch (ApiException ex) {
                    // No corta el flujo aquí; la verificación estricta se aplica en rutas protegidas
                }
            }
        });

        // Proteger rutas administrativas y operaciones sensibles
        app.before(ctx -> {
            final String p = ctx.path();
            final boolean isWrite = ctx.method() == io.javalin.http.HandlerType.POST
                    || ctx.method() == io.javalin.http.HandlerType.PUT
                    || ctx.method() == io.javalin.http.HandlerType.PATCH
                    || ctx.method() == io.javalin.http.HandlerType.DELETE;
            boolean needsAuth = p.startsWith("/admin")
                    || (p.startsWith("/pedidos") && isWrite)
                    || (p.startsWith("/ubicaciones") && isWrite)
                    || (p.startsWith("/productos") && isWrite);

            // Excluir chat y soporte de autenticación
            if (p.startsWith("/chat/") || p.startsWith("/soporte/")) {
                needsAuth = false;
            }

            if (needsAuth) {
                if (ctx.attribute("authUser") == null) {
                    throw new ApiException(401, "No autorizado: falta token válido");
                }
            }
        });

        // --- HEALTH & VERSION ---
        app.get("/health", ctx -> {
            boolean dbOk = true;
            String dbErr = null;
            try {
                Database.ping();
            } catch (RuntimeException ex) {
                dbOk = false;
                dbErr = ex.getMessage();
            }
            long uptime = System.currentTimeMillis() - START_TIME;
            Map<String, Object> db = new HashMap<>();
            db.put("connected", dbOk);
            db.put("error", dbErr);
            Map<String, Object> body = new HashMap<>();
            body.put("status", dbOk ? "UP" : "DEGRADED");
            body.put("uptimeMs", uptime);
            body.put("db", db);
            ctx.status(dbOk ? io.javalin.http.HttpStatus.OK : io.javalin.http.HttpStatus.SERVICE_UNAVAILABLE);
            ctx.json(body);
        });

        app.get("/version", ctx -> {
            String version = Optional.ofNullable(DeliveryApi.class.getPackage().getImplementationVersion()).orElse("dev");
            Map<String, Object> body = new HashMap<>();
            body.put("name", "delivery-api");
            body.put("version", version);
            body.put("time", new Date().toString());
            ctx.json(body);
        });

        app.get("/negocios/{id}/stats", ctx -> {
            long negocioId = Long.parseLong(ctx.pathParam("id"));
            var stats = NEGOCIO_REPOSITORY.getNegocioStats(negocioId);
            handleResponse(ctx, ApiResponse.success(200, "Estadisticas del negocio", stats));
        });

        // --- FEATURES ---
        app.get("/features", ctx -> {
            var features = java.util.Map.of(
                    "gpt5", FeatureFlags.isGpt5Enabled()
            );
            handleResponse(ctx, ApiResponse.success(200, "Features", features));
        });

        // =============== AUTHENTICATION ===============
        app.post("/auth/login", ctx -> {
            var body = ctx.bodyAsClass(Payloads.LoginRequest.class);
            RequestValidator.requireEmail(body.getCorreo(), "correo");
            RequestValidator.requireMinLength(body.getContrasena(), 6, "contrasena");
            handleResponse(ctx, USUARIO_CONTROLLER.login(body.getCorreo(), body.getContrasena()));
        });

        // Verificar disponibilidad de correo (para UX de registro)
        app.get("/usuarios/check-email", ctx -> {
            String correo = ctx.queryParam("correo");
            RequestValidator.requireEmail(correo, "correo");
            handleResponse(ctx, USUARIO_CONTROLLER.checkEmail(correo));
        });

        // Registrar el resto de rutas de la API (chat, soporte, tracking, usuarios,
        // etc.)
        registerRoutes(app);
    }

    private static int resolvePort() {
        // Prioridad: propiedad del sistema -> variable de entorno -> .env -> 7070
        String[] keys = new String[]{"PORT", "SERVER_PORT"};
        for (String k : keys) {
            String v = System.getProperty(k);
            if (v != null && !v.isBlank()) {
                try {
                    return Integer.parseInt(v.trim());
                } catch (NumberFormatException ignored) {
                }
            }
        }
        for (String k : keys) {
            String v = System.getenv(k);
            if (v != null && !v.isBlank()) {
                try {
                    return Integer.parseInt(v.trim());
                } catch (NumberFormatException ignored) {
                }
            }
        }
        try {
            String v = com.mycompany.delivery.api.config.Config.get("PORT");
            if (v != null && !v.isBlank()) {
                return Integer.parseInt(v.trim());
            }
        } catch (Exception ignored) {
        }
        try {
            String v = io.github.cdimascio.dotenv.Dotenv.configure().ignoreIfMissing().load().get("PORT");
            if (v != null && !v.isBlank()) {
                return Integer.parseInt(v.trim());
            }
        } catch (Exception ignored) {
        }
        return 7070;
    }

    private static void registerRoutes(Javalin app) {
        // --- AUTH ---
        app.post("/login", ctx -> {
            var body = ctx.bodyAsClass(LoginRequest.class);
            RequestValidator.requireEmail(body.getCorreo(), "correo");
            RequestValidator.requireMinLength(body.getContrasena(), 6, "contrasena");
            handleResponse(ctx, USUARIO_CONTROLLER.login(body.getCorreo(), body.getContrasena()));
        });
        // Generar código de reset (sin email/SMS). Devuelve el código al cliente para compartir/mostrar.
        app.post("/auth/reset/generar", ctx -> {
            var body = ctx.bodyAsClass(Payloads.ResetGenerateRequest.class);
            String correo = RequestValidator.requireEmail(body.correo, "correo");
            var pr = new com.mycompany.delivery.api.repository.PasswordResetRepository();
            try {
                Long createdBy = Optional.ofNullable((Usuario) ctx.attribute("authUser")).map(Usuario::getIdUsuario).orElse(null);
                var rc = pr.generarCodigo(correo, createdBy);
                Map<String, Object> data = new HashMap<>();
                data.put("correo", correo);
                data.put("codigo", rc.code); // Nota: solo para entorno académico; no exponer en producción
                long minutes = java.time.Duration.between(java.time.Instant.now(), rc.expiresAt).toMinutes();
                data.put("expiresInMinutes", Math.max(minutes, 0));

                // Enviar el código al chat de soporte interno (sin costo) para que el usuario
                // lo vea en la app. Esto facilita la entrega en entornos académicos/tiendas.
                try {
                    var usuarioRepo = new com.mycompany.delivery.api.repository.UsuarioRepository();
                    var usuarioOpt = usuarioRepo.obtenerPorId(rc.userId);
                    String rol = "cliente";
                    if (usuarioOpt.isPresent()) {
                        rol = usuarioOpt.get().getRol();
                    }
                    long idConv = SOPORTE_REPO.ensureSoporteConversacion(rc.userId, rol);
                    String mensaje = "Código de recuperación: " + rc.code + " (expira en ~" + Math.max(minutes, 0) + " min)";
                    SOPORTE_REPO.insertMensajeUsuario(idConv, rc.userId, mensaje);
                } catch (Exception e) {
                    // No bloquear el flujo si falla la inserción al chat; solo loguear.
                    System.err.println("⚠️ No se pudo enviar el código al chat de soporte: " + e.getMessage());
                }

                handleResponse(ctx, ApiResponse.success(201, "Código de recuperación generado", data));
            } catch (SQLException e) {
                throw new ApiException(500, "No se pudo generar el código de recuperación", e);
            }
        });
        // Confirmar reset con código y nueva contraseña
        app.post("/auth/reset/confirmar", ctx -> {
            var body = ctx.bodyAsClass(Payloads.ResetConfirmRequest.class);
            String correo = RequestValidator.requireEmail(body.correo, "correo");
            RequestValidator.requireNonBlank(body.codigo, "codigo");
            RequestValidator.requireMinLength(body.nuevaContrasena, 6, "nuevaContrasena");
            var pr = new com.mycompany.delivery.api.repository.PasswordResetRepository();
            try {
                boolean ok = pr.confirmar(correo, body.codigo, body.nuevaContrasena);
                if (!ok) {
                    throw new ApiException(500, "No se pudo actualizar la contraseña");
                }
                handleResponse(ctx, ApiResponse.success(200, "Contraseña restablecida correctamente", null));
            } catch (SQLException e) {
                throw new ApiException(500, "No se pudo confirmar el restablecimiento", e);
            }
        });
        // Cambiar contraseña (autenticado)
        app.put("/auth/cambiar-password", ctx -> {
            Usuario auth = ctx.attribute("authUser");
            var body = ctx.bodyAsClass(Payloads.ChangePasswordRequest.class);
            RequestValidator.requireMinLength(body.nueva, 6, "nueva");
            handleResponse(ctx, USUARIO_CONTROLLER.cambiarContrasena(auth, body.actual, body.nueva));
        });
        app.post("/registro", ctx -> {
            var b = ctx.bodyAsClass(Payloads.RegistroRequest.class);

            // Normalizar rol: cliente, delivery/repartidor, negocio, admin, soporte
            String rolNormalizado = b.rol != null ? b.rol.trim().toLowerCase() : "cliente";
            if ("repartidor".equals(rolNormalizado)) {
                rolNormalizado = "delivery";
            }

            // Validar rol permitido para registro público
            if (!"cliente".equals(rolNormalizado)
                    && !"delivery".equals(rolNormalizado)
                    && !"negocio".equals(rolNormalizado)) {
                throw new ApiException(400,
                        "El rol especificado '" + b.rol + "' no es válido. Debe ser 'cliente', 'delivery' o 'negocio'.");
            }

            var u = new Usuario();
            u.setNombre(com.mycompany.delivery.api.util.RequestValidator.requireNonBlank(b.nombre, "nombre es obligatorio"));
            u.setCorreo(RequestValidator.requireEmail(b.correo, "correo"));
            RequestValidator.requireMinLength(b.contrasena, 6, "contrasena");
            u.setNombre(b.nombre);
            u.setCorreo(b.correo);
            u.setContrasena(b.contrasena);
            u.setTelefono(b.telefono);
            u.setRol(rolNormalizado);  // Usa el rol ya normalizado
            handleResponse(ctx, USUARIO_CONTROLLER.registrar(u));
        });
        app.get("/usuarios", ctx -> {
            handleResponse(ctx, USUARIO_CONTROLLER.listarUsuarios());
        });
        app.get("/usuarios/{id}", ctx -> {
            var id = getLongId(ctx, "id");
            handleResponse(ctx, USUARIO_CONTROLLER.obtenerPorId(id));
        });
        app.put("/usuarios/{id}", ctx -> {
            var id = getLongId(ctx, "id");
            Usuario usuario = ctx.bodyAsClass(Usuario.class);
            usuario.setIdUsuario(id);
            // Validaciones suaves opcionales: solo si vienen presentes
            if (usuario.getCorreo() != null) {
                usuario.setCorreo(RequestValidator.requireEmail(usuario.getCorreo(), "correo"));
            }
            if (usuario.getNombre() != null) {
                usuario.setNombre(RequestValidator.requireNonBlank(usuario.getNombre(), "nombre es obligatorio"));
            }
            if (usuario.getContrasena() != null) {
                RequestValidator.requireMinLength(usuario.getContrasena(), 6, "contrasena");
            }
            handleResponse(ctx, USUARIO_CONTROLLER.actualizarUsuario(usuario));
        });
        // (eliminado duplicado) PUT /usuarios/{id}/negocio ya se define más abajo en la sección "NEGOCIO DEL USUARIO"
        app.delete("/usuarios/{id}", ctx -> {
            var id = getLongId(ctx, "id");
            handleResponse(ctx, USUARIO_CONTROLLER.eliminarUsuario(id));
        });

        // --- NEGOCIO DEL USUARIO ---
        app.get("/usuarios/{id}/negocio", ctx -> {
            int id = getIntId(ctx, "id");
            handleResponse(ctx, NEGOCIO_CONTROLLER.obtenerPorUsuario(id));
        });
        app.post("/usuarios/{id}/negocio", ctx -> {
            int id = getIntId(ctx, "id");
            Negocio negocio = ctx.bodyAsClass(Negocio.class);
            handleResponse(ctx, NEGOCIO_CONTROLLER.registrarONActualizar(id, negocio));
        });
        app.put("/usuarios/{id}/negocio", ctx -> {
            int id = getIntId(ctx, "id");
            Negocio negocio = ctx.bodyAsClass(Negocio.class);
            handleResponse(ctx, NEGOCIO_CONTROLLER.registrarONActualizar(id, negocio));
        });

        // --- PRODUCTOS ---
        app.get("/productos", ctx -> {
            String q = ctx.queryParam("query");
            String cat = ctx.queryParam("categoria");
            var resp = (q != null || cat != null) ? PRODUCTO_CONTROLLER.buscarProductos(q, cat)
                    : PRODUCTO_CONTROLLER.getAllProductos();
            handleResponse(ctx, resp);
        });
        app.get("/productos/{id}", ctx -> {
            int id = getIntId(ctx, "id");
            handleResponse(ctx, PRODUCTO_CONTROLLER.obtenerProducto(id));
        });
        app.get("/admin/productos", ctx -> {
            handleResponse(ctx, PRODUCTO_CONTROLLER.getAllProductos());
        });
        app.post("/admin/productos", ctx -> {
            Producto producto = ctx.bodyAsClass(Producto.class);
            handleResponse(ctx, PRODUCTO_CONTROLLER.createProducto(producto));
        });
        app.put("/admin/productos/{id}", ctx -> {
            int id = getIntId(ctx, "id");
            Producto producto = ctx.bodyAsClass(Producto.class);
            handleResponse(ctx, PRODUCTO_CONTROLLER.updateProducto(id, producto));
        });
        app.delete("/admin/productos/{id}", ctx -> {
            int id = getIntId(ctx, "id");
            handleResponse(ctx, PRODUCTO_CONTROLLER.deleteProducto(id));
        });

        // --- CATEGORIAS ---
        app.get("/categorias", ctx -> {
            handleResponse(ctx, PRODUCTO_CONTROLLER.obtenerCategorias());
        });
        // Nuevo endpoint: categorías directas desde la tabla (incluye vacías)
        app.get("/categorias-db", ctx -> {
            handleResponse(ctx, PRODUCTO_CONTROLLER.obtenerCategoriasDb());
        });

        // --- NEGOCIOS PUBLICOS ---
        app.get("/negocios", ctx -> {
            var all = USUARIO_CONTROLLER.listarUsuarios();
            java.util.List<Usuario> lista = (java.util.List<Usuario>) all.getData();
            var negocios = new java.util.ArrayList<java.util.Map<String, Object>>();
            if (lista != null) {
                for (var u : lista) {
                    if ("negocio".equalsIgnoreCase(u.getRol())) {
                        negocios.add(u.toMap());
                    }
                }
            }
            handleResponse(ctx, ApiResponse.success(200, "Negocios listados", negocios));
        });
        app.get("/negocios/{id}", ctx -> {
            var id = getLongId(ctx, "id");
            var usuario = USUARIO_CONTROLLER.obtenerPorId(id);
            if (usuario.getData() != null && "negocio".equalsIgnoreCase(((Usuario) usuario.getData()).getRol())) {
                handleResponse(ctx, usuario);
            } else {
                throw new ApiException(404, "Negocio no encontrado");
            }
        });

        // --- NEGOCIOS (usa usuarios con rol negocio) ---
        app.get("/admin/negocios", ctx -> {
            var all = USUARIO_CONTROLLER.listarUsuarios();
            java.util.List<com.mycompany.delivery.api.model.Usuario> lista = (java.util.List<com.mycompany.delivery.api.model.Usuario>) all.getData();
            var negocios = new java.util.ArrayList<java.util.Map<String, Object>>();
            if (lista != null) {
                for (var u : lista) {
                    if ("negocio".equalsIgnoreCase(u.getRol())) {
                        negocios.add(u.toMap());
                    }
                }
            }
            handleResponse(ctx, ApiResponse.success(200, "Negocios listados", negocios));
        });
        app.post("/admin/negocios", ctx -> {
            Usuario u = ctx.bodyAsClass(Usuario.class);
            RequestValidator.requireNonBlank(u.getNombre(), "nombre es obligatorio");
            RequestValidator.requireEmail(u.getCorreo(), "correo");
            RequestValidator.requireMinLength(u.getContrasena(), 6, "contrasena");
            u.setRol("negocio");
            handleResponse(ctx, USUARIO_CONTROLLER.registrar(u));
        });
        app.get("/admin/negocios/{id}", ctx -> {
            var id = getLongId(ctx, "id");
            handleResponse(ctx, USUARIO_CONTROLLER.obtenerPorId(id));
        });
        app.put("/admin/negocios/{id}", ctx -> {
            var id = getLongId(ctx, "id");
            Usuario body = ctx.bodyAsClass(Usuario.class);
            body.setIdUsuario(id);
            body.setRol("negocio");
            handleResponse(ctx, USUARIO_CONTROLLER.actualizarUsuario(body));
        });
        app.get("/admin/negocios/{id}/productos", ctx -> {
            int id = getIntId(ctx, "id");
            var negocio = USUARIO_CONTROLLER.obtenerPorId(id).getData();
            if (negocio == null || !"negocio".equalsIgnoreCase(((Usuario) negocio).getRol())) {
                throw new ApiException(404, "Negocio no encontrado");
            }
            var prov = ((Usuario) negocio).getNombre();
            var repo = new com.mycompany.delivery.api.repository.ProductoRepository();
            var lista = repo.listarPorProveedor(prov);
            handleResponse(ctx, ApiResponse.success(200, "Productos del negocio", lista));
        });
        app.post("/admin/negocios/{id}/productos", ctx -> {
            int id = getIntId(ctx, "id");
            var negocio = USUARIO_CONTROLLER.obtenerPorId(id).getData();
            if (negocio == null || !"negocio".equalsIgnoreCase(((Usuario) negocio).getRol())) {
                throw new ApiException(404, "Negocio no encontrado");
            }
            var prov = ((Usuario) negocio).getNombre();
            Producto p = ctx.bodyAsClass(Producto.class);
            var repo = new com.mycompany.delivery.api.repository.ProductoRepository();
            var creado = repo.crearProductoParaProveedor(p, prov);
            if (creado.isEmpty()) {
                throw new ApiException(500, "No se pudo crear el producto");
            }
            handleResponse(ctx, ApiResponse.success(201, "Producto creado para negocio", creado.get()));
        });

        // --- PEDIDOS ---
        app.post("/pedidos", ctx -> {
            try {
                var body = ctx.bodyAsClass(PedidoPayload.class);

                // Validaciones reforzadas con mensajes más específicos
                if (body == null) {
                    throw new ApiException(400, "El cuerpo de la solicitud es obligatorio");
                }
                if (body.idCliente == null || body.idCliente <= 0) {
                    throw new ApiException(400, "El campo 'idCliente' es obligatorio y debe ser válido");
                }
                if (body.productos == null || body.productos.isEmpty()) {
                    throw new ApiException(400, "El pedido debe contener al menos un producto");
                }
                if (body.metodoPago == null || body.metodoPago.isBlank()) {
                    throw new ApiException(400, "El método de pago es obligatorio");
                }

                var pedido = new Pedido();
                pedido.setIdCliente(body.idCliente);
                pedido.setIdDelivery(body.idDelivery);
                pedido.setIdUbicacion(body.getIdUbicacion() != null ? body.getIdUbicacion() : 0);
                pedido.setDireccionEntrega(body.getDireccionEntrega());
                pedido.setMetodoPago(body.metodoPago);
                pedido.setEstado(body.estado != null ? body.estado : "pendiente");
                pedido.setTotal(body.getTotal() != null ? body.getTotal() : 0.0);

                var detalles = new ArrayList<DetallePedido>();
                for (int i = 0; i < body.productos.size(); i++) {
                    var it = body.productos.get(i);
                    if (it == null) {
                        throw new ApiException(400, "Producto #" + (i + 1) + " es nulo");
                    }
                    if (it.idProducto <= 0) {
                        throw new ApiException(400, "Producto #" + (i + 1) + " tiene ID inválido: " + it.idProducto);
                    }
                    if (it.cantidad <= 0) {
                        throw new ApiException(400, "Producto #" + (i + 1) + " tiene cantidad inválida: " + it.cantidad);
                    }
                    if (it.precioUnitario < 0) {
                        throw new ApiException(400, "Producto #" + (i + 1) + " tiene precio inválido: " + it.precioUnitario);
                    }

                    var d = new DetallePedido();
                    d.setIdProducto(it.idProducto);
                    d.setCantidad(it.cantidad);
                    d.setPrecioUnitario(it.precioUnitario);
                    d.setSubtotal(it.subtotal);
                    detalles.add(d);
                }

                handleResponse(ctx, PEDIDO_CONTROLLER.crearPedido(pedido, detalles));

            } catch (JsonSyntaxException e) {
                throw new ApiException(400, "Formato JSON inválido: " + e.getMessage(), e);
            } catch (Exception e) {
                if (e instanceof ApiException) {
                    throw e;
                }
                System.err.println("Error inesperado en POST /pedidos: " + e.getMessage());
                e.printStackTrace();
                throw new ApiException(500, "Error interno al procesar el pedido: " + e.getMessage(), e);
            }
        });
        app.get("/pedidos", ctx -> {
            handleResponse(ctx, PEDIDO_CONTROLLER.getPedidos());
        });
        // Colocar antes de /pedidos/{id} para que no capture 'disponibles'
        app.get("/pedidos/disponibles", ctx -> {
            // Usamos el método dedicado que selecciona columnas explícitas y evita
            // desalineaciones.
            handleResponse(ctx, PEDIDO_CONTROLLER.listarPedidosDisponibles());
        });
        app.get("/pedidos/{id}", ctx -> {
            var id = getIntId(ctx, "id");
            handleResponse(ctx, PEDIDO_CONTROLLER.obtenerPedidoConDetalle(id));
        });
        app.get("/pedidos/cliente/{id}", ctx -> {
            var id = getIntId(ctx, "id");
            handleResponse(ctx, PEDIDO_CONTROLLER.getPedidosPorCliente(id));
        });
        app.get("/pedidos/estado/{estado}", ctx -> {
            var estado = ctx.pathParam("estado");
            handleResponse(ctx, PEDIDO_CONTROLLER.getPedidosPorEstado(estado));
        });
        app.get("/pedidos/delivery/{id}", ctx -> {
            var id = getIntId(ctx, "id");
            handleResponse(ctx, PEDIDO_CONTROLLER.listarPedidosPorDelivery(id));
        });
        app.get("/pedidos/negocio/{id}", ctx -> {
            var id = getIntId(ctx, "id");
            handleResponse(ctx, PEDIDO_CONTROLLER.getPedidosPorNegocio(id));
        });
        app.put("/pedidos/{id}/estado", ctx -> {
            var id = getIntId(ctx, "id");
            var body = ctx.bodyAsClass(EstadoUpdateRequest.class);
            String estado = RequestValidator.requireNonBlank(body.estado, "estado").toLowerCase();
            // Opcional: validar valores permitidos
            java.util.Set<String> allowedEstados = java.util.Set.of("pendiente", "en_camino", "entregado", "cancelado");
            if (!allowedEstados.contains(estado)) {
                throw new ApiException(400, "estado inválido. Valores permitidos: " + allowedEstados);
            }
            handleResponse(ctx, PEDIDO_CONTROLLER.updateEstadoPedido(id, estado));
        });
        app.put("/pedidos/{id}/asignar", ctx -> {
            var id = getIntId(ctx, "id");
            var body = ctx.bodyAsClass(AsignarPedidoRequest.class);
            int idDelivery = RequestValidator.requirePositiveInt(body.idDelivery, "id_delivery");
            handleResponse(ctx, PEDIDO_CONTROLLER.asignarPedido(id, idDelivery));
        });

        // --- UBICACIONES ---
        app.post("/ubicaciones", ctx -> {
            var b = ctx.bodyAsClass(Payloads.UbicacionRequest.class);
            var u = toUbicacion(b);
            handleResponse(ctx, UBICACION_CONTROLLER.guardarUbicacion(u));
        });
        app.put("/ubicaciones/{idUbicacion}", ctx -> {
            var id = getLongId(ctx, "idUbicacion");
            var b = ctx.bodyAsClass(Payloads.UbicacionRequest.class);
            UBICACION_CONTROLLER.actualizarCoordenadas(id, b.getLatitud(), b.getLongitud());
            handleResponse(ctx, ApiResponse.success("Ubicación actualizada correctamente"));
        });
        app.get("/ubicaciones/activas", ctx -> {
            handleResponse(ctx, UBICACION_CONTROLLER.listarActivas());
        });
        app.get("/ubicaciones/usuario/{id}", ctx -> {
            int id = getIntId(ctx, "id");
            handleResponse(ctx, UBICACION_CONTROLLER.obtenerUbicacionesPorUsuario(id));
        });
        app.delete("/ubicaciones/{id}", ctx -> {
            int id = getIntId(ctx, "id");
            handleResponse(ctx, UBICACION_CONTROLLER.eliminarUbicacion(id));
        });
        app.put("/ubicaciones/repartidor/{idRepartidor}", ctx -> {
            var idRepartidor = getLongId(ctx, "idRepartidor");
            var body = ctx.bodyAsClass(Payloads.UbicacionRequest.class);
            UBICACION_CONTROLLER.actualizarCoordenadas(idRepartidor, body.getLatitud(), body.getLongitud());
            handleResponse(ctx, ApiResponse.success("Ubicación del repartidor actualizada"));
        });

        // --- MENSAJES (CHAT) ---
        app.post("/chat", ctx -> {
            var body = ctx.bodyAsClass(Mensaje.class);
            var result = CHAT_REPOSITORY.guardarMensaje(body);
            if (result.containsKey("error")) {
                handleResponse(ctx, ApiResponse.error(500, "Error al guardar mensaje", result.get("error")));
            } else {
                handleResponse(ctx, ApiResponse.success(201, "Mensaje guardado", result));
            }
        });
        app.get("/chat/{idPedido}", ctx -> {
            var idPedido = getLongId(ctx, "idPedido");
            var mensajes = CHAT_REPOSITORY.obtenerChatPorPedido(idPedido);
            handleResponse(ctx, ApiResponse.success(200, "Mensajes del chat", mensajes));
        });

        // --- RECOMENDACIONES ---
        app.post("/productos/{id}/recomendaciones", ctx -> {
            var idProducto = getLongId(ctx, "id");
            @SuppressWarnings("unchecked")
            Map<String, Object> body = (Map<String, Object>) ctx.bodyAsClass(Map.class);
            Long idUsuario = parseNullableLong(body.get("id_usuario"));
            Integer puntuacion = parseNullableInt(body.get("puntuacion"));
            String comentario = body.get("comentario") != null ? body.get("comentario").toString() : null;
            RequestValidator.requirePositiveLong(idUsuario, "id_usuario");
            if (puntuacion == null) {
                throw new ApiException(400, "puntuacion es obligatoria");
            }
            RequestValidator.requireRangeInt(puntuacion, 1, 5, "puntuacion");
            int idProd = Math.toIntExact(idProducto);
            int idUser = Math.toIntExact(idUsuario);
            int puntu = puntuacion;
            handleResponse(ctx,
                    RECOMENDACION_CONTROLLER.guardarRecomendacion(idProd, idUser, puntu, comentario));
        });
        app.get("/productos/{id}/recomendaciones", ctx -> {
            var idProducto = getLongId(ctx, "id");
            int idProd = Math.toIntExact(idProducto);
            handleResponse(ctx, RECOMENDACION_CONTROLLER.obtenerResumenYLista(idProd));
        });
        app.get("/recomendaciones/usuario/{id}", ctx -> {
            var idUsuario = getLongId(ctx, "id");
            int idUser = Math.toIntExact(idUsuario);
            handleResponse(ctx, RECOMENDACION_CONTROLLER.obtenerRecomendacionesPorUsuario(idUser));
        });
        // ENDPOINT FALTANTE: Carrusel de recomendaciones destacadas
        app.get("/recomendaciones/destacadas", ctx -> {
            handleResponse(ctx, RECOMENDACION_CONTROLLER.listarRecomendacionesDestacadas());
        });
        // Recomendaciones con IA
        app.post("/recomendaciones/productos", ctx -> {
            @SuppressWarnings("unchecked")
            Map<String, Object> body = (Map<String, Object>) ctx.bodyAsClass(Map.class);
            Long idUsuario = parseNullableLong(body.get("idUsuario"));
            Double presupuesto = body.get("presupuesto") instanceof Number n ? n.doubleValue() : null;

            if (idUsuario == null || idUsuario <= 0) {
                throw new ApiException(400, "idUsuario es obligatorio");
            }

            var productos = PRODUCTO_CONTROLLER.getAllProductos().getData();
            var recomendaciones = new java.util.ArrayList<java.util.Map<String, Object>>();

            if (productos instanceof java.util.List) {
                for (Object p : (java.util.List<?>) productos) {
                    if (p instanceof Producto producto) {
                        if (presupuesto == null || producto.getPrecio() <= presupuesto) {
                            var rec = new java.util.HashMap<String, Object>();
                            rec.put("idProducto", producto.getIdProducto());
                            rec.put("nombre", producto.getNombre());
                            rec.put("precio", producto.getPrecio());
                            rec.put("razon", "Producto dentro de tu presupuesto");
                            recomendaciones.add(rec);
                            if (recomendaciones.size() >= 10) {
                                break;
                            }
                        }
                    }
                }
            }

            handleResponse(ctx, ApiResponse.success(200, "Recomendaciones generadas", recomendaciones));
        });

        // --- TRACKING (SEGUIMIENTO) ---
        app.get("/tracking/pedido/{idPedido}", ctx -> {
            var idPedido = getLongId(ctx, "idPedido");
            try {
                handleResponse(ctx, UBICACION_CONTROLLER.obtenerUbicacionTracking(idPedido));
            } catch (ApiException ex) {
                if (ex.getStatus() == 404) {
                    handleResponse(ctx,
                            ApiResponse.success(200, "Sin ubicacion de seguimiento", java.util.Collections.emptyMap()));
                } else {
                    throw ex;
                }
            }
        });
        app.get("/tracking/pedido/{idPedido}/ruta", ctx -> {
            var idPedido = getLongId(ctx, "idPedido");
            try {
                handleResponse(ctx, UBICACION_CONTROLLER.obtenerRutaTracking(idPedido));
            } catch (ApiException ex) {
                if (ex.getStatus() == 404) {
                    handleResponse(ctx,
                            ApiResponse.success(200, "Ruta de seguimiento", java.util.Collections.emptyList()));
                } else {
                    throw ex;
                }
            }
        });
        // (eliminado duplicado) PUT /ubicaciones/repartidor/{idRepartidor} ya se define arriba con el mismo handler

        // --- NUEVO ENDPOINT OPTIMIZADO ---
        app.post("/tracking/repartidores/ubicaciones", ctx -> {
            var body = ctx.bodyAsClass(UbicacionesRequest.class);
            if (body.ids == null || body.ids.isEmpty()) {
                throw new BadRequestResponse("La lista de IDs de repartidores es obligatoria.");
            }
            handleResponse(ctx, UBICACION_CONTROLLER.obtenerUbicacionesDeRepartidores(body.ids));
        });

        // --- GEOCODIFICAR ---
        app.post("/geocodificar", ctx -> {
            @SuppressWarnings("unchecked")
            Map<String, Object> body = (Map<String, Object>) ctx.bodyAsClass(Map.class);
            String direccion = body != null ? (String) body.get("direccion") : null;
            RequestValidator.requireNonBlank(direccion, "direccion es obligatoria");
            handleResponse(ctx, UBICACION_CONTROLLER.geocodificarDireccion(direccion));
        });

        // --- DASHBOARD ---
        app.get("/admin/stats", ctx -> {
            handleResponse(ctx,
                    ApiResponse.success(200, "EstadÃ­sticas admin", DASHBOARD_DAO.obtenerEstadisticasAdmin()));
        });
        app.get("/delivery/stats/{id}", ctx -> {
            var id = getIntId(ctx, "id");
            handleResponse(ctx,
                    ApiResponse.success(200, "EstadÃƒÂ­sticas delivery",
                            DASHBOARD_DAO.obtenerEstadisticasDelivery(id)));
        });

        // --- SOPORTE ---
        app.post("/soporte/iniciar", ctx -> {
            @SuppressWarnings("unchecked")
            Map<String, Object> body = (Map<String, Object>) ctx.bodyAsClass(Map.class);
            Long idUsuario = parseNullableLong(body.get("idUsuario"));
            String rol = Objects.toString(body.getOrDefault("rol", "cliente"), "cliente").toLowerCase();

            if (idUsuario == null || idUsuario <= 0) {
                throw new ApiException(400, "idUsuario es obligatorio");
            }
            if (!rol.equals("cliente") && !rol.equals("delivery")) {
                throw new ApiException(400, "rol debe ser 'cliente' o 'delivery'");
            }

            try {
                long idConv = SOPORTE_REPO.ensureSoporteConversacion(idUsuario, rol);
                java.util.Map<String, Object> result = new java.util.HashMap<>();
                result.put("id_conversacion", idConv);
                handleResponse(ctx, ApiResponse.success(201, "Conversacion de soporte iniciada", result));
            } catch (SQLException e) {
                throw new ApiException(500, "No se pudo iniciar la conversacion de soporte", e);
            }
        });

        app.post("/soporte/mensajes", ctx -> {
            Payloads.SoporteMensajeRequest req = ctx.bodyAsClass(Payloads.SoporteMensajeRequest.class);
            if (req == null || req.idConversacion == null || req.idConversacion <= 0) {
                throw new ApiException(400, "idConversacion es obligatorio");
            }
            if (req.idRemitente == null || req.idRemitente <= 0) {
                throw new ApiException(400, "idRemitente es obligatorio");
            }
            String mensaje = Objects.toString(req.mensaje, "").trim();
            if (mensaje.isEmpty()) {
                throw new ApiException(400, "mensaje es obligatorio");
            }

            try {
                SOPORTE_REPO.insertMensajeUsuario(req.idConversacion, req.idRemitente, mensaje);

                Optional<Map<String, Object>> convInfo = SOPORTE_REPO.getInfoConversacion(req.idConversacion);
                String rol = convInfo.map(info -> Objects.toString(info.get("rol"), "cliente")).orElse("cliente");
                boolean esDelivery = "delivery".equalsIgnoreCase(rol);
                boolean esCliente = "cliente".equalsIgnoreCase(rol) || "negocio".equalsIgnoreCase(rol);

                Optional<String> auto = SOPORTE_REPO.buscarAutoRespuesta(mensaje, esCliente, esDelivery);
                if (auto.isPresent()) {
                    long botId = SOPORTE_REPO.ensureBotSoporte();
                    SOPORTE_REPO.insertMensajeSoporte(req.idConversacion, botId, auto.get());
                    java.util.Map<String, Object> result = new java.util.HashMap<>();
                    result.put("id_conversacion", req.idConversacion);
                    result.put("respuesta", auto.orElse(""));
                    result.put("auto", true);
                    handleResponse(ctx, ApiResponse.success(201, "Auto-respuesta enviada", result));
                } else {
                    java.util.Map<String, Object> result = new java.util.HashMap<>();
                    result.put("id_conversacion", req.idConversacion);
                    result.put("auto", false);
                    handleResponse(ctx, ApiResponse.success(201, "Mensaje guardado; esperando agente humano", result));
                }
            } catch (SQLException e) {
                throw new ApiException(500, "Error al registrar el mensaje de soporte", e);
            }
        });

        app.get("/soporte/conversaciones/{id}/mensajes", ctx -> {
            long idConv = getLongId(ctx, "id");

            // Obtener parámetros de paginación desde query params
            int limit = ctx.queryParam("limit") != null ? Integer.parseInt(ctx.queryParam("limit")) : -1;
            int offset = ctx.queryParam("offset") != null ? Integer.parseInt(ctx.queryParam("offset")) : 0;

            try {
                var mensajes = SOPORTE_REPO.listarMensajes(idConv, limit, offset);
                handleResponse(ctx, ApiResponse.success(200, "Historial soporte", mensajes));
            } catch (SQLException e) {
                throw new ApiException(500, "No se pudo obtener el historial de soporte", e);
            }
        });

        app.get("/soporte/usuario/{idUsuario}/conversaciones", ctx -> {
            var idUsuario = getLongId(ctx, "idUsuario");
            try {
                var convs = SOPORTE_REPO.listarConversacionesPorUsuario(idUsuario);
                handleResponse(ctx, ApiResponse.success(200, "Conversaciones de soporte", convs));
            } catch (SQLException e) {
                throw new ApiException(500, "No se pudieron obtener las conversaciones de soporte", e);
            }
        });

        app.post("/soporte/responder", ctx -> {
            @SuppressWarnings("unchecked")
            Map<String, Object> body = (Map<String, Object>) ctx.bodyAsClass(Map.class);
            Long idConversacion = body.get("idConversacion") instanceof Number n ? n.longValue() : null;
            Integer idSoporte = body.get("idSoporte") instanceof Number n ? n.intValue() : null;
            String mensaje = Objects.toString(body.get("mensaje"), "").trim();

            if (idConversacion == null || idConversacion <= 0) {
                throw new ApiException(400, "idConversacion es obligatorio");
            }
            if (idSoporte == null || idSoporte <= 0) {
                throw new ApiException(400, "idSoporte es obligatorio");
            }
            if (mensaje.isEmpty()) {
                throw new ApiException(400, "mensaje es obligatorio");
            }

            try {
                SOPORTE_REPO.asignarHumano(idConversacion, idSoporte);
                SOPORTE_REPO.insertMensajeSoporte(idConversacion, idSoporte, mensaje);
                java.util.Map<String, Object> result = new java.util.HashMap<>();
                result.put("id_conversacion", idConversacion);
                handleResponse(ctx, ApiResponse.success(201, "Respuesta enviada", result));
            } catch (SQLException e) {
                throw new ApiException(500, "No se pudo registrar la respuesta del agente", e);
            }
        });

        app.post("/soporte/asignar", ctx -> {
            Payloads.SoporteAsignacionRequest req = ctx.bodyAsClass(Payloads.SoporteAsignacionRequest.class);
            if (req.idConversacion == null || req.idConversacion <= 0) {
                throw new ApiException(400, "idConversacion requerido");
            }
            if (req.idAgente == null || req.idAgente <= 0) {
                throw new ApiException(400, "idAgente requerido");
            }
            try {
                SOPORTE_REPO.asignarHumano(req.idConversacion, req.idAgente);
                java.util.Map<String, Object> result = new java.util.HashMap<>();
                result.put("id_conversacion", req.idConversacion);
                result.put("id_agente", req.idAgente);
                handleResponse(ctx, ApiResponse.success(200, "Conversacion asignada", result));
            } catch (SQLException e) {
                throw new ApiException(500, "No se pudo asignar la conversacion", e);
            }
        });

        app.post("/soporte/cerrar", ctx -> {
            Payloads.SoporteCerrarRequest req = ctx.bodyAsClass(Payloads.SoporteCerrarRequest.class);
            if (req.idConversacion == null || req.idConversacion <= 0) {
                throw new ApiException(400, "idConversacion requerido");
            }
            try {
                SOPORTE_REPO.cerrarConversacion(req.idConversacion);
                java.util.Map<String, Object> result = new java.util.HashMap<>();
                result.put("id_conversacion", req.idConversacion);
                handleResponse(ctx, ApiResponse.success(200, "Conversacion cerrada", result));
            } catch (SQLException e) {
                throw new ApiException(500, "No se pudo cerrar la conversacion", e);
            }
        });

        // --- ADMIN SOPORTE: RESPUESTAS PREDEFINIDAS ---
        app.post("/admin/soporte/respuestas", ctx -> {
            Payloads.SoporteRespuestaPayload payload = ctx.bodyAsClass(Payloads.SoporteRespuestaPayload.class);
            if (payload.categoria == null || payload.categoria.isBlank()) {
                throw new ApiException(400, "categoria requerida");
            }
            if (payload.pregunta == null || payload.pregunta.isBlank()) {
                throw new ApiException(400, "pregunta requerida");
            }
            if (payload.respuesta == null || payload.respuesta.isBlank()) {
                throw new ApiException(400, "respuesta requerida");
            }
            try {
                int id = RESPUESTA_SOPORTE_REPO.crearAutoRespuesta(payload);
                java.util.Map<String, Object> result = new java.util.HashMap<>();
                result.put("id_respuesta", id);
                handleResponse(ctx, ApiResponse.success(201, "Respuesta creada", result));
            } catch (SQLException e) {
                throw new ApiException(500, "No se pudo crear la respuesta predefinida", e);
            }
        });

        app.get("/admin/soporte/respuestas", ctx -> {
            String categoria = ctx.queryParam("categoria");
            try {
                var list = RESPUESTA_SOPORTE_REPO.listarAutoRespuestas(categoria);
                handleResponse(ctx, ApiResponse.success(200, "Respuestas", list));
            } catch (SQLException e) {
                throw new ApiException(500, "No se pudo listar las respuestas predefinidas", e);
            }
        });

        app.put("/admin/soporte/respuestas/{id}", ctx -> {
            var id = getLongId(ctx, "id");
            Payloads.SoporteRespuestaPayload payload = ctx.bodyAsClass(Payloads.SoporteRespuestaPayload.class);
            try {
                RESPUESTA_SOPORTE_REPO.actualizarAutoRespuesta(Math.toIntExact(id), payload);
                java.util.Map<String, Object> result = new java.util.HashMap<>();
                result.put("id_respuesta", id);
                handleResponse(ctx, ApiResponse.success(200, "Respuesta actualizada", result));
            } catch (SQLException e) {
                throw new ApiException(500, "No se pudo actualizar la respuesta", e);
            }
        });

        app.delete("/admin/soporte/respuestas/{id}", ctx -> {
            var id = getLongId(ctx, "id");
            try {
                RESPUESTA_SOPORTE_REPO.borrarAutoRespuesta(Math.toIntExact(id));
                handleResponse(ctx, ApiResponse.success(204, "Respuesta eliminada", null));
            } catch (SQLException e) {
                throw new ApiException(500, "No se pudo eliminar la respuesta", e);
            }
        });

        // --- OPINIONES ---
        app.get("/opiniones", ctx -> {
            try {
                var repo = new com.mycompany.delivery.api.repository.OpinionRepository();
                String limitParam = ctx.queryParam("limit");
                int limit = limitParam != null ? Integer.parseInt(limitParam) : 20;
                var opiniones = repo.listarOpinionesAprobadas(limit);
                handleResponse(ctx, ApiResponse.success(200, "Opiniones de clientes", opiniones));
            } catch (Exception e) {
                System.err.println("Error al obtener opiniones: " + e.getMessage());
                handleResponse(ctx, ApiResponse.error(500, "Error al cargar opiniones", null));
            }
        });

        app.post("/opiniones", ctx -> {
            try {
                @SuppressWarnings("unchecked")
                Map<String, Object> body = (Map<String, Object>) ctx.bodyAsClass(Map.class);

                Integer idUsuario = parseNullableInt(body.get("id_usuario"));
                String nombre = (String) body.get("nombre");
                String email = (String) body.get("email");
                Integer rating = parseNullableInt(body.get("rating"));
                String comentario = (String) body.get("comentario");
                String plataforma = (String) body.getOrDefault("plataforma", "app");

                if (rating == null || rating < 1 || rating > 5) {
                    throw new ApiException(400, "Rating debe estar entre 1 y 5");
                }
                if (comentario == null || comentario.trim().isEmpty()) {
                    throw new ApiException(400, "Comentario es obligatorio");
                }

                var repo = new com.mycompany.delivery.api.repository.OpinionRepository();
                boolean success = repo.crearOpinion(idUsuario, nombre, email, rating, comentario, plataforma);

                if (success) {
                    handleResponse(ctx, ApiResponse.success(201, "Opinión creada exitosamente", null));
                } else {
                    handleResponse(ctx, ApiResponse.error(500, "No se pudo crear la opinión", null));
                }
            } catch (Exception e) {
                System.err.println("Error al crear opinión: " + e.getMessage());
                if (e instanceof ApiException) {
                    throw e;
                }
                handleResponse(ctx, ApiResponse.error(500, "Error al procesar la opinión", null));
            }
        });

        app.get("/admin/opiniones", ctx -> {
            try {
                var repo = new com.mycompany.delivery.api.repository.OpinionRepository();
                String clasificacion = ctx.queryParam("clasificacion");
                String limitParam = ctx.queryParam("limit");
                int limit = limitParam != null ? Integer.parseInt(limitParam) : 50;

                var opiniones = repo.listarOpinionesAdmin(clasificacion, limit);
                handleResponse(ctx, ApiResponse.success(200, "Opiniones para administración", opiniones));
            } catch (Exception e) {
                System.err.println("Error al obtener opiniones admin: " + e.getMessage());
                handleResponse(ctx, ApiResponse.error(500, "Error al cargar opiniones", null));
            }
        });

        // --- CHAT BOT ---
        // Conversaciones del usuario
        app.get("/chat/conversaciones/{idUsuario}", ctx -> {
            var idUsuario = getLongId(ctx, "idUsuario");
            var conversaciones = CHAT_REPOSITORY.listarConversacionesPorUsuario(idUsuario);
            handleResponse(ctx, ApiResponse.success(200, "Conversaciones", conversaciones));
        });

        // Iniciar una conversacion (pedido o libre)
        app.post("/chat/iniciar", ctx -> {
            @SuppressWarnings("unchecked")
            Map<String, Object> body = (Map<String, Object>) ctx.bodyAsClass(Map.class);

            Long idCliente = parseNullableLong(body.get("idCliente"));
            Long idDelivery = parseNullableLong(body.get("idDelivery"));
            Long idAdminSoporte = parseNullableLong(body.get("idAdminSoporte"));
            Long idPedido = parseNullableLong(body.get("idPedido"));

            if (idCliente == null || idCliente <= 0) {
                throw new ApiException(400, "El campo 'idCliente' es obligatorio");
            }

            long idConversacion;
            if (idPedido != null && idPedido > 0) {
                idConversacion = idPedido.longValue();
                CHAT_REPOSITORY.ensureConversation(
                        idConversacion,
                        idCliente,
                        idDelivery,
                        idAdminSoporte,
                        idPedido,
                        false);
            } else {
                idConversacion = CHAT_REPOSITORY.ensureConversationForUser(idCliente);
                if (idDelivery != null || idAdminSoporte != null) {
                    CHAT_REPOSITORY.ensureConversation(
                            idConversacion,
                            idCliente,
                            idDelivery,
                            idAdminSoporte,
                            null,
                            false);
                }
            }

            java.util.Map<String, Object> result = new java.util.HashMap<>();
            result.put("id_conversacion", idConversacion);
            handleResponse(ctx, ApiResponse.success(201, "Conversacion iniciada", result));
        });

        // Enviar mensaje (no bot)
        app.post("/chat/mensajes", ctx -> {
            @SuppressWarnings("unchecked")
            Map<String, Object> body = (Map<String, Object>) ctx.bodyAsClass(Map.class);
            Long idConversacion = parseNullableLong(body.get("idConversacion"));
            Long idRemitente = parseNullableLong(body.get("idRemitente"));
            Long idDestinatario = parseNullableLong(body.get("idDestinatario"));
            String mensaje = Objects.toString(body.get("mensaje"), "").trim();

            if (idConversacion == null || idConversacion <= 0) {
                throw new ApiException(400, "El campo 'idConversacion' es obligatorio");
            }
            if (idRemitente == null || idRemitente <= 0) {
                throw new ApiException(400, "El campo 'idRemitente' es obligatorio");
            }
            if (mensaje.isBlank()) {
                throw new ApiException(400, "El campo 'mensaje' es obligatorio");
            }

            var inserted = CHAT_REPOSITORY.insertMensaje(idConversacion, idRemitente, idDestinatario,
                    mensaje);
            handleResponse(ctx, ApiResponse.success(201, "Mensaje enviado", inserted));
        });

        app.get("/chat/conversaciones/{id}/mensajes", ctx -> {
            var idConversacion = getLongId(ctx, "id");

            // Obtener parámetros de paginación desde query params
            int limit = ctx.queryParam("limit") != null ? Integer.parseInt(ctx.queryParam("limit")) : -1;
            int offset = ctx.queryParam("offset") != null ? Integer.parseInt(ctx.queryParam("offset")) : 0;

            var mensajes = CHAT_REPOSITORY.listarMensajes(idConversacion, limit, offset);
            handleResponse(ctx, ApiResponse.success(200, "Historial de mensajes", mensajes));
        });

        app.post("/chat/bot/mensajes", ctx -> {
            System.err.println("🔵 DEBUG: Entrando al handler del chatbot");
            var req = ctx.bodyAsClass(Payloads.ChatBotRequest.class);
            System.err.println("🔵 DEBUG: Request parseado: idRemitente=" + req.idRemitente + ", mensaje=" + req.mensaje);

            try {
                // Fix rápido: validar nulos mínimos para evitar NPE
                // Validación de nulos ya cubierta, bloque eliminado
                if (req.mensaje == null) {
                    req.mensaje = ""; // forzar a cadena vacía para pasar validación estándar
                }
                // 1. Validar el request
                if (req.idRemitente == null || req.idRemitente <= 0) {
                    throw new ApiException(400, "idRemitente es obligatorio");
                }
                if (req.mensaje == null || req.mensaje.isBlank()) {
                    throw new ApiException(400, "mensaje es obligatorio");
                }
                System.err.println("🔵 DEBUG: Validación OK");

                // 2. Obtener o crear conversación
                long idConversacion = (req.idConversacion != null && req.idConversacion > 0)
                        ? req.idConversacion
                        : CHAT_REPOSITORY.ensureBotConversationForUser(req.idRemitente);
                System.err.println("🔵 DEBUG: idConversacion=" + idConversacion);

                // 3. Guardar el mensaje del usuario
                System.err.println("🔵 DEBUG: Guardando mensaje del usuario...");
                CHAT_REPOSITORY.insertMensaje(idConversacion, req.idRemitente, null, req.mensaje);
                System.err.println("🔵 DEBUG: Mensaje guardado");

                // 4. Obtener el historial de la conversacion para el contexto de la IA
                System.err.println("🔵 DEBUG: Obteniendo historial...");
                List<Map<String, Object>> history = CHAT_REPOSITORY.listarMensajes(idConversacion);
                if (history == null) {
                    history = java.util.Collections.emptyList();
                }
                System.err.println("🔵 DEBUG: Historial obtenido, " + history.size() + " mensajes");

                // 5. Generar la respuesta del bot
                System.err.println("🔵 DEBUG: Generando respuesta del bot...");
                String botReply = CHATBOT_RESPONDER.generateReply(req.mensaje, history, req.idRemitente);
                System.err.println("🔵 DEBUG: Bot reply generado: " + botReply);

                // 6. Guardar la respuesta del bot usando el usuario del bot
                System.err.println("🔵 DEBUG: Guardando respuesta del bot...");
                long botUserId = CHAT_REPOSITORY.ensureBotUser();
                CHAT_REPOSITORY.insertMensaje(idConversacion, botUserId, req.idRemitente.longValue(), botReply);
                System.err.println("🔵 DEBUG: Respuesta del bot guardada");

                // 7. Preparar respuesta con telemetría
                String modelUsed = GEMINI_SERVICE.getLastModelUsed();
                System.err.println("✅ DEBUG: modelUsed = " + modelUsed);
                System.err.println("✅ DEBUG: botReply = " + botReply);
                if (modelUsed != null && !modelUsed.isBlank()) {
                    ctx.header("X-LLM-Model", modelUsed);
                }

                // Evitar NPE: usar HashMap (acepta null) y asegurar defaults
                System.err.println("✅ DEBUG: Creando HashMap para respuesta...");
                java.util.Map<String, Object> result = new java.util.HashMap<>();
                result.put("id_conversacion", idConversacion);
                result.put("bot_reply", botReply != null ? botReply : "Estoy aquí para ayudarte con tu pedido.");
                result.put("model_used", (modelUsed != null && !modelUsed.isBlank()) ? modelUsed : "predefinido");
                System.err.println("✅ DEBUG: HashMap creado exitosamente");
                handleResponse(ctx, ApiResponse.success(201, "Respuesta generada", result));

            } catch (SQLException e) {
                System.err.println("❌ Error SQL en chatbot: " + e.getMessage());
                e.printStackTrace();
                throw new ApiException(500, "Error en la base de datos del chatbot: " + e.getMessage(), e);
            } catch (Exception e) {
                System.err.println("❌ Error general en chatbot: " + e.getMessage());
                e.printStackTrace();
                throw new ApiException(500, "Error al procesar mensaje del chatbot: " + e.getMessage(), e);
            }
        });

        // ============ ENDPOINT DE SOPORTE (Respuestas predefinidas SIN IA) ============
        app.post("/soporte/mensaje", ctx -> {
            System.err.println("🟢 SOPORTE: Procesando mensaje de soporte...");

            @SuppressWarnings("unchecked")
            Map<String, Object> body = (Map<String, Object>) ctx.bodyAsClass(Map.class);
            Long idUsuario = parseNullableLong(body.get("idUsuario"));
            String mensaje = Objects.toString(body.get("mensaje"), "").trim();

            if (idUsuario == null || idUsuario <= 0) {
                throw new ApiException(400, "El campo 'idUsuario' es obligatorio");
            }
            if (mensaje.isBlank()) {
                throw new ApiException(400, "El campo 'mensaje' es obligatorio");
            }

            try {
                long idSoporteConv = SOPORTE_REPO.obtenerOCrearConversacion(idUsuario);
                SOPORTE_REPO.insertarMensaje(idSoporteConv, idUsuario, false, mensaje);

                String respuestaAutomatica = RESPUESTA_SOPORTE_REPO.buscarRespuesta(mensaje);
                String respuestaFinal = respuestaAutomatica != null && !respuestaAutomatica.isBlank()
                        ? respuestaAutomatica
                        : "Gracias por contactarnos. Tu consulta ha sido registrada y un técnico te atenderá pronto.";

                SOPORTE_REPO.insertarMensaje(idSoporteConv, null, true, respuestaFinal);

                Map<String, Object> result = new HashMap<>();
                result.put("id_conversacion", idSoporteConv);
                result.put("respuesta", respuestaFinal);

                handleResponse(ctx, ApiResponse.success(201, "Mensaje procesado", result));

            } catch (SQLException e) {
                throw new ApiException(500, "Error en la base de datos de soporte: " + e.getMessage(), e);
            }
        });

        // Endpoint legacy (mantener por compatibilidad)
        app.post("/chat/mensaje", ctx -> {
            System.err.println("🟢 SOPORTE: Procesando mensaje de soporte...");

            @SuppressWarnings("unchecked")
            Map<String, Object> body = (Map<String, Object>) ctx.bodyAsClass(Map.class);
            Long idUsuario = parseNullableLong(body.get("idUsuario"));
            String mensaje = Objects.toString(body.get("mensaje"), "").trim();
            String tipo = Objects.toString(body.get("tipo"), "").trim();

            // Validaciones
            if (idUsuario == null || idUsuario <= 0) {
                throw new ApiException(400, "El campo 'idUsuario' es obligatorio");
            }
            if (mensaje.isBlank()) {
                throw new ApiException(400, "El campo 'mensaje' es obligatorio");
            }
            if (!"soporte".equalsIgnoreCase(tipo)) {
                throw new ApiException(400, "El campo 'tipo' debe ser 'soporte'");
            }

            try {
                // 1. Obtener o crear conversación de soporte
                long idSoporteConv = SOPORTE_REPO.obtenerOCrearConversacion(idUsuario);
                System.err.println("🟢 SOPORTE: id_soporte_conv=" + idSoporteConv);

                // 2. Guardar mensaje del usuario
                SOPORTE_REPO.insertarMensaje(idSoporteConv, idUsuario, false, mensaje);
                System.err.println("🟢 SOPORTE: Mensaje del usuario guardado");

                // 3. Buscar respuesta predefinida
                String respuestaAutomatica = RESPUESTA_SOPORTE_REPO.buscarRespuesta(mensaje);

                String respuestaFinal;
                if (respuestaAutomatica != null && !respuestaAutomatica.isBlank()) {
                    respuestaFinal = respuestaAutomatica;
                    System.err.println("🟢 SOPORTE: Respuesta predefinida encontrada");
                } else {
                    respuestaFinal = "Gracias por contactarnos. Tu consulta ha sido registrada y un técnico de soporte te atenderá pronto. Te responderemos a la brevedad.";
                    System.err.println("🟢 SOPORTE: No se encontró respuesta predefinida, escalando a técnico");
                }

                // 4. Guardar respuesta del sistema
                SOPORTE_REPO.insertarMensaje(idSoporteConv, null, true, respuestaFinal);
                System.err.println("🟢 SOPORTE: Respuesta guardada");

                // 5. Preparar respuesta
                Map<String, Object> result = new HashMap<>();
                result.put("id_conversacion", idSoporteConv);
                result.put("respuesta", respuestaFinal);
                result.put("tipo_respuesta", respuestaAutomatica != null ? "automatica" : "derivada_a_tecnico");

                handleResponse(ctx, ApiResponse.success(201, "Mensaje procesado", result));

            } catch (SQLException e) {
                System.err.println("❌ Error SQL en soporte: " + e.getMessage());
                e.printStackTrace();
                throw new ApiException(500, "Error en la base de datos de soporte: " + e.getMessage(), e);
            } catch (Exception e) {
                System.err.println("❌ Error general en soporte: " + e.getMessage());
                e.printStackTrace();
                throw new ApiException(500, "Error al procesar mensaje de soporte: " + e.getMessage(), e);
            }
        });
    }

    // --- HELPERS ---
    private static void handleResponse(Context ctx, ApiResponse<?> response) {
        if (response == null) {
            throw new ApiException(500, "Respuesta nula del controlador");
        }
        // Javalin 6.x requiere HttpStatus enum, no int directo
        int statusCode = response.getStatus();
        ctx.status(io.javalin.http.HttpStatus.forStatus(statusCode));

        // Si es 204 No Content, no enviamos body para respetar el estandar HTTP
        if (statusCode == 204) {
            return;
        }
        ctx.json(response);
    }

    private static Ubicacion toUbicacion(Payloads.UbicacionRequest r) {
        if (r == null) {
            throw new ApiException(400, "El cuerpo de la solicitud es obligatorio");
        }
        requireValidCoordinates(r.getLatitud(), r.getLongitud(), "Coordenadas invÃ¡lidas");
        Ubicacion u = new Ubicacion();
        u.setIdUsuario(r.getIdUsuario());
        u.setLatitud(r.getLatitud());
        u.setLongitud(r.getLongitud());
        u.setDireccion(requireNonBlank(r.getDireccion(), "La direcciÃƒÂ³n es obligatoria"));
        u.setDescripcion(normalizeDescripcion(r.getDescripcion()));
        u.setActiva(r.getActiva() == null || r.getActiva());
        return u;
    }

    // Utilidad para obtener el ID como int desde pathParam
    static int getIntId(Context ctx, String param) {
        try {
            return Integer.parseInt(ctx.pathParam(param));
        } catch (NumberFormatException e) {
            throw new ApiException(400, "Identificador inválido: '" + ctx.pathParam(param) + "'");
        }
    }

    // Utilidad para obtener el ID como long desde pathParam
    static long getLongId(Context ctx, String param) {
        try {
            return Long.parseLong(ctx.pathParam(param));
        } catch (NumberFormatException e) {
            throw new ApiException(400, "Identificador inválido: '" + ctx.pathParam(param) + "'");
        }
    }

    /**
     * Valida que las variables de entorno críticas estén configuradas
     */
    private static void validateEnvironment() {
        List<String> missing = new ArrayList<>();

        // Variables críticas para el funcionamiento
        String[] required = {
            "DB_URL",
            "DB_USER",
            "DB_PASSWORD",
            "JWT_SECRET"
        };

        for (String var : required) {
            String value = System.getenv(var);
            if (value == null || value.isBlank()) {
                missing.add(var);
            }
        }

        if (!missing.isEmpty()) {
            System.err.println("❌ Variables de entorno faltantes:");
            missing.forEach(v -> System.err.println("   - " + v));
            System.err.println("\n⚠️  El servidor puede no funcionar correctamente.");
            System.err.println("💡 Crea un archivo .env o configura las variables del sistema.\n");
        } else {
            System.out.println("✅ Variables de entorno validadas correctamente");
        }
    }

    // Utilidad para obtener Integer desde Object
    static Integer getNullableInt(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Number number) {
            return number.intValue();
        }
        String text = value.toString().trim();
        if (text.isEmpty()) {
            return null;
        }
        try {
            return Integer.parseInt(text);
        } catch (NumberFormatException e) {
            throw new ApiException(400, "Valor numérico inválido: '" + text + "'", e);
        }
    }

    private static Long parseNullableLong(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Number number) {
            return number.longValue();
        }
        try {
            return Long.parseLong(value.toString().trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static Integer parseNullableInt(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Number number) {
            return number.intValue();
        }
        try {
            return Integer.parseInt(value.toString().trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
