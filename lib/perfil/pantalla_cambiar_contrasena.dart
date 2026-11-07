import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../servicios/servicio_autenticacion.dart';
import '../tema/colores_app.dart';
import '../tema/escala.dart';
import '../validacion/validadores.dart';
import '../widgets/boton_principal.dart';
import '../widgets/campo_texto.dart';
import '../widgets/dialogo_descartar.dart';
import '../widgets/requisitos_contrasena.dart';
import 'servicio_perfil.dart';

// Ventana para cambiar la contraseña. Si el usuario intenta salir con cambios sin guardar,
// se le avisa que se descartarán. Al cambiarla, la API cierra todas las sesiones.
class PantallaCambiarContrasena extends StatefulWidget {
  const PantallaCambiarContrasena({super.key});

  @override
  State<PantallaCambiarContrasena> createState() =>
      _PantallaCambiarContrasenaState();
}

class _PantallaCambiarContrasenaState extends State<PantallaCambiarContrasena> {
  final _formulario = GlobalKey<FormState>();
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();
  final _focoNueva = FocusNode();
  final _perfil = ServicioPerfil();
  final _autenticacion = ServicioAutenticacion();

  bool _guardando = false;
  String? _errorGeneral;

  @override
  void initState() {
    super.initState();
    _focoNueva.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _confirmar.dispose();
    _focoNueva.dispose();
    super.dispose();
  }

  // Hay cambios cuando algún campo tiene texto
  bool get _hayCambios =>
      _actual.text.isNotEmpty ||
      _nueva.text.isNotEmpty ||
      _confirmar.text.isNotEmpty;

  Future<void> _guardar() async {
    if (_guardando) return;
    if (!(_formulario.currentState?.validate() ?? false)) return;

    setState(() {
      _guardando = true;
      _errorGeneral = null;
    });

    final resultado = await _perfil.cambiarContrasena(
      contrasenaActual: _actual.text,
      contrasenaNueva: _nueva.text,
    );
    if (!mounted) return;

    if (resultado.sesionVencida) {
      await _autenticacion.cerrarSesionLocal();
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/ingreso', (ruta) => false);
      return;
    }

    if (!resultado.exitoso) {
      setState(() {
        _guardando = false;
        _errorGeneral =
            resultado.mensaje ?? 'No se pudo cambiar la contraseña.';
      });
      return;
    }

    // La API cerró todas las sesiones: el token guardado ya no sirve y se pide iniciar sesión de nuevo
    await _autenticacion.cerrarSesionLocal();
    if (!mounted) return;
    await _avisarInicioDeNuevo();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/ingreso', (ruta) => false);
  }

  Future<void> _avisarInicioDeNuevo() {
    return showDialog<void>(
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
                'Contraseña cambiada',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: Escala.de(contexto, 20),
                  fontWeight: FontWeight.w700,
                  color: ColoresApp.verdeTexto,
                ),
              ),
              SizedBox(height: Escala.de(contexto, 8)),
              Text(
                'Tu contraseña se cambió. Inicia sesión de nuevo.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: Escala.de(contexto, 14),
                  height: 1.45,
                  color: ColoresApp.grisEtiqueta,
                ),
              ),
              SizedBox(height: Escala.de(contexto, 20)),
              BotonPrincipal(
                texto: 'Entendido',
                compacto: true,
                alPresionar: () => Navigator.of(contexto).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reglas = Validadores.reglasContrasena(_nueva.text);
    final cumplidas = reglas.where((regla) => regla.cumple).length;
    // Los requisitos solo se muestran mientras se escribe la nueva contraseña y todavía no se cumplen
    final mostrarRequisitos =
        _focoNueva.hasFocus &&
        _nueva.text.isNotEmpty &&
        cumplidas < reglas.length;

    return PopScope(
      canPop: !_hayCambios,
      onPopInvokedWithResult: (didPop, resultado) async {
        if (didPop) return;
        final salir = await confirmarDescartarCambios(context);
        if (salir && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              Escala.de(context, 24),
              Escala.de(context, 20),
              Escala.de(context, 24),
              Escala.de(context, 32),
            ),
            child: Form(
              key: _formulario,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          width: Escala.de(context, 44),
                          height: Escala.de(context, 44),
                          decoration: BoxDecoration(
                            color: ColoresApp.blanco,
                            borderRadius: BorderRadius.circular(
                              Escala.de(context, 14),
                            ),
                          ),
                          child: Icon(
                            Icons.chevron_left,
                            size: Escala.de(context, 26),
                            color: ColoresApp.verdeTexto,
                          ),
                        ),
                      ),
                      SizedBox(width: Escala.de(context, 16)),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Cambiar contraseña',
                            maxLines: 1,
                            style: GoogleFonts.poppins(
                              fontSize: Escala.de(context, 26),
                              fontWeight: FontWeight.w700,
                              color: ColoresApp.verdeTexto,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Escala.de(context, 8)),
                  Text(
                    'Cerrará la sesión en todos tus dispositivos.',
                    style: GoogleFonts.poppins(
                      fontSize: Escala.de(context, 14),
                      color: ColoresApp.grisEtiqueta,
                    ),
                  ),
                  SizedBox(height: Escala.de(context, 24)),
                  CampoTexto(
                    compacto: true,
                    etiqueta: 'Contraseña actual',
                    controlador: _actual,
                    pista: 'Tu contraseña actual',
                    ocultar: true,
                    longitudMaxima: 100,
                    validador: Validadores.contrasenaSimple,
                    alCambiar: (_) => setState(() {}),
                  ),
                  SizedBox(height: Escala.de(context, 14)),
                  CampoTexto(
                    compacto: true,
                    etiqueta: 'Contraseña nueva',
                    controlador: _nueva,
                    focusNode: _focoNueva,
                    pista: 'Crea una contraseña',
                    ocultar: true,
                    longitudMaxima: 100,
                    validador: Validadores.contrasenaNueva,
                    alCambiar: (_) => setState(() {}),
                  ),
                  if (mostrarRequisitos) ...[
                    SizedBox(height: Escala.de(context, 8)),
                    IndicadorFortaleza(
                      cumplidas: cumplidas,
                      total: reglas.length,
                    ),
                    SizedBox(height: Escala.de(context, 6)),
                    for (final regla in reglas)
                      RequisitoContrasena(regla: regla),
                  ],
                  SizedBox(height: Escala.de(context, 14)),
                  CampoTexto(
                    compacto: true,
                    etiqueta: 'Confirmar contraseña nueva',
                    controlador: _confirmar,
                    pista: 'Escribe la contraseña nueva otra vez',
                    ocultar: true,
                    longitudMaxima: 100,
                    alCambiar: (_) => setState(() {}),
                    validador: (valor) {
                      if (valor == null || valor.isEmpty) {
                        return 'Vuelve a escribir la contraseña nueva.';
                      }
                      if (valor != _nueva.text) {
                        return 'Las contraseñas no coinciden.';
                      }
                      return null;
                    },
                  ),
                  if (_errorGeneral != null) ...[
                    SizedBox(height: Escala.de(context, 18)),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: Escala.de(context, 14),
                        vertical: Escala.de(context, 12),
                      ),
                      decoration: BoxDecoration(
                        color: ColoresApp.fondoError,
                        borderRadius: BorderRadius.circular(
                          Escala.de(context, 12),
                        ),
                      ),
                      child: Text(
                        _errorGeneral!,
                        style: GoogleFonts.poppins(
                          fontSize: Escala.de(context, 13),
                          height: 1.45,
                          color: ColoresApp.textoError,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: Escala.de(context, 28)),
                  SizedBox(
                    width: double.infinity,
                    child: BotonPrincipal(
                      texto: _guardando ? 'Cambiando...' : 'Cambiar contraseña',
                      alPresionar: _guardando ? null : _guardar,
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
