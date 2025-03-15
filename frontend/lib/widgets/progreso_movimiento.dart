import 'package:flutter/material.dart';
import '../api/protected/movimientos.api.dart';

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
    const estados = MovimientosApi.estadosDetalle;
    final estadosValues = estados.values.toList();
    final currentIndex = estadosValues.indexOf(estadoActual);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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
          children: estadosValues.asMap().entries.map((entry) {
            final index = entry.key;
            final estado = entry.value;
            final isActive = index <= currentIndex;
            final isCurrentState = estado == estadoActual;

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
          children: estadosValues.asMap().entries.map((entry) {
            final index = entry.key;
            final estado = entry.value;
            final isActive = index <= currentIndex;
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
} 