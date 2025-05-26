import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5fa),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo o icono de la aplicación
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF090467),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.scanner, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 32),
            Text(
              'Scanner Personal',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF090467),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Inicializando aplicación...',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF090467)),
            ),
            const SizedBox(height: 16),
            Text(
              'Cargando...',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
