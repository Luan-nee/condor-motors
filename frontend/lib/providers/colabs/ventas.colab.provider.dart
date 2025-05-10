import 'package:collection/collection.dart';
import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/models/cliente.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/proforma.model.dart' hide DetalleProforma;
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:flutter/material.dart';

/// Provider para gestionar ventas en el módulo de colaboradores
///
/// REF: Ahora toda la lógica de productos usa List<Producto> (no Maps). La carga de productos se hace usando ProductoRepository.
class VentasColabProvider extends ChangeNotifier {
  // APIs
  final ProductosApi _productosApi = api.productos;
  final ProformaVentaApi _proformasApi = api.proformas;
  final ClientesApi _clientesApi = api.clientes;

  // Estado general
  bool _isLoading = false;
  String _loadingMessage = '';
  String _sucursalId = '1'; // Valor por defecto
  int _empleadoId = 1; // Valor por defecto

  // Estado para productos
  List<Producto> _productos = <Producto>[];
  bool _productosLoaded = false;
  bool _isLoadingProductos = false;
  List<String> _categorias = <String>['Todas'];

  // Estado para la venta actual
  final List<Producto> _productosVenta = <Producto>[];
  final List<int> _cantidades = <int>[];
  Cliente? _clienteSeleccionado;

  // Estado para clientes
  List<Cliente> _clientes = <Cliente>[];
  bool _clientesLoaded = false;

  // Estado para promociones
  final String _mensajePromocion = '';
  final String _nombreProductoPromocion = '';

  // Getters
  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;
  String get sucursalId => _sucursalId;
  int get empleadoId => _empleadoId;

  List<Producto> get productos => _productos;
  bool get productosLoaded => _productosLoaded;
  bool get isLoadingProductos => _isLoadingProductos;
  List<String> get categorias => _categorias;

  List<Producto> get productosVenta => _productosVenta;
  List<int> get cantidades => _cantidades;
  Cliente? get clienteSeleccionado => _clienteSeleccionado;

  List<Cliente> get clientes => _clientes;
  bool get clientesLoaded => _clientesLoaded;

  String get mensajePromocion => _mensajePromocion;
  String get nombreProductoPromocion => _nombreProductoPromocion;

  // Métodos para gestionar el estado
  void setLoading({required bool loading, String message = ''}) {
    _isLoading = loading;
    _loadingMessage = message;
    notifyListeners();
  }

  /// Inicializar datos básicos del provider
  Future<void> inicializar() async {
    setLoading(loading: true, message: 'Configurando datos iniciales...');
    await _configurarDatosIniciales();
    setLoading(loading: false);
  }

  /// Configurar datos iniciales del provider
  Future<void> _configurarDatosIniciales() async {
    try {
      // Obtener datos del usuario autenticado
      final Map<String, dynamic>? userData = await api.auth.getUserData();
      if (userData != null && userData['sucursalId'] != null) {
        _sucursalId = userData['sucursalId'].toString();
        debugPrint('Usando sucursal del usuario autenticado: $_sucursalId');

        // Determinar ID de empleado directamente desde userData
        if (userData['empleadoId'] != null) {
          _empleadoId = int.tryParse(userData['empleadoId'].toString()) ?? 0;
          debugPrint('Usando empleadoId del userData: $_empleadoId');
        } else {
          // Si no hay empleadoId en userData, usar el ID del usuario como empleadoId
          // Esta es la solución más segura sin depender de la API de empleados
          if (userData['id'] != null) {
            _empleadoId = int.tryParse(userData['id'].toString()) ?? 0;
            debugPrint('Usando id del usuario como empleadoId: $_empleadoId');
          } else {
            _empleadoId = 0; // Valor cero para que sea un error explícito
            debugPrint('No se pudo determinar el empleadoId, usando 0');
          }
        }
      } else {
        debugPrint(
            'No se pudo obtener la sucursal del usuario, usando fallback: $_sucursalId');
      }
    } catch (e) {
      debugPrint('Error al obtener datos del usuario: $e');
    } finally {
      // Cargar productos y clientes después de configurar la sucursal
      await Future.wait(<Future<void>>[
        cargarProductos(),
        cargarClientes(),
      ]);
    }
  }

  /// Cargar productos desde la API
  Future<void> cargarProductos() async {
    if (_productosLoaded) {
      return;
    }

    _isLoadingProductos = true;
    notifyListeners();

    try {
      debugPrint('Cargando productos para sucursal ID: $_sucursalId');

      // Obtener productos con stock disponible usando el repositorio
      final response = await ProductoRepository.instance.getProductosPorFiltros(
        sucursalId: _sucursalId,
        stockPositivo: true,
        pageSize: 100,
      );
      _productos = response.items;
      _productosLoaded = true;
      _categorias = <String>{'Todas', ..._productos.map((p) => p.categoria)}
          .toList()
        ..sort();
      _isLoadingProductos = false;
      notifyListeners();
      debugPrint('Productos cargados: ${_productos.length}');
      debugPrint('Categorías detectadas: ${_categorias.length}');
    } catch (e) {
      debugPrint('Error al cargar productos: $e');
      _isLoadingProductos = false;
      notifyListeners();
      throw Exception('Error al cargar productos: $e');
    }
  }

  /// Cargar clientes desde la API
  Future<void> cargarClientes() async {
    if (_clientesLoaded) {
      return; // Evitar cargar múltiples veces
    }

    setLoading(loading: true, message: 'Cargando clientes...');

    try {
      debugPrint('Cargando clientes desde la API...');

      // Obtener los clientes desde la API
      final List<Cliente> clientesData = await _clientesApi.getClientes(
        pageSize: 100, // Obtener más clientes por página
        sortBy: 'denominacion', // Ordenar por nombre
      );

      _clientes = clientesData;
      _clientesLoaded = true;
      debugPrint('Clientes cargados: ${_clientes.length}');
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar clientes: $e');
      throw Exception('Error al cargar clientes: $e');
    } finally {
      setLoading(loading: false);
    }
  }

  /// Calcular el total de la venta actual
  double get totalVenta {
    double total = 0;
    for (int i = 0; i < _productosVenta.length; i++) {
      final producto = _productosVenta[i];
      final cantidad = _cantidades[i];
      total += producto.getPrecioConDescuento(cantidad) * cantidad;
    }
    return total;
  }

  /// Agregar un producto a la venta actual
  bool agregarProducto(Producto producto) {
    final index = _productosVenta.indexWhere((p) => p.id == producto.id);
    if (index >= 0) {
      _cantidades[index]++;
    } else {
      _productosVenta.add(producto);
      _cantidades.add(1);
    }
    notifyListeners();
    return true;
  }

  /// Eliminar un producto de la venta
  void eliminarProducto(int index) {
    _productosVenta.removeAt(index);
    _cantidades.removeAt(index);
    notifyListeners();
  }

  /// Cambiar la cantidad de un producto en la venta
  bool cambiarCantidad(int index, int nuevaCantidad) {
    if (index < 0 || index >= _productosVenta.length) {
      return false;
    }
    if (nuevaCantidad <= 0) {
      _productosVenta.removeAt(index);
      _cantidades.removeAt(index);
    } else {
      _cantidades[index] = nuevaCantidad;
    }
    notifyListeners();
    return true;
  }

  /// Limpiar la venta actual
  void limpiarVenta() {
    _productosVenta.clear();
    _cantidades.clear();
    _clienteSeleccionado = null;
    notifyListeners();
  }

  /// Seleccionar un cliente para la venta
  void seleccionarCliente(Cliente cliente) {
    _clienteSeleccionado = cliente;
    notifyListeners();
  }

  /// Crear un nuevo cliente
  Future<Cliente> crearCliente(Map<String, dynamic> clienteData) async {
    setLoading(loading: true, message: 'Creando cliente...');

    try {
      // Crear cliente en la API
      final Cliente nuevoCliente =
          await _clientesApi.createCliente(clienteData);

      // Actualizar la lista de clientes y seleccionar el nuevo cliente
      _clientes.add(nuevoCliente);
      _clienteSeleccionado = nuevoCliente;
      notifyListeners();

      return nuevoCliente;
    } catch (e) {
      debugPrint('Error al crear cliente: $e');
      throw Exception('Error al crear cliente: $e');
    } finally {
      setLoading(loading: false);
    }
  }

  /// Verificar el stock de los productos antes de finalizar venta
  Future<bool> verificarStockProductos() async {
    if (_productosVenta.isEmpty) {
      return false;
    }

    setLoading(
        loading: true, message: 'Verificando disponibilidad de stock...');

    try {
      // Verificar stock de cada producto
      for (final Producto producto in _productosVenta) {
        // Validar ID de producto
        final dynamic productoIdDynamic = producto.id;
        int productoId;

        if (productoIdDynamic is int) {
          productoId = productoIdDynamic;
        } else if (productoIdDynamic is String) {
          productoId = int.parse(productoIdDynamic);
        } else {
          setLoading(loading: false);
          return false;
        }

        final int cantidad = _cantidades[productoId];

        // Actualizar mensaje de loading
        setLoading(
            loading: true,
            message: 'Verificando stock de ${producto.nombre}...');

        // Obtener producto actualizado para verificar stock
        final Producto productoActual = await _productosApi.getProducto(
          sucursalId: _sucursalId,
          productoId: productoId,
          useCache: false, // No usar caché para obtener datos actualizados
        );

        if (productoActual.stock < cantidad) {
          setLoading(loading: false);
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error al verificar stock: $e');
      return false;
    } finally {
      setLoading(loading: false);
    }
  }

  /// Crear proforma de venta
  Future<Proforma?> crearProformaVenta() async {
    // Validar que haya productos y cliente seleccionado
    if (_productosVenta.isEmpty || _clienteSeleccionado == null) {
      return null;
    }

    setLoading(loading: true, message: 'Enviando datos al servidor...');

    try {
      setLoading(loading: true, message: 'Preparando detalles de la venta...');

      // Convertir los productos de la venta al formato esperado por la API
      final List<DetalleProforma> detalles =
          _productosVenta.map((Producto producto) {
        final double precioUnitario =
            producto.getPrecioConDescuento(_cantidades[producto.id]);
        final double subtotal = precioUnitario * _cantidades[producto.id];

        return DetalleProforma(
          productoId: producto.id,
          nombre: producto.nombre,
          cantidad: _cantidades[producto.id],
          subtotal: subtotal,
          precioUnitario: precioUnitario,
        );
      }).toList();

      setLoading(loading: true, message: 'Comunicando con el servidor...');

      // Llamar a la API para crear la proforma
      final Map<String, dynamic> respuesta =
          await _proformasApi.createProformaVenta(
        sucursalId: _sucursalId,
        nombre: 'Proforma ${_clienteSeleccionado!.denominacion}',
        total: totalVenta,
        detalles: detalles,
        empleadoId: _empleadoId,
        clienteId: _clienteSeleccionado!.id,
      );

      setLoading(loading: true, message: 'Procesando respuesta...');

      // Convertir la respuesta a un objeto estructurado
      final Proforma? proformaCreada =
          _proformasApi.parseProformaVenta(respuesta);

      // Recargar productos para reflejar el stock actualizado por el backend
      _productosLoaded = false;
      await cargarProductos();

      return proformaCreada;
    } catch (e) {
      debugPrint('Error al crear la proforma: $e');
      throw Exception('Error al crear la proforma: $e');
    } finally {
      setLoading(loading: false);
    }
  }

  /// Buscar un producto por código de barras
  Producto? buscarProductoPorCodigo(String codigo) {
    return _productos.firstWhereOrNull((p) => p.sku == codigo);
  }

  /// Invalida el caché de clientes y recarga desde la API
  Future<void> invalidateClientesCache() async {
    _clientesLoaded = false;
    _clientes = <Cliente>[];
    await cargarClientes();
  }
}
