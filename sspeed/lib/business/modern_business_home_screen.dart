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
import '../admin/business_products_view.dart';
import '../admin/admin_orders_view.dart';

class ModernBusinessHomeScreen extends StatefulWidget {
  final Usuario businessUser;
  const ModernBusinessHomeScreen({super.key, required this.businessUser});

  @override
  State<ModernBusinessHomeScreen> createState() => _ModernBusinessHomeScreenState();
}

class _ModernBusinessHomeScreenState extends State<ModernBusinessHomeScreen>
    with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _statsFuture;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadStats() {
    _statsFuture = Provider.of<DatabaseService>(context, listen: false)
        .getNegocioStats(widget.businessUser.idUsuario);
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0F8FF), Color(0xFFE6F3FF)],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildBusinessHeader()),
                    SliverToBoxAdapter(child: _buildBusinessStats()),
                    SliverToBoxAdapter(child: _buildMainActions()),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00BFA5), Color(0xFF00ACC1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BFA5).withAlpha(102),
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
            child: const Icon(Icons.store, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏪 Mi Negocio',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ProductNameOptimizer.optimizarNombre(widget.businessUser.nombre),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const SizedBox.shrink();
          }
          final stats = snapshot.data!;
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              ModernDashboardCard(
                title: 'Ventas Hoy',
                value: ProductNameOptimizer.formatearPrecio((stats['ventas_hoy'] ?? 0).toDouble()),
                icon: Icons.monetization_on_outlined,
                primaryColor: const Color(0xFF4CAF50),
              ),
              ModernDashboardCard(
                title: 'Pedidos',
                value: (stats['pedidos_hoy'] ?? 0).toString(),
                icon: Icons.shopping_bag_outlined,
                primaryColor: const Color(0xFF2196F3),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainActions() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          ModernActionCard(
            title: '🍕 Mis Productos',
            subtitle: 'Gestiona tu catálogo',
            icon: Icons.restaurant_menu_outlined,
            color: const Color(0xFF00BFA5),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BusinessProductsView(negocioUser: widget.businessUser),
              ),
            ),
          ),
          ModernActionCard(
            title: '📋 Pedidos',
            subtitle: 'Ver pedidos recibidos',
            icon: Icons.receipt_long_outlined,
            color: const Color(0xFF2196F3),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminOrdersView()),
            ),
          ),
        ],
      ),
    );
  }
}
