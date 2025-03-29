import 'package:condorsmotors/api/protected/movimientos.api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProgresoMovimiento extends StatelessWidget {
  final String estadoActual;
  final VoidCallback? onInfoTap;

  const ProgresoMovimiento({
    super.key,
    required this.estadoActual,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    const Map<String, String> estados = MovimientosApi.estadosDetalle;
    final List<String> estadosValues = estados.values.toList();
    final int currentIndex = estadosValues.indexOf(estadoActual);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text(
              'Estado del Movimiento',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onInfoTap != null)
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: onInfoTap,
                tooltip: 'Ver información',
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: estadosValues.asMap().entries.map((MapEntry<int, String> entry) {
            final int index = entry.key;
            final String estado = entry.value;
            final bool isActive = index <= currentIndex;
            final bool isCurrentState = estado == estadoActual;

            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isActive ? Theme.of(context).primaryColor : Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
                child: isCurrentState
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: estadosValues.asMap().entries.map((MapEntry<int, String> entry) {
            final int index = entry.key;
            final String estado = entry.value;
            final bool isActive = index <= currentIndex;
            return Text(
              estado,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.white : Colors.grey[500],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('estadoActual', estadoActual))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onInfoTap', onInfoTap));
  }
} 