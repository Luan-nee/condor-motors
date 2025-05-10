import 'package:condorsmotors/models/categoria.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:flutter/material.dart';

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
    return productos.map((p) => mapToProductoFlexible(p)).toList();
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
              'enLiquidacion': p.estaEnLiquidacion,
              'liquidacion': p.estaEnLiquidacion,
              // Agregar información de promociones usando getters del modelo
              'cantidadMinima': p.cantidadMinimaDescuento,
              'cantidadGratis': p.cantidadGratisDescuento,
              'descuentoPorcentaje': p.porcentajeDescuento,
              'tienePromocionGratis': p.tienePromocionGratis,
              'tieneDescuentoPorcentual': p.tieneDescuentoPorcentual,
              'tienePromocion': p.estaEnLiquidacion ||
                  p.tienePromocionGratis ||
                  p.tieneDescuentoPorcentual,
              // Agregar la URL de la foto usando el getter y el campo real
              'pathFoto': p.pathFoto,
            })
        .toList();
  }

  /// Filtra productos por tipo de descuento
  static List<Producto> filtrarPorTipoDescuento(
      List<Producto> productos, TipoDescuento tipoDescuento,
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

      for (final Producto producto in productos) {
        if (producto.estaEnLiquidacion) {
          conLiquidacion++;
        }
        if (producto.tienePromocionGratis) {
          conPromoGratis++;
        }
        if (producto.tieneDescuentoPorcentual) {
          conDescuentoPorcentual++;
        }
      }

      debugPrint('📊 Productos con cada tipo de descuento:');
      debugPrint('- Liquidación: $conLiquidacion');
      debugPrint('- Promo "Lleva y Paga": $conPromoGratis');
      debugPrint('- Descuento porcentual: $conDescuentoPorcentual');
    }

    // Filtrar los productos según el tipo de descuento
    final List<Producto> productosFiltrados =
        productos.where((Producto producto) {
      bool cumpleFiltro = false;

      switch (tipoDescuento) {
        case TipoDescuento.liquidacion:
          cumpleFiltro = producto.estaEnLiquidacion;
          break;
        case TipoDescuento.promoGratis:
          cumpleFiltro = producto.tienePromocionGratis;

          if (debugMode && !cumpleFiltro) {
            // Revisar por qué no cumple para posible diagnóstico
            if (producto.cantidadMinimaDescuento != null &&
                producto.cantidadGratisDescuento != null) {
              debugPrint(
                  '⚠️ Producto ${producto.nombre} tiene cantidadMinima=${producto.cantidadMinimaDescuento} y cantidadGratis=${producto.cantidadGratisDescuento} pero tienePromocionGratis=${producto.tienePromocionGratis}');
            }
          }
          break;
        case TipoDescuento.descuentoPorcentual:
          cumpleFiltro = producto.tieneDescuentoPorcentual;

          if (debugMode && !cumpleFiltro) {
            // Revisar por qué no cumple para posible diagnóstico
            if (producto.cantidadMinimaDescuento != null &&
                producto.porcentajeDescuento != null) {
              debugPrint(
                  '⚠️ Producto ${producto.nombre} tiene cantidadMinima=${producto.cantidadMinimaDescuento} y descuentoPorcentaje=${producto.porcentajeDescuento} pero tieneDescuentoPorcentual=${producto.tieneDescuentoPorcentual}');
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

  /// Filtra productos usando el modelo Producto de forma centralizada
  static List<Producto> filtrarProductos({
    required List<Map<String, dynamic>> productos,
    required String filtroTexto,
    required String filtroCategoria,
    required TipoDescuento tipoDescuento,
    bool debugMode = false,
  }) {
    // 1. Convertir la lista de Map a lista de Producto al inicio
    final List<Producto> listaProductos = convertirAProductos(productos);

    if (debugMode) {
      debugPrint(
          '⚙️ Filtrando ${listaProductos.length} productos (después de convertir de Map)');
    }

    // 2. Aplicar filtrado por texto y categoría sobre List<Producto>
    final List<Producto> filtradoTextoCategoria =
        listaProductos.where((Producto producto) {
      // Filtrar por texto (nombre o sku)
      final bool coincideTexto = filtroTexto.isEmpty ||
          producto.nombre.toLowerCase().contains(filtroTexto.toLowerCase()) ||
          producto.sku.toLowerCase().contains(filtroTexto.toLowerCase());

      // Filtrar por categoría (verificación exhaustiva)
      bool coincideCategoria = esCategoriaTodos(filtroCategoria);

      if (!coincideCategoria && producto.categoria.isNotEmpty) {
        final String categoriaProducto = producto.categoria.trim();
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

    if (debugMode) {
      debugPrint(
          '🔍 Filtrado por texto/categoría: ${filtradoTextoCategoria.length} resultados');
    }

    // 3. Aplicar filtrado por tipo de descuento sobre la lista de Producto ya filtrada
    final List<Producto> resultadosFinales = filtrarPorTipoDescuento(
        filtradoTextoCategoria, tipoDescuento,
        debugMode: debugMode);

    // 4. Ordenar: primero los que tienen promociones, luego por nombre
    resultadosFinales.sort((Producto a, Producto b) {
      // Primero ordenar por si tiene alguna promoción (usar el getter del modelo)
      final bool aPromo = a.tienePromocion;
      final bool bPromo = b.tienePromocion;

      if (aPromo && !bPromo) {
        return -1;
      }
      if (!aPromo && bPromo) {
        return 1;
      }

      // Si ambos tienen o no tienen promoción, ordenar por nombre
      return a.nombre.compareTo(b.nombre);
    });

    if (debugMode) {
      debugPrint(
          '✅ Filtrado completo y ordenado. Resultado: ${resultadosFinales.length} productos');
    }

    return resultadosFinales;
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

  static Color getPromocionColor(
      bool tienePromocionGratis, bool tieneDescuentoPorcentual) {
    if (tienePromocionGratis) {
      return Colors.green;
    } else if (tieneDescuentoPorcentual) {
      return Colors.purple;
    }
    return Colors.blue;
  }

  /// Conversión flexible de Map a Producto, manejando alias de campos
  ///
  /// RECOMENDACIÓN: Siempre que sea posible, usa 'precioVenta' en los Maps en vez de 'precio'.
  /// Esto evita confusiones y asegura compatibilidad con el modelo Producto.
  static Producto mapToProductoFlexible(Map<String, dynamic> map) {
    final Map<String, dynamic> normalized = Map<String, dynamic>.from(map);
    // Alias para sku
    if (normalized['sku'] == null && normalized['codigo'] != null) {
      normalized['sku'] = normalized['codigo'];
    }
    // Alias para precioOferta
    if (normalized['precioOferta'] == null &&
        normalized['precioLiquidacion'] != null) {
      normalized['precioOferta'] = normalized['precioLiquidacion'];
    }
    // Alias para liquidacion
    if (normalized['liquidacion'] == null &&
        normalized['enLiquidacion'] != null) {
      normalized['liquidacion'] = normalized['enLiquidacion'];
    }
    // Alias para cantidadMinimaDescuento
    if (normalized['cantidadMinimaDescuento'] == null &&
        normalized['cantidadMinima'] != null) {
      normalized['cantidadMinimaDescuento'] = normalized['cantidadMinima'];
    }
    // Alias para cantidadGratisDescuento
    if (normalized['cantidadGratisDescuento'] == null &&
        normalized['cantidadGratis'] != null) {
      normalized['cantidadGratisDescuento'] = normalized['cantidadGratis'];
    }
    // Alias para porcentajeDescuento
    if (normalized['porcentajeDescuento'] == null &&
        normalized['descuentoPorcentaje'] != null) {
      normalized['porcentajeDescuento'] = normalized['descuentoPorcentaje'];
    }
    // Alias para precioVenta (FIX: bug de precio 0 en carrito)
    if (normalized['precioVenta'] == null && normalized['precio'] != null) {
      normalized['precioVenta'] = normalized['precio'];
    }
    // Alias para pathFoto si solo viene fotoUrl
    if (normalized['pathFoto'] == null && normalized['fotoUrl'] != null) {
      normalized['pathFoto'] = normalized['fotoUrl'];
    }
    return Producto.fromJson(normalized);
  }
}
