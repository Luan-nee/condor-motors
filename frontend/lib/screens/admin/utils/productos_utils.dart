import 'package:flutter/material.dart';

import '../../../main.dart' show api;
import '../../../models/producto.model.dart';
import '../../../models/sucursal.model.dart';

/// Clase para representar el stock de un producto en una sucursal
class ProductoEnSucursal {
  final Sucursal sucursal;
  final Producto producto;
  final bool disponible;
  
  const ProductoEnSucursal({
    required this.sucursal,
    required this.producto,
    this.disponible = true,
  });
}

/// Clase de utilidad para funciones relacionadas con productos
class ProductosUtils {
  /// Obtiene la lista de categorías desde la API
  static Future<List<String>> obtenerCategorias() async {
    try {
      final categorias = await api.categorias.getCategorias();
      // Extraer nombres de categorías 
      final listaCategorias = categorias
          .map<String>((cat) => cat['nombre'] as String)
          .where((nombre) => nombre.isNotEmpty)
          .toList();
      
      // Ordenar alfabéticamente
      listaCategorias.sort();
      
      return listaCategorias;
    } catch (e) {
      debugPrint('Error al obtener categorías: $e');
      // Si falla, retornar una lista predefinida
      return const [
        'Motor',
        'Cascos',
        'Accesorios',
        'Repuestos',
        'Lubricantes',
        'Herramientas',
      ];
    }
  }

  /// Obtiene la lista de marcas desde la API
  static Future<List<String>> obtenerMarcas() async {
    try {
      final marcas = await api.marcas.getMarcas();
      
      // Extraer nombres de marcas usando la notación de punto
      final listaMarcas = marcas
          .map<String>((marca) => marca.nombre)
          .where((nombre) => nombre.isNotEmpty)
          .toList();
      
      // Ordenar alfabéticamente
      listaMarcas.sort();
      
      return listaMarcas;
    } catch (e) {
      debugPrint('Error al obtener marcas: $e');
      return const ['Genérico', 'Honda', 'Yamaha', 'Suzuki', 'Bajaj', 'TVS'];
    }
  }

  /// Filtra productos según criterios de búsqueda y categoría
  static List<Producto> filtrarProductos({
    required List<Producto> productos,
    required String searchQuery,
    required String selectedCategory,
  }) {
    if (productos.isEmpty) {
      return [];
    }

    final String query = searchQuery.toLowerCase().trim();
    
    return productos.where((producto) {
      // Filtro por categoría (si no es 'Todos')
      if (selectedCategory != 'Todos' && 
          producto.categoria.toLowerCase() != selectedCategory.toLowerCase()) {
        return false;
      }
      
      // Si no hay consulta de búsqueda, incluir el producto
      if (query.isEmpty) {
        return true;
      }
      
      // Buscar en nombre, SKU, marca y descripción
      return producto.nombre.toLowerCase().contains(query) ||
             (producto.sku.toLowerCase().contains(query)) ||
             (producto.marca.toLowerCase().contains(query)) ||
             (producto.descripcion != null && producto.descripcion!.toLowerCase().contains(query));
    }).toList();
  }

  /// Verifica si un producto tiene stock bajo
  static bool tieneStockBajo(Producto producto) {
    return producto.tieneStockBajo();
  }

  /// Calcula el margen de ganancia entre precio de compra y venta
  static double calcularMargen(double precioCompra, double precioVenta) {
    if (precioCompra <= 0) return 0;
    return ((precioVenta - precioCompra) / precioCompra) * 100;
  }

  /// Calcula la ganancia absoluta entre precio de compra y venta
  static double calcularGanancia(double precioCompra, double precioVenta) {
    return precioVenta - precioCompra;
  }

  /// Formatea el porcentaje con símbolo y 2 decimales
  static String formatearPorcentaje(double porcentaje) {
    return '${porcentaje.toStringAsFixed(2)}%';
  }

  /// Obtiene el color apropiado para mostrar el estado del stock
  static bool esStockCritico(Producto producto) {
    final minimo = producto.stockMinimo ?? 0;
    // Stock crítico: menos del 50% del stock mínimo
    return producto.stock < (minimo * 0.5);
  }

  // Formatear precio a string (en soles)
  static String formatearPrecio(double precio) {
    return 'S/ ${precio.toStringAsFixed(2)}';
  }

  // Obtener color según el estado del stock
  static Color getColorStock(Producto producto) {
    if (tieneStockBajo(producto)) {
      return const Color(0xFFE31E24);
    }
    return Colors.white;
  }
  
  /// Comprueba la disponibilidad de un producto en todas las sucursales
  static Future<List<ProductoEnSucursal>> obtenerProductoEnSucursales({
    required int productoId,
    required List<Sucursal> sucursales,
  }) async {
    final List<ProductoEnSucursal> resultados = [];
    
    try {
      // Obtener todas las sucursales si no se proporcionaron
      final List<Sucursal> listaSucursales = sucursales.isNotEmpty 
          ? sucursales 
          : await api.sucursales.getSucursales();
          
      // Consultar en paralelo para mayor eficiencia
      final futures = listaSucursales.map((sucursal) async {
        try {
          final producto = await api.productos.getProducto(
            sucursalId: sucursal.id,
            productoId: productoId,
          );
          
          return ProductoEnSucursal(
            sucursal: sucursal,
            producto: producto,
          );
        } catch (e) {
          // Si hay un error, asumimos que el producto no está disponible
          debugPrint('Producto $productoId no disponible en sucursal ${sucursal.id}: $e');
          
          // Creamos un objeto ficticio para representar la no disponibilidad
          return ProductoEnSucursal(
            sucursal: sucursal,
            producto: Producto(
              id: productoId,
              sku: '',
              nombre: '',
              categoria: '',
              marca: '',
              fechaCreacion: DateTime.now(),
              precioCompra: 0,
              precioVenta: 0,
              stock: 0,
              stockBajo: true,
            ),
            disponible: false,
          );
        }
      }).toList();
      
      // Esperar a que se completen todas las consultas
      resultados.addAll(await Future.wait(futures));
      
      // Ordenar: primero sucursales con producto disponible, luego las centrales
      resultados.sort((a, b) {
        // Primero por disponibilidad (disponibles primero)
        if (a.disponible != b.disponible) {
          return a.disponible ? -1 : 1;
        }
        
        // Luego por tipo de sucursal (centrales primero)
        if (a.sucursal.sucursalCentral != b.sucursal.sucursalCentral) {
          return a.sucursal.sucursalCentral ? -1 : 1;
        }
        
        // Finalmente por nombre de sucursal
        return a.sucursal.nombre.compareTo(b.sucursal.nombre);
      });
      
      return resultados;
    } catch (e) {
      debugPrint('Error al obtener producto en sucursales: $e');
      return resultados;
    }
  }
  
  /// Agrupa los productos por su disponibilidad en: disponibles, stock bajo y agotados
  static Map<String, List<Producto>> agruparProductosPorDisponibilidad(List<Producto> productos) {
    final Map<String, List<Producto>> resultado = {
      'disponibles': [],
      'stockBajo': [],
      'agotados': [],
    };

    for (final producto in productos) {
      if (producto.stock <= 0) {
        resultado['agotados']!.add(producto);
      } else if (producto.tieneStockBajo()) {
        resultado['stockBajo']!.add(producto);
      } else {
        resultado['disponibles']!.add(producto);
      }
    }

    return resultado;
  }
}
