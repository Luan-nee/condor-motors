import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Clase para dibujar el fondo de forma optimizada
/// Utiliza el patrón Flyweight reutilizando pinceles Paint y estructuras Path mutables
/// para erradicar las asignaciones dinámicas a 60 FPS.
class BackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final List<Offset> _particlePositions = <Offset>[];
  final List<double> _particleSizes = <double>[];

  // Pinceles reutilizables (Patrón Flyweight)
  final Paint _backgroundPaint = Paint()..style = PaintingStyle.fill;
  
  final Paint _particlePaint = Paint()
    ..color = const Color(0xFFE31E24).withValues(alpha: 0.05)
    ..style = PaintingStyle.fill;
    
  final Paint _wavePaint = Paint()
    ..color = const Color(0xFFE31E24).withValues(alpha: 0.03)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
    
  final Paint _glowPaint = Paint()..style = PaintingStyle.fill;
  
  final Paint _gridPaint = Paint()
    ..color = const Color(0xFFE31E24).withValues(alpha: 0.02)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
    
  final Paint _pulsePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
    
  final Paint _smallPulsePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  // Trazado reutilizable para evitar instanciaciones efímeras de Path
  final Path _cachedPath = Path();

  // Caché de tamaño para reutilizar Shaders sin reconstruir
  Size? _lastSize;
  Shader? _backgroundShader;
  Shader? _glowShader;

  // Constructor con inicialización de partículas
  BackgroundPainter({
    required this.animation,
  }) : super(repaint: animation) {
    // Inicializar posiciones y tamaños de partículas una sola vez
    // en lugar de recalcularlos en cada frame
    final math.Random random = math.Random(42); // Semilla fija para consistencia
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
    final Rect rect = Offset.zero & size;

    // Solo regenerar shaders si las dimensiones del Canvas cambian (redimensionamiento o rotación)
    if (_lastSize != size || _backgroundShader == null || _glowShader == null) {
      _lastSize = size;

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
      _backgroundShader = gradient.createShader(rect);

      final RadialGradient glowRadial = RadialGradient(
        colors: <Color>[
          const Color(0xFFE31E24).withValues(alpha: 0.1),
          const Color(0xFFE31E24).withValues(alpha: 0.0),
        ],
      );
      _glowShader = glowRadial.createShader(Rect.fromCircle(
        center: Offset.zero,
        radius: size.width * 0.5,
      ));
    }

    // 1. Fondo de gradiente con Shader en caché
    _backgroundPaint.shader = _backgroundShader;
    canvas.drawRect(rect, _backgroundPaint);

    final double animValue = animation.value;
    final double wave = math.sin(animValue * math.pi * 2 * 2) * 20;
    final double scale = 1 + 0.1 * math.sin(animValue * math.pi * 2 * 2);

    // 2. Partículas flotantes
    for (int i = 0; i < _particlePositions.length; i++) {
      final Offset position = _particlePositions[i];
      final double baseSize = _particleSizes[i];

      final double offsetX = wave * math.sin(animValue * math.pi * 2 * 2 + i);
      final double offsetY = wave * math.cos(animValue * math.pi * 2 * 2 + i);

      double x = size.width * position.dx + offsetX;
      double y = size.height * position.dy + offsetY;
      final double radius = baseSize * scale;

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

      canvas.drawCircle(
        Offset(x, y),
        radius,
        _particlePaint,
      );
    }

    // 3. Líneas onduladas decorativas con Path reciclado
    for (int i = 0; i < 3; i++) {
      _cachedPath
        ..reset()
        ..moveTo(0, size.height * (0.2 + i * 0.3));

      for (double x = 0.0; x < size.width; x += 30) {
        final double dx = x / size.width;
        final double y = size.height * (0.2 + i * 0.3) +
            math.sin(dx * math.pi * 4 + animValue * math.pi * 2 * 2) *
                20 *
                scale;
        _cachedPath.lineTo(x, y);
      }

      canvas.drawPath(_cachedPath, _wavePaint);
    }

    // 4. Efecto de resplandor en las esquinas con Shader en caché
    _glowPaint.shader = _glowShader;

    // Esquina superior izquierda
    canvas
      ..drawCircle(
        Offset.zero,
        size.width * 0.3 * (1 + math.sin(animValue * math.pi * 2 * 2) * 0.1),
        _glowPaint,
      )

      // Esquina inferior derecha
      ..drawCircle(
        Offset(size.width, size.height),
        size.width * 0.3 * (1 + math.cos(animValue * math.pi * 2 * 2) * 0.1),
        _glowPaint,
      );

    // 5. Malla geométrica
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
        _gridPaint,
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
        _gridPaint,
      );
    }

    // 6. Efecto de pulso principal
    _pulsePaint.color = const Color(0xFFE31E24).withValues(
        alpha: 0.12 * (1 + math.cos(animValue * math.pi * 2 * 3)) / 2);

    final double pulseRadius = (size.width * 0.25) *
        (1 + math.sin(animValue * math.pi * 2 * 2) * 0.15);
    final Offset pulseCenter = Offset(size.width * 0.85, size.height * 0.3);

    // Círculo exterior
    canvas.drawCircle(
      pulseCenter,
      pulseRadius,
      _pulsePaint,
    );

    // Círculo interior (actualizando ancho temporalmente)
    _pulsePaint.strokeWidth = 2;
    canvas.drawCircle(
      pulseCenter,
      pulseRadius * 0.7 * (1 + math.cos(animValue * math.pi * 2 * 2) * 0.2),
      _pulsePaint,
    );
    _pulsePaint.strokeWidth = 3; // Restaurar ancho base

    // 7. Segundo grupo de pulsos
    _smallPulsePaint.color = const Color(0xFFE31E24).withValues(
        alpha: 0.08 * (1 + math.sin(animValue * math.pi * 2 * 4)) / 2);

    final Offset smallPulseCenter = Offset(size.width * 0.75, size.height * 0.4);

    // Círculo pequeño exterior
    canvas.drawCircle(
      smallPulseCenter,
      (size.width * 0.15) *
          (1 + math.sin(animValue * math.pi * 2 * 3) * 0.25),
      _smallPulsePaint,
    );

    // Círculo pequeño interior
    _smallPulsePaint.strokeWidth = 1.5;
    canvas.drawCircle(
      smallPulseCenter,
      (size.width * 0.1) * (1 + math.cos(animValue * math.pi * 2 * 3) * 0.25),
      _smallPulsePaint,
    );
    _smallPulsePaint.strokeWidth = 2; // Restaurar ancho base
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) =>
      oldDelegate.animation.value != animation.value;
}
