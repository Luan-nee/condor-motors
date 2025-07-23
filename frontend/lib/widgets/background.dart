import 'dart:math' as math;

import 'package:flutter/material.dart';

// Clase para dibujar el fondo
class BackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final List<Offset> _particlePositions = <Offset>[];
  final List<double> _particleSizes = <double>[];

  // Constructor con inicialización de partículas
  BackgroundPainter({
    required this.animation,
  }) : super(repaint: animation) {
    // Inicializar posiciones y tamaños de partículas una sola vez
    // en lugar de recalcularlos en cada frame
    final math.Random random =
        math.Random(42); // Semilla fija para consistencia
    for (int i = 0; i < 20; i++) {
      _particlePositions.add(
        Offset(
          0.1 + 0.8 * random.nextDouble(),
          0.1 + 0.8 * random.nextDouble(),
        ),
      );
      _particleSizes.add(3 + random.nextDouble() * 2);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Gradiente de fondo
    final Rect rect = Offset.zero & size;
    final LinearGradient gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        const Color(0xFF1A1A1A),
        const Color(0xFF1A1A1A).withRed(40),
        const Color(0xFF1A1A1A),
      ],
      stops: const <double>[0.0, 0.5, 1.0],
    );

    canvas.drawRect(
      rect,
      Paint()..shader = gradient.createShader(rect),
    );

    // Usar directamente el valor de la animación (0 a 1) para los ciclos completos
    final double animValue = animation.value;

    // Usamos 2*pi para ciclos completos que empiezan y terminan en el mismo punto

    // Función de onda que varía suavemente (ajustamos multiplicador para velocidad)
    final double wave = math.sin(animValue * math.pi * 2 * 2) * 20;

    // Escala que varía suavemente (ajustamos multiplicador para velocidad)
    final double scale = 1 + 0.1 * math.sin(animValue * math.pi * 2 * 2);

    // Efecto de partículas flotantes
    final Paint particlePaint = Paint()
      ..color = const Color(0xFFE31E24).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < _particlePositions.length; i++) {
      final Offset position = _particlePositions[i];
      final double baseSize = _particleSizes[i];

      // Usar múltiplos de 2*pi para garantizar ciclos completos
      final double offsetX = wave * math.sin(animValue * math.pi * 2 * 2 + i);
      final double offsetY = wave * math.cos(animValue * math.pi * 2 * 2 + i);

      // Calcular posición animada
      double x = size.width * position.dx + offsetX;
      double y = size.height * position.dy + offsetY;
      final double radius = baseSize * scale;

      // --- Implementar Wrapping --- // FIX: Mejorar wrapping si es necesario para efectos más complejos.
      // Asegurar que las partículas se envuelvan al salir de la pantalla
      if (x > size.width + radius) {
        x -= size.width + 2 * radius;
      }
      if (x < -radius) {
        x += size.width + 2 * radius;
      }
      if (y > size.height + radius) {
        y -= size.height + 2 * radius;
      }
      if (y < -radius) {
        y += size.height + 2 * radius;
      }
      // --- Fin Implementación Wrapping ---

      canvas.drawCircle(
        Offset(x, y),
        radius,
        particlePaint,
      );
    }

    // Líneas onduladas decorativas con funciones cíclicas
    final Paint wavePaint = Paint()
      ..color = const Color(0xFFE31E24).withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 3; i++) {
      final Path path = Path()..moveTo(0, size.height * (0.2 + i * 0.3));

      for (double x = 0.0; x < size.width; x += 30) {
        final double dx = x / size.width;
        final double y = size.height * (0.2 + i * 0.3) +
            math.sin(dx * math.pi * 4 + animValue * math.pi * 2 * 2) *
                20 *
                scale;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, wavePaint);
    }

    // Efecto de resplandor en las esquinas
    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFFE31E24).withValues(alpha: 0.1),
          const Color(0xFFE31E24).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset.zero,
        radius: size.width * 0.5,
      ));

    // Esquina superior izquierda
    canvas
      ..drawCircle(
        Offset.zero,
        size.width * 0.3 * (1 + math.sin(animValue * math.pi * 2 * 2) * 0.1),
        glowPaint,
      )

      // Esquina inferior derecha
      ..drawCircle(
        Offset(size.width, size.height),
        size.width * 0.3 * (1 + math.cos(animValue * math.pi * 2 * 2) * 0.1),
        glowPaint,
      );

    // Efecto de red geométrica con ciclos completos
    final Paint gridPaint = Paint()
      ..color = const Color(0xFFE31E24).withValues(alpha: 0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final double spacing = size.width / 15;
    for (int i = 0; i < 16; i++) {
      final double x = i * spacing;
      final double y1 = wave *
          math.sin(x / size.width * math.pi + animValue * math.pi * 2 * 2);
      final double y2 = size.height +
          wave *
              math.sin(x / size.width * math.pi + animValue * math.pi * 2 * 2);

      canvas.drawLine(
        Offset(x, y1),
        Offset(x, y2),
        gridPaint,
      );
    }

    for (int i = 0; i < 16; i++) {
      final double y = i * spacing;
      final double x1 = wave *
          math.cos(y / size.height * math.pi + animValue * math.pi * 2 * 2);
      final double x2 = size.width +
          wave *
              math.cos(y / size.height * math.pi + animValue * math.pi * 2 * 2);

      canvas.drawLine(
        Offset(x1, y),
        Offset(x2, y),
        gridPaint,
      );
    }

    // Efecto de pulso principal con ciclos completos
    final Paint pulsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFE31E24).withValues(
          alpha: 0.12 * (1 + math.cos(animValue * math.pi * 2 * 3)) / 2);

    // Pulso principal con doble círculo
    final double pulseRadius = (size.width * 0.25) *
        (1 + math.sin(animValue * math.pi * 2 * 2) * 0.15);
    final Offset pulseCenter = Offset(size.width * 0.85, size.height * 0.3);

    // Círculo exterior
    canvas
      ..drawCircle(
        pulseCenter,
        pulseRadius,
        pulsePaint,
      )

      // Círculo interior con diferente fase pero ciclo completo
      ..drawCircle(
        pulseCenter,
        pulseRadius * 0.7 * (1 + math.cos(animValue * math.pi * 2 * 2) * 0.2),
        pulsePaint..strokeWidth = 2,
      );

    // Segundo grupo de pulsos más pequeños
    final Paint smallPulsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFE31E24).withValues(
          alpha: 0.08 * (1 + math.sin(animValue * math.pi * 2 * 4)) / 2);

    final Offset smallPulseCenter =
        Offset(size.width * 0.75, size.height * 0.4);

    // Círculo pequeño exterior
    canvas
      ..drawCircle(
        smallPulseCenter,
        (size.width * 0.15) *
            (1 + math.sin(animValue * math.pi * 2 * 3) * 0.25),
        smallPulsePaint,
      )

      // Círculo pequeño interior
      ..drawCircle(
        smallPulseCenter,
        (size.width * 0.1) * (1 + math.cos(animValue * math.pi * 2 * 3) * 0.25),
        smallPulsePaint..strokeWidth = 1.5,
      );
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) =>
      oldDelegate.animation.value != animation.value;
}
