import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../screen/chat_screen.dart';
import '../screen/live_map_screen.dart';
import '../screen/negocio_home_screen.dart';
import '../screen/profile_screen.dart';
import 'home_screen.dart';

class MainNavigator extends StatefulWidget {
  final Usuario usuario;
  const MainNavigator({super.key, required this.usuario});

  @override
  State<MainNavigator> createState() => MainNavigatorState();
}

class MainNavigatorState extends State<MainNavigator> {
  int selectedIndex = 0;
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      HomeScreen(usuario: widget.usuario),
      const LiveMapScreen(),
      ProfileScreen(usuario: widget.usuario),
    ];
  }

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNegocio = widget.usuario.rol == 'negocio';

    return Scaffold(
      // Sin AppBar aquí - cada pantalla maneja su propio AppBar
      body: Stack(
        children: [
          IndexedStack(
            index: selectedIndex,
            children: _widgetOptions,
          ),

          // Botón de Soporte eliminado de la vista de Productos (Home)
          // Motivo: Evitar ruido visual y centralizar soporte desde Perfil/ayuda.

          // Botón del chatbot CIA (solo en la pestaña Home)
          if (selectedIndex == 0)
            Positioned(
              bottom: 32,
              right: 24,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white, // Fondo blanco
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: const Color(0xFF3B82F6), // Borde azul
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withAlpha(51),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(32),
                      hoverColor: const Color(0xFF3B82F6).withAlpha(26),
                      splashColor: const Color(0xFF3B82F6).withAlpha(51),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => FractionallySizedBox(
                            heightFactor: 0.92,
                            child: ChatScreen(
                                currentUser: widget.usuario,
                                initialSection: ChatSection.ciaBot),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/logo_de_Chat_bot_movimiento_pagina-removebg-preview.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.smart_toy,
                                size: 32,
                                color: Color(0xFF3B82F6),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Botón "Ver Estadísticas" para usuarios de negocio (solo en Home)
          if (selectedIndex == 0 && isNegocio)
            Positioned(
              bottom: 100, // Por encima del botón del chatbot
              right: 24,
              child: FloatingActionButton.extended(
                heroTag: 'negocioStats',
                backgroundColor: theme.colorScheme.secondary,
                icon: const Icon(Icons.bar_chart, color: Colors.white),
                label: const Text(
                  'Estadísticas',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  // Importar la pantalla directamente para usar Navigator.push
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NegocioHomeScreen(
                        negocioUser: widget.usuario,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      // SE APLICA EL REDISEÑO VISUAL A LA BARRA DE NAVEGACIÓN
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -5), // Sombra hacia arriba
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.shop),
              label: 'Productos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Mapa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
          currentIndex: selectedIndex,
          onTap: onItemTapped,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          showUnselectedLabels: true,
        ),
      ),
    );
  }
}
