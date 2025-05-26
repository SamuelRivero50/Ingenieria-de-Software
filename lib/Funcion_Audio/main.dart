import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../WidgetBarra.dart';
import 'cv_generator.dart';

// Constante para la API key
const String ASSEMBLY_API_KEY = '127d118f76c446a0ad8dce63a120336d';
const int MAX_MONTHLY_TRANSCRIPTIONS = 25000; // ~416 horas = 25,000 minutos
const double COST_PER_MINUTE = 0.002; // $0.12 por hora = $0.002 por minuto

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Error cargando archivo .env: $e');
  }

  // Obtener las credenciales de Supabase desde las variables de entorno
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception(
      'Las variables de entorno SUPABASE_URL y SUPABASE_ANON_KEY son requeridas',
    );
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AppSelectionScreen(),
    ),
  );
}

final supabase = Supabase.instance.client;

class AppSelectionScreen extends StatelessWidget {
  const AppSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: 'Herramientas Disponibles'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tarjeta para el generador de CV
            _buildSelectionCard(
              context,
              title: 'Generador de Hojas de Vida',
              description: 'Crea tu CV paso a paso usando audio',
              iconData: Icons.description,
              color: Color(0xFF4B9EFA),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CVGenerator()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData iconData,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(20),
          width: double.infinity,
          child: Column(
            children: [
              Icon(iconData, size: 60, color: color),
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
