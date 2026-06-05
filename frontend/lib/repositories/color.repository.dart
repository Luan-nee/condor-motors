import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/models/color.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';

/// Repositorio para gestionar colores.
///
/// Encapsula la lógica de negocio y consumo de APIs de colores,
/// delegando la autenticación mediante el mixin [AuthDelegator].
class ColorRepository with AuthDelegator implements BaseRepository {
  static final ColorRepository _instance = ColorRepository._internal();
  static ColorRepository get instance => _instance;

  late final dynamic _coloresApi;

  ColorRepository._internal() {
    _coloresApi = api_index.api.colores;
  }

  /// Obtiene todos los colores disponibles.
  Future<List<ColorApp>> getColores({bool useCache = true}) =>
      _coloresApi.getColores(useCache: useCache);

  /// Obtiene un color específico por su ID.
  Future<ColorApp?> getColor(int id) async {
    final List<ColorApp> colores = await getColores();
    return colores.firstWhere(
      (color) => color.id == id,
      orElse: () => throw Exception('Color no encontrado'),
    );
  }

  /// Busca colores por coincidencia de nombre.
  Future<List<ColorApp>> buscarPorNombre(String nombre) async {
    final List<ColorApp> todosLosColores = await getColores();
    return todosLosColores
        .where((color) =>
            color.nombre.toLowerCase().contains(nombre.toLowerCase()))
        .toList();
  }

  /// Obtiene un color por nombre exacto.
  Future<ColorApp?> getColorPorNombre(String nombre) async {
    if (nombre.isEmpty) {
      return null;
    }
    final List<ColorApp> colores = await getColores();
    return colores.firstWhere(
      (ColorApp color) => color.nombre.toLowerCase() == nombre.toLowerCase(),
      orElse: () => throw Exception('Color no encontrado'),
    );
  }

  /// Obtiene colores filtrando por hexadecimal.
  Future<List<ColorApp>> buscarPorHexadecimal(String hex) async {
    final List<ColorApp> todosLosColores = await getColores();
    return todosLosColores.where((color) => color.hex == hex).toList();
  }
}
