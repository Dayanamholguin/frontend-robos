import 'dart:async';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../tema/colores_app.dart';
import '../transiciones/velocidad_red.dart';
import '../tema/escala.dart';
import 'logo_approbos.dart';

// Envuelve toda la app. Cuando no hay red, cubre la pantalla con el fondo difuminado y
// el logo APPROBOS con un indicador de carga. Al volver la red, la capa desaparece sola.
class ConexionGlobal extends StatefulWidget {
  const ConexionGlobal({super.key, required this.child});

  final Widget child;

  @override
  State<ConexionGlobal> createState() => _ConexionGlobalState();
}

class _ConexionGlobalState extends State<ConexionGlobal> {
  bool _sinConexion = false;
  StreamSubscription<List<ConnectivityResult>>? _cambios;

  @override
  void initState() {
    super.initState();
    _revisarInicial();
    VelocidadRed.medir();
    _cambios = Connectivity().onConnectivityChanged.listen(_actualizar);
  }

  @override
  void dispose() {
    _cambios?.cancel();
    super.dispose();
  }

  Future<void> _revisarInicial() async {
    _actualizar(await Connectivity().checkConnectivity());
  }

  // Wi-Fi, datos móviles o cable de red cuentan como conexión
  void _actualizar(List<ConnectivityResult> resultados) {
    final hayRed = resultados.any(
      (resultado) =>
          resultado == ConnectivityResult.wifi ||
          resultado == ConnectivityResult.mobile ||
          resultado == ConnectivityResult.ethernet,
    );
    if (hayRed) VelocidadRed.medir();
    if (!mounted || _sinConexion == !hayRed) return;
    setState(() => _sinConexion = !hayRed);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_sinConexion) const Positioned.fill(child: _CapaSinConexion()),
      ],
    );
  }
}

// Fondo gris difuminado. El logo y el indicador van encima, sin el tono gris,
// para que se vean con sus colores reales. Bloquea los toques mientras no hay red.
class _CapaSinConexion extends StatelessWidget {
  const _CapaSinConexion();

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width * 0.8;

    // Material transparente: el texto necesita un Material en el árbol para no mostrar subrayados
    return AbsorbPointer(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: ColoresApp.grisFondoBlur.withValues(alpha: 0.55),
              ),
            ),
            Center(
              child: SizedBox(
                width: ancho,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LogoApprobos(oscuro: true),
                    SizedBox(height: Escala.de(context, 28)),
                    SizedBox(
                      width: Escala.de(context, 28),
                      height: Escala.de(context, 28),
                      child: const CircularProgressIndicator(
                        strokeWidth: 3,
                        color: ColoresApp.verdeBoton,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
