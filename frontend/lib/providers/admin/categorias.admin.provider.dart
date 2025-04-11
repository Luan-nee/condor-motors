import 'package:condorsmotors/models/categoria.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/material.dart';

/// Provider para gestionar las categorías en el panel de administración
class CategoriasProvider extends ChangeNotifier {
  // Repositorio para acceder a las categorías
  final CategoriaRepository _categoriaRepository;

  // Estados
  bool _isLoading = false;
  bool _isCreating = false;
  String _errorMessage = '';
  List<Categoria> _categorias = [];

  // Getters
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  String get errorMessage => _errorMessage;
  List<Categoria> get categorias => _categorias;

  // Constructor
  CategoriasProvider({CategoriaRepository? categoriaRepository})
      : _categoriaRepository =
            categoriaRepository ?? CategoriaRepository.instance;

  /// Recarga todos los datos forzando actualización desde el servidor
  Future<void> recargarDatos() async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint(
          'Forzando recarga de datos de categorías desde el repositorio...');
      await cargarCategorias(useCache: false);
      debugPrint('Datos de categorías recargados exitosamente');
    } catch (e) {
      debugPrint('Error al recargar datos de categorías: $e');
      _setError('Error al recargar datos: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Carga la lista de categorías desde el repositorio
  Future<void> cargarCategorias({bool useCache = true}) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('Cargando categorías desde el repositorio...');

      final List<Categoria> categoriasObtenidas =
          await _categoriaRepository.getCategorias(useCache: useCache);

      _categorias = categoriasObtenidas;
      debugPrint('${_categorias.length} categorías cargadas correctamente');
    } catch (e) {
      debugPrint('Error al cargar categorías: $e');
      _setError('Error al cargar categorías: $e');

      // En caso de error, usar datos de ejemplo para desarrollo
      _cargarCategoriasDePrueba();
    } finally {
      _setLoading(false);
    }
  }

  /// Crea una nueva categoría o actualiza una existente
  Future<bool> guardarCategoria({
    int? id,
    required String nombre,
    String? descripcion,
  }) async {
    _setCreating(true);
    _clearError();

    try {
      if (id == null) {
        // Crear nueva categoría
        debugPrint('Creando nueva categoría: $nombre');
        await _categoriaRepository.createCategoria(
          nombre: nombre,
          descripcion: descripcion?.isNotEmpty == true ? descripcion : null,
        );
      } else {
        // Actualizar categoría existente
        debugPrint('Actualizando categoría: $id');
        await _categoriaRepository.updateCategoria(
          id: id.toString(),
          nombre: nombre,
          descripcion: descripcion?.isNotEmpty == true ? descripcion : null,
        );
      }

      // Recargar las categorías para mostrar cambios
      await cargarCategorias(useCache: false);
      return true;
    } catch (e) {
      debugPrint('Error al guardar categoría: $e');
      _setError('Error al guardar categoría: $e');
      return false;
    } finally {
      _setCreating(false);
    }
  }

  /// Actualiza una categoría usando un objeto Categoria
  Future<bool> actualizarCategoria(Categoria categoria) async {
    return guardarCategoria(
      id: categoria.id,
      nombre: categoria.nombre,
      descripcion: categoria.descripcion,
    );
  }

  /// Elimina una categoría
  Future<bool> eliminarCategoria(int id) async {
    _setLoading(true);
    _clearError();

    try {
      final bool resultado =
          await _categoriaRepository.deleteCategoria(id.toString());
      if (resultado) {
        await cargarCategorias(useCache: false);
      } else {
        _setError('No se pudo eliminar la categoría.');
      }
      return resultado;
    } catch (e) {
      debugPrint('Error al eliminar categoría: $e');
      _setError('Error al eliminar categoría: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Obtiene el detalle de una categoría específica
  Future<Categoria?> obtenerCategoria(int id) async {
    try {
      return await _categoriaRepository.getCategoria(id.toString());
    } catch (e) {
      debugPrint('Error al obtener detalle de categoría: $e');
      _setError('Error al obtener detalle de categoría: $e');
      return null;
    }
  }

  /// Busca una categoría por su ID
  Categoria? buscarCategoriaPorId(int id) {
    try {
      return _categorias.firstWhere((cat) => cat.id == id);
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

  // Método privado renombrado para uso interno
  void _clearError() {
    clearError();
  }

  // Carga datos de prueba en caso de error
  void _cargarCategoriasDePrueba() {
    _categorias = [
      Categoria(
        id: 1,
        nombre: 'Cascos',
        descripcion: 'Cascos de seguridad para motociclistas',
        totalProductos: 45,
      ),
      Categoria(
        id: 2,
        nombre: 'Lubricantes',
        descripcion: 'Aceites y lubricantes para motocicletas',
        totalProductos: 32,
      ),
      Categoria(
        id: 3,
        nombre: 'Llantas',
        descripcion: 'Llantas y neumáticos para motocicletas',
        totalProductos: 28,
      ),
      Categoria(
        id: 4,
        nombre: 'Repuestos',
        descripcion: 'Repuestos y partes para motocicletas',
        totalProductos: 156,
      ),
    ];
  }
}
