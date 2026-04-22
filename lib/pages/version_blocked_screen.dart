// lib/pages/version_blocked_screen.dart
import 'package:flutter/material.dart';
import '../pages/config/app_config.dart';

class VersionBlockedScreen extends StatelessWidget {
  final String mensaje;
  final String? minVersion;

  const VersionBlockedScreen({
    super.key,
    required this.mensaje,
    this.minVersion,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 80,
                  color: Colors.orange,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Actualización requerida',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  mensaje,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Versión instalada: $kAppVersion',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                if (minVersion != null)
                  Text(
                    'Versión mínima requerida: $minVersion',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    // Aquí podrías usar url_launcher para abrir Play Store o la web
                    // de momento solo cierra la app o muestra el mensaje
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
