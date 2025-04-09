import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TransferenciasUtils {
  /// Obtiene el color asociado a un estado de transferencia
  static Color getEstadoColor(EstadoTransferencia estado) {
    switch (estado) {
      case EstadoTransferencia.pedido:
        return const Color(0xFFFFA000); // Naranja
      case EstadoTransferencia.enviado:
        return const Color(0xFF2196F3); // Azul
      case EstadoTransferencia.recibido:
        return const Color(0xFF43A047); // Verde
    }
  }

  /// Obtiene el icono asociado a un estado de transferencia
  static IconData getEstadoIcon(EstadoTransferencia estado) {
    switch (estado) {
      case EstadoTransferencia.pedido:
        return FontAwesomeIcons.clock;
      case EstadoTransferencia.enviado:
        return FontAwesomeIcons.truckFast;
      case EstadoTransferencia.recibido:
        return FontAwesomeIcons.checkDouble;
    }
  }

  /// Obtiene el estilo completo para un estado de transferencia
  static Map<String, dynamic> getEstadoEstilo(EstadoTransferencia estado) {
    final Color color = getEstadoColor(estado);
    final IconData icon = getEstadoIcon(estado);

    return {
      'backgroundColor': color.withOpacity(0.1),
      'textColor': color,
      'iconData': icon,
      'tooltipText': _getEstadoTooltip(estado),
      'estadoDisplay': estado.nombre,
    };
  }

  /// Obtiene el texto de ayuda para un estado de transferencia
  static String _getEstadoTooltip(EstadoTransferencia estado) {
    switch (estado) {
      case EstadoTransferencia.pedido:
        return 'Transferencia solicitada';
      case EstadoTransferencia.enviado:
        return 'En tránsito';
      case EstadoTransferencia.recibido:
        return 'Transferencia completada';
    }
  }

  /// Obtiene los pasos del proceso de transferencia
  static List<Map<String, dynamic>> getTransferenciaSteps(
      TransferenciaInventario transferencia) {
    return [
      {
        'title': EstadoTransferencia.pedido.nombre,
        'subtitle': 'Solicitada',
        'icon': FontAwesomeIcons.clock,
        'date': transferencia.salidaOrigen,
        'isCompleted': true,
        'color': getEstadoColor(EstadoTransferencia.pedido),
      },
      {
        'title': EstadoTransferencia.enviado.nombre,
        'subtitle': 'En tránsito',
        'icon': FontAwesomeIcons.truckFast,
        'date': null,
        'isCompleted': transferencia.estado == EstadoTransferencia.enviado ||
            transferencia.estado == EstadoTransferencia.recibido,
        'color': getEstadoColor(EstadoTransferencia.enviado),
      },
      {
        'title': EstadoTransferencia.recibido.nombre,
        'subtitle': 'Completada',
        'icon': FontAwesomeIcons.checkDouble,
        'date': transferencia.llegadaDestino,
        'isCompleted': transferencia.estado == EstadoTransferencia.recibido,
        'color': getEstadoColor(EstadoTransferencia.recibido),
      },
    ];
  }

  /// Obtiene el estilo para el badge de cantidad de productos
  static BoxDecoration getProductCountBadgeStyle() {
    return BoxDecoration(
      color: const Color(0xFFE31E24).withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFFE31E24).withOpacity(0.3),
      ),
    );
  }

  /// Obtiene el estilo para el contenedor de estado
  static BoxDecoration getEstadoContainerStyle(EstadoTransferencia estado) {
    final Color color = getEstadoColor(estado);
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: color.withOpacity(0.3),
      ),
    );
  }
}
