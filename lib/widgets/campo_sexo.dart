import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tema/colores_app.dart';
import '../tema/escala.dart';

// Lista desplegable de sexo/género con el mismo estilo de los campos
class CampoSexo extends StatelessWidget {
  const CampoSexo({
    super.key,
    required this.valor,
    required this.opciones,
    required this.alCambiar,
    this.cargando = false,
  });

  final String? valor;
  final List<String> opciones;
  final ValueChanged<String?> alCambiar;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Escala.de(context, 12)),
      borderSide: const BorderSide(color: ColoresApp.bordeCampo, width: 1.5),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sexo / género',
          style: GoogleFonts.poppins(
            fontSize: Escala.de(context, 13),
            fontWeight: FontWeight.w500,
            color: ColoresApp.textoCampo,
          ),
        ),
        SizedBox(height: Escala.de(context, 6)),
        DropdownButtonFormField<String>(
          initialValue: valor,
          isExpanded: true,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          hint: Text(
            'Selecciona',
            style: GoogleFonts.poppins(
              fontSize: Escala.de(context, 14),
              color: ColoresApp.placeholderCampo,
            ),
          ),
          style: GoogleFonts.poppins(
            fontSize: Escala.de(context, 14),
            color: ColoresApp.textoCampo,
          ),
          decoration: InputDecoration(
            suffixIcon: cargando
                ? Padding(
                    padding: EdgeInsets.all(Escala.de(context, 12)),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ColoresApp.verdeBoton,
                      ),
                    ),
                  )
                : null,
            filled: true,
            fillColor: ColoresApp.blanco,
            contentPadding: EdgeInsets.symmetric(
              horizontal: Escala.de(context, 12),
            ),
            border: borde,
            enabledBorder: borde,
            focusedBorder: borde.copyWith(
              borderSide: const BorderSide(
                color: ColoresApp.verdeBoton,
                width: 1.5,
              ),
            ),
          ),
          items: [
            for (final opcion in opciones)
              DropdownMenuItem(value: opcion, child: Text(opcion)),
          ],
          validator: (valorElegido) =>
              valorElegido == null ? 'Elige una opción.' : null,
          onChanged: cargando ? null : alCambiar,
        ),
      ],
    );
  }
}
