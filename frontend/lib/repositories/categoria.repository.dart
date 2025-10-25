import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/api/protected/categorias.api.dart';
import 'package:condorsmotors/models/categoria.model.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/foundation.dart';

/// Repositorio para gestionar categorías
///
/// Esta clase encapsula la lógica de negocio relacionada con categorías,
/// actuando como una capa intermedia entre la UI y la API
class CategoriaRepository implements BaseRepository {
  /// Instancia singleton del repositorio
  static final CategoriaRepository _instance = CategoriaRepository._internal();

  /// Getter para la instancia singleton
  static CategoriaRepository get instance => _instance;

  /// API de categorías
  late final CategoriasApi _categoriasApi;

  /// Constructor privado para el patrón singleton
  CategoriaRepository._internal() {
    try {
      // Utilizamos la API global inicializada en index.api.dart
      _categoriasApi = api_index.api.categorias;
    } catch (e) {
      debugPrint('Error al obtener CategoriasApi: $e');
      // Si hay un error al acceder a la API global, lanzamos una excepción
      throw Exception('No se pudo inicializar CategoriaRepository: $e');
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

  /// Obtiene todas las categorías como objetos
  ///
  /// [useCache] Indica si se debe usar el caché
  Future<List<Categoria>> getCategorias({bool useCache = true}) async {
    try {
      return await _categoriasApi.getCategoriasObjetos(useCache: useCache);
    } catch (e) {
      debugPrint('Error en CategoriaRepository.getCategorias: $e');
      rethrow;
    }
  }

  /// Obtiene categorías paginadas
  ///
  /// [page] Número de página
  /// [pageSize] Tamaño de página
  /// [useCache] Indica si se debe usar el caché
  Future<PaginatedResponse<Categoria>> getCategoriasPaginadas({
    int? page,
    int? pageSize,
    bool useCache = true,
  }) async {
    try {
      return await _categoriasApi.getCategoriasObjetosPaginados(
        page: page,
        pageSize: pageSize,
        useCache: useCache,
      );
    } catch (e) {
      debugPrint('Error en CategoriaRepository.getCategoriasPaginadas: $e');
      rethrow;
    }
  }

  /// Obtiene una categoría específica por su ID
  ///
  /// [id] ID de la categoría
  /// [useCache] Indica si se debe usar el caché
  Future<Categoria> getCategoria(String id, {bool useCache = true}) async {
    try {
      return await _categoriasApi.getCategoriaObjeto(id, useCache: useCache);
    } catch (e) {
      debugPrint('Error en CategoriaRepository.getCategoria: $e');
      rethrow;
    }
  }

  /// Crea una nueva categoría
  ///
  /// [nombre] Nombre de la categoría
  /// [descripcion] Descripción opcional
  Future<Categoria> createCategoria({
    required String nombre,
    String? descripcion,
  }) async {
    try {
      final Map<String, dynamic> data = await _categoriasApi.createCategoria(
        nombre: nombre,
        descripcion: descripcion,
      );
      return Categoria.fromJson(data);
    } catch (e) {
      debugPrint('Error en CategoriaRepository.createCategoria: $e');
      rethrow;
    }
  }

  /// Crea una nueva categoría a partir de un objeto Categoria
  ///
  /// [categoria] Objeto Categoria a crear
  Future<Categoria> createCategoriaFromObject(Categoria categoria) async {
    try {
      return await _categoriasApi.createCategoriaObjeto(categoria);
    } catch (e) {
      debugPrint('Error en CategoriaRepository.createCategoriaFromObject: $e');
      rethrow;
    }
  }

  /// Actualiza una categoría existente
  ///
  /// [id] ID de la categoría
  /// [nombre] Nuevo nombre de la categoría (opcional)
  /// [descripcion] Nueva descripción de la categoría (opcional)
  Future<Categoria> updateCategoria({
    required String id,
    String? nombre,
    String? descripcion,
  }) async {
    try {
      final Map<String, dynamic> data = await _categoriasApi.updateCategoria(
        id: id,
        nombre: nombre,
        descripcion: descripcion,
      );
      return Categoria.fromJson(data);
    } catch (e) {
      debugPrint('Error en CategoriaRepository.updateCategoria: $e');
      rethrow;
    }
  }

  /// Actualiza una categoría a partir de un objeto Categoria
  ///
  /// [categoria] Objeto Categoria con los datos actualizados
  Future<Categoria> updateCategoriaFromObject(Categoria categoria) async {
    try {
      return await _categoriasApi.updateCategoriaObjeto(categoria);
    } catch (e) {
      debugPrint('Error en CategoriaRepository.updateCategoriaFromObject: $e');
      rethrow;
    }
  }

  /// Elimina una categoría
  ///
  /// [id] ID de la categoría a eliminar
  Future<bool> deleteCategoria(String id) async {
    try {
      return await _categoriasApi.deleteCategoria(id);
    } catch (e) {
      debugPrint('Error en CategoriaRepository.deleteCategoria: $e');
      return false;
    }
  }

  /// Busca categorías por nombre
  ///
  /// [nombre] Término de búsqueda
  /// [useCache] Indica si se debe usar el caché
  Future<List<Categoria>> buscarCategoriasPorNombre(
    String nombre, {
    bool useCache = true,
  }) async {
    try {
      return await _categoriasApi.buscarCategoriasPorNombre(
        nombre,
        useCache: useCache,
      );
    } catch (e) {
      debugPrint('Error en CategoriaRepository.buscarCategoriasPorNombre: $e');
      rethrow;
    }
  }

  /// Invalida la caché de categorías
  ///
  /// [categoriaId] ID de una categoría específica (opcional)
  void invalidateCache([String? categoriaId]) {
    try {
      _categoriasApi.invalidateCache(categoriaId);
    } catch (e) {
      debugPrint('Error en CategoriaRepository.invalidateCache: $e');
    }
  }
}
