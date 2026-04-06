import 'package:condorsmotors/models/categoria.model.dart';
import 'package:condorsmotors/repositories/categoria.repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'categorias.admin.riverpod.g.dart';

class CategoriasAdminState {
  final bool isLoading;
  final bool isCreating;
  final List<Categoria> categorias;
  final String? errorMessage;

  CategoriasAdminState({
    this.isLoading = false,
    this.isCreating = false,
    this.categorias = const [],
    this.errorMessage,
  });

  CategoriasAdminState copyWith({
    bool? isLoading,
    bool? isCreating,
    List<Categoria>? categorias,
    String? errorMessage,
  }) {
    return CategoriasAdminState(
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      categorias: categorias ?? this.categorias,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

@riverpod
class CategoriasAdmin extends _$CategoriasAdmin {
  late final CategoriaRepository _categoriaRepository;

  @override
  CategoriasAdminState build() {
    _categoriaRepository = CategoriaRepository.instance;
    Future.microtask(cargarCategorias);
    return CategoriasAdminState();
  }

  Future<void> cargarCategorias({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true);
    try {
      final categorias = await _categoriaRepository.getCategorias(useCache: !forceRefresh);
      state = state.copyWith(
        categorias: categorias,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al cargar categorías: $e',
        isLoading: false,
      );
    }
  }

  Future<void> guardarCategoria({
    Categoria? categoria,
    required String nombre,
    String? descripcion,
  }) async {
    state = state.copyWith(isCreating: true);
    try {
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
      await cargarCategorias(forceRefresh: true);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al guardar categoría: $e',
        isCreating: false,
      );
      rethrow;
    } finally {
      state = state.copyWith(isCreating: false);
    }
  }

  void limpiarError() {
    state = state.copyWith();
  }
}
