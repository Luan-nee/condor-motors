import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProgresoMovimiento extends StatelessWidget {
  final String estado;
  final double width;
  final double height;
  final double iconSize;
  final double fontSize;
  final bool showLabels;

  const ProgresoMovimiento({
    super.key,
    required this.estado,
    this.width = 300,
    this.height = 80,
    this.iconSize = 24,
    this.fontSize = 12,
    this.showLabels = true,
  });

  static const Map<String, String> _estadosMovimiento = {
    'PENDIENTE': 'Pendiente',
    'EN_PROCESO': 'En Proceso',
    'EN_TRANSITO': 'En Tránsito',
    'ENTREGADO': 'Entregado',
    'COMPLETADO': 'Completado',
  };

  int _obtenerPasoActual() {
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return 0;
      case 'EN_PROCESO':
        return 1;
      case 'EN_TRANSITO':
        return 2;
      case 'ENTREGADO':
        return 3;
      case 'COMPLETADO':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int pasoActual = _obtenerPasoActual();
    final List<String> pasos = _estadosMovimiento.keys.toList();

    return SizedBox(
      width: width,
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(pasos.length, (index) {
          final bool esPasoActual = index == pasoActual;
          final bool esPasoCompletado = index < pasoActual;
          final Color color = esPasoActual
              ? Theme.of(context).primaryColor
              : esPasoCompletado
                  ? Colors.green
                  : Colors.grey;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                esPasoCompletado
                    ? Icons.check_circle
                    : esPasoActual
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                color: color,
                size: iconSize,
              ),
              if (showLabels) ...[
                const SizedBox(height: 4),
                Text(
                  _estadosMovimiento[pasos[index]] ?? pasos[index],
                  style: TextStyle(
                    color: color,
                    fontSize: fontSize,
                    fontWeight:
                        esPasoActual ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('estado', estado))
      ..add(DoubleProperty('width', width))
      ..add(DoubleProperty('height', height))
      ..add(DoubleProperty('iconSize', iconSize))
      ..add(DoubleProperty('fontSize', fontSize))
      ..add(DiagnosticsProperty<bool>('showLabels', showLabels));
  }
}
