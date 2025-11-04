import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_state.dart';
import '../models/usuario.dart';
import '../routes/app_routes.dart';
import '../widgets/modern_dashboard_card.dart';
import '../utils/product_name_optimizer.dart';

// Importar vistas existentes
import 'delivery_activeorders_view.dart';
import 'delivery_availableorders_view.dart';
import 'delivery_history_orders_view.dart';
import 'delivery_chat_hub_view.dart';
import 'delivery_stats_view.dart';

class ModernDeliveryHomeScreen extends StatefulWidget {
  final Usuario deliveryUser;
  const ModernDeliveryHomeScreen({super.key, required this.deliveryUser});

  @override
  State<ModernDeliveryHomeScreen> createState() =>
      _ModernDeliveryHomeScreenState();
}

class _ModernDeliveryHomeScreenState extends State<ModernDeliveryHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _availableOrdersCount = 0;
  final int _activeOrdersCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onAvailableOrdersChanged(int count) {
    if (mounted && _availableOrdersCount != count) {
      setState(() => _availableOrdersCount = count);
    }
  }

  Future<void> _handleLogout() async {
    final navigator = Navigator.of(context);
    final sessionController = context.read<SessionController>();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      sessionController.clearUser();
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
            colors: [
              Color(0xFFF8F9FA),
              Color(0xFFE9ECEF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header moderno
              _buildModernHeader(),

              // Dashboard cards
              _buildDashboardCards(),

              // Tabs content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Tab bar moderno
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          indicator: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey.shade600,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          tabs: [
                            _buildModernTab(
                              '🎯 Disponibles',
                              Icons.list_alt,
                              _availableOrdersCount,
                            ),
                            _buildModernTab(
                              '🚚 En Curso',
                              Icons.delivery_dining,
                              _activeOrdersCount,
                            ),
                            _buildModernTab(
                              '📋 Historial',
                              Icons.history,
                              0,
                            ),
                            _buildModernTab(
                              '💬 Chat',
                              Icons.chat_bubble_outline,
                              0,
                            ),
                            _buildModernTab(
                              '📊 Stats',
                              Icons.analytics_outlined,
                              0,
                            ),
                          ],
                        ),
                      ),

                      // Tab content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            DeliveryAvailableOrdersView(
                              deliveryUser: widget.deliveryUser,
                              onOrderCountChanged: _onAvailableOrdersChanged,
                            ),
                            DeliveryActiveOrdersView(
                              deliveryUser: widget.deliveryUser,
                            ),
                            DeliveryHistoryOrdersView(
                              deliveryUser: widget.deliveryUser,
                            ),
                            DeliveryChatHubView(
                              deliveryUser: widget.deliveryUser,
                            ),
                            DeliveryStatsView(
                              deliveryUser: widget.deliveryUser,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.delivery_dining,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🚚 Panel de Delivery',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Hola, ${ProductNameOptimizer.optimizarNombre(widget.deliveryUser.nombre)} 👋',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCards() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ModernDashboardCard(
              title: 'Pedidos Disponibles',
              value: _availableOrdersCount.toString(),
              icon: Icons.assignment_outlined,
              primaryColor: const Color(0xFF4CAF50),
              onTap: () => _tabController.animateTo(0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ModernDashboardCard(
              title: 'En Curso',
              value: _activeOrdersCount.toString(),
              icon: Icons.local_shipping_outlined,
              primaryColor: const Color(0xFF2196F3),
              onTap: () => _tabController.animateTo(1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ModernDashboardCard(
              title: 'Estado',
              value: 'Activo',
              icon: Icons.check_circle_outline,
              primaryColor: const Color(0xFF9C27B0),
              subtitle: 'En línea',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTab(String text, IconData icon, int count) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: badges.Badge(
          showBadge: count > 0,
          badgeContent: Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          position: badges.BadgePosition.topEnd(top: -8, end: -8),
          badgeStyle: badges.BadgeStyle(
            badgeColor: const Color(0xFFFF5722),
            elevation: 0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 6),
              Text(
                text,
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
