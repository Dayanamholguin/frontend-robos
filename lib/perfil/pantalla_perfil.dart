import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../servicios/servicio_autenticacion.dart';
import '../tema/colores_app.dart';
import '../tema/escala.dart';
import '../validacion/validadores.dart';
import '../widgets/barra_navegacion.dart';
import '../widgets/boton_principal.dart';
import '../widgets/campo_sexo.dart';
import '../widgets/campo_telefono.dart';
import '../widgets/campo_texto.dart';
import 'servicio_perfil.dart';

// Perfil del ciudadano. Edita los datos personales con las mismas validaciones del registro.
// El correo y el rol se muestran pero no se pueden cambiar.
class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  // Etiquetas del diseño y el código que espera la API
  static const _sexos = {
    'Femenino': 'FEMENINO',
    'Masculino': 'MASCULINO',
    'Prefiero no decirlo': 'PREFIERO_NO_DECIR',
  };

  static const _mensajeTelefonoRepetido = 'Ese celular ya tiene una cuenta.';

  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _telefono = TextEditingController();
  final _fecha = TextEditingController();
  final _perfil = ServicioPerfil();
  final _autenticacion = ServicioAutenticacion();

  bool _cargando = true;
  bool _guardando = false;
  bool _telefonoOcupado = false;
  String? _errorGeneral;
  String? _correo;
  String? _iniciales;
  String? _sexo;
  DateTime? _fechaNacimiento;

  // Teléfono guardado: si el usuario no lo cambia, no se vuelve a consultar
  String _telefonoOriginal = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _telefono.dispose();
    _fecha.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final resultado = await _perfil.obtener();
    if (!mounted) return;

    if (resultado.sesionVencida) {
      await _autenticacion.cerrarSesionLocal();
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/ingreso', (ruta) => false);
      return;
    }

    final datos = resultado.datos;
    if (datos == null) {
      setState(() {
        _cargando = false;
        _errorGeneral = resultado.mensaje;
      });
      return;
    }

    setState(() {
      _cargando = false;
      _correo = datos.correo;
      _iniciales = _calcularIniciales(datos.nombre, datos.apellido);
      _nombre.text = datos.nombre;
      _apellido.text = datos.apellido;
      _telefono.text = _formatearTelefono(datos.telefono);
      _telefonoOriginal = Validadores.soloDigitos(datos.telefono);
      _fechaNacimiento = datos.fechaNacimiento;
      _fecha.text = _formatearFecha(datos.fechaNacimiento);
      _sexo = _etiquetaDeCodigo(datos.sexoCodigo);
    });
  }

  String _calcularIniciales(String nombre, String apellido) {
    final primera = nombre.isNotEmpty ? nombre[0] : '';
    final segunda = apellido.isNotEmpty ? apellido[0] : '';
    return (primera + segunda).toUpperCase();
  }

  String? _etiquetaDeCodigo(String codigo) {
    for (final entrada in _sexos.entries) {
      if (entrada.value == codigo) return entrada.key;
    }
    return null;
  }

  // Muestra el celular con el mismo formato del registro: (312) 123 - 1234
  String _formatearTelefono(String telefono) {
    final d = Validadores.soloDigitos(telefono);
    if (d.length != 10) return d;
    return '(${d.substring(0, 3)}) ${d.substring(3, 6)} - ${d.substring(6)}';
  }

  String _formatearFecha(DateTime fecha) {
    String dosDigitos(int valor) => valor.toString().padLeft(2, '0');
    return '${dosDigitos(fecha.day)}/${dosDigitos(fecha.month)}/${fecha.year}';
  }

  // Consulta si el celular nuevo está libre. Si es el mismo que ya tenía, no se consulta.
  Future<void> _revisarTelefono() async {
    final digitos = Validadores.soloDigitos(_telefono.text);
    if (digitos == _telefonoOriginal) {
      setState(() => _telefonoOcupado = false);
      return;
    }
    if (Validadores.telefono(_telefono.text) != null) return;

    final disponible = await _autenticacion.telefonoDisponible(digitos);
    if (!mounted || disponible == null) return;
    if (Validadores.soloDigitos(_telefono.text) != digitos) return;

    setState(() => _telefonoOcupado = !disponible);
  }

  // Calendario con los límites de 18 a 100 años, con los colores del diseño
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

  String _limpiar(String texto) => texto.trim().replaceAll(RegExp(r'\s+'), ' ');

  Future<void> _guardar() async {
    if (_guardando) return;
    if (!(_formulario.currentState?.validate() ?? false)) return;
    if (_telefonoOcupado) return;

    setState(() {
      _guardando = true;
      _errorGeneral = null;
    });

    final resultado = await _perfil.actualizar(
      nombre: _limpiar(_nombre.text),
      apellido: _limpiar(_apellido.text),
      telefono: Validadores.soloDigitos(_telefono.text),
      fechaNacimiento: _fechaNacimiento!,
      sexoCodigo: _sexos[_sexo]!,
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
      final mensaje =
          resultado.mensaje ?? 'No se pudieron guardar los cambios.';
      setState(() {
        _guardando = false;
        if (mensaje.contains('celular')) {
          _telefonoOcupado = true;
        } else {
          _errorGeneral = mensaje;
        }
      });
      return;
    }

    final datos = resultado.datos;
    if (datos != null) {
      _telefonoOriginal = Validadores.soloDigitos(datos.telefono);
    }
    setState(() {
      _guardando = false;
      _iniciales = _calcularIniciales(_nombre.text, _apellido.text);
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Cambios guardados.')));
  }

  // Copia el correo al portapapeles del teléfono
  Future<void> _copiarCorreo() async {
    await Clipboard.setData(ClipboardData(text: _correo ?? ''));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Correo copiado.')));
  }

  // Pide confirmar antes de cerrar sesión. Tocar fuera de la ventana no hace nada.
  Future<void> _confirmarCerrarSesion() async {
    final salir = await showDialog<bool>(
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '¿Quieres cerrar sesión?',
                      style: GoogleFonts.poppins(
                        fontSize: Escala.de(contexto, 18),
                        fontWeight: FontWeight.w700,
                        color: ColoresApp.verdeTexto,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cancelar',
                    onPressed: () => Navigator.of(contexto).pop(false),
                    icon: const Icon(Icons.close, color: ColoresApp.verdeTexto),
                  ),
                ],
              ),
              SizedBox(height: Escala.de(contexto, 16)),
              BotonPrincipal(
                texto: 'Sí, salir',
                compacto: true,
                alPresionar: () => Navigator.of(contexto).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
    if (salir != true || !mounted) return;
    await _autenticacion.cerrarSesionLocal();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/adios', (ruta) => false);
  }

  // Ventana con el nombre, el correo y el rol, con X para cerrar y la opción de cerrar sesión
  Future<void> _verDetalle() {
    final nombre = '${_nombre.text} ${_apellido.text}'.trim();
    return showDialog<void>(
      context: context,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mi cuenta',
                      style: GoogleFonts.poppins(
                        fontSize: Escala.de(contexto, 20),
                        fontWeight: FontWeight.w700,
                        color: ColoresApp.verdeTexto,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(contexto).pop(),
                    icon: const Icon(Icons.close, color: ColoresApp.verdeTexto),
                  ),
                ],
              ),
              SizedBox(height: Escala.de(contexto, 8)),
              _DatoDetalle(etiqueta: 'Nombre', valor: nombre),
              _DatoDetalle(
                etiqueta: 'Correo · toca para copiar',
                valor: _correo ?? '',
                alPresionar: _copiarCorreo,
              ),
              SizedBox(height: Escala.de(contexto, 20)),
              BotonPrincipal(
                texto: 'Cerrar sesión',
                compacto: true,
                alPresionar: () {
                  Navigator.of(contexto).pop();
                  _confirmarCerrarSesion();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BarraNavegacion(
        seccionActiva: SeccionApp.perfil,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            Escala.de(context, 20),
            Escala.de(context, 20),
            Escala.de(context, 20),
            Escala.de(context, 32),
          ),
          child: Form(
            key: _formulario,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mi perfil',
                        style: GoogleFonts.poppins(
                          fontSize: Escala.de(context, 26),
                          fontWeight: FontWeight.w700,
                          color: ColoresApp.verdeTexto,
                        ),
                      ),
                    ),
                    _BotonSalir(alPresionar: _confirmarCerrarSesion),
                  ],
                ),
                SizedBox(height: Escala.de(context, 14)),
                GestureDetector(
                  onTap: _verDetalle,
                  child: _TarjetaUsuario(
                    iniciales: _iniciales ?? '',
                    nombreCompleto: '${_nombre.text} ${_apellido.text}'.trim(),
                    correo: _correo ?? '',
                  ),
                ),
                if (_errorGeneral != null) ...[
                  SizedBox(height: Escala.de(context, 14)),
                  _AvisoError(mensaje: _errorGeneral!),
                ],
                SizedBox(height: Escala.de(context, 18)),
                CampoTexto(
                  compacto: true,
                  etiqueta: 'Nombre',
                  controlador: _nombre,
                  cargando: _cargando,
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
                  cargando: _cargando,
                  pista: 'Apellido',
                  longitudMaxima: 100,
                  formateadores: [Validadores.formateadorNombre],
                  validador: (valor) =>
                      Validadores.nombre(valor, campo: 'El apellido'),
                ),
                SizedBox(height: Escala.de(context, 14)),
                CampoTelefono(
                  controlador: _telefono,
                  cargando: _cargando,
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
                  cargando: _cargando,
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
                  cargando: _cargando,
                  opciones: _sexos.keys.toList(),
                  alCambiar: (valor) => setState(() => _sexo = valor),
                ),
                SizedBox(height: Escala.de(context, 18)),
                _FilaCambiarContrasena(
                  alPresionar: () =>
                      Navigator.of(context).pushNamed('/cambiar-contrasena'),
                ),
                SizedBox(height: Escala.de(context, 24)),
                SizedBox(
                  width: double.infinity,
                  child: BotonPrincipal(
                    texto: _guardando ? 'Guardando...' : 'Guardar cambios',
                    alPresionar: _guardando || _cargando ? null : _guardar,
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

// Tarjeta con las iniciales, el nombre, el correo (solo lectura) y el rol
class _TarjetaUsuario extends StatelessWidget {
  const _TarjetaUsuario({
    required this.iniciales,
    required this.nombreCompleto,
    required this.correo,
  });

  final String iniciales;
  final String nombreCompleto;
  final String correo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Escala.de(context, 14)),
      decoration: BoxDecoration(
        color: ColoresApp.blanco,
        borderRadius: BorderRadius.circular(Escala.de(context, 18)),
      ),
      child: Row(
        children: [
          Container(
            width: Escala.de(context, 52),
            height: Escala.de(context, 52),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: ColoresApp.verdeBoton,
              shape: BoxShape.circle,
            ),
            child: Text(
              iniciales,
              style: GoogleFonts.poppins(
                fontSize: Escala.de(context, 18),
                fontWeight: FontWeight.w600,
                color: ColoresApp.blanco,
              ),
            ),
          ),
          SizedBox(width: Escala.de(context, 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombreCompleto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: Escala.de(context, 16),
                    fontWeight: FontWeight.w600,
                    color: ColoresApp.verdeOscuro,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: Escala.de(context, 13),
                      color: ColoresApp.grisEtiqueta,
                    ),
                    SizedBox(width: Escala.de(context, 6)),
                    Expanded(
                      child: Text(
                        '$correo · no editable',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: Escala.de(context, 13),
                          color: ColoresApp.grisEtiqueta,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: Escala.de(context, 8)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Escala.de(context, 8),
              vertical: Escala.de(context, 4),
            ),
            decoration: BoxDecoration(
              color: ColoresApp.verdeEtiqueta,
              borderRadius: BorderRadius.circular(Escala.de(context, 8)),
            ),
            child: Text(
              'Ciudadano',
              style: GoogleFonts.poppins(
                fontSize: Escala.de(context, 11.5),
                fontWeight: FontWeight.w600,
                color: ColoresApp.verdeTexto,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Fila que abre la ventana de cambio de contraseña
class _FilaCambiarContrasena extends StatelessWidget {
  const _FilaCambiarContrasena({required this.alPresionar});

  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColoresApp.blanco,
      borderRadius: BorderRadius.circular(Escala.de(context, 14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(Escala.de(context, 14)),
        onTap: alPresionar,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Escala.de(context, 14),
            vertical: Escala.de(context, 14),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/svg/icono_llave.svg',
                width: Escala.de(context, 20),
                height: Escala.de(context, 20),
                colorFilter: const ColorFilter.mode(
                  ColoresApp.verdeTexto,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: Escala.de(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cambiar contraseña',
                      style: GoogleFonts.poppins(
                        fontSize: Escala.de(context, 14),
                        fontWeight: FontWeight.w600,
                        color: ColoresApp.verdeOscuro,
                      ),
                    ),
                    Text(
                      'Cerrará la sesión en todos tus dispositivos',
                      style: GoogleFonts.poppins(
                        fontSize: Escala.de(context, 12),
                        color: ColoresApp.grisEtiqueta,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: Escala.de(context, 20),
                color: ColoresApp.grisEtiqueta,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Aviso de error de la pantalla
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

// Botón de salir del perfil: cuadrado blanco con el ícono de salir
class _BotonSalir extends StatelessWidget {
  const _BotonSalir({required this.alPresionar});

  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: alPresionar,
      child: Container(
        width: Escala.de(context, 44),
        height: Escala.de(context, 44),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ColoresApp.blanco,
          borderRadius: BorderRadius.circular(Escala.de(context, 14)),
        ),
        child: SvgPicture.asset(
          'assets/svg/icono_salir.svg',
          width: Escala.de(context, 20),
          height: Escala.de(context, 20),
          colorFilter: const ColorFilter.mode(
            ColoresApp.verdeTexto,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

// Dato de la cuenta dentro de la ventana de detalle: etiqueta pequeña y valor debajo
class _DatoDetalle extends StatelessWidget {
  const _DatoDetalle({
    required this.etiqueta,
    required this.valor,
    this.alPresionar,
  });

  final String etiqueta;
  final String valor;
  // Si se indica, tocar el dato ejecuta esta acción (por ejemplo, copiarlo)
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: alPresionar,
      child: Padding(
        padding: EdgeInsets.only(bottom: Escala.de(context, 12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              etiqueta,
              style: GoogleFonts.poppins(
                fontSize: Escala.de(context, 13),
                color: ColoresApp.grisEtiqueta,
              ),
            ),
            Text(
              valor,
              style: GoogleFonts.poppins(
                fontSize: Escala.de(context, 15),
                fontWeight: FontWeight.w600,
                color: ColoresApp.verdeOscuro,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
