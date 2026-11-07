import 'package:flutter/material.dart';

import 'velocidad_red.dart';

// Transición entre pantallas: desvanecido suave si la red es rápida; sin animación si está lenta.
class TransicionAdaptativa extends PageTransitionsBuilder {
  const TransicionAdaptativa();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (!VelocidadRed.rapida) return child;
    return FadeTransition(opacity: animation, child: child);
  }
}
