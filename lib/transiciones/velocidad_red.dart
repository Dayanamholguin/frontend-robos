import 'package:http/http.dart' as http;

import '../servicios/configuracion_api.dart';

// Mide qué tan rápida es la red hablando con la API.
// Si la respuesta tarda más de lo normal, las pantallas se muestran sin animación.
class VelocidadRed {
  const VelocidadRed._();

  // Por defecto se asume red rápida hasta que se mida
  static bool rapida = true;

  static const _umbral = Duration(milliseconds: 1200);

  // Hace una petición corta a la API y guarda si la respuesta llegó a tiempo.
  static Future<void> medir() async {
    final inicio = DateTime.now();
    try {
      await http
          .get(Uri.parse('$urlApi/api/catalogos/municipios'))
          .timeout(const Duration(seconds: 5));
      rapida = DateTime.now().difference(inicio) < _umbral;
    } catch (_) {
      rapida = false;
    }
  }
}
