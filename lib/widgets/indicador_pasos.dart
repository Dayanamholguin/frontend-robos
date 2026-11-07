import 'package:flutter/material.dart';

import '../tema/colores_app.dart';

// Indicador de pasos del recorrido inicial. El paso actual es más ancho.
class IndicadorPasos extends StatelessWidget {
  const IndicadorPasos({super.key, required this.total, required this.actual});

  final int total;

  // Índice del paso activo, empezando en 0
  final int actual;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Paso ${actual + 1} de $total',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(total, (indice) {
          final activo = indice == actual;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: activo ? 36 : 20,
            height: 8,
            decoration: BoxDecoration(
              color: activo ? ColoresApp.verdeBoton : ColoresApp.blanco,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
