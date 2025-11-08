import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_state.dart';
import '../models/usuario.dart';
import '../routes/app_routes.dart';
import '../services/database_service.dart';
import '../widgets/modern_dashboard_card.dart';
import '../utils/product_name_optimizer.dart';

// Importar vistas existentes
import 'admin_products_view.dart';
import 'business_products_view.dart';
import 'admin_orders_view.dart';

class ModernAdminHomeScreen extends StatefulWidget {
  final Usuario adminUser;
  const ModernAdminHomeScreen({super.key, required this.adminUser});

  @override
  State<ModernAdminHomeScreen> createState() => _ModernAdminHomeScreenState();
}

class _ModernAdminHomeScreenState extends State<ModernAdminHomeScreen>
    with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _statsFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadStats() {
    _statsFuture = Provider.of<DatabaseService>(context, listen: false).getAdminStats();
  }

  Future<void> _handleLogout() async {
    final navigator = Navigator.of(context);
    final session = context.read<SessionController>();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      session.clearUser();
      navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNegocio = widget.adminUser.rol.trim().toLowerCase() == 'negocio';
    final isAdmin = widget.adminUser.rol.trim().toLowerCase() == 'admin';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8F9FA),
              Color(0xFFE9ECEF),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              slivers: [
                // Header moderno
                SliverToBoxAdapter(
                  child: _buildModernHeader(isNegocio),
                ),

                // Dashboard stats
                SliverToBoxAdapter(
                  child: _buildStatsSection(),
                ),

                // Acciones rápidas
                SliverToBoxAdapter(
                  child: _buildQuickActions(isAdmin, isNegocio),
                ),

                // Gestión principal
                SliverToBoxAdapter(
                  child: _buildMainActions(isAdmin, isNegocio),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(bool isNegocio) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isNegocio 
            ? [const Color(0xFF00BFA5), const Color(0xFF00ACC1)]
            : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isNegocio ? const Color(0xFF00BFA5) : const Color(0xFF667EEA)).withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isNegocio ? Icons.store : Icons.admin_panel_settings,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNegocio ? '🏪 Panel de Negocio' : '⚡ Panel de Admin',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bienvenido, ${ProductNameOptimizer.optimizarNombre(widget.adminUser.nombre)} 👋',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isNegocio ? 'Gestiona tu negocio' : 'Control total del sistema',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => setState(() => _loadStats()),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Actualizar',
              ),
              IconButton(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                tooltip: 'Cerrar Sesión',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '📊 Resumen del Día',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<Map<String, dynamic>>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildStatsLoading();
              }
              if (snapshot.hasError) {
                return _buildStatsError(snapshot.error.toString());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildStatsEmpty();
              }
              return _buildStatsGrid(snapshot.data!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        ModernDashboardCard(
          title: 'Ingresos Totales',
          value: ProductNameOptimizer.formatearPrecio(
            (stats['ingresos_totales'] ?? 0).toDouble(),
          ),
          icon: Icons.attach_money_outlined,
          primaryColor: const Color(0xFF4CAF50),
          subtitle: 'Hoy',
        ),
        ModernDashboardCard(
          title: 'Pedidos Completados',
          value: (stats['pedidos_completados'] ?? 0).toString(),
          icon: Icons.check_circle_outline,
          primaryColor: const Color(0xFF2196F3),
          subtitle: 'Exitosos',
        ),
        ModernDashboardCard(
          title: 'Nuevos Clientes',
          value: (stats['total_clientes'] ?? 0).toString(),
          icon: Icons.person_add_alt_1_outlined,
          primaryColor: const Color(0xFF9C27B0),
          subtitle: 'Registrados',
        ),
        ModernDashboardCard(
          title: 'Productos Activos',
          value: (stats['total_productos'] ?? 0).toString(),
          icon: Icons.inventory_2_outlined,
          primaryColor: const Color(0xFFFF9800),
          subtitle: 'En catálogo',
        ),
      ],
    );
  }

  Widget _buildStatsLoading() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: List.generate(
        4,
        (index) => Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsError(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Error al cargar estadísticas: $error',
              style: TextStyle(color: Colors.red.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsEmpty() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey),
          SizedBox(width: 12),
          Text('No hay estadísticas disponibles'),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isAdmin, bool isNegocio) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.flash_on_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '⚡ Acciones Rápidas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ModernActionCard(
                  title: 'Pedidos Pendientes',
                  subtitle: 'Ver pedidos en espera',
                  icon: Icons.pending_actions,
                  color: const Color(0xFFFF9800),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminOrdersView()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (isAdmin)
                Expanded(
                  child: ModernActionCard(
                    title: 'Mapa en Vivo',
                    subtitle: 'Ver ubicaciones',
                    icon: Icons.map_outlined,
                    color: const Color(0xFF4CAF50),
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.adminMapLite,
                      arguments: widget.adminUser,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainActions(bool isAdmin, bool isNegocio) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '🛠️ Gestión Principal',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (isAdmin)
            ModernActionCard(
              title: '🍕 Gestionar Productos',
              subtitle: 'Agregar, editar o eliminar productos del catálogo',
              icon: Icons.restaurant_menu_outlined,
              color: const Color(0xFF2196F3),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminProductsView()),
              ),
            ),
          if (isNegocio)
            ModernActionCard(
              title: '🏪 Mis Productos',
              subtitle: 'Gestiona el catálogo de tu negocio',
              icon: Icons.store_mall_directory_outlined,
              color: const Color(0xFF00BFA5),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BusinessProductsView(negocioUser: widget.adminUser),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
