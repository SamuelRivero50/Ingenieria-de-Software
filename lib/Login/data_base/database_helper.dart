import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  final Logger _logger = Logger();
  final SupabaseClient _supabase = Supabase.instance.client;

  DatabaseHelper._init();

  /// **Obtener usuario por email desde Supabase**
  Future<Map<String, dynamic>?> obtenerUsuarioPorEmail(String email) async {
    try {
      final response =
          await _supabase
              .from('usuarios')
              .select()
              .eq('correo', email)
              .maybeSingle();

      return response;
    } catch (e) {
      _logger.e("Error obteniendo usuario por email: $e");
      return null;
    }
  }

  /// **Registrar usuario usando Supabase Auth**
  Future<bool> registrarUsuario(
    String nombre,
    String apellido,
    String correo,
    String password,
  ) async {
    try {
      // Verificar si el usuario ya existe
      final existingUser = await obtenerUsuarioPorEmail(correo);
      if (existingUser != null) {
        _logger.w("Usuario ya existe con el correo: $correo");
        return false;
      }

      // Registrar en Supabase Auth
      final authResponse = await _supabase.auth.signUp(
        email: correo,
        password: password,
        data: {'nombre': nombre, 'apellido': apellido},
      );

      if (authResponse.user != null) {
        // Insertar datos adicionales en la tabla usuarios
        try {
          await _supabase.from('usuarios').insert({
            'id': authResponse.user!.id,
            'nombre_usuario': nombre,
            'apellido_usuario': apellido,
            'correo': correo,
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          _logger.w("Error insertando datos adicionales del usuario: $e");
          // Continúa porque el usuario ya está registrado en Auth
        }

        _logger.i(
          "Usuario registrado exitosamente: ${authResponse.user!.email}",
        );
        return true;
      } else {
        _logger.w("Registro fallido - respuesta de auth vacía");
        return false;
      }
    } catch (e) {
      _logger.e("Error en registro: $e");
      return false;
    }
  }

  /// **Iniciar sesión con Supabase Auth**
  Future<bool> iniciarSesion(String correo, String password) async {
    try {
      final authResponse = await _supabase.auth.signInWithPassword(
        email: correo,
        password: password,
      );

      if (authResponse.session != null && authResponse.user != null) {
        _logger.i(
          "Usuario autenticado exitosamente: ${authResponse.user!.email}",
        );
        return true;
      } else {
        _logger.w("Credenciales incorrectas o sesión no creada");
        return false;
      }
    } catch (e) {
      _logger.e("Error en inicio de sesión: $e");
      return false;
    }
  }

  /// **Cerrar sesión**
  Future<void> cerrarSesion() async {
    try {
      // Cierra sesión en Supabase
      await _supabase.auth.signOut();

      // Limpia SharedPreferences solo para datos no críticos
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('usuario_actual');
      await prefs.remove('ultima_conexion');

      _logger.i("Sesión cerrada exitosamente");
    } catch (e) {
      _logger.e("Error al cerrar sesión: $e");
    }
  }

  /// **Obtener usuario autenticado actual**
  Future<Map<String, dynamic>?> obtenerUsuarioActual() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user != null) {
        // Obtener información adicional de la base de datos
        final userData = await obtenerUsuarioPorEmail(user.email!);

        return {
          'id': user.id,
          'email': user.email,
          'nombre':
              userData?['nombre_usuario'] ?? user.userMetadata?['nombre'] ?? '',
          'apellido':
              userData?['apellido_usuario'] ??
              user.userMetadata?['apellido'] ??
              '',
          'created_at': user.createdAt,
          'last_sign_in': user.lastSignInAt,
        };
      }
      return null;
    } catch (e) {
      _logger.e("Error obteniendo usuario actual: $e");
      return null;
    }
  }

  /// **Verificar si hay una sesión activa**
  bool tieneSessionActiva() {
    return _supabase.auth.currentSession != null;
  }

  /// **Recuperar contraseña**
  Future<bool> recuperarPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://scanner-6c414.web.app/#/change-password',
      );
      _logger.i("Email de recuperación enviado a: $email");
      return true;
    } catch (e) {
      _logger.e("Error enviando email de recuperación: $e");
      return false;
    }
  }

  /// **Cambiar contraseña**
  Future<bool> cambiarPassword(String nuevaPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: nuevaPassword));
      _logger.i("Contraseña actualizada exitosamente");
      return true;
    } catch (e) {
      _logger.e("Error actualizando contraseña: $e");
      return false;
    }
  }

  /// **Guardar sesión en SharedPreferences (solo para recordar ultimo usuario)**
  Future<void> guardarSesion(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario_actual', email);
    await prefs.setString('ultima_conexion', DateTime.now().toIso8601String());
  }
}
