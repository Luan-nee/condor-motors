import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../main.dart' show api;
import '../../../models/proforma.model.dart';

/// Utilidades para manejar proformas y ventas pendientes
class VentasPendientesUtils {
  /// Obtiene el ID de sucursal del usuario autenticado
  /// 
  /// Retorna el ID como entero, o null si no se encuentra
  static Future<int?> obtenerSucursalId() async {
    try {
      final userData = await api.authService.getUserData();
      if (userData != null && userData.containsKey('sucursalId')) {
        try {
          return int.parse(userData['sucursalId'].toString());
        } catch (e) {
          debugPrint('Error al parsear sucursalId: $e');
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener datos del usuario: $e');
      return null;
    }
  }

  /// Convierte una lista de objetos Proforma a formato compatible con ventasPendientes
  /// 
  /// [proformas] - Lista de objetos Proforma a convertir
  /// 
  /// Retorna una lista de mapas con el formato necesario para PendingSalesWidget
  static List<Map<String, dynamic>> convertirProformasAVentasPendientes(
    List<Proforma> proformas
  ) {
    return proformas.map((proforma) {
      return convertirProformaAVentaPendiente(proforma);
    }).toList();
  }

  /// Convierte un objeto Proforma individual a formato compatible con ventasPendientes
  /// 
  /// [proforma] - Objeto Proforma a convertir
  /// 
  /// Retorna un mapa con el formato necesario para PendingSalesWidget
  static Map<String, dynamic> convertirProformaAVentaPendiente(Proforma proforma) {
    // Obtener datos del cliente, o crear uno genérico si no existe
    final cliente = proforma.cliente ?? {
      'id': 0,
      'nombre': 'Cliente sin nombre',
    };

    return {
      'id': proforma.id,
      'nombre': proforma.nombre ?? 'Proforma #${proforma.id}',
      'total': proforma.total,
      'fecha': formatearFecha(proforma.fechaCreacion),
      'tipoDocumento': 'PROFORMA',
      'cliente': cliente,
      'sucursalId': proforma.sucursalId,
      'detalles': proforma.detalles,
      'empleadoId': proforma.empleadoId,
      'tipoVenta': 'PROFORMA', // Tipo para diferenciar en la lista
    };
  }

  /// Verifica si un ID de venta corresponde a una proforma
  /// 
  /// [id] - ID de venta a verificar
  /// [tipoVenta] - Si se proporciona, se verifica este campo directamente
  /// 
  /// Retorna true si es una proforma, false en caso contrario
  static bool esProforma(String id, {String? tipoVenta}) {
    // Si se proporciona el tipo de venta, usarlo directamente
    if (tipoVenta != null) {
      return tipoVenta == 'PROFORMA';
    }
    
    // Para compatibilidad con el formato antiguo
    if (id.startsWith('PRO-')) {
      return true;
    }
    
    return false;
  }

  /// Extrae el ID numérico de una proforma
  /// 
  /// [id] - ID de proforma, ya sea en formato numérico directo o "PRO-X"
  /// 
  /// Retorna el ID numérico, o null si el formato es inválido
  static int? extraerIdProforma(String id) {
    // Primero intentar parsear directamente (nuevo formato)
    try {
      return int.parse(id);
    } catch (_) {
      // Si falla, intentar el formato antiguo
      if (id.startsWith('PRO-')) {
        try {
          return int.parse(id.substring(4)); // Quitar "PRO-" y convertir a entero
        } catch (e) {
          debugPrint('Error al extraer ID de proforma: $e');
        }
      }
    }
    
    return null;
  }
  
  /// Formatea una fecha para mostrar
  /// 
  /// [fecha] - Fecha a formatear
  /// 
  /// Retorna un string con el formato: "dd/MM/yyyy HH:mm"
  static String formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }
}
