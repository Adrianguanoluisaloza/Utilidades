// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/producto.dart';
import '../models/usuario.dart';
import '../services/database_service.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';

class BusinessProductsView extends StatefulWidget {
  final Usuario negocioUser;
  const BusinessProductsView({super.key, required this.negocioUser});

  @override
  State<BusinessProductsView> createState() => _BusinessProductsViewState();
}

class _BusinessProductsViewState extends State<BusinessProductsView> {
  late Future<List<Producto>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context
        .read<DatabaseService>()
        .getProductosPorNegocio(widget.negocioUser.idUsuario);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Productos'),
        elevation: 0,
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewProductDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Producto'),
      ),
      body: FutureBuilder<List<Producto>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Error al cargar',
              message: snapshot.error.toString(),
              actionText: 'Reintentar',
              onAction: () => setState(_reload),
            );
          }
          final items = snapshot.data ?? const <Producto>[];
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Sin productos',
              message: 'Aún no has agregado productos a tu catálogo.',
              actionText: 'Agregar Producto',
              onAction: _showNewProductDialog,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final p = items[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  onTap: () => _showEditProductDialog(p),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (p.imagenUrl != null && p.imagenUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                p.imagenUrl!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.fastfood,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.fastfood,
                                size: 40,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.nombre,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (p.descripcion != null &&
                                    p.descripcion!.isNotEmpty)
                                  Text(
                                    p.descripcion!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '\$${p.precio.toStringAsFixed(2)}',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (p.stock != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: p.stock! > 10
                                              ? theme
                                                  .colorScheme.tertiaryContainer
                                              : theme
                                                  .colorScheme.errorContainer,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Stock: ${p.stock}',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: p.stock! > 10
                                                ? theme.colorScheme
                                                    .onTertiaryContainer
                                                : theme.colorScheme
                                                    .onErrorContainer,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showEditProductDialog(p),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Editar'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _confirmDelete(p),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Eliminar'),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showNewProductDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '0');
    final descCtrl = TextEditingController();
    final imagenCtrl = TextEditingController();
    final categoriaCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Producto'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.fastfood),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'El nombre es obligatorio'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Precio *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'El precio es obligatorio';
                    }
                    final precio = double.tryParse(v.trim());
                    if (precio == null || precio <= 0) {
                      return 'Ingresa un precio válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: stockCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Stock Inicial',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      final stock = int.tryParse(v.trim());
                      if (stock == null || stock < 0) {
                        return 'Ingresa un stock válido';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: imagenCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL de Imagen',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.image),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: categoriaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Crear Producto'),
          ),
        ],
      ),
    );

    if (result != true) {
      return;
    }

    final nombre = nameCtrl.text.trim();
    final precio = double.tryParse(priceCtrl.text.trim()) ?? 0;
    final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;

    final nuevo = Producto(
      idProducto: 0,
      nombre: nombre,
      precio: precio,
      stock: stock,
      descripcion: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
      imagenUrl: imagenCtrl.text.trim().isEmpty ? null : imagenCtrl.text.trim(),
      categoria:
          categoriaCtrl.text.trim().isEmpty ? null : categoriaCtrl.text.trim(),
      disponible: true,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    if (!context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final databaseService = context.read<DatabaseService>();

    databaseService
        .createProductoParaNegocio(widget.negocioUser.idUsuario, nuevo)
        .then((created) {
      if (!context.mounted) {
        return;
      }
      if (navigator.mounted) {
        navigator.pop();
      }
      setState(_reload);
      messenger.showSnackBar(
        SnackBar(
          content: Text(created != null
              ? 'Producto creado'
              : 'No se pudo crear el producto'),
          backgroundColor: created != null ? Colors.green : Colors.red,
        ),
      );
    }).catchError((error, _) {
      if (!context.mounted) {
        return;
      }
      if (navigator.mounted) {
        navigator.pop();
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al crear producto: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  Future<void> _showEditProductDialog(Producto p) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: p.nombre);
    final priceCtrl = TextEditingController(text: p.precio.toStringAsFixed(2));
    final stockCtrl = TextEditingController(text: (p.stock ?? 0).toString());
    final descCtrl = TextEditingController(text: p.descripcion ?? '');
    final imagenCtrl = TextEditingController(text: p.imagenUrl ?? '');
    final categoriaCtrl = TextEditingController(text: p.categoria ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Producto'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.fastfood),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'El nombre es obligatorio'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Precio *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'El precio es obligatorio';
                    }
                    final precio = double.tryParse(v.trim());
                    if (precio == null || precio <= 0) {
                      return 'Ingresa un precio válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: stockCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Stock',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory_2),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      final stock = int.tryParse(v.trim());
                      if (stock == null || stock < 0) {
                        return 'Ingresa un stock válido';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: imagenCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL de Imagen',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.image),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: categoriaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Guardar Cambios'),
          ),
        ],
      ),
    );
    if (result != true) {
      return;
    }

    final updated = Producto(
      idProducto: p.idProducto,
      nombre: nameCtrl.text.trim().isEmpty ? p.nombre : nameCtrl.text.trim(),
      precio: double.tryParse(priceCtrl.text.trim()) ?? p.precio,
      stock: int.tryParse(stockCtrl.text.trim()) ?? p.stock ?? 0,
      descripcion: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
      imagenUrl: imagenCtrl.text.trim().isEmpty ? null : imagenCtrl.text.trim(),
      categoria:
          categoriaCtrl.text.trim().isEmpty ? null : categoriaCtrl.text.trim(),
      disponible: p.disponible,
      idNegocio: p.idNegocio,
      idCategoria: p.idCategoria,
      fechaCreacion: p.fechaCreacion,
    );

    if (!mounted) {
      return;
    }
    final db2 = context.read<DatabaseService>();
    await db2.updateProducto(updated);
    if (!mounted) {
      return;
    }
    setState(_reload);
  }

  Future<void> _confirmDelete(Producto p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('Eliminar "${p.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (!mounted) {
        return; // Asegura que el widget sigue montado antes de usar el contexto
      }
      final db3 = context.read<DatabaseService>();
      await db3.deleteProducto(p.idProducto);
      if (!mounted) {
        return;
      }
      setState(_reload);
    }
  }
}
