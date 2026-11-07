import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tema/colores_app.dart';
import '../tema/escala.dart';
import '../validacion/validadores.dart';

// Campo de texto con etiqueta y el estilo del diseño.
// Revisa el contenido mientras el usuario escribe y bloquea los caracteres peligrosos.
class CampoTexto extends StatelessWidget {
  const CampoTexto({
    super.key,
    required this.etiqueta,
    required this.controlador,
    required this.pista,
    required this.validador,
    this.tipoTeclado,
    this.ocultar = false,
    this.formateadores = const [],
    this.alCambiar,
    this.prefijo,
    this.sufijo,
    this.longitudMaxima,
    this.soloLectura = false,
    this.alTocar,
    this.cargando = false,
    this.compacto = false,
    this.focusNode,
    this.errorExterno,
  });

  // Mensaje que viene de una revisión externa (por ejemplo, el correo ya registrado)
  final String? errorExterno;

  // Por defecto el campo se revisa cuando el usuario sale de él, no mientras escribe
  final FocusNode? focusNode;

  // Versión más pequeña del diseño de registro: etiqueta 13, texto 14 y bordes de 12
  final bool compacto;

  final String etiqueta;
  final TextEditingController controlador;
  final String pista;
  final String? Function(String?) validador;
  final TextInputType? tipoTeclado;
  final bool ocultar;
  final List<TextInputFormatter> formateadores;
  final ValueChanged<String>? alCambiar;
  final Widget? prefijo;
  final Widget? sufijo;
  final int? longitudMaxima;
  final bool soloLectura;
  final VoidCallback? alTocar;
  // Mientras llegan los datos, el campo muestra un indicador pequeño dentro del valor
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final radio = compacto ? 12.0 : 14.0;
    final tamanoTexto = compacto ? 14.0 : 15.0;
    final tamanoEtiqueta = compacto ? 13.0 : 14.0;
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Escala.de(context, radio)),
      borderSide: const BorderSide(color: ColoresApp.bordeCampo, width: 1.5),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: GoogleFonts.poppins(
            fontSize: Escala.de(context, tamanoEtiqueta),
            fontWeight: FontWeight.w500,
            color: ColoresApp.textoCampo,
          ),
        ),
        SizedBox(height: Escala.de(context, 6)),
        TextFormField(
          controller: controlador,
          focusNode: focusNode,
          autovalidateMode: AutovalidateMode.onUnfocus,
          obscureText: ocultar,
          readOnly: soloLectura || cargando,
          onTap: alTocar,
          keyboardType: tipoTeclado,
          maxLength: longitudMaxima,
          // Oculta el contador de caracteres que agrega maxLength
          buildCounter: (
            _, {
            required currentLength,
            required isFocused,
            maxLength,
          }) => null,
          validator: validador,
          onChanged: alCambiar,
          inputFormatters: [Validadores.formateadorSeguro, ...formateadores],
          style: GoogleFonts.poppins(
            fontSize: Escala.de(context, tamanoTexto),
            color: ColoresApp.textoCampo,
          ),
          decoration: InputDecoration(
            hintText: pista,
            hintStyle: GoogleFonts.poppins(
              fontSize: Escala.de(context, tamanoTexto),
              color: ColoresApp.placeholderCampo,
            ),
            prefix: prefijo,
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
                : sufijo,
            filled: true,
            fillColor: ColoresApp.blanco,
            contentPadding: EdgeInsets.symmetric(
              horizontal: Escala.de(context, 16),
            ),
            border: borde,
            enabledBorder: borde,
            focusedBorder: borde.copyWith(
              borderSide: const BorderSide(
                color: ColoresApp.verdeBoton,
                width: 1.5,
              ),
            ),
            errorBorder: borde.copyWith(
              borderSide: const BorderSide(
                color: ColoresApp.textoError,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: borde.copyWith(
              borderSide: const BorderSide(
                color: ColoresApp.textoError,
                width: 1.5,
              ),
            ),
            errorStyle: GoogleFonts.poppins(
              fontSize: Escala.de(context, 12),
              color: ColoresApp.textoError,
            ),
            errorText: errorExterno,
          ),
        ),
      ],
    );
  }
}
