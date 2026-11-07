import 'package:flutter/material.dart';

// Escala de textos, iconos e ilustraciones según el ancho del celular.
// El diseño está pensado para 390 px de ancho. En celulares más angostos o más anchos
// los valores se achican o agrandan, pero dentro de un rango para que nada quede muy chico o muy grande.
class Escala {
  const Escala._();

  // Ancho de referencia del diseño
  static const double anchoReferencia = 390;

  static double factor(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    return (ancho / anchoReferencia).clamp(0.82, 1.2).toDouble();
  }

  // Devuelve el valor de diseño ajustado al ancho del celular
  static double de(BuildContext context, double valor) =>
      valor * factor(context);
}
