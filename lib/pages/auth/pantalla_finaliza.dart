import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PantallaFinaliza extends StatelessWidget {
  const PantallaFinaliza({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Compra Exitosa 🎉',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFF9C4),
              Color(0xFFFFE082),
              Color(0xFFFFD54F),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🎬 Animación de éxito
            SizedBox(
              height: 200,
              child: Lottie.asset(
                'assets/animations/success.json',
                repeat: false,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              '¡Gracias por tu compra!',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),

            const SizedBox(height: 10),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Tu pedido ha sido recibido exitosamente y está siendo preparado con mucho cariño 💛',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 5,
              ),
              icon: const Icon(Icons.home_rounded, color: Colors.white),
              label: const Text(
                'Volver al inicio',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/perfil-cliente');
              },
              child: const Text(
                'Ver mis compras',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.brown,
                  fontSize: 15,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
