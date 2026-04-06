import 'package:collection/collection.dart';
import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/api/protected/clientes.api.dart';
import 'package:condorsmotors/api/protected/productos.api.dart';
import 'package:condorsmotors/api/protected/proforma.api.dart' as api_proforma;
import 'package:condorsmotors/models/cliente.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/proforma.model.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ventas.colab.riverpod.g.dart';

class VentasColabState {
  final bool isLoading;
  final String loadingMessage;
  final String sucursalId;
  final int empleadoId;

  final List<Producto> productos;
  final bool productosLoaded;
  final bool isLoadingProductos;
  final List<String> categorias;

  final List<Producto> productosVenta;
  final List<int> cantidades;
  final Cliente? clienteSeleccionado;

  final List<Cliente> clientes;
  final bool clientesLoaded;

  final String mensajePromocion;
  final String nombreProductoPromocion;

  const VentasColabState({
    this.isLoading = false,
    this.loadingMessage = '',
    this.sucursalId = '1',
    this.empleadoId = 1,
    this.productos = const <Producto>[],
    this.productosLoaded = false,
    this.isLoadingProductos = false,
    this.categorias = const <String>['Todas'],
    this.productosVenta = const <Producto>[],
    this.cantidades = const <int>[],
    this.clienteSeleccionado,
    this.clientes = const <Cliente>[],
    this.clientesLoaded = false,
    this.mensajePromocion = '',
    this.nombreProductoPromocion = '',
  });

  VentasColabState copyWith({
    bool? isLoading,
    String? loadingMessage,
    String? sucursalId,
    int? empleadoId,
    List<Producto>? productos,
    bool? productosLoaded,
    bool? isLoadingProductos,
    List<String>? categorias,
    List<Producto>? productosVenta,
    List<int>? cantidades,
    Cliente? clienteSeleccionado,
    bool nullifyCliente = false,
    List<Cliente>? clientes,
    bool? clientesLoaded,
    String? mensajePromocion,
    String? nombreProductoPromocion,
  }) {
    return VentasColabState(
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      sucursalId: sucursalId ?? this.sucursalId,
      empleadoId: empleadoId ?? this.empleadoId,
      productos: productos ?? this.productos,
      productosLoaded: productosLoaded ?? this.productosLoaded,
      isLoadingProductos: isLoadingProductos ?? this.isLoadingProductos,
      categorias: categorias ?? this.categorias,
      productosVenta: productosVenta ?? this.productosVenta,
      cantidades: cantidades ?? this.cantidades,
      clienteSeleccionado: nullifyCliente
          ? null
          : (clienteSeleccionado ?? this.clienteSeleccionado),
      clientes: clientes ?? this.clientes,
      clientesLoaded: clientesLoaded ?? this.clientesLoaded,
      mensajePromocion: mensajePromocion ?? this.mensajePromocion,
      nombreProductoPromocion:
          nombreProductoPromocion ?? this.nombreProductoPromocion,
    );
  }
}

@Riverpod(keepAlive: true)
class VentasColab extends _$VentasColab {
  // APIs
  final ProductosApi _productosApi = api.productos;
  final api_proforma.ProformaVentaApi _proformasApi = api.proformas;
  final ClientesApi _clientesApi = api.clientes;

  @override
  VentasColabState build() {
    return const VentasColabState();
  }

  void setLoading({required bool loading, String message = ''}) {
    state = state.copyWith(isLoading: loading, loadingMessage: message);
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
      String sucursalId = state.sucursalId;
      int empleadoId = state.empleadoId;

      if (userData != null && userData['sucursalId'] != null) {
        sucursalId = userData['sucursalId'].toString();

        // Determinar ID de empleado directamente desde userData
        if (userData['empleadoId'] != null) {
          empleadoId = int.tryParse(userData['empleadoId'].toString()) ?? 0;
        } else {
          // Si no hay empleadoId en userData, usar el ID del usuario como empleadoId
          if (userData['id'] != null) {
            empleadoId = int.tryParse(userData['id'].toString()) ?? 0;
          } else {
            empleadoId = 0; // Valor cero para que sea un error explícito
          }
        }
      } else {
      }

      state = state.copyWith(
        sucursalId: sucursalId,
        empleadoId: empleadoId,
      );
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
    if (state.productosLoaded) {
      return;
    }

    state = state.copyWith(isLoadingProductos: true);

    try {

      // Obtener productos con stock disponible usando el repositorio
      final response = await ProductoRepository.instance.getProductosPorFiltros(
        sucursalId: state.sucursalId,
        stockPositivo: true,
        pageSize: 100,
      );

      final productos = response.items;
      final categorias = <String>{'Todas', ...productos.map((p) => p.categoria)}
          .toList()
        ..sort();

      state = state.copyWith(
        productos: productos,
        productosLoaded: true,
        categorias: categorias,
        isLoadingProductos: false,
      );

    } catch (e) {
      debugPrint('Error al cargar productos: $e');
      state = state.copyWith(isLoadingProductos: false);
      throw Exception('Error al cargar productos: $e');
    }
  }

  /// Cargar clientes desde la API
  Future<void> cargarClientes() async {
    if (state.clientesLoaded) {
      return; // Evitar cargar múltiples veces
    }

    setLoading(loading: true, message: 'Cargando clientes...');

    try {

      // Obtener los clientes desde la API
      final List<Cliente> clientesData = await _clientesApi.getClientes(
        pageSize: 100, // Obtener más clientes por página
        sortBy: 'denominacion', // Ordenar por nombre
      );

      state = state.copyWith(
        clientes: clientesData,
        clientesLoaded: true,
      );
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
    for (int i = 0; i < state.productosVenta.length; i++) {
      final producto = state.productosVenta[i];
      final cantidad = state.cantidades[i];
      total += producto.getPrecioConDescuento(cantidad) * cantidad;
    }
    return total;
  }

  /// Agregar un producto a la venta actual
  bool agregarProducto(Producto producto) {
    final newProductosVenta = List<Producto>.from(state.productosVenta);
    final newCantidades = List<int>.from(state.cantidades);

    final index = newProductosVenta.indexWhere((p) => p.id == producto.id);
    if (index >= 0) {
      newCantidades[index]++;
    } else {
      newProductosVenta.add(producto);
      newCantidades.add(1);
    }

    state = state.copyWith(
      productosVenta: newProductosVenta,
      cantidades: newCantidades,
    );
    return true;
  }

  /// Eliminar un producto de la venta
  void eliminarProducto(int index) {
    final newProductosVenta = List<Producto>.from(state.productosVenta);
    final newCantidades = List<int>.from(state.cantidades);

    newProductosVenta.removeAt(index);
    newCantidades.removeAt(index);

    state = state.copyWith(
      productosVenta: newProductosVenta,
      cantidades: newCantidades,
    );
  }

  /// Cambiar la cantidad de un producto en la venta
  bool cambiarCantidad(int index, int nuevaCantidad) {
    if (index < 0 || index >= state.productosVenta.length) {
      return false;
    }

    final newProductosVenta = List<Producto>.from(state.productosVenta);
    final newCantidades = List<int>.from(state.cantidades);

    if (nuevaCantidad <= 0) {
      newProductosVenta.removeAt(index);
      newCantidades.removeAt(index);
    } else {
      newCantidades[index] = nuevaCantidad;
    }

    state = state.copyWith(
      productosVenta: newProductosVenta,
      cantidades: newCantidades,
    );
    return true;
  }

  /// Limpiar la venta actual
  void limpiarVenta() {
    state = state.copyWith(
      productosVenta: [],
      cantidades: [],
      nullifyCliente: true,
    );
  }

  /// Seleccionar un cliente para la venta
  void seleccionarCliente(Cliente cliente) {
    state = state.copyWith(clienteSeleccionado: cliente);
  }

  /// Crear un nuevo cliente
  Future<Cliente> crearCliente(Map<String, dynamic> clienteData) async {
    setLoading(loading: true, message: 'Creando cliente...');

    try {
      // Crear cliente en la API
      final Cliente nuevoCliente =
          await _clientesApi.createCliente(clienteData);

      // Actualizar la lista de clientes y seleccionar el nuevo cliente
      final newClientes = List<Cliente>.from(state.clientes)..add(nuevoCliente);

      state = state.copyWith(
        clientes: newClientes,
        clienteSeleccionado: nuevoCliente,
      );

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
    if (state.productosVenta.isEmpty) {
      return false;
    }

    setLoading(
        loading: true, message: 'Verificando disponibilidad de stock...');

    try {
      // Usar validaciones del modelo Producto
      final List<String> errors = Producto.validateProductsForSale(
          state.productosVenta, state.cantidades);
      if (errors.isNotEmpty) {
        setLoading(loading: false);
        debugPrint('Errores de validación de stock: ${errors.join(', ')}');
        return false;
      }

      // Verificar stock de cada producto (validación adicional con API)
      for (final Producto producto in state.productosVenta) {
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

        // Buscar indice
        final index =
            state.productosVenta.indexWhere((p) => p.id == producto.id);
        if (index < 0) {
          continue;
        }

        final int cantidad = state.cantidades[index];

        // Actualizar mensaje de loading
        setLoading(
            loading: true,
            message: 'Verificando stock de ${producto.nombre}...');

        // Obtener producto actualizado para verificar stock
        final Producto productoActual = await _productosApi.getProducto(
          sucursalId: state.sucursalId,
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
    if (state.productosVenta.isEmpty || state.clienteSeleccionado == null) {
      return null;
    }

    setLoading(loading: true, message: 'Enviando datos al servidor...');

    try {
      setLoading(loading: true, message: 'Preparando detalles de la venta...');

      // Convertir los productos de la venta al formato esperado por la API
      final List<api_proforma.DetalleProforma> detalles =
          state.productosVenta.map((Producto producto) {
        final index =
            state.productosVenta.indexWhere((p) => p.id == producto.id);
        final int cantidad = state.cantidades[index];
        final double precioUnitario = producto.getPrecioConDescuento(cantidad);
        final double subtotal = precioUnitario * cantidad;

        return api_proforma.DetalleProforma(
          productoId: producto.id,
          nombre: producto.nombre,
          cantidad: cantidad,
          subtotal: subtotal,
          precioUnitario: precioUnitario,
        );
      }).toList();

      setLoading(loading: true, message: 'Comunicando con el servidor...');

      // Llamar a la API para crear la proforma
      final Map<String, dynamic> respuesta =
          await _proformasApi.createProformaVenta(
        sucursalId: state.sucursalId,
        nombre: 'Proforma ${state.clienteSeleccionado!.denominacion}',
        total: totalVenta,
        detalles: detalles,
        empleadoId: state.empleadoId,
        clienteId: state.clienteSeleccionado!.id,
      );

      setLoading(loading: true, message: 'Procesando respuesta...');

      // Convertir la respuesta a un objeto estructurado
      final Proforma? proformaCreada =
          _proformasApi.parseProformaVenta(respuesta);

      // Recargar productos para reflejar el stock actualizado por el backend
      state = state.copyWith(productosLoaded: false);
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
    return state.productos.firstWhereOrNull((p) => p.sku == codigo);
  }

  /// Invalida el caché de clientes y recarga desde la API
  Future<void> invalidateClientesCache() async {
    state = state.copyWith(
      clientesLoaded: false,
      clientes: <Cliente>[],
    );
    await cargarClientes();
  }
}
