import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tema/colores_app.dart';
import '../tema/escala.dart';
import '../widgets/boton_principal.dart';
import '../widgets/indicador_pasos.dart';

// Primer paso del recorrido inicial: presentación de la app.
class PantallaBienvenida extends StatelessWidget {
  const PantallaBienvenida({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              right: -Escala.de(context, 40),
              bottom: Escala.de(context, 120),
              child: SvgPicture.asset(
                'assets/svg/ilustracion_bienvenida.svg',
                width: Escala.de(context, 360),
                height: Escala.de(context, 460),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                Escala.de(context, 28),
                Escala.de(context, 72),
                Escala.de(context, 28),
                Escala.de(context, 40),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Bienvenido',
                      maxLines: 1,
                      style: GoogleFonts.poppins(
                        fontSize: Escala.de(context, 50),
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                        color: ColoresApp.verdeTexto,
                      ),
                    ),
                  ),
                  SizedBox(height: Escala.de(context, 14)),
                  SizedBox(
                    width: Escala.de(context, 210),
                    child: Text(
                      'Nos alegra que estés aquí. Juntos cuidamos el barrio.',
                      style: GoogleFonts.poppins(
                        fontSize: Escala.de(context, 16),
                        height: 1.4,
                        color: ColoresApp.verdeTexto,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: BotonPrincipal(
                      texto: 'Empecemos',
                      alPresionar: () =>
                          Navigator.of(context).pushNamed('/descubre'),
                    ),
                  ),
                  SizedBox(height: Escala.de(context, 28)),
                  const Center(child: IndicadorPasos(total: 3, actual: 0)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
