import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tema/colores_app.dart';
import '../tema/escala.dart';
import '../widgets/boton_principal.dart';
import '../widgets/campo_texto.dart';

// Pide la contraseña otra vez antes de crear la cuenta.
// Devuelve true solo si lo que se escribe coincide con la contraseña de la pantalla.
// Los dos botones van uno debajo del otro, a todo el ancho: Confirmar arriba y Cancelar abajo.
class DialogoConfirmarContrasena extends StatefulWidget {
  const DialogoConfirmarContrasena({super.key, required this.contrasena});

  final String contrasena;

  @override
  State<DialogoConfirmarContrasena> createState() =>
      _DialogoConfirmarContrasenaState();
}

class _DialogoConfirmarContrasenaState
    extends State<DialogoConfirmarContrasena> {
  final _formulario = GlobalKey<FormState>();
  final _confirmacion = TextEditingController();

  @override
  void dispose() {
    _confirmacion.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (_formulario.currentState?.validate() ?? false) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColoresApp.fondo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Escala.de(context, 20)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(Escala.de(context, 24)),
            child: Form(
              key: _formulario,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Confirma tu contraseña',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: Escala.de(context, 20),
                      fontWeight: FontWeight.w700,
                      color: ColoresApp.verdeTexto,
                    ),
                  ),
                  SizedBox(height: Escala.de(context, 8)),
                  Text(
                    'Vuelve a escribir la contraseña para crear tu cuenta.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: Escala.de(context, 14),
                      height: 1.45,
                      color: ColoresApp.grisEtiqueta,
                    ),
                  ),
                  SizedBox(height: Escala.de(context, 20)),
                  CampoTexto(
                    compacto: true,
                    etiqueta: 'Contraseña',
                    controlador: _confirmacion,
                    pista: 'Escribe la contraseña otra vez',
                    ocultar: true,
                    longitudMaxima: 100,
                    validador: (valor) {
                      if (valor == null || valor.isEmpty) {
                        return 'Vuelve a escribir la contraseña.';
                      }
                      if (valor != widget.contrasena) {
                        return 'Las contraseñas no coinciden.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: Escala.de(context, 20)),
                  SizedBox(
                    width: double.infinity,
                    child: BotonPrincipal(
                      texto: 'Confirmar',
                      compacto: true,
                      alPresionar: _confirmar,
                    ),
                  ),
                  SizedBox(height: Escala.de(context, 8)),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancelar',
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: Escala.de(context, 14),
                          fontWeight: FontWeight.w600,
                          color: ColoresApp.verdeTexto,
                        ),
                      ),
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
