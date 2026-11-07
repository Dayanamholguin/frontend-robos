import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'inicio/pantalla_bienvenida.dart';
import 'inicio/pantalla_descubre.dart';
import 'inicio/pantalla_inicio_app.dart';
import 'ingreso/pantalla_ingreso.dart';
import 'mapa/pantalla_mapa.dart';
import 'perfil/pantalla_adios.dart';
import 'perfil/pantalla_cambiar_contrasena.dart';
import 'perfil/pantalla_perfil.dart';
import 'registro/pantalla_registro.dart';
import 'inicio/pantalla_permisos.dart';
import 'tema/tema_app.dart';
import 'widgets/conexion_global.dart';

void main() {
  runApp(const AppRobos());
}

class AppRobos extends StatelessWidget {
  const AppRobos({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppRobos',
      debugShowCheckedModeBanner: false,
      theme: crearTemaApp(),
      // La capa de conexión cubre toda la app, también el inicio
      builder: (context, hijo) =>
          ConexionGlobal(child: hijo ?? const SizedBox()),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('es', 'CO'), Locale('es')],
      initialRoute: '/',
      routes: {
        '/': (_) => const PantallaInicioApp(),
        '/bienvenida': (_) => const PantallaBienvenida(),
        '/descubre': (_) => const PantallaDescubre(),
        '/permisos': (_) => const PantallaPermisos(),
        '/ingreso': (_) => const PantallaIngreso(),
        '/registro': (_) => const PantallaRegistro(),
        '/mapa': (_) => const PantallaMapa(),
        '/perfil': (_) => const PantallaPerfil(),
        '/adios': (_) => const PantallaAdios(),
        '/cambiar-contrasena': (_) => const PantallaCambiarContrasena(),
      },
    );
  }
}
