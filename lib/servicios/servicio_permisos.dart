import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';

// Resultado de revisar los requisitos para usar la app.
enum ResultadoPermisos {
  listo,
  sinConexion,
  gpsApagado,
  ubicacionDenegada,
  ubicacionDenegadaSiempre,
}

// Revisa la conexión a la red y el permiso de ubicación.
// La app no guarda estos permisos: el sistema del teléfono los guarda y la app los consulta.
class ServicioPermisos {
  // Indica si el permiso de ubicación ya fue concedido, sin mostrar el diálogo del sistema.
  static Future<bool> ubicacionConcedida() async {
    final permiso = await Geolocator.checkPermission();
    return permiso == LocationPermission.whileInUse ||
        permiso == LocationPermission.always;
  }

  // Revisa la conexión primero. Después revisa el GPS y pide el permiso de ubicación si falta.
  static Future<ResultadoPermisos> verificarRequisitos() async {
    if (!await _hayConexion()) {
      return ResultadoPermisos.sinConexion;
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      return ResultadoPermisos.gpsApagado;
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.deniedForever) {
      return ResultadoPermisos.ubicacionDenegadaSiempre;
    }

    final concedido =
        permiso == LocationPermission.whileInUse ||
        permiso == LocationPermission.always;
    return concedido
        ? ResultadoPermisos.listo
        : ResultadoPermisos.ubicacionDenegada;
  }

  // Wi-Fi, datos móviles o cable de red cuentan como conexión.
  static Future<bool> _hayConexion() async {
    final conexiones = await Connectivity().checkConnectivity();
    return conexiones.any(
      (conexion) =>
          conexion == ConnectivityResult.wifi ||
          conexion == ConnectivityResult.mobile ||
          conexion == ConnectivityResult.ethernet,
    );
  }
}
