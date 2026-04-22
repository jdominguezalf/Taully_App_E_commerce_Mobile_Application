import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const String _url =
      'https://us-central1-flutter-base-de-datos-ed70a.cloudfunctions.net/enviarCorreo';

  /// Enviar correo de confirmación de pedido
  static Future<void> enviarCorreoPedido({
    required String nombre,
    required String email,
    required List<Map<String, dynamic>> items,
    required double total,
  }) async {
    final resumen = items.map((item) {
      final subtotal = (item['price'] * item['quantity']).toStringAsFixed(2);
      return '- ${item['name']} x${item['quantity']} (S/ $subtotal)';
    }).join('\n');

    final response = await http.post(
      Uri.parse(_url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'orderDetails': resumen,
        'total': total.toStringAsFixed(2),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('❌ Error al enviar el correo: ${response.body}');
    }
  }
}
