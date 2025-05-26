import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data_base/database_helper.dart';
import 'package:scanner_personal/WidgetBarra.dart';

class CambiarPasswordScreen extends StatefulWidget {
  const CambiarPasswordScreen({super.key});

  @override
  _CambiarPasswordScreenState createState() => _CambiarPasswordScreenState();
}

class _CambiarPasswordScreenState extends State<CambiarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isValidPassword = false;
  bool passwordsMatch = true;
  bool isLoading = false;
  String passwordStrength = '';
  String? userEmail;

  @override
  void initState() {
    super.initState();
    passwordController.addListener(_validatePassword);
    confirmPasswordController.addListener(_checkPasswordsMatch);

    _handleRecoveryFlow();
  }

  Future<void> _handleRecoveryFlow() async {
    try {
      final uri = Uri.base;
      final code = uri.queryParameters['code'];

      if (code != null && code.isNotEmpty) {
        try {
          final response = await Supabase.instance.client.auth
              .exchangeCodeForSession(code);
          final email = response.session.user.email;

          if (!mounted) return;
          setState(() {
            userEmail = email;
          });

          _mostrarExito('Sesión iniciada como $email');
        } catch (e) {
          debugPrint('❌ Error al intercambiar código: $e');
          if (!mounted) return;
          _mostrarError('No se pudo iniciar sesión. Redirigiendo al login...');
          await Future.delayed(const Duration(seconds: 2));
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        // Verificar si hay sesión activa
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          setState(() {
            userEmail = session.user.email;
          });
        }
      }
    } catch (e) {
      debugPrint('Error en _handleRecoveryFlow: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final password = passwordController.text.trim();

    setState(() {
      passwordsMatch = password == confirmPasswordController.text.trim();
      isValidPassword = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~.,;:<>?])[A-Za-z\d!@#\$&*~.,;:<>?]{8,}$',
      ).hasMatch(password);
      passwordStrength = _calcularFuerza(password);
    });
  }

  void _checkPasswordsMatch() {
    setState(() {
      passwordsMatch =
          passwordController.text.trim() ==
          confirmPasswordController.text.trim();
    });
  }

  String _calcularFuerza(String password) {
    if (password.length < 8) return 'Débil';
    final hasLetters = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasNumbers = RegExp(r'\d').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#\$&*~.,;:<>?]').hasMatch(password);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);

    if (hasLetters && hasNumbers && hasSpecial && hasUpper) return 'Fuerte';
    if (hasLetters && hasNumbers) return 'Media';
    return 'Débil';
  }

  Color _colorPorFuerza(String fuerza) {
    switch (fuerza) {
      case 'Fuerte':
        return Colors.green;
      case 'Media':
        return Colors.orange;
      default:
        return Colors.red;
    }
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!isValidPassword || !passwordsMatch) return;

    setState(() => isLoading = true);

    final password = passwordController.text.trim();

    try {
      final success = await DatabaseHelper.instance.cambiarPassword(password);

      if (!mounted) return;

      if (success) {
        _mostrarExito('Contraseña actualizada con éxito');
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        _mostrarError('No se pudo actualizar la contraseña. Intenta de nuevo.');
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cambiar Contraseña',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFeff8ff),
        foregroundColor: primaryColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                if (userEmail != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Cambiando contraseña para: $userEmail',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  'Crea una nueva contraseña segura',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu nueva contraseña debe cumplir con los requisitos de seguridad',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    labelStyle: GoogleFonts.poppins(),
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                    helperText:
                        'Mínimo 8 caracteres, incluir mayúsculas, minúsculas, números y símbolos',
                    helperStyle: GoogleFonts.poppins(fontSize: 12),
                    errorText:
                        isValidPassword || passwordController.text.isEmpty
                            ? null
                            : 'Contraseña no válida',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa una contraseña';
                    }
                    if (!isValidPassword) {
                      return 'La contraseña no cumple con los requisitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Fortaleza: ',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      passwordStrength,
                      style: GoogleFonts.poppins(
                        color: _colorPorFuerza(passwordStrength),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: !isConfirmPasswordVisible,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    labelStyle: GoogleFonts.poppins(),
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isConfirmPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          isConfirmPasswordVisible = !isConfirmPasswordVisible;
                        });
                      },
                    ),
                    errorText:
                        passwordsMatch ? null : 'Las contraseñas no coinciden',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor confirma tu contraseña';
                    }
                    if (!passwordsMatch) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed:
                      (isValidPassword && passwordsMatch && !isLoading)
                          ? _submit
                          : null,
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
                            'Actualizar contraseña',
                            style: TextStyle(color: Colors.white),
                          ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed:
                      isLoading
                          ? null
                          : () => Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          ),
                  child: Text(
                    'Volver al inicio de sesión',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
