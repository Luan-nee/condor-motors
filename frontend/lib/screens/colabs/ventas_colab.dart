import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/cliente.model.dart'; // Importamos el modelo de Cliente
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/proforma.model.dart' hide DetalleProforma;
import 'package:condorsmotors/providers/colabs/ventas.colab.provider.dart';
import 'package:condorsmotors/screens/colabs/barcode_colab.dart';
import 'package:condorsmotors/screens/colabs/widgets/busqueda_producto.dart';
import 'package:condorsmotors/screens/colabs/widgets/busqueda_cliente.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class VentasColabScreen extends StatefulWidget {
  const VentasColabScreen({super.key});

  @override
  State<VentasColabScreen> createState() => _VentasColabScreenState();
}

class _VentasColabScreenState extends State<VentasColabScreen>
    with SingleTickerProviderStateMixin {
  late final VentasColabProvider _provider;

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
  List<Map<String, dynamic>> get _productos => _provider.productos;
  List<Map<String, dynamic>> get _productosVenta => _provider.productosVenta;
  Cliente? get _clienteSeleccionado => _provider.clienteSeleccionado;
  bool get _isLoading => _provider.isLoading;
  String get _loadingMessage => _provider.loadingMessage;
  bool get _productosLoaded => _provider.productosLoaded;
  String get _sucursalId => _provider.sucursalId;
  double get _totalVenta => _provider.totalVenta;
  int get _empleadoId => _provider.empleadoId;
  ProductosApi get _productosApi => api.productos;
  ProformaVentaApi get _proformasApi => api.proformas;

  @override
  void initState() {
    super.initState();

    // Inicializar el provider inmediatamente
    _provider = Provider.of<VentasColabProvider>(context, listen: false);

    // Inicializar el controlador de animación
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Programar la inicialización del provider después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _provider.inicializar();
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
    // Asegurarse de que los clientes estén cargados
    if (!_provider.clientesLoaded) {
      _provider.cargarClientes();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: EdgeInsets.symmetric(
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
                  clientes: _provider.clientes,
                  onClienteSeleccionado: (Cliente cliente) {
                    _provider.seleccionarCliente(cliente);
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
                  isLoading: _provider.isLoading && !_provider.clientesLoaded,
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
    final TextEditingController denominacionController =
        TextEditingController();
    final TextEditingController numeroDocumentoController =
        TextEditingController();
    final TextEditingController telefonoController = TextEditingController();
    final TextEditingController direccionController = TextEditingController();
    final TextEditingController correoController = TextEditingController();

    // Cerrar diálogo anterior
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Nuevo Cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: denominacionController,
                decoration: const InputDecoration(
                  labelText: 'Nombre/Razón Social *',
                ),
              ),
              TextField(
                controller: numeroDocumentoController,
                decoration: const InputDecoration(
                  labelText: 'Número de Documento *',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                ),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                ),
              ),
              TextField(
                controller: correoController,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validar campos obligatorios
              if (denominacionController.text.isEmpty ||
                  numeroDocumentoController.text.isEmpty) {
                if (!dialogContext.mounted) {
                  return;
                }
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Nombre y número de documento son obligatorios'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Cerrar el diálogo
              Navigator.pop(dialogContext);

              try {
                // Crear cliente usando el provider
                await _provider.crearCliente(<String, dynamic>{
                  'tipoDocumentoId': 1,
                  'numeroDocumento': numeroDocumentoController.text,
                  'denominacion': denominacionController.text,
                  'telefono': telefonoController.text,
                  'direccion': direccionController.text,
                  'correo': correoController.text,
                });

                if (!mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Cliente ${denominacionController.text} creado exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al crear cliente: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // Mostrar diálogo para buscar productos
  Future<void> _mostrarDialogoProductos() async {
    // Mostrar indicador de carga mientras se cargan los productos
    if (!_productosLoaded) {
      _provider.setLoading(true, message: 'Cargando productos...');
      try {
        await _provider.cargarProductos();
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
          _provider.setLoading(false);
        }
      }
    }

    if (!mounted) {
      return;
    }

    // Verificar que tengamos productos para mostrar
    if (_provider.productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay productos disponibles'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    debugPrint(
        '📦 Mostrando diálogo con ${_provider.productos.length} productos');

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: EdgeInsets.symmetric(
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
                    productos: _provider.productos,
                    categorias: _provider.categorias,
                    isLoading: _provider.isLoadingProductos,
                    sucursalId: _provider.sucursalId,
                    onProductoSeleccionado: (Map<String, dynamic> producto) {
                      debugPrint(
                          '✅ Producto seleccionado: ${producto['nombre']}');
                      // Mostrar detalles de promoción antes de agregar
                      _mostrarDetallesPromocion(producto);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Mostrar detalles de promoción
  void _mostrarDetallesPromocion(Map<String, dynamic> producto) {
    debugPrint('🔍 Verificando promociones para: ${producto['nombre']}');
    Navigator.pop(context); // Cerrar diálogo de búsqueda
    _agregarProductoConVerificacion(producto);
  }

  // Nuevo método para verificar y agregar producto
  void _agregarProductoConVerificacion(Map<String, dynamic> producto) {
    debugPrint('🛒 Intentando agregar producto: ${producto['nombre']}');

    // Verificar que el producto tenga los campos necesarios
    if (!producto.containsKey('id') ||
        !producto.containsKey('nombre') ||
        !producto.containsKey('precio')) {
      debugPrint('❌ Error: Producto no tiene los campos requeridos');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Producto inválido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar stock disponible
    final int stockDisponible = producto['stock'] ?? 0;
    if (stockDisponible <= 0) {
      debugPrint('❌ Error: Producto sin stock disponible');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${producto['nombre']} no tiene stock disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Intentar agregar el producto
    final bool resultado = _agregarProducto(producto);

    if (resultado) {
      debugPrint('✅ Producto agregado exitosamente');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${producto['nombre']} agregado al carrito'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      debugPrint('❌ Error al agregar el producto');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al agregar el producto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Métodos para delegar al provider
  bool _agregarProducto(Map<String, dynamic> producto) {
    debugPrint(
        '➡️ Delegando agregar producto al provider: ${producto['nombre']}');
    final bool resultado = _provider.agregarProducto(producto);

    // Mostrar mensaje de promoción si existe
    if (resultado && _provider.mensajePromocion.isNotEmpty) {
      debugPrint('🎉 Mostrando mensaje de promoción');
      _mostrarMensajePromocionConAnimacion(
        _provider.nombreProductoPromocion,
        _provider.mensajePromocion,
      );
    }

    return resultado;
  }

  // Método para mostrar la promoción de liquidación
  Widget _buildPromocionLiquidacionCard(Map<String, dynamic> producto) {
    final double precioOriginal = (producto['precio'] as num).toDouble();
    final double precioLiquidacion = producto['precioLiquidacion'] is num
        ? (producto['precioLiquidacion'] as num).toDouble()
        : precioOriginal;

    // Calcular el porcentaje de descuento
    final double ahorro = precioOriginal - precioLiquidacion;
    final int porcentaje =
        precioOriginal > 0 ? ((ahorro / precioOriginal) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.local_offer,
                color: Colors.amber,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Liquidación',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$porcentaje% OFF',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Precio regular',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'S/ ${precioOriginal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.lineThrough,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Precio liquidación',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'S/ ${precioLiquidacion.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Método para mostrar la promoción de productos gratis
  Widget _buildPromocionGratisCard(Map<String, dynamic> producto) {
    final int cantidadMinima = producto['cantidadMinima'] ?? 0;
    final int cantidadGratis = producto['cantidadGratis'] ?? 0;

    if (cantidadMinima <= 0 || cantidadGratis <= 0) {
      return const SizedBox();
    }

    return Card(
      color: const Color(0xFF263238), // Azul grisáceo oscuro
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.gift,
                    color: Color(0xFF4CAF50),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Promoción: Lleva y te Regalamos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Por la compra de $cantidadMinima unidades, el sistema te regalará $cantidadGratis unidades adicionales.',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta promoción se aplicará automáticamente por el servidor',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 12,
                color: Color(0xFFB0BEC5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para mostrar la promoción de descuento porcentual
  Widget _buildPromocionDescuentoCard(Map<String, dynamic> producto) {
    final int cantidadMinima = producto['cantidadMinima'] ?? 0;
    final int porcentaje = producto['descuentoPorcentaje'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.percent,
                color: Colors.blue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$porcentaje% de descuento',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Se aplica un $porcentaje% de descuento al comprar $cantidadMinima o más unidades.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Este descuento será aplicado automáticamente por el servidor',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
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

  // Método para construir cada elemento de producto en la venta
  Widget _buildProductoVentaItem(Map<String, dynamic> producto, int index) {
    final int cantidad = producto['cantidad'];
    final double precioOriginal = (producto['precio'] as num).toDouble();
    final int? porcentajeDescuento = producto['descuentoPorcentaje'] as int?;
    final int? cantidadMinima = producto['cantidadMinima'] as int?;
    final int? cantidadGratis = producto['cantidadGratis'] as int?;
    final int stockDisponible =
        producto['stockDisponible'] ?? producto['stock'] ?? 0;
    final bool stockLimitado = cantidad >= stockDisponible;
    final bool promocionActivada = producto['promocionActivada'] == true;
    final bool tienePromocionGratis = producto['tienePromocionGratis'] ?? false;
    final bool tieneDescuentoPorcentual =
        producto['tieneDescuentoPorcentual'] ?? false;
    final bool enLiquidacion = producto['enLiquidacion'] ?? false;

    // Calcular el precio con descuento si aplica
    double precio;
    if (producto['enLiquidacion'] == true &&
        producto['precioLiquidacion'] != null) {
      precio = (producto['precioLiquidacion'] as num).toDouble();
    } else if (porcentajeDescuento != null &&
        cantidad >= (cantidadMinima ?? 0)) {
      // Aplicar el descuento porcentual
      final double descuento = (precioOriginal * porcentajeDescuento) / 100;
      precio = precioOriginal - descuento;
    } else {
      precio = producto['precioVenta'] ?? precioOriginal;
    }

    // Calcular el subtotal
    final double subtotal = precio * cantidad;

    // Calcular productos gratis si aplica
    int productosGratis = 0;
    if (tienePromocionGratis &&
        cantidadMinima != null &&
        cantidadGratis != null &&
        cantidad >= cantidadMinima) {
      final int gruposCompletos = cantidad ~/ cantidadMinima;
      productosGratis = gruposCompletos * cantidadGratis;
    }

    // Determinar el color del borde según el tipo de promoción
    Color? borderColor;
    Color? backgroundColor;
    IconData? promocionIcon;
    String? promocionTooltip;

    if (promocionActivada) {
      if (tienePromocionGratis) {
        borderColor = const Color(0xFF2E7D32); // Verde oscuro
        backgroundColor = const Color(0xFF2E7D32).withOpacity(0.1);
        promocionIcon = Icons.card_giftcard;
        promocionTooltip = 'Promoción "Lleva y Paga" activada';
      } else if (tieneDescuentoPorcentual &&
          cantidad >= (cantidadMinima ?? 0)) {
        borderColor = Colors.purple;
        backgroundColor = Colors.purple.withOpacity(0.1);
        promocionIcon = Icons.percent;
        promocionTooltip = 'Descuento del $porcentajeDescuento% aplicado';
      }
    } else if (enLiquidacion) {
      borderColor = Colors.amber;
      backgroundColor = Colors.amber.withOpacity(0.1);
      promocionIcon = Icons.local_offer;
      promocionTooltip = 'Producto en liquidación';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: borderColor != null
            ? BorderSide(color: borderColor, width: 1.5)
            : (stockLimitado
                ? const BorderSide(color: Colors.orange)
                : BorderSide.none),
      ),
      color: backgroundColor ?? Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                // Icono de promoción
                if (promocionIcon != null)
                  Tooltip(
                    message: promocionTooltip ?? '',
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: borderColor?.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          promocionIcon,
                          size: 14,
                          color: borderColor,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    producto['nombre'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: borderColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarProducto(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            if (promocionActivada)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.info_outline,
                      size: 12,
                      color: borderColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        tienePromocionGratis &&
                                cantidadMinima != null &&
                                cantidadGratis != null
                            ? 'Por cada $cantidadMinima unidades, recibirás $cantidadGratis gratis'
                            : (tieneDescuentoPorcentual &&
                                    cantidad >= (cantidadMinima ?? 0)
                                ? 'Descuento del $porcentajeDescuento% aplicado por comprar $cantidad o más unidades'
                                : 'Promoción aplicada automáticamente por el servidor'),
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: borderColor?.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                // Mostrar precios con descuento si aplica
                if (tieneDescuentoPorcentual &&
                    porcentajeDescuento != null &&
                    cantidad >= (cantidadMinima ?? 0))
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'S/ ${precioOriginal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-$porcentajeDescuento%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'S/ ${precio.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: borderColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Subtotal: S/ ${subtotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: borderColor?.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'S/ ${precio.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                promocionActivada ? FontWeight.bold : null,
                            color: borderColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Subtotal: S/ ${subtotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: borderColor?.withOpacity(0.8),
                          ),
                        ),
                        if (tienePromocionGratis && productosGratis > 0) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF2E7D32).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.card_giftcard,
                                  size: 12,
                                  color: Color(0xFF2E7D32),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Recibirás $productosGratis unidades gratis',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: stockLimitado
                        ? Colors.orange.withOpacity(0.2)
                        : (borderColor?.withOpacity(0.1) ??
                            Colors.blue.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16),
                        onPressed: () => _cambiarCantidad(index, cantidad - 1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '$cantidad',
                          style: TextStyle(
                            color: stockLimitado ? Colors.orange : borderColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.add,
                          size: 16,
                          color: stockLimitado
                              ? Colors.orange.withOpacity(0.5)
                              : null,
                        ),
                        onPressed: stockLimitado
                            ? null
                            : () => _cambiarCantidad(index, cantidad + 1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Disponible: $stockDisponible',
              style: TextStyle(
                fontSize: 12,
                color: stockLimitado ? Colors.orange : Colors.green,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para finalizar venta (verificar stock y crear proforma)
  Future<void> _finalizarVenta() async {
    debugPrint('🛍️ Iniciando proceso de finalización de venta...');

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
      _provider.setLoading(true,
          message: 'Verificando disponibilidad de stock...');

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
          // Si hay un error con el formato de ID, mostrar error y salir
          _provider.setLoading(false);

          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Error con el ID del producto ${producto['nombre']}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final int cantidad = producto['cantidad'];

        // Actualizar mensaje de loading
        if (mounted) {
          _provider.setLoading(true,
              message: 'Verificando stock de ${producto['nombre']}...');
        }

        // Obtener producto actualizado para verificar stock
        final Producto productoActual = await _productosApi.getProducto(
          sucursalId: _sucursalId,
          productoId: productoId,
          useCache: false, // No usar caché para obtener datos actualizados
        );

        if (!mounted) {
          return;
        }

        if (productoActual.stock < cantidad) {
          _provider.setLoading(false);

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
        _provider.setLoading(false);

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
    debugPrint('📝 Iniciando creación de proforma...');

    // Mostrar indicador de carga con más contexto para reducir ansiedad
    _provider.setLoading(true, message: 'Enviando datos al servidor...');

    try {
      // Actualizar mensaje para proporcionar retroalimentación del progreso
      if (mounted) {
        _provider.setLoading(true,
            message: 'Preparando detalles de la venta...');
      }

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

      // Actualizar mensaje para proporcionar retroalimentación del progreso
      if (mounted) {
        _provider.setLoading(true, message: 'Comunicando con el servidor...');
      }

      // Llamar a la API para crear la proforma
      final Map<String, dynamic> respuesta =
          await _proformasApi.createProformaVenta(
        sucursalId: _sucursalId,
        nombre: 'Proforma ${_clienteSeleccionado!.denominacion}',
        total: _totalVenta,
        detalles: detalles,
        empleadoId: _empleadoId,
        clienteId: _clienteSeleccionado!.id,
      );

      if (!mounted) {
        return;
      }

      // Actualizar mensaje para proporcionar retroalimentación del progreso
      _provider.setLoading(true, message: 'Procesando respuesta...');

      // Convertir la respuesta a un objeto estructurado
      final Proforma? proformaCreada =
          _proformasApi.parseProformaVenta(respuesta);

      // Recargar productos para reflejar el stock actualizado por el backend
      _provider.cargarProductos();

      if (mounted) {
        _provider.setLoading(true, message: 'Actualizando inventario...');
      }

      if (!mounted) {
        return;
      }

      // Cambiar estado antes de mostrar el diálogo
      _provider.setLoading(false);

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
                debugPrint(
                    '✅ Venta finalizada exitosamente. Limpiando carrito...');
                Navigator.pop(dialogContext);
                _provider
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
      debugPrint('🚨 Error al crear la proforma: $e');

      if (!mounted) {
        return;
      }

      // Resetear estado de carga
      _provider.setLoading(false);

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
            color: Colors.black.withOpacity(0.7),
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
    // Asegurarse de que los productos estén cargados
    if (!_productosLoaded) {
      await _cargarProductos();
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
          onProductoSeleccionado: (Map<String, dynamic> producto) {
            // Mostrar detalles de promoción antes de agregar
            _mostrarDetallesPromocion(producto);
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
    _provider.eliminarProducto(index);
  }

  bool _cambiarCantidad(int index, int cantidad) {
    bool resultado = _provider.cambiarCantidad(index, cantidad);
    // Actualizar mensaje de promoción si existe
    if (_provider.mensajePromocion.isNotEmpty) {
      _mostrarMensajePromocionConAnimacion(
        _provider.nombreProductoPromocion,
        _provider.mensajePromocion,
      );
    }
    return resultado;
  }

  Future<void> _cargarProductos() async {
    await _provider.cargarProductos();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VentasColabProvider>(
      builder:
          (BuildContext context, VentasColabProvider provider, Widget? child) {
        debugPrint(
            '🔄 Reconstruyendo VentasColabScreen - Productos en carrito: ${provider.productosVenta.length}');
        debugPrint(
            '💰 Total actual: S/ ${provider.totalVenta.toStringAsFixed(2)}');

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
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    child: Row(
                      children: <Widget>[
                        // Icono o avatar del cliente
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: provider.clienteSeleccionado != null
                                ? const Color(0xFF1976D2).withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: FaIcon(
                              provider.clienteSeleccionado != null
                                  ? FontAwesomeIcons.userCheck
                                  : FontAwesomeIcons.userPlus,
                              size: 16,
                              color: provider.clienteSeleccionado != null
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
                                provider.clienteSeleccionado?.denominacion ??
                                    'Seleccionar Cliente',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: provider.clienteSeleccionado != null
                                      ? const Color.fromARGB(221, 255, 255, 255)
                                      : Colors.grey,
                                ),
                              ),
                              if (provider.clienteSeleccionado != null) ...[
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
                                      provider
                                          .clienteSeleccionado!.numeroDocumento,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (provider.clienteSeleccionado!
                                                .telefono !=
                                            null &&
                                        provider.clienteSeleccionado!.telefono!
                                            .isNotEmpty) ...[
                                      const SizedBox(width: 16),
                                      const FaIcon(
                                        FontAwesomeIcons.phone,
                                        size: 12,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        provider.clienteSeleccionado!.telefono!,
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
                                    provider.clienteSeleccionado != null
                                        ? 'Cambiar'
                                        : 'Seleccionar',
                                    style: TextStyle(
                                      color:
                                          provider.clienteSeleccionado != null
                                              ? const Color(0xFF1976D2)
                                              : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  FaIcon(
                                    provider.clienteSeleccionado != null
                                        ? FontAwesomeIcons.penToSquare
                                        : FontAwesomeIcons.chevronRight,
                                    size: 14,
                                    color: provider.clienteSeleccionado != null
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
                      provider.productosVenta.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const <Widget>[
                                  FaIcon(
                                    FontAwesomeIcons.cartShopping,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No hay productos en la venta',
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
                          : ListView.builder(
                              padding: const EdgeInsets.only(
                                  bottom:
                                      100), // Espacio para el botón de finalizar
                              itemCount: provider.productosVenta.length,
                              itemBuilder: (BuildContext context, int index) {
                                final Map<String, dynamic> producto =
                                    provider.productosVenta[index];
                                return _buildProductoVentaItem(producto, index);
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
                        color: Colors.black.withOpacity(0.1),
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
                                  'S/ ${provider.totalVenta.toStringAsFixed(2)}',
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const FaIcon(FontAwesomeIcons.trash,
                                  size: 16),
                              label: const Text('Limpiar'),
                              onPressed: provider.productosVenta.isEmpty
                                  ? null
                                  : () {
                                      provider.limpiarVenta();
                                      debugPrint('🧹 Carrito limpiado');
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const FaIcon(FontAwesomeIcons.check,
                                  size: 16),
                              label: const Text('Finalizar Venta'),
                              onPressed: provider.productosVenta.isEmpty ||
                                      provider.clienteSeleccionado == null
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
      },
    );
  }
}
