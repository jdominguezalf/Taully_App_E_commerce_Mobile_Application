import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PantallaRegistroCliente extends StatefulWidget {
  const PantallaRegistroCliente({super.key});

  @override
  State<PantallaRegistroCliente> createState() =>
      _PantallaRegistroClienteState();
}

class _PantallaRegistroClienteState extends State<PantallaRegistroCliente>
    with TickerProviderStateMixin {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _isEmailValid = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _buttonController;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _buttonController.dispose();
    _nombreController.dispose();
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _checkEmailValidity(String value) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    setState(() => _isEmailValid = emailRegex.hasMatch(value));
  }

  Future<void> _registrarCliente() async {
    final nombre = _nombreController.text.trim();
    final email = _emailController.text.trim();
    final password = _passController.text.trim();

    if (nombre.isEmpty || email.isEmpty || password.isEmpty) {
      _mostrarSnackbar("Completa todos los campos");
      return;
    }
    if (!_isEmailValid) {
      _mostrarSnackbar("Correo electrónico inválido");
      return;
    }

    try {
      setState(() => _isLoading = true);
      await _buttonController.forward();

      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCred.user!.uid)
          .set({
        'nombre': nombre,
        'email': email,
        'rol': 'cliente',
        'creado': Timestamp.now(),
      });

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => ScaleTransition(
          scale: CurvedAnimation(
            parent: _animController,
            curve: Curves.elasticOut,
          ),
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("🎉 ¡Registro exitoso!"),
            content: Text(
              "Bienvenido $nombre 👋\n\nTu cuenta ha sido creada exitosamente.",
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
          "Registro de Cliente",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 🌈 Fondo degradado con niebla
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF7D024),
                  Color(0xFFFFE45C),
                  Color(0xFFFFF6A8),
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

          // 📋 Formulario animado
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 100),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
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
                            width: size.width * 0.35,
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Center(
                          child: Text(
                            "Crear cuenta de Cliente",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Regístrate para empezar a comprar con Taully",
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 15, color: Colors.black54),
                        ),
                        const SizedBox(height: 30),

                        // Campos
                        _buildInputField(
                          controller: _nombreController,
                          icon: Icons.person,
                          label: "Nombre completo",
                          hint: "Ingresa tu nombre y apellido",
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          label: "Correo electrónico",
                          hint: "ejemplo@correo.com",
                          onChanged: _checkEmailValidity,
                          errorText: _isEmailValid ? null : "Correo no válido",
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
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
                            onPressed: () => setState(
                                () => _showPassword = !_showPassword),
                          ),
                        ),
                        const SizedBox(height: 40),

                        _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.green)
                            : ElevatedButton.icon(
                                onPressed: _registrarCliente,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 60, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 8,
                                  shadowColor:
                                      Colors.greenAccent.withOpacity(0.5),
                                ),
                                icon: const Icon(Icons.person_add_alt_1),
                                label: const Text(
                                  "Registrar Cliente",
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                        const SizedBox(height: 20),
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
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
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
        prefixIcon: Icon(icon, color: Colors.green),
        suffixIcon: suffix,
        errorText: errorText,
        filled: true,
        fillColor: Colors.white,
        floatingLabelStyle:
            const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      ),
    );
  }
}
