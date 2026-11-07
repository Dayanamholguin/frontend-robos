import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tema/colores_app.dart';
import '../tema/escala.dart';

// Pantalla de despedida al cerrar sesión. Dura 6 segundos y luego lleva al ingreso.
class PantallaAdios extends StatefulWidget {
  const PantallaAdios({super.key});

  @override
  State<PantallaAdios> createState() => _PantallaAdiosState();
}

class _PantallaAdiosState extends State<PantallaAdios>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  bool _salido = false;

  @override
  void initState() {
    super.initState();
    _controlador =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..addStatusListener((estado) {
            if (estado == AnimationStatus.completed && mounted) {
              Navigator.of(context).pushReplacementNamed('/ingreso');
            }
          })
          ..forward();
  }

  // Pasa al ingreso una sola vez, al terminar la animación o al tocar la pantalla
  void _irAlIngreso() {
    if (_salido || !mounted) return;
    _salido = true;
    Navigator.of(context).pushReplacementNamed('/ingreso');
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Logo y texto aparecen en los primeros segundos; los puntos laten durante toda la animación
    final logo = CurvedAnimation(
      parent: _controlador,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
    );
    final texto = CurvedAnimation(
      parent: _controlador,
      curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
    );
    final subtexto = CurvedAnimation(
      parent: _controlador,
      curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
    );

    return Scaffold(
      backgroundColor: ColoresApp.verdeBoton,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _irAlIngreso,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Escala.de(context, 24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: logo,
                    child: FadeTransition(
                      opacity: logo,
                      child: SvgPicture.asset(
                        'assets/svg/logo_inicio.svg',
                        width: Escala.de(context, 64),
                        height: Escala.de(context, 64),
                      ),
                    ),
                  ),
                  SizedBox(height: Escala.de(context, 18)),
                  FadeTransition(
                    opacity: texto,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'ADIÓS',
                        maxLines: 1,
                        style: GoogleFonts.poppins(
                          fontSize: Escala.de(context, 46),
                          letterSpacing: 4,
                          color: ColoresApp.textoClaro,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: Escala.de(context, 14)),
                  FadeTransition(
                    opacity: subtexto,
                    child: Text(
                      'Gracias por ser parte de una comunidad más unida.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: Escala.de(context, 15),
                        color: ColoresApp.verdeEtiqueta,
                      ),
                    ),
                  ),
                  SizedBox(height: Escala.de(context, 36)),
                  AnimatedBuilder(
                    animation: _controlador,
                    builder: (context, _) {
                      // Tres puntos que laten en secuencia mientras pasan los 6 segundos
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (indice) {
                          final fase = (_controlador.value * 6 - indice) % 3;
                          final activo = fase < 1;
                          return Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: Escala.de(context, 4),
                            ),
                            width: Escala.de(context, 10),
                            height: Escala.de(context, 10),
                            decoration: BoxDecoration(
                              color: activo
                                  ? ColoresApp.verdeClaro
                                  : ColoresApp.verdeEtiqueta.withValues(
                                      alpha: 0.35,
                                    ),
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
