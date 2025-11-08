import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../services/database_service.dart';
import '../utils/product_name_optimizer.dart';
import 'package:provider/provider.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  late Future<List<Producto>> _productosFuture;

  @override
  void initState() {
    super.initState();
    // ¡CAMBIO CLAVE!
    // Obtenemos la instancia de DatabaseService del Provider.
    // listen: false es importante en initState.
    _productosFuture = Provider.of<DatabaseService>(context, listen: false).getProductos(query: '', categoria: '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú de Productos'),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: FutureBuilder<List<Producto>>(
          future: _productosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              debugPrint('Error al cargar productos: ${snapshot.error}');
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Error al cargar productos. Revisa la conexión a Neon y las credenciales.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              );
            }
            final productos = snapshot.data ?? [];
            if (productos.isEmpty) {
              return const Center(
                child: Text('No hay productos disponibles.'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8.0),
              itemCount: productos.length,
              itemBuilder: (context, index) {
                final producto = productos[index];
                return _ProductCard(producto: producto);
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Producto producto;
  const _ProductCard({required this.producto});



  @override
  Widget build(BuildContext context) {
    final imageUrl = (producto.imagenUrl ?? '').trim();
    final nombreOptimizado = ProductNameOptimizer.optimizarNombre(producto.nombre);
    final descripcionOptimizada = ProductNameOptimizer.optimizarDescripcion(producto.descripcion);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.blue.shade50,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✨ Seleccionaste: $nombreOptimizado'),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Imagen del producto
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade100,
                        Colors.orange.shade200,
                      ],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.isNotEmpty && !imageUrl.contains('example.com')
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.restaurant_menu,
                                color: Colors.orange.shade700,
                                size: 32,
                              );
                            },
                          )
                        : Icon(
                            Icons.restaurant_menu,
                            color: Colors.orange.shade700,
                            size: 32,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Información del producto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombreOptimizado,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        descripcionOptimizada,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Precio
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade500,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withAlpha(77),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '\$${producto.precio.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
