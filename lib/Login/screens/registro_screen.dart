import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data_base/database_helper.dart';
import 'package:scanner_personal/Home/home.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  _RegistroScreenState createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final nombreController = TextEditingController();
  final apellidoController = TextEditingController();
  final correoController = TextEditingController();
  final passwordController = TextEditingController();

  final nombreFocus = FocusNode();
  final apellidoFocus = FocusNode();
  final correoFocus = FocusNode();
  final passwordFocus = FocusNode();

  bool showPassword = false;
  bool nombreTouched = false;
  bool apellidoTouched = false;
  bool correoTouched = false;
  bool passwordTouched = false;
  bool isLoading = false;

  String? nombreError;
  String? apellidoError;
  String? correoError;
  String? passwordError;

  bool isFormValid = false;

  @override
  void initState() {
    super.initState();

    nombreController.addListener(validarFormulario);
    apellidoController.addListener(validarFormulario);
    correoController.addListener(validarFormulario);
    passwordController.addListener(validarFormulario);

    nombreFocus.addListener(() {
      if (nombreFocus.hasFocus) setState(() => nombreTouched = true);
    });
    apellidoFocus.addListener(() {
      if (apellidoFocus.hasFocus) setState(() => apellidoTouched = true);
    });
    correoFocus.addListener(() {
      if (correoFocus.hasFocus) setState(() => correoTouched = true);
    });
    passwordFocus.addListener(() {
      if (passwordFocus.hasFocus) setState(() => passwordTouched = true);
    });
  }

  @override
  void dispose() {
    nombreController.dispose();
    apellidoController.dispose();
    correoController.dispose();
    passwordController.dispose();
    nombreFocus.dispose();
    apellidoFocus.dispose();
    correoFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  bool validarCorreo(String correo) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(correo) && correo.isNotEmpty;
  }

  bool validarPassword(String password) {
    final lengthValid = password.length >= 8;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    return lengthValid && hasUpper && hasSpecial;
  }

  void validarFormulario() {
    final correo = correoController.text.trim();
    final password = passwordController.text.trim();
    final nombre = nombreController.text.trim();
    final apellido = apellidoController.text.trim();

    setState(() {
      nombreError = nombre.isEmpty ? 'Nombre requerido' : null;
      apellidoError = apellido.isEmpty ? 'Apellido requerido' : null;
      correoError = validarCorreo(correo) ? null : 'Correo no válido';
      passwordError =
          validarPassword(password)
              ? null
              : 'Mínimo 8 caracteres, 1 mayúscula y 1 símbolo';

      isFormValid =
          nombreError == null &&
          apellidoError == null &&
          correoError == null &&
          passwordError == null &&
          nombre.isNotEmpty &&
          apellido.isNotEmpty &&
          correo.isNotEmpty &&
          password.isNotEmpty;
    });
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> registrarUsuario() async {
    validarFormulario();
    if (!isFormValid) return;

    setState(() => isLoading = true);

    final correo = correoController.text.trim();
    final password = passwordController.text.trim();
    final nombre = nombreController.text.trim();
    final apellido = apellidoController.text.trim();

    try {
      final success = await DatabaseHelper.instance.registrarUsuario(
        nombre,
        apellido,
        correo,
        password,
      );

      if (!mounted) return;

      if (success) {
        _mostrarExito('Usuario registrado correctamente');

        // Navegar al home y limpiar la pila de navegación
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        _mostrarError(
          'Error al registrar usuario. El correo ya puede estar en uso.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarError(
        'Error de conexión. Verifica tu conexión a internet e intenta de nuevo.',
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF090467);
    const backgroundColor = Color(0xfff5f5fa);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Registro de Usuario",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFeff8ff),
        foregroundColor: primaryColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Crear cuenta',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Completa la información para registrarte',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: nombreController,
                focusNode: nombreFocus,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: "Nombre",
                  labelStyle: GoogleFonts.poppins(),
                  errorText: nombreTouched ? nombreError : null,
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color:
                          nombreTouched && nombreError != null
                              ? Colors.red
                              : primaryColor,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: apellidoController,
                focusNode: apellidoFocus,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: "Apellido",
                  labelStyle: GoogleFonts.poppins(),
                  errorText: apellidoTouched ? apellidoError : null,
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color:
                          apellidoTouched && apellidoError != null
                              ? Colors.red
                              : primaryColor,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: correoController,
                focusNode: correoFocus,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: "Correo Electrónico",
                  labelStyle: GoogleFonts.poppins(),
                  errorText: correoTouched ? correoError : null,
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color:
                          correoTouched && correoError != null
                              ? Colors.red
                              : primaryColor,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                focusNode: passwordFocus,
                obscureText: !showPassword,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  labelStyle: GoogleFonts.poppins(),
                  errorText: passwordTouched ? passwordError : null,
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color:
                          passwordTouched && passwordError != null
                              ? Colors.red
                              : primaryColor,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => showPassword = !showPassword);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'La contraseña debe tener al menos 8 caracteres, una mayúscula y un símbolo',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed:
                    (isFormValid && !isLoading) ? registrarUsuario : null,
                child:
                    isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text(
                          "Registrar",
                          style: TextStyle(color: Colors.white),
                        ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: Text(
                  '¿Ya tienes cuenta? Inicia sesión',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
