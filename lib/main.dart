import 'package:flutter/material.dart'; // Importa la biblioteca de Flutter para construir la interfaz de usuario.
      import 'screens/login_screen.dart'; // Importa la pantalla de inicio de sesión.
      import 'screens/registro_screen.dart'; // Importa la pantalla de registro.

      void main() {
        runApp(const MyApp()); // Ejecuta la aplicación MyApp.
      }

      class MyApp extends StatelessWidget {
        const MyApp({super.key}); // Constructor de la clase MyApp.

        @override
        Widget build(BuildContext context) {
          return MaterialApp(
            debugShowCheckedModeBanner: false, // Desactiva la etiqueta de modo debug.
            initialRoute: '/', // Establece la ruta inicial de la aplicación.
            routes: {
              '/': (context) => const LoginScreen(), // Define la ruta para la pantalla de inicio de sesión.
              '/registro': (context) => const RegistroScreen(), // Define la ruta para la pantalla de registro.
            },
          );
        }
      }