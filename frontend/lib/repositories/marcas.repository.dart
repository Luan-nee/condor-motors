import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/models/marca.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/foundation.dart';

/// Repositorio para gestionar marcas
///
/// Esta clase encapsula la lógica de negocio relacionada con marcas,
/// actuando como una capa intermedia entre la UI y la API
class MarcaRepository implements BaseRepository {
  /// Instancia singleton del repositorio
  static final MarcaRepository _instance = MarcaRepository._internal();

  /// Getter para la instancia singleton
  static MarcaRepository get instance => _instance;

  /// API de marcas
  late final dynamic _marcasApi;

  /// Constructor privado para el patrón singleton
  MarcaRepository._internal() {
    try {
      // Utilizamos la API global inicializada en index.api.dart
      _marcasApi = api.marcas;
    } catch (e) {
      debugPrint('Error al obtener API de marcas: $e');
      // Si hay un error al acceder a la API global, lanzamos una excepción
      throw Exception('No se pudo inicializar MarcaRepository: $e');
    }
  }

  /// Obtiene datos del usuario desde la API centralizada
  ///
  /// Ayuda a los providers a acceder a la información del usuario autenticado
  @override
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      return await api.getUserData();
    } catch (e) {
      debugPrint('Error en MarcaRepository.getUserData: $e');
      return null;
    }
  }

  /// Obtiene el ID de la sucursal del usuario actual
  ///
  /// Útil para operaciones que requieren el ID de sucursal automáticamente
  @override
  Future<String?> getCurrentSucursalId() async {
    try {
      final userData = await getUserData();
      if (userData == null) {
        return null;
      }
      return userData['sucursalId']?.toString();
    } catch (e) {
      debugPrint('Error en MarcaRepository.getCurrentSucursalId: $e');
      return null;
    }
  }

  /// Obtiene todas las marcas
  ///
  /// [forceRefresh] Indica si se debe forzar la recarga desde el servidor
  Future<List<Marca>> getMarcas({bool forceRefresh = false}) async {
    try {
      return await _marcasApi.getMarcas(forceRefresh: forceRefresh);
    } catch (e) {
      debugPrint('Error en MarcaRepository.getMarcas: $e');
      rethrow;
    }
  }

  /// Obtiene una marca específica
  ///
  /// [id] ID de la marca
  Future<Marca> getMarca(String id) async {
    try {
      return await _marcasApi.getMarca(id);
    } catch (e) {
      debugPrint('Error en MarcaRepository.getMarca: $e');
      rethrow;
    }
  }

  /// Crea una nueva marca
  ///
  /// [marcaData] Datos de la marca a crear
  Future<Marca> createMarca(Map<String, String> marcaData) async {
    try {
      return await _marcasApi.createMarca(marcaData);
    } catch (e) {
      debugPrint('Error en MarcaRepository.createMarca: $e');
      rethrow;
    }
  }

  /// Actualiza una marca existente
  ///
  /// [id] ID de la marca a actualizar
  /// [marcaData] Datos actualizados de la marca
  Future<Marca> updateMarca(String id, Map<String, String> marcaData) async {
    try {
      return await _marcasApi.updateMarca(id, marcaData);
    } catch (e) {
      debugPrint('Error en MarcaRepository.updateMarca: $e');
      rethrow;
    }
  }

  /// Elimina una marca
  ///
  /// [id] ID de la marca a eliminar
  Future<bool> deleteMarca(String id) async {
    try {
      return await _marcasApi.deleteMarca(id);
    } catch (e) {
      debugPrint('Error en MarcaRepository.deleteMarca: $e');
      return false;
    }
  }

  /// Busca marcas por nombre
  ///
  /// [nombre] Nombre o parte del nombre de la marca
  Future<List<Marca>> buscarPorNombre(String nombre) async {
    try {
      final List<Marca> todasLasMarcas = await getMarcas();
      return todasLasMarcas
          .where((marca) =>
              marca.nombre.toLowerCase().contains(nombre.toLowerCase()))
          .toList();
    } catch (e) {
      debugPrint('Error en MarcaRepository.buscarPorNombre: $e');
      rethrow;
    }
  }
}
