import 'package:condorsmotors/models/categoria.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/utils/productos_utils.dart';
import 'package:flutter/foundation.dart';

/// Tipos de descuento disponibles para filtrar productos
enum TipoDescuento {
  todos,
  liquidacion,
  promoGratis,
  descuentoPorcentual,
}

/// Utilidades para el manejo de búsqueda y filtrado de productos
class BusquedaProductoUtils {
  /// Normaliza una categoría para unificar 'Todos'/'Todas'
  static String normalizarCategoria(String categoria) {
    if (categoria.isEmpty) {
      return 'Todos'; // Categoría vacía se considera como "Todos"
    }

    final String categoriaLC = categoria.trim().toLowerCase();
    if (categoriaLC == 'todas' ||
        categoriaLC == 'todos' ||
        categoriaLC == 'all') {
      return 'Todos'; // Normalizar a 'Todos' como estándar
    }
    return categoria
        .trim(); // Mantener mayúsculas/minúsculas originales, pero quitar espacios
  }

  /// Verifica si una categoría es la opción "todos/todas"
  static bool esCategoriaTodos(String categoria) {
    if (categoria.isEmpty) {
      return true; // Categoría vacía se considera como "Todos"
    }

    final String categoriaLC = categoria.trim().toLowerCase();
    final bool esTodos = categoriaLC == 'todas' ||
        categoriaLC == 'todos' ||
        categoriaLC == 'all';
    if (esTodos) {
      debugPrint('✅ Categoría identificada como "Todos": "$categoria"');
    }
    return esTodos;
  }

  /// Verifica si los datos son compatibles con ProductosUtils
  static bool esFormatoCompatible(List<Map<String, dynamic>> productos) {
    if (productos.isEmpty) {
      return false;
    }

    // Verificar campos mínimos necesarios
    return productos.first.containsKey('nombre') &&
        productos.first.containsKey('categoria') &&
        productos.first.containsKey('codigo');
  }

  /// Convierte de Map<String, dynamic> a Producto para usar ProductosUtils
  static List<Producto> convertirAProductos(
      List<Map<String, dynamic>> productos) {
    return productos
        .map((Map<String, dynamic> p) => Producto(
              id: p['id'] is int
                  ? p['id']
                  : int.tryParse(p['id']?.toString() ?? '0') ?? 0,
              sku: p['codigo']?.toString() ?? '',
              nombre: p['nombre']?.toString() ?? '',
              categoria: p['categoria']?.toString() ?? '',
              categoriaId: p['categoriaId'] is int
                  ? p['categoriaId']
                  : int.tryParse(p['categoriaId']?.toString() ?? '0') ?? 0,
              marca: p['marca']?.toString() ?? '',
              marcaId: p['marcaId'] is int
                  ? p['marcaId']
                  : int.tryParse(p['marcaId']?.toString() ?? '0') ?? 0,
              fechaCreacion: DateTime.now(),
              precioCompra: 0, // No es relevante para filtrado
              precioVenta:
                  (p['precio'] is num) ? (p['precio'] as num).toDouble() : 0,
              stock: p['stock'] is int
                  ? p['stock']
                  : int.tryParse(p['stock']?.toString() ?? '0') ?? 0,
              stockMinimo: p['stockMinimo'] is int ? p['stockMinimo'] : null,
              // Añadir precio de liquidación y estado de liquidación
              precioOferta: p['precioLiquidacion'] is num
                  ? (p['precioLiquidacion'] as num).toDouble()
                  : null,
              liquidacion:
                  p['enLiquidacion'] == true || p['liquidacion'] == true,
              // Añadir información sobre promociones de descuento
              cantidadMinimaDescuento:
                  p['cantidadMinima'] is int ? p['cantidadMinima'] : null,
              cantidadGratisDescuento:
                  p['cantidadGratis'] is int ? p['cantidadGratis'] : null,
              porcentajeDescuento: p['descuentoPorcentaje'] is int
                  ? p['descuentoPorcentaje']
                  : null,
              // Campos opcionales
              stockBajo: p['stock'] != null && p['stockMinimo'] != null
                  ? p['stock'] < p['stockMinimo']
                  : false,
              descripcion: p['descripcion']?.toString(),
            ))
        .toList();
  }

  /// Convierte de Producto a Map<String, dynamic> para la UI
  static List<Map<String, dynamic>> convertirAMapas(List<Producto> productos) {
    return productos
        .map((Producto p) => <String, Object?>{
              'id': p.id,
              'codigo': p.sku,
              'nombre': p.nombre,
              'categoria': p.categoria,
              'marca': p.marca,
              'precio': p.precioVenta,
              'stock': p.stock,
              'stockMinimo': p.stockMinimo,
              // Añadir precio de liquidación y estado de liquidación
              'precioLiquidacion': p.precioOferta,
              'enLiquidacion': p.liquidacion,
              'liquidacion': p.liquidacion,
              // Agregar información de promociones
              'cantidadMinima': p.cantidadMinimaDescuento,
              'cantidadGratis': p.cantidadGratisDescuento,
              'descuentoPorcentaje': p.porcentajeDescuento,
              // Determinar si tiene promociones basado en los datos del modelo
              'tienePromocionGratis': p.cantidadGratisDescuento != null &&
                  p.cantidadGratisDescuento! > 0,
              'tieneDescuentoPorcentual': p.porcentajeDescuento != null &&
                  p.porcentajeDescuento! > 0 &&
                  p.cantidadMinimaDescuento != null &&
                  p.cantidadMinimaDescuento! > 0,
              // Agregar flag de promoción general para facilitar filtrado
              'tienePromocion': p.liquidacion ||
                  (p.cantidadGratisDescuento != null &&
                      p.cantidadGratisDescuento! > 0) ||
                  (p.porcentajeDescuento != null &&
                      p.porcentajeDescuento! > 0 &&
                      p.cantidadMinimaDescuento != null &&
                      p.cantidadMinimaDescuento! > 0),
            })
        .toList();
  }

  /// Filtra productos por tipo de descuento
  static List<Map<String, dynamic>> filtrarPorTipoDescuento(
      List<Map<String, dynamic>> productos, TipoDescuento tipoDescuento,
      {bool debugMode = false}) {
    if (tipoDescuento == TipoDescuento.todos) {
      return productos; // No aplicar filtro
    }

    if (debugMode) {
      debugPrint(
          '🔍 Aplicando filtro de tipo de descuento: $tipoDescuento a ${productos.length} productos');
    }

    // Antes de filtrar, verificar qué productos tienen cada tipo de promoción
    if (debugMode) {
      int conLiquidacion = 0;
      int conPromoGratis = 0;
      int conDescuentoPorcentual = 0;

      for (final Map<String, dynamic> producto in productos) {
        if (producto['enLiquidacion'] == true) {
          conLiquidacion++;
        }
        if (producto['tienePromocionGratis'] == true) {
          conPromoGratis++;
        }
        if (producto['tieneDescuentoPorcentual'] == true) {
          conDescuentoPorcentual++;
        }
      }

      debugPrint('📊 Productos con cada tipo de descuento:');
      debugPrint('- Liquidación: $conLiquidacion');
      debugPrint('- Promo "Lleva y Paga": $conPromoGratis');
      debugPrint('- Descuento porcentual: $conDescuentoPorcentual');
    }

    // Filtrar los productos según el tipo de descuento
    final List<Map<String, dynamic>> productosFiltrados =
        productos.where((Map<String, dynamic> producto) {
      bool cumpleFiltro = false;

      switch (tipoDescuento) {
        case TipoDescuento.liquidacion:
          cumpleFiltro = producto['enLiquidacion'] == true;
          break;
        case TipoDescuento.promoGratis:
          cumpleFiltro = producto['tienePromocionGratis'] == true;

          if (debugMode && !cumpleFiltro) {
            // Revisar por qué no cumple para posible diagnóstico
            if (producto['cantidadMinima'] != null &&
                producto['cantidadGratis'] != null) {
              debugPrint(
                  '⚠️ Producto ${producto['nombre']} tiene cantidadMinima=${producto['cantidadMinima']} y cantidadGratis=${producto['cantidadGratis']} pero tienePromocionGratis=${producto['tienePromocionGratis']}');
            }
          }
          break;
        case TipoDescuento.descuentoPorcentual:
          cumpleFiltro = producto['tieneDescuentoPorcentual'] == true;

          if (debugMode && !cumpleFiltro) {
            // Revisar por qué no cumple para posible diagnóstico
            if (producto['cantidadMinima'] != null &&
                producto['descuentoPorcentaje'] != null) {
              debugPrint(
                  '⚠️ Producto ${producto['nombre']} tiene cantidadMinima=${producto['cantidadMinima']} y descuentoPorcentaje=${producto['descuentoPorcentaje']} pero tieneDescuentoPorcentual=${producto['tieneDescuentoPorcentual']}');
            }
          }
          break;
        default:
          cumpleFiltro = true;
          break;
      }

      return cumpleFiltro;
    }).toList();

    if (debugMode) {
      debugPrint(
          '✅ Filtro aplicado. Resultado: ${productosFiltrados.length} productos cumplen el filtro $tipoDescuento');
    }

    return productosFiltrados;
  }

  /// Filtra productos usando el método más apropiado según el formato
  static List<Map<String, dynamic>> filtrarProductos({
    required List<Map<String, dynamic>> productos,
    required String filtroTexto,
    required String filtroCategoria,
    required TipoDescuento tipoDescuento,
    bool debugMode = false,
  }) {
    // NUEVO: Utilizar ProductosUtils cuando sea posible
    if (esFormatoCompatible(productos)) {
      try {
        // Convertir los datos al formato esperado por ProductosUtils
        final List<Producto> productosFormateados =
            convertirAProductos(productos);

        // Usar la función centralizada de filtrado
        final List<Producto> productosFiltrados =
            ProductosUtils.filtrarProductos(
          productos: productosFormateados,
          searchQuery: filtroTexto,
          selectedCategory: filtroCategoria,
          debugMode: debugMode,
        );

        if (debugMode) {
          debugPrint(
              '✅ Filtrado usando ProductosUtils: ${productosFiltrados.length} resultados');
        }

        // Convertir de nuevo al formato de mapa esperado por la UI
        final List<Map<String, dynamic>> resultadosFiltrados =
            convertirAMapas(productosFiltrados);

        // Aplicar filtrado adicional por tipo de descuento
        return filtrarPorTipoDescuento(resultadosFiltrados, tipoDescuento,
            debugMode: debugMode);
      } catch (e) {
        // Si hay algún error, caer al método de filtrado original
        if (debugMode) {
          debugPrint(
              '⚠️ Error al usar ProductosUtils, usando filtrado alternativo: $e');
        }
      }
    }

    // Si no podemos usar ProductosUtils, usamos el filtrado mejorado:
    final List<Map<String, dynamic>> resultadosFiltrados =
        productos.where((Map<String, dynamic> producto) {
      // Filtrar por texto (nombre o código)
      final bool coincideTexto = filtroTexto.isEmpty ||
          producto['nombre'].toString().toLowerCase().contains(filtroTexto) ||
          producto['codigo'].toString().toLowerCase().contains(filtroTexto);

      // Filtrar por categoría (verificación exhaustiva)
      bool coincideCategoria = esCategoriaTodos(filtroCategoria);

      if (!coincideCategoria && producto['categoria'] != null) {
        final String categoriaProducto =
            producto['categoria'].toString().trim();
        final String categoriaProductoNormalizada =
            categoriaProducto.toLowerCase();
        final String filtroCategoriaNormalizadoLC =
            filtroCategoria.toLowerCase();

        // Intentar varias formas de comparación
        coincideCategoria =
            categoriaProductoNormalizada == filtroCategoriaNormalizadoLC ||
                normalizarCategoria(categoriaProducto).toLowerCase() ==
                    filtroCategoriaNormalizadoLC;

        // Depuración mejorada
        if (debugMode) {
          if (!coincideCategoria) {
            debugPrint(
                '❌ No coincide: "$categoriaProducto" ($categoriaProductoNormalizada) vs "$filtroCategoria" ($filtroCategoriaNormalizadoLC)');
          } else {
            debugPrint(
                '✅ Coincidencia: "$categoriaProducto" con "$filtroCategoria"');
          }
        }
      }

      return coincideTexto && coincideCategoria;
    }).toList();

    // Aplicar filtrado por tipo de descuento
    final List<Map<String, dynamic>> resultadosConDescuentoFiltrado =
        filtrarPorTipoDescuento(resultadosFiltrados, tipoDescuento);

    // Ordenar: primero los que tienen promociones, luego por nombre
    return resultadosConDescuentoFiltrado
      ..sort((Map<String, dynamic> a, Map<String, dynamic> b) {
        // Primero ordenar por si tiene alguna promoción
        final bool aPromo = (a['enLiquidacion'] == true) ||
            (a['tienePromocionGratis'] == true) ||
            (a['tieneDescuentoPorcentual'] == true);

        final bool bPromo = (b['enLiquidacion'] == true) ||
            (b['tienePromocionGratis'] == true) ||
            (b['tieneDescuentoPorcentual'] == true);

        if (aPromo && !bPromo) {
          return -1;
        }
        if (!aPromo && bPromo) {
          return 1;
        }

        // Si ambos tienen o no tienen promoción, ordenar por nombre
        return a['nombre'].toString().compareTo(b['nombre'].toString());
      });
  }

  /// Extrae categorías únicas de una lista de productos
  static List<String> extraerCategorias(List<Map<String, dynamic>> productos) {
    final List<String> categorias = productos
        .map(
            (Map<String, dynamic> p) => p['categoria']?.toString().trim() ?? '')
        .where((String cat) => cat.isNotEmpty)
        .toSet()
        .toList()
      ..sort(); // Ordenar alfabéticamente

    return <String>['Todos', ...categorias];
  }

  /// Combina categorías de diferentes fuentes en una sola lista
  static List<String> combinarCategorias({
    required List<Map<String, dynamic>> productos,
    required List<String> categoriasFallback,
    required List<Categoria> categoriasApi,
  }) {
    // 1. Intentar extraer categorías de productos
    final List<String> categoriasProductos = extraerCategorias(productos);
    if (categoriasProductos.length > 1) {
      // Si hay más que solo "Todos"
      return categoriasProductos;
    }

    // 2. Usar categorías de fallback si están disponibles
    if (categoriasFallback.isNotEmpty) {
      return <String>[
        'Todos',
        ...categoriasFallback
            .where((String cat) => cat != 'Todos' && cat != 'Todas')
      ];
    }

    // 3. Usar categorías de API si están disponibles
    if (categoriasApi.isNotEmpty) {
      categoriasApi
          .sort((Categoria a, Categoria b) => a.nombre.compareTo(b.nombre));
      return <String>['Todos', ...categoriasApi.map((Categoria c) => c.nombre)];
    }

    // 4. Si todo lo demás falla, retornar lista básica
    return <String>['Todos', 'Repuestos', 'Accesorios', 'Lubricantes'];
  }
}
