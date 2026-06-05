import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/models/estadisticas.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';

/// Repositorio para gestionar estadísticas e informes del sistema.
///
/// Encapsula la lógica de negocio y consumo de APIs estadísticas,
/// delegando la autenticación mediante el mixin [AuthDelegator].
class EstadisticaRepository with AuthDelegator implements BaseRepository {
  static final EstadisticaRepository _instance = EstadisticaRepository._internal();
  static EstadisticaRepository get instance => _instance;

  late final dynamic _estadisticasApi;

  EstadisticaRepository._internal() {
    _estadisticasApi = api_index.api.estadisticas;
  }

  /// Obtiene un resumen general de estadísticas crudas.
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
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Obtiene un resumen general de estadísticas como objeto fuertemente tipado.
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
    } catch (_) {}

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

  /// Obtiene estadísticas para una sucursal específica.
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
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Obtiene estadísticas de ventas para un período específico.
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
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Obtiene estadísticas de productos con sucursal o categoría opcionales.
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
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Obtiene estadísticas de productos como objeto tipado.
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
    } catch (_) {}

    return const EstadisticasProductos(
      stockBajo: 0,
      liquidacion: 0,
      sucursales: [],
    );
  }

  /// Obtiene estadísticas de ventas como objeto tipado.
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
    } catch (_) {}

    return const EstadisticasVentas(
      ventas: {'hoy': 0, 'esteMes': 0},
      totalVentas: {'hoy': 0, 'esteMes': 0},
      sucursales: [],
    );
  }

  /// Obtiene datos para gráficos de ventas consolidables.
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
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Obtiene las últimas ventas registradas en el sistema.
  Future<List<UltimaVenta>> getUltimasVentas({
    bool useCache = false,
    bool forceRefresh = true,
  }) async {
    try {
      final response = await _estadisticasApi.getUltimasVentas(
        useCache: useCache,
        forceRefresh: forceRefresh,
      );

      if (response['status'] == 'success' && response['data'] is List) {
        final List<UltimaVenta> resultado = [];
        for (final ventaJson in (response['data'] as List)) {
          try {
            resultado.add(UltimaVenta.fromJson(ventaJson));
          } catch (_) {}
        }
        return resultado;
      }
    } catch (_) {}
    return [];
  }

  /// Obtiene estadísticas de productos con stock bajo en formato crudo.
  Future<Map<String, dynamic>> getProductosStockBajo({
    bool useCache = false,
    bool forceRefresh = true,
  }) async {
    try {
      final response = await _estadisticasApi.getEstadisticasProductos(
        useCache: useCache,
        forceRefresh: forceRefresh,
      );

      if (response['status'] == 'success' && response['data'] != null) {
        return response;
      }

      return {
        'status': 'error',
        'message': response['message'] ?? 'Error al obtener productos con stock bajo',
        'data': const {
          'stockBajo': 0,
          'liquidacion': 0,
          'sucursales': [],
        }
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
        'data': const {
          'stockBajo': 0,
          'liquidacion': 0,
          'sucursales': [],
        }
      };
    }
  }

  /// Obtiene el listado de detalles específicos sobre repuestos con stock bajo.
  Future<List<Map<String, dynamic>>> getDetallesProductosStockBajo({
    bool useCache = false,
    bool forceRefresh = true,
  }) async {
    try {
      final estadisticasProductos = await getEstadisticasProductosTyped(
        useCache: useCache,
        forceRefresh: forceRefresh,
      );

      final List<Map<String, dynamic>> productosDetalle = [];

      for (final sucursal in estadisticasProductos.sucursales) {
        final int idSucursal = sucursal.id;
        final String nombreSucursal = sucursal.nombre;

        if (sucursal.stockBajo > 0) {
          try {
            final response = await _estadisticasApi.getProductosStockBajoSucursal(
              sucursalId: idSucursal.toString(),
              useCache: useCache,
              forceRefresh: forceRefresh,
            );

            if (response['status'] == 'success' && response['data'] is List) {
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
          } catch (_) {
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

      if (productosDetalle.isEmpty && estadisticasProductos.stockBajo > 0) {
        for (final sucursal in estadisticasProductos.sucursales) {
          if (sucursal.stockBajo > 0) {
            productosDetalle.add({
              'productoId': 'global',
              'productoNombre': '${sucursal.stockBajo} producto(s) con stock bajo',
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

      return productosDetalle;
    } catch (_) {
      return [];
    }
  }
}
