import 'package:flutter/material.dart';

/// Clase centralizada para gestionar el tema visual de la aplicación.
///
/// Define colores, tipografías y estilos de widgets de forma consistente
/// en toda la app.
class AppTheme {
  // Hacemos el constructor privado para que no se pueda instanciar la clase.
  AppTheme._();

  // --- PALETA DE COLORES PRINCIPAL ---
  // Alineado con la web: Primario azul y secundario naranja
  static const Color primaryColor = Color(0xFF1E3A8A); // Azul Oscuro (brand)
  static const Color accentColor = Color(0xFFF97316); // Naranja (brand)
  static const Color backgroundColor =
      Color(0xFFF5F5F5); // Fondo gris claro para resaltar contenido

  // --- COLORES SEMÁNTICOS ---
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);

  // --- SISTEMA DE BORDES ---
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;

  // --- SISTEMA DE ESPACIADO ---
  static const double spacing1 = 8.0;
  static const double spacing2 = 16.0;
  static const double spacing3 = 24.0;
  static const double spacing4 = 32.0;

  // --- SOMBRAS PREDEFINIDAS ---
  static List<BoxShadow> get shadowSmall => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowLarge => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  /// Devuelve el ThemeData principal de la aplicación.
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',

      // --- ESQUEMA DE COLORES GLOBAL ---
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        surface: backgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        error: Colors.red.shade700,
        onError: Colors.white,
      ),

      // --- COLORES DE LA UI ---
      scaffoldBackgroundColor: Color(0xFFF5F5F5), // Gris claro

      // --- ESTILOS DE WIDGETS PRINCIPALES ---

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor:
            accentColor, // Cambiado a naranja como color predominante
        foregroundColor: Colors.white,
        elevation: 0, // Sin elevación
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        // MEJORA: Se añade un FlexibleSpaceBar para crear un degradado naranja-azul
        // con predominio del naranja en el AppBar
        surfaceTintColor: Colors.transparent,
      ),

      // Botones Elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMedium)),
          textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),

      // Botones Outlined
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMedium)),
        ),
      ),

      // Tarjetas
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge)),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),

      // Campos de Texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50, // Fondo muy sutil para campos de texto
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return primaryColor;
          if (states.contains(WidgetState.error)) return errorColor;
          return Colors.grey.shade600;
        }),
        labelStyle: TextStyle(color: Colors.grey.shade700),
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),

      // Chips (filtros de categorías)
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: primaryColor,
        secondarySelectedColor: primaryColor,
        labelStyle:
            const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
        secondaryLabelStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXLarge)),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 1,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        contentTextStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}
