import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/models/color.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/foundation.dart';

/// Repositorio para gestionar colores
///
/// Esta clase encapsula la lógica de negocio relacionada con colores,
/// actuando como una capa intermedia entre la UI y la API
class ColorRepository implements BaseRepository {
  /// Instancia singleton del repositorio
  static final ColorRepository _instance = ColorRepository._internal();

  /// Getter para la instancia singleton
  static ColorRepository get instance => _instance;

  /// API de colores
  late final dynamic _coloresApi;

  /// Constructor privado para el patrón singleton
  ColorRepository._internal() {
    try {
      // Utilizamos la API global inicializada en index.api.dart
      _coloresApi = api.colores;
    } catch (e) {
      debugPrint('Error al obtener API de colores: $e');
      // Si hay un error al acceder a la API global, lanzamos una excepción
      throw Exception('No se pudo inicializar ColorRepository: $e');
    }
  }

  /// Obtiene todos los colores disponibles
  ///
  /// [useCache] Indica si se debe usar la caché
  Future<List<ColorApp>> getColores({bool useCache = true}) async {
    try {
      return await _coloresApi.getColores(useCache: useCache);
    } catch (e) {
      debugPrint('Error en ColorRepository.getColores: $e');
      rethrow;
    }
  }

  /// Obtiene un color específico por su ID
  ///
  /// [id] ID del color
  Future<ColorApp?> getColor(int id) async {
    try {
      final List<ColorApp> colores = await getColores();
      return colores.firstWhere(
        (color) => color.id == id,
        orElse: () => throw Exception('Color no encontrado'),
      );
    } catch (e) {
      debugPrint('Error en ColorRepository.getColor: $e');
      return null;
    }
  }

  /// Busca colores por nombre
  ///
  /// [nombre] Nombre o parte del nombre del color
  Future<List<ColorApp>> buscarPorNombre(String nombre) async {
    try {
      final List<ColorApp> todosLosColores = await getColores();
      return todosLosColores
          .where((color) =>
              color.nombre.toLowerCase().contains(nombre.toLowerCase()))
          .toList();
    } catch (e) {
      debugPrint('Error en ColorRepository.buscarPorNombre: $e');
      rethrow;
    }
  }

  /// Obtiene un color por nombre exacto
  ///
  /// [nombre] Nombre exacto del color
  Future<ColorApp?> getColorPorNombre(String nombre) async {
    try {
      if (nombre.isEmpty) {
        return null;
      }

      final List<ColorApp> colores = await getColores();
      return colores.firstWhere(
        (ColorApp color) => color.nombre.toLowerCase() == nombre.toLowerCase(),
        orElse: () => throw Exception('Color no encontrado'),
      );
    } catch (e) {
      debugPrint('Error en ColorRepository.getColorPorNombre: $e');
      return null;
    }
  }

  /// Obtiene colores por hexadecimal
  ///
  /// [hex] Código hexadecimal del color
  Future<List<ColorApp>> buscarPorHexadecimal(String hex) async {
    try {
      final List<ColorApp> todosLosColores = await getColores();
      return todosLosColores.where((color) => color.hex == hex).toList();
    } catch (e) {
      debugPrint('Error en ColorRepository.buscarPorHexadecimal: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserData() =>
      AuthRepository.instance.getUserData();

  @override
  Future<String?> getCurrentSucursalId() =>
      AuthRepository.instance.getCurrentSucursalId();
}
