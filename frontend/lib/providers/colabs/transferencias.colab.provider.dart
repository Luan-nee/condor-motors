import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/foundation.dart';

class TransferenciasColabProvider extends ChangeNotifier {
  // Instancias de repositorios
  final TransferenciaRepository _transferenciaRepository =
      TransferenciaRepository.instance;
  final ProductoRepository _productoRepository = ProductoRepository.instance;

  bool _isLoading = false;
  String? _errorMessage;
  List<TransferenciaInventario> _transferencias = [];
  String? _sucursalId;
  int? _empleadoId;
  String _selectedFilter = 'Todos';

  // Nueva propiedad para la transferencia en proceso
  TransferenciaInventario? _transferenciaEnProceso;
  final List<DetalleProducto> _productosSeleccionados = [];

  // Agregar propiedad para almacenar el detalle de transferencia actual
  TransferenciaInventario? _detalleTransferenciaActual;

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

  // Getter para el detalle de la transferencia actual
  TransferenciaInventario? get detalleTransferenciaActual =>
      _detalleTransferenciaActual;

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
          await _transferenciaRepository.getUserData();

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
  Future<void> cargarTransferencias({bool forceRefresh = false}) async {
    _setLoading(true);

    try {
      debugPrint('Cargando todas las transferencias');

      // Usar método similar a getTransferencias pero con parámetros predeterminados
      final paginatedResponse =
          await _transferenciaRepository.getTransferencias(
        pageSize:
            100, // Ajustamos el tamaño de página para obtener más resultados
        sortBy: _ordenarPor,
        order: _orden,
        forceRefresh: forceRefresh,
      );

      _transferencias = paginatedResponse.items;
      _errorMessage = null;
      notifyListeners();

      debugPrint('Transferencias cargadas: ${_transferencias.length}');
      // Debug de los datos recibidos
      for (var t in _transferencias) {
        debugPrint('Transferencia #${t.id}:');
        debugPrint('- Estado: ${t.estado.nombre}');
        debugPrint('- Destino: ${t.nombreSucursalDestino}');
        debugPrint('- Origen: ${t.nombreSucursalOrigen}');
      }
    } catch (e) {
      _setError('Error al cargar transferencias: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Obtener detalle de una transferencia con productos completos
  Future<TransferenciaInventario> obtenerDetalleTransferencia(String id) async {
    try {
      debugPrint('Obteniendo detalle de transferencia #$id');

      final TransferenciaInventario transferencia =
          await _transferenciaRepository.getTransferencia(id);

      debugPrint('Detalle de transferencia cargado:');
      debugPrint('- ID: ${transferencia.id}');
      debugPrint('- Estado: ${transferencia.estado.nombre}');
      debugPrint('- Productos: ${transferencia.productos?.length ?? 0}');

      return transferencia;
    } catch (e) {
      _setError('Error al obtener detalle de transferencia: $e');
      rethrow;
    }
  }

  /// Carga y almacena el detalle de una transferencia específica
  Future<void> cargarDetalleTransferencia(String id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      debugPrint('Cargando detalle de transferencia #$id para la UI');

      final TransferenciaInventario transferencia =
          await _transferenciaRepository.getTransferencia(id);

      _detalleTransferenciaActual = transferencia;
      debugPrint('Detalle cargado correctamente');
      debugPrint('Productos: ${transferencia.productos?.length ?? 0}');
    } catch (e) {
      debugPrint('Error al cargar detalle de transferencia: $e');
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Obtener comparación de una transferencia
  Future<ComparacionTransferencia> obtenerComparacionTransferencia(
      String id) async {
    if (_sucursalId == null) {
      throw Exception('No se ha establecido la sucursal de origen');
    }

    try {
      debugPrint('Obteniendo comparación de transferencia #$id');

      final ComparacionTransferencia comparacion =
          await _transferenciaRepository.compararTransferencia(
        id: id,
        sucursalOrigenId: int.parse(_sucursalId!),
      );

      debugPrint('Comparación de transferencia cargada:');
      debugPrint('- Sucursal Origen: ${comparacion.sucursalOrigen.nombre}');
      debugPrint('- Sucursal Destino: ${comparacion.sucursalDestino.nombre}');
      debugPrint('- Productos: ${comparacion.productos.length}');
      debugPrint(
          '- Productos con stock bajo: ${comparacion.productosConStockBajo.length}');
      debugPrint(
          '- Todos los productos procesables: ${comparacion.todosProductosProcesables}');

      return comparacion;
    } catch (e) {
      _setError('Error al obtener comparación de transferencia: $e');
      rethrow;
    }
  }

  // Crear nueva transferencia sin cargar productos completos
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
      final items = productos
          .map((p) => <String, dynamic>{
                'productoId': p.id,
                'cantidad': p.cantidad,
              })
          .toList();

      final TransferenciaInventario nuevaTransferencia =
          await _transferenciaRepository.createTransferencia(
        sucursalDestinoId: sucursalDestinoId,
        items: items,
      );

      _transferencias.insert(0, nuevaTransferencia);
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

  // Agregar producto a la transferencia en proceso
  void agregarProducto(DetalleProducto producto) {
    if (_productosSeleccionados.any((p) => p.id == producto.id)) {
      _setError('El producto ya está en la lista');
      return;
    }

    _productosSeleccionados.add(producto);
    notifyListeners();
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

  // Validar recepción de una transferencia
  Future<void> validarRecepcion(TransferenciaInventario transferencia) async {
    _setLoading(true);

    try {
      await _transferenciaRepository.recibirTransferencia(
        transferencia.id.toString(),
      );

      await cargarTransferencias();
    } catch (e) {
      _setError('Error al validar recepción: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Enviar una transferencia
  Future<void> enviarTransferencia(
      TransferenciaInventario transferencia) async {
    _setLoading(true);

    try {
      if (_sucursalId == null) {
        throw Exception('No se pudo obtener el ID de la sucursal del usuario');
      }

      final int sucursalOrigenId = int.parse(_sucursalId!);

      await _transferenciaRepository.enviarTransferencia(
        transferencia.id.toString(),
        sucursalOrigenId: sucursalOrigenId,
      );

      await cargarTransferencias();
    } catch (e) {
      _setError('Error al enviar transferencia: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Cambiar filtro seleccionado
  Future<void> cambiarFiltro(String filtro) async {
    _selectedFilter = filtro;
    await cargarTransferencias();
  }

  // Filtrar transferencias por sucursal actual
  List<TransferenciaInventario> getTransferenciasFiltradas() {
    debugPrint('Filtrando transferencias...');
    debugPrint('Total transferencias: ${_transferencias.length}');
    debugPrint('Filtro seleccionado: $_selectedFilter');
    debugPrint('ID Sucursal: $_sucursalId');

    // Si no hay filtro de estado y no estamos en modo de filtrado por sucursal, mostrar todas
    if (_selectedFilter == 'Todos') {
      debugPrint('Retornando todas las transferencias sin filtrar');
      return _transferencias;
    }

    return _transferencias.where((t) {
      bool cumpleFiltroEstado = true;

      // Aplicar filtro por estado si está seleccionado
      if (_selectedFilter != 'Todos') {
        final EstadoTransferencia estadoFiltro =
            EstadoTransferencia.values.firstWhere(
          (e) => e.nombre == _selectedFilter,
          orElse: () => EstadoTransferencia.pedido,
        );
        cumpleFiltroEstado = t.estado == estadoFiltro;
      }

      final bool cumple = cumpleFiltroEstado;
      debugPrint(
          'Transferencia #${t.id}: ${cumple ? 'Incluida' : 'Excluida'} (Estado: ${t.estado.nombre})');
      return cumple;
    }).toList();
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
        return await _productoRepository.getProductosConStockBajo(
          sucursalId: sucursalId,
          page: page ?? 1,
          pageSize: pageSize ?? 20,
          sortBy: _ordenarPor,
          useCache: useCache,
        );
      }

      // Usar el método de filtro avanzado del repositorio
      return await _productoRepository.getProductos(
        sucursalId: sucursalId,
        page: page ?? 1,
        pageSize: pageSize ?? 20,
        sortBy: _ordenarPor,
        order: _orden,
        filterType: _filtroCategoria != 'Todos' ? 'categoria' : null,
        filterValue: _filtroCategoria != 'Todos' ? _filtroCategoria : null,
        stockBajo: _soloStockPositivo ? true : null,
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

      final response = await _productoRepository.getProductosConStockBajo(
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
      final response = await _productoRepository.getProductosAgotados(
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

      final response = await _productoRepository.buscarProductosPorNombre(
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

  // Obtener comparación de stocks entre sucursales
  Future<List<Map<String, dynamic>>> obtenerComparacionStocks(
    TransferenciaInventario transferencia,
  ) async {
    if (transferencia.productos == null ||
        transferencia.productos!.isEmpty ||
        _sucursalId == null) {
      return [];
    }

    try {
      final List<Map<String, dynamic>> comparaciones = [];

      for (final producto in transferencia.productos!) {
        // Obtener stock actual en nuestra sucursal
        final stockActual = await _productoRepository.getProducto(
          sucursalId: _sucursalId!,
          productoId: producto.id,
          useCache: false,
        );

        if (stockActual != null) {
          comparaciones.add({
            'producto': producto,
            'stockActual': stockActual.stock,
            'cantidadSolicitada': producto.cantidad,
          });
        }
      }

      return comparaciones;
    } catch (e) {
      _setError('Error al obtener comparación de stocks: $e');
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
