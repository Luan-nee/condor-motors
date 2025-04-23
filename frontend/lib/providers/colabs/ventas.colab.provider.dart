import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/models/cliente.model.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/proforma.model.dart' hide DetalleProforma;
import 'package:flutter/material.dart';

/// Provider para gestionar ventas en el módulo de colaboradores
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
  List<Map<String, dynamic>> _productos = <Map<String, dynamic>>[];
  bool _productosLoaded = false;
  bool _isLoadingProductos = false;
  List<String> _categorias = <String>['Todas'];

  // Estado para la venta actual
  final List<Map<String, dynamic>> _productosVenta = <Map<String, dynamic>>[];
  Cliente? _clienteSeleccionado;

  // Estado para clientes
  List<Cliente> _clientes = <Cliente>[];
  bool _clientesLoaded = false;

  // Estado para promociones
  String _mensajePromocion = '';
  String _nombreProductoPromocion = '';

  // Getters
  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;
  String get sucursalId => _sucursalId;
  int get empleadoId => _empleadoId;

  List<Map<String, dynamic>> get productos => _productos;
  bool get productosLoaded => _productosLoaded;
  bool get isLoadingProductos => _isLoadingProductos;
  List<String> get categorias => _categorias;

  List<Map<String, dynamic>> get productosVenta => _productosVenta;
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
      final Map<String, dynamic>? userData = await api.getUserData();
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

      // Obtener productos con stock disponible
      final PaginatedResponse<Producto> response =
          await _productosApi.getProductosPorFiltros(
        sucursalId: _sucursalId,
        stockPositivo: true,
        pageSize: 100,
      );

      // Extraer categorías únicas para el filtro
      final Set<String> categoriasUnicas = <String>{'Todas'};

      // Lista para almacenar los productos formateados
      final List<Map<String, dynamic>> productosFormateados =
          <Map<String, dynamic>>[];

      // Procesar la lista de productos obtenida
      for (final Producto producto in response.items) {
        // Agregar categoría a la lista de categorías únicas
        categoriasUnicas.add(producto.categoria);

        // Verificar el tipo de promoción que tiene el producto
        final bool tienePromocionGratis =
            producto.cantidadGratisDescuento != null &&
                producto.cantidadGratisDescuento! > 0;

        final bool tieneDescuentoPorcentual =
            producto.porcentajeDescuento != null &&
                producto.porcentajeDescuento! > 0 &&
                producto.cantidadMinimaDescuento != null &&
                producto.cantidadMinimaDescuento! > 0;

        // Formatear el producto para la interfaz
        productosFormateados.add(<String, dynamic>{
          'id': producto.id,
          'nombre': producto.nombre,
          'descripcion': producto.descripcion ?? '',
          'categoria': producto.categoria,
          'precio': producto.precioVenta,
          'precioCompra': producto.precioCompra,
          'stock': producto.stock,
          'stockMinimo': producto.stockMinimo,
          'stockBajo': producto.stockBajo,
          'sku': producto.sku,
          'codigo': producto.sku, // Duplicado para compatibilidad
          'marca': producto.marca,

          // Campos para liquidación
          'enLiquidacion': producto.liquidacion,
          'precioLiquidacion': producto.precioOferta,

          // Campos para promoción "Lleva X, Paga Y"
          'tienePromocionGratis': tienePromocionGratis,
          'cantidadMinima': producto.cantidadMinimaDescuento,
          'cantidadGratis': producto.cantidadGratisDescuento,

          // Campos para promoción de descuento porcentual
          'tieneDescuentoPorcentual': tieneDescuentoPorcentual,
          'descuentoPorcentaje': producto.porcentajeDescuento,

          // Para cálculos de descuento
          'precioOriginal': producto.precioVenta,

          // Tener en un solo campo si hay alguna promoción
          'tienePromocion': producto.liquidacion ||
              tienePromocionGratis ||
              tieneDescuentoPorcentual,
        });
      }

      // Actualizar el estado
      _productos = productosFormateados;
      _productosLoaded = true;
      _categorias = categoriasUnicas.toList()..sort();
      _isLoadingProductos = false;
      notifyListeners();

      debugPrint('Productos cargados: ${_productos.length}');
      debugPrint('Categorías detectadas: ${_categorias.length}');

      // Debug de promociones
      final int productosLiquidacion =
          productosFormateados.where((p) => p['enLiquidacion'] == true).length;
      final int productosPromoGratis = productosFormateados
          .where((p) => p['tienePromocionGratis'] == true)
          .length;
      final int productosDescuentoPorcentual = productosFormateados
          .where((p) => p['tieneDescuentoPorcentual'] == true)
          .length;

      debugPrint('Detalle de promociones:');
      debugPrint('- Productos en liquidación: $productosLiquidacion');
      debugPrint('- Productos con promo "Lleva y Paga": $productosPromoGratis');
      debugPrint(
          '- Productos con descuento porcentual: $productosDescuentoPorcentual');
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
    debugPrint('💰 Calculando total de venta...');
    double total = 0;

    for (final Map<String, dynamic> producto in _productosVenta) {
      final int cantidad = producto['cantidad'] ?? 0;

      // Obtener el precio correcto según las promociones
      double precioUnitario = producto['precioVenta'] ?? 0.0;

      if (precioUnitario == 0) {
        // Si no hay precioVenta, intentar obtener el precio según la liquidación
        if (producto['enLiquidacion'] == true &&
            producto['precioLiquidacion'] != null) {
          precioUnitario = (producto['precioLiquidacion'] as num).toDouble();
        } else {
          precioUnitario = (producto['precio'] as num?)?.toDouble() ?? 0.0;
        }
      }

      final double subtotal = precioUnitario * cantidad;
      debugPrint('📊 Producto: ${producto['nombre']}');
      debugPrint('   Cantidad: $cantidad');
      debugPrint('   Precio unitario: S/ ${precioUnitario.toStringAsFixed(2)}');
      debugPrint('   Subtotal: S/ ${subtotal.toStringAsFixed(2)}');

      total += subtotal;
    }

    debugPrint('💰 Total calculado: S/ ${total.toStringAsFixed(2)}');
    return total;
  }

  /// Agregar un producto a la venta actual
  bool agregarProducto(Map<String, dynamic> producto) {
    debugPrint(
        '🛒 Provider: Iniciando agregar producto: ${producto['nombre']}');

    // Verificar disponibilidad de stock
    final int stockDisponible = producto['stock'] ?? 0;
    debugPrint('📦 Stock disponible: $stockDisponible');

    if (stockDisponible <= 0) {
      debugPrint('❌ Sin stock disponible');
      return false;
    }

    // Determinar el precio correcto según si está en liquidación o no
    final bool enLiquidacion = producto['enLiquidacion'] ?? false;
    final double precioFinal =
        enLiquidacion && producto['precioLiquidacion'] != null
            ? (producto['precioLiquidacion'] as num).toDouble()
            : (producto['precio'] as num).toDouble();

    debugPrint('💰 Precio final calculado: $precioFinal');

    // Verificar si el producto ya está en la venta
    final int index = _productosVenta
        .indexWhere((Map<String, dynamic> p) => p['id'] == producto['id']);

    debugPrint('🔍 Producto en carrito: ${index >= 0 ? 'Sí' : 'No'}');

    try {
      if (index >= 0) {
        // Si ya existe, verificar que no exceda el stock disponible
        final int cantidadActual = _productosVenta[index]['cantidad'];
        debugPrint('📊 Cantidad actual: $cantidadActual');

        if (cantidadActual < stockDisponible) {
          // Solo incrementar si hay stock suficiente
          _productosVenta[index]['cantidad']++;
          debugPrint(
              '✅ Cantidad incrementada a: ${_productosVenta[index]['cantidad']}');

          // Aplicar descuentos basados en la nueva cantidad
          _aplicarDescuentosPorCantidad(index);
          notifyListeners();
          debugPrint(
              '📢 Estado actualizado - Total productos en carrito: ${_productosVenta.length}');
          return true;
        } else {
          debugPrint('❌ No hay suficiente stock para incrementar');
          return false;
        }
      } else {
        // Si no existe, agregarlo con cantidad 1
        final Map<String, dynamic> nuevoProducto = <String, dynamic>{
          ...producto,
          'cantidad': 1,
          'stockDisponible': stockDisponible,
          'precioVenta': precioFinal,
        };

        _productosVenta.add(nuevoProducto);
        debugPrint('✅ Nuevo producto agregado al carrito');

        // Aplicar descuentos si corresponde (para cantidad 1)
        final int nuevoIndex = _productosVenta.length - 1;
        _aplicarDescuentosPorCantidad(nuevoIndex);

        debugPrint(
            '📢 Estado actualizado - Total productos en carrito: ${_productosVenta.length}');
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('🚨 Error al agregar producto: $e');
      return false;
    }
  }

  /// Eliminar un producto de la venta
  void eliminarProducto(int index) {
    _productosVenta.removeAt(index);
    notifyListeners();
  }

  /// Cambiar la cantidad de un producto en la venta
  bool cambiarCantidad(int index, int cantidad) {
    if (cantidad <= 0) {
      eliminarProducto(index);
      return true;
    }

    // Verificar que la nueva cantidad no exceda el stock disponible
    final int stockDisponible = _productosVenta[index]['stockDisponible'] ??
        _productosVenta[index]['stock'] ??
        0;

    if (cantidad > stockDisponible) {
      // Si la cantidad excede el stock, limitar al máximo disponible
      _productosVenta[index]['cantidad'] = stockDisponible;
      notifyListeners();
      return false;
    }

    _productosVenta[index]['cantidad'] = cantidad;

    // Reiniciar el estado de promociones si la cantidad cambió
    final Map<String, dynamic> producto = _productosVenta[index];
    final bool tienePromocionGratis = producto['tienePromocionGratis'] ?? false;
    final int cantidadMinima = producto['cantidadMinima'] ?? 0;

    // Si tiene promoción de regalo y la cantidad está por debajo del mínimo, resetear el estado
    if (tienePromocionGratis &&
        cantidadMinima > 0 &&
        cantidad < cantidadMinima) {
      producto['promocionActivada'] = false;
    }

    // Calcular y aplicar descuentos según la cantidad (si corresponde)
    _aplicarDescuentosPorCantidad(index);
    notifyListeners();
    return true;
  }

  /// Método para calcular y aplicar descuentos basados en la cantidad
  void _aplicarDescuentosPorCantidad(int index) {
    final Map<String, dynamic> producto = _productosVenta[index];
    final int cantidad = producto['cantidad'];

    // Precio base del producto (sin descuentos)
    final double precioBase = (producto['precio'] as num).toDouble();
    double precioFinal = precioBase;

    // Flag para saber si se aplicó algún descuento
    bool descuentoAplicado = false;
    String mensajeDescuento = '';

    // Verificar si está en liquidación
    final bool enLiquidacion = producto['enLiquidacion'] ?? false;
    if (enLiquidacion && producto['precioLiquidacion'] != null) {
      final double precioLiquidacion =
          (producto['precioLiquidacion'] as num).toDouble();
      // Usar el precio de liquidación
      precioFinal = precioLiquidacion;
      descuentoAplicado = true;
      mensajeDescuento = 'Precio de liquidación aplicado';
    }

    // Verificar si tiene promoción de unidades gratis (solo para información visual)
    final bool tienePromocionGratis = producto['tienePromocionGratis'] ?? false;
    if (tienePromocionGratis) {
      final int cantidadMinima = producto['cantidadMinima'] ?? 0;
      final int cantidadGratis = producto['cantidadGratis'] ?? 0;

      if (cantidad >= cantidadMinima &&
          cantidadMinima > 0 &&
          cantidadGratis > 0) {
        // Solo marcar como que la promoción está activada para visualización
        producto['promocionActivada'] = true;

        // Solo actualizar el mensaje si no hay otro descuento aplicado o es más relevante
        if (!descuentoAplicado) {
          final int promocionesCompletas = cantidad ~/ cantidadMinima;
          final int unidadesGratis = promocionesCompletas * cantidadGratis;
          mensajeDescuento =
              '$unidadesGratis unidades gratis serán incluidas por el servidor';
          descuentoAplicado = true;
        }
      } else {
        // Si ya no cumple con la cantidad mínima, desactivar la promoción
        producto['promocionActivada'] = false;
      }
    }

    // Verificar si tiene descuento porcentual (solo para información visual)
    final bool tieneDescuentoPorcentual =
        producto['tieneDescuentoPorcentual'] ?? false;
    if (tieneDescuentoPorcentual && !descuentoAplicado) {
      final int cantidadMinima = producto['cantidadMinima'] ?? 0;
      final int porcentaje = producto['descuentoPorcentaje'] ?? 0;

      if (cantidad >= cantidadMinima && cantidadMinima > 0 && porcentaje > 0) {
        // El server aplicará este descuento, solo mostrar el mensaje
        mensajeDescuento =
            '$porcentaje% de descuento será aplicado por el servidor';
        descuentoAplicado = true;
      }
    }

    // Actualizar el precio de venta y el mensaje de descuento
    _productosVenta[index]['precioVenta'] = precioFinal;
    _productosVenta[index]['descuentoAplicado'] = descuentoAplicado;
    _productosVenta[index]['mensajeDescuento'] = mensajeDescuento;

    // Actualizar mensaje de promoción
    if (descuentoAplicado && mensajeDescuento.isNotEmpty) {
      _mensajePromocion = mensajeDescuento;
      _nombreProductoPromocion = producto['nombre'];
      notifyListeners();
    }
  }

  /// Limpiar la venta actual
  void limpiarVenta() {
    _productosVenta.clear();
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
      for (final Map<String, dynamic> producto in _productosVenta) {
        // Validar ID de producto
        final dynamic productoIdDynamic = producto['id'];
        int productoId;

        if (productoIdDynamic is int) {
          productoId = productoIdDynamic;
        } else if (productoIdDynamic is String) {
          productoId = int.parse(productoIdDynamic);
        } else {
          setLoading(loading: false);
          return false;
        }

        final int cantidad = producto['cantidad'];

        // Actualizar mensaje de loading
        setLoading(
            loading: true,
            message: 'Verificando stock de ${producto['nombre']}...');

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
          _productosVenta.map((Map<String, dynamic> producto) {
        // Manejar caso donde id puede ser entero o cadena
        final int productoId = producto['id'] is int
            ? producto['id']
            : int.parse(producto['id'].toString());

        // Usar el precio con descuentos aplicados si existe
        final double precioUnitario = producto['precioVenta'] ??
            (producto['enLiquidacion'] == true &&
                    producto['precioLiquidacion'] != null
                ? (producto['precioLiquidacion'] as num).toDouble()
                : (producto['precio'] as num).toDouble());

        final double subtotal = precioUnitario * producto['cantidad'];

        return DetalleProforma(
          productoId: productoId,
          nombre: producto['nombre'],
          cantidad: producto['cantidad'],
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
  Map<String, dynamic> buscarProductoPorCodigo(String codigo) {
    try {
      // Buscar el producto por código de barras en la lista de productos
      return _productos.firstWhere(
        (p) => p['codigo'] == codigo,
        orElse: () => <String, dynamic>{},
      );
    } catch (e) {
      debugPrint('Error al buscar producto por código: $e');
      return <String, dynamic>{};
    }
  }

  /// Invalida el caché de clientes y recarga desde la API
  Future<void> invalidateClientesCache() async {
    _clientesLoaded = false;
    _clientes = <Cliente>[];
    await cargarClientes();
  }
}
