import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'usuario.dart';

/// Controlador para manejar el estado de sesión con persistencia
class SessionController extends ChangeNotifier {
  Usuario? _usuario;
  bool _isLoading = false;

  Usuario? get usuario => _usuario;
  bool get isAuthenticated => _usuario != null && _usuario!.idUsuario > 0;
  bool get isLoading => _isLoading;

  // Cargar sesión guardada al iniciar la app
  Future<void> loadSession() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      
      if (userData != null) {
        final userMap = jsonDecode(userData) as Map<String, dynamic>;
        _usuario = Usuario.fromJson(userMap);
      }
    } catch (e) {
      if (kDebugMode) print('Error cargando sesión: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Guardar usuario y persistir sesión
  Future<void> setUser(Usuario usuario) async {
    _usuario = usuario;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(usuario.toJson()));
    } catch (e) {
      if (kDebugMode) print('Error guardando sesión: $e');
    }
  }

  // Limpiar sesión y datos guardados
  Future<void> clearUser() async {
    _usuario = null;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
    } catch (e) {
      if (kDebugMode) print('Error limpiando sesión: $e');
    }
  }
}
