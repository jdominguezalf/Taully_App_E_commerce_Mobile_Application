import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../cart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? _selectedPaymentMethod;
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Finalizar Compra',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
      ),
      body:
          _isProcessing
              ? _buildProcessingView()
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumen de la compra
                    _buildOrderSummary(cart),
                    const SizedBox(height: 24),

                    // Información de entrega
                    _buildDeliveryInfo(),
                    const SizedBox(height: 24),

                    // Métodos de pago
                    _buildPaymentMethods(),
                    const SizedBox(height: 32),

                    // Botón de confirmar pago
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _selectedPaymentMethod == null ||
                                    _nombreController.text.trim().isEmpty ||
                                    _emailController.text.trim().isEmpty ||
                                    _phoneController.text.trim().isEmpty ||
                                    _direccionController.text.trim().isEmpty
                                ? null
                                : () => _processPayment(context, cart),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          'Confirmar Pago',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildOrderSummary(Cart cart) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.shopping_cart, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Resumen de la compra',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...cart.items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['name'],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      'S/ ${item['price'].toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            }),
            const Divider(thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'S/ ${cart.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Envío:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('S/ 5.00', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'S/ ${(cart.totalAmount + 5.0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Información de contacto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nombre completo
            TextField(
              controller: _nombreController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Nombre completo',
                hintText: 'Ej: Juan Pérez',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                ),
                prefixIcon: const Icon(
                  Icons.account_circle,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Correo electrónico
            TextField(
              controller: _emailController,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                hintText: 'ejemplo@gmail.com',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                ),
                prefixIcon: const Icon(Icons.email, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),

            // Número de teléfono
            TextField(
              controller: _phoneController,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Número de teléfono',
                hintText: 'Ej: 987654321',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                ),
                prefixIcon: const Icon(Icons.phone, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),

            // Dirección
            TextField(
              controller: _direccionController,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.streetAddress,
              decoration: InputDecoration(
                labelText: 'Dirección de entrega',
                hintText: 'Ej: Calle Falsa 123, Lima',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                ),
                prefixIcon: const Icon(Icons.location_on, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.payment, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Método de pago',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPaymentOption(
              'Billeteras Digitales (Yape/Plin)',
              Icons.smartphone,
              'Pago rápido y seguro con código QR',
              _selectedPaymentMethod == 'Yape',
              () {
                setState(() {
                  _selectedPaymentMethod = 'Yape';
                });
                _showYapeInstructions(context);
              },
              Colors.purple.shade800,
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              'Tarjeta de crédito/débito',
              Icons.credit_card,
              'Visa, Mastercard, American Express y más',
              _selectedPaymentMethod == 'Tarjeta',
              () {
                setState(() {
                  _selectedPaymentMethod = 'Tarjeta';
                });
                _showCardPaymentForm(context);
              },
              Colors.blue.shade800,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String title,
    IconData icon,
    String subtitle,
    bool isSelected,
    VoidCallback onTap,
    Color iconColor,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey[300]!,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.orange.withAlpha(25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? iconColor.withAlpha(25) : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? iconColor : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
            if (!isSelected)
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showYapeInstructions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (_, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          height: 5,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Pago con Yape/Plin',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code_2,
                                  size: 120,
                                  color: Colors.orange.shade800,
                                ),
                                const Text(
                                  'Código QR de pago',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Instrucciones de pago',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInstructionStep(
                          1,
                          'Abre tu aplicación de Yape o Plin',
                        ),
                        _buildInstructionStep(
                          2,
                          'Selecciona la opción de "Escanear QR"',
                        ),
                        _buildInstructionStep(
                          3,
                          'Escanea el código QR mostrado arriba',
                        ),
                        _buildInstructionStep(4, 'Confirma el monto a pagar'),
                        _buildInstructionStep(
                          5,
                          'Completa el pago en tu aplicación',
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'También puedes pagar al número',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '+51 987 654 321',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text('A nombre de: Taully Minimarket.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Aceptar',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildInstructionStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  void _showCardPaymentForm(BuildContext context) {
    final TextEditingController cardNumberController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController expiryController = TextEditingController();
    final TextEditingController cvvController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              String formatCardNumber(String input) {
                // Eliminar espacios y caracteres no numéricos
                final cleanInput = input.replaceAll(RegExp(r'\D'), '');

                // Dividir en grupos de 4 dígitos
                final parts = <String>[];
                for (var i = 0; i < cleanInput.length; i += 4) {
                  final end =
                      i + 4 < cleanInput.length ? i + 4 : cleanInput.length;
                  parts.add(cleanInput.substring(i, end));
                }

                // Completar con X si es necesario
                while (parts.length < 4) {
                  parts.add('XXXX');
                }

                return parts.join(' ');
              }

              return DraggableScrollableSheet(
                initialChildSize: 0.85,
                minChildSize: 0.6,
                maxChildSize: 0.95,
                expand: false,
                builder:
                    (_, scrollController) => SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Center(
                              child: Container(
                                height: 5,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Center(
                              child: Text(
                                'Pago con Tarjeta',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Tarjeta de crédito visual
                            Container(
                              height: 200,
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.shade700,
                                    Colors.orange.shade300,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Minimarket',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.payment,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 30),
                                  Text(
                                    cardNumberController.text.isEmpty
                                        ? 'XXXX XXXX XXXX XXXX'
                                        : formatCardNumber(
                                          cardNumberController.text,
                                        ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      letterSpacing: 2,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'TITULAR',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            nameController.text.isEmpty
                                                ? 'NOMBRE APELLIDO'
                                                : nameController.text
                                                    .toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'EXP',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            expiryController.text.isEmpty
                                                ? 'MM/YY'
                                                : expiryController.text,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                            // Formulario de tarjeta
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCardTextField(
                                  controller: cardNumberController,
                                  label: 'Número de tarjeta',
                                  hint: 'xxxx xxxx xxxx xxxx',
                                  keyboardType: TextInputType.number,
                                  icon: Icons.credit_card,
                                  onChanged: (value) {
                                    setState(() {});
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildCardTextField(
                                  controller: nameController,
                                  label: 'Nombre en la tarjeta',
                                  hint: 'Como aparece en la tarjeta',
                                  icon: Icons.person,
                                  onChanged: (value) {
                                    setState(() {});
                                  },
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildCardTextField(
                                        controller: expiryController,
                                        label: 'Fecha de vencimiento',
                                        hint: 'MM/YY',
                                        keyboardType: TextInputType.datetime,
                                        icon: Icons.date_range,
                                        onChanged: (value) {
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildCardTextField(
                                        controller: cvvController,
                                        label: 'CVV',
                                        hint: '123',
                                        keyboardType: TextInputType.number,
                                        icon: Icons.security,
                                        obscureText: true,
                                        onChanged: (value) {},
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Logos de tarjetas aceptadas
                            Center(
                              child: Wrap(
                                spacing: 16,
                                children: [
                                  _buildCardLogo('Visa'),
                                  _buildCardLogo('Mastercard'),
                                  _buildCardLogo('Amex'),
                                  _buildCardLogo('Diners'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Nota de seguridad
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.security,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Text(
                                      'Tus datos de pago están protegidos con encriptación de nivel bancario.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Aceptar',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              );
            },
          ),
    );
  }

  Widget _buildCardTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.orange, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCardLogo(String brand) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        brand,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
          const SizedBox(height: 24),
          const Text(
            'Procesando tu pago...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Por favor, no cierres esta página',
              style: TextStyle(color: Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }

  void _processPayment(BuildContext context, Cart cart) async {
    setState(() => _isProcessing = true);

    final resumen = generarResumenPedido(cart.items);
    final total = cart.totalAmount + 5.0;

    try {
      // 1. Enviar correo
      final url = Uri.parse(
        'https://us-central1-flutter-base-de-datos-ed70a.cloudfunctions.net/enviarCorreo',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': _nombreController.text.trim(),
          'email': _emailController.text.trim(),
          'orderDetails': resumen,
          'total': total.toStringAsFixed(2),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al enviar el correo');
      }

      // 2. Guardar en Firestore
      await FirebaseFirestore.instance.collection('pedidos').add({
        'nombre': _nombreController.text.trim(),
        'email': _emailController.text.trim(),
        'telefono': _phoneController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'total': total,
        'estado': 'Pendiente',
        'fecha': Timestamp.now(),
        'items':
            cart.items
                .map(
                  (item) => {
                    'name': item['name'],
                    'price': item['price'],
                    'quantity': item['quantity'],
                  },
                )
                .toList(),
      });

      // 3. Limpiar y confirmar
      cart.clear();
      if (mounted) _showPaymentSuccess(context);
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showPaymentSuccess(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '¡Pago completado!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tu pedido ha sido procesado exitosamente. Recibirás un correo con los detalles de tu compra.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Volver a la tienda',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

String generarResumenPedido(List<Map<String, dynamic>> items) {
  return items
      .map((item) {
        final subtotal = (item['price'] * item['quantity']).toStringAsFixed(2);
        return '- ${item['name']} x${item['quantity']} (S/ $subtotal)';
      })
      .join('\n');
}

Future<void> enviarCorreoDesdeFlutter({
  required String nombre,
  required String email,
  required String resumen,
  required double total,
}) async {
  final url = Uri.parse(
    'https://us-central1-flutter-base-de-datos-ed70a.cloudfunctions.net/enviarCorreo',
  );

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'orderDetails': resumen,
        'total': total.toStringAsFixed(2),
      }),
    );

    if (response.statusCode == 200) {
      print('✅ Correo enviado correctamente');
    } else {
      print('❌ Error en el servidor: ${response.body}');
      throw Exception('Error del servidor');
    }
  } catch (e) {
    print('❌ Error al conectar con la función: $e');
    rethrow;
  }
}
