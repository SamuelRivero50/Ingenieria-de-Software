import 'package:flutter/material.dart'; // Importa la biblioteca de Flutter para construir la interfaz de usuario.
                import '../data_base/database_helper.dart'; // Importa el helper de la base de datos para manejar operaciones de base de datos.

                class RegistroScreen extends StatefulWidget { // Define un widget con estado para la pantalla de registro.
                  const RegistroScreen({super.key}); // Constructor de la clase RegistroScreen.

                  @override
                  RegistroScreenState createState() => RegistroScreenState(); // Crea el estado asociado a este widget.
                }

                class RegistroScreenState extends State<RegistroScreen> { // Define el estado para la pantalla de registro.
                  final _formKey = GlobalKey<FormState>(); // Clave global para identificar el formulario y validar su estado.
                  String _nombre = ''; // Variable para almacenar el nombre ingresado.
                  String _email = ''; // Variable para almacenar el email ingresado.
                  String _password = ''; // Variable para almacenar la contraseña ingresada.

                  Future<void> _registrarUsuario() async { // Método para registrar un nuevo usuario.
                    if (_formKey.currentState!.validate()) { // Valida el formulario.
                      _formKey.currentState!.save(); // Guarda los valores del formulario.

                      // Verificar si el correo ya está registrado
                      final usuarioExistente = await DatabaseHelper.instance.obtenerUsuarioPorEmail(_email); // Obtiene el usuario por email de la base de datos.
                      if (usuarioExistente != null) { // Si el usuario ya está registrado.
                        ScaffoldMessenger.of(context).showSnackBar( // Muestra un mensaje de error.
                          const SnackBar(content: Text('El correo ya está registrado')),
                        );
                        return; // Termina la ejecución del método.
                      }

                      // Guardar usuario en SQLite
                      await DatabaseHelper.instance.agregarUsuario(_nombre, _email, _password); // Agrega el nuevo usuario a la base de datos.

                      ScaffoldMessenger.of(context).showSnackBar( // Muestra un mensaje de éxito.
                        const SnackBar(content: Text('Usuario registrado correctamente')),
                      );

                      Navigator.pop(context); // Regresa a la pantalla de inicio de sesión.
                    }
                  }

                  bool _validarPassword(String password) { // Método para validar la contraseña.
                    return password.length >= 8 && // Verifica que la contraseña tenga al menos 8 caracteres.
                        password.contains(RegExp(r'[A-Z]')) && // Verifica que la contraseña tenga al menos una letra mayúscula.
                        password.contains(RegExp(r'[0-9]')) && // Verifica que la contraseña tenga al menos un número.
                        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')); // Verifica que la contraseña tenga al menos un símbolo especial.
                  }

                  @override
                  Widget build(BuildContext context) { // Construye la interfaz de usuario.
                    return Scaffold(
                      appBar: AppBar(title: const Text('Registro')), // Barra de aplicación con el título.
                      body: Padding(
                        padding: const EdgeInsets.all(16.0), // Padding alrededor del formulario.
                        child: Form(
                          key: _formKey, // Asigna la clave del formulario.
                          child: Column(
                            children: [
                              TextFormField(
                                decoration: const InputDecoration(labelText: 'Nombre'), // Campo de texto para el nombre.
                                validator: (value) => value!.isEmpty ? 'Ingrese su nombre' : null, // Valida el nombre.
                                onSaved: (value) => _nombre = value!, // Guarda el nombre ingresado.
                              ),
                              TextFormField(
                                decoration: const InputDecoration(labelText: 'Email'), // Campo de texto para el email.
                                keyboardType: TextInputType.emailAddress, // Tipo de teclado para email.
                                validator: (value) =>
                                value!.isEmpty || !value.contains('@') ? 'Ingrese un correo válido' : null, // Valida el email.
                                onSaved: (value) => _email = value!, // Guarda el email ingresado.
                              ),
                              TextFormField(
                                decoration: const InputDecoration(labelText: 'Contraseña'), // Campo de texto para la contraseña.
                                obscureText: true, // Oculta el texto ingresado.
                                validator: (value) =>
                                !_validarPassword(value!)
                                    ? 'Debe tener al menos 8 caracteres, una mayúscula, un número y un símbolo'
                                    : null, // Valida la contraseña.
                                onSaved: (value) => _password = value!, // Guarda la contraseña ingresada.
                              ),
                              const SizedBox(height: 20), // Espacio entre los campos y el botón.
                              ElevatedButton(
                                onPressed: _registrarUsuario, // Llama al método para registrar el usuario.
                                child: const Text('Registrar'), // Texto del botón.
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                }