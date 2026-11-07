import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tema/colores_app.dart';
import '../tema/escala.dart';
import 'boton_principal.dart';

// Alerta antes de salir con cambios sin guardar. Solo tiene una opción: "Estoy de acuerdo".
// Tocar fuera de la ventana no la cierra; así el usuario se queda en la sección si no acepta.
Future<bool> confirmarDescartarCambios(BuildContext context) async {
  final resultado = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (contexto) => Dialog(
      backgroundColor: ColoresApp.fondo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Escala.de(contexto, 20)),
      ),
      child: Padding(
        padding: EdgeInsets.all(Escala.de(contexto, 24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¿Descartar cambios?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: Escala.de(contexto, 20),
                fontWeight: FontWeight.w700,
                color: ColoresApp.verdeTexto,
              ),
            ),
            SizedBox(height: Escala.de(contexto, 8)),
            Text(
              'Si sales de esta ventana, se descartarán los cambios que no guardaste.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: Escala.de(contexto, 14),
                height: 1.45,
                color: ColoresApp.grisEtiqueta,
              ),
            ),
            SizedBox(height: Escala.de(contexto, 20)),
            BotonPrincipal(
              texto: 'Estoy de acuerdo',
              compacto: true,
              alPresionar: () => Navigator.of(contexto).pop(true),
            ),
          ],
        ),
      ),
    ),
  );
  return resultado ?? false;
}
