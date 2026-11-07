import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'configuracion_api.dart';

// Resultado de intentar iniciar sesión.
sealed class ResultadoLogin {
  const ResultadoLogin();
}

class LoginExitoso extends ResultadoLogin {
  const LoginExitoso();
}

// Correo o contraseña incorrectos (401).
class LoginCredencialesInvalidas extends ResultadoLogin {
  const LoginCredencialesInvalidas(this.mensaje);

  final String mensaje;
}

// La cuenta está bloqueada temporalmente (423). Trae la fecha en que se desbloquea.
class LoginBloqueada extends ResultadoLogin {
  const LoginBloqueada(this.bloqueadaHasta);

  final DateTime? bloqueadaHasta;
}

// La cuenta está deshabilitada o inactiva (403).
class LoginCuentaNoDisponible extends ResultadoLogin {
  const LoginCuentaNoDisponible(this.mensaje);

  final String mensaje;
}

// Datos que la API no acepta (400) o demasiados intentos (429).
class LoginError extends ResultadoLogin {
  const LoginError(this.mensaje);

  final String mensaje;
}

// No hay conexión con la API.
class LoginSinConexion extends ResultadoLogin {
  const LoginSinConexion();
}

// Resultado de crear una cuenta.
sealed class ResultadoRegistro {
  const ResultadoRegistro();
}

class RegistroExitoso extends ResultadoRegistro {
  const RegistroExitoso();
}

// El correo ya tiene una cuenta (409).
class RegistroCorreoRepetido extends ResultadoRegistro {
  const RegistroCorreoRepetido(this.mensaje);

  final String mensaje;
}

// La API rechazó algún dato (400).
class RegistroDatosInvalidos extends ResultadoRegistro {
  const RegistroDatosInvalidos(this.mensaje);

  final String mensaje;
}

class RegistroSinConexion extends ResultadoRegistro {
  const RegistroSinConexion();
}

class RegistroError extends ResultadoRegistro {
  const RegistroError(this.mensaje);

  final String mensaje;
}

// Inicio de sesión y registro contra la API. El token se guarda en el almacenamiento seguro del teléfono.
class ServicioAutenticacion {
  ServicioAutenticacion({http.Client? cliente, FlutterSecureStorage? almacen})
    : _cliente = cliente ?? http.Client(),
      _almacen = almacen ?? const FlutterSecureStorage();

  static const _claveToken = 'token_sesion';
  static const _claveExpiracion = 'token_expira_en';
  static const _tiempoMaximo = Duration(seconds: 15);

  final http.Client _cliente;
  final FlutterSecureStorage _almacen;

  // Borra el token guardado en el teléfono
  Future<void> cerrarSesionLocal() async {
    await _almacen.delete(key: _claveToken);
    await _almacen.delete(key: _claveExpiracion);
  }

  // Devuelve el token guardado, o null si no hay sesión
  Future<String?> leerToken() => _almacen.read(key: _claveToken);

  // Indica si hay un token guardado que todavía no venció.
  Future<bool> sesionVigente() async {
    final token = await _almacen.read(key: _claveToken);
    final expiraTexto = await _almacen.read(key: _claveExpiracion);
    final expira = expiraTexto == null ? null : DateTime.tryParse(expiraTexto);
    return token != null && expira != null && expira.isAfter(DateTime.now());
  }

  Future<ResultadoLogin> iniciarSesion(String correo, String contrasena) async {
    final http.Response respuesta;
    try {
      respuesta = await _enviar('/api/autenticacion/login', {
        'correo': correo,
        'contrasena': contrasena,
      });
    } on _SinConexion {
      return const LoginSinConexion();
    }

    final cuerpo = _leerCuerpo(respuesta.body);

    switch (respuesta.statusCode) {
      case 200:
        final token = cuerpo['token'] as String?;
        final expira = cuerpo['expiraEn'] as String?;
        if (token == null) {
          return const LoginError('La respuesta del servidor no trae sesión.');
        }
        await _guardarSesion(token, expira);
        return const LoginExitoso();
      case 401:
        return LoginCredencialesInvalidas(
          _mensajeDetalle(cuerpo, 'Correo o contraseña incorrectos.'),
        );
      case 403:
        return LoginCuentaNoDisponible(
          _mensajeDetalle(cuerpo, 'La cuenta no está disponible.'),
        );
      case 423:
        return LoginBloqueada(_fechaBloqueo(cuerpo));
      case 429:
        return const LoginError(
          'Demasiados intentos. Espera un momento e inténtalo de nuevo.',
        );
      case 400:
        return LoginError(
          _mensajeValidacion(cuerpo, 'Revisa los datos e inténtalo de nuevo.'),
        );
      default:
        return const LoginError(
          'No se pudo iniciar sesión. Inténtalo de nuevo más tarde.',
        );
    }
  }

  // Pregunta a la API si el correo está libre. Devuelve null si no se pudo consultar.
  Future<bool?> correoDisponible(String correo) async {
    try {
      final respuesta = await _cliente
          .get(
            Uri.parse('$urlApi/api/autenticacion/correo-disponible')
                .replace(queryParameters: {'correo': correo}),
          )
          .timeout(_tiempoMaximo);
      if (respuesta.statusCode != 200) return null;
      final cuerpo = _leerCuerpo(respuesta.body);
      return cuerpo['disponible'] as bool?;
    } on SocketException {
      return null;
    } on TimeoutException {
      return null;
    } on http.ClientException {
      return null;
    }
  }

  // Pregunta a la API si el celular está libre. Devuelve null si no se pudo consultar.
  Future<bool?> telefonoDisponible(String digitos) async {
    try {
      final respuesta = await _cliente
          .get(
            Uri.parse('$urlApi/api/autenticacion/telefono-disponible')
                .replace(queryParameters: {'telefono': digitos}),
          )
          .timeout(_tiempoMaximo);
      if (respuesta.statusCode != 200) return null;
      final cuerpo = _leerCuerpo(respuesta.body);
      return cuerpo['disponible'] as bool?;
    } on SocketException {
      return null;
    } on TimeoutException {
      return null;
    } on http.ClientException {
      return null;
    }
  }

  // Crea la cuenta. Si se crea bien, el llamador inicia sesión con los mismos datos.
  Future<ResultadoRegistro> registrar({
    required String nombre,
    required String apellido,
    required String correo,
    required String contrasena,
    required String telefono,
    required DateTime fechaNacimiento,
    required String sexoCodigo,
  }) async {
    final http.Response respuesta;
    try {
      respuesta = await _enviar('/api/autenticacion/registro', {
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'contrasena': contrasena,
        'telefono': telefono,
        'fechaNacimiento': _fechaIso(fechaNacimiento),
        'sexoCodigo': sexoCodigo,
      });
    } on _SinConexion {
      return const RegistroSinConexion();
    }

    final cuerpo = _leerCuerpo(respuesta.body);

    switch (respuesta.statusCode) {
      case 201:
        return const RegistroExitoso();
      case 409:
        return RegistroCorreoRepetido(
          _mensajeDetalle(cuerpo, 'Ese correo ya tiene una cuenta.'),
        );
      case 400:
        return RegistroDatosInvalidos(
          _mensajeValidacion(cuerpo, 'Revisa los datos e inténtalo de nuevo.'),
        );
      default:
        return const RegistroError(
          'No se pudo crear la cuenta. Inténtalo de nuevo más tarde.',
        );
    }
  }

  // Envía una petición JSON a la API con tiempo máximo. Si no hay red, lanza _SinConexion.
  Future<http.Response> _enviar(String ruta, Map<String, dynamic> datos) async {
    try {
      return await _cliente
          .post(
            Uri.parse('$urlApi$ruta'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(datos),
          )
          .timeout(_tiempoMaximo);
    } on SocketException {
      throw const _SinConexion();
    } on TimeoutException {
      throw const _SinConexion();
    } on http.ClientException {
      throw const _SinConexion();
    }
  }

  Future<void> _guardarSesion(String token, String? expiraEn) async {
    await _almacen.write(key: _claveToken, value: token);
    if (expiraEn != null) {
      await _almacen.write(key: _claveExpiracion, value: expiraEn);
    }
  }

  // Fecha en formato AAAA-MM-DD, el que espera la API
  String _fechaIso(DateTime fecha) {
    String dosDigitos(int valor) => valor.toString().padLeft(2, '0');
    return '${fecha.year}-${dosDigitos(fecha.month)}-${dosDigitos(fecha.day)}';
  }

  // Lee el cuerpo JSON de la respuesta. Si no es JSON, devuelve un mapa vacío.
  Map<String, dynamic> _leerCuerpo(String texto) {
    try {
      final decodificado = jsonDecode(texto);
      return decodificado is Map<String, dynamic> ? decodificado : {};
    } on FormatException {
      return {};
    }
  }

  // Toma el detalle del ProblemDetails o el mensaje por defecto.
  String _mensajeDetalle(Map<String, dynamic> cuerpo, String porDefecto) {
    final detalle = cuerpo['detail'] as String?;
    return (detalle == null || detalle.isEmpty) ? porDefecto : detalle;
  }

  // Los errores de validación llegan en "errors": { campo: [mensajes] }. Se muestra el primero.
  String _mensajeValidacion(Map<String, dynamic> cuerpo, String porDefecto) {
    final errores = cuerpo['errors'];
    if (errores is Map<String, dynamic> && errores.isNotEmpty) {
      final primero = errores.values.first;
      if (primero is List && primero.isNotEmpty) {
        return primero.first.toString();
      }
    }
    return _mensajeDetalle(cuerpo, porDefecto);
  }

  // La API envía bloqueadaHasta en UTC; se convierte a la hora local del teléfono.
  DateTime? _fechaBloqueo(Map<String, dynamic> cuerpo) {
    final texto = cuerpo['bloqueadaHasta'] as String?;
    return texto == null ? null : DateTime.tryParse(texto)?.toLocal();
  }
}

// Error interno: no hay conexión con la API.
class _SinConexion implements Exception {
  const _SinConexion();
}
