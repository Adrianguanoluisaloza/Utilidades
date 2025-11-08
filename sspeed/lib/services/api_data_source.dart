import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart' show AppConfig;
import '../models/cart_model.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/pedido.dart';
import '../models/pedido_detalle.dart';
import '../models/producto.dart';
import '../models/negocio.dart';
import '../models/recomendacion_data.dart';
import '../models/tracking_point.dart';
import '../models/ubicacion.dart';
import '../models/usuario.dart';
import 'api_exception.dart';
import 'data_source.dart';

class ApiDataSource implements DataSource {
  // ----------------- CACHE INTERNAS -----------------
  // Cache de categorías combinadas para reducir llamadas repetitivas.
  List<String>? _cachedCategorias;
  DateTime? _cachedCategoriasAt;
  static const Duration _categoriasCacheTtl = Duration(seconds: 60);

  @override
  Future<bool> deleteUbicacion(int id) async {
    final response = await _delete('/ubicaciones/$id');
    return response['success'] ?? false;
  }

  final String _baseUrl = AppConfig.baseUrl;
  final http.Client _httpClient;
  String? _token;

  ApiDataSource({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  @override
  void setAuthToken(String? token) {
    _token = token;
    if (AppConfig.enableLogs) {
      debugPrint('[ApiDataSource] Token actualizado: \x1B[33m$_token\x1B[0m');
    }
  }

  Map<String, String> get _jsonHeaders {
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    headers['ngrok-skip-browser-warning'] = 'true';

    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static const Duration _timeout = Duration(seconds: 30);

  bool _looksLikeJson(String? body) {
    if (body == null) return false;
    final trimmed = body.trimLeft();
    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }

  Future<Map<String, dynamic>> _parseMapResponse(http.Response response) async {
    final bodyString =
        response.bodyBytes.isEmpty ? null : utf8.decode(response.bodyBytes);

    if (bodyString != null && !_looksLikeJson(bodyString)) {
      if (AppConfig.enableLogs) {
        debugPrint('   <- Response [${response.statusCode}]: $bodyString');
      }
      throw ApiException(
        'Respuesta inesperada del servidor (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    final raw = bodyString == null ? null : jsonDecode(bodyString);
    if (AppConfig.enableLogs) {
      debugPrint('   <- Response [${response.statusCode}]: $raw');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (raw == null) {
        return {'success': true};
      }
      if (raw is Map<String, dynamic>) {
        return raw;
      }
      if (raw is List<dynamic>) {
        return {'success': true, 'data': raw};
      }
      throw const ApiException('Respuesta inesperada del servidor.');
    }

    final message = raw is Map<String, dynamic>
        ? raw['message']?.toString()
        : 'Error del servidor (${response.statusCode})';
    throw ApiException(message ?? 'Error del servidor',
        statusCode: response.statusCode);
  }

  Future<List<dynamic>> _parseListResponse(http.Response response) async {
    final bodyString =
        response.bodyBytes.isEmpty ? null : utf8.decode(response.bodyBytes);

    if (bodyString != null && !_looksLikeJson(bodyString)) {
      if (AppConfig.enableLogs) {
        debugPrint('   <- Response [${response.statusCode}]: $bodyString');
      }
      throw ApiException(
        'Respuesta inesperada del servidor (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    final raw = bodyString == null ? [] : jsonDecode(bodyString);
    if (AppConfig.enableLogs) {
      debugPrint('   <- Response [${response.statusCode}]: (list)');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (raw is List<dynamic>) {
        return raw;
      }
      if (raw is Map<String, dynamic>) {
        const keys = [
          'data',
          'productos',
          'items',
          'pedidos',
          'ubicaciones',
          'detalles',
          'results',
          'usuarios',
          'recomendaciones',
          'conversaciones',
          'mensajes'
        ];
        for (final key in keys) {
          if (raw.containsKey(key) && raw[key] is List<dynamic>) {
            return raw[key];
          }
        }
      }
      throw const ApiException('Formato de lista no valido.');
    }

    final message = raw is Map<String, dynamic>
        ? raw['message']?.toString()
        : 'Error del servidor (${response.statusCode})';
    throw ApiException(message ?? 'Error del servidor',
        statusCode: response.statusCode);
  }

  ApiException _mapToApiException(Object error) {
    if (error is ApiException) {
      return error;
    }
    if (error is SocketException) {
      return const ApiException(
          'No se pudo conectar al servidor. Verifica tu conexion.');
    }
    if (error is TimeoutException) {
      return const ApiException(
          'Tiempo de espera agotado, intenta nuevamente.');
    }
    if (error is FormatException) {
      return const ApiException('Respuesta inesperada del servidor.');
    }
    return ApiException(error.toString());
  }

  Future<Map<String, dynamic>> _post(
      String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    if (AppConfig.enableLogs) {
      debugPrint('API POST: $url');
    }
    if (AppConfig.enableLogs) {
      debugPrint('   -> Payload: ${jsonEncode(data)}');
    }
    try {
      final response = await _httpClient
          .post(url, headers: _jsonHeaders, body: jsonEncode(data))
          .timeout(_timeout);
      return await _parseMapResponse(response);
    } catch (e) {
      if (AppConfig.enableLogs) {
        debugPrint('   <- Error: $e');
      }
      throw _mapToApiException(e);
    }
  }

  Future<Map<String, dynamic>> _put(
      String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    if (AppConfig.enableLogs) {
      debugPrint('API PUT: $url');
    }
    if (AppConfig.enableLogs) {
      debugPrint('   -> Payload: ${jsonEncode(data)}');
    }
    try {
      final response = await _httpClient
          .put(url, headers: _jsonHeaders, body: jsonEncode(data))
          .timeout(_timeout);
      return await _parseMapResponse(response);
    } catch (e) {
      if (AppConfig.enableLogs) {
        debugPrint('   <- Error: $e');
      }
      throw _mapToApiException(e);
    }
  }

  Future<List<dynamic>> _get(String endpoint) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    if (AppConfig.enableLogs) {
      debugPrint('API GET List: $uri');
    }
    try {
      final response =
          await _httpClient.get(uri, headers: _jsonHeaders).timeout(_timeout);
      return await _parseListResponse(response);
    } catch (e) {
      if (AppConfig.enableLogs) {
        debugPrint('   <- Error: $e');
      }
      throw _mapToApiException(e);
    }
  }

  Future<Map<String, dynamic>> _getMap(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    if (AppConfig.enableLogs) {
      debugPrint('API GET Map: $url');
    }
    try {
      final response =
          await _httpClient.get(url, headers: _jsonHeaders).timeout(_timeout);
      return await _parseMapResponse(response);
    } catch (e) {
      if (AppConfig.enableLogs) {
        debugPrint('   <- Error: $e');
      }
      throw _mapToApiException(e);
    }
  }

  // --- IMPLEMENTACIONES ---

  @override
  Future<Usuario?> login(String email, String password) async {
    final response =
        await _post('/login', {'correo': email, 'contrasena': password});
    final rawUser = response['usuario'] ?? response['user'] ?? response['data'];
    if (rawUser is Map<String, dynamic>) {
      return Usuario.fromMap(rawUser);
    }
    return null;
  }

  @override
  Future<bool> register(String name, String email, String password,
      String phone, String rol) async {
    final normalizedRole = {
          'cliente': 'cliente',
          'delivery': 'repartidor',
          'repartidor': 'repartidor',
          'admin': 'admin',
          'soporte': 'soporte',
        }[rol.trim().toLowerCase()] ??
        'cliente';
    final response = await _post('/registro', {
      'nombre': name,
      'correo': email,
      'contrasena': password,
      'telefono': phone,
      'rol': normalizedRole,
    });
    return response['success'] ?? false;
  }

  @override
  Future<Usuario?> updateUsuario(Usuario usuario) async {
    final response =
        await _put('/usuarios/${usuario.idUsuario}', usuario.toMap());

    if (response['success'] == true) {
      final userMap = response['usuario'] as Map<String, dynamic>? ?? response;
      return Usuario.fromMap(userMap);
    }

    return null;
  }

  @override
  Future<bool> emailExists(String email) async {
    final uri = Uri.parse('$_baseUrl/usuarios/check-email')
        .replace(queryParameters: {'correo': email});
    if (AppConfig.enableLogs) {
      debugPrint('API GET Map: $uri');
    }
    try {
      final response =
          await _httpClient.get(uri, headers: _jsonHeaders).timeout(_timeout);
      final m = await _parseMapResponse(response);
      final data = m['data'] as Map<String, dynamic>? ?? m;
      final exists = data['exists'];
      if (exists is bool) return exists;
      if (exists is num) return exists != 0;
      if (exists is String) {
        final s = exists.toLowerCase();
        return s == 'true' || s == '1' || s == 'yes';
      }
      return false;
    } catch (e) {
      debugPrint('   <- Error: $e');
      throw _mapToApiException(e);
    }
  }

  @override
  Future<Usuario?> getUsuarioById(int idUsuario) async {
    final data = await _getMap('/usuarios/$idUsuario');
    final rawUser = data['usuario'] ?? data['user'] ?? data['data'] ?? data;
    return rawUser is Map<String, dynamic> ? Usuario.fromMap(rawUser) : null;
  }

  // --- Password reset / change ---
  @override
  Future<Map<String, dynamic>> generarReset(String correo) async {
    final resp = await _post('/auth/reset/generar', {'correo': correo});
    final data = resp['data'] as Map<String, dynamic>? ?? resp;
    return data;
  }

  @override
  Future<bool> confirmarReset(
      String correo, String codigo, String nuevaContrasena) async {
    final resp = await _post('/auth/reset/confirmar', {
      'correo': correo,
      'codigo': codigo,
      'nuevaContrasena': nuevaContrasena,
    });
    return resp['success'] ?? (resp['status'] == 200);
  }

  @override
  Future<bool> cambiarPassword(
      {required String actual, required String nueva}) async {
    final resp = await _put('/auth/cambiar-password', {
      'actual': actual,
      'nueva': nueva,
    });
    return resp['success'] ?? (resp['status'] == 200);
  }

  @override
  Future<List<Producto>> getProductos(
      {String? query, String? categoria}) async {
    final params = <String, String>{};
    if (query != null && query.isNotEmpty) {
      params['q'] = query;
    }
    if (categoria != null && categoria.isNotEmpty) {
      params['categoria'] = categoria;
    }

    final uri = params.isEmpty
        ? Uri.parse('$_baseUrl/productos')
        : Uri.parse('$_baseUrl/productos').replace(queryParameters: params);
    final response =
        await _httpClient.get(uri, headers: _jsonHeaders).timeout(_timeout);
    final data = await _parseListResponse(response);
    return data
        .map((item) => Producto.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Producto?> getProductoById(int id) async {
    final data = await _getMap('/productos/$id');
    return Producto.fromMap(data);
  }

  @override
  Future<List<Ubicacion>> getUbicaciones(int idUsuario) async {
    final data = await _get('/ubicaciones/usuario/$idUsuario');
    return data.cast<Map<String, dynamic>>().map(Ubicacion.fromMap).toList();
  }

  @override
  Future<List<Ubicacion>> getUbicacionesActivas() async {
    final data = await _get('/ubicaciones/activas');
    return data.cast<Map<String, dynamic>>().map(Ubicacion.fromMap).toList();
  }

  @override
  Future<void> guardarUbicacion(Ubicacion ubicacion) async {
    await _post('/ubicaciones', ubicacion.toMap());
  }

  @override
  Future<Map<String, dynamic>?> geocodificarDireccion(String direccion) async {
    final response = await _post('/geocodificar', {'direccion': direccion});
    final data = response['data'];
    if (data == null) {
      return null;
    }
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          final results = decoded['results'];
          if (results is List && results.isNotEmpty) {
            final first = results.first as Map<String, dynamic>;
            final geom = first['geometry'] as Map<String, dynamic>?;
            final loc =
                geom != null ? geom['location'] as Map<String, dynamic>? : null;
            final lat = loc != null ? (loc['lat'] as num?)?.toDouble() : null;
            final lng = loc != null ? (loc['lng'] as num?)?.toDouble() : null;
            final formatted = first['formatted_address']?.toString();
            if (lat != null && lng != null) {
              return {
                'latitud': lat,
                'longitud': lng,
                'direccion': formatted ?? direccion,
              };
            }
          }
        }
      } catch (_) {/* ignora y cae al null */}
    }
    return null;
  }

  @override
  Future<List<String>> getCategorias() async {
    // Retornar cache si es válida
    final now = DateTime.now();
    if (_cachedCategorias != null && _cachedCategoriasAt != null) {
      final age = now.difference(_cachedCategoriasAt!);
      if (age <= _categoriasCacheTtl) {
        if (AppConfig.enableLogs) {
          debugPrint(
              '[ApiDataSource] getCategorias() usando cache (${age.inSeconds}s)');
        }
        return List<String>.from(_cachedCategorias!);
      }
    }
    // Consumir el endpoint base (categorías derivadas) y el completo (categorías de tabla)
    // para asegurar que aparezcan también las vacías + la categoría artificial "Otros".
    List<String> nombres = <String>[];
    try {
      final data = await _get('/categorias');
      nombres.addAll(data.cast<String>());
    } catch (e) {
      if (AppConfig.enableLogs) {
        debugPrint('[ApiDataSource] Falló /categorias: $e');
      }
    }
    try {
      final fullResp = await _getMap('/categorias-db');
      final fullData = fullResp['data'];
      if (fullData is List) {
        for (var item in fullData) {
          if (item is Map && item['nombre'] is String) {
            nombres.add(item['nombre'] as String);
          }
        }
      }
    } catch (e) {
      if (AppConfig.enableLogs) {
        debugPrint('[ApiDataSource] /categorias-db no disponible: $e');
      }
    }
    // Normalizar: limpiar espacios, descartar vacíos
    nombres = nombres
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toSet() // quitar duplicados
        .toList();
    // Añadir "Otros" si no está
    if (!nombres.any((c) => c.toLowerCase() == 'otros')) {
      nombres.add('Otros');
    }
    // Orden alfabético (case-insensitive)
    nombres.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    // Guardar en cache
    _cachedCategorias = nombres;
    _cachedCategoriasAt = now;
    return nombres;
  }

  /// Invalida manualmente el cache de categorías (por ejemplo tras crear/editar producto).
  void invalidateCategoriasCache() {
    _cachedCategorias = null;
    _cachedCategoriasAt = null;
    if (AppConfig.enableLogs) {
      debugPrint('[ApiDataSource] Cache de categorías invalidado');
    }
  }

  /// Devuelve categorías con metadatos visuales (icono + displayName) sin romper el contrato previo.
  Future<List<Map<String, String>>> getCategoriasDecoradas() async {
    final base = await getCategorias();
    const iconMap = <String, String>{
      'bebidas': '🥤',
      'pizzas': '🍕',
      'makis': '🍣',
      'hamburguesas': '🍔',
      'otros': '📦',
    };
    String titleCase(String s) {
      if (s.isEmpty) return s;
      return s
          .split(RegExp(r"\s+"))
          .where((p) => p.isNotEmpty)
          .map((p) =>
              p.substring(0, 1).toUpperCase() + p.substring(1).toLowerCase())
          .join(' ');
    }

    return base.map((c) {
      final key = c.toLowerCase();
      final icon = iconMap[key] ?? '📁';
      return {
        'nombre': c,
        'displayName': '${icon} ${titleCase(c)}',
        'icon': icon,
      };
    }).toList(growable: false);
  }

  @override
  Future<List<ProductoRankeado>> getRecomendaciones() async {
    try {
      final response = await _getMap('/recomendaciones/destacadas');
      final data = response['data'];
      if (data is! List) return [];

      return data
          .cast<Map<String, dynamic>>()
          .map((item) => ProductoRankeado.fromMap(item))
          .where((p) => p.idProducto > 0)
          .where((p) {
        final n = p.nombre.trim();
        return n.isNotEmpty &&
            n.toLowerCase() != 'producto' &&
            n.toLowerCase() != 'sin nombre';
      }).toList();
    } on ApiException catch (e) {
      if (e.statusCode != null && e.statusCode! >= 500) {
        rethrow;
      }
      if (AppConfig.enableLogs) {
        debugPrint(
            '[ApiDataSource] Recomendaciones destacadas no disponibles (${e.statusCode ?? '-'}): ${e.message}');
      }
      return const <ProductoRankeado>[];
    }
  }

  @override
  Future<RecomendacionesProducto> getRecomendacionesPorProducto(
      int idProducto) async {
    final response = await _getMap('/productos/$idProducto/recomendaciones');
    final raw = response['data'];
    final data = raw is Map<String, dynamic>
        ? raw
        : (raw is Map
            ? raw.cast<String, dynamic>()
            : const <String, dynamic>{});
    return RecomendacionesProducto.fromMap(data);
  }

  @override
  Future<bool> addRecomendacion(
      {required int idProducto,
      required int idUsuario,
      required int puntuacion,
      String? comentario}) async {
    final response = await _post('/productos/$idProducto/recomendaciones', {
      'id_usuario': idUsuario,
      'puntuacion': puntuacion,
      'comentario': comentario,
    });
    return response['success'] ?? false;
  }

  @override
  Future<bool> placeOrder({
    required Usuario user,
    required CartModel cart,
    required Ubicacion location,
    required String paymentMethod,
  }) async {
    final productosJson = cart.items
        .map((item) => {
              'id_producto': item.producto.idProducto,
              'cantidad': item.quantity,
              'precio_unitario': item.producto.precio,
              'subtotal': item.subtotal,
            })
        .toList();

    final payload = {
      'idUsuario': user.idUsuario,
      'idNegocio': 1, // ID del negocio (puedes obtenerlo del producto)
      'items': productosJson,
      'direccionEntrega': location.direccion,
      'latitud': location.latitud ?? 0.0,
      'longitud': location.longitud ?? 0.0,
      'metodoPago': paymentMethod,
    };

    final response = await _post('/pedidos', payload);
    return response['success'] ?? false;
  }

  @override
  Future<List<Pedido>> getPedidos(int idUsuario) async {
    final data = await _get('/pedidos/cliente/$idUsuario');
    return data
        .map((item) => Pedido.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PedidoDetalle?> getPedidoDetalle(int idPedido) async {
    final data = await _getMap('/pedidos/$idPedido');
    final Map<String, dynamic> pedidoData =
        (data['data'] as Map<String, dynamic>?) ?? data;
    return PedidoDetalle.fromMap(pedidoData);
  }

  @override
  Future<List<Pedido>> getPedidosPorEstado(String estado) async {
    final data = await _get('/pedidos/estado/$estado');
    return data
        .map((item) => Pedido.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<bool> updatePedidoEstado(int idPedido, String nuevoEstado) async {
    final response =
        await _put('/pedidos/$idPedido/estado', {'estado': nuevoEstado});
    return response['success'] ?? false;
  }

  @override
  Future<List<Producto>> getAllProductosAdmin() async {
    final data = await _get('/admin/productos');
    return data
        .map((item) => Producto.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Producto?> createProducto(Producto producto) async {
    final response = await _post('/admin/productos', producto.toMap());
    return Producto.fromMap(response['producto'] as Map<String, dynamic>);
  }

  @override
  Future<bool> updateProducto(Producto producto) async {
    if (AppConfig.enableLogs) {
      debugPrint(
          '[ApiDataSource] Actualizando producto ${producto.idProducto}');
      debugPrint(
          '   -> Token presente: ${_token != null && _token!.isNotEmpty}');
      debugPrint('   -> Payload: ${producto.toMap()}');
    }

    try {
      final response = await _put(
          '/admin/productos/${producto.idProducto}', producto.toMap());

      if (AppConfig.enableLogs) {
        debugPrint('[ApiDataSource] Producto actualizado exitosamente');
        debugPrint('   <- Response: $response');
      }

      return response['success'] ?? false;
    } catch (e) {
      if (AppConfig.enableLogs) {
        debugPrint('[ApiDataSource] ERROR al actualizar producto: $e');
      }
      rethrow;
    }
  }

  @override
  Future<bool> deleteProducto(int idProducto) async {
    final response = await _delete('/admin/productos/$idProducto');
    return response['success'] ?? false;
  }

  Future<Map<String, dynamic>> _delete(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    if (AppConfig.enableLogs) {
      debugPrint('API DELETE: $url');
    }
    try {
      final response = await _httpClient
          .delete(url, headers: _jsonHeaders)
          .timeout(_timeout);
      return await _parseMapResponse(response);
    } catch (e) {
      debugPrint('   <- Error: $e');
      throw _mapToApiException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getAdminStats() async {
    return await _getMap('/admin/stats');
  }

  @override
  Future<Map<String, dynamic>> getNegocioStats(int negocioId) async {
    final m = await _getMap('/negocios/$negocioId/stats');
    final data = m['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return m;
  }

  @override
  Future<Negocio?> getNegocioDeUsuario(int idUsuario) async {
    final resp = await _getMap('/usuarios/$idUsuario/negocio');
    final data = resp['data'];
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      return Negocio.fromMap(data);
    }
    if (data is Map) {
      return Negocio.fromMap(Map<String, dynamic>.from(data));
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> registrarNegocioParaUsuario(
      int idUsuario, Negocio negocio) async {
    final payload = Map<String, dynamic>.from(negocio.toJson());
    payload['id_usuario'] = idUsuario;
    final resp = await _post('/usuarios/$idUsuario/negocio', payload);
    final data = resp['data'];

    if (data is Map<String, dynamic>) {
      // Respuesta actualizada con negocio y usuario
      if (data.containsKey('negocio') && data.containsKey('usuario')) {
        return {
          'negocio': Negocio.fromMap(data['negocio'] as Map<String, dynamic>),
          'usuario': Usuario.fromMap(data['usuario'] as Map<String, dynamic>),
        };
      }
      // Retrocompatibilidad: respuesta antigua solo con negocio
      return {
        'negocio': Negocio.fromMap(data),
        'usuario': null,
      };
    }
    if (data is Map) {
      final dataMap = Map<String, dynamic>.from(data);
      if (dataMap.containsKey('negocio') && dataMap.containsKey('usuario')) {
        return {
          'negocio':
              Negocio.fromMap(dataMap['negocio'] as Map<String, dynamic>),
          'usuario':
              Usuario.fromMap(dataMap['usuario'] as Map<String, dynamic>),
        };
      }
      return {
        'negocio': Negocio.fromMap(dataMap),
        'usuario': null,
      };
    }
    return null;
  }

  // --- Negocios ---
  @override
  Future<List<Usuario>> getNegocios() async {
    final data = await _get('/admin/negocios');
    return data.map((e) => Usuario.fromMap(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Usuario?> createNegocio(Usuario negocio) async {
    final resp = await _post('/admin/negocios', negocio.toMap());
    final m = resp['usuario'] as Map<String, dynamic>? ??
        resp['data'] as Map<String, dynamic>? ??
        resp;
    return Usuario.fromMap(m);
  }

  @override
  Future<Usuario?> getNegocioById(int id) async {
    final m = await _getMap('/admin/negocios/$id');
    final data = m['data'] as Map<String, dynamic>? ?? m;
    return Usuario.fromMap(data);
  }

  @override
  Future<Usuario?> updateNegocio(Usuario negocio) async {
    final m =
        await _put('/admin/negocios/${negocio.idUsuario}', negocio.toMap());
    final data = m['data'] as Map<String, dynamic>? ?? m;
    return Usuario.fromMap(data);
  }

  @override
  Future<List<Producto>> getProductosPorNegocio(int idNegocio) async {
    final data = await _get('/admin/negocios/$idNegocio/productos');
    return data
        .map((e) => Producto.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Producto?> createProductoParaNegocio(
      int idNegocio, Producto producto) async {
    final resp =
        await _post('/admin/negocios/$idNegocio/productos', producto.toMap());
    final m = resp['producto'] as Map<String, dynamic>? ??
        resp['data'] as Map<String, dynamic>? ??
        resp;
    return Producto.fromMap(m);
  }

  @override
  Future<List<Pedido>> getPedidosDisponibles() async {
    final data = await _get('/pedidos/disponibles');
    return data
        .map((item) => Pedido.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<bool> asignarPedido(int idPedido, int idDelivery) async {
    final response =
        await _put('/pedidos/$idPedido/asignar', {'id_delivery': idDelivery});
    return response['success'] ?? false;
  }

  @override
  Future<List<Pedido>> getPedidosPorDelivery(int idDelivery) async {
    final data = await _get('/pedidos/delivery/$idDelivery');
    return data
        .map((item) => Pedido.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getDeliveryStats(int idDelivery) async {
    return await _getMap('/delivery/stats/$idDelivery');
  }

  @override
  Future<bool> updateRepartidorLocation(
      int idRepartidor, double lat, double lon) async {
    final response = await _put('/ubicaciones/repartidor/$idRepartidor',
        {'latitud': lat, 'longitud': lon});
    return response['success'] ?? false;
  }

  @override
  Future<Map<String, dynamic>?> getRepartidorLocation(int idPedido) async {
    try {
      final data = await _getMap('/tracking/pedido/$idPedido');
      return data['data'] as Map<String, dynamic>?;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return null; // Not found is not an error here.
      }
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRepartidoresLocation(
      List<int> ids) async {
    final response =
        await _post('/tracking/repartidores/ubicaciones', {'ids': ids});
    final data = response['data'];
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  @override
  Future<List<TrackingPoint>> getTrackingRoute(int idPedido) async {
    try {
      final data = await _get('/tracking/pedido/$idPedido/ruta');
      return data
          .map((item) => TrackingPoint.fromMap(item as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return const [];
      }
      rethrow;
    }
  }

  @override
  Future<int?> iniciarConversacion(
      {required int idCliente,
      int? idDelivery,
      int? idAdminSoporte,
      int? idPedido}) async {
    final response = await _post(
        '/chat/iniciar',
        {
          'idCliente': idCliente,
          'idDelivery': idDelivery,
          'idAdminSoporte': idAdminSoporte,
          'idPedido': idPedido
        }..removeWhere((key, value) => value == null));
    return response['id_conversacion'] as int?;
  }

  @override
  Future<List<ChatConversation>> getConversaciones(int idUsuario) async {
    final data = await _get('/chat/conversaciones/$idUsuario');
    return data
        .map((item) => ChatConversation.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ChatMessage>> getMensajesDeConversacion(int idConversacion,
      {int limit = 20, int offset = 0}) async {
    final data = await _get(
        '/chat/conversaciones/$idConversacion/mensajes?limit=$limit&offset=$offset');
    return data
        .map((item) => ChatMessage.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> enviarMensaje({
    required int idConversacion,
    required int idRemitente,
    required String mensaje,
    required String chatSection,
    bool esBot = false,
  }) async {
    if (chatSection == 'unibot') {
      // Bot con IA (Gemini)
      final response = await _post('/chat/bot/mensajes', {
        'id_conversacion': idConversacion,
        'idRemitente': idRemitente,
        'mensaje': mensaje,
      });

      // Extraer data para el cliente
      final data = response['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(response['data'] as Map)
          : <String, dynamic>{};

      return {
        'success': response['success'] ?? true,
        'id_conversacion': data['id_conversacion'] ?? idConversacion,
        'bot_reply': data['bot_reply'],
        'message': response['message'],
      };
    }

    if (chatSection == 'soporte') {
      // Soporte usa el mismo endpoint que el bot (respuestas automáticas)
      // El backend diferencia por el contexto del mensaje
      final response = await _post('/chat/bot/mensajes', {
        'id_conversacion': idConversacion,
        'idRemitente': idRemitente,
        'mensaje': mensaje,
      });

      if (AppConfig.enableLogs) {
        debugPrint('[ApiDataSource] Soporte response: $response');
      }

      // Extraer data para el cliente
      final data = response['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(response['data'] as Map)
          : <String, dynamic>{};

      return {
        'success': response['success'] ?? true,
        'id_conversacion': data['id_conversacion'] ?? idConversacion,
        'bot_reply': data['bot_reply'] ?? data['respuesta'],
        'message': response['message'],
      };
    }

    if (idConversacion <= 0) {
      throw const ApiException('Conversacion no valida para enviar mensajes.');
    }

    return _post(
      '/chat/mensajes',
      {
        'idConversacion': idConversacion,
        'idRemitente': idRemitente,
        'mensaje': mensaje,
        'idDestinatario': null,
      },
    );
  }

  // --- Opiniones ---
  @override
  Future<List<Map<String, dynamic>>> getOpiniones({int limit = 20}) async {
    final data = await _get('/opiniones?limit=$limit');
    return data.whereType<Map<String, dynamic>>().toList();
  }

  @override
  Future<bool> crearOpinion({
    int? idUsuario,
    String? nombre,
    String? email,
    required int rating,
    required String comentario,
    String? plataforma,
  }) async {
    final payload = <String, dynamic>{
      'id_usuario': idUsuario,
      'nombre': nombre,
      'email': email,
      'rating': rating,
      'comentario': comentario,
      'plataforma': plataforma ?? 'app',
    }..removeWhere((k, v) => v == null);
    final resp = await _post('/opiniones', payload);
    return resp['success'] ?? false;
  }

  @override
  Future<List<Map<String, dynamic>>> getOpinionesAdmin(
      {String? clasificacion, int limit = 50}) async {
    final qp = <String, String>{'limit': '$limit'};
    if (clasificacion != null && clasificacion.isNotEmpty) {
      qp['clasificacion'] = clasificacion;
    }
    final uri =
        Uri.parse('$_baseUrl/admin/opiniones').replace(queryParameters: qp);
    if (AppConfig.enableLogs) {
      debugPrint('API GET List: $uri');
    }
    final response =
        await _httpClient.get(uri, headers: _jsonHeaders).timeout(_timeout);
    final list = await _parseListResponse(response);
    return list.whereType<Map<String, dynamic>>().toList();
  }
}
