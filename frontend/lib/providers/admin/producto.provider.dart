import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/color.model.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:condorsmotors/utils/productos_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Provider para gestionar productos
class ProductoProvider extends ChangeNotifier {
  final ProductoRepository _productoRepository = ProductoRepository.instance;

  // Datos de productos
  PaginatedResponse<Producto>? _paginatedProductos;
  List<Producto> _productosFiltrados = <Producto>[];
  final List<String> _categorias = <String>['Todos'];
  List<Sucursal> _sucursales = <Sucursal>[];
  Sucursal? _sucursalSeleccionada;

  // Parámetros de paginación y filtrado
  String _searchQuery = '';
  String _selectedCategory = 'Todos';
  int _currentPage = 1;
  int _pageSize = 10;
  String _sortBy = '';
  String _order = 'desc';

  // Estados
  bool _isLoadingSucursales = false;
  bool _isLoadingProductos = false;
  bool _isLoadingCategorias = false;
  String? _errorMessage;

  // Getters
  PaginatedResponse<Producto>? get paginatedProductos => _paginatedProductos;
  List<Producto> get productosFiltrados => _productosFiltrados;
  List<String> get categorias => _categorias;
  List<Sucursal> get sucursales => _sucursales;
  Sucursal? get sucursalSeleccionada => _sucursalSeleccionada;

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  String get sortBy => _sortBy;
  String get order => _order;

  bool get isLoadingSucursales => _isLoadingSucursales;
  bool get isLoadingProductos => _isLoadingProductos;
  bool get isLoadingCategorias => _isLoadingCategorias;
  String? get errorMessage => _errorMessage;

  /// Inicializa el provider cargando sucursales y categorías
  void inicializar() {
    cargarSucursales();
    cargarCategorias();
  }

  /// Filtra los productos basados en la búsqueda y categoría seleccionada
  void _filtrarProductos() {
    if (_paginatedProductos == null) {
      _productosFiltrados = <Producto>[];
      notifyListeners();
      return;
    }

    _productosFiltrados = ProductosUtils.filtrarProductos(
      productos: _paginatedProductos!.items,
      searchQuery: _searchQuery,
      selectedCategory: _selectedCategory,
    );
    notifyListeners();
  }

  /// Carga las categorías disponibles
  Future<void> cargarCategorias() async {
    _isLoadingCategorias = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<String> categoriasResult =
          await ProductosUtils.obtenerCategorias();

      // Actualizar la lista de categorías para el filtro, manteniendo 'Todos' al inicio
      _categorias
        ..clear()
        ..add('Todos')
        ..addAll(categoriasResult);

      _isLoadingCategorias = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar categorías: $e');
      _errorMessage = 'Error al cargar categorías: $e';
      _isLoadingCategorias = false;
      notifyListeners();
    }
  }

  /// Carga la lista de sucursales
  Future<void> cargarSucursales() async {
    _isLoadingSucursales = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<Sucursal> sucursalesList =
          await api.sucursales.getSucursales();

      _sucursales = sucursalesList;
      _isLoadingSucursales = false;

      if (_sucursales.isNotEmpty && _sucursalSeleccionada == null) {
        _sucursalSeleccionada = _sucursales.first;
        await cargarProductos();
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar sucursales: $e';
      _isLoadingSucursales = false;
      notifyListeners();
    }
  }

  /// Carga los productos aplicando filtros de paginación, ordenamiento y búsqueda
  Future<void> cargarProductos() async {
    if (_sucursalSeleccionada == null) {
      return;
    }

    _isLoadingProductos = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String sucursalId = _sucursalSeleccionada!.id.toString();

      // Aplicar la búsqueda del servidor sólo si la búsqueda es mayor a 3 caracteres
      final String? searchQuery =
          _searchQuery.length >= 3 ? _searchQuery : null;

      debugPrint(
          'ProductosAdmin: Cargando productos de sucursal $sucursalId (página $_currentPage)');

      // Forzar actualización desde servidor (sin caché) después de editar un producto
      final PaginatedResponse<Producto> paginatedProductos =
          await _productoRepository.getProductos(
        sucursalId: sucursalId,
        search: searchQuery,
        page: _currentPage,
        pageSize: _pageSize,
        sortBy: _sortBy.isNotEmpty ? _sortBy : null,
        order: _order,
        // Forzar bypass de caché después de operaciones de escritura
        useCache: false,
        forceRefresh: true, // Forzar refresco ignorando completamente la caché
      );

      _paginatedProductos = paginatedProductos;
      _productosFiltrados = paginatedProductos.items;

      // Si hay una búsqueda local (menos de 3 caracteres) o filtro por categoría, se aplica
      if ((_searchQuery.isNotEmpty && _searchQuery.length < 3) ||
          _selectedCategory != 'Todos') {
        _filtrarProductos();
      }

      _isLoadingProductos = false;
      notifyListeners();

      debugPrint(
          'ProductosAdmin: Productos cargados desde servidor: ${_productosFiltrados.length} items');
    } catch (e) {
      _errorMessage = 'Error al cargar productos: $e';
      _isLoadingProductos = false;
      notifyListeners();
    }
  }

  /// Cambia la página actual de la paginación
  void cambiarPagina(int pagina) {
    if (_currentPage != pagina) {
      _currentPage = pagina;
      cargarProductos();
    }
  }

  /// Cambia el número de items por página
  void cambiarTamanioPagina(int tamanio) {
    if (_pageSize != tamanio) {
      _pageSize = tamanio;
      _currentPage = 1; // Volvemos a la primera página al cambiar el tamaño
      cargarProductos();
    }
  }

  /// Cambia el campo de ordenamiento y la dirección
  void ordenarPor(String campo) {
    if (_sortBy == campo) {
      // Si ya estamos ordenando por este campo, cambiamos la dirección
      _order = _order == 'asc' ? 'desc' : 'asc';
    } else {
      _sortBy = campo;
      _order = 'desc'; // Por defecto ordenamos descendente
    }
    _currentPage = 1; // Volvemos a la primera página al cambiar el orden
    cargarProductos();
  }

  /// Guarda un producto (nuevo o existente)
  Future<bool> guardarProducto(
      Map<String, dynamic> productoData, bool esNuevo) async {
    if (_sucursalSeleccionada == null) {
      _errorMessage = 'No hay sucursal seleccionada';
      notifyListeners();
      return false;
    }

    final String sucursalId = _sucursalSeleccionada!.id.toString();
    _isLoadingProductos = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Añadir logging para diagnóstico
      debugPrint('ProductosAdmin: Guardando producto en sucursal $sucursalId');
      debugPrint('ProductosAdmin: Es nuevo producto: $esNuevo');
      debugPrint('ProductosAdmin: Datos del producto: $productoData');

      Producto? resultado;
      if (esNuevo) {
        resultado = await _productoRepository.createProducto(
          sucursalId: sucursalId,
          productoData: productoData,
        );
        debugPrint('ProductosAdmin: Producto creado correctamente');
      } else {
        // Manejar correctamente el tipo de ID
        final dynamic rawId = productoData['id'];
        if (rawId == null) {
          throw Exception('ID de producto es null. No se puede actualizar.');
        }

        // Convertir ID a entero de forma segura
        final int productoId =
            rawId is int ? rawId : (rawId is String ? int.parse(rawId) : -1);

        if (productoId <= 0) {
          throw Exception('ID de producto inválido: $rawId');
        }

        debugPrint('ProductosAdmin: Actualizando producto ID $productoId');

        resultado = await _productoRepository.updateProducto(
          sucursalId: sucursalId,
          productoId: productoId,
          productoData: productoData,
        );

        debugPrint('ProductosAdmin: Producto actualizado correctamente');

        // Forzar limpieza de caché para este producto específico
        _productoRepository.invalidateCache(sucursalId);
      }

      // Mostrar mensaje de error si no se pudo guardar el producto
      if (resultado == null) {
        _errorMessage = 'No se pudo guardar el producto. Inténtelo de nuevo.';
        _isLoadingProductos = false;
        notifyListeners();
        return false;
      }

      // Recargar productos forzando ignorar caché
      await cargarProductos();

      return true;
    } catch (e) {
      debugPrint('ProductosAdmin: ERROR al guardar producto: $e');
      _errorMessage = 'Error al guardar producto: $e';
      _isLoadingProductos = false;
      notifyListeners();
      return false;
    }
  }

  /// Elimina un producto
  Future<bool> eliminarProducto(Producto producto) async {
    if (_sucursalSeleccionada == null) {
      _errorMessage = 'No hay sucursal seleccionada';
      notifyListeners();
      return false;
    }

    _isLoadingProductos = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String sucursalId = _sucursalSeleccionada!.id.toString();
      final bool eliminado = await _productoRepository.deleteProducto(
        sucursalId: sucursalId,
        productoId: producto.id,
      );

      if (eliminado) {
        await cargarProductos();
        return true;
      } else {
        _errorMessage = 'No se pudo eliminar el producto';
        _isLoadingProductos = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error al eliminar producto: $e';
      _isLoadingProductos = false;
      notifyListeners();
      return false;
    }
  }

  /// Selecciona una sucursal y carga sus productos
  void seleccionarSucursal(Sucursal sucursal) {
    // Solo actualizar si realmente se seleccionó una sucursal diferente
    if (_sucursalSeleccionada?.id != sucursal.id) {
      _sucursalSeleccionada = sucursal;
      _currentPage = 1; // Volver a la primera página al cambiar de sucursal
      notifyListeners();
      cargarProductos();
    }
  }

  /// Actualiza el término de búsqueda y filtra los productos
  void actualizarBusqueda(String query) {
    _searchQuery = query;

    // Si la búsqueda es mayor a 3 caracteres, hacemos una nueva solicitud al servidor
    if (query.length >= 3 || query.isEmpty) {
      _currentPage = 1; // Reiniciar a la primera página
      cargarProductos();
    } else {
      // Para búsquedas cortas, filtramos localmente
      _filtrarProductos();
    }
  }

  /// Actualiza la categoría seleccionada y filtra los productos
  void actualizarCategoria(String categoria) {
    if (_selectedCategory != categoria) {
      _selectedCategory = categoria;
      _filtrarProductos();
    }
  }

  /// Obtiene los colores disponibles
  Future<List<ColorApp>> obtenerColores() async {
    try {
      return await api.colores.getColores();
    } catch (e) {
      _errorMessage = 'Error al obtener colores: $e';
      notifyListeners();
      return <ColorApp>[];
    }
  }

  /// Obtiene la información de un producto en diferentes sucursales
  Future<List<ProductoEnSucursal>> obtenerProductoEnSucursales(
      {required int productoId, required List<Sucursal> sucursales}) async {
    try {
      return await ProductosUtils.obtenerProductoEnSucursales(
        productoId: productoId,
        sucursales: sucursales,
      );
    } catch (e) {
      _errorMessage = 'Error al obtener producto en sucursales: $e';
      notifyListeners();
      return <ProductoEnSucursal>[];
    }
  }

  /// Exporta los productos de la sucursal actual (implementación pendiente)
  Future<bool> exportarProductos() async {
    if (_sucursalSeleccionada == null) {
      return false;
    }

    try {
      // TODO: Implementar la exportación real
      await Future<void>.delayed(const Duration(seconds: 2));
      return true;
    } catch (e) {
      _errorMessage = 'Error al exportar productos: $e';
      notifyListeners();
      return false;
    }
  }
}
