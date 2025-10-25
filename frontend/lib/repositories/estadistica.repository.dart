import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/models/estadisticas.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/foundation.dart';

/// Repositorio para gestionar estadísticas
///
/// Esta clase encapsula la lógica de negocio relacionada con estadísticas,
/// actuando como una capa intermedia entre la UI y la API
class EstadisticaRepository implements BaseRepository {
  /// Instancia singleton del repositorio
  static final EstadisticaRepository _instance =
      EstadisticaRepository._internal();

  /// Getter para la instancia singleton
  static EstadisticaRepository get instance => _instance;

  /// API de estadísticas
  late final dynamic _estadisticasApi;

  /// Constructor privado para el patrón singleton
  EstadisticaRepository._internal() {
    try {
      // Utilizamos la API global inicializada en index.api.dart
      _estadisticasApi = api_index.api.estadisticas;
    } catch (e) {
      debugPrint('Error al obtener EstadisticasApi: $e');
      // Si hay un error al acceder a la API global, lanzamos una excepción
      throw Exception('No se pudo inicializar EstadisticaRepository: $e');
    }
  }

  /// Obtiene datos del usuario desde la API centralizada
  ///
  /// Ayuda a los providers a acceder a la información del usuario autenticado
  @override
  Future<Map<String, dynamic>?> getUserData() =>
      api_index.AuthManager.getUserData();

  /// Obtiene el ID de la sucursal del usuario actual
  ///
  /// Útil para operaciones que requieren el ID de sucursal automáticamente
  @override
  Future<String?> getCurrentSucursalId() =>
      api_index.AuthManager.getCurrentSucursalId();

  /// Obtiene un resumen general de estadísticas
  ///
  /// [useCache] Indica si se debe usar la caché
  /// [forceRefresh] Indica si se debe forzar la recarga desde el servidor
  Future<Map<String, dynamic>> getResumenEstadisticas({
    bool useCache = false,
    bool forceRefresh = true,
  }) async {
    try {
      return await _estadisticasApi.getResumenEstadisticas(
        useCache: useCache,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      debugPrint('Error en EstadisticaRepository.getResumenEstadisticas: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Obtiene un resumen general de estadísticas como objeto tipado
  ///
  /// [useCache] Indica si se debe usar la caché
  /// [forceRefresh] Indica si se debe forzar la recarga desde el servidor
  Future<ResumenEstadisticas> getResumenEstadisticasTyped({
    bool useCache = false,
    bool forceRefresh = true,
  }) async {
    try {
      final response = await getResumenEstadisticas(
        useCache: useCache,
        forceRefresh: forceRefresh,
      );

      if (response['status'] == 'success' && response['data'] != null) {
        return ResumenEstadisticas.fromJson(response['data']);
      }

      // Respuesta por defecto si no hay datos
      return const ResumenEstadisticas(
        productos: EstadisticasProductos(
          stockBajo: 0,
          liquidacion: 0,
          sucursales: [],
        ),
        ventas: EstadisticasVentas(
          ventas: {'hoy': 0, 'esteMes': 0},
          totalVentas: {'hoy': 0, 'esteMes': 0},
          sucursales: [],
        ),
      );
    } catch (e) {
      debugPrint(
          'Error en EstadisticaRepository.getResumenEstadisticasTyped: $e');
      // Respuesta por defecto en caso de error
      return const ResumenEstadisticas(
        productos: EstadisticasProductos(
          stockBajo: 0,
          liquidacion: 0,
          sucursales: [],
        ),
        ventas: EstadisticasVentas(
          ventas: {'hoy': 0, 'esteMes': 0},
          totalVentas: {'hoy': 0, 'esteMes': 0},
          sucursales: [],
        ),
      );
    }
  }

  /// Obtiene estadísticas por sucursal
  ///
  /// [sucursalId] ID de la sucursal para la que se quieren obtener estadísticas
  /// [useCache] Indica si se debe usar la caché
  Future<Map<String, dynamic>> getEstadisticasPorSucursal(
    String sucursalId, {
    bool useCache = false,
  }) async {
    try {
      return await _estadisticasApi.getEstadisticasPorSucursal(
        sucursalId,
        useCache: useCache,
      );
    } catch (e) {
      debugPrint(
          'Error en EstadisticaRepository.getEstadisticasPorSucursal: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Obtiene estadísticas de ventas para un período específico
  ///
  /// [fechaInicio] Fecha de inicio del período
  /// [fechaFin] Fecha de fin del período
  /// [sucursalId] ID de la sucursal (opcional)
  Future<Map<String, dynamic>> getEstadisticasVentas({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? sucursalId,
  }) async {
    try {
      return await _estadisticasApi.getEstadisticasVentas(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        sucursalId: sucursalId,
      );
    } catch (e) {
      debugPrint('Error en EstadisticaRepository.getEstadisticasVentas: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Obtiene estadísticas de productos
  ///
  /// [sucursalId] ID de la sucursal (opcional)
  /// [categoria] Categoría de productos (opcional)
  Future<Map<String, dynamic>> getEstadisticasProductos({
    String? sucursalId,
    String? categoria,
  }) async {
    try {
      return await _estadisticasApi.getEstadisticasProductos(
        sucursalId: sucursalId,
        categoria: categoria,
      );
    } catch (e) {
      debugPrint('Error en EstadisticaRepository.getEstadisticasProductos: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Obtiene estadísticas de productos como objeto tipado
  ///
  /// [sucursalId] ID de la sucursal (opcional)
  /// [categoria] Categoría de productos (opcional)
  /// [useCache] Indica si se debe usar la caché
  /// [forceRefresh] Indica si se debe forzar la recarga desde el servidor
  Future<EstadisticasProductos> getEstadisticasProductosTyped({
    String? sucursalId,
    String? categoria,
    bool useCache = false,
    bool forceRefresh = true,
  }) async {
    try {
      final response = await _estadisticasApi.getEstadisticasProductos(
        sucursalId: sucursalId,
        categoria: categoria,
        useCache: useCache,
        forceRefresh: forceRefresh,
      );

      if (response['status'] == 'success' && response['data'] != null) {
        return EstadisticasProductos.fromJson(response['data']);
      }

      // Respuesta por defecto si no hay datos
      return const EstadisticasProductos(
        stockBajo: 0,
        liquidacion: 0,
        sucursales: [],
      );
    } catch (e) {
      debugPrint(
          'Error en EstadisticaRepository.getEstadisticasProductosTyped: $e');
      // Respuesta por defecto en caso de error
      return const EstadisticasProductos(
        stockBajo: 0,
        liquidacion: 0,
        sucursales: [],
      );
    }
  }

  /// Obtiene estadísticas de ventas como objeto tipado
  ///
  /// [useCache] Indica si se debe usar la caché
  /// [forceRefresh] Indica si se debe forzar la recarga desde el servidor
  Future<EstadisticasVentas> getEstadisticasVentasTyped({
    bool useCache = false,
    bool forceRefresh = true,
  }) async {
    try {
      final response = await _estadisticasApi.getEstadisticasVentas(
        useCache: useCache,
        forceRefresh: forceRefresh,
      );

      if (response['status'] == 'success' && response['data'] != null) {
        return EstadisticasVentas.fromJson(response['data']);
      }

      // Respuesta por defecto si no hay datos
      return const EstadisticasVentas(
        ventas: {'hoy': 0, 'esteMes': 0},
        totalVentas: {'hoy': 0, 'esteMes': 0},
        sucursales: [],
      );
    } catch (e) {
      debugPrint(
          'Error en EstadisticaRepository.getEstadisticasVentasTyped: $e');
      // Respuesta por defecto en caso de error
      return const EstadisticasVentas(
        ventas: {'hoy': 0, 'esteMes': 0},
        totalVentas: {'hoy': 0, 'esteMes': 0},
        sucursales: [],
      );
    }
  }

  /// Obtiene datos para gráficos de ventas
  ///
  /// [tipo] Tipo de gráfico (diario, semanal, mensual, anual)
  /// [sucursalId] ID de la sucursal (opcional)
  /// [fechaInicio] Fecha de inicio (opcional)
  /// [fechaFin] Fecha de fin (opcional)
  Future<Map<String, dynamic>> getGraficosVentas({
    required String tipo,
    String? sucursalId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      return await _estadisticasApi.getGraficosVentas(
        tipo: tipo,
        sucursalId: sucursalId,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
    } catch (e) {
      debugPrint('Error en EstadisticaRepository.getGraficosVentas: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Obtiene las últimas ventas registradas en el sistema
  ///
  /// [useCache] Indica si se debe usar la caché
  /// [forceRefresh] Indica si se debe forzar la recarga desde el servidor
  Future<List<UltimaVenta>> getUltimasVentas({
    bool useCache = false,
    bool forceRefresh = true,
  }) async {
    try {
      debugPrint("Llamando a getUltimasVentas en la API");
      final response = await _estadisticasApi.getUltimasVentas(
        useCache: useCache,
        forceRefresh: forceRefresh,
      );

      debugPrint(
          "Respuesta recibida de getUltimasVentas: ${response['status']}");

      if (response['status'] == 'success' && response['data'] != null) {
        if (response['data'] is List) {
          debugPrint(
              "Procesando ${(response['data'] as List).length} últimas ventas");
          try {
            return (response['data'] as List)
                .map((ventaJson) => UltimaVenta.fromJson(ventaJson))
                .toList();
          } catch (e) {
            debugPrint("Error al parsear ventas: $e");
            // Intentar procesar elemento por elemento para identificar errores
            List<UltimaVenta> resultado = [];
            for (var ventaJson in (response['data'] as List)) {
              try {
                resultado.add(UltimaVenta.fromJson(ventaJson));
              } catch (e) {
                debugPrint("Error parseando venta individual: $e");
                debugPrint("JSON problemático: $ventaJson");
              }
            }
            return resultado;
          }
        } else {
          debugPrint(
              "El formato de data no es una lista: ${response['data'].runtimeType}");
        }
      } else {
        debugPrint(
            "Respuesta fallida o sin datos: ${response['message'] ?? 'No hay mensaje'}");
      }

      // Si no hay datos o hay un error, devolver lista vacía
      return [];
    } catch (e) {
      debugPrint('Error en EstadisticaRepository.getUltimasVentas: $e');
      // En caso de error, devolvemos una lista vacía
      return [];
    }
  }

  /// Obtiene productos con stock bajo para todas las sucursales
  ///
  /// [useCache] Indica si se debe usar la caché
  /// [forceRefresh] Indica si se debe forzar la recarga desde el servidor
  Future<Map<String, dynamic>> getProductosStockBajo({
    bool useCache = false,
    bool forceRefresh = true,
  }) async {
    try {
      debugPrint("Obteniendo productos con stock bajo");
      final response = await _estadisticasApi.getEstadisticasProductos(
        useCache: useCache,
        forceRefresh: forceRefresh,
      );

      if (response['status'] == 'success' && response['data'] != null) {
        debugPrint("Productos con stock bajo obtenidos correctamente");
        return response;
      } else {
        debugPrint(
            "Error al obtener productos con stock bajo: ${response['message'] ?? 'Sin mensaje'}");
        return {
          'status': 'error',
          'message': response['message'] ??
              'Error al obtener productos con stock bajo',
          'data': {
            'stockBajo': 0,
            'liquidacion': 0,
            'sucursales': [],
          }
        };
      }
    } catch (e) {
      debugPrint('Error en EstadisticaRepository.getProductosStockBajo: $e');
      return {
        'status': 'error',
        'message': e.toString(),
        'data': {
          'stockBajo': 0,
          'liquidacion': 0,
          'sucursales': [],
        }
      };
    }
  }

  /// Obtiene detalles de productos con stock bajo
  ///
  /// Este método obtiene información específica sobre los productos con stock bajo
  /// de todas las sucursales
  /// [useCache] Indica si se debe usar la caché
  /// [forceRefresh] Indica si se debe forzar la recarga desde el servidor
  Future<List<Map<String, dynamic>>> getDetallesProductosStockBajo({
    bool useCache = false,
    bool forceRefresh = true,
  }) async {
    try {
      debugPrint("Obteniendo detalles de productos con stock bajo...");

      // Primero obtenemos los datos resumidos de estadísticas
      final estadisticasProductos = await getEstadisticasProductosTyped(
          useCache: useCache, forceRefresh: forceRefresh);

      // Lista para almacenar los detalles de productos
      List<Map<String, dynamic>> productosDetalle = [];

      // Para cada sucursal en las estadísticas
      for (final sucursal in estadisticasProductos.sucursales) {
        final int idSucursal = sucursal.id;
        final String nombreSucursal = sucursal.nombre;
        final int stockBajo = sucursal.stockBajo;

        // Si hay productos con stock bajo en esta sucursal
        if (stockBajo > 0) {
          debugPrint(
              "Sucursal $nombreSucursal tiene $stockBajo productos con stock bajo");

          // Intentamos obtener los productos específicos de stock bajo para esta sucursal
          try {
            // Esta llamada dependerá de cómo está estructurada tu API
            final response =
                await _estadisticasApi.getProductosStockBajoSucursal(
              sucursalId: idSucursal.toString(),
              useCache: useCache,
              forceRefresh: forceRefresh,
            );

            if (response['status'] == 'success' && response['data'] != null) {
              // Si la respuesta contiene una lista de productos
              if (response['data'] is List) {
                for (final producto in response['data']) {
                  productosDetalle.add({
                    'productoId': producto['id'].toString(),
                    'productoNombre': producto['nombre'] ?? 'Sin nombre',
                    'stock': producto['stock'] ?? 0,
                    'stockMinimo': producto['stockMinimo'] ?? 10,
                    'sucursalId': idSucursal.toString(),
                    'sucursalNombre': nombreSucursal,
                    'categoria': producto['categoria'] is Map
                        ? producto['categoria']['nombre']
                        : producto['categoria'] ?? 'Sin categoría',
                    'marca': producto['marca'] is Map
                        ? producto['marca']['nombre']
                        : producto['marca'] ?? 'Sin marca',
                  });
                }
              } else {
                debugPrint("La respuesta no contiene una lista de productos");
              }
            } else {
              debugPrint(
                  "No se obtuvieron detalles de productos para sucursal $nombreSucursal");
            }
          } catch (e) {
            debugPrint(
                "Error obteniendo detalles para sucursal $idSucursal: $e");

            // En caso de error, agregamos un placeholder para la sucursal
            productosDetalle.add({
              'productoId': 'no-id',
              'productoNombre': 'Producto con stock bajo',
              'stock': 0,
              'stockMinimo': 10,
              'sucursalId': idSucursal.toString(),
              'sucursalNombre': nombreSucursal,
              'categoria': 'No disponible',
              'marca': 'No disponible',
            });
          }
        }
      }

      // Si no se obtuvieron productos específicos pero sí hay productos con stock bajo
      if (productosDetalle.isEmpty && estadisticasProductos.stockBajo > 0) {
        debugPrint(
            "No se obtuvieron detalles específicos, agregando datos generales");

        // Agregamos datos generales basados en las estadísticas
        for (final sucursal in estadisticasProductos.sucursales) {
          if (sucursal.stockBajo > 0) {
            productosDetalle.add({
              'productoId': 'global',
              'productoNombre':
                  '${sucursal.stockBajo} producto(s) con stock bajo',
              'stock': 0,
              'stockMinimo': 10,
              'sucursalId': sucursal.id.toString(),
              'sucursalNombre': sucursal.nombre,
              'categoria': 'Varias categorías',
              'marca': 'Varias marcas',
            });
          }
        }
      }

      debugPrint("Total de detalles obtenidos: ${productosDetalle.length}");
      return productosDetalle;
    } catch (e) {
      debugPrint(
          'Error en EstadisticaRepository.getDetallesProductosStockBajo: $e');
      return [];
    }
  }
}
