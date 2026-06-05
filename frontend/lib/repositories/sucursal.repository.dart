import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/api/protected/sucursales.api.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';

/// Repositorio para gestionar sucursales.
///
/// Encapsula la lógica de negocio y consumo de APIs de sucursales,
/// delegando la autenticación mediante el mixin [AuthDelegator].
class SucursalRepository with AuthDelegator implements BaseRepository {
  static final SucursalRepository _instance = SucursalRepository._internal();
  static SucursalRepository get instance => _instance;

  late final SucursalesApi _sucursalesApi;

  SucursalRepository._internal() {
    _sucursalesApi = api_index.api.sucursales;
  }

  /// Obtiene la lista de todas las sucursales.
  Future<List<Sucursal>> getSucursales({bool useCache = true}) =>
      _sucursalesApi.getSucursales(useCache: useCache);

  /// Obtiene los datos completos de una sucursal específica.
  Future<Sucursal> getSucursalData(
    String sucursalId, {
    bool useCache = true,
    bool forceRefresh = false,
  }) =>
      _sucursalesApi.getSucursalData(
        sucursalId,
        useCache: useCache,
        forceRefresh: forceRefresh,
      );

  /// Obtiene la sucursal actual del usuario autenticado.
  Future<Sucursal?> getCurrentUserSucursal() async {
    final sucursalId = await getCurrentSucursalId();
    if (sucursalId == null) {
      return null;
    }
    return getSucursalData(sucursalId);
  }

  /// Crea una sucursal provisional local con datos mínimos.
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

  /// Invalida la caché de sucursales.
  void invalidateCache() => _sucursalesApi.invalidateCache();

  /// Crea una nueva sucursal validando los datos previamente.
  Future<Sucursal> createSucursal(Map<String, dynamic> sucursalData) {
    final String? validationError = Sucursal.validateSucursalData(sucursalData);
    if (validationError != null) {
      throw Exception(validationError);
    }
    return _sucursalesApi.createSucursal(sucursalData);
  }

  /// Actualiza una sucursal existente validando los datos previamente.
  Future<Sucursal> updateSucursal(
      String sucursalId, Map<String, dynamic> sucursalData) {
    final String? validationError = Sucursal.validateSucursalData(sucursalData);
    if (validationError != null) {
      throw Exception(validationError);
    }
    return _sucursalesApi.updateSucursal(sucursalId, sucursalData);
  }

  /// Elimina una sucursal.
  Future<void> deleteSucursal(String sucursalId) =>
      _sucursalesApi.deleteSucursal(sucursalId);

  /// Obtiene los productos asociados a una sucursal.
  Future<List<dynamic>> getProductosSucursal(
    String sucursalId, {
    bool useCache = true,
    bool forceRefresh = false,
  }) =>
      _sucursalesApi.getProductosSucursal(
        sucursalId,
        useCache: useCache,
        forceRefresh: forceRefresh,
      );

  /// Registra entrada de inventario en una sucursal.
  Future<Map<String, dynamic>> registrarEntradaInventario(
    String sucursalId,
    Map<String, dynamic> entradaData,
  ) =>
      _sucursalesApi.registrarEntradaInventario(sucursalId, entradaData);

  /// Obtiene información de ventas de una sucursal.
  Future<Map<String, dynamic>> getInformacionVentas(String sucursalId) =>
      _sucursalesApi.getInformacionVentas(sucursalId);

  /// Declara facturación de una sucursal.
  Future<Map<String, dynamic>> declararFacturacion(
    String sucursalId,
    Map<String, dynamic> declaracionData,
  ) =>
      _sucursalesApi.declararFacturacion(sucursalId, declaracionData);

  /// Sincroniza facturación de una sucursal.
  Future<Map<String, dynamic>> sincronizarFacturacion(
    String sucursalId,
    Map<String, dynamic> sincronizacionData,
  ) =>
      _sucursalesApi.sincronizarFacturacion(sucursalId, sincronizacionData);
}
