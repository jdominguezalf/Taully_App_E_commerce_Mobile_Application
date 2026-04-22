import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../cart.dart';

class ConfirmacionPedidoPage extends StatefulWidget {
  const ConfirmacionPedidoPage({super.key});

  @override
  State<ConfirmacionPedidoPage> createState() => _ConfirmacionPedidoPageState();
}

class _ConfirmacionPedidoPageState extends State<ConfirmacionPedidoPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  bool _isLoading = true;
  String nombre = '';
  String correo = '';
  String? _metodoPago;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  // =====================================================
  // 👤 Cargar datos del usuario logueado desde Firestore
  // =====================================================
  Future<void> _cargarDatosUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();

        final data = doc.data();
        setState(() {
          nombre = data?['nombre'] ?? 'Sin nombre';
          correo = data?['email'] ?? user.email ?? 'Sin correo';
          _celularController.text = data?['telefono'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error al cargar datos de usuario: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // =====================================================
  // ✅ Confirmar y guardar el pedido + enviar correo
  // =====================================================
  Future<void> _confirmarPedido(Cart cart) async {
    if (_direccionController.text.isEmpty ||
        _celularController.text.isEmpty ||
        _metodoPago == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Completa todos los campos antes de confirmar.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado.');

      // 🔹 Datos a guardar
      final pedidoData = {
        'usuario_id': user.uid,
        'nombre': nombre,
        'email': correo,
        'telefono': _celularController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'metodo_pago': _metodoPago,
        'total': cart.totalAmount,
        'items': cart.items
            .map((item) => {
                  'name': item['name'],
                  'price': item['price'],
                  'quantity': item['quantity'],
                })
            .toList(),
        'fecha': FieldValue.serverTimestamp(),
        'estado': 'Pendiente',
      };

      // 🔸 Guardar en Firestore
      final pedidoRef =
          await FirebaseFirestore.instance.collection('pedidos').add(pedidoData);

      if (pedidoRef.id.isEmpty) {
        throw Exception('Error al registrar el pedido.');
      }

      // 🔸 Enviar correo asincrónicamente (sin bloquear)
      _enviarCorreoConfirmacion(cart);

      // 🔹 Limpiar carrito
      cart.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '✅ Pedido confirmado correctamente.',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      Navigator.pushReplacementNamed(context, '/Finaliza');
    } catch (e) {
      debugPrint('❌ Error al confirmar pedido: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // =====================================================
  // 📧 Envío de correo (separado, sin bloquear el flujo)
  // =====================================================
  Future<void> _enviarCorreoConfirmacion(Cart cart) async {
    try {
      final resumen = cart.items.map((item) {
        final subtotal = (item['price'] * item['quantity']).toStringAsFixed(2);
        return '- ${item['name']} x${item['quantity']} (S/ $subtotal)';
      }).join('\n');

      final url = Uri.parse(
        'https://us-central1-flutter-base-de-datos-ed70a.cloudfunctions.net/enviarCorreo',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'email': correo,
          'direccion': _direccionController.text.trim(),
          'telefono': _celularController.text.trim(),
          'metodo_pago': _metodoPago,
          'orderDetails': resumen,
          'total': cart.totalAmount.toStringAsFixed(2),
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('📩 Correo enviado correctamente.');
      } else {
        debugPrint('⚠️ Error al enviar correo: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error de correo: $e');
    }
  }

  // =====================================================
  // 🧱 UI PRINCIPAL
  // =====================================================
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Confirmar Pedido',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE0B2), Color(0xFFFFFDE7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 80),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeIn,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildUserInfo(),
                const SizedBox(height: 16),
                _buildResumenPedido(cart),
                const SizedBox(height: 16),
                _buildCelularField(),
                const SizedBox(height: 16),
                _buildDireccionEntrega(),
                const SizedBox(height: 16),
                _buildMetodoPago(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => _confirmarPedido(cart),
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            label: const Text(
              'Confirmar Pedido',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // =====================================================
  // 🧡 Encabezado decorativo
  // =====================================================
  Widget _buildHeader() {
    return Column(
      children: const [
        Icon(Icons.shopping_bag, color: Colors.orange, size: 70),
        SizedBox(height: 8),
        Text(
          '¡Revisa y confirma tu pedido!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
        Text(
          'Estamos listos para procesarlo con cariño 🧡',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.brown,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // 👤 Información del usuario
  // =====================================================
  Widget _buildUserInfo() {
    return Card(
      elevation: 5,
      shadowColor: Colors.orange.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          nombre,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          correo,
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
      ),
    );
  }

  // =====================================================
  // 🧾 Resumen del pedido
  // =====================================================
  Widget _buildResumenPedido(Cart cart) {
    return Card(
      elevation: 5,
      shadowColor: Colors.orange.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Resumen del Pedido',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...cart.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['name'],
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '${item['quantity']} x S/${(item['price'] as double).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.brown,
                        ),
                      ),
                    ],
                  ),
                )),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: S/${cart.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // 📱 Campo de celular
  // =====================================================
  Widget _buildCelularField() {
    return _inputCard(
      label: 'Número de celular',
      icon: Icons.phone_android,
      controller: _celularController,
      hint: 'Ej: 987654321',
    );
  }

  // =====================================================
  // 📦 Dirección
  // =====================================================
  Widget _buildDireccionEntrega() {
    return _inputCard(
      label: 'Dirección de entrega',
      icon: Icons.location_on,
      controller: _direccionController,
      hint: 'Ej: Av. Los Olivos 123, Lima Norte',
    );
  }

  // =====================================================
  // 💳 Métodos de pago
  // =====================================================
  Widget _buildMetodoPago() {
    return Card(
      elevation: 5,
      shadowColor: Colors.orange.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.credit_card, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Método de pago',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _radioTile('Yape', Icons.qr_code),
            _radioTile('Tarjeta', Icons.credit_card),
            _radioTile('Efectivo', Icons.payments),
          ],
        ),
      ),
    );
  }

  Widget _radioTile(String value, IconData icon) {
    return RadioListTile<String>(
      title: Text(value, style: const TextStyle(fontFamily: 'Poppins')),
      secondary: Icon(icon, color: Colors.orange),
      activeColor: Colors.orange,
      value: value,
      groupValue: _metodoPago,
      onChanged: (val) => setState(() => _metodoPago = val),
    );
  }

  // =====================================================
  // 🧱 Widget base para campos de texto
  // =====================================================
  Widget _inputCard({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.orange.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: InputBorder.none,
            prefixIcon: Icon(icon, color: Colors.orange),
            labelStyle: const TextStyle(fontFamily: 'Poppins'),
          ),
        ),
      ),
    );
  }
}
