import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Importa la función adecuada según la plataforma (web o no web).
import '../utils/google_maps_iframe_stub.dart'
    if (dart.library.html) '../utils/google_maps_iframe_web.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import '../routes/app_routes.dart';

import '../models/pedido.dart';
import '../models/session_state.dart';
import '../services/database_service.dart';
import '../utils/web_geolocation_stub.dart'
    if (dart.library.html) '../utils/web_geolocation_web.dart' as webgeo;

class LiveMapScreenOptimized extends StatefulWidget {
  const LiveMapScreenOptimized({super.key});

  @override
  State<LiveMapScreenOptimized> createState() => _LiveMapScreenOptimizedState();
}

class _LiveMapScreenOptimizedState extends State<LiveMapScreenOptimized> {
  static const LatLng _esmeraldasCenter = LatLng(0.988, -79.652);

  final Location _location = Location();
  GoogleMapController? _mapController;
  StreamSubscription<LocationData>? _locationSubscription;
  StreamSubscription<webgeo.WebGeoPosition>? _webLocationSubscription;
  
  // OPTIMIZACIÓN: Solo mantener timers que se usan activamente
  Timer? _refreshTimer;
  Timer? _updateDebounce; // Nuevo: debounce para actualizaciones

  DateTime? _lastLocationUpload;
  bool _isRefreshingMarkers = false;

  LatLng? _userPosition;
  bool _isMapReady = false;
  String? _infoMessage;
  String? _errorMessage;
  PermissionStatus _permissionStatus = PermissionStatus.denied;

  Set<Marker> _markers = <Marker>{};
  
  // OPTIMIZACIÓN: Función _sameMarkers mejorada con O(n) en lugar de O(n²)
  bool _sameMarkers(Set<Marker> other) {
    if (other.length != _markers.length) return false;
    
    // Crear mapa para búsqueda O(1)
    final currentMap = {for (var m in _markers) m.markerId: m};
    
    for (final marker in other) {
      final current = currentMap[marker.markerId];
      if (current == null || 
          current.position != marker.position || 
          current.icon != marker.icon) {
        return false;
      }
    }
    return true;
  }

  void _fitCameraToMarkers(Set<Marker> markers) {
    if (_mapController == null || markers.isEmpty) return;
    final positions = markers.map((m) => m.position).toList();
    if (positions.isEmpty) return;
    if (positions.length == 1) {
      _mapController!.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: positions.first, zoom: 15),
      ));
      return;
    }
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLon = positions.first.longitude;
    double maxLon = positions.first.longitude;
    for (final position in positions.skip(1)) {
      minLat = math.min(minLat, position.latitude);
      maxLat = math.max(maxLat, position.latitude);
      minLon = math.min(minLon, position.longitude);
      maxLon = math.max(maxLon, position.longitude);
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 72),
    );
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    context.read<SessionController>().removeListener(_onSessionChange);
    _mapController?.dispose();
    _locationSubscription?.cancel();
    _webLocationSubscription?.cancel();
    _refreshTimer?.cancel();
    _updateDebounce?.cancel(); // Limpiar debounce
    super.dispose();
  }

  Future<void> _bootstrap() async {
    context.read<SessionController>().addListener(_onSessionChange);
    try {
      await _checkAndRequestLocationPermission();
      await _refreshMarkers();
      if (mounted) {
        setState(() => _isMapReady = true);
        _startLocationUpdates();
        _startOptimizedRefreshTimer(); // Nuevo método optimizado
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al inicializar: $e';
          _isMapReady = true;
        });
      }
    }
  }

  // OPTIMIZACIÓN: Timer inteligente que se adapta según la actividad
  void _startOptimizedRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _scheduleMarkerUpdate();
    });
  }

  // OPTIMIZACIÓN: Debounce para evitar actualizaciones excesivas
  void _scheduleMarkerUpdate() {
    _updateDebounce?.cancel();
    _updateDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _refreshMarkers();
    });
  }

  void _onSessionChange() {
    final session = context.read<SessionController>();
    if (session.isAuthenticated) {
      _scheduleMarkerUpdate(); // Usar debounce
    }
  }

  Future<void> _checkAndRequestLocationPermission() async {
    try {
      if (kIsWeb) {
        if (mounted) {
          setState(() => _permissionStatus = PermissionStatus.granted);
        }
        final pos = await webgeo.getCurrentPosition();
        if (mounted) {
          setState(() {
            _userPosition = pos != null
                ? LatLng(pos.lat, pos.lng)
                : _esmeraldasCenter;
          });
        }
        await _refreshMarkers();
        return;
      }

      bool serviceEnabled = true;
      if (!kIsWeb) {
        serviceEnabled = await _location.serviceEnabled();
        if (!serviceEnabled) {
          serviceEnabled = await _location.requestService();
          if (!serviceEnabled) {
            if (mounted) {
              setState(() => _permissionStatus = PermissionStatus.denied);
            }
            return;
          }
        }
      }

      _permissionStatus = await _location.hasPermission();
      if (_permissionStatus == PermissionStatus.denied) {
        _permissionStatus = await _location.requestPermission();
      }

      if (_permissionStatus != PermissionStatus.granted) {
        if (mounted) {
          setState(() {});
        }
        return;
      }

      if (mounted) {
        setState(() => _permissionStatus = PermissionStatus.granted);
      }
      await _fetchCurrentUserLocation();
    } catch (e) {
      if (mounted) {
        setState(
            () => _errorMessage = 'Error con los permisos: ${e.toString()}');
      }
    }
  }

  Future<void> _fetchCurrentUserLocation() async {
    try {
      final currentLocation = await _location.getLocation();
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        final latLng =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);
        if (mounted) {
          setState(() {
            _userPosition = latLng;
            _infoMessage = 'Ubicacion actualizada.';
          });
          _moveCamera(latLng, zoom: 15);
          _maybeUploadDeliveryLocation(latLng);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'No se pudo obtener tu ubicacion.');
      }
    }
  }

  Future<void> _refreshMarkers() async {
    if (!mounted || _isRefreshingMarkers) return;
    if (!mounted) return;

    final db = context.read<DatabaseService>();
    final session = context.read<SessionController>();
    final usuario = session.usuario;

    if (usuario == null || !usuario.isAuthenticated) {
      if (mounted) {
        setState(() {
          _infoMessage = 'Inicia sesion para ver tus pedidos en el mapa.';
          _markers.clear();
        });
      }
      return;
    }

    // OPTIMIZACIÓN: Batch setState calls
    setState(() {
      _infoMessage = 'Actualizando...';
      _errorMessage = null;
      _isRefreshingMarkers = true;
    });

    try {
      final role = usuario.rol.trim().toLowerCase();
      final List<Pedido> pedidos;
      switch (role) {
        case 'delivery':
        case 'repartidor':
          pedidos = await db.getPedidosPorDelivery(usuario.idUsuario);
          break;
        case 'admin':
        case 'soporte':
        case 'negocio':
          pedidos = await db.getPedidosPorEstado('en camino');
          break;
        default:
          final todosLosPedidos = await db.getPedidos(usuario.idUsuario);
          pedidos = todosLosPedidos
              .where((p) => p.estado != 'entregado' && p.estado != 'cancelado')
              .toList();
      }

      final markers = <Marker>{};

      // OPTIMIZACIÓN: Agrupar por repartidor para reducir llamadas de red
      final deliveryIds = pedidos
          .where((p) => p.idDelivery != null)
          .map((p) => p.idDelivery!)
          .toSet()
          .toList();

      final deliveryLocations = <int, LatLng>{};

      if (deliveryIds.isNotEmpty) {
        try {
          final locationsData = await db.getRepartidoresLocation(deliveryIds);
          for (final locData in locationsData) {
            final id = locData['id_repartidor'] as int?;
            final lat = _parseDouble(locData['latitud']);
            final lon = _parseDouble(locData['longitud']);

            if (id != null && lat != null && lon != null) {
              deliveryLocations[id] = LatLng(lat, lon);
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error al obtener ubicaciones de repartidores en lote: $e');
          }
        }
      }

      // Construir marcadores usando el mapa pre-cargado
      for (final pedido in pedidos) {
        if (pedido.idDelivery == null) continue;
        final deliveryPosition = deliveryLocations[pedido.idDelivery];
        if (deliveryPosition != null) {
          markers.add(_createDeliveryMarker(pedido, deliveryPosition));
        }
      }

      if (mounted) {
        // OPTIMIZACIÓN: Solo actualizar si hay cambios reales
        if (!_sameMarkers(markers)) {
          setState(() {
            _markers = markers;
            _infoMessage = '';
          });
        } else {
          setState(() {
            _infoMessage = '';
          });
        }
        
        if (markers.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _fitCameraToMarkers(markers);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error al actualizar: ${e.toString()}');
      }
    } finally {
      _isRefreshingMarkers = false;
    }
  }

  Marker _createDeliveryMarker(Pedido pedido, LatLng position) {
    return Marker(
      markerId: MarkerId('delivery_${pedido.idDelivery}_${pedido.idPedido}'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow: InfoWindow(
        title: 'Repartidor #${pedido.idDelivery}',
        snippet: 'Pedido ${pedido.idPedido}',
      ),
      onTap: () {
        _moveCamera(position, zoom: 16);
        Navigator.of(context).pushNamed(
          AppRoutes.orderDetail,
          arguments: pedido.idPedido,
        );
      },
    );
  }

  void _moveCamera(LatLng target, {double zoom = 13}) =>
      _mapController?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: zoom)));
          
  double? _parseDouble(dynamic value) => (value is num)
      ? value.toDouble()
      : (value is String ? double.tryParse(value) : null);

  void _startLocationUpdates() {
    if (kIsWeb) {
      _webLocationSubscription?.cancel();
      _webLocationSubscription = webgeo.watchPosition().listen((p) {
        if (!mounted) return;
        final nextPosition = LatLng(p.lat, p.lng);
        final movedEnough = _userPosition == null ||
            _distanceBetween(_userPosition!, nextPosition) > 5;
        if (!movedEnough) return;
        setState(() {
          _userPosition = nextPosition;
          _infoMessage = 'Ubicacion actualizada.';
        });
        _maybeUploadDeliveryLocation(nextPosition);
      });
      return;
    }
    _locationSubscription?.cancel();
    _locationSubscription = _location.onLocationChanged.listen((data) {
      if (!mounted) return;
      final lat = data.latitude;
      final lon = data.longitude;
      if (lat == null || lon == null) return;
      final nextPosition = LatLng(lat, lon);
      final movedEnough = _userPosition == null ||
          _distanceBetween(_userPosition!, nextPosition) > 5;
      if (!movedEnough) return;

      setState(() {
        _userPosition = nextPosition;
        _infoMessage = 'Ubicacion actualizada.';
      });
      _maybeUploadDeliveryLocation(nextPosition);
    });
  }

  Future<void> _maybeUploadDeliveryLocation(LatLng position) async {
    final session = context.read<SessionController>();
    final usuario = session.usuario;
    if (usuario == null || !usuario.isAuthenticated) return;
    final role = usuario.rol.trim().toLowerCase();
    if (role != 'delivery' && role != 'repartidor') return;

    final now = DateTime.now();
    // OPTIMIZACIÓN: Aumentar intervalo a 20 segundos para reducir carga
    if (_lastLocationUpload != null &&
        now.difference(_lastLocationUpload!) < const Duration(seconds: 20)) {
      return;
    }
    _lastLocationUpload = now;

    try {
      await context.read<DatabaseService>().updateRepartidorLocation(
          usuario.idUsuario, position.latitude, position.longitude);
    } catch (e) {
      if (kDebugMode) {
        print('No se pudo enviar la ubicacion del repartidor: $e');
      }
    }
  }

  double _distanceBetween(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final hav =
        _haversin(dLat) + math.cos(lat1) * math.cos(lat2) * _haversin(dLon);
    final c = 2 * math.atan2(math.sqrt(hav), math.sqrt(1 - hav));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);
  double _haversin(double value) => math.pow(math.sin(value / 2), 2).toDouble();

  String _buildWebMapUrl() {
    final positions = <LatLng>[];
    if (_userPosition != null) {
      positions.add(_userPosition!);
    }
    positions.addAll(_markers
        .where((m) => m.markerId.value != 'user')
        .map((m) => m.position));

    if (positions.isEmpty) {
      positions.add(_esmeraldasCenter);
    }

    final queries = <String>{};
    for (final position in positions) {
      queries.add('${position.latitude},${position.longitude}');
    }

    final buffer =
        StringBuffer('https://maps.google.com/maps?output=embed&z=14');
    for (final coordinate in queries) {
      buffer.write('&q=$coordinate');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Optimizado'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: () => _scheduleMarkerUpdate(), // Usar debounce
          ),
        ],
      ),
      body: _buildMapBody(),
    );
  }

  Widget _buildMapBody() {
    if (!_isMapReady) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_permissionStatus != PermissionStatus.granted) {
      return _buildPermissionDeniedView();
    }

    if (kIsWeb) {
      final url = _buildWebMapUrl();
      registerGoogleMapsIframe(url);
      return Stack(children: [
        const SizedBox.expand(
          child: HtmlElementView(viewType: 'google-maps-iframe'),
        ),
        _buildTopInfoBar(),
      ]);
    } else {
      return Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _userPosition ?? _esmeraldasCenter,
              zoom: _userPosition != null ? 14 : 12,
              tilt: 45,
            ),
            markers: _markers,
            myLocationEnabled: _permissionStatus == PermissionStatus.granted,
            myLocationButtonEnabled:
                _permissionStatus == PermissionStatus.granted,
            liteModeEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
            buildingsEnabled: true,
            indoorViewEnabled: true,
            trafficEnabled: false,
            minMaxZoomPreference: const MinMaxZoomPreference(3, 19),
            onMapCreated: (controller) async {
              _mapController = controller;
            },
          ),
          _buildTopInfoBar(),
        ],
      );
    }
  }

  Widget _buildPermissionDeniedView() {
    final isPermanentlyDenied =
        _permissionStatus == PermissionStatus.deniedForever;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 96,
              color: Theme.of(context).colorScheme.primary.withAlpha(179),
            ),
            const SizedBox(height: 24),
            Text(
              'Permiso de ubicacion Requerido',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isPermanentlyDenied
                  ? 'Para usar el mapa, debes habilitar los permisos de ubicacion manualmente desde la configuracion de tu dispositivo.'
                  : 'Necesitamos tu permiso para mostrar tu ubicacion y los repartidores cercanos en el mapa.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: Icon(
                isPermanentlyDenied && !kIsWeb
                    ? Icons.settings
                    : Icons.location_on,
              ),
              onPressed: () async {
                if (isPermanentlyDenied && !kIsWeb) {
                  await _location.requestService();
                }
                await _checkAndRequestLocationPermission();
              },
              label: Text(isPermanentlyDenied
                  ? 'Abrir configuracion'
                  : 'Conceder Permiso'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopInfoBar() {
    final bool hasError = _errorMessage != null;
    final String message = _errorMessage ?? _infoMessage ?? 'Cargando mapa...';
    final Color bgColor = hasError
        ? Colors.red.shade400
        : Colors.black.withAlpha(153);
    final IconData icon =
        hasError ? Icons.warning_amber_rounded : Icons.info_outline_rounded;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
              .copyWith(top: MediaQuery.of(context).viewPadding.top + 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(128),
                Colors.transparent,
              ],
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 5, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (hasError ||
                    message.contains('Sin repartidores') ||
                    message.contains('Actualizando'))
                  TextButton(
                    onPressed: () => _scheduleMarkerUpdate(),
                    child: const Text(
                      'Reintentar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}