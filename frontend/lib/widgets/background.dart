import 'dart:math' as math;

import 'package:flutter/material.dart';

// Clase para dibujar el fondo
class BackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final List<Offset> _particlePositions = [];
  final List<double> _particleSizes = [];
  
  // Constructor con inicialización de partículas
  BackgroundPainter({required this.animation}) : super(repaint: animation) {
    // Inicializar posiciones y tamaños de partículas una sola vez
    // en lugar de recalcularlos en cada frame
    final random = math.Random(42); // Semilla fija para consistencia
    for (var i = 0; i < 20; i++) {
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
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF1A1A1A),
        const Color(0xFF1A1A1A).withRed(40),
        const Color(0xFF1A1A1A),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    canvas.drawRect(
      rect,
      Paint()..shader = gradient.createShader(rect),
    );

    // Valores de animación
    final animValue = animation.value;
    final wave = math.sin(animValue * math.pi * 2) * 20;
    final scale = 1 + math.sin(animValue * math.pi) * 0.1;
    
    // Efecto de partículas flotantes
    final particlePaint = Paint()
      ..color = const Color(0xFFE31E24).withOpacity(0.05)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < _particlePositions.length; i++) {
      final position = _particlePositions[i];
      final baseSize = _particleSizes[i];
      
      // Calcular posición animada
      final x = size.width * position.dx + wave * math.sin(animValue * math.pi + i);
      final y = size.height * position.dy + wave * math.cos(animValue * math.pi + i);
      final radius = baseSize * scale;
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        particlePaint,
      );
    }

    // Líneas onduladas decorativas
    final wavePaint = Paint()
      ..color = const Color(0xFFE31E24).withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < 3; i++) {
      final path = Path();
      path.moveTo(0, size.height * (0.2 + i * 0.3));
      
      for (var x = 0.0; x < size.width; x += 30) {
        final dx = x / size.width;
        final y = size.height * (0.2 + i * 0.3) +
            math.sin(dx * math.pi * 4 + animValue * math.pi * 2) * 20 * scale;
        path.lineTo(x, y);
      }
      
      canvas.drawPath(path, wavePaint);
    }

    // Efecto de resplandor en las esquinas
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE31E24).withOpacity(0.1),
          const Color(0xFFE31E24).withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: const Offset(0, 0),
        radius: size.width * 0.5,
      ));

    // Esquina superior izquierda
    canvas.drawCircle(
      const Offset(0, 0),
      size.width * 0.3 * (1 + math.sin(animValue * math.pi) * 0.1),
      glowPaint,
    );

    // Esquina inferior derecha
    canvas.drawCircle(
      Offset(size.width, size.height),
      size.width * 0.3 * (1 + math.cos(animValue * math.pi) * 0.1),
      glowPaint,
    );

    // Efecto de red geométrica
    final gridPaint = Paint()
      ..color = const Color(0xFFE31E24).withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final spacing = size.width / 15;
    for (var i = 0; i < 16; i++) {
      final x = i * spacing;
      final y1 = wave * math.sin(x / size.width * math.pi + animValue * math.pi);
      final y2 = size.height + wave * math.sin(x / size.width * math.pi + animValue * math.pi);
      
      canvas.drawLine(
        Offset(x, y1),
        Offset(x, y2),
        gridPaint,
      );
    }

    for (var i = 0; i < 16; i++) {
      final y = i * spacing;
      final x1 = wave * math.cos(y / size.height * math.pi + animValue * math.pi);
      final x2 = size.width + wave * math.cos(y / size.height * math.pi + animValue * math.pi);
      
      canvas.drawLine(
        Offset(x1, y),
        Offset(x2, y),
        gridPaint,
      );
    }

    // Efecto de pulso principal
    final pulsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFE31E24).withOpacity(
        0.12 * (1 + math.cos(animValue * math.pi * 3)) / 2
      );

    // Pulso principal con doble círculo
    final pulseRadius = (size.width * 0.25) * (1 + math.sin(animValue * math.pi * 2) * 0.15);
    final pulseCenter = Offset(size.width * 0.85, size.height * 0.3);
    
    // Círculo exterior
    canvas.drawCircle(
      pulseCenter,
      pulseRadius,
      pulsePaint,
    );
    
    // Círculo interior con diferente fase
    canvas.drawCircle(
      pulseCenter,
      pulseRadius * 0.7 * (1 + math.cos(animValue * math.pi * 2) * 0.2),
      pulsePaint..strokeWidth = 2,
    );

    // Segundo grupo de pulsos más pequeños
    final smallPulsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFE31E24).withOpacity(
        0.08 * (1 + math.sin(animValue * math.pi * 4)) / 2
      );

    final smallPulseCenter = Offset(size.width * 0.75, size.height * 0.4);
    
    // Círculo pequeño exterior
    canvas.drawCircle(
      smallPulseCenter,
      (size.width * 0.15) * (1 + math.sin(animValue * math.pi * 3) * 0.25),
      smallPulsePaint,
    );
    
    // Círculo pequeño interior
    canvas.drawCircle(
      smallPulseCenter,
      (size.width * 0.1) * (1 + math.cos(animValue * math.pi * 3) * 0.25),
      smallPulsePaint..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) => true;
}
