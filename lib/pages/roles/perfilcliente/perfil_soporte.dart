import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PerfilSoportePage extends StatelessWidget {
  const PerfilSoportePage({super.key});

  /// Abre WhatsApp con un mensaje predeterminado
  Future<void> _abrirWhatsApp(BuildContext context) async {
    final Uri url = Uri.parse(
      "https://wa.me/51987654321?text=¡Hola!%20Necesito%20ayuda%20con%20mi%20pedido%20de%20Minimarket%20Taully.%20😊",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo abrir WhatsApp."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// Abre correo electrónico de soporte
  Future<void> _enviarCorreo(BuildContext context) async {
    final Uri correo = Uri(
      scheme: 'mailto',
      path: 'soporte.taully@gmail.com',
      queryParameters: {
        'subject': 'Consulta de soporte - Minimarket Taully',
        'body': 'Hola equipo de soporte,\n\nNecesito ayuda con...',
      },
    );

    if (await canLaunchUrl(correo)) {
      await launchUrl(correo);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo abrir el correo."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDE7),
      appBar: AppBar(
        backgroundColor: Colors.indigoAccent,
        title: const Text(
          "Soporte y Ayuda",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.support_agent_rounded,
                size: 80, color: Colors.indigoAccent),
            const SizedBox(height: 20),
            const Text(
              "¿Necesitas ayuda?",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Puedes comunicarte con nuestro equipo de soporte a través de WhatsApp o correo electrónico. 💬",
              style: TextStyle(fontSize: 15, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Botón de WhatsApp
           ElevatedButton.icon(
  icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
  label: const Text(
    "Contactar por WhatsApp",
    style: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
  ),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    minimumSize: const Size(double.infinity, 55),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  onPressed: () => _abrirWhatsApp(context),
),

            // Botón de correo electrónico
            ElevatedButton.icon(
              icon: const Icon(Icons.email_outlined, color: Colors.white),
              label: const Text(
                "Enviar correo a soporte",
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _enviarCorreo(context),
            ),
          ],
        ),
      ),
    );
  }
}
