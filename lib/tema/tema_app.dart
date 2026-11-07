import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../transiciones/transicion_adaptativa.dart';
import 'colores_app.dart';

// Tema general de la app: fondo, colores y tipografía Poppins.
ThemeData crearTemaApp() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ColoresApp.verdeBoton,
      surface: ColoresApp.fondo,
    ),
    scaffoldBackgroundColor: ColoresApp.fondo,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final plataforma in TargetPlatform.values)
          plataforma: const TransicionAdaptativa(),
      },
    ),
    fontFamily: GoogleFonts.poppins().fontFamily,
  );
}
