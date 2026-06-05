import 'package:condorsmotors/models/marca.model.dart';
import 'package:condorsmotors/repositories/marcas.repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'marcas.admin.riverpod.g.dart';

/// Notifier para la gestión de marcas en el panel de administración.
///
/// Patron: [AsyncNotifier] de Riverpod 2.x.
/// Maneja el estado asíncrono nativamente mediante [AsyncValue].
@riverpod
class MarcasAdmin extends _$MarcasAdmin {
  late final MarcaRepository _marcaRepository;

  @override
  FutureOr<List<Marca>> build() {
    _marcaRepository = MarcaRepository.instance;
    return _marcaRepository.getMarcas();
  }

  /// Carga o recarga las marcas del servidor
  ///
  /// [forceRefresh] Indica si se debe ignorar el caché local
  Future<void> cargarMarcas({bool forceRefresh = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _marcaRepository.getMarcas(forceRefresh: forceRefresh));
  }

  /// Crea una nueva marca o actualiza una existente
  ///
  /// Lanza la excepción en caso de error para que la UI pueda capturarla en el formulario.
  Future<void> guardarMarca({
    Marca? marca,
    required String nombre,
    String? descripcion,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final Map<String, dynamic> marcaData = {
        'nombre': nombre,
        'descripcion': descripcion,
      };

      if (marca == null) {
        await _marcaRepository.createMarca(marcaData);
      } else {
        await _marcaRepository.updateMarca(marca.id.toString(), marcaData);
      }

      // Retorna la lista fresca del servidor forzando el refresco de caché
      return _marcaRepository.getMarcas(forceRefresh: true);
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
