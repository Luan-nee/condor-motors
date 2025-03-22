import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  
  /// Verifica si un producto tiene problemas de stock (agotado o bajo)
  static bool tieneProblemasStock(Producto producto) {
    return sinStockFromProducto(producto) || tieneStockBajoFromProducto(producto);
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
  
  /// Obtiene el estado del stock como enumeración
  static StockStatus getStockStatus(int stockActual, int stockMinimo) {
    if (stockActual <= 0) {
      return StockStatus.agotado;
    } else if (stockActual < stockMinimo) {
      return StockStatus.stockBajo;
    } else {
      return StockStatus.disponible;
    }
  }

  /// Agrupa los productos por estado de stock (agotados, stock bajo, disponibles)
  static Map<StockStatus, List<Producto>> agruparProductosPorEstadoStock(List<Producto> productos) {
    final Map<StockStatus, List<Producto>> grupos = {
      StockStatus.agotado: [],
      StockStatus.stockBajo: [],
      StockStatus.disponible: [],
    };
    
    for (final producto in productos) {
      final status = getStockStatus(producto.stock, producto.stockMinimo ?? 0);
      grupos[status]!.add(producto);
    }
    
    return grupos;
  }
  
  /// Reorganiza la lista de productos para priorizar los que tienen problemas de stock
  static List<Producto> reorganizarProductosPorPrioridad(List<Producto> productos) {
    final grupos = agruparProductosPorEstadoStock(productos);
    
    // Unir las listas en el orden de prioridad: agotados primero, luego stock bajo, finalmente disponibles
    return [
      ...grupos[StockStatus.agotado]!,
      ...grupos[StockStatus.stockBajo]!,
      ...grupos[StockStatus.disponible]!,
    ];
  }
  
  /// Método para combinar productos con el mismo ID pero de diferentes sucursales
  /// Útil cuando se consolidan productos de múltiples consultas de paginación
  static List<Producto> consolidarProductosUnicos(List<Producto> productos) {
    final Map<int, Producto> productosMap = {};
    
    for (final producto in productos) {
      if (!productosMap.containsKey(producto.id) || 
          tieneProblemasStock(producto)) {
        // Priorizamos productos con problemas de stock
        productosMap[producto.id] = producto;
      }
    }
    
    return productosMap.values.toList();
  }
  
  /// Filtra productos que tienen problemas de stock (agotados o stock bajo)
  static List<Producto> filtrarProductosConProblemasStock(List<Producto> productos) {
    return productos.where((producto) => 
      sinStockFromProducto(producto) || tieneStockBajoFromProducto(producto)
    ).toList();
  }
  
  /// Filtra productos por un estado específico de stock
  static List<Producto> filtrarPorEstadoStock(List<Producto> productos, StockStatus estado) {
    return productos.where((producto) => 
      getStockStatus(producto.stock, producto.stockMinimo ?? 0) == estado
    ).toList();
  }
}

/// Enumeración para el estado del stock de un producto
enum StockStatus {
  agotado,
  stockBajo,
  disponible,
} 