import 'package:flutter/material.dart';
import 'pantalla_registro_admin.dart';
import 'pantalla_registro_cliente.dart';
import '../../widgets/custom_page_route.dart';

class PantallaSelectorRegistro extends StatefulWidget {
  const PantallaSelectorRegistro({super.key});

  @override
  State<PantallaSelectorRegistro> createState() =>
      _PantallaSelectorRegistroState();
}

class _PantallaSelectorRegistroState extends State<PantallaSelectorRegistro>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🪄 Logo animado
                  Hero(
                    tag: "taully_logo",
                    child: Image.asset(
                      'lib/imgtaully/Taully_remo.png',
                      width: size.width * 0.4,
                      height: size.width * 0.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Elige cómo unirte a Taully",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A2540),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Crea tu cuenta para comenzar a comprar o administrar tu tienda digital.",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50),

                  // 🛍️ Tarjeta Cliente
                  _buildAnimatedOption(
                    title: "Soy Cliente",
                    color: const Color(0xFF43A047),
                    description:
                        "Explora productos, haz compras y lleva el control desde tu app.",
                    icon: Icons.shopping_cart_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        CustomPageRoute(
                            child: const PantallaRegistroCliente()),
                      );
                    },
                  ),
                  const SizedBox(height: 25),

                  // 👨‍💼 Tarjeta Admin
                  _buildAnimatedOption(
                    title: "Soy Administrador",
                    color: const Color(0xFF1E88E5),
                    description:
                        "Gestiona tus productos, pedidos y control total del minimarket.",
                    icon: Icons.admin_panel_settings_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        CustomPageRoute(child: const PantallaRegistroAdmin()),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // 🔙 Volver
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    icon:
                        const Icon(Icons.arrow_back_ios_new, color: Colors.black54),
                    label: const Text(
                      "Volver al inicio de sesión",
                      style: TextStyle(color: Colors.black54, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedOption({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTapDown: (_) => setState(() {}),
      onTapUp: (_) => setState(() {}),
      onTapCancel: () => setState(() {}),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: title,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.8), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Colors.black54,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: color.withOpacity(0.8), size: 22),
          ],
        ),
      ),
    );
  }
}
