import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tema/colores_app.dart';
import '../tema/escala.dart';

// Logo y nombre de la app, igual que en la pantalla de inicio: ícono y APPROBOS en una sola línea.
class LogoApprobos extends StatelessWidget {
  const LogoApprobos({super.key, this.oscuro = false});

  // Versión verde oscuro para la capa sin conexión. La pantalla de inicio usa la versión clara.
  final bool oscuro;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          oscuro
              ? 'assets/svg/logo_sin_conexion.svg'
              : 'assets/svg/logo_inicio.svg',
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
              children: [
                TextSpan(
                  text: 'APP',
                  style: TextStyle(color: ColoresApp.textoClaro),
                ),
                TextSpan(
                  text: 'ROBOS',
                  style: TextStyle(
                    color: oscuro
                        ? ColoresApp.verdeBoton
                        : ColoresApp.verdeClaro,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ],
    );
  }
}
