import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/custom_page_route.dart'; // 👈 necesario para las transiciones
import '../../pantalla_login.dart'; // ruta correcta al login

class PerfilClientePage extends StatefulWidget {
  const PerfilClientePage({super.key});

  @override
  State<PerfilClientePage> createState() => _PerfilClientePageState();
}

class _PerfilClientePageState extends State<PerfilClientePage>
    with SingleTickerProviderStateMixin {
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? datosUsuario;
  bool _isLoading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _obtenerDatosUsuario();
  }

  Future<void> _obtenerDatosUsuario() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        setState(() {
          datosUsuario = doc.data();
          _isLoading = false;
        });
        _animController.forward();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error al obtener datos del usuario: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      CustomPageRoute(child: const PantallaLogin()),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    if (datosUsuario == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Perfil de Cliente")),
        body: const Center(child: Text("No se encontraron tus datos.")),
      );
    }

    final nombre = datosUsuario!['nombre'] ?? 'Sin nombre';
    final email = datosUsuario!['email'] ?? 'Sin correo';
    final fecha = (datosUsuario!['creado'] != null)
        ? (datosUsuario!['creado'] as Timestamp).toDate()
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDE7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          "Mi Perfil",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black87),
            tooltip: "Cerrar sesión",
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // 🧍 Imagen del usuario
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_rounded,
                      size: 70, color: Colors.green[700]),
                ),
              ),

              const SizedBox(height: 15),
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 5),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              if (fecha != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Miembro desde ${fecha.day}/${fecha.month}/${fecha.year}",
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),

              const SizedBox(height: 30),

              // 🌟 SECCIONES
              _buildSectionHeader("Mi Actividad"),
              _buildProfileOption(
                icon: Icons.shopping_bag_outlined,
                title: "Mis Compras",
                color: Colors.orange,
                onTap: () => Navigator.pushNamed(context, '/perfil-mis-compras'),
              ),
              _buildProfileOption(
                icon: Icons.favorite_border,
                title: "Mis Favoritos",
                color: Colors.pinkAccent,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Favoritos próximamente")),
                ),
              ),

              const SizedBox(height: 15),
              _buildSectionHeader("Cuenta"),
              _buildProfileOption(
                icon: Icons.settings_outlined,
                title: "Configuración",
                color: Colors.blueGrey,
                onTap: () =>
                    Navigator.pushNamed(context, '/perfil-configuracion'),
              ),
              _buildProfileOption(
                icon: Icons.support_agent_outlined,
                title: "Soporte y Ayuda",
                color: Colors.indigoAccent,
                onTap: () => Navigator.pushNamed(context, '/perfil-soporte'),
              ),

              const SizedBox(height: 25),
              _buildLogoutButton(),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 26),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
            color: Colors.black87,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.logout, color: Colors.white),
      label: const Text(
        "Cerrar Sesión",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 5,
      ),
      onPressed: _cerrarSesion,
    );
  }
}
