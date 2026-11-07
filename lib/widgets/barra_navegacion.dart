import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tema/colores_app.dart';
import '../tema/escala.dart';

// Secciones principales de la app que aparecen en la barra inferior
enum SeccionApp { mapa, perfil }

// Barra inferior con las cinco secciones. El botón central de reportar sobresale.
class BarraNavegacion extends StatelessWidget {
  const BarraNavegacion({super.key, required this.seccionActiva});

  // Sección que se muestra como activa en la barra
  final SeccionApp seccionActiva;

  // Cambia de sección sin apilar pantallas; si ya está en esa sección, no hace nada
  void _irA(BuildContext context, String ruta, SeccionApp destino) {
    if (seccionActiva == destino) return;
    Navigator.of(context).pushReplacementNamed(ruta);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Escala.de(context, 84),
      decoration: BoxDecoration(
        color: ColoresApp.blanco,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Escala.de(context, 24)),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        Escala.de(context, 8),
        0,
        Escala.de(context, 8),
        Escala.de(context, 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ItemNavegacion(
            icono: 'assets/svg/icono_mapa.svg',
            texto: 'Mapa',
            activo: seccionActiva == SeccionApp.mapa,
            alPresionar: () => _irA(context, '/mapa', SeccionApp.mapa),
          ),
          _ItemNavegacion(
            icono: 'assets/svg/icono_analisis.svg',
            texto: 'Análisis',
          ),
          _BotonReportar(),
          _ItemNavegacion(
            icono: 'assets/svg/icono_lugares.svg',
            texto: 'Lugares',
          ),
          _ItemNavegacion(
            icono: 'assets/svg/icono_perfil.svg',
            texto: 'Perfil',
            activo: seccionActiva == SeccionApp.perfil,
            alPresionar: () => _irA(context, '/perfil', SeccionApp.perfil),
          ),
        ],
      ),
    );
  }
}

class _ItemNavegacion extends StatelessWidget {
  const _ItemNavegacion({
    required this.icono,
    required this.texto,
    this.activo = false,
    this.alPresionar,
  });

  final String icono;
  final String texto;
  final bool activo;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    final color = activo ? ColoresApp.verdeTexto : ColoresApp.grisEtiqueta;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: alPresionar,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icono,
              width: Escala.de(context, 24),
              height: Escala.de(context, 24),
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            SizedBox(height: Escala.de(context, 2)),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                texto,
                maxLines: 1,
                style: GoogleFonts.poppins(
                  fontSize: Escala.de(context, 11.5),
                  fontWeight: activo ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Botón central de reportar: cuadrado verde con el signo más, subido sobre la barra
class _BotonReportar extends StatelessWidget {
  const _BotonReportar();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Transform.translate(
        offset: Offset(0, -Escala.de(context, 26)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: Escala.de(context, 48),
              height: Escala.de(context, 48),
              decoration: BoxDecoration(
                color: ColoresApp.verdeBoton,
                borderRadius: BorderRadius.circular(Escala.de(context, 16)),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/svg/icono_mas.svg',
                width: Escala.de(context, 24),
                height: Escala.de(context, 24),
                colorFilter: const ColorFilter.mode(
                  ColoresApp.blanco,
                  BlendMode.srcIn,
                ),
              ),
            ),
            SizedBox(height: Escala.de(context, 2)),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Reportar',
                maxLines: 1,
                style: GoogleFonts.poppins(
                  fontSize: Escala.de(context, 11.5),
                  fontWeight: FontWeight.w500,
                  color: ColoresApp.grisEtiqueta,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
