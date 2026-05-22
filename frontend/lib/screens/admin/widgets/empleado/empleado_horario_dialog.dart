import 'package:condorsmotors/models/empleado.model.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:condorsmotors/utils/empleados_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget para mostrar información del horario del empleado
///
/// Puede ser usado como un componente dentro de otros widgets o como un diálogo
class EmpleadoHorarioViewer extends StatelessWidget {
  final Empleado empleado;
  final bool showTitle;
  final Color? backgroundColor;
  final double width;

  const EmpleadoHorarioViewer({
    super.key,
    required this.empleado,
    this.showTitle = true,
    this.backgroundColor,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    // Formatear las horas para asegurar que no tengan segundos
    final String horaInicio =
        EmpleadosUtils.formatearHora(empleado.horaInicioJornada);
    final String horaFin =
        EmpleadosUtils.formatearHora(empleado.horaFinJornada);

    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (showTitle) ...<Widget>[
            const Row(
              children: <Widget>[
                FaIcon(
                  FontAwesomeIcons.clock,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'HORARIO LABORAL',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Horario
          Column(
            children: <Widget>[
              _buildHorarioItem(
                'Hora de inicio',
                horaInicio,
                FontAwesomeIcons.solidClock,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Colors.white24),
              ),
              _buildHorarioItem(
                'Hora de fin',
                horaFin,
                FontAwesomeIcons.solidClock,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget para mostrar un elemento de horario
  Widget _buildHorarioItem(String label, String value, FaIconData icon) {
    return Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          ),
          child: Center(
            child: FaIcon(
              icon,
              color: AppTheme.primaryColor,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Empleado>('empleado', empleado))
      ..add(DiagnosticsProperty<bool>('showTitle', showTitle))
      ..add(ColorProperty('backgroundColor', backgroundColor))
      ..add(DoubleProperty('width', width));
  }
}

/// Diálogo para mostrar el horario de un empleado
class EmpleadoHorarioDialog extends StatelessWidget {
  final Empleado empleado;

  const EmpleadoHorarioDialog({
    super.key,
    required this.empleado,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const FaIcon(
                  FontAwesomeIcons.clock,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Horario de ${empleado.nombre}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Reutilizamos el widget EmpleadoHorarioViewer
            EmpleadoHorarioViewer(
              empleado: empleado,
              showTitle: false,
            ),

            const SizedBox(height: 24),

            // Botón para cerrar
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Empleado>('empleado', empleado));
  }
}
