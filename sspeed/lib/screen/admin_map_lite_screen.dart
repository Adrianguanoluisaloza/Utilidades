import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../models/usuario.dart';
import '../services/database_service.dart';

class AdminMapLiteScreen extends StatefulWidget {
  final Usuario adminUser;
  const AdminMapLiteScreen({super.key, required this.adminUser});

  @override
  State<AdminMapLiteScreen> createState() => _AdminMapLiteScreenState();
}

class _AdminMapLiteScreenState extends State<AdminMapLiteScreen> {
  static const LatLng _defaultCenter = LatLng(0.988, -79.652);

  GoogleMapController? _controller;
  final Set<Marker> _markers = {};
  final Map<int, String> _roleCache = {}; // idUsuario -> rol
  Timer? _pollTimer;
  bool _firstFitDone = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAndUpdate();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 45), (_) => _fetchAndUpdate());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _fetchAndUpdate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final db = context.read<DatabaseService>();
      final list = await db.getUbicacionesActivas();

      // Pre-cargar roles en caché (limitamos el número por ciclo para evitar sobrecarga)
      final missing = <int>{};
      for (final u in list) {
        if (!_roleCache.containsKey(u.idUsuario)) missing.add(u.idUsuario);
      }
      // Trae hasta 30 roles por ciclo
      final toFetch = missing.take(30).toList();
      for (final id in toFetch) {
        try {
          final user = await db.getUsuarioById(id);
          if (user != null) {
            _roleCache[id] = user.rol.trim().toLowerCase();
          }
        } catch (_) {
          // ignorar fallos individuales
        }
      }

      final markers = <Marker>{};
      for (final loc in list) {
        final lat = loc.latitud;
        final lon = loc.longitud;
        if (lat == null || lon == null) continue;
        final role = _roleCache[loc.idUsuario] ?? 'cliente';
        final hue = role == 'delivery' || role == 'repartidor'
            ? BitmapDescriptor.hueRed
            : BitmapDescriptor.hueGreen;
        markers.add(
          Marker(
            markerId: MarkerId(
                'u_${loc.idUsuario}_${loc.id ?? math.Random().nextInt(99999)}'),
            position: LatLng(lat, lon),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            infoWindow: InfoWindow(
              title: role == 'delivery' || role == 'repartidor'
                  ? 'Repartidor'
                  : 'Cliente',
              snippet: loc.direccion ?? 'Ubicación activa',
            ),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _markers
          ..clear()
          ..addAll(markers);
        _loading = false;
      });

      if (!_firstFitDone && markers.isNotEmpty && _controller != null) {
        _firstFitDone = true;
        _fitBounds(markers);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar ubicaciones: $e';
        _loading = false;
      });
    }
  }

  void _fitBounds(Set<Marker> markers) {
    if (markers.isEmpty || _controller == null) return;
    final positions = markers.map((m) => m.position).toList();
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLon = positions.first.longitude;
    double maxLon = positions.first.longitude;
    for (final p in positions.skip(1)) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLon = math.min(minLon, p.longitude);
      maxLon = math.max(maxLon, p.longitude);
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );
    _controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 56));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Lite (Admin)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAndUpdate,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: kIsWeb
          ? _buildWebFallback()
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: _defaultCenter,
                    zoom: 12,
                  ),
                  liteModeEnabled: true, // modo rápido, sin gestos avanzados
                  markers: _markers,
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  buildingsEnabled: false,
                  indoorViewEnabled: false,
                  trafficEnabled: false,
                  minMaxZoomPreference: const MinMaxZoomPreference(3, 19),
                  onMapCreated: (c) async {
                    _controller = c;
                    // El método setMapStyle está obsoleto. Si la API lo permite, usar la propiedad 'style' en GoogleMap.
                    // Si no está disponible, simplemente omitir la llamada.
                    if (_markers.isNotEmpty) {
                      _fitBounds(_markers);
                    }
                  },
                ),
                if (_loading)
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                if (_error != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 16,
                    child: _ErrorBanner(message: _error!),
                  ),
              ],
            ),
    );
  }

  Widget _buildWebFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'El Mapa Lite está disponible en la app móvil (Android).',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
