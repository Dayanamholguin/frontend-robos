import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../servicios/servicio_permisos.dart';
import '../tema/colores_app.dart';
import '../tema/escala.dart';
import '../widgets/boton_principal.dart';
import '../widgets/indicador_pasos.dart';

// Tercer paso del recorrido inicial: pide la ubicación y revisa la conexión.
// Si el permiso ya fue concedido, muestra que ya está activo y deja continuar.
class PantallaPermisos extends StatefulWidget {
  const PantallaPermisos({super.key});

  @override
  State<PantallaPermisos> createState() => _PantallaPermisosState();
}

class _PantallaPermisosState extends State<PantallaPermisos> {
  bool _revisando = false;
  bool _ubicacionConcedida = false;

  @override
  void initState() {
    super.initState();
    _cargarEstadoUbicacion();
  }

  // Lee el permiso sin mostrar el diálogo del sistema
  Future<void> _cargarEstadoUbicacion() async {
    final concedida = await ServicioPermisos.ubicacionConcedida();
    if (!mounted) return;
    setState(() => _ubicacionConcedida = concedida);
  }

  Future<void> _permitirYContinuar() async {
    setState(() => _revisando = true);
    final resultado = await ServicioPermisos.verificarRequisitos();

    if (!mounted) return;
    setState(() => _revisando = false);

    switch (resultado) {
      case ResultadoPermisos.listo:
        Navigator.of(context).pushReplacementNamed('/ingreso');
      case ResultadoPermisos.sinConexion:
        _mostrarAviso(
          'No hay conexión a internet. Conéctate a Wi-Fi o a datos móviles para continuar.',
        );
      case ResultadoPermisos.gpsApagado:
        _mostrarAviso(
          'Activa el GPS para continuar.',
          accion: 'Ajustes',
          alPresionarAccion: Geolocator.openLocationSettings,
        );
      case ResultadoPermisos.ubicacionDenegada:
        _mostrarAviso('Necesitamos tu ubicación para continuar.');
      case ResultadoPermisos.ubicacionDenegadaSiempre:
        _mostrarAviso(
          'El permiso de ubicación está bloqueado. Actívalo en los ajustes del teléfono.',
          accion: 'Ajustes',
          alPresionarAccion: Geolocator.openAppSettings,
        );
    }
  }

  void _mostrarAviso(
    String mensaje, {
    String? accion,
    VoidCallback? alPresionarAccion,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        action: accion == null || alPresionarAccion == null
            ? null
            : SnackBarAction(label: accion, onPressed: alPresionarAccion),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titulo = _ubicacionConcedida
        ? 'Permisos activos'
        : 'Activa tu ubicación';
    final descripcion = _ubicacionConcedida
        ? 'Ya diste los permisos que necesita AppRobos. Puedes continuar.'
        : 'AppRobos necesita estos permisos para mostrarte el riesgo donde estás.';
    final textoBoton = _revisando
        ? 'Revisando...'
        : _ubicacionConcedida
        ? 'Continuar'
        : 'Permitir y continuar';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            Escala.de(context, 28),
            Escala.de(context, 40),
            Escala.de(context, 28),
            Escala.de(context, 40),
          ),
          child: Column(
            children: [
              SvgPicture.asset(
                'assets/svg/ilustracion_permisos.svg',
                width: Escala.de(context, 140),
                height: Escala.de(context, 150),
              ),
              SizedBox(height: Escala.de(context, 28)),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: Escala.de(context, 24),
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: ColoresApp.verdeTexto,
                ),
              ),
              SizedBox(height: Escala.de(context, 12)),
              Text(
                descripcion,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: Escala.de(context, 15),
                  height: 1.5,
                  color: ColoresApp.verdeTexto,
                ),
              ),
              SizedBox(height: Escala.de(context, 32)),
              _TarjetaRequisito(
                icono: 'assets/svg/icono_ubicacion.svg',
                titulo: 'Ubicación en tiempo real',
                descripcion: 'Para el mapa, el riesgo y las alertas',
                etiqueta: _ubicacionConcedida ? 'Activo' : 'Obligatorio',
              ),
              SizedBox(height: Escala.de(context, 12)),
              const _TarjetaRequisito(
                icono: 'assets/svg/icono_internet.svg',
                titulo: 'Conexión a internet',
                descripcion: 'Para consultar y enviar reportes',
                etiqueta: 'Obligatorio',
              ),
              SizedBox(height: Escala.de(context, 32)),
              Align(
                alignment: Alignment.centerRight,
                child: BotonPrincipal(
                  texto: textoBoton,
                  alPresionar: _revisando ? null : _permitirYContinuar,
                ),
              ),
              SizedBox(height: Escala.de(context, 28)),
              const IndicadorPasos(total: 3, actual: 2),
            ],
          ),
        ),
      ),
    );
  }
}

// Tarjeta blanca con el icono, el nombre del requisito y su etiqueta (Obligatorio o Activo).
class _TarjetaRequisito extends StatelessWidget {
  const _TarjetaRequisito({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.etiqueta,
  });

  final String icono;
  final String titulo;
  final String descripcion;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Escala.de(context, 16)),
      decoration: BoxDecoration(
        color: ColoresApp.blanco,
        borderRadius: BorderRadius.circular(Escala.de(context, 16)),
      ),
      child: Row(
        children: [
          Container(
            width: Escala.de(context, 44),
            height: Escala.de(context, 44),
            decoration: BoxDecoration(
              color: ColoresApp.verdeIcono,
              borderRadius: BorderRadius.circular(Escala.de(context, 12)),
            ),
            child: Center(
              child: SvgPicture.asset(
                icono,
                width: Escala.de(context, 22),
                height: Escala.de(context, 22),
              ),
            ),
          ),
          SizedBox(width: Escala.de(context, 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.poppins(
                    fontSize: Escala.de(context, 15),
                    fontWeight: FontWeight.w600,
                    color: ColoresApp.verdeOscuro,
                  ),
                ),
                Text(
                  descripcion,
                  style: GoogleFonts.poppins(
                    fontSize: Escala.de(context, 13),
                    color: ColoresApp.grisTexto,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: Escala.de(context, 8)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Escala.de(context, 8),
              vertical: Escala.de(context, 4),
            ),
            decoration: BoxDecoration(
              color: ColoresApp.verdeEtiqueta,
              borderRadius: BorderRadius.circular(Escala.de(context, 8)),
            ),
            child: Text(
              etiqueta,
              style: GoogleFonts.poppins(
                fontSize: Escala.de(context, 12),
                fontWeight: FontWeight.w600,
                color: ColoresApp.verdeTexto,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
