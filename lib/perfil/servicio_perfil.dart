import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../servicios/configuracion_api.dart';
import '../servicios/servicio_autenticacion.dart';

// Datos personales del ciudadano, tal como los devuelve la API.
class DatosPerfil {
  const DatosPerfil({
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.telefono,
    required this.fechaNacimiento,
    required this.sexoCodigo,
  });

  final String nombre;
  final String apellido;
  final String correo;
  final String telefono;
  final DateTime fechaNacimiento;
  final String sexoCodigo;

  factory DatosPerfil.desdeJson(Map<String, dynamic> json) {
    return DatosPerfil(
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      correo: json['correo'] as String,
      telefono: json['telefono'] as String,
      fechaNacimiento: DateTime.parse(json['fechaNacimiento'] as String),
      sexoCodigo: json['sexoCodigo'] as String,
    );
  }
}

// Resultado de una operación sobre el perfil.
class ResultadoPerfil {
  const ResultadoPerfil._({
    this.datos,
    this.mensaje,
    this.sesionVencida = false,
    this.exitoso = false,
  });

  factory ResultadoPerfil.exito([DatosPerfil? datos]) =>
      ResultadoPerfil._(datos: datos, exitoso: true);

  factory ResultadoPerfil.error(String mensaje) =>
      ResultadoPerfil._(mensaje: mensaje);

  factory ResultadoPerfil.sesionVencida() => const ResultadoPerfil._(
    mensaje: 'Tu sesión venció. Inicia sesión de nuevo.',
    sesionVencida: true,
  );

  final DatosPerfil? datos;
  final String? mensaje;
  final bool sesionVencida;
  final bool exitoso;
}

// Consume la API del perfil: GET y PUT de /api/autenticacion/perfil y PUT de /perfil/contrasena.
class ServicioPerfil {
  ServicioPerfil({http.Client? cliente, ServicioAutenticacion? autenticacion})
    : _cliente = cliente ?? http.Client(),
      _autenticacion = autenticacion ?? ServicioAutenticacion();

  static const _tiempoMaximo = Duration(seconds: 15);

  final http.Client _cliente;
  final ServicioAutenticacion _autenticacion;

  Future<ResultadoPerfil> obtener() async {
    final token = await _autenticacion.leerToken();
    if (token == null) return ResultadoPerfil.sesionVencida();

    try {
      final respuesta = await _cliente
          .get(
            Uri.parse('$urlApi/api/autenticacion/perfil'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_tiempoMaximo);
      if (respuesta.statusCode == 401) return ResultadoPerfil.sesionVencida();
      if (respuesta.statusCode != 200) {
        return ResultadoPerfil.error(
          'No se pudo cargar tu perfil. Inténtalo de nuevo.',
        );
      }
      final cuerpo = jsonDecode(respuesta.body) as Map<String, dynamic>;
      return ResultadoPerfil.exito(DatosPerfil.desdeJson(cuerpo));
    } on SocketException {
      return ResultadoPerfil.error(_mensajeSinConexion);
    } on TimeoutException {
      return ResultadoPerfil.error(_mensajeSinConexion);
    } on http.ClientException {
      return ResultadoPerfil.error(_mensajeSinConexion);
    } on FormatException {
      return ResultadoPerfil.error(
        'No se pudo cargar tu perfil. Inténtalo de nuevo.',
      );
    }
  }

  Future<ResultadoPerfil> actualizar({
    required String nombre,
    required String apellido,
    required String telefono,
    required DateTime fechaNacimiento,
    required String sexoCodigo,
  }) async {
    final token = await _autenticacion.leerToken();
    if (token == null) return ResultadoPerfil.sesionVencida();

    try {
      final respuesta = await _cliente
          .put(
            Uri.parse('$urlApi/api/autenticacion/perfil'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'nombre': nombre,
              'apellido': apellido,
              'telefono': telefono,
              'fechaNacimiento': _fechaIso(fechaNacimiento),
              'sexoCodigo': sexoCodigo,
            }),
          )
          .timeout(_tiempoMaximo);

      final cuerpo = _leerCuerpo(respuesta.body);
      switch (respuesta.statusCode) {
        case 200:
          return ResultadoPerfil.exito(DatosPerfil.desdeJson(cuerpo));
        case 401:
          return ResultadoPerfil.sesionVencida();
        case 409:
          return ResultadoPerfil.error(
            _detalle(cuerpo, 'Ese celular ya tiene una cuenta.'),
          );
        case 400:
          return ResultadoPerfil.error(_mensajeValidacion(cuerpo));
        default:
          return ResultadoPerfil.error(
            'No se pudieron guardar los cambios. Inténtalo de nuevo.',
          );
      }
    } on SocketException {
      return ResultadoPerfil.error(_mensajeSinConexion);
    } on TimeoutException {
      return ResultadoPerfil.error(_mensajeSinConexion);
    } on http.ClientException {
      return ResultadoPerfil.error(_mensajeSinConexion);
    }
  }

  // Al cambiar la contraseña la API cierra todas las sesiones, incluida esta.
  Future<ResultadoPerfil> cambiarContrasena({
    required String contrasenaActual,
    required String contrasenaNueva,
  }) async {
    final token = await _autenticacion.leerToken();
    if (token == null) return ResultadoPerfil.sesionVencida();

    try {
      final respuesta = await _cliente
          .put(
            Uri.parse('$urlApi/api/autenticacion/perfil/contrasena'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'contrasenaActual': contrasenaActual,
              'contrasenaNueva': contrasenaNueva,
            }),
          )
          .timeout(_tiempoMaximo);

      final cuerpo = _leerCuerpo(respuesta.body);
      switch (respuesta.statusCode) {
        case 200:
          return ResultadoPerfil.exito();
        case 401:
          return ResultadoPerfil.sesionVencida();
        case 403:
          return ResultadoPerfil.error(
            _detalle(cuerpo, 'La contraseña actual es incorrecta.'),
          );
        case 423:
          return ResultadoPerfil.error(
            'Tu cuenta está bloqueada temporalmente por intentos fallidos.',
          );
        case 400:
          return ResultadoPerfil.error(_mensajeValidacion(cuerpo));
        default:
          return ResultadoPerfil.error(
            'No se pudo cambiar la contraseña. Inténtalo de nuevo.',
          );
      }
    } on SocketException {
      return ResultadoPerfil.error(_mensajeSinConexion);
    } on TimeoutException {
      return ResultadoPerfil.error(_mensajeSinConexion);
    } on http.ClientException {
      return ResultadoPerfil.error(_mensajeSinConexion);
    }
  }

  static const _mensajeSinConexion =
      'No hay conexión con el servidor. Revisa tu Wi-Fi o tus datos móviles.';

  String _fechaIso(DateTime fecha) {
    String dosDigitos(int valor) => valor.toString().padLeft(2, '0');
    return '${fecha.year}-${dosDigitos(fecha.month)}-${dosDigitos(fecha.day)}';
  }

  Map<String, dynamic> _leerCuerpo(String texto) {
    try {
      final decodificado = jsonDecode(texto);
      return decodificado is Map<String, dynamic> ? decodificado : {};
    } on FormatException {
      return {};
    }
  }

  String _detalle(Map<String, dynamic> cuerpo, String porDefecto) {
    final detalle = cuerpo['detail'] as String?;
    return (detalle == null || detalle.isEmpty) ? porDefecto : detalle;
  }

  String _mensajeValidacion(Map<String, dynamic> cuerpo) {
    final errores = cuerpo['errors'];
    if (errores is Map<String, dynamic> && errores.isNotEmpty) {
      final primero = errores.values.first;
      if (primero is List && primero.isNotEmpty) {
        return primero.first.toString();
      }
    }
    return _detalle(cuerpo, 'Revisa los datos e inténtalo de nuevo.');
  }
}
