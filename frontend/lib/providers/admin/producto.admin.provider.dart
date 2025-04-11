import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/categoria.model.dart';
import 'package:condorsmotors/models/color.model.dart';
import 'package:condorsmotors/models/marca.model.dart';
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
  bool _isLoadingColores = false;
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
  bool get isLoadingColores => _isLoadingColores;
  String? get errorMessage => _errorMessage;

  // Propiedades para formulario de productos
  Map<String, Map<String, Object>> _categoriasMap =
      <String, Map<String, Object>>{};
  Map<String, Map<String, Object>> _marcasMap = <String, Map<String, Object>>{};
  List<ColorApp> _colores = <ColorApp>[];

  Map<String, Map<String, Object>> get categoriasMap => _categoriasMap;
  Map<String, Map<String, Object>> get marcasMap => _marcasMap;
  List<ColorApp> get colores => _colores;

  /// Inicializa el provider cargando sucursales y categorías
  Future<void> inicializar() async {
    await cargarSucursales();
    await cargarCategorias();
    await cargarColores();
    await cargarMarcas();
  }

  /// Recarga todos los datos forzando actualización desde el servidor
  Future<void> recargarDatos() async {
    _errorMessage = null;
    notifyListeners();

    try {
      // Forzar recarga de sucursales
      await cargarSucursales();

      // Forzar recarga de categorías
      await cargarCategorias();

      // Forzar recarga de colores
      await cargarColores();

      // Forzar recarga de marcas
      await cargarMarcas();

      if (_sucursalSeleccionada != null) {
        // Invalidar caché en el repositorio
        _productoRepository
            .invalidateCache(_sucursalSeleccionada!.id.toString());

        // Recargar productos forzando actualización desde servidor
        await cargarProductos();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error al recargar datos: $e');
      _errorMessage = 'Error al recargar datos: $e';
      notifyListeners();
    }
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

      // Obtener las categorías como objetos para tener acceso a los IDs
      final List<Categoria> categoriasList =
          await api.categorias.getCategoriasObjetos(useCache: false);

      // Extraer nombres para la lista desplegable
      List<String> categoriaNames = categoriasList
          .map<String>((Categoria cat) => cat.nombre)
          .where((String nombre) => nombre.isNotEmpty)
          .toList();
      categoriaNames.sort(); // Mantener orden alfabético

      // Crear un mapa para fácil acceso a los IDs por nombre
      _categoriasMap = <String, Map<String, Object>>{
        for (Categoria cat in categoriasList)
          cat.nombre: <String, Object>{'id': cat.id, 'nombre': cat.nombre}
      };

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
      }

      // Mostrar mensaje de error si no se pudo guardar el producto
      if (resultado == null) {
        _errorMessage = 'No se pudo guardar el producto. Inténtelo de nuevo.';
        _isLoadingProductos = false;
        notifyListeners();
        return false;
      }

      // Forzar limpieza de caché para los productos de esta sucursal
      _productoRepository.invalidateCache(sucursalId);

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

  /// Carga las marcas disponibles
  Future<void> cargarMarcas() async {
    _isLoadingProductos = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Obtenemos las marcas como objetos tipados
      final ResultadoPaginado<Marca> marcasResult =
          await api.marcas.getMarcasPaginadas(useCache: false);

      // Extraemos la lista de marcas del resultado paginado
      final List<Marca> marcasList = marcasResult.items;

      // Crear un mapa para fácil acceso a los IDs por nombre
      _marcasMap = <String, Map<String, Object>>{
        for (Marca marca in marcasList)
          marca.nombre: <String, Object>{'id': marca.id, 'nombre': marca.nombre}
      };

      _isLoadingProductos = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar marcas: $e');
      _errorMessage = 'Error al cargar marcas: $e';
      _isLoadingProductos = false;
      notifyListeners();
    }
  }

  /// Carga los colores disponibles
  Future<void> cargarColores() async {
    _isLoadingColores = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _colores = await api.colores.getColores();
      _isLoadingColores = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar colores: $e');
      _errorMessage = 'Error al cargar colores: $e';
      _isLoadingColores = false;
      notifyListeners();
    }
  }

  /// Obtener información completa de un producto en todas las sucursales
  Future<List<ProductoEnSucursal>> obtenerSucursalesCompartidas(
      int productoId) async {
    try {
      return await ProductosUtils.obtenerProductoEnSucursales(
        productoId: productoId,
        sucursales: _sucursales,
      );
    } catch (e) {
      debugPrint('Error al obtener sucursales compartidas: $e');
      _errorMessage = 'Error al obtener sucursales compartidas: $e';
      notifyListeners();
      return <ProductoEnSucursal>[];
    }
  }

  /// Obtener información completa de un producto en las sucursales especificadas
  Future<List<ProductoEnSucursal>> obtenerProductoEnSucursales({
    required int productoId,
    required List<Sucursal> sucursales,
  }) async {
    try {
      return await ProductosUtils.obtenerProductoEnSucursales(
        productoId: productoId,
        sucursales: sucursales,
      );
    } catch (e) {
      debugPrint('Error al obtener producto en sucursales: $e');
      _errorMessage = 'Error al obtener producto en sucursales: $e';
      notifyListeners();
      return <ProductoEnSucursal>[];
    }
  }

  /// Obtiene el color por nombre
  ColorApp? obtenerColorPorNombre(String nombre) {
    try {
      if (nombre.isEmpty) {
        return null;
      }
      return _colores.firstWhere(
        (ColorApp color) => color.nombre.toLowerCase() == nombre.toLowerCase(),
        orElse: () => _colores.isNotEmpty
            ? _colores.first
            : throw Exception('No hay colores disponibles'),
      );
    } catch (e) {
      debugPrint('Error al obtener color por nombre: $e');
      return _colores.isNotEmpty ? _colores.first : null;
    }
  }

  /// Obtener lista de colores disponibles
  Future<List<ColorApp>> obtenerColores() async {
    if (_colores.isEmpty) {
      await cargarColores();
    }
    return _colores;
  }

  /// Prepara los datos del producto para guardar
  Map<String, dynamic> prepararDatosProducto({
    required Producto? producto,
    required String nombre,
    required String descripcion,
    required String marca,
    required String categoria,
    required double precioVenta,
    required double precioCompra,
    required int stock,
    required int? stockMinimo,
    required bool liquidacion,
    required double? precioOferta,
    required String tipoPromocion,
    required int? cantidadMinimaDescuento,
    required int? cantidadGratisDescuento,
    required int? porcentajeDescuento,
    required ColorApp? colorSeleccionado,
  }) {
    final bool esNuevoProducto = producto == null;

    // Construir el cuerpo de la solicitud
    final Map<String, dynamic> productoData = <String, dynamic>{
      if (producto != null) 'id': producto.id,
      'nombre': nombre,
      'descripcion': descripcion,
      'marca': marca,
      'categoria': categoria,
      'precioVenta': precioVenta,
      'precioCompra': precioCompra,
      // Solo incluir stock para productos nuevos
      if (esNuevoProducto) 'stock': stock,

      // Liquidación (campo independiente)
      'liquidacion': liquidacion,

      // Por defecto, valores nulos para los campos opcionales
      'cantidadMinimaDescuento': null,
      'cantidadGratisDescuento': null,
      'porcentajeDescuento': null,
      'precioOferta': null,
    };

    // Si está en liquidación, incluir precio de oferta
    if (liquidacion && precioOferta != null) {
      productoData['precioOferta'] = precioOferta;
    }

    // Aplicar configuración según el tipo de promoción seleccionada
    switch (tipoPromocion) {
      case 'gratis':
        if (cantidadMinimaDescuento != null) {
          productoData['cantidadMinimaDescuento'] = cantidadMinimaDescuento;
        }
        if (cantidadGratisDescuento != null) {
          productoData['cantidadGratisDescuento'] = cantidadGratisDescuento;
        }
        break;

      case 'descuentoPorcentual':
        if (cantidadMinimaDescuento != null) {
          productoData['cantidadMinimaDescuento'] = cantidadMinimaDescuento;
        }
        if (porcentajeDescuento != null) {
          productoData['porcentajeDescuento'] = porcentajeDescuento;
        }
        break;
    }

    // Stock mínimo (opcional)
    if (stockMinimo != null) {
      productoData['stockMinimo'] = stockMinimo;
    }

    // Buscar y añadir el ID de categoría si está disponible
    if (_categoriasMap.containsKey(categoria)) {
      final Map<String, Object>? categoriaInfo = _categoriasMap[categoria];
      if (categoriaInfo != null && categoriaInfo['id'] != null) {
        final String idStr = categoriaInfo['id'].toString();
        final int? id = int.tryParse(idStr);
        if (id != null) {
          productoData['categoriaId'] = id;
          debugPrint(
              'ProductoProvider: Categoría $categoria con ID válido: $id');
        } else {
          debugPrint(
              'ProductoProvider: Advertencia - ID de categoría no válido: $idStr');
        }
      }
    }

    // Buscar y añadir el ID de marca si está disponible
    if (_marcasMap.containsKey(marca)) {
      final Map<String, Object>? marcaInfo = _marcasMap[marca];
      if (marcaInfo != null && marcaInfo['id'] != null) {
        final String idStr = marcaInfo['id'].toString();
        final int? id = int.tryParse(idStr);
        if (id != null) {
          productoData['marcaId'] = id;
          debugPrint('ProductoProvider: Marca $marca con ID válido: $id');
        } else {
          debugPrint(
              'ProductoProvider: Advertencia - ID de marca no válido: $idStr');
        }
      }
    }

    // Manejar el color correctamente
    if (colorSeleccionado != null) {
      // ColorApp.id ya es int según la definición del modelo
      productoData['colorId'] = colorSeleccionado.id;
      debugPrint(
          'ProductoProvider: Color ${colorSeleccionado.nombre} con ID: ${colorSeleccionado.id}');

      // Incluir también el nombre para claridad
      productoData['color'] = colorSeleccionado.nombre;
    }

    return productoData;
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
