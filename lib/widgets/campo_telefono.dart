import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tema/colores_app.dart';
import '../tema/escala.dart';
import '../validacion/validadores.dart';

// Campo de teléfono: el prefijo +57 queda fijo a la izquierda y el número a la derecha.
// El error aparece debajo de todo el bloque, no solo debajo del número.
class CampoTelefono extends StatefulWidget {
  const CampoTelefono({
    super.key,
    required this.controlador,
    required this.validador,
    this.cargando = false,
    this.errorExterno,
    this.alSalir,
    this.alEscribir,
  });

  final TextEditingController controlador;
  final String? Function(String?) validador;
  // Mensaje que viene de la consulta a la API (por ejemplo, celular ya registrado)
  final String? errorExterno;
  final VoidCallback? alSalir;
  final VoidCallback? alEscribir;
  final bool cargando;

  @override
  State<CampoTelefono> createState() => _CampoTelefonoState();
}

class _CampoTelefonoState extends State<CampoTelefono> {
  final _foco = FocusNode();
  final _campo = GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    super.initState();
    // Se revisa al salir del campo, igual que los demás
    _foco.addListener(() {
      if (!_foco.hasFocus) {
        _campo.currentState?.validate();
        widget.alSalir?.call();
      }
    });
  }

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radio = Radius.circular(Escala.de(context, 12));

    return FormField<String>(
      key: _campo,
      validator: (_) => widget.validador(widget.controlador.text),
      builder: (estado) {
        // El error de la validación local o el que viene de la API
        final error = estado.errorText ?? widget.errorExterno;
        final tieneError = error != null;
        final colorBorde = tieneError
            ? ColoresApp.textoError
            : ColoresApp.bordeCampo;
        final borde = BorderSide(color: colorBorde, width: 1.5);
        final bordeEnfoque = BorderSide(
          color: tieneError ? ColoresApp.textoError : ColoresApp.verdeBoton,
          width: 1.5,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Teléfono',
              style: GoogleFonts.poppins(
                fontSize: Escala.de(context, 13),
                fontWeight: FontWeight.w500,
                color: ColoresApp.textoCampo,
              ),
            ),
            SizedBox(height: Escala.de(context, 6)),
            IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Escala.de(context, 12),
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ColoresApp.verdeIcono,
                      border: Border(top: borde, bottom: borde, left: borde),
                      borderRadius: BorderRadius.horizontal(left: radio),
                    ),
                    child: Text(
                      '+57',
                      style: GoogleFonts.poppins(
                        fontSize: Escala.de(context, 14),
                        fontWeight: FontWeight.w600,
                        color: ColoresApp.textoCampo,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.controlador,
                      focusNode: _foco,
                      onChanged: (_) => widget.alEscribir?.call(),
                      readOnly: widget.cargando,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        const FormateadorTelefono(),
                      ],
                      style: GoogleFonts.poppins(
                        fontSize: Escala.de(context, 14),
                        color: ColoresApp.textoCampo,
                      ),
                      decoration: InputDecoration(
                        suffixIcon: widget.cargando
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
                        hintText: '(3XX) XXX - XXXX',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: Escala.de(context, 14),
                          color: ColoresApp.placeholderCampo,
                        ),
                        filled: true,
                        fillColor: ColoresApp.blanco,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: Escala.de(context, 12),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.horizontal(right: radio),
                          borderSide: borde,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.horizontal(right: radio),
                          borderSide: borde,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.horizontal(right: radio),
                          borderSide: bordeEnfoque,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (tieneError) ...[
              SizedBox(height: Escala.de(context, 6)),
              Text(
                error,
                style: GoogleFonts.poppins(
                  fontSize: Escala.de(context, 12),
                  color: ColoresApp.textoError,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
