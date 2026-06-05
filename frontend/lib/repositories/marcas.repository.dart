import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/api/protected/marcas.api.dart';
import 'package:condorsmotors/models/marca.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';

/// Repositorio para gestionar marcas.
///
/// Encapsula la lógica de negocio y consumo de APIs de marcas,
/// delegando la autenticación mediante el mixin [AuthDelegator].
class MarcaRepository with AuthDelegator implements BaseRepository {
  static final MarcaRepository _instance = MarcaRepository._internal();
  static MarcaRepository get instance => _instance;

  late final MarcasApi _marcasApi;

  MarcaRepository._internal() {
    _marcasApi = api_index.api.marcas;
  }

  /// Obtiene todas las marcas.
  Future<List<Marca>> getMarcas({bool forceRefresh = false}) =>
      _marcasApi.getMarcas(forceRefresh: forceRefresh);

  /// Obtiene una marca específica por su ID.
  Future<Marca> getMarca(String id) =>
      _marcasApi.getMarca(id);

  /// Crea una nueva marca.
  Future<Marca> createMarca(Map<String, dynamic> marcaData) =>
      _marcasApi.createMarca(marcaData);

  /// Actualiza una marca existente.
  Future<Marca> updateMarca(String id, Map<String, dynamic> marcaData) =>
      _marcasApi.updateMarca(id, marcaData);

  /// Elimina una marca por su ID.
  Future<bool> deleteMarca(String id) =>
      _marcasApi.deleteMarca(id);

  /// Busca marcas filtrando por nombre.
  Future<List<Marca>> buscarPorNombre(String nombre) async {
    final List<Marca> todasLasMarcas = await getMarcas();
    return todasLasMarcas
        .where((marca) =>
            marca.nombre.toLowerCase().contains(nombre.toLowerCase()))
        .toList();
  }
}
