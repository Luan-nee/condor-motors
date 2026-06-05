import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/api/protected/categorias.api.dart';
import 'package:condorsmotors/models/categoria.model.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';

/// Repositorio para gestionar categorías.
///
/// Encapsula la lógica de negocio y consumo de APIs de categorías,
/// delegando la autenticación mediante el mixin [AuthDelegator].
class CategoriaRepository with AuthDelegator implements BaseRepository {
  static final CategoriaRepository _instance = CategoriaRepository._internal();
  static CategoriaRepository get instance => _instance;

  late final CategoriasApi _categoriasApi;

  CategoriaRepository._internal() {
    _categoriasApi = api_index.api.categorias;
  }

  /// Obtiene todas las categorías como objetos.
  Future<List<Categoria>> getCategorias({bool useCache = true}) =>
      _categoriasApi.getCategoriasObjetos(useCache: useCache);

  /// Obtiene categorías paginadas.
  Future<PaginatedResponse<Categoria>> getCategoriasPaginadas({
    int? page,
    int? pageSize,
    bool useCache = true,
  }) =>
      _categoriasApi.getCategoriasObjetosPaginados(
        page: page,
        pageSize: pageSize,
        useCache: useCache,
      );

  /// Obtiene una categoría específica por su ID.
  Future<Categoria> getCategoria(String id, {bool useCache = true}) =>
      _categoriasApi.getCategoriaObjeto(id, useCache: useCache);

  /// Crea una nueva categoría con parámetros individuales.
  Future<Categoria> createCategoria({
    required String nombre,
    String? descripcion,
  }) async {
    final Map<String, dynamic> data = await _categoriasApi.createCategoria(
      nombre: nombre,
      descripcion: descripcion,
    );
    return Categoria.fromJson(data);
  }

  /// Crea una nueva categoría a partir de un objeto Categoria.
  Future<Categoria> createCategoriaFromObject(Categoria categoria) =>
      _categoriasApi.createCategoriaObjeto(categoria);

  /// Actualiza una categoría existente con parámetros individuales.
  Future<Categoria> updateCategoria({
    required String id,
    String? nombre,
    String? descripcion,
  }) async {
    final Map<String, dynamic> data = await _categoriasApi.updateCategoria(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
    );
    return Categoria.fromJson(data);
  }

  /// Actualiza una categoría a partir de un objeto Categoria.
  Future<Categoria> updateCategoriaFromObject(Categoria categoria) =>
      _categoriasApi.updateCategoriaObjeto(categoria);

  /// Elimina una categoría por su ID.
  Future<bool> deleteCategoria(String id) =>
      _categoriasApi.deleteCategoria(id);

  /// Busca categorías filtrando por nombre.
  Future<List<Categoria>> buscarCategoriasPorNombre(
    String nombre, {
    bool useCache = true,
  }) =>
      _categoriasApi.buscarCategoriasPorNombre(
        nombre,
        useCache: useCache,
      );

  /// Invalida la caché de categorías.
  void invalidateCache([String? categoriaId]) =>
      _categoriasApi.invalidateCache(categoriaId);
}
