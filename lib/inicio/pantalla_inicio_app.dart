import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../servicios/servicio_autenticacion.dart';
import '../servicios/servicio_permisos.dart';
import '../tema/colores_app.dart';
import '../tema/escala.dart';

// Pantalla de inicio con el logo. Pasa sola después de unos segundos, o antes si el usuario toca la pantalla.
// Si el permiso de ubicación ya está concedido, va directo al ingreso. Si no, sigue el recorrido inicial.
class PantallaInicioApp extends StatefulWidget {
  const PantallaInicioApp({super.key});

  @override
  State<PantallaInicioApp> createState() => _PantallaInicioAppState();
}

class _PantallaInicioAppState extends State<PantallaInicioApp> {
  static const _duracion = Duration(seconds: 6);

  Timer? _temporizador;
  bool _navegado = false;

  @override
  void initState() {
    super.initState();
    _temporizador = Timer(_duracion, _continuar);
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  // Decide la siguiente pantalla una sola vez, aunque el temporizador y el toque ocurran juntos
  Future<void> _continuar() async {
    if (_navegado || !mounted) return;
    _navegado = true;
    _temporizador?.cancel();

    // Si la sesión sigue vigente, entra directo al mapa sin pasar por el login
    if (await ServicioAutenticacion().sesionVigente()) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/mapa');
      return;
    }

    final tienePermiso = await ServicioPermisos.ubicacionConcedida();
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacementNamed(tienePermiso ? '/ingreso' : '/bienvenida');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresApp.verdeBoton,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _continuar,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Escala.de(context, 24),
                vertical: Escala.de(context, 40),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/svg/logo_inicio.svg',
                    width: Escala.de(context, 64),
                    height: Escala.de(context, 64),
                  ),
                  SizedBox(height: Escala.de(context, 18)),
                  // FittedBox reduce el texto si no cabe en una sola línea
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: Escala.de(context, 46),
                          letterSpacing: 1,
                          height: 1,
                        ),
                        children: const [
                          TextSpan(
                            text: 'APP',
                            style: TextStyle(color: ColoresApp.textoClaro),
                          ),
                          TextSpan(
                            text: 'ROBOS',
                            style: TextStyle(color: ColoresApp.verdeClaro),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                  SizedBox(height: Escala.de(context, 18)),
                  Text(
                    'Medellín y Valle de Aburrá',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: Escala.de(context, 14),
                      color: ColoresApp.verdeEtiqueta,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
