import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tema/colores_app.dart';
import '../tema/escala.dart';
import '../widgets/boton_principal.dart';
import '../widgets/indicador_pasos.dart';

// Segundo paso del recorrido inicial: explica para qué sirve el mapa de riesgo.
// El texto queda centrado en el espacio disponible y los botones quedan fijos abajo.
class PantallaDescubre extends StatelessWidget {
  const PantallaDescubre({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El mapa empieza en el borde superior del celular, detrás de la barra de estado
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(
              height:
                  Escala.de(context, 170) + MediaQuery.paddingOf(context).top,
              width: double.infinity,
              child: SvgPicture.asset(
                'assets/svg/mapa_descubre.svg',
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
            // Área central: el texto se centra aquí y, si la pantalla es corta, se desplaza
            Expanded(
              child: LayoutBuilder(
                builder: (context, restricciones) => SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: Escala.de(context, 36),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: restricciones.maxHeight,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Conoce el riesgo de tu zona',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: Escala.de(context, 24),
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: ColoresApp.verdeTexto,
                            ),
                          ),
                          SizedBox(height: Escala.de(context, 14)),
                          Text(
                            'Mira en el mapa los hurtos que otros ciudadanos reportaron cerca de ti y recibe alertas.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: Escala.de(context, 15),
                              height: 1.5,
                              color: ColoresApp.verdeTexto,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Pie fijo: botón e indicador siempre abajo
            Padding(
              padding: EdgeInsets.fromLTRB(
                Escala.de(context, 28),
                0,
                Escala.de(context, 28),
                Escala.de(context, 40),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  BotonPrincipal(
                    texto: 'Continuar',
                    alPresionar: () =>
                        Navigator.of(context).pushNamed('/permisos'),
                  ),
                  SizedBox(height: Escala.de(context, 28)),
                  const Center(child: IndicadorPasos(total: 3, actual: 1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
