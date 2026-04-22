import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 👇 Versión actual de la app
const String kAppVersion = "2.2.1";

class PantallaBienvenida extends StatefulWidget {
  const PantallaBienvenida({super.key});

  @override
  State<PantallaBienvenida> createState() => _PantallaBienvenidaState();
}

class _PantallaBienvenidaState extends State<PantallaBienvenida>
    with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  bool _versionOk = true; // 👈 si es false, se bloquea el acceso

  @override
  void initState() {
    super.initState();

    // 🎬 Video de fondo
    _videoController = VideoPlayerController.asset('assets/videos/Taully_remo.mp4')
      ..initialize().then((_) {
        _videoController.play();
        _videoController.setLooping(true);
        setState(() {});
      });

    // ✨ Fade-in del contenido
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    // 💫 Efecto de escala sutil en el logo
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation =
        Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // 🔐 Validar versión de la app contra Firestore
    _validarVersion();
  }

  @override
  void dispose() {
    _videoController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // 🔢 Comparar versión actual vs mínima
  bool _esVersionMayorOIgual(String actual, String minima) {
    final a = actual.split('.').map(int.parse).toList();
    final b = minima.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (a[i] > b[i]) return true;
      if (a[i] < b[i]) return false;
    }
    return true; // son iguales
  }

  // 🔐 Leer min_version de Firestore y validar
  Future<void> _validarVersion() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('app')
          .get();

      if (!doc.exists) return;

      final data = doc.data() ?? {};
      final minVersion = (data['min_version'] ?? '') as String;
      final mensaje = (data['mensaje'] ?? 'Actualiza la app para continuar.') as String;

      final esValida = _esVersionMayorOIgual(kAppVersion, minVersion);

      if (!esValida) {
        setState(() => _versionOk = false);
        _mostrarDialogoActualizacion(mensaje);
      }
    } catch (e) {
      debugPrint('Error validando versión: $e');
      // Si falla la validación, puedes decidir bloquear o permitir
      // Aquí la dejamos como está (_versionOk true) para no romper la app si Firestore falla
    }
  }

  void _mostrarDialogoActualizacion(String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("⚠️ Actualización requerida"),
        content: Text(
          mensaje,
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Aquí podrías abrir una URL del Play Store / web
              Navigator.of(context).pop();
            },
            child: const Text("Entendido"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 🎥 Fondo con video o imagen
          if (_videoController.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            Container(color: Colors.orange.shade100),

          // 🌫️ Capa translúcida (efecto vidrio)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          // ✨ Contenido centrado con LayoutBuilder para respetar ancho limitado
          FadeTransition(
            opacity: _fadeAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double maxW = constraints.maxWidth; // 👉 aquí sí respeta el maxWidth de web

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 🔸 Logo animado
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD54F), Color(0xFFFFA726)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'lib/imgtaully/Taully_remo.png',
                              width: maxW * 0.55,
                              height: maxW * 0.55,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // 🛍️ Título principal
                      const Text(
                        "Bienvenido a Taully",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 8,
                              color: Colors.black45,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Tu minimarket digital de confianza 🛒",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 50),

                      // 🚀 Botón moderno con Glassmorphism
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: ElevatedButton(
                            onPressed: _versionOk
                                ? () {
                                    Navigator.of(context)
                                        .pushReplacementNamed('/login');
                                  }
                                : null, // 👉 si versión es vieja, se desactiva el botón
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              padding: EdgeInsets.symmetric(
                                horizontal: maxW * 0.25,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                              elevation: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  "Comenzar",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 📜 Pie de página (puedes poner versión aquí si quieres)
          Positioned(
            bottom: 25,
            left: 0,
            right: 0,
            child: Text(
              "Versión $kAppVersion",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'Poppins',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
