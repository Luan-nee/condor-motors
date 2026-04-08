import 'package:condorsmotors/theme/apptheme.dart';
import 'package:flutter/material.dart';

/// Chip que muestra un filtro activo con acción de limpiar.
enum ActiveFilterChipVariant {
  /// Fondo tenue, texto/icono claros (búsqueda producto/cliente).
  compact,

  /// Borde, sombra y acentos del color (productos colab).
  card,
}

class ActiveFilterChip extends StatelessWidget {
  const ActiveFilterChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onClear,
    this.variant = ActiveFilterChipVariant.compact,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onClear;
  final ActiveFilterChipVariant variant;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      ActiveFilterChipVariant.compact => _CompactChip(
          icon: icon,
          label: label,
          color: color,
          onClear: onClear,
        ),
      ActiveFilterChipVariant.card => _CardChip(
          icon: icon,
          label: label,
          color: color,
          onClear: onClear,
        ),
    };
  }
}

class _CompactChip extends StatelessWidget {
  const _CompactChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onClear,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 14,
            color: Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onClear,
            child: const Icon(
              Icons.close,
              size: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardChip extends StatelessWidget {
  const _CardChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onClear,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: AppTheme.commonShadows,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.close,
                size: 12,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
