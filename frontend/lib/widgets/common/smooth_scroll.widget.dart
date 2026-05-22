import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Un widget que proporciona scroll suave para eventos de rueda de ratón (mouse wheel)
/// en plataformas de escritorio (Windows, Linux, macOS) y Web.
/// También envuelve el contenido en un scrollbar consistente con la estética premium del sistema.
class SmoothScroll extends StatefulWidget {
  final ScrollController controller;
  final Widget child;
  final double scrollSpeed;
  final int duration;
  final Curve curve;

  const SmoothScroll({
    super.key,
    required this.controller,
    required this.child,
    this.scrollSpeed = 1.0,
    this.duration = 200,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<SmoothScroll> createState() => _SmoothScrollState();
}

class _SmoothScrollState extends State<SmoothScroll> {
  double _scrollTarget = 0.0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    // Registrar callback después del frame inicial para sincronizar el offset
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.hasClients) {
        _scrollTarget = widget.controller.position.pixels;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Solo aplicar scroll suave en plataformas de escritorio o Web
    final bool applySmoothScroll = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

    if (!applySmoothScroll) {
      return Scrollbar(
        controller: widget.controller,
        thumbVisibility: true,
        child: widget.child,
      );
    }

    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          final double delta = pointerSignal.scrollDelta.dy;
          if (delta == 0) {
            return;
          }

          if (!widget.controller.hasClients) {
            return;
          }

          // Registrar nuestro callback para consumir el evento
          GestureBinding.instance.pointerSignalResolver.register(pointerSignal, (event) {
            final double maxScroll = widget.controller.position.maxScrollExtent;
            final double minScroll = widget.controller.position.minScrollExtent;

            // Sincronizar el target si no estamos animando o si el offset actual difiere
            if (!_isAnimating || (widget.controller.position.pixels - _scrollTarget).abs() > 50) {
              _scrollTarget = widget.controller.position.pixels;
            }

            // Incrementar y limitar el offset objetivo
            _scrollTarget += delta * widget.scrollSpeed;
            _scrollTarget = _scrollTarget.clamp(minScroll, maxScroll);

            if (_scrollTarget != widget.controller.position.pixels) {
              _isAnimating = true;
              widget.controller.animateTo(
                _scrollTarget,
                duration: Duration(milliseconds: widget.duration),
                curve: widget.curve,
              ).then((_) {
                _isAnimating = false;
              });
            }
          });
        }
      },
      child: Scrollbar(
        controller: widget.controller,
        thumbVisibility: true,
        interactive: true,
        thickness: 8.0,
        radius: const Radius.circular(4.0),
        child: widget.child,
      ),
    );
  }
}
