import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tema/colores_app.dart';
import '../tema/escala.dart';

// Botón principal de las pantallas de bienvenida y permisos.
// Si alPresionar es null, el botón queda deshabilitado.
class BotonPrincipal extends StatelessWidget {
  const BotonPrincipal({
    super.key,
    required this.texto,
    required this.alPresionar,
    this.compacto = false,
  });

  final String texto;
  final VoidCallback? alPresionar;

  // Botón más chico para ventanas y espacios reducidos
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: alPresionar,
      style: FilledButton.styleFrom(
        backgroundColor: ColoresApp.verdeBoton,
        foregroundColor: ColoresApp.blanco,
        minimumSize: Size(0, Escala.de(context, compacto ? 42 : 52)),
        padding: EdgeInsets.symmetric(
          horizontal: Escala.de(context, compacto ? 16 : 28),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Escala.de(context, 14)),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: Escala.de(context, compacto ? 14 : 16),
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(texto, maxLines: 1, textAlign: TextAlign.center),
    );
  }
}
