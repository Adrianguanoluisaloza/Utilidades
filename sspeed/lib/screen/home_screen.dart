import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../models/cart_model.dart';
import '../models/producto.dart';
import '../models/usuario.dart';
import '../models/pedido.dart'; // ignore: unused_import
import '../services/database_service.dart';
import '../config/app_theme.dart';
import '../widgets/app_card.dart';
import 'widgets/login_required_dialog.dart';
import 'package:speed_delivery/screen/product_detail.dart';
import 'cart_screen.dart';

// Resuelve URLs de imágenes para soportar S3/CloudFront
String _resolveImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  // Si ya es una URL completa, devolverla tal cual
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  // Usar bucket S3 configurado
  const s3BaseUrl = 'http://unitespeed-landing-2025.s3-website.us-east-2.amazonaws.com/productos/';
  return s3BaseUrl + url;
}

class HomeScreen extends StatefulWidget {
  final Usuario usuario;
  const HomeScreen({super.key, required this.usuario});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Producto>> _productosFuture;
  late Future<List<ProductoRankeado>> _recommendationsFuture;
  // late Future<List<Map<String, dynamic>>> _repartidoresLocationFuture; // Deshabilitado temporalmente
  late DatabaseService _databaseService;
  late final PageController _recommendationsController;
  late Future<Set<Marker>> _deliveryMarkersFuture;

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "Todos";
  bool _hasQuery = false;
  Timer? _debounce;
  // Timer? _repartidoresRefreshTimer; // Deshabilitado temporalmente
  int _currentRecommendationPage = 0;

  final List<String> _categories = const [
    'Todos',
    'Pizzas',
    'Hamburguesas',
    'Acompanamientos',
    'Bebidas',
    'Postres',
    'Ensaladas',
    'Pastas',
    'Mexicana',
    'Japonesa',
    'Mariscos',
  ];

  @override
  void initState() {
    super.initState();
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    _recommendationsController = PageController(viewportFraction: 0.82);
    _loadProducts();
    _loadRecommendations();
    _deliveryMarkersFuture = _loadDeliveryMarkers();
    // _loadRepartidoresLocation(); // Deshabilitado - Tracking de repartidores removido
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    // _repartidoresRefreshTimer?.cancel(); // Deshabilitado - Tracking de repartidores removido
    _recommendationsController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _loadRecommendations() {
    _recommendationsFuture = _databaseService.getRecomendaciones().timeout(
      const Duration(seconds: 3),
      onTimeout: () => <ProductoRankeado>[],
    );
  }

  void _loadProducts() {
    final query = _searchController.text.trim();
    final categoryFilter =
        _selectedCategory == 'Todos' ? '' : _selectedCategory;
    setState(() {
      _productosFuture = _databaseService.getProductos(
          query: query, categoria: categoryFilter);
    });
  }

  /* DESHABILITADO - Tracking de repartidores removido para evitar errores
  void _loadRepartidoresLocation() {
    // CORRECCI�N: Ahora primero obtenemos los pedidos 'en camino' para saber qu� repartidores buscar.
    // Esto soluciona el problema de que los marcadores de repartidor no aparec�an.
    Future<List<Map<String, dynamic>>> fetchLocations() async {
      final pedidosEnCamino =
          await _databaseService.getPedidosPorEstado('en camino');
      final deliveryIds = pedidosEnCamino
          .where((p) => p.idDelivery != null)
          .map((p) => p.idDelivery!)
          .toSet()
          .toList();

      if (deliveryIds.isEmpty) return [];
      return _databaseService.getRepartidoresLocation(deliveryIds);
    }

    setState(() {
      _repartidoresLocationFuture = fetchLocations();
    });
    _repartidoresRefreshTimer?.cancel();
    _repartidoresRefreshTimer = Timer.periodic(
      const Duration(
          hours:
              2), // OPTIMIZACION: Actualizacionsion cada 2 horas para ahorrar cuota de Google Maps API gratuita
      (_) {
        if (mounted) {
          setState(() {
            _repartidoresLocationFuture = fetchLocations();
          });
        }
      },
    );
  }
  */

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(AppTheme.spacing2),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _hasQuery
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                    _loadProducts();
                  },
                )
              : null,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        onSubmitted: (_) => _loadProducts(),
      ),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing2),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) {
              setState(() => _selectedCategory = category);
              _loadProducts();
            },
          );
        },
        separatorBuilder: (_, __) => SizedBox(width: AppTheme.spacing1),
        itemCount: _categories.length,
      ),
    );
  }

  void _onSearchChanged() {
    final hasQuery = _searchController.text.trim().isNotEmpty;
    if (_hasQuery != hasQuery) {
      setState(() => _hasQuery = hasQuery);
    }
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _loadProducts);
  }

  void _handleCartTap() {
    if (!widget.usuario.isAuthenticated) {
      showLoginRequiredDialog(context);
    } else {
      // CORRECCI�N: Se navega a la pantalla del carrito en lugar de directamente al checkout.
      // Esto evita el crash de la app, ya que la pantalla del carrito es el paso previo
      // donde el usuario puede revisar su pedido antes de seleccionar la direcci�n.
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CartScreen(usuario: widget.usuario)));
    }
  }

  Widget _buildProductosTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _productosFuture;
        _loadProducts();
        // refrescar posiciones de repartidores bajo demanda
        setState(() {
          _deliveryMarkersFuture = _loadDeliveryMarkers();
        });
      },
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                if (!_hasQuery) ...[
                  _buildDeliveryMapCard(),
                  _buildRecommendationsCarousel(),
                  const SizedBox(height: 16),
                  _buildLiveTrackingCard(),
                ],
                const SizedBox(height: 16),
                _buildCategoryList(),
              ],
            ),
          ),
          _buildProductsGrid(),
        ],
      ),
    );
  }

  // Nuevo: Mapa real con controles mostrando repartidores (sin tiempo real)
  Widget _buildDeliveryMapCard() {
    return FutureBuilder<Set<Marker>>(
      future: _deliveryMarkersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Card(
              child: SizedBox(
                height: 220,
                child: Container(color: Colors.grey.shade200),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: InfoMessage(
                icon: Icons.map_outlined,
                message: 'No se pudo cargar el mapa: ${snapshot.error}'),
          );
        }
        final markers = snapshot.data ?? <Marker>{};
        if (markers.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: const [
                    Icon(Icons.delivery_dining, color: Colors.grey),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Sin repartidores activos hoy.'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final center = markers.first.position;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 220,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: center, zoom: 13),
                markers: markers,
                // Mapa real con controles por defecto (sin myLocation para no pedir permisos)
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                mapToolbarEnabled: true,
                compassEnabled: true,
                buildingsEnabled: true,
                indoorViewEnabled: true,
                trafficEnabled: false,
                liteModeEnabled: false,
                tiltGesturesEnabled: true,
                rotateGesturesEnabled: true,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Set<Marker>> _loadDeliveryMarkers() async {
    // Sin tiempo real: una sola consulta bajo demanda
    final pedidosEnCamino =
        await _databaseService.getPedidosPorEstado('en camino');
    final deliveryIds = pedidosEnCamino
        .where((p) => p.idDelivery != null)
        .map((p) => p.idDelivery!)
        .toSet()
        .toList();
    if (deliveryIds.isEmpty) return <Marker>{};

    final locations =
        await _databaseService.getRepartidoresLocation(deliveryIds);
    final markers = <Marker>{};
    for (final loc in locations) {
      final id = loc['id_repartidor'] as int?;
      final lat = _parseDouble(loc['latitud']);
      final lon = _parseDouble(loc['longitud']);
      if (id == null || lat == null || lon == null) continue;
      markers.add(
        Marker(
          markerId: MarkerId('delivery_$id'),
          position: LatLng(lat, lon),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(title: 'Repartidor #$id'),
        ),
      );
    }
    return markers;
  }

  double? _parseDouble(dynamic value) => (value is num)
      ? value.toDouble()
      : (value is String ? double.tryParse(value) : null);

  Widget _buildProductsGrid() => FutureBuilder<List<Producto>>(
        future: _productosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SliverToBoxAdapter(child: ProductsGridLoading());
          }
          if (snapshot.hasError) {
            return SliverFillRemaining(
                child: InfoMessage(
                    icon: Icons.cloud_off,
                    message: 'Error al cargar productos: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SliverFillRemaining(
                child: InfoMessage(
                    icon: Icons.search_off,
                    message: 'No se encontraron productos.'));
          }
          final productos = snapshot.data!;
          return SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: productos.length,
              itemBuilder: (context, index) => ProductCard(
                  producto: productos[index], usuario: widget.usuario),
            ),
          );
        },
      );

  // MEJORA: Se redise�a el carrusel para ser m�s atractivo y robusto.
  Widget _buildRecommendationsCarousel() {
    return FutureBuilder<List<ProductoRankeado>>(
      future: _recommendationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _RecommendationsLoading();
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final recommendations = snapshot.data!;
        if (_currentRecommendationPage >= recommendations.length) {
          _currentRecommendationPage = 0;
        }
        return SizedBox(
          height: 260,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _recommendationsController,
                  onPageChanged: (index) {
                    setState(() => _currentRecommendationPage = index);
                  },
                  itemCount: recommendations.length,
                  itemBuilder: (context, index) {
                    final producto = recommendations[index];
                    final isFocused = index == _currentRecommendationPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      margin: EdgeInsets.symmetric(
                        horizontal: isFocused ? 12 : 20,
                        vertical: isFocused ? 4 : 16,
                      ),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(
                                ((isFocused ? 0.14 : 0.08) * 255).round()),
                            blurRadius: isFocused ? 18 : 10,
                            offset: Offset(0, isFocused ? 10 : 6),
                          ),
                        ],
                      ),
                      child: Transform.scale(
                        scale: isFocused ? 1 : 0.95,
                        child: _buildRecommendationCard(producto),
                      ),
                    );
                  },
                ),
              ),
              if (recommendations.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(recommendations.length, (index) {
                      final isActive = index == _currentRecommendationPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: isActive ? 22 : 10,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withAlpha((0.25 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveTrackingCard() {
    // DESHABILITADO: Card de repartidores en vivo removido para evitar errores
    // TODO: Implementar notificaciones push cuando el pedido est� cerca
    // Para activar notificaciones Gmail API, descomentar la siguiente secci�n:

    /*
    // INFRAESTRUCTURA PARA NOTIFICACIONES (Gmail API)
    // 1. Agregar dependencia en pubspec.yaml: 
    //    googleapis: ^11.0.0
    //    googleapis_auth: ^1.4.1
    
    // 2. Funci�n para enviar notificaci�n:
    Future<void> _sendOrderNearNotification(String userEmail, String orderDetails) async {
      // Configurar Gmail API credentials
      final credentials = /* Tu configuraci�n OAuth2 */;
      
      // Enviar email
      final message = '''
        ?? �Tu pedido est� cerca!
        
        El repartidor llegar� en aproximadamente 5 minutos.
        
        Detalles: $orderDetails
        
        Gracias por usar Speed7Delivery
      ''';
      
      // await gmailApi.send(userEmail, 'Tu pedido est� cerca', message);
    }
    
    // 3. Llamar cuando el repartidor est� a menos de 500m del cliente
    // if (distanceToClient < 0.5) {
    //   _sendOrderNearNotification(cliente.email, pedido.id);
    // }
    */

    return const SizedBox.shrink(); // No mostrar nada por ahora
  }

  Widget _buildRecommendationCard(ProductoRankeado producto) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              producto: producto.toProducto(),
              usuario: widget.usuario,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        margin:
            EdgeInsets.symmetric(horizontal: 4, vertical: AppTheme.spacing1),
        child: AppCard(
          elevation: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: _resolveImageUrl(producto.imagenUrl),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.restaurant,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                        memCacheHeight: 300,
                        maxHeightDiskCache: 600,
                        fadeInDuration: const Duration(milliseconds: 200),
                      ),
                    ),
                    if ((producto.negocio ?? '').isNotEmpty)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316).withAlpha(230),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.store,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 160),
                                child: Text(
                                  producto.negocio!,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: AppTheme.spacing1 / 2),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        SizedBox(width: AppTheme.spacing1 / 2),
                        Text(
                          '${producto.ratingPromedio.toStringAsFixed(1)} (${producto.totalReviews})',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700),
                        ),
                        const Spacer(),
                        if ((producto.precio ?? 0) > 0)
                          Text(
                            '\$${(producto.precio ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // CORRECCI�N: Se permite que roles 'admin' y 'negocio' tambi�n vean la interfaz de cliente.
    final isCliente = widget.usuario.rol == 'cliente' ||
        widget.usuario.rol == 'admin' ||
        widget.usuario.rol == 'negocio';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF97316),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              'assets/images/LOGO DE AP Y WEB.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          'Hola, ${widget.usuario.nombre.split(' ').first}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          Consumer<CartModel>(
            builder: (context, cart, child) => Badge(
              label: Text(cart.items.length.toString()),
              isLabelVisible: cart.items.isNotEmpty,
              child: IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                color: Colors.white,
                onPressed: _handleCartTap,
              ),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF97316),
                Color(0xFFFF6F3C),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
      body: isCliente ? _buildProductosTab() : Container(),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Producto producto;
  final Usuario usuario;

  const ProductCard({required this.producto, required this.usuario, super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context, listen: false);
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ProductDetailScreen(producto: producto, usuario: usuario))),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 12,
                  child: Hero(
                    tag: 'product-${producto.idProducto}',
                    child: _ProductImage(
                      imageUrl: producto.imagenUrl,
                      categoria: producto.categoria,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(AppTheme.spacing1,
                      AppTheme.spacing1, AppTheme.spacing1, 0),
                  child: Text(producto.nombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing1,
                      vertical: AppTheme.spacing1 / 2),
                  child: Text('\$${producto.precio.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
              ],
            ),
            Positioned(
              bottom: AppTheme.spacing1,
              right: AppTheme.spacing1,
              child: ElevatedButton(
                onPressed: !usuario.isAuthenticated
                    ? () => showLoginRequiredDialog(context)
                    : () {
                        HapticFeedback.lightImpact();
                        cart.addToCart(producto);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:
                                Text('${producto.nombre} anadido al carrito.'),
                            backgroundColor: AppTheme.successColor,
                            duration: const Duration(seconds: 1)));
                      },
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: EdgeInsets.all(AppTheme.spacing1 + 2),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: const Icon(Icons.add_shopping_cart,
                    color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  final String? categoria;
  const _ProductImage({this.imageUrl, this.categoria});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _ImagePlaceholder(categoria: categoria);
    }
    return CachedNetworkImage(
      imageUrl: _resolveImageUrl(imageUrl),
      fit: BoxFit.cover,
      placeholder: (context, url) =>
          _ImagePlaceholder(isLoading: true, categoria: categoria),
      errorWidget: (c, url, error) => _ImagePlaceholder(categoria: categoria),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeInCurve: Curves.easeOut,
      memCacheHeight: 400,
      maxHeightDiskCache: 800,
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final bool isLoading;
  final String? categoria;
  const _ImagePlaceholder({this.isLoading = false, this.categoria});

  IconData _getCategoryIcon() {
    if (categoria == null) return Icons.restaurant;
    final cat = categoria!.toLowerCase();
    if (cat.contains('hamburgues')) return Icons.lunch_dining;
    if (cat.contains('pizza')) return Icons.local_pizza;
    if (cat.contains('bebida') || cat.contains('jugo')) {
      return Icons.local_drink;
    }
    if (cat.contains('postre') || cat.contains('helado')) return Icons.cake;
    if (cat.contains('mariscos') || cat.contains('ceviche')) {
      return Icons.set_meal;
    }
    if (cat.contains('pollo')) return Icons.egg_alt;
    if (cat.contains('sushi')) return Icons.restaurant_menu;
    if (cat.contains('café') || cat.contains('cafetería')) return Icons.coffee;
    if (cat.contains('ensalada')) return Icons.emoji_food_beverage;
    return Icons.restaurant;
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: isLoading
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.grey.shade200,
                    Colors.grey.shade100,
                    Colors.grey.shade200,
                  ],
                )
              : null,
          color: isLoading ? null : Colors.grey.shade200,
        ),
        child: Icon(_getCategoryIcon(), color: Colors.grey.shade400, size: 40),
      );
}

class InfoMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  const InfoMessage({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withAlpha(153)),
        const SizedBox(height: 12),
        Text(message,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.grey[600]))
      ]));
}

class ProductsGridLoading extends StatelessWidget {
  const ProductsGridLoading({super.key}); // ignore: unused_element
  @override
  Widget build(BuildContext context) => GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16),
        itemCount: 6,
        itemBuilder: (c, i) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Card(
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
}

class _RecommendationsLoading extends StatelessWidget {
  const _RecommendationsLoading();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: 3,
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 220,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/* DESHABILITADO - Widget no usado después de remover tracking de repartidores
class _LiveMapPlaceholder extends StatelessWidget {
  const _LiveMapPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 8),
              Icon(Icons.delivery_dining,
                  color: Colors.grey.shade500, size: 32),
              const SizedBox(width: 12),
              Text(
                'Cargando mapa�',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
