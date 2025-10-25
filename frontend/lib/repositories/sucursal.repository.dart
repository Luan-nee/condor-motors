import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/api/protected/sucursales.api.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/foundation.dart';

/// Repositorio para gestionar sucursales
///
/// Esta clase encapsula la lógica de negocio relacionada con sucursales,
/// actuando como una capa intermedia entre la UI y la API
class SucursalRepository implements BaseRepository {
  /// Instancia singleton del repositorio
  static final SucursalRepository _instance = SucursalRepository._internal();

  /// Getter para la instancia singleton
  static SucursalRepository get instance => _instance;

  /// API de sucursales
  late final SucursalesApi _sucursalesApi;

  /// Constructor privado para el patrón singleton
  SucursalRepository._internal() {
    try {
      // Utilizamos la API global inicializada en index.api.dart
      _sucursalesApi = api_index.api.sucursales;
    } catch (e) {
      debugPrint('Error al obtener SucursalesApi: $e');
      // Si hay un error al acceder a la API global, lanzamos una excepción
      throw Exception('No se pudo inicializar SucursalRepository: $e');
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

  /// Obtiene la lista de todas las sucursales
  ///
  /// [useCache] Indica si se debe usar la caché
  Future<List<Sucursal>> getSucursales({bool useCache = true}) async {
    try {
      return await _sucursalesApi.getSucursales(useCache: useCache);
    } catch (e) {
      debugPrint('Error en SucursalRepository.getSucursales: $e');
      rethrow;
    }
  }

  /// Obtiene los datos completos de una sucursal específica
  ///
  /// [sucursalId] ID de la sucursal
  /// [useCache] Indica si se debe usar la caché
  /// [forceRefresh] Indica si se debe forzar la recarga desde el servidor
  Future<Sucursal> getSucursalData(
    String sucursalId, {
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      return await _sucursalesApi.getSucursalData(
        sucursalId,
        useCache: useCache,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      debugPrint('Error en SucursalRepository.getSucursalData: $e');
      rethrow;
    }
  }

  /// Obtiene la sucursal actual del usuario
  ///
  /// Primero obtiene el ID de la sucursal del usuario desde el token,
  /// luego carga los datos completos de esa sucursal
  Future<Sucursal?> getCurrentUserSucursal() async {
    try {
      final sucursalId = await getCurrentSucursalId();
      if (sucursalId == null) {
        return null;
      }

      return await getSucursalData(sucursalId);
    } catch (e) {
      debugPrint('Error en SucursalRepository.getCurrentUserSucursal: $e');
      return null;
    }
  }

  /// Crea una sucursal provisional con datos mínimos
  ///
  /// Útil cuando no se pueden obtener los datos completos del servidor
  Sucursal createProvisionalSucursal(String sucursalId) {
    final DateTime ahora = DateTime.now();
    return Sucursal(
      id: sucursalId,
      nombre: 'Sucursal $sucursalId',
      direccion: '',
      sucursalCentral: false,
      serieFactura: '',
      serieBoleta: '',
      fechaCreacion: ahora,
      fechaActualizacion: ahora,
    );
  }

  /// Invalida la caché de sucursales
  void invalidateCache() {
    try {
      _sucursalesApi.invalidateCache();
    } catch (e) {
      debugPrint('Error en SucursalRepository.invalidateCache: $e');
    }
  }

  /// Crea una nueva sucursal
  ///
  /// [sucursalData] Datos de la sucursal a crear
  Future<Sucursal> createSucursal(Map<String, dynamic> sucursalData) async {
    try {
      // Validar datos usando el modelo antes de llamar a la API
      final String? validationError =
          Sucursal.validateSucursalData(sucursalData);
      if (validationError != null) {
        throw Exception(validationError);
      }

      return await _sucursalesApi.createSucursal(sucursalData);
    } catch (e) {
      debugPrint('Error en SucursalRepository.createSucursal: $e');
      rethrow;
    }
  }

  /// Actualiza una sucursal existente
  ///
  /// [sucursalId] ID de la sucursal a actualizar
  /// [sucursalData] Datos actualizados de la sucursal
  Future<Sucursal> updateSucursal(
      String sucursalId, Map<String, dynamic> sucursalData) async {
    try {
      // Validar datos usando el modelo antes de llamar a la API
      final String? validationError =
          Sucursal.validateSucursalData(sucursalData);
      if (validationError != null) {
        throw Exception(validationError);
      }

      return await _sucursalesApi.updateSucursal(sucursalId, sucursalData);
    } catch (e) {
      debugPrint('Error en SucursalRepository.updateSucursal: $e');
      rethrow;
    }
  }

  /// Elimina una sucursal
  ///
  /// [sucursalId] ID de la sucursal a eliminar
  Future<void> deleteSucursal(String sucursalId) async {
    try {
      await _sucursalesApi.deleteSucursal(sucursalId);
    } catch (e) {
      debugPrint('Error en SucursalRepository.deleteSucursal: $e');
      rethrow;
    }
  }

  /// Obtiene los productos de una sucursal específica
  ///
  /// [sucursalId] ID de la sucursal
  /// [useCache] Indica si se debe usar la caché
  /// [forceRefresh] Indica si se debe forzar la recarga desde el servidor
  Future<List<dynamic>> getProductosSucursal(
    String sucursalId, {
    bool useCache = true,
    bool forceRefresh = false,
  }) async {
    try {
      return await _sucursalesApi.getProductosSucursal(
        sucursalId,
        useCache: useCache,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      debugPrint('Error en SucursalRepository.getProductosSucursal: $e');
      rethrow;
    }
  }

  /// Registra entrada de inventario en una sucursal
  ///
  /// [sucursalId] ID de la sucursal
  /// [entradaData] Datos de la entrada de inventario
  Future<Map<String, dynamic>> registrarEntradaInventario(
    String sucursalId,
    Map<String, dynamic> entradaData,
  ) async {
    try {
      return await _sucursalesApi.registrarEntradaInventario(
        sucursalId,
        entradaData,
      );
    } catch (e) {
      debugPrint('Error en SucursalRepository.registrarEntradaInventario: $e');
      rethrow;
    }
  }

  /// Obtiene información de ventas de una sucursal
  ///
  /// [sucursalId] ID de la sucursal
  Future<Map<String, dynamic>> getInformacionVentas(String sucursalId) async {
    try {
      return await _sucursalesApi.getInformacionVentas(sucursalId);
    } catch (e) {
      debugPrint('Error en SucursalRepository.getInformacionVentas: $e');
      rethrow;
    }
  }

  /// Declara facturación de una sucursal
  ///
  /// [sucursalId] ID de la sucursal
  /// [declaracionData] Datos de la declaración de facturación
  Future<Map<String, dynamic>> declararFacturacion(
    String sucursalId,
    Map<String, dynamic> declaracionData,
  ) async {
    try {
      return await _sucursalesApi.declararFacturacion(
        sucursalId,
        declaracionData,
      );
    } catch (e) {
      debugPrint('Error en SucursalRepository.declararFacturacion: $e');
      rethrow;
    }
  }

  /// Sincroniza facturación de una sucursal
  ///
  /// [sucursalId] ID de la sucursal
  /// [sincronizacionData] Datos para la sincronización
  Future<Map<String, dynamic>> sincronizarFacturacion(
    String sucursalId,
    Map<String, dynamic> sincronizacionData,
  ) async {
    try {
      return await _sucursalesApi.sincronizarFacturacion(
        sucursalId,
        sincronizacionData,
      );
    } catch (e) {
      debugPrint('Error en SucursalRepository.sincronizarFacturacion: $e');
      rethrow;
    }
  }
}
