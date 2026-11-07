import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../servicios/configuracion_api.dart';
import '../servicios/servicio_autenticacion.dart';

// Qué se sabe del territorio de un punto del mapa.
enum EstadoTerritorio {
  conDatos,
  sinBarrio,
  fueraDeArea,
  sesionVencida,
  sinRespuesta,
}

class UbicacionTerritorio {
  const UbicacionTerritorio({
    required this.estado,
    this.municipio,
    this.barrio,
  });

  final EstadoTerritorio estado;
  final String? municipio;
  final String? barrio;
}

// Consultas del mapa a la API: territorio del punto, nombre del usuario y ubicación del teléfono.
class ServicioMapa {
  ServicioMapa({http.Client? cliente, ServicioAutenticacion? autenticacion})
    : _cliente = cliente ?? http.Client(),
      _autenticacion = autenticacion ?? ServicioAutenticacion();

  static const _tiempoMaximo = Duration(seconds: 15);

  final http.Client _cliente;
  final ServicioAutenticacion _autenticacion;

  Future<bool> tieneSesion() async =>
      (await _autenticacion.leerToken()) != null;

  // Ubicación actual del teléfono. Devuelve null si el GPS está apagado o no hay permiso.
  Future<Position?> ubicacionActual() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    final permiso = await Geolocator.checkPermission();
    if (permiso != LocationPermission.whileInUse &&
        permiso != LocationPermission.always) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // Municipio y barrio del punto. Consume GET /api/territorio/ubicacion.
  Future<UbicacionTerritorio> territorioEn(
    double latitud,
    double longitud,
  ) async {
    final token = await _autenticacion.leerToken();
    if (token == null) {
      return const UbicacionTerritorio(estado: EstadoTerritorio.sesionVencida);
    }

    try {
      final respuesta = await _cliente
          .get(
            Uri.parse('$urlApi/api/territorio/ubicacion').replace(
              queryParameters: {'latitud': '$latitud', 'longitud': '$longitud'},
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_tiempoMaximo);

      switch (respuesta.statusCode) {
        case 200:
          final cuerpo = jsonDecode(respuesta.body) as Map<String, dynamic>;
          final municipio = cuerpo['municipioNombre'] as String?;
          final barrio = cuerpo['barrioNombre'] as String?;
          if (barrio == null) {
            return UbicacionTerritorio(
              estado: EstadoTerritorio.sinBarrio,
              municipio: municipio,
            );
          }
          return UbicacionTerritorio(
            estado: EstadoTerritorio.conDatos,
            municipio: municipio,
            barrio: barrio,
          );
        case 422:
          return const UbicacionTerritorio(
            estado: EstadoTerritorio.fueraDeArea,
          );
        case 401:
          return const UbicacionTerritorio(
            estado: EstadoTerritorio.sesionVencida,
          );
        default:
          return const UbicacionTerritorio(
            estado: EstadoTerritorio.sinRespuesta,
          );
      }
    } on SocketException {
      return const UbicacionTerritorio(estado: EstadoTerritorio.sinRespuesta);
    } on TimeoutException {
      return const UbicacionTerritorio(estado: EstadoTerritorio.sinRespuesta);
    } on http.ClientException {
      return const UbicacionTerritorio(estado: EstadoTerritorio.sinRespuesta);
    } on FormatException {
      return const UbicacionTerritorio(estado: EstadoTerritorio.sinRespuesta);
    }
  }

  // Nombre del ciudadano con la sesión activa. Consume GET /api/autenticacion/perfil.
  Future<String?> nombreUsuario() async {
    final token = await _autenticacion.leerToken();
    if (token == null) return null;

    try {
      final respuesta = await _cliente
          .get(
            Uri.parse('$urlApi/api/autenticacion/perfil'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_tiempoMaximo);
      if (respuesta.statusCode != 200) return null;
      final cuerpo = jsonDecode(respuesta.body) as Map<String, dynamic>;
      return cuerpo['nombre'] as String?;
    } on SocketException {
      return null;
    } on TimeoutException {
      return null;
    } on http.ClientException {
      return null;
    } on FormatException {
      return null;
    }
  }
}
