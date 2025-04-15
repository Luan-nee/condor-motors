import 'package:condorsmotors/api/main.api.dart' show ApiException;
import 'package:condorsmotors/models/marca.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/material.dart';

/// Provider para gestionar las marcas en el panel de administración
class MarcasProvider extends ChangeNotifier {
  // Repositorio para acceder a las marcas
  final MarcaRepository _marcaRepository;

  // Estados
  bool _isLoading = false;
  bool _isCreating = false;
  String _errorMessage = '';
  List<Marca> _marcas = <Marca>[];
  Map<int, int> _productosPorMarca = <int, int>{};

  // Getters
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  String get errorMessage => _errorMessage;
  List<Marca> get marcas => _marcas;
  Map<int, int> get productosPorMarca => _productosPorMarca;

  // Constructor
  MarcasProvider({MarcaRepository? marcaRepository})
      : _marcaRepository = marcaRepository ?? MarcaRepository.instance;

  /// Recarga todos los datos forzando actualización desde el servidor
  Future<void> recargarDatos() async {
    _setLoading(true);
    clearError();

    try {
      debugPrint('Forzando recarga de datos de marcas desde el repositorio...');
      // Forzar recarga desde el servidor ignorando caché
      await cargarMarcas(forceRefresh: true);
      debugPrint('Datos de marcas recargados exitosamente');
    } catch (e) {
      debugPrint('Error al recargar datos de marcas: $e');
      _setError('Error al recargar datos: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Carga la lista de marcas desde el repositorio
  Future<void> cargarMarcas({bool forceRefresh = false}) async {
    _setLoading(true);
    clearError();

    try {
      debugPrint('Cargando marcas desde el repositorio...');
      // Obtenemos las marcas directamente como objetos Marca
      final List<Marca> marcasObtenidas =
          await _marcaRepository.getMarcas(forceRefresh: forceRefresh);

      // Crear mapa de totalProductos usando el valor real que viene en el modelo
      final Map<int, int> tempProductosPorMarca = <int, int>{};
      for (Marca marca in marcasObtenidas) {
        tempProductosPorMarca[marca.id] = marca.totalProductos;
      }

      _marcas = marcasObtenidas;
      _productosPorMarca = tempProductosPorMarca;
      debugPrint('${_marcas.length} marcas cargadas correctamente');
    } catch (e) {
      debugPrint('Error al cargar marcas: $e');
      _setError('Error al cargar marcas: $e');

      // Si tenemos error de autenticación, no hay datos mock de ejemplo
      if (e is ApiException && e.statusCode == 401) {
        _setError('Sesión expirada. Por favor, inicie sesión nuevamente.');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Guarda una marca (creación o actualización)
  Future<bool> guardarMarca({
    int? id,
    required String nombre,
    String? descripcion,
  }) async {
    _setCreating(true);
    clearError();

    try {
      final Map<String, String> marcaData = <String, String>{
        'nombre': nombre,
      };

      if (descripcion != null && descripcion.isNotEmpty) {
        marcaData['descripcion'] = descripcion;
      }

      if (id != null) {
        // Actualizar marca existente
        debugPrint('Actualizando marca: $id');
        await _marcaRepository.updateMarca(id.toString(), marcaData);
      } else {
        // Crear nueva marca
        debugPrint('Creando nueva marca: $nombre');
        await _marcaRepository.createMarca(marcaData);
      }

      // Recargar la lista de marcas para mostrar cambios
      await cargarMarcas();
      return true;
    } catch (e) {
      debugPrint('Error al guardar marca: $e');
      _setError('Error al guardar marca: $e');
      return false;
    } finally {
      _setCreating(false);
    }
  }

  /// Actualiza una marca existente
  Future<bool> actualizarMarca(Marca marca) async {
    return guardarMarca(
      id: marca.id,
      nombre: marca.nombre,
      descripcion: marca.descripcion,
    );
  }

  /// Elimina una marca
  Future<bool> eliminarMarca(int id) async {
    _setLoading(true);
    clearError();

    try {
      final bool resultado = await _marcaRepository.deleteMarca(id.toString());
      if (resultado) {
        await cargarMarcas();
      } else {
        _setError('No se pudo eliminar la marca.');
      }
      return resultado;
    } catch (e) {
      debugPrint('Error al eliminar marca: $e');
      _setError('Error al eliminar marca: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Obtiene una marca específica por ID
  Marca? buscarMarcaPorId(int id) {
    try {
      return _marcas.firstWhere((marca) => marca.id == id);
    } catch (e) {
      return null;
    }
  }

  // Métodos privados para gestionar el estado
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setCreating(bool value) {
    _isCreating = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Limpia el mensaje de error actual
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
