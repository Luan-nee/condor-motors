import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../api/protected/proforma.api.dart';
import '../../../main.dart' show api;

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

  /// Convierte una lista de objetos ProformaVenta a formato compatible con ventasPendientes
  /// 
  /// [proformas] - Lista de objetos ProformaVenta a convertir
  /// 
  /// Retorna una lista de mapas con el formato necesario para PendingSalesWidget
  static List<Map<String, dynamic>> convertirProformasAVentasPendientes(
    List<ProformaVenta> proformas
  ) {
    return proformas.map((proforma) {
      return convertirProformaAVentaPendiente(proforma);
    }).toList();
  }

  /// Convierte un objeto ProformaVenta individual a formato compatible con ventasPendientes
  /// 
  /// [proforma] - Objeto ProformaVenta a convertir
  /// 
  /// Retorna un mapa con el formato necesario para PendingSalesWidget
  static Map<String, dynamic> convertirProformaAVentaPendiente(ProformaVenta proforma) {
    // Obtener datos del cliente, o crear uno genérico si no existe
    final cliente = proforma.cliente ?? {
      'id': 0,
      'nombre': 'Cliente sin nombre',
      'documento': 'Sin documento',
      'telefono': '',
    };

    // Convertir detalles de proforma a formato de productos
    final productos = proforma.detalles.map((detalle) {
      return {
        'id': detalle.productoId,
        'nombre': detalle.nombre,
        'precio': detalle.precioUnitario,
        'cantidad': detalle.cantidad,
      };
    }).toList();

    // Crear estructura de venta pendiente
    return {
      'id': 'PRO-${proforma.id}', // Prefijo para identificar que es una proforma
      'cliente': cliente,
      'productos': productos,
      'total': proforma.total,
      'fecha': proforma.createdAt.toIso8601String(),
      'estado': 'PENDIENTE',
      'empleadoId': proforma.empleadoId,
      'proformaId': proforma.id,
    };
  }

  /// Verifica si un ID de venta corresponde a una proforma
  /// 
  /// [id] - ID de venta a verificar
  /// 
  /// Retorna true si es una proforma, false en caso contrario
  static bool esProforma(String id) {
    return id.startsWith('PRO-');
  }

  /// Extrae el ID numérico de una proforma del formato "PRO-X"
  /// 
  /// [id] - ID con formato "PRO-X"
  /// 
  /// Retorna el ID numérico, o null si el formato es inválido
  static int? extraerIdProforma(String id) {
    if (!esProforma(id)) return null;
    
    try {
      return int.parse(id.substring(4)); // Quitar "PRO-" y convertir a entero
    } catch (e) {
      debugPrint('Error al extraer ID de proforma: $e');
      return null;
    }
  }
  
  /// Formatea una fecha en formato legible
  /// 
  /// [fecha] - Fecha a formatear
  /// 
  /// Retorna la fecha formateada como string (ej: "01/01/2023 15:30")
  static String formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }
}
