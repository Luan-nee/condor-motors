import 'package:condorsmotors/models/categoria.model.dart';
import 'package:condorsmotors/repositories/categoria.repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'categorias.admin.riverpod.g.dart';

/// Notifier para la gestión de categorías en el panel de administración.
///
/// Patron: [AsyncNotifier] de Riverpod 2.x.
/// Resuelve el bug sistemático de limpieza de errores y elimina el boilerplate.
@riverpod
class CategoriasAdmin extends _$CategoriasAdmin {
  late final CategoriaRepository _categoriaRepository;

  @override
  FutureOr<List<Categoria>> build() {
    _categoriaRepository = CategoriaRepository.instance;
    return _categoriaRepository.getCategorias();
  }

  /// Carga o recarga las categorías del servidor
  ///
  /// [forceRefresh] Indica si se debe ignorar el caché local
  Future<void> cargarCategorias({bool forceRefresh = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _categoriaRepository.getCategorias(useCache: !forceRefresh));
  }

  /// Crea una nueva categoría o actualiza una existente
  ///
  /// Lanza la excepción para que el modal de la UI capture y muestre errores locales.
  Future<void> guardarCategoria({
    Categoria? categoria,
    required String nombre,
    String? descripcion,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (categoria == null) {
        await _categoriaRepository.createCategoria(
          nombre: nombre,
          descripcion: descripcion,
        );
      } else {
        await _categoriaRepository.updateCategoria(
          id: categoria.id.toString(),
          nombre: nombre,
          descripcion: descripcion,
        );
      }

      // Retorna la lista fresca del servidor forzando el refresco de caché
      return _categoriaRepository.getCategorias(useCache: false);
    });
  }

  /// Limpia el estado de error y retorna al último valor de datos disponible
  void limpiarError() {
    final currentVal = state.value;
    if (currentVal != null) {
      state = AsyncData(currentVal);
    } else {
      state = const AsyncData([]);
    }
  }
}
