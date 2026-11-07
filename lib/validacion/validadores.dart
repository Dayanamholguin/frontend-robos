import 'package:flutter/services.dart';

// Reglas de los campos de texto. Las mismas reglas que aplica la API, revisadas mientras el usuario escribe.
abstract final class Validadores {
  // Caracteres que se usan para inyectar SQL o HTML. Ningún campo de texto los acepta.
  static final _caracteresPeligrosos = RegExp(r"['\x22;\\<>`]");
  static final _secuenciasPeligrosas = RegExp(r'--|/\*|\*/');

  static final _nombre = RegExp(r"^\p{L}[\p{L} '\-]*$", unicode: true);
  // Cinco o más números iguales seguidos (por ejemplo 3333333) no son un celular real
  static final _numerosRepetidos = RegExp(r'(\d)\1{4}');
  static final _correo = RegExp(r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$');

  // Solo letras (con tildes, diéresis y ñ), espacios, apóstrofes y guiones
  static final formateadorNombre = FilteringTextInputFormatter.allow(
    RegExp(r"[\p{L} '\-]", unicode: true),
  );

  // Bloquea los caracteres peligrosos mientras el usuario escribe, en cualquier campo de texto
  static final formateadorSeguro = FilteringTextInputFormatter.deny(
    RegExp(r"['\x22;\\<>`]"),
  );

  // Correo: sin espacios
  static final formateadorCorreo = FilteringTextInputFormatter.deny(
    RegExp(r'\s'),
  );

  static String? _revisarSeguridad(String texto) {
    if (_caracteresPeligrosos.hasMatch(texto) ||
        _secuenciasPeligrosas.hasMatch(texto)) {
      return 'Este campo contiene caracteres no permitidos.';
    }
    return null;
  }

  static String? nombre(String? valor, {String campo = 'El nombre'}) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return '$campo es obligatorio.';
    final seguridad = _revisarSeguridad(texto);
    if (seguridad != null) return seguridad;
    if (texto.length < 2) return '$campo debe tener al menos 2 letras.';
    if (texto.length > 100) {
      return '$campo no puede tener más de 100 caracteres.';
    }
    if (!_nombre.hasMatch(texto)) {
      return '$campo solo puede tener letras, espacios, apóstrofes y guiones.';
    }
    return null;
  }

  static String? correo(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Escribe tu correo.';
    final seguridad = _revisarSeguridad(texto);
    if (seguridad != null) return seguridad;
    if (texto.length > 255) return 'El correo es demasiado largo.';
    if (!_correo.hasMatch(texto)) {
      return 'El correo no tiene un formato válido.';
    }
    return null;
  }

  static String? contrasenaSimple(String? valor) {
    final texto = valor ?? '';
    if (texto.isEmpty) return 'Escribe tu contraseña.';
    return _revisarSeguridad(texto);
  }

  // Teléfono: solo dígitos, 10 en total, empieza por 3 (celular colombiano)
  static String? telefono(String? valorFormateado) {
    final digitos = soloDigitos(valorFormateado);
    if (digitos.isEmpty) return 'Escribe tu número de celular.';
    if (digitos.length < 10) return 'El celular debe tener 10 dígitos.';
    if (!digitos.startsWith('3')) return 'El celular debe empezar por 3.';
    if (_numerosRepetidos.hasMatch(digitos)) {
      return 'El celular no puede tener números repetidos, como 3333333.';
    }
    return null;
  }

  static String soloDigitos(String? valor) =>
      (valor ?? '').replaceAll(RegExp(r'\D'), '');

  // Fecha de nacimiento: la persona debe tener entre 18 y 100 años
  static String? fechaNacimiento(DateTime? fecha) {
    if (fecha == null) return 'Elige tu fecha de nacimiento.';
    final limites = limitesFechaNacimiento();
    if (fecha.isBefore(limites.minima) || fecha.isAfter(limites.maxima)) {
      return 'Debes tener entre 18 y 100 años.';
    }
    return null;
  }

  // Primera y última fecha de nacimiento aceptadas, según la fecha de hoy
  static ({DateTime minima, DateTime maxima}) limitesFechaNacimiento() {
    final hoy = DateTime.now();
    return (
      minima: DateTime(hoy.year - 100, hoy.month, hoy.day),
      maxima: DateTime(hoy.year - 18, hoy.month, hoy.day),
    );
  }

  // Requisitos de la contraseña, en el mismo orden del diseño. Cada uno indica si ya se cumple.
  static List<ReglaContrasena> reglasContrasena(String valor) => [
    ReglaContrasena('Mínimo 8 caracteres', valor.length >= 8),
    ReglaContrasena('Una letra mayúscula', RegExp(r'[A-Z]').hasMatch(valor)),
    ReglaContrasena('Una letra minúscula', RegExp(r'[a-z]').hasMatch(valor)),
    ReglaContrasena('Un número', RegExp(r'[0-9]').hasMatch(valor)),
  ];

  static String? contrasenaNueva(String? valor) {
    final texto = valor ?? '';
    if (texto.isEmpty) return 'Crea una contraseña.';
    final seguridad = _revisarSeguridad(texto);
    if (seguridad != null) return seguridad;
    if (reglasContrasena(texto).any((regla) => !regla.cumple)) {
      return 'La contraseña no cumple los requisitos.';
    }
    return null;
  }
}

// Un requisito de la contraseña y si ya se cumple.
class ReglaContrasena {
  const ReglaContrasena(this.texto, this.cumple);

  final String texto;
  final bool cumple;
}

// Formato del celular mientras se escribe: (312) 123 - 1234.
// Solo acepta dígitos y se detiene en 10.
class FormateadorTelefono extends TextInputFormatter {
  const FormateadorTelefono();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) {
    final digitos = nuevo.text.replaceAll(RegExp(r'\D'), '');
    final limitados = digitos.length > 10 ? digitos.substring(0, 10) : digitos;

    final texto = _formatear(limitados);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }

  String _formatear(String d) {
    if (d.isEmpty) return '';
    if (d.length <= 3) return '($d';
    if (d.length <= 6) return '(${d.substring(0, 3)}) ${d.substring(3)}';
    return '(${d.substring(0, 3)}) ${d.substring(3, 6)} - ${d.substring(6)}';
  }
}
