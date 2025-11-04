import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_state.dart';
import '../models/usuario.dart';
import '../routes/app_routes.dart';
import '../services/database_service.dart';
import 'admin_products_view.dart';
import 'business_products_view.dart';
import 'admin_orders_view.dart';

class AdminHomeScreen extends StatefulWidget {
  final Usuario adminUser;
  const AdminHomeScreen({super.key, required this.adminUser});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    _statsFuture =
        Provider.of<DatabaseService>(context, listen: false).getAdminStats();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1E1E1E), const Color(0xFF252526)]
                : [const Color(0xFFF5F5F5), const Color(0xFFE8E8E8)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // 🎨 AppBar moderno con gradiente
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00D4FF), Color(0xFF0078D4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.asset(
                              'assets/images/LOGO DE AP Y WEB.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.admin_panel_settings,
                                  color: Color(0xFF3B82F6),
                                  size: 32,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Panel de Admin',
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Bienvenido, ${widget.adminUser.nombre}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon:
                        const Icon(Icons.refresh_rounded, color: Colors.white),
                    onPressed: () => setState(() => _loadStats()),
                    tooltip: 'Actualizar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    onPressed: _handleLogout,
                    tooltip: 'Cerrar Sesión',
                  ),
                ],
              ),

              // Contenido
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título de estadísticas
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00D4FF), Color(0xFF0078D4)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.analytics_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Resumen del Día',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Grid de estadísticas
                      FutureBuilder<Map<String, dynamic>>(
                        future: _statsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'Error: ${snapshot.error}',
                                  style: TextStyle(color: Colors.red.shade800),
                                ),
                              ),
                            );
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const _StatsGridLoading();
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                    'No hay estadísticas disponibles.'),
                              ),
                            );
                          }
                          final stats = snapshot.data!;
                          return _StatsGrid(stats: stats);
                        },
                      ),

                      const SizedBox(height: 32),

                      // Título de gestión
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.settings_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Gestión',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Opciones de gestión
                      if (widget.adminUser.rol.trim().toLowerCase() == 'admin')
                        _MenuActionCard(
                          title: 'Mapa Lite (Posiciones)',
                          subtitle:
                              'Clientes (verde) y repartidores (rojo) - vista rápida',
                          icon: Icons.map_outlined,
                          color: const Color(0xFF00BFA5),
                          onTap: () => Navigator.of(context).pushNamed(
                            AppRoutes.adminMapLite,
                            arguments: widget.adminUser,
                          ),
                        ),
                      if (widget.adminUser.rol.trim().toLowerCase() == 'admin')
                        _MenuActionCard(
                          title: 'Gestionar Productos',
                          subtitle: 'Agregar, editar o eliminar productos',
                          icon: Icons.fastfood_outlined,
                          color: const Color(0xFF0078D4),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AdminProductsView()),
                          ),
                        ),
                      if (widget.adminUser.rol.trim().toLowerCase() ==
                          'negocio')
                        _MenuActionCard(
                          title: 'Mis Productos (Negocio)',
                          subtitle: 'Gestiona el catálogo de tu negocio',
                          icon: Icons.store_mall_directory_outlined,
                          color: const Color(0xFF00BFA5),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BusinessProductsView(
                                  negocioUser: widget.adminUser),
                            ),
                          ),
                        ),
                      _MenuActionCard(
                        title: 'Pedidos Pendientes',
                        subtitle: 'Ver y gestionar pedidos en espera',
                        icon: Icons.receipt_long_outlined,
                        color: const Color(0xFFFF6D00),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const AdminOrdersView()),
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
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
            title: 'Ingresos Totales',
            value: '\$${(stats['ingresos_totales'] ?? 0).toStringAsFixed(2)}',
            icon: Icons.attach_money,
            color: Colors.green),
        _StatCard(
            title: 'Pedidos Completados',
            value: (stats['pedidos_completados'] ?? 0).toString(),
            icon: Icons.check_circle_outline,
            color: Colors.blue),
        _StatCard(
            title: 'Nuevos Clientes',
            value: (stats['total_clientes'] ?? 0).toString(),
            icon: Icons.person_add_alt_1_outlined,
            color: Colors.teal),
        _StatCard(
            title: 'Productos Activos',
            value: (stats['total_productos'] ?? 0).toString(),
            icon: Icons.list_alt,
            color: Colors.purple),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(204), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(77),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGridLoading extends StatelessWidget {
  const _StatsGridLoading();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children:
          List.generate(4, (index) => const Card(child: SizedBox.expand())),
    );
  }
}

class _MenuActionCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuActionCard(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        // CORRECCIÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œN: Se usa withAlpha en lugar de withOpacity
        leading: CircleAvatar(
            backgroundColor: color.withAlpha(26),
            child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
