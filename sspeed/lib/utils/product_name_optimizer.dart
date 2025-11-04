/// Utilidades para optimizar nombres y descripciones de productos
class ProductNameOptimizer {
  
  /// Optimiza el nombre de un producto agregando emojis y mejorando la presentación
  static String optimizarNombre(String nombre) {
    final nombreLimpio = nombre.trim();
    
    // Mapeo de nombres específicos mejorados
    final nombresOptimizados = {
      'Pizza Margarita': '🍕 Pizza Margarita Artesanal',
      'Maki Acevichado': '🍣 Maki Acevichado Premium',
      'Latte Andino': '☕ Latte Andino Especial',
      'Burger Station Clásica': '🍔 Burger Clásica Gourmet',
      'Burger Clasica': '🍔 Burger Clásica Gourmet',
      'Latte': '☕ Latte Cremoso',
      'Pizza': '🍕 Pizza Artesanal',
      'Maki': '🍣 Maki Premium',
      'Burger': '🍔 Burger Gourmet',
      'Hamburguesa': '🍔 Hamburguesa Gourmet',
      'Café': '☕ Café Premium',
      'Coffee': '☕ Coffee Especial',
    };
    
    // Buscar coincidencia exacta primero
    if (nombresOptimizados.containsKey(nombreLimpio)) {
      return nombresOptimizados[nombreLimpio]!;
    }
    
    // Buscar coincidencias parciales
    for (final entry in nombresOptimizados.entries) {
      if (nombreLimpio.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    
    // Si no hay coincidencia, agregar emoji según categoría
    final nombreLower = nombreLimpio.toLowerCase();
    
    // Categorías principales
    if (nombreLower.contains('pizza')) return '🍕 $nombreLimpio';
    if (nombreLower.contains('burger') || nombreLower.contains('hamburguesa')) return '🍔 $nombreLimpio';
    if (nombreLower.contains('maki') || nombreLower.contains('sushi') || nombreLower.contains('roll')) return '🍣 $nombreLimpio';
    if (nombreLower.contains('latte') || nombreLower.contains('café') || nombreLower.contains('coffee') || nombreLower.contains('cappuccino')) return '☕ $nombreLimpio';
    
    // Categorías secundarias
    if (nombreLower.contains('bebida') || nombreLower.contains('jugo') || nombreLower.contains('refresco')) return '🥤 $nombreLimpio';
    if (nombreLower.contains('postre') || nombreLower.contains('helado') || nombreLower.contains('torta')) return '🍰 $nombreLimpio';
    if (nombreLower.contains('ensalada') || nombreLower.contains('salad')) return '🥗 $nombreLimpio';
    if (nombreLower.contains('pasta') || nombreLower.contains('spaghetti')) return '🍝 $nombreLimpio';
    if (nombreLower.contains('pollo') || nombreLower.contains('chicken')) return '🍗 $nombreLimpio';
    if (nombreLower.contains('pescado') || nombreLower.contains('fish') || nombreLower.contains('salmón')) return '🐟 $nombreLimpio';
    if (nombreLower.contains('carne') || nombreLower.contains('beef') || nombreLower.contains('steak')) return '🥩 $nombreLimpio';
    if (nombreLower.contains('taco') || nombreLower.contains('burrito')) return '🌮 $nombreLimpio';
    if (nombreLower.contains('sandwich') || nombreLower.contains('sándwich')) return '🥪 $nombreLimpio';
    if (nombreLower.contains('hot dog') || nombreLower.contains('hotdog')) return '🌭 $nombreLimpio';
    if (nombreLower.contains('sopa') || nombreLower.contains('soup')) return '🍲 $nombreLimpio';
    if (nombreLower.contains('arroz') || nombreLower.contains('rice')) return '🍚 $nombreLimpio';
    if (nombreLower.contains('pan') || nombreLower.contains('bread')) return '🍞 $nombreLimpio';
    
    // Emoji genérico para comida
    return '🍽️ $nombreLimpio';
  }

  /// Optimiza la descripción de un producto
  static String optimizarDescripcion(String? descripcion) {
    if (descripcion == null || descripcion.trim().isEmpty) {
      return 'Delicioso platillo preparado con ingredientes frescos y de calidad';
    }
    
    final desc = descripcion.trim();
    
    // Descripciones específicas mejoradas
    final descripcionesOptimizadas = {
      'Masa madre, mozzarella y albahaca fresca': 'Auténtica pizza italiana con masa madre artesanal, mozzarella fresca y albahaca del huerto 🌿',
      'Relleno de pescado blanco, salsa acevichada': 'Exquisito maki con pescado blanco fresco y nuestra exclusiva salsa acevichada 🐟',
      'Espresso con leche vaporizada y canela': 'Cremoso latte con espresso premium, leche vaporizada y un toque de canela aromática ☕',
      'Carne angus, queso cheddar, tocino y salsa especial': 'Jugosa burger con carne Angus premium, queso cheddar derretido, tocino crujiente y salsa secreta 🥓',
    };
    
    // Buscar descripción optimizada
    if (descripcionesOptimizadas.containsKey(desc)) {
      return descripcionesOptimizadas[desc]!;
    }
    
    // Si la descripción es muy corta, mejorarla
    if (desc.length < 20) {
      return '$desc - Preparado con ingredientes frescos y de calidad';
    }
    
    return desc;
  }

  /// Obtiene el emoji apropiado para una categoría
  static String getEmojiForCategory(String? categoria) {
    if (categoria == null || categoria.trim().isEmpty) {
      return '🍽️';
    }
    
    final cat = categoria.toLowerCase().trim();
    
    final emojiMap = {
      'pizzas': '🍕',
      'pizza': '🍕',
      'hamburguesas': '🍔',
      'burger': '🍔',
      'burgers': '🍔',
      'makis': '🍣',
      'maki': '🍣',
      'sushi': '🍣',
      'bebidas': '☕',
      'bebida': '☕',
      'café': '☕',
      'coffee': '☕',
      'postres': '🍰',
      'postre': '🍰',
      'ensaladas': '🥗',
      'ensalada': '🥗',
      'pasta': '🍝',
      'pastas': '🍝',
      'pollo': '🍗',
      'chicken': '🍗',
      'pescado': '🐟',
      'fish': '🐟',
      'carne': '🥩',
      'beef': '🥩',
      'tacos': '🌮',
      'taco': '🌮',
      'mexican': '🌮',
      'mexicana': '🌮',
    };
    
    return emojiMap[cat] ?? '🍽️';
  }

  /// Formatea el precio de manera atractiva
  static String formatearPrecio(double precio) {
    if (precio == precio.roundToDouble()) {
      return '\$${precio.round()}';
    }
    return '\$${precio.toStringAsFixed(2)}';
  }
}
