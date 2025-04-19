import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Utilidades para el manejo de sucursales
class SucursalUtils {
  /// Color principal para sucursales centrales
  static const Color colorCentral = Color(0xFFE31E24);

  /// Color para sucursales locales
  static const Color colorLocal = Colors.white70;

  /// Tipos de sucursales disponibles
  static const List<String> tiposSucursal = ['Todos', 'Central', 'Sucursal'];

  /// Obtiene el icono apropiado para una sucursal basado en su tipo y nombre
  static IconData getIconForSucursal(Sucursal sucursal) {
    // Primero revisamos si es sucursal central
    if (sucursal.sucursalCentral) {
      return FontAwesomeIcons.building;
    }

    // Luego revisamos el nombre
    final String nombre = sucursal.nombre.toLowerCase();
    if (nombre.contains('central') || nombre.contains('principal')) {
      return FontAwesomeIcons.buildingColumns;
    } else if (nombre.contains('taller')) {
      return FontAwesomeIcons.buildingShield;
    } else if (nombre.contains('almacén') ||
        nombre.contains('almacen') ||
        nombre.contains('bodega')) {
      return FontAwesomeIcons.warehouse;
    } else if (nombre.contains('tienda') || nombre.contains('venta')) {
      return FontAwesomeIcons.buildingLock;
    }
    // Icono por defecto para otras sucursales
    // Opciones disponibles para locales:
    // return FontAwesomeIcons.shop;           // Tienda/Local comercial
    // return FontAwesomeIcons.store;          // Tienda más moderna
    // return FontAwesomeIcons.storeAlt;       // Tienda alternativa
    // return FontAwesomeIcons.house;          // Casa/Local pequeño
    return FontAwesomeIcons.store; // Tienda moderna (más comercial)
  }

  /// Obtiene el color para una sucursal basado en su tipo
  static Color getColorForSucursal(Sucursal sucursal) {
    return sucursal.sucursalCentral ? colorCentral : colorLocal;
  }

  /// Obtiene el color de fondo para el contenedor del icono
  static Color getIconBackgroundColor(Sucursal sucursal) {
    return sucursal.sucursalCentral
        ? colorCentral.withOpacity(0.1)
        : const Color(0xFF2D2D2D);
  }

  /// Obtiene el tipo de sucursal como texto
  static String getTipoSucursal(Sucursal sucursal) {
    return sucursal.sucursalCentral ? 'CENTRAL' : 'LOCAL';
  }

  /// Obtiene el estilo para mostrar el tipo de sucursal
  static Widget buildTipoSucursalBadge(Sucursal sucursal) {
    if (!sucursal.sucursalCentral) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorCentral.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'CENTRAL',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: colorCentral,
        ),
      ),
    );
  }

  /// Construye un widget para mostrar el código de establecimiento
  static Widget buildCodigoEstablecimiento(String? codigo) {
    if (codigo == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FaIcon(
            FontAwesomeIcons.buildingUser,
            size: 10,
            color: Colors.white54,
          ),
          const SizedBox(width: 4),
          Text(
            codigo,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye un widget para mostrar información de serie (factura o boleta)
  static Widget buildSerieInfo(String? serie, int? numeroInicial) {
    if (serie == null) {
      return const Text(
        'No configurado',
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: Colors.white38,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            serie,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        if (numeroInicial != null) ...[
          const SizedBox(height: 4),
          Text(
            'Desde: $numeroInicial',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white54,
            ),
          ),
        ],
      ],
    );
  }

  /// Valida una serie de factura o boleta
  static String? validarSerie(String? value, String tipo) {
    if (value != null && value.isNotEmpty) {
      final String prefijo = tipo == 'factura' ? 'F' : 'B';
      if (!value.startsWith(prefijo) || value.length != 4) {
        return 'La serie debe empezar con $prefijo y tener 4 caracteres';
      }
    }
    return null;
  }

  /// Valida un número inicial de factura o boleta
  static String? validarNumeroInicial(String? value) {
    if (value != null && value.isNotEmpty) {
      if (int.tryParse(value) == null || int.parse(value) < 1) {
        return 'Debe ser un número positivo';
      }
    }
    return null;
  }
}
