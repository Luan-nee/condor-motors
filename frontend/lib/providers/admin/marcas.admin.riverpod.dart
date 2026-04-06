import 'package:condorsmotors/models/marca.model.dart';
import 'package:condorsmotors/repositories/marcas.repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'marcas.admin.riverpod.g.dart';

class MarcasAdminState {
  final bool isLoading;
  final bool isCreating;
  final List<Marca> marcas;
  final String? errorMessage;

  MarcasAdminState({
    this.isLoading = false,
    this.isCreating = false,
    this.marcas = const [],
    this.errorMessage,
  });

  MarcasAdminState copyWith({
    bool? isLoading,
    bool? isCreating,
    List<Marca>? marcas,
    String? errorMessage,
  }) {
    return MarcasAdminState(
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      marcas: marcas ?? this.marcas,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

@riverpod
class MarcasAdmin extends _$MarcasAdmin {
  late final MarcaRepository _marcaRepository;

  @override
  MarcasAdminState build() {
    _marcaRepository = MarcaRepository.instance;
    Future.microtask(cargarMarcas);
    return MarcasAdminState();
  }

  Future<void> cargarMarcas({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true);
    try {
      final marcas = await _marcaRepository.getMarcas();
      state = state.copyWith(
        marcas: marcas,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al cargar marcas: $e',
        isLoading: false,
      );
    }
  }

  Future<void> guardarMarca({
    Marca? marca,
    required String nombre,
    String? descripcion,
  }) async {
    state = state.copyWith(isCreating: true);
    try {
      final marcaData = {
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
      };

      if (marca == null) {
        await _marcaRepository.createMarca(marcaData);
      } else {
        await _marcaRepository.updateMarca(marca.id.toString(), marcaData);
      }
      await cargarMarcas(forceRefresh: true);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al guardar marca: $e',
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
