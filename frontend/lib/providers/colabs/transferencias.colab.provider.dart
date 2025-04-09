import 'package:condorsmotors/api/protected/productos.api.dart';
import 'package:condorsmotors/api/protected/transferencias.api.dart';
import 'package:condorsmotors/main.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:flutter/foundation.dart';

class TransferenciasColabProvider extends ChangeNotifier {
  final TransferenciasInventarioApi _transferenciasApi = api.transferencias;
  final ProductosApi _productosApi = api.productos;
  bool _isLoading = false;
  String? _errorMessage;
  List<TransferenciaInventario> _transferencias = [];
  String? _sucursalId;
  int? _empleadoId;
  String _selectedFilter = 'Todos';

  // Nueva propiedad para la transferencia en proceso
  TransferenciaInventario? _transferenciaEnProceso;
  final List<DetalleProducto> _productosSeleccionados = [];

  // Nuevas propiedades para filtrado avanzado
  String _searchQuery = '';
  String _filtroCategoria = 'Todos';
  String _ordenarPor = 'nombre';
  String _orden = 'asc';
  bool _soloStockBajo = false;
  bool _soloStockPositivo = false;
  double? _precioMinimo;
  double? _precioMaximo;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<TransferenciaInventario> get transferencias => _transferencias;
  String get selectedFilter => _selectedFilter;
  String? get sucursalId => _sucursalId;
  int? get empleadoId => _empleadoId;
  TransferenciaInventario? get transferenciaEnProceso =>
      _transferenciaEnProceso;
  List<DetalleProducto> get productosSeleccionados => _productosSeleccionados;

  // Nuevos getters para filtrado
  String get searchQuery => _searchQuery;
  String get filtroCategoria => _filtroCategoria;
  String get ordenarPor => _ordenarPor;
  String get orden => _orden;
  bool get soloStockBajo => _soloStockBajo;
  bool get soloStockPositivo => _soloStockPositivo;
  double? get precioMinimo => _precioMinimo;
  double? get precioMaximo => _precioMaximo;

  // Lista de filtros disponibles
  final List<String> filters = [
    'Todos',
    'Pedido',
    'Enviado',
    'Recibido',
  ];

  // Inicializar provider
  Future<void> inicializar() async {
    await _obtenerDatosUsuario();
  }

  // Obtener datos del usuario y cargar transferencias
  Future<void> _obtenerDatosUsuario() async {
    _setLoading(true);

    try {
      final Map<String, dynamic>? userData =
          await api.authService.getUserData();

      if (userData != null) {
        _sucursalId = userData['sucursalId']?.toString();
        _empleadoId = int.tryParse(userData['id']?.toString() ?? '0');

        debugPrint(
            'Usuario obtenido: ID=$_empleadoId, SucursalID=$_sucursalId');

        await cargarTransferencias();
      } else {
        _setError('No se pudieron obtener datos del usuario');
      }
    } catch (e) {
      _setError('Error al obtener datos del usuario: $e');
    }
  }

  // Cargar transferencias desde la API con datos completos de productos
  Future<void> cargarTransferencias() async {
    if (_sucursalId == null) {
      _setError(
          'No se puede cargar transferencias: ID de sucursal no disponible');
      return;
    }

    _setLoading(true);

    try {
      debugPrint('Cargando transferencias para sucursal ID: $_sucursalId');

      String? estadoFiltro;
      if (_selectedFilter != 'Todos') {
        estadoFiltro = EstadoTransferencia.values
            .firstWhere(
              (e) => e.nombre == _selectedFilter,
              orElse: () => EstadoTransferencia.pedido,
            )
            .codigo;
      }

      final List<TransferenciaInventario> transferenciasData =
          await _transferenciasApi.getTransferencias(
        sucursalId: _sucursalId,
        estado: estadoFiltro,
        forceRefresh: true,
      );

      // Cargar datos completos de productos para cada transferencia
      _transferencias = await Future.wait(
        transferenciasData.map((t) => t.cargarDatosProductos(_productosApi)),
      );

      _errorMessage = null;
      notifyListeners();

      debugPrint('Transferencias cargadas: ${_transferencias.length}');
    } catch (e) {
      _setError('Error al cargar transferencias: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Crear nueva transferencia con productos completos
  Future<bool> crearTransferencia(
    int sucursalDestinoId,
    List<DetalleProducto> productos,
  ) async {
    if (_sucursalId == null) {
      _setError(
          'No se puede crear transferencia: ID de sucursal no disponible');
      return false;
    }

    _setLoading(true);

    try {
      // Cargar datos completos de los productos antes de crear la transferencia
      final List<DetalleProducto> productosCompletos = await Future.wait(
        productos
            .map((p) => p.cargarDatosProducto(_productosApi, _sucursalId!)),
      );

      final TransferenciaInventario nuevaTransferencia =
          await _transferenciasApi.createTransferencia(
        sucursalDestinoId: sucursalDestinoId,
        items: productosCompletos
            .map((p) => <String, dynamic>{
                  'productoId': p.id,
                  'cantidad': p.cantidad,
                })
            .toList(),
      );

      // Cargar datos completos de la nueva transferencia
      final TransferenciaInventario transferenciaCompleta =
          await nuevaTransferencia.cargarDatosProductos(_productosApi);

      _transferencias.insert(0, transferenciaCompleta);
      _limpiarTransferenciaEnProceso();
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Error al crear transferencia: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Agregar producto a la transferencia en proceso con datos completos
  Future<void> agregarProducto(DetalleProducto producto) async {
    if (_productosSeleccionados.any((p) => p.id == producto.id)) {
      _setError('El producto ya está en la lista');
      return;
    }

    try {
      // Cargar datos completos del producto
      final DetalleProducto productoCompleto =
          await producto.cargarDatosProducto(_productosApi, _sucursalId!);

      _productosSeleccionados.add(productoCompleto);
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar datos del producto: $e');
    }
  }

  // Obtener cantidad total de productos seleccionados
  int getCantidadTotalProductosSeleccionados() {
    return _productosSeleccionados.fold(
      0,
      (sum, producto) => sum + producto.cantidad,
    );
  }

  // Remover producto de la transferencia en proceso
  void removerProducto(int productoId) {
    _productosSeleccionados.removeWhere((p) => p.id == productoId);
    notifyListeners();
  }

  // Actualizar cantidad de un producto
  void actualizarCantidadProducto(int productoId, int nuevaCantidad) {
    final int index =
        _productosSeleccionados.indexWhere((p) => p.id == productoId);
    if (index != -1) {
      final DetalleProducto productoActual = _productosSeleccionados[index];
      _productosSeleccionados[index] = DetalleProducto(
        id: productoId,
        nombre: productoActual.nombre,
        codigo: productoActual.codigo,
        cantidad: nuevaCantidad,
        producto: productoActual.producto,
      );
      notifyListeners();
    }
  }

  // Limpiar transferencia en proceso
  void _limpiarTransferenciaEnProceso() {
    _transferenciaEnProceso = null;
    _productosSeleccionados.clear();
    notifyListeners();
  }

  // Obtener detalle de una transferencia con productos completos
  Future<TransferenciaInventario> obtenerDetalleTransferencia(String id) async {
    try {
      final TransferenciaInventario transferencia =
          await _transferenciasApi.getTransferencia(id);
      return transferencia.cargarDatosProductos(_productosApi);
    } catch (e) {
      throw Exception('Error al obtener detalle de transferencia: $e');
    }
  }

  // Validar recepción de una transferencia
  Future<void> validarRecepcion(TransferenciaInventario transferencia) async {
    _setLoading(true);

    try {
      await _transferenciasApi.recibirTransferencia(
        transferencia.id.toString(),
      );

      await cargarTransferencias();
    } catch (e) {
      _setError('Error al validar recepción: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Cambiar filtro seleccionado
  Future<void> cambiarFiltro(String filtro) async {
    _selectedFilter = filtro;
    await cargarTransferencias();
  }

  // Obtener transferencias filtradas según el filtro seleccionado
  List<TransferenciaInventario> getTransferenciasFiltradas() {
    if (_selectedFilter == 'Todos') {
      return _transferencias;
    }

    final EstadoTransferencia estadoFiltro =
        EstadoTransferencia.values.firstWhere(
      (e) => e.nombre == _selectedFilter,
      orElse: () => EstadoTransferencia.pedido,
    );

    return _transferencias.where((t) => t.estado == estadoFiltro).toList();
  }

  // Método mejorado para obtener productos con filtros
  Future<PaginatedResponse<Producto>> obtenerProductosFiltrados({
    required String sucursalId,
    int? page,
    int? pageSize,
    bool useCache = false,
  }) async {
    try {
      if (_soloStockBajo) {
        return await _productosApi.getProductosConStockBajo(
          sucursalId: sucursalId,
          page: page,
          pageSize: pageSize,
          sortBy: _ordenarPor,
          useCache: useCache,
        );
      }

      // Usar el método avanzado de filtrado
      return await _productosApi.getProductosPorFiltros(
        sucursalId: sucursalId,
        categoria: _filtroCategoria != 'Todos' ? _filtroCategoria : null,
        precioMinimo: _precioMinimo,
        precioMaximo: _precioMaximo,
        stockPositivo: _soloStockPositivo,
        page: page,
        pageSize: pageSize,
        useCache: useCache,
      );
    } catch (e) {
      _setError('Error al obtener productos filtrados: $e');
      rethrow;
    }
  }

  // Método para actualizar filtros
  void actualizarFiltros({
    String? searchQuery,
    String? categoria,
    String? ordenarPor,
    String? orden,
    bool? soloStockBajo,
    bool? soloStockPositivo,
    double? precioMinimo,
    double? precioMaximo,
  }) {
    bool cambios = false;

    if (searchQuery != null && searchQuery != _searchQuery) {
      _searchQuery = searchQuery;
      cambios = true;
    }
    if (categoria != null && categoria != _filtroCategoria) {
      _filtroCategoria = categoria;
      cambios = true;
    }
    if (ordenarPor != null && ordenarPor != _ordenarPor) {
      _ordenarPor = ordenarPor;
      cambios = true;
    }
    if (orden != null && orden != _orden) {
      _orden = orden;
      cambios = true;
    }
    if (soloStockBajo != null && soloStockBajo != _soloStockBajo) {
      _soloStockBajo = soloStockBajo;
      cambios = true;
    }
    if (soloStockPositivo != null && soloStockPositivo != _soloStockPositivo) {
      _soloStockPositivo = soloStockPositivo;
      cambios = true;
    }
    if (precioMinimo != null && precioMinimo != _precioMinimo) {
      _precioMinimo = precioMinimo;
      cambios = true;
    }
    if (precioMaximo != null && precioMaximo != _precioMaximo) {
      _precioMaximo = precioMaximo;
      cambios = true;
    }

    if (cambios) {
      notifyListeners();
    }
  }

  // Método para restablecer filtros
  void restablecerFiltros() {
    _searchQuery = '';
    _filtroCategoria = 'Todos';
    _ordenarPor = 'nombre';
    _orden = 'asc';
    _soloStockBajo = false;
    _soloStockPositivo = false;
    _precioMinimo = null;
    _precioMaximo = null;
    notifyListeners();
  }

  // Método para obtener productos con stock bajo mejorado
  Future<List<Producto>> obtenerProductosConStockBajo(String sucursalId) async {
    try {
      debugPrint(
          'Obteniendo productos con stock bajo para sucursal $sucursalId');

      final response = await _productosApi.getProductosConStockBajo(
        sucursalId: sucursalId,
        pageSize: 100,
        sortBy: 'stock',
        useCache: false,
      );

      return response.items;
    } catch (e) {
      _setError('Error al obtener productos con stock bajo: $e');
      return [];
    }
  }

  // Método para obtener productos agotados
  Future<List<Producto>> obtenerProductosAgotados(String sucursalId) async {
    try {
      final response = await _productosApi.getProductosAgotados(
        sucursalId: sucursalId,
        pageSize: 100,
        sortBy: 'nombre',
        useCache: false,
      );

      return response.items;
    } catch (e) {
      _setError('Error al obtener productos agotados: $e');
      return [];
    }
  }

  // Método para buscar productos por nombre
  Future<List<Producto>> buscarProductosPorNombre(
    String sucursalId,
    String nombre,
  ) async {
    try {
      if (nombre.isEmpty) {
        return [];
      }

      final response = await _productosApi.buscarProductosPorNombre(
        sucursalId: sucursalId,
        nombre: nombre,
        pageSize: 50,
        useCache: false,
      );

      return response.items;
    } catch (e) {
      _setError('Error al buscar productos: $e');
      return [];
    }
  }

  // Helpers para manejar estados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
    debugPrint('Error: $message');
  }
}
