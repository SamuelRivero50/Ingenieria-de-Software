import 'package:flutter/material.dart';
import 'package:scanner_personal/Perfil_Cv/perfill.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:scanner_personal/Login/screens/auth_router.dart';
import 'package:scanner_personal/Login/screens/change_password_screen.dart';
import 'package:scanner_personal/Login/screens/login_screen.dart';
import 'package:scanner_personal/Login/screens/registro_screen.dart';
import 'package:scanner_personal/Home/home.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Configuracion/mainConfig.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno con mejor manejo de errores
  String? supabaseUrl;
  String? supabaseAnonKey;

  try {
    print('🔄 Cargando variables de entorno...');
    await dotenv.load(fileName: ".env");
    supabaseUrl = dotenv.env['SUPABASE_URL'];
    supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    print('✅ Variables de entorno cargadas');
    print('📡 URL: ${supabaseUrl?.substring(0, 20)}...');
    print('🔑 Key: ${supabaseAnonKey?.substring(0, 20)}...');
  } catch (e) {
    print('⚠️ Error cargando archivo .env: $e');
    print('🔄 Usando credenciales hardcodeadas como fallback...');

    // Fallback a credenciales hardcodeadas si .env falla
    supabaseUrl = 'https://zpprbzujtziokfyyhlfa.supabase.co';
    supabaseAnonKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpwcHJienVqdHppb2tmeXlobGZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA3ODAyNzgsImV4cCI6MjA1NjM1NjI3OH0.cVRK3Ffrkjk7M4peHsiPPpv_cmXwpX859Ii49hohSLk';
  }

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception(
      'Error: No se pudieron cargar las credenciales de Supabase',
    );
  }

  try {
    print('🚀 Inicializando Supabase...');
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    print('✅ Supabase inicializado correctamente');
  } catch (e) {
    print('❌ Error inicializando Supabase: $e');
    throw Exception('Error inicializando Supabase: $e');
  }

  print('🎯 Iniciando aplicación...');
  runApp(MyApp());
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (_) => const AuthRouter(),
        '/login': (_) => const LoginScreen(),
        '/registro': (_) => RegistroScreen(),
        '/home': (_) => HomeScreen(),
        '/change-password': (_) => CambiarPasswordScreen(),
        '/perfil': (_) => ProfileScreen(),
      },
      onGenerateRoute: (settings) {
        print('🔀 Navegando a: ${settings.name}');
        return null; // Usar las rutas por defecto
      },
    );
  }
}
