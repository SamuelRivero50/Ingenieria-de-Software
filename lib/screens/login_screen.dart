import 'package:flutter/material.dart'; // Importa la biblioteca de Flutter para construir la interfaz de usuario.
  import '../data_base/database_helper.dart'; // Importa el helper de la base de datos para manejar operaciones de base de datos.

  class LoginScreen extends StatefulWidget { // Define un widget con estado para la pantalla de inicio de sesión.
    const LoginScreen({super.key}); // Constructor de la clase LoginScreen.

    @override
    LoginScreenState createState() => LoginScreenState(); // Crea el estado asociado a este widget.
  }

  class LoginScreenState extends State<LoginScreen> { // Define el estado para la pantalla de inicio de sesión.
    final _formKey = GlobalKey<FormState>(); // Clave global para identificar el formulario y validar su estado.
    String _email = ''; // Variable para almacenar el email ingresado.
    String _password = ''; // Variable para almacenar la contraseña ingresada.

    Future<void> _iniciarSesion() async { // Método para iniciar sesión.
      if (_formKey.currentState!.validate()) { // Valida el formulario.
        _formKey.currentState!.save(); // Guarda los valores del formulario.

        final usuario = await DatabaseHelper.instance.autenticarUsuario(_email, _password); // Autentica al usuario con la base de datos.

        if (!mounted) return; // Verifica si el widget sigue montado.

        if (usuario != null) { // Si el usuario es válido.
          ScaffoldMessenger.of(context).showSnackBar( // Muestra un mensaje de bienvenida.
            const SnackBar(content: Text('Bienvenido')),
          );
          Navigator.pushReplacementNamed(context, '/home'); // Redirige a la pantalla principal.
        } else { // Si las credenciales son incorrectas.
          ScaffoldMessenger.of(context).showSnackBar( // Muestra un mensaje de error.
            const SnackBar(content: Text('Credenciales incorrectas')),
          );
        }
      }
    }

    Future<void> _recuperarPassword() async { // Método para recuperar la contraseña.
      if (_email.isEmpty || !_email.contains('@')) { // Verifica si el email es válido.
        ScaffoldMessenger.of(context).showSnackBar( // Muestra un mensaje de error si el email no es válido.
          const SnackBar(content: Text('Ingrese un correo válido para recuperar la contraseña')),
        );
        return;
      }

      final usuario = await DatabaseHelper.instance.obtenerUsuarioPorEmail(_email); // Obtiene el usuario por email de la base de datos.
      if (usuario == null) { // Si el usuario no está registrado.
        ScaffoldMessenger.of(context).showSnackBar( // Muestra un mensaje de error.
          const SnackBar(content: Text('Correo no registrado')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar( // Muestra un mensaje de éxito.
        const SnackBar(content: Text('Se ha enviado un enlace de recuperación a su correo')),
      );

      // Aquí podrías implementar lógica para enviar un email
    }

    @override
    Widget build(BuildContext context) { // Construye la interfaz de usuario.
      return Scaffold(
        appBar: AppBar(title: const Text('Inicio de Sesión')), // Barra de aplicación con el título.
        body: Padding(
          padding: const EdgeInsets.all(16.0), // Padding alrededor del formulario.
          child: Form(
            key: _formKey, // Asigna la clave del formulario.
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Centra los elementos verticalmente.
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'), // Campo de texto para el email.
                  keyboardType: TextInputType.emailAddress, // Tipo de teclado para email.
                  validator: (value) => value!.isEmpty || !value.contains('@') ? 'Ingrese un correo válido' : null, // Valida el email.
                  onSaved: (value) => _email = value!, // Guarda el email ingresado.
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Contraseña'), // Campo de texto para la contraseña.
                  obscureText: true, // Oculta el texto ingresado.
                  validator: (value) => value!.isEmpty ? 'Ingrese su contraseña' : null, // Valida la contraseña.
                  onSaved: (value) => _password = value!, // Guarda la contraseña ingresada.
                ),
                const SizedBox(height: 20), // Espacio entre los campos y el botón.
                ElevatedButton(
                  onPressed: _iniciarSesion, // Llama al método para iniciar sesión.
                  child: const Text('Iniciar Sesión'), // Texto del botón.
                ),
                const SizedBox(height: 10), // Espacio entre los botones.
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/registro'); // Navega a la pantalla de registro.
                  },
                  child: const Text(
                    'Crear cuenta',
                    style: TextStyle(fontSize: 16, color: Colors.blue), // Estilo del texto.
                  ),
                ),
                const SizedBox(height: 10), // Espacio entre los botones.
                TextButton(
                  onPressed: _recuperarPassword, // Llama al método para recuperar la contraseña.
                  child: const Text(
                    'Olvidé mi contraseña',
                    style: TextStyle(fontSize: 16, color: Colors.red), // Estilo del texto.
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }