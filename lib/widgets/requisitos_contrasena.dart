import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tema/colores_app.dart';
import '../tema/escala.dart';
import '../validacion/validadores.dart';

// Barras que se llenan según los requisitos de la contraseña que ya se cumplen
class IndicadorFortaleza extends StatelessWidget {
  const IndicadorFortaleza({
    super.key,
    required this.cumplidas,
    required this.total,
  });

  final int cumplidas;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (indice) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: indice == total - 1 ? 0 : Escala.de(context, 4),
            ),
            height: Escala.de(context, 4),
            decoration: BoxDecoration(
              color: indice < cumplidas
                  ? ColoresApp.verdeBoton
                  : ColoresApp.barraVacia,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

// Requisito de la contraseña con su marca de cumplido
class RequisitoContrasena extends StatelessWidget {
  const RequisitoContrasena({super.key, required this.regla});

  final ReglaContrasena regla;

  @override
  Widget build(BuildContext context) {
    final color = regla.cumple ? ColoresApp.verdeBoton : ColoresApp.grisTexto;
    return Padding(
      padding: EdgeInsets.only(top: Escala.de(context, 2)),
      child: Row(
        children: [
          Icon(
            regla.cumple ? Icons.check_circle : Icons.radio_button_unchecked,
            size: Escala.de(context, 14),
            color: color,
          ),
          SizedBox(width: Escala.de(context, 6)),
          Text(
            regla.texto,
            style: GoogleFonts.poppins(
              fontSize: Escala.de(context, 12),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
