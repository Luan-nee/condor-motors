import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../models/producto.model.dart';
import '../../../models/sucursal.model.dart';

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
  /// considerando la gravedad de los problemas (agotados primero) y la cantidad de sucursales afectadas
  static List<Producto> reorganizarProductosPorPrioridad(
    List<Producto> productos, {
    Map<int, Map<String, int>>? stockPorSucursal,
    List<Sucursal>? sucursales,
  }) {
    // Si no hay productos, retornar lista vacía
    if (productos.isEmpty) {
      return [];
    }
    
    // Si tenemos datos de stock por sucursal, podemos hacer una priorización más sofisticada
    if (stockPorSucursal != null && sucursales != null && sucursales.isNotEmpty) {
      // Crear una lista con puntuación de prioridad para cada producto
      final productosConPuntuacion = productos.map((producto) {
        // Inicializamos la puntuación
        int puntuacion = 0;
        int sucursalesAgotadas = 0;
        int sucursalesStockBajo = 0;
        double porcentajeAgotado = 0.0;
        
        // Obtener el stock mínimo del producto
        final stockMinimo = producto.stockMinimo ?? 0;
        
        // Revisar el stock en cada sucursal
        for (final sucursal in sucursales) {
          final stock = stockPorSucursal[producto.id]?[sucursal.id] ?? 0;
          
          // Asignar puntos según el estado del stock en cada sucursal
          if (stock <= 0) {
            // Producto agotado en esta sucursal: 5 puntos (aumentado de 3)
            puntuacion += 5;
            sucursalesAgotadas++;
          } else if (stock < stockMinimo) {
            // Producto con stock bajo en esta sucursal: 2 puntos (aumentado de 1)
            puntuacion += 2;
            sucursalesStockBajo++;
          }
        }
        
        // Calcular porcentaje de sucursales donde el producto está agotado
        if (sucursales.isNotEmpty) {
          porcentajeAgotado = (sucursalesAgotadas / sucursales.length) * 100;
        }
        
        // Si está agotado en más del 50% de sucursales, doblar la puntuación
        if (porcentajeAgotado > 50) {
          puntuacion *= 2;
        } 
        // Si está agotado en más del 25% de sucursales, aumentar 50% la puntuación
        else if (porcentajeAgotado > 25) {
          puntuacion = (puntuacion * 1.5).round();
        }
        
        // Si tiene stock bajo en más del 75% de sucursales, aumentar puntuación
        if (sucursales.isNotEmpty && sucursalesStockBajo / sucursales.length > 0.75) {
          puntuacion += 10;
        }
        
        // Productos completamente agotados en todas las sucursales tienen máxima prioridad
        if (porcentajeAgotado == 100 && sucursales.length > 1) {
          puntuacion += 100; // Valor muy alto para garantizar que aparezcan primero
        }
        
        // Productos agotados en la sucursal principal (ID = 1) tienen prioridad adicional
        final stockSucursalPrincipal = stockPorSucursal[producto.id]?['1'] ?? -1;
        if (stockSucursalPrincipal == 0) {
          puntuacion += 50; // Prioridad alta para productos agotados en la sucursal principal
        }
        
        // Para productos de alta rotación o críticos, se puede dar prioridad adicional
        // (aquí podríamos agregar lógica basada en categoría, marca u otras propiedades)
        final esCategoriaImportante = producto.categoria.toLowerCase().contains('repuesto') || 
                                     producto.categoria.toLowerCase().contains('motor');
        if (esCategoriaImportante && (sucursalesAgotadas > 0 || sucursalesStockBajo > 0)) {
          puntuacion += 25;
        }
        
        // Log de depuración para verificar puntuaciones
        if (puntuacion > 100) {
          debugPrint('Producto ${producto.nombre} (ID ${producto.id}) tiene puntuación alta: $puntuacion. ' +
                   'Agotado en $sucursalesAgotadas sucursales (${porcentajeAgotado.round()}%)');
        }
        
        // Retornar el producto y su puntuación
        return (producto: producto, puntuacion: puntuacion);
      }).toList();
      
      // Ordenar por puntuación (mayor a menor)
      productosConPuntuacion.sort((a, b) => b.puntuacion.compareTo(a.puntuacion));
      
      // Retornar solo los productos, ya ordenados por prioridad
      return productosConPuntuacion.map((p) => p.producto).toList();
    }
    
    // Si no tenemos datos de stock por sucursal, usar el método original
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
  
  /// Genera un resumen de stock para todas las sucursales
  /// Retorna un mapa con el total de productos por estado y sucursal
  static Map<String, Map<StockStatus, int>> generarResumenStockPorSucursal(
    Map<int, Map<String, int>> stockPorSucursal,
    List<Producto> productos,
    List<Sucursal> sucursales
  ) {
    final Map<String, Map<StockStatus, int>> resumen = {};
    
    // Inicializar el resumen para cada sucursal
    for (final sucursal in sucursales) {
      resumen[sucursal.id] = {
        StockStatus.agotado: 0,
        StockStatus.stockBajo: 0,
        StockStatus.disponible: 0,
      };
    }
    
    // Procesar cada producto
    for (final producto in productos) {
      final stockMinimo = producto.stockMinimo ?? 0;
      
      // Revisar el stock en cada sucursal
      for (final sucursal in sucursales) {
        final stock = stockPorSucursal[producto.id]?[sucursal.id] ?? 0;
        final estado = getStockStatus(stock, stockMinimo);
        
        // Incrementar el contador para este estado en esta sucursal
        resumen[sucursal.id]![estado] = (resumen[sucursal.id]![estado] ?? 0) + 1;
      }
    }
    
    return resumen;
  }
  
  /// Calcula el porcentaje de productos con problemas por sucursal
  /// Útil para destacar las sucursales con más problemas de stock
  static Map<String, double> calcularPorcentajeProblemasPorSucursal(
    Map<String, Map<StockStatus, int>> resumenStock
  ) {
    final Map<String, double> porcentajes = {};
    
    for (final entry in resumenStock.entries) {
      final sucursalId = entry.key;
      final estados = entry.value;
      
      final totalProductos = estados.values.fold<int>(0, (sum, count) => sum + count);
      final productosConProblemas = (estados[StockStatus.agotado] ?? 0) + 
                                    (estados[StockStatus.stockBajo] ?? 0);
      
      if (totalProductos > 0) {
        porcentajes[sucursalId] = (productosConProblemas / totalProductos) * 100;
      } else {
        porcentajes[sucursalId] = 0;
      }
    }
    
    return porcentajes;
  }
  
  /// Obtiene las sucursales con mayor porcentaje de problemas de stock
  /// Retorna una lista ordenada de IDs de sucursales
  static List<String> obtenerSucursalesConMasProblemas(
    Map<String, double> porcentajesProblemas,
    {int limite = 3}
  ) {
    final entries = porcentajesProblemas.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return entries.take(limite).map((e) => e.key).toList();
  }
  
  /// Verifica si una sucursal tiene problemas críticos de stock
  /// Retorna true si más del umbral especificado de productos tienen problemas
  static bool sucursalTieneProblemasCriticos(
    String sucursalId,
    Map<String, Map<StockStatus, int>> resumenStock,
    {double umbralPorcentaje = 30.0}
  ) {
    final estados = resumenStock[sucursalId];
    if (estados == null) return false;
    
    final totalProductos = estados.values.fold<int>(0, (sum, count) => sum + count);
    if (totalProductos == 0) return false;
    
    final productosConProblemas = (estados[StockStatus.agotado] ?? 0) + 
                                  (estados[StockStatus.stockBajo] ?? 0);
    
    final porcentaje = (productosConProblemas / totalProductos) * 100;
    return porcentaje >= umbralPorcentaje;
  }
}

/// Enumeración para el estado del stock de un producto
enum StockStatus {
  agotado,
  stockBajo,
  disponible,
} 