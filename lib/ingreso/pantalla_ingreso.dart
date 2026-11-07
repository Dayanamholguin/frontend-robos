import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../servicios/servicio_autenticacion.dart';
import '../tema/colores_app.dart';
import '../tema/escala.dart';
import '../validacion/validadores.dart';
import '../widgets/boton_principal.dart';
import '../widgets/campo_texto.dart';

// Pantalla de inicio de sesión. Consume POST /api/autenticacion/login.
class PantallaIngreso extends StatefulWidget {
  const PantallaIngreso({super.key});

  @override
  State<PantallaIngreso> createState() => _PantallaIngresoState();
}

class _PantallaIngresoState extends State<PantallaIngreso> {
  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _servicio = ServicioAutenticacion();

  bool _enviando = false;
  String? _errorGeneral;

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    if (!(_formulario.currentState?.validate() ?? false)) return;

    setState(() {
      _enviando = true;
      _errorGeneral = null;
    });

    final resultado = await _servicio.iniciarSesion(
      _correo.text.trim(),
      _contrasena.text,
    );
    if (!mounted) return;
    setState(() => _enviando = false);

    switch (resultado) {
      case LoginExitoso():
        Navigator.of(context).pushReplacementNamed('/mapa');
      case LoginCredencialesInvalidas(:final mensaje):
        setState(() => _errorGeneral = mensaje);
      case LoginBloqueada(:final bloqueadaHasta):
        setState(
          () => _errorGeneral = bloqueadaHasta == null
              ? 'Tu cuenta está bloqueada temporalmente.'
              : 'Tu cuenta está bloqueada hasta ${_formatearFecha(bloqueadaHasta)}.',
        );
      case LoginCuentaNoDisponible(:final mensaje):
        setState(() => _errorGeneral = mensaje);
      case LoginError(:final mensaje):
        setState(() => _errorGeneral = mensaje);
      case LoginSinConexion():
        setState(
          () => _errorGeneral = 'No hay conexión con el servidor. Revisa tu Wi-Fi o tus datos móviles.',
        );
    }
  }

  // Fecha en formato día/mes/año hora:minuto, en la hora local del teléfono
  String _formatearFecha(DateTime fecha) {
    String dosDigitos(int valor) => valor.toString().padLeft(2, '0');
    return '${dosDigitos(fecha.day)}/${dosDigitos(fecha.month)}/${fecha.year} '
        '${dosDigitos(fecha.hour)}:${dosDigitos(fecha.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            Escala.de(context, 28),
            Escala.de(context, 88),
            Escala.de(context, 28),
            Escala.de(context, 40),
          ),
          child: Form(
            key: _formulario,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Marca(),
                SizedBox(height: Escala.de(context, 36)),
                Text(
                  'Iniciar sesión',
                  style: GoogleFonts.poppins(
                    fontSize: Escala.de(context, 34),
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: ColoresApp.verdeTexto,
                  ),
                ),
                SizedBox(height: Escala.de(context, 8)),
                Text(
                  'Ingresa con tu correo registrado',
                  style: GoogleFonts.poppins(
                    fontSize: Escala.de(context, 15),
                    color: ColoresApp.verdeTexto,
                  ),
                ),
                SizedBox(height: Escala.de(context, 36)),
                CampoTexto(
                  etiqueta: 'Correo',
                  controlador: _correo,
                  pista: 'nombre@correo.com',
                  tipoTeclado: TextInputType.emailAddress,
                  formateadores: [Validadores.formateadorCorreo],
                  validador: Validadores.correo,
                ),
                SizedBox(height: Escala.de(context, 18)),
                CampoTexto(
                  etiqueta: 'Contraseña',
                  controlador: _contrasena,
                  pista: 'Tu contraseña',
                  ocultar: true,
                  validador: Validadores.contrasenaSimple,
                ),
                SizedBox(height: Escala.de(context, 18)),
                const _AvisoBloqueo(),
                if (_errorGeneral != null) ...[
                  SizedBox(height: Escala.de(context, 18)),
                  _AvisoError(mensaje: _errorGeneral!),
                ],
                SizedBox(height: Escala.de(context, 36)),
                SizedBox(
                  width: double.infinity,
                  child: BotonPrincipal(
                    texto: _enviando ? 'Ingresando...' : 'Ingresar',
                    alPresionar: _enviando ? null : _ingresar,
                  ),
                ),
                SizedBox(height: Escala.de(context, 18)),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        '¿No tienes cuenta? ',
                        style: GoogleFonts.poppins(
                          fontSize: Escala.de(context, 14),
                          color: ColoresApp.grisEtiqueta,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            Navigator.of(context).pushNamed('/registro'),
                        child: Text(
                          'Crear cuenta',
                          style: GoogleFonts.poppins(
                            fontSize: Escala.de(context, 14),
                            fontWeight: FontWeight.w600,
                            color: ColoresApp.verdeTexto,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Logo en texto: APP en verde oscuro y ROBOS en verde claro
class _Marca extends StatelessWidget {
  const _Marca();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          style: GoogleFonts.poppins(
            fontSize: Escala.de(context, 22),
            letterSpacing: 1,
          ),
          children: const [
            TextSpan(
              text: 'APP',
              style: TextStyle(color: ColoresApp.verdeBoton),
            ),
            TextSpan(
              text: 'ROBOS',
              style: TextStyle(color: ColoresApp.verdeMarca),
            ),
          ],
        ),
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}

// Aviso fijo del diseño sobre el bloqueo después de 3 intentos
class _AvisoBloqueo extends StatelessWidget {
  const _AvisoBloqueo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Escala.de(context, 14),
        vertical: Escala.de(context, 12),
      ),
      decoration: BoxDecoration(
        color: ColoresApp.fondoAviso,
        borderRadius: BorderRadius.circular(Escala.de(context, 12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: Escala.de(context, 18),
            color: ColoresApp.verdeTexto,
          ),
          SizedBox(width: Escala.de(context, 10)),
          Expanded(
            child: Text(
              'Después de 3 intentos fallidos tu cuenta se bloquea por un tiempo.',
              style: GoogleFonts.poppins(
                fontSize: Escala.de(context, 12.5),
                height: 1.45,
                color: ColoresApp.textoAviso,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Aviso de error que devuelve la API o la conexión
class _AvisoError extends StatelessWidget {
  const _AvisoError({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Escala.de(context, 14),
        vertical: Escala.de(context, 12),
      ),
      decoration: BoxDecoration(
        color: ColoresApp.fondoError,
        borderRadius: BorderRadius.circular(Escala.de(context, 12)),
      ),
      child: Text(
        mensaje,
        style: GoogleFonts.poppins(
          fontSize: Escala.de(context, 13),
          height: 1.45,
          color: ColoresApp.textoError,
        ),
      ),
    );
  }
}
