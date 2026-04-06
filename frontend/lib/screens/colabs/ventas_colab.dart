import 'package:condorsmotors/models/cliente.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/proforma.model.dart';
import 'package:condorsmotors/providers/colabs/ventas.colab.riverpod.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:condorsmotors/screens/colabs/barcode_colab.dart';
import 'package:condorsmotors/screens/colabs/ventas/producto_venta_item.widget.dart';
import 'package:condorsmotors/screens/colabs/widgets/busqueda_producto.dart';
import 'package:condorsmotors/screens/colabs/widgets/cliente/busqueda_cliente.dart';
import 'package:condorsmotors/screens/colabs/widgets/cliente/busqueda_cliente_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class VentasColabScreen extends ConsumerStatefulWidget {
  const VentasColabScreen({super.key});

  @override
  ConsumerState<VentasColabScreen> createState() => _VentasColabScreenState();
}

class _VentasColabScreenState extends ConsumerState<VentasColabScreen>
    with SingleTickerProviderStateMixin {
  // Variables para la animación de promoción
  late AnimationController _animationController;
  bool _mostrarMensajePromocion = false;
  String _nombreProductoPromocion = '';
  String _mensajePromocion = '';

  // Controladores para búsqueda
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _clienteSearchController =
      TextEditingController();

  // Accesos directos a propiedades del provider con manejo de nulos
  // Accesos directos a propiedades del provider con manejo de nulos
  List<Producto> get _productos => ref.watch(ventasColabProvider).productos;
  List<Producto> get _productosVenta =>
      ref.watch(ventasColabProvider).productosVenta;
  Cliente? get _clienteSeleccionado =>
      ref.watch(ventasColabProvider).clienteSeleccionado;
  bool get _isLoading => ref.watch(ventasColabProvider).isLoading;
  String get _loadingMessage => ref.watch(ventasColabProvider).loadingMessage;
  bool get _productosLoaded => ref.watch(ventasColabProvider).productosLoaded;
  String get _sucursalId => ref.watch(ventasColabProvider).sucursalId;
  double get _totalVenta => ref.watch(ventasColabProvider.notifier).totalVenta;
  // Los repositorios se acceden a través del provider

  @override
  void initState() {
    super.initState();

    // Inicializar el controlador de animación
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Programar la inicialización del provider después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(ventasColabProvider.notifier).inicializar();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _clienteSearchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Mostrar diálogo para seleccionar cliente
  void _mostrarDialogoClientes() {
    final notifier = ref.read(ventasColabProvider.notifier);
    final state = ref.watch(ventasColabProvider);
    // Asegurarse de que los clientes estén cargados
    if (!state.clientesLoaded) {
      notifier.cargarClientes();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.95,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Encabezado del diálogo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'Seleccionar Cliente',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 20, color: Colors.white70),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Widget de búsqueda de cliente
              Expanded(
                child: BusquedaClienteWidget(
                  clientes: state.clientes,
                  onClienteSeleccionado: (Cliente cliente) {
                    notifier.seleccionarCliente(cliente);
                    Navigator.pop(context);
                    // Mostrar mensaje de confirmación
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Cliente ${cliente.denominacion} seleccionado'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  onNuevoCliente: () {
                    Navigator.pop(context);
                    _mostrarDialogoNuevoCliente();
                  },
                  isLoading: state.isLoading && !state.clientesLoaded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mostrar diálogo para crear nuevo cliente
  void _mostrarDialogoNuevoCliente() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: BusquedaClienteForm(
            onClienteCreado: (Cliente nuevoCliente) {
              // Cerrar el diálogo actual
              Navigator.pop(dialogContext);

              // Seleccionar automáticamente el cliente recién creado
              ref
                  .read(ventasColabProvider.notifier)
                  .seleccionarCliente(nuevoCliente);

              // Mostrar mensaje de éxito
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Cliente ${nuevoCliente.denominacion} creado y seleccionado'),
                  backgroundColor: Colors.green,
                ),
              );

              // Mostrar el diálogo de selección de clientes
              _mostrarDialogoClientes();
            },
            onCancel: () => Navigator.pop(dialogContext),
          ),
        ),
      ),
    );
  }

  // Mostrar diálogo para buscar productos
  Future<void> _mostrarDialogoProductos() async {
    final notifier = ref.read(ventasColabProvider.notifier);
    final state = ref.read(ventasColabProvider);
    // Mostrar indicador de carga mientras se cargan los productos
    if (!state.productosLoaded) {
      notifier.setLoading(loading: true, message: 'Cargando productos...');
      try {
        await notifier.cargarProductos();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cargar productos: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      } finally {
        if (mounted) {
          notifier.setLoading(loading: false);
        }
      }
    }

    if (!mounted) {
      return;
    }

    final stateUpdated = ref.read(ventasColabProvider);
    // Verificar que tengamos productos para mostrar
    if (stateUpdated.productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay productos disponibles'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }


    await showDialog(
      context: context,
      builder: (BuildContext context) {
        // En un showDialog es probable que tengamos que usar Consumer o pasar el state si no cambia
        // Usaremos el state capturado al inicio
        return Consumer(builder: (context, ref, _) {
          final dialogState = ref.watch(ventasColabProvider);
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.95,
              height: MediaQuery.of(context).size.height * 0.95,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Buscar Producto',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: BusquedaProductoWidget(
                      productos: dialogState.productos,
                      categorias: dialogState.categorias,
                      isLoading: dialogState.isLoadingProductos,
                      sucursalId: dialogState.sucursalId,
                      onProductoSeleccionado: (Producto producto) {
                        _mostrarDetallesPromocion(producto);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // Mostrar detalles de promoción
  void _mostrarDetallesPromocion(Producto producto) {
    Navigator.pop(context); // Cerrar diálogo de búsqueda
    _agregarProductoConVerificacion(producto);
  }

  // Nuevo método para verificar y agregar producto
  void _agregarProductoConVerificacion(Producto producto) {

    // Verificar stock disponible
    final int stockDisponible = producto.stock;
    if (stockDisponible <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${producto.nombre} no tiene stock disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Intentar agregar el producto
    final bool resultado = _agregarProducto(producto);

    if (resultado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${producto.nombre} agregado al carrito'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al agregar el producto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Métodos para delegar al provider
  bool _agregarProducto(Producto producto) {
    final notifier = ref.read(ventasColabProvider.notifier);
    final resultado = notifier.agregarProducto(producto);
    final state = ref.read(ventasColabProvider);
    // Mostrar mensaje de promoción si existe
    if (resultado && state.mensajePromocion.isNotEmpty) {
      _mostrarMensajePromocionConAnimacion(
        state.nombreProductoPromocion,
        state.mensajePromocion,
      );
    }
    return resultado;
  }

  // Método para mostrar el mensaje de promoción con animación
  void _mostrarMensajePromocionConAnimacion(
      String nombreProducto, String mensaje) {
    setState(() {
      _nombreProductoPromocion = nombreProducto;
      _mensajePromocion = mensaje;
      _mostrarMensajePromocion = true;
    });

    // Animar la entrada
    _animationController.forward().then((_) {
      // Esperar un momento antes de comenzar a desvanecer
      Future<void>.delayed(const Duration(seconds: 2), () {
        // Asegurarse de que el widget aún está montado antes de animar
        if (mounted) {
          // Animar la salida
          _animationController.reverse().then((_) {
            if (mounted) {
              setState(() {
                _mostrarMensajePromocion = false;
              });
            }
          });
        }
      });
    });
  }

  // Método para finalizar venta (verificar stock y crear proforma)
  Future<void> _finalizarVenta() async {

    // Validar que haya productos y cliente seleccionado
    if (_productosVenta.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay productos en la venta'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar un cliente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar stock antes de finalizar
    try {
      final notifier = ref.read(ventasColabProvider.notifier)
      ..setLoading(
          loading: true, message: 'Verificando disponibilidad de stock...');

      // Verificar stock de cada producto
      for (int i = 0; i < _productosVenta.length; i++) {
        final producto = _productosVenta[i];
        final cantidad = ref.read(ventasColabProvider).cantidades[i];
        // Validar ID de producto
        final int productoId = producto.id;
        // Actualizar mensaje de loading
        if (mounted) {
          notifier.setLoading(
              loading: true,
              message: 'Verificando stock de ${producto.nombre}...');
        }
        // Obtener producto actualizado para verificar stock
        final Producto? productoActual =
            await ProductoRepository.instance.getProducto(
          sucursalId: _sucursalId,
          productoId: productoId,
          useCache: false,
        );

        if (productoActual == null) {
          notifier.setLoading(loading: false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Producto no encontrado'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        if (!mounted) {
          return;
        }
        if (productoActual.stock < cantidad) {
          notifier.setLoading(loading: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Stock insuficiente para ${productoActual.nombre}. Disponible: ${productoActual.stock}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Si hay stock suficiente, crear la proforma
      await _crearProformaVenta();
    } catch (e) {
      debugPrint('Error al verificar stock: $e');

      if (mounted) {
        ref.read(ventasColabProvider.notifier).setLoading(loading: false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al verificar disponibilidad de productos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Método para crear proforma de venta
  Future<void> _crearProformaVenta() async {

    final notifier = ref.read(ventasColabProvider.notifier)

    // Mostrar indicador de carga con más contexto para reducir ansiedad
    ..setLoading(
        loading: true, message: 'Enviando datos al servidor...');

    try {
      // Actualizar mensaje para proporcionar retroalimentación del progreso
      if (mounted) {
        notifier.setLoading(
            loading: true, message: 'Preparando detalles de la venta...');
      }

      // Los detalles se manejan internamente en el provider

      // Actualizar mensaje para proporcionar retroalimentación del progreso
      if (mounted) {
        notifier.setLoading(
            loading: true, message: 'Comunicando con el servidor...');
      }

      // Crear proforma a través del provider (arquitectura correcta)
      final Proforma? proformaCreada = await notifier.crearProformaVenta();

      if (!mounted) {
        return;
      }

      // Recargar productos para reflejar el stock actualizado por el backend
      notifier.cargarProductos();

      if (mounted) {
        notifier.setLoading(
            loading: true, message: 'Actualizando inventario...');
      }

      if (!mounted) {
        return;
      }

      // Cambiar estado antes de mostrar el diálogo
      notifier.setLoading(loading: false);

      // Mostrar diálogo de confirmación
      await showDialog(
        context: context,
        barrierDismissible: false, // No permitir cerrar haciendo clic fuera
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('Proforma Creada Exitosamente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const FaIcon(
                FontAwesomeIcons.fileInvoiceDollar,
                color: Color(0xFF4CAF50),
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Total: S/ ${_totalVenta.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Cliente: ${_clienteSeleccionado!.denominacion}'),
              if (proformaCreada != null) ...<Widget>[
                const SizedBox(height: 8),
                Text('Proforma ID: ${proformaCreada.id}'),
              ],
              const SizedBox(height: 16),
              const Text(
                'La proforma ha sido creada y podrá ser procesada en caja.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Nota: Los descuentos y promociones serán aplicados automáticamente por el servidor.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                notifier
                    .limpiarVenta(); // Limpiar el carrito usando el provider

                // Mostrar mensaje de éxito
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Venta finalizada exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error al crear la proforma: $e');

      if (!mounted) {
        return;
      }

      // Resetear estado de carga
      notifier.setLoading(loading: false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear la proforma: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Mostrar overlay de carga para operaciones asíncronas
  Widget _buildLoadingOverlay(Widget child) {
    return Stack(
      children: <Widget>[
        child,
        if (_isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.7),
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Card(
                color: const Color(0xFF2D2D2D),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(),
                      ),
                      const SizedBox(height: 24),
                      if (_loadingMessage.isNotEmpty)
                        Column(
                          children: <Widget>[
                            Text(
                              _loadingMessage,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Por favor espere...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Escanear producto con código de barras
  Future<void> _escanearProducto() async {
    final notifier = ref.read(ventasColabProvider.notifier);
    // Asegurarse de que los productos estén cargados
    if (!_productosLoaded) {
      notifier.setLoading(loading: true, message: 'Cargando productos...');
      try {
        await _cargarProductos();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cargar productos: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      } finally {
        if (mounted) {
          notifier.setLoading(loading: false);
        }
      }
    }

    if (!mounted) {
      return;
    }

    // Navegar a la pantalla de escaneo con los productos
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => BarcodeColabScreen(
          productos: _productos,
          onProductoSeleccionado: (Producto producto) {
            _agregarProductoConVerificacion(producto);
          },
          isLoading: _isLoading,
        ),
      ),
    );
  }

  void _eliminarProducto(int index) {
    if (index < 0) {
      return;
    }
    ref.read(ventasColabProvider.notifier).eliminarProducto(index);
  }

  bool _cambiarCantidad(int index, int cantidad) {
    final notifier = ref.read(ventasColabProvider.notifier);
    final resultado = notifier.cambiarCantidad(index, cantidad);
    final state = ref.read(ventasColabProvider);
    if (state.mensajePromocion.isNotEmpty) {
      _mostrarMensajePromocionConAnimacion(
        state.nombreProductoPromocion,
        state.mensajePromocion,
      );
    }
    return resultado;
  }

  Future<void> _cargarProductos() async {
    await ref.read(ventasColabProvider.notifier).cargarProductos();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ventasColabProvider);
    final notifier = ref.read(ventasColabProvider.notifier);


    return _buildLoadingOverlay(
      Scaffold(
        appBar: AppBar(
          title: const Text('Ventas'),
        ),
        body: Column(
          children: <Widget>[
            // Sección de cliente
            Card(
              margin: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: <Widget>[
                    // Icono o avatar del cliente
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: state.clienteSeleccionado != null
                            ? const Color(0xFF1976D2).withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: FaIcon(
                          state.clienteSeleccionado != null
                              ? FontAwesomeIcons.userCheck
                              : FontAwesomeIcons.userPlus,
                          size: 16,
                          color: state.clienteSeleccionado != null
                              ? const Color(0xFF1976D2)
                              : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Información del cliente
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            state.clienteSeleccionado?.denominacion ??
                                'Seleccionar Cliente',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: state.clienteSeleccionado != null
                                  ? const Color.fromARGB(221, 255, 255, 255)
                                  : Colors.grey,
                            ),
                          ),
                          if (state.clienteSeleccionado != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: <Widget>[
                                const FaIcon(
                                  FontAwesomeIcons.idCard,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  state.clienteSeleccionado!.numeroDocumento,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                                if (state.clienteSeleccionado!.telefono !=
                                        null &&
                                    state.clienteSeleccionado!.telefono!
                                        .isNotEmpty) ...[
                                  const SizedBox(width: 16),
                                  const FaIcon(
                                    FontAwesomeIcons.phone,
                                    size: 12,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    state.clienteSeleccionado!.telefono!,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Botón para cambiar cliente
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _mostrarDialogoClientes,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                state.clienteSeleccionado != null
                                    ? 'Cambiar'
                                    : 'Seleccionar',
                                style: TextStyle(
                                  color: state.clienteSeleccionado != null
                                      ? const Color(0xFF1976D2)
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              FaIcon(
                                state.clienteSeleccionado != null
                                    ? FontAwesomeIcons.penToSquare
                                    : FontAwesomeIcons.chevronRight,
                                size: 14,
                                color: state.clienteSeleccionado != null
                                    ? const Color(0xFF1976D2)
                                    : Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botones de acción (escanear y buscar)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A1B9A), // Morado
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const FaIcon(FontAwesomeIcons.barcode),
                      label: const Text('Escanear'),
                      onPressed: _escanearProducto,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2), // Azul
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const FaIcon(FontAwesomeIcons.magnifyingGlass),
                      label: const Text('Buscar Productos'),
                      onPressed: _mostrarDialogoProductos,
                    ),
                  ),
                ],
              ),
            ),

            // Contenido principal (lista de productos)
            Expanded(
              child: Stack(
                children: <Widget>[
                  if (state.productosVenta.isEmpty)
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          FaIcon(
                            FontAwesomeIcons.cartShopping,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No hay productos en el carrito',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Busca o escanea productos para agregarlos',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      padding: const EdgeInsets.only(
                          bottom: 100), // Espacio para el botón de finalizar
                      itemCount: state.productosVenta.length,
                      itemBuilder: (BuildContext context, int index) {
                        final producto = state.productosVenta[index];
                        final cantidad = state.cantidades[index];
                        return ProductoVentaItemWidget(
                          producto: producto,
                          cantidad: cantidad,
                          onEliminar: () => _eliminarProducto(index),
                          onCambiarCantidad: (nuevaCantidad) {
                            _cambiarCantidad(index, nuevaCantidad);
                          },
                        );
                      },
                    ),

                  // Mensaje de promoción animado
                  if (_mostrarMensajePromocion)
                    Positioned(
                      bottom: 75,
                      left: 0,
                      right: 0,
                      child: FadeTransition(
                        opacity: _animationController,
                        child: Center(
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xFF2E7D32), // Verde oscuro
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    _nombreProductoPromocion,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _mensajePromocion,
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Barra inferior con total y botón de finalizar
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Información del total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 0, 0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            const Text(
                              'TOTAL',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'S/ ${notifier.totalVenta.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Botones de acción
                  Row(
                    children: <Widget>[
                      // Botón para limpiar la venta
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF424242),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const FaIcon(FontAwesomeIcons.trash, size: 16),
                          label: const Text('Limpiar'),
                          onPressed: state.productosVenta.isEmpty
                              ? null
                              : () {
                                  notifier.limpiarVenta();
                                  debugPrint('Carrito limpiado');
                                },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Botón para finalizar venta
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const FaIcon(FontAwesomeIcons.check, size: 16),
                          label: const Text('Finalizar Venta'),
                          onPressed: state.productosVenta.isEmpty ||
                                  state.clienteSeleccionado == null
                              ? null
                              : _finalizarVenta,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
