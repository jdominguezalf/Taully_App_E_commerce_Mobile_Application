// lib/utils/version_checker.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../pages/config/app_config.dart';

class VersionCheckResult {
  final bool isAllowed;
  final String message;
  final String? minVersion;

  VersionCheckResult({
    required this.isAllowed,
    required this.message,
    this.minVersion,
  });
}

class VersionChecker {
  static Future<VersionCheckResult> checkVersion() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('configuracion')
          .doc('app')
          .get();

      if (!doc.exists) {
        // Si no hay config, no bloqueamos nada
        return VersionCheckResult(
          isAllowed: true,
          message: '',
        );
      }

      final data = doc.data() ?? {};
      final String minVersion = (data['min_version'] ?? '') as String;
      final String mensaje = (data['mensaje'] ??
              'Actualiza Taully para continuar usando el sistema.')
          as String;

      if (minVersion.isEmpty) {
        return VersionCheckResult(
          isAllowed: true,
          message: '',
        );
      }

      final bool ok = _isVersionGreaterOrEqual(kAppVersion, minVersion);

      return VersionCheckResult(
        isAllowed: ok,
        message: mensaje,
        minVersion: minVersion,
      );
    } catch (e) {
      // Si algo falla (sin internet, etc.) NO bloqueamos
      return VersionCheckResult(
        isAllowed: true,
        message: '',
      );
    }
  }

  /// Compara versiones del tipo x.y.z
  static bool _isVersionGreaterOrEqual(String current, String min) {
    final c = current.split('.').map(int.parse).toList();
    final m = min.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (c[i] > m[i]) return true;
      if (c[i] < m[i]) return false;
    }
    return true; // iguales
  }
}
