import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PantallaRegistroAdmin extends StatefulWidget {
  const PantallaRegistroAdmin({super.key});

  @override
  State<PantallaRegistroAdmin> createState() => _PantallaRegistroAdminState();
}

class _PantallaRegistroAdminState extends State<PantallaRegistroAdmin>
    with TickerProviderStateMixin {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showCodigo = false;
  bool _isEmailValid = true;

  late AnimationController _fadeController;
  late AnimationController _buttonController;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _buttonController.dispose();
    _nombreController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  void _checkEmailValidity(String value) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    setState(() => _isEmailValid = emailRegex.hasMatch(value));
  }

  // 🔐 Leer código de admin desde Firestore
  Future<String?> _obtenerCodigoAdminDesdeDB() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('admin')
          .get();

      if (!doc.exists) return null;
      return doc.data()?['codigo_admin'] as String?;
    } catch (e) {
      debugPrint('Error obteniendo codigo_admin: $e');
      return null;
    }
  }

  Future<void> _registrarAdmin() async {
    final nombre = _nombreController.text.trim();
    final email = _emailController.text.trim();
    final password = _passController.text.trim();
    final codigoIngresado = _codigoController.text.trim();

    if (nombre.isEmpty || email.isEmpty || password.isEmpty || codigoIngresado.isEmpty) {
      _mostrarSnackbar("Completa todos los campos");
      return;
    }

    try {
      setState(() => _isLoading = true);
      await _buttonController.forward();

      // ✅ 1. Obtener código válido desde Firestore
      final codigoValido = await _obtenerCodigoAdminDesdeDB();

      if (codigoValido == null) {
        _mostrarSnackbar(
          "No se encontró el código de administrador. Contacta al administrador del sistema.",
        );
        await _buttonController.reverse();
        setState(() => _isLoading = false);
        return;
      }

      // ✅ 2. Validar código ingresado
      if (codigoIngresado != codigoValido) {
        _mostrarSnackbar("Código de administrador inválido");
        await _buttonController.reverse();
        setState(() => _isLoading = false);
        return;
      }

      // ✅ 3. Crear usuario administrador
      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCred.user!.uid)
          .set({
        'nombre': nombre,
        'email': email,
        'rol': 'admin',
        'creado': Timestamp.now(),
      });

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => ScaleTransition(
          scale: CurvedAnimation(
            parent: _fadeController,
            curve: Curves.elasticOut,
          ),
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("✅ ¡Registro exitoso!"),
            content: Text(
              "Bienvenido administrador $nombre 👋\n\nTu cuenta ha sido creada correctamente.",
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                child: const Text("Ir al login"),
              ),
            ],
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al registrar';
      if (e.code == 'email-already-in-use') mensaje = 'El correo ya está en uso';
      if (e.code == 'weak-password') mensaje = 'Contraseña débil';
      if (e.code == 'invalid-email') mensaje = 'Correo inválido';
      _mostrarSnackbar(mensaje);
    } finally {
      await _buttonController.reverse();
      setState(() => _isLoading = false);
    }
  }

  void _mostrarSnackbar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Registro de Administrador",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 🎨 Fondo degradado
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0072FF),
                  Color(0xFF00C6FF),
                  Color(0xFFB2FEFA),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

        Positioned.fill(
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
    child: Container(color: Colors.white.withOpacity(0.05)),
  ),
),


          // 📋 Tarjeta de formulario
          FadeTransition(
            opacity: _fadeController,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 100),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Hero(
                        tag: "taully_logo",
                        child: Image.asset(
                          'lib/imgtaully/Taully_remo.png',
                          width: size.width * 0.3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          "Crear cuenta de Administrador",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Regístrate con tu código de administrador",
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                      const SizedBox(height: 35),

                      // Campos de texto
                      _buildField(
                        controller: _nombreController,
                        icon: Icons.person,
                        label: "Nombre completo",
                        hint: "Ej. Juan Pérez",
                      ),
                      const SizedBox(height: 20),
                      _buildField(
                        controller: _emailController,
                        icon: Icons.email_outlined,
                        label: "Correo electrónico",
                        hint: "ejemplo@correo.com",
                        onChanged: _checkEmailValidity,
                        errorText: _isEmailValid ? null : "Correo inválido",
                      ),
                      const SizedBox(height: 20),
                      _buildField(
                        controller: _passController,
                        icon: Icons.lock_outline,
                        label: "Contraseña",
                        hint: "Mínimo 6 caracteres",
                        obscure: !_showPassword,
                        suffix: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildField(
                        controller: _codigoController,
                        icon: Icons.vpn_key,
                        label: "Código de administrador",
                        hint: "Ingresa tu código especial",
                        obscure: !_showCodigo,
                        suffix: IconButton(
                          icon: Icon(
                            _showCodigo
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () =>
                              setState(() => _showCodigo = !_showCodigo),
                        ),
                      ),

                      const SizedBox(height: 40),

                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.blue)
                          : ScaleTransition(
                              scale: Tween(begin: 1.0, end: 1.1).animate(
                                CurvedAnimation(
                                  parent: _buttonController,
                                  curve: Curves.elasticInOut,
                                ),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _registrarAdmin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 60, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 10,
                                  shadowColor:
                                      Colors.blueAccent.withOpacity(0.5),
                                ),
                                icon: const Icon(Icons.admin_panel_settings),
                                label: const Text(
                                  "Registrar Administrador",
                                  style: TextStyle(fontSize: 17),
                                ),
                              ),
                            ),
                      const SizedBox(height: 25),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                            context, '/login'),
                        child: const Text(
                          "¿Ya tienes cuenta? Inicia sesión",
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    bool obscure = false,
    Widget? suffix,
    Function(String)? onChanged,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue),
        suffixIcon: suffix,
        errorText: errorText,
        filled: true,
        fillColor: Colors.white,
        floatingLabelStyle: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      ),
    );
  }
}
