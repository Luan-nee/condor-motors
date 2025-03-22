import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../api/protected/stocks.api.dart';
import '../../../models/producto.model.dart';

/// Clase de utilidades para funciones comunes relacionadas con stock e inventario
class StockUtils {
  /// Determina el color del indicador de stock basado en la cantidad actual vs mínima
  static Color getStockStatusColor(int stockActual, int stockMinimo) {
    if (stockActual <= 0) {
      return Colors.red.shade800; // Sin stock
    } else if (stockActual < stockMinimo) {
      return const Color(0xFFE31E24); // Stock bajo
    } else {
      return Colors.green; // Stock normal
    }
  }
  
  /// Determina el icono para el estado del stock
  static IconData getStockStatusIcon(int stockActual, int stockMinimo) {
    if (stockActual <= 0) {
      return FontAwesomeIcons.ban; // Sin stock
    } else if (stockActual < stockMinimo) {
      return FontAwesomeIcons.triangleExclamation; // Stock bajo
    } else {
      return FontAwesomeIcons.check; // Stock normal
    }
  }
  
  /// Formatea el valor del inventario como moneda
  static String formatCurrency(double value) {
    return 'S/ ${value.toStringAsFixed(2)}';
  }
  
  /// Filtra productos por sucursal
  static List<Map<String, dynamic>> filtrarProductosPorSucursal(
    List<Map<String, dynamic>> productos, 
    String sucursalId
  ) {
    if (sucursalId.isEmpty) {
      return productos;
    }
    
    return productos.where((producto) => 
      producto['sucursalId']?.toString() == sucursalId || 
      producto['sucursal_id']?.toString() == sucursalId
    ).toList();
  }
  
  /// Verifica si un producto tiene stock bajo
  static bool tieneStockBajo(Map<String, dynamic> producto) {
    final stockActual = producto['stock_actual'] as int? ?? 0;
    final stockMinimo = producto['stock_minimo'] as int? ?? 0;
    return stockActual < stockMinimo && stockActual > 0;
  }
  
  /// Verifica si un producto está sin stock
  static bool sinStock(Map<String, dynamic> producto) {
    final stockActual = producto['stock_actual'] as int? ?? 0;
    return stockActual <= 0;
  }
  
  /// Verifica si un producto tiene stock bajo utilizando el modelo Producto
  static bool tieneStockBajoFromProducto(Producto producto) {
    final stockActual = producto.stock;
    final stockMinimo = producto.stockMinimo ?? 0;
    return stockActual < stockMinimo && stockActual > 0;
  }
  
  /// Verifica si un producto está sin stock utilizando el modelo Producto
  static bool sinStockFromProducto(Producto producto) {
    return producto.stock <= 0;
  }
  
  /// Obtiene el estado del stock como texto
  static String getStockStatusText(int stockActual, int stockMinimo) {
    if (stockActual <= 0) {
      return 'Agotado';
    } else if (stockActual < stockMinimo) {
      return 'Stock bajo';
    } else {
      return 'Disponible';
    }
  }
  
  /// Prepara los datos para usar con la API real
  static Future<List<Map<String, dynamic>>> getStockData(StocksApi stocksApi, String sucursalId) async {
    try {
      if (sucursalId.isEmpty) {
        return [];
      }
      
      // TODO: Implementar llamada real a la API cuando esté listo
      // Por ahora devolvemos datos de ejemplo
      return [
        {
          'nombre': 'Producto de ejemplo',
          'stock_actual': 10,
          'stock_minimo': 5,
          'stock_maximo': 100,
          'sucursalId': sucursalId
        }
      ];
      
      // Implementación futura:
      // final stockData = await stocksApi.getStockBySucursal(sucursalId: sucursalId);
      // return stockData.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error al obtener datos de stock: $e');
      return [];
    }
  }
} 