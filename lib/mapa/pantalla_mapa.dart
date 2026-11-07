import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../tema/colores_app.dart';
import '../tema/escala.dart';
import '../widgets/barra_navegacion.dart';
import 'servicio_mapa.dart';

// Pantalla principal: mapa con la ubicación del ciudadano, su zona y los reportes cercanos.
class PantallaMapa extends StatefulWidget {
  const PantallaMapa({super.key});

  @override
  State<PantallaMapa> createState() => _PantallaMapaState();
}

class _PantallaMapaState extends State<PantallaMapa> {
  // Centro de Medellín, que se muestra si no hay ubicación
  static const _medellin = LatLng(6.2442, -75.5812);
  static const _zoomCercano = 15.0;
  static const _zoomGeneral = 13.0;

  final _mapa = MapController();
  final _servicio = ServicioMapa();

  bool _buscando = true;
  String? _nombre;
  LatLng? _miPosicion;
  UbicacionTerritorio? _territorio;
  String? _avisoUbicacion;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!await _servicio.tieneSesion()) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/ingreso');
      return;
    }

    final nombre = _servicio.nombreUsuario();
    final posicion = await _servicio.ubicacionActual();
    final nombreResuelto = await nombre;
    if (!mounted) return;

    if (posicion == null) {
      setState(() {
        _nombre = nombreResuelto;
        _buscando = false;
        _avisoUbicacion = 'No pudimos obtener tu ubicación. Revisa que el GPS esté activo y que la app tenga permiso.';
      });
      return;
    }

    final punto = LatLng(posicion.latitude, posicion.longitude);
    final territorio = await _servicio.territorioEn(
      punto.latitude,
      punto.longitude,
    );
    if (!mounted) return;

    setState(() {
      _nombre = nombreResuelto;
      _miPosicion = punto;
      _territorio = territorio;
      _buscando = false;
    });

    // El mapa se centra en la ubicación una vez que ya está construido
    try {
      _mapa.move(punto, _zoomCercano);
    } catch (_) {
      // Si el mapa todavía no está listo, queda en el centro inicial
    }
  }

  // Línea de saludo: "Hola, nombre" o "Hola" si no se conoce el nombre
  String get _saludo => _nombre == null ? 'Hola' : 'Hola, $_nombre';

  // Barrio y municipio, o el aviso que corresponde a la ubicación
  String get _lineaUbicacion {
    if (_buscando) return 'Buscando tu ubicación...';
    if (_miPosicion == null) return 'Tu ubicación';
    final territorio = _territorio;
    if (territorio == null) return 'Tu ubicación';
    switch (territorio.estado) {
      case EstadoTerritorio.conDatos:
        return '${territorio.barrio} · ${territorio.municipio}';
      case EstadoTerritorio.sinBarrio:
        return territorio.municipio ?? 'Tu ubicación';
      case EstadoTerritorio.fueraDeArea:
        return 'Fuera del área metropolitana';
      case EstadoTerritorio.sesionVencida:
        return 'Inicia sesión de nuevo';
      case EstadoTerritorio.sinRespuesta:
        return 'Tu ubicación';
    }
  }

  // Mensaje del panel de riesgo. Como todavía no hay registros, se explica por qué no hay datos.
  String get _mensajeRiesgo {
    if (_buscando) return 'Buscando tu ubicación...';
    if (_miPosicion == null) {
      return 'Activa tu ubicación para ver el riesgo de tu zona.';
    }
    final estado = _territorio?.estado;
    if (estado == EstadoTerritorio.fueraDeArea) {
      return 'Esta zona no está habilitada en la app.';
    }
    return 'Todavía no hay registros de hurtos en tu zona. Cuando los ciudadanos reporten hechos cerca, aquí verás el nivel de riesgo.';
  }

  // Mensaje de la sección de reportes cercanos
  String get _mensajeReportes {
    if (_buscando) return 'Buscando reportes cerca de ti...';
    if (_miPosicion == null) {
      return 'Activa tu ubicación para ver los reportes cerca de ti.';
    }
    if (_territorio?.estado == EstadoTerritorio.fueraDeArea) {
      return 'Esta zona no está habilitada en la app.';
    }
    return 'Todavía no hay reportes cerca de ti. Cuando alguien reporte un hurto en tu zona, aparecerá aquí.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Encabezado(
                      saludo: _saludo,
                      ubicacion: _lineaUbicacion,
                      cargando: _buscando,
                    ),
                    _Mapa(
                      controlador: _mapa,
                      centroInicial: _miPosicion ?? _medellin,
                      zoomInicial: _miPosicion == null
                          ? _zoomGeneral
                          : _zoomCercano,
                      miPosicion: _miPosicion,
                    ),
                    if (_avisoUbicacion != null)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          Escala.de(context, 20),
                          Escala.de(context, 8),
                          Escala.de(context, 20),
                          0,
                        ),
                        child: Text(
                          _avisoUbicacion!,
                          style: GoogleFonts.poppins(
                            fontSize: Escala.de(context, 12),
                            color: ColoresApp.grisEtiqueta,
                          ),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        Escala.de(context, 20),
                        Escala.de(context, 4),
                        Escala.de(context, 20),
                        0,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '© OpenStreetMap contributors',
                          style: GoogleFonts.poppins(
                            fontSize: Escala.de(context, 10),
                            color: ColoresApp.grisTexto,
                          ),
                        ),
                      ),
                    ),
                    _PanelRiesgo(mensaje: _mensajeRiesgo),
                    _SeccionReportes(mensaje: _mensajeReportes),
                    SizedBox(height: Escala.de(context, 20)),
                  ],
                ),
              ),
            ),
            const BarraNavegacion(seccionActiva: SeccionApp.mapa),
          ],
        ),
      ),
    );
  }
}

// Saludo y barrio o municipio del ciudadano, con el botón de notificaciones
class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.saludo,
    required this.ubicacion,
    this.cargando = false,
  });

  final String saludo;
  final String ubicacion;
  // Mientras se busca la ubicación, el valor del barrio muestra un indicador pequeño
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Escala.de(context, 20),
        Escala.de(context, 20),
        Escala.de(context, 20),
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  saludo,
                  style: GoogleFonts.poppins(
                    fontSize: Escala.de(context, 13),
                    color: ColoresApp.grisEtiqueta,
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        ubicacion,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: Escala.de(context, 18),
                          fontWeight: FontWeight.w600,
                          color: ColoresApp.verdeOscuro,
                        ),
                      ),
                    ),
                    if (cargando) ...[
                      SizedBox(width: Escala.de(context, 8)),
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColoresApp.verdeBoton,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: Escala.de(context, 12)),
          _BotonCuadrado(icono: 'assets/svg/icono_campana.svg'),
        ],
      ),
    );
  }
}

// Mapa con la zona de 500 m alrededor del ciudadano y su ubicación
class _Mapa extends StatelessWidget {
  const _Mapa({
    required this.controlador,
    required this.centroInicial,
    required this.zoomInicial,
    required this.miPosicion,
  });

  final MapController controlador;
  final LatLng centroInicial;
  final double zoomInicial;
  final LatLng? miPosicion;

  @override
  Widget build(BuildContext context) {
    final posicion = miPosicion;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Escala.de(context, 20),
        Escala.de(context, 14),
        Escala.de(context, 20),
        0,
      ),
      child: SizedBox(
        height: Escala.de(context, 290),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Escala.de(context, 22)),
          child: Stack(
            children: [
              FlutterMap(
                mapController: controlador,
                options: MapOptions(
                  initialCenter: centroInicial,
                  initialZoom: zoomInicial,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.approbos.app',
                  ),
                  if (posicion != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: posicion,
                          radius: 500,
                          useRadiusInMeter: true,
                          color: ColoresApp.verdeBoton.withValues(alpha: 0.08),
                          borderColor: ColoresApp.verdeBoton,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  if (posicion != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: posicion,
                          radius: 9,
                          color: ColoresApp.verdeBoton,
                          borderColor: ColoresApp.blanco,
                          borderStrokeWidth: 3,
                        ),
                      ],
                    ),
                ],
              ),
              Positioned(
                left: Escala.de(context, 12),
                top: Escala.de(context, 12),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Escala.de(context, 10),
                    vertical: Escala.de(context, 6),
                  ),
                  decoration: BoxDecoration(
                    color: ColoresApp.blanco,
                    borderRadius: BorderRadius.circular(Escala.de(context, 10)),
                  ),
                  child: Text(
                    'Radio 500 m',
                    style: GoogleFonts.poppins(
                      fontSize: Escala.de(context, 12),
                      fontWeight: FontWeight.w600,
                      color: ColoresApp.verdeTexto,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: Escala.de(context, 12),
                top: Escala.de(context, 8),
                child: _BotonCuadrado(icono: 'assets/svg/icono_filtro.svg'),
              ),
              Positioned(
                left: Escala.de(context, 12),
                right: Escala.de(context, 12),
                bottom: Escala.de(context, 12),
                child: Container(
                  height: Escala.de(context, 44),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ColoresApp.verdeBoton,
                    borderRadius: BorderRadius.circular(Escala.de(context, 12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/svg/icono_buscar.svg',
                        width: Escala.de(context, 18),
                        height: Escala.de(context, 18),
                        colorFilter: const ColorFilter.mode(
                          ColoresApp.blanco,
                          BlendMode.srcIn,
                        ),
                      ),
                      SizedBox(width: Escala.de(context, 8)),
                      Flexible(
                        child: Text(
                          'Analizar otra ubicación u hora',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: Escala.de(context, 14),
                            fontWeight: FontWeight.w600,
                            color: ColoresApp.blanco,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Panel de riesgo. Sin registros todavía, muestra el mensaje en vez de un nivel.
class _PanelRiesgo extends StatelessWidget {
  const _PanelRiesgo({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        Escala.de(context, 20),
        Escala.de(context, 14),
        Escala.de(context, 20),
        0,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: Escala.de(context, 18),
        vertical: Escala.de(context, 16),
      ),
      decoration: BoxDecoration(
        color: ColoresApp.blanco,
        borderRadius: BorderRadius.circular(Escala.de(context, 20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riesgo en tu zona ahora',
            style: GoogleFonts.poppins(
              fontSize: Escala.de(context, 13),
              color: ColoresApp.grisEtiqueta,
            ),
          ),
          Text(
            'Sin datos',
            style: GoogleFonts.poppins(
              fontSize: Escala.de(context, 20),
              fontWeight: FontWeight.w700,
              color: ColoresApp.grisEtiqueta,
            ),
          ),
          SizedBox(height: Escala.de(context, 10)),
          Container(
            height: Escala.de(context, 10),
            decoration: BoxDecoration(
              color: ColoresApp.barraVacia,
              borderRadius: BorderRadius.circular(Escala.de(context, 5)),
            ),
          ),
          SizedBox(height: Escala.de(context, 10)),
          Text(
            mensaje,
            style: GoogleFonts.poppins(
              fontSize: Escala.de(context, 13),
              height: 1.45,
              color: ColoresApp.textoAviso,
            ),
          ),
          SizedBox(height: Escala.de(context, 10)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Bajo 0–19  ·  Medio 20–78  ·  Alto 79–100',
              maxLines: 1,
              style: GoogleFonts.poppins(
                fontSize: Escala.de(context, 11.5),
                color: ColoresApp.grisEtiqueta,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sección de reportes cercanos. Sin reportes todavía, muestra el mensaje.
class _SeccionReportes extends StatelessWidget {
  const _SeccionReportes({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Escala.de(context, 20),
        Escala.de(context, 16),
        Escala.de(context, 20),
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reportes recientes cerca',
            style: GoogleFonts.poppins(
              fontSize: Escala.de(context, 15),
              fontWeight: FontWeight.w600,
              color: ColoresApp.verdeOscuro,
            ),
          ),
          SizedBox(height: Escala.de(context, 8)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(Escala.de(context, 14)),
            decoration: BoxDecoration(
              color: ColoresApp.blanco,
              borderRadius: BorderRadius.circular(Escala.de(context, 16)),
            ),
            child: Text(
              mensaje,
              style: GoogleFonts.poppins(
                fontSize: Escala.de(context, 13),
                height: 1.45,
                color: ColoresApp.grisEtiqueta,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Botón cuadrado blanco con un ícono, como en el diseño
class _BotonCuadrado extends StatelessWidget {
  const _BotonCuadrado({required this.icono});

  final String icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Escala.de(context, 44),
      height: Escala.de(context, 44),
      decoration: BoxDecoration(
        color: ColoresApp.blanco,
        borderRadius: BorderRadius.circular(Escala.de(context, 14)),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        icono,
        width: Escala.de(context, 20),
        height: Escala.de(context, 20),
        colorFilter: const ColorFilter.mode(
          ColoresApp.verdeTexto,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
