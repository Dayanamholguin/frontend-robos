import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../servicios/servicio_autenticacion.dart';
import '../tema/colores_app.dart';
import '../tema/escala.dart';
import '../validacion/validadores.dart';
import '../widgets/boton_principal.dart';
import '../widgets/campo_texto.dart';
import '../widgets/requisitos_contrasena.dart';
import '../widgets/campo_sexo.dart';
import '../widgets/campo_telefono.dart';
import 'dialogo_confirmar_contrasena.dart';

// Pantalla para crear una cuenta de ciudadano. Consume POST /api/autenticacion/registro.
// Cada campo se revisa al salir de él. Al tocar "Crear cuenta" se revisan todos y se pide
// confirmar la contraseña.
class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  // Valores de las opciones de sexo/género que espera la API
  static const _sexos = {
    'Femenino': 'FEMENINO',
    'Masculino': 'MASCULINO',
    'Prefiero no decirlo': 'PREFIERO_NO_DECIR',
  };

  static const _mensajeCorreoRepetido = 'Ese correo ya tiene una cuenta.';
  static const _mensajeTelefonoRepetido = 'Ese celular ya tiene una cuenta.';

  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _telefono = TextEditingController();
  final _fecha = TextEditingController();
  final _focoContrasena = FocusNode();
  final _focoCorreo = FocusNode();
  final _servicio = ServicioAutenticacion();

  DateTime? _fechaNacimiento;
  String? _sexo;
  bool _enviando = false;
  String? _errorGeneral;

  // Resultado de la última consulta del correo: true si ya tiene una cuenta
  bool _correoOcupado = false;

  // Resultado de la última consulta del celular: true si ya tiene una cuenta
  bool _telefonoOcupado = false;

  @override
  void initState() {
    super.initState();
    // Los requisitos de la contraseña aparecen o desaparecen según el foco del campo
    _focoContrasena.addListener(() => setState(() {}));
    // Al salir del correo se consulta si ya está registrado
    _focoCorreo.addListener(() {
      if (!_focoCorreo.hasFocus) _revisarCorreo();
    });
  }

  @override
  void dispose() {
    for (final controlador in [
      _nombre,
      _apellido,
      _correo,
      _contrasena,
      _telefono,
      _fecha,
    ]) {
      controlador.dispose();
    }
    _focoContrasena.dispose();
    _focoCorreo.dispose();
    super.dispose();
  }

  // Consulta a la API si el correo está libre. Si no hay respuesta, no bloquea el registro.
  Future<void> _revisarCorreo() async {
    final correo = _correo.text.trim();
    if (Validadores.correo(correo) != null) return;

    final disponible = await _servicio.correoDisponible(correo);
    if (!mounted || disponible == null) return;
    // Si el correo cambió mientras se consultaba, el resultado ya no aplica
    if (_correo.text.trim() != correo) return;

    setState(() => _correoOcupado = !disponible);
  }

  // Consulta a la API si el celular está libre. Si no hay respuesta, no bloquea el registro.
  Future<void> _revisarTelefono() async {
    final digitos = Validadores.soloDigitos(_telefono.text);
    if (Validadores.telefono(_telefono.text) != null) return;

    final disponible = await _servicio.telefonoDisponible(digitos);
    if (!mounted || disponible == null) return;
    // Si el número cambió mientras se consultaba, el resultado ya no aplica
    if (Validadores.soloDigitos(_telefono.text) != digitos) return;

    setState(() => _telefonoOcupado = !disponible);
  }

  // Revisa la fecha con el calendario del sistema, con los colores del diseño.
  // Solo deja elegir fechas que correspondan a una edad entre 18 y 100 años.
  Future<void> _elegirFecha() async {
    final limites = Validadores.limitesFechaNacimiento();
    final inicial = _fechaNacimiento ?? limites.maxima;

    final elegida = await showDatePicker(
      context: context,
      initialDate: inicial.isBefore(limites.minima)
          ? limites.minima
          : (inicial.isAfter(limites.maxima) ? limites.maxima : inicial),
      firstDate: limites.minima,
      lastDate: limites.maxima,
      locale: const Locale('es', 'CO'),
      builder: (context, hijo) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: ColoresApp.verdeBoton,
            onPrimary: ColoresApp.blanco,
            surface: ColoresApp.blanco,
            onSurface: ColoresApp.verdeOscuro,
          ),
        ),
        child: hijo!,
      ),
    );

    if (elegida == null) return;
    setState(() {
      _fechaNacimiento = elegida;
      _fecha.text = _formatearFecha(elegida);
    });
  }

  String _formatearFecha(DateTime fecha) {
    String dosDigitos(int valor) => valor.toString().padLeft(2, '0');
    return '${dosDigitos(fecha.day)}/${dosDigitos(fecha.month)}/${fecha.year}';
  }

  // Quita espacios repetidos y espacios de los extremos
  String _limpiar(String texto) => texto.trim().replaceAll(RegExp(r'\s+'), ' ');

  Future<void> _crearCuenta() async {
    if (_enviando) return;

    // Al enviar se revisan todos los campos y se marcan los que tienen error
    if (!(_formulario.currentState?.validate() ?? false)) return;

    // Antes de crear la cuenta se vuelve a confirmar que el correo esté libre
    final disponible = await _servicio.correoDisponible(_correo.text.trim());
    if (!mounted) return;
    if (disponible == false) {
      setState(() => _correoOcupado = true);
      return;
    }

    // Antes de crear la cuenta se vuelve a confirmar que el celular esté libre
    final telefonoLibre = await _servicio.telefonoDisponible(
      Validadores.soloDigitos(_telefono.text),
    );
    if (!mounted) return;
    if (telefonoLibre == false) {
      setState(() => _telefonoOcupado = true);
      return;
    }

    // Pide la contraseña otra vez: solo se crea la cuenta si coincide
    final confirmada = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DialogoConfirmarContrasena(contrasena: _contrasena.text),
    );
    if (!mounted || confirmada != true) return;

    setState(() {
      _enviando = true;
      _errorGeneral = null;
    });

    final correo = _correo.text.trim();
    final contrasena = _contrasena.text;

    final registro = await _servicio.registrar(
      nombre: _limpiar(_nombre.text),
      apellido: _limpiar(_apellido.text),
      correo: correo,
      contrasena: contrasena,
      telefono: Validadores.soloDigitos(_telefono.text),
      fechaNacimiento: _fechaNacimiento!,
      sexoCodigo: _sexos[_sexo]!,
    );
    if (!mounted) return;

    switch (registro) {
      case RegistroExitoso():
        // La cuenta recién creada entra directo con los mismos datos
        final login = await _servicio.iniciarSesion(correo, contrasena);
        if (!mounted) return;
        if (login is LoginExitoso) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/mapa', (ruta) => false);
          return;
        }
        setState(() {
          _enviando = false;
          _errorGeneral = 'Tu cuenta se creó. Inicia sesión para continuar.';
        });
      case RegistroCorreoRepetido(:final mensaje):
        setState(() {
          _enviando = false;
          // El mensaje de la API indica si el repetido es el celular o el correo
          if (mensaje.contains('celular')) {
            _telefonoOcupado = true;
          } else {
            _correoOcupado = true;
          }
        });
      case RegistroDatosInvalidos(:final mensaje):
        setState(() {
          _enviando = false;
          _errorGeneral = mensaje;
        });
      case RegistroSinConexion():
        setState(() {
          _enviando = false;
          _errorGeneral = 'No hay conexión con el servidor. Revisa tu Wi-Fi o tus datos móviles.';
        });
      case RegistroError(:final mensaje):
        setState(() {
          _enviando = false;
          _errorGeneral = mensaje;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reglas = Validadores.reglasContrasena(_contrasena.text);
    final cumplidas = reglas.where((regla) => regla.cumple).length;
    // Solo se muestran mientras el usuario escribe la contraseña y todavía no cumple todo
    final mostrarRequisitos =
        _focoContrasena.hasFocus &&
        _contrasena.text.isNotEmpty &&
        cumplidas < reglas.length;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            Escala.de(context, 24),
            Escala.de(context, 52),
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
                      child: Text(
                        'Crear cuenta',
                        style: GoogleFonts.poppins(
                          fontSize: Escala.de(context, 30),
                          fontWeight: FontWeight.w700,
                          color: ColoresApp.verdeTexto,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Escala.de(context, 8)),
                Text(
                  'Por una comunidad más unida',
                  style: GoogleFonts.poppins(
                    fontSize: Escala.de(context, 14),
                    color: ColoresApp.verdeTexto,
                  ),
                ),
                SizedBox(height: Escala.de(context, 24)),
                CampoTexto(
                  compacto: true,
                  etiqueta: 'Nombre',
                  controlador: _nombre,
                  pista: 'Nombre',
                  longitudMaxima: 100,
                  formateadores: [Validadores.formateadorNombre],
                  validador: (valor) =>
                      Validadores.nombre(valor, campo: 'El nombre'),
                ),
                SizedBox(height: Escala.de(context, 14)),
                CampoTexto(
                  compacto: true,
                  etiqueta: 'Apellido',
                  controlador: _apellido,
                  pista: 'Apellido',
                  longitudMaxima: 100,
                  formateadores: [Validadores.formateadorNombre],
                  validador: (valor) =>
                      Validadores.nombre(valor, campo: 'El apellido'),
                ),
                SizedBox(height: Escala.de(context, 14)),
                CampoTexto(
                  compacto: true,
                  etiqueta: 'Correo electrónico',
                  controlador: _correo,
                  focusNode: _focoCorreo,
                  pista: 'nombre@correo.com',
                  tipoTeclado: TextInputType.emailAddress,
                  longitudMaxima: 255,
                  formateadores: [Validadores.formateadorCorreo],
                  validador: Validadores.correo,
                  errorExterno: _correoOcupado ? _mensajeCorreoRepetido : null,
                  alCambiar: (_) {
                    if (_correoOcupado) setState(() => _correoOcupado = false);
                  },
                ),
                SizedBox(height: Escala.de(context, 4)),
                Text(
                  'No podrás cambiarlo después',
                  style: GoogleFonts.poppins(
                    fontSize: Escala.de(context, 12),
                    color: ColoresApp.grisTexto,
                  ),
                ),
                SizedBox(height: Escala.de(context, 14)),
                CampoTexto(
                  compacto: true,
                  etiqueta: 'Contraseña',
                  controlador: _contrasena,
                  focusNode: _focoContrasena,
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
                  for (final regla in reglas) RequisitoContrasena(regla: regla),
                ],
                SizedBox(height: Escala.de(context, 14)),
                CampoTelefono(
                  controlador: _telefono,
                  validador: Validadores.telefono,
                  errorExterno: _telefonoOcupado
                      ? _mensajeTelefonoRepetido
                      : null,
                  alSalir: _revisarTelefono,
                  alEscribir: () {
                    if (_telefonoOcupado) {
                      setState(() => _telefonoOcupado = false);
                    }
                  },
                ),
                SizedBox(height: Escala.de(context, 14)),
                CampoTexto(
                  compacto: true,
                  etiqueta: 'Fecha de nacimiento',
                  controlador: _fecha,
                  pista: 'DD/MM/AAAA',
                  soloLectura: true,
                  alTocar: _elegirFecha,
                  sufijo: Icon(
                    Icons.calendar_month_outlined,
                    size: Escala.de(context, 20),
                    color: ColoresApp.verdeBoton,
                  ),
                  validador: (_) =>
                      Validadores.fechaNacimiento(_fechaNacimiento),
                ),
                SizedBox(height: Escala.de(context, 14)),
                CampoSexo(
                  valor: _sexo,
                  opciones: _sexos.keys.toList(),
                  alCambiar: (valor) => setState(() => _sexo = valor),
                ),
                if (_errorGeneral != null) ...[
                  SizedBox(height: Escala.de(context, 18)),
                  Container(
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
                    texto: _enviando ? 'Creando cuenta...' : 'Crear cuenta',
                    alPresionar: _enviando ? null : _crearCuenta,
                  ),
                ),
                SizedBox(height: Escala.de(context, 16)),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes cuenta? ',
                        style: GoogleFonts.poppins(
                          fontSize: Escala.de(context, 14),
                          color: ColoresApp.grisEtiqueta,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Text(
                          'Inicia sesión',
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
