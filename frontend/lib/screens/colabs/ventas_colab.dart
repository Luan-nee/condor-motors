import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/cliente.model.dart'; // Importamos el modelo de Cliente
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/proforma.model.dart' hide DetalleProforma;
// Importamos la API de proformas para usar DetalleProforma
import 'package:condorsmotors/screens/colabs/barcode_colab.dart';
import 'package:condorsmotors/screens/colabs/historial_ventas_colab.dart';
import 'package:condorsmotors/screens/colabs/widgets/busqueda_producto.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class VentasColabScreen extends StatefulWidget {
  const VentasColabScreen({super.key});

  @override
  State<VentasColabScreen> createState() => _VentasColabScreenState();
}

class _VentasColabScreenState extends State<VentasColabScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late final ProductosApi _productosApi;
  late final ProformaVentaApi _proformasApi;
  late final ClientesApi _clientesApi; // Agregamos la API de clientes
  String _sucursalId = '9'; // Valor por defecto, se actualizará al inicializar
  int _empleadoId = 1; // Valor por defecto, se actualizará al inicializar
  List<Map<String, dynamic>> _productos = <Map<String, dynamic>>[]; // Lista de productos obtenidos de la API
  bool _productosLoaded = false; // Flag para controlar si ya se cargaron los productos
  
  // Lista de productos en la venta actual
  final List<Map<String, dynamic>> _productosVenta = <Map<String, dynamic>>[];
  
  // Cliente seleccionado (cambiamos de Map a Cliente)
  Cliente? _clienteSeleccionado;
  
  // Lista de clientes cargados desde la API
  List<Cliente> _clientes = <Cliente>[];
  bool _clientesLoaded = false;
  
  // Controlador para el campo de búsqueda de productos
  final TextEditingController _searchController = TextEditingController();
  
  // Controlador para el campo de búsqueda de clientes
  final TextEditingController _clienteSearchController = TextEditingController();
  
  // Agregar las variables faltantes
  List<String> _categorias = <String>['Todas']; // Lista de categorías de productos
  bool _isLoadingProductos = false; // Flag para indicar si se están cargando productos
  
  String _loadingMessage = ''; // Variable para mostrar mensajes de carga
  
  // Variables para la animación de promoción
  late AnimationController _animationController;
  String _mensajePromocion = '';
  String _nombreProductoPromocion = '';
  bool _mostrarMensajePromocion = false;
  
  @override
  void initState() {
    super.initState();
    _productosApi = api.productos;
    _proformasApi = api.proformas;
    _clientesApi = api.clientes; // Inicializamos la API de clientes
    
    // Inicializar el controlador de animación
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Configurar los datos iniciales y cargar productos
    _configurarDatosIniciales();
  }

  // Método para configurar los datos iniciales de manera asíncrona
  Future<void> _configurarDatosIniciales() async {
    setState(() => _isLoading = true);
    
    try {
      // Obtener el ID de sucursal del usuario autenticado usando await
      final Map<String, dynamic>? userData = await api.authService.getUserData();
      if (userData != null && userData['sucursalId'] != null) {
        _sucursalId = userData['sucursalId'].toString();
        debugPrint('Usando sucursal del usuario autenticado: $_sucursalId');
        
        // Obtener ID del empleado
        _empleadoId = int.tryParse(userData['id']?.toString() ?? '0') ?? 0;
        debugPrint('ID del empleado: $_empleadoId');
      } else {
        // Fallback por si no se puede obtener el ID de sucursal
        debugPrint('No se pudo obtener la sucursal del usuario, usando fallback: $_sucursalId');
      }
    } catch (e) {
      debugPrint('Error al obtener datos del usuario: $e');
    } finally {
      // Cargar productos y clientes después de configurar la sucursal
      await Future.wait(<Future<void>>[
        _cargarProductos(),
        _cargarClientes(),
      ]);
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _clienteSearchController.dispose(); // Eliminamos también el controlador de búsqueda de clientes
    _animationController.dispose(); // Liberar recursos del controlador de animación
    super.dispose();
  }
  
  // Cargar productos desde la API usando ProductosApi
  Future<void> _cargarProductos() async {
    if (_productosLoaded) {
      return;
    }
    
    setState(() {
      _isLoadingProductos = true;
    });
    
    try {
      debugPrint('Cargando productos para sucursal ID: $_sucursalId (Sucursal del vendedor)');
      
      // Usar el método mejorado getProductosPorFiltros para obtener datos más relevantes
      final PaginatedResponse<Producto> response = await _productosApi.getProductosPorFiltros(
        sucursalId: _sucursalId,
        stockPositivo: true, // Mostrar solo productos con stock disponible
        pageSize: 100, // Obtener más productos por página
      );
      
      // Extraer categorías únicas para el filtro
      final Set<String> categoriasUnicas = <String>{'Todas'};
      
      // Lista para almacenar los productos formateados
      final List<Map<String, dynamic>> productosFormateados = <Map<String, dynamic>>[];
      
      // Procesar la lista de productos obtenida
      for (final Producto producto in response.items) {
        // Agregar categoría a la lista de categorías únicas
        categoriasUnicas.add(producto.categoria);
        
        // Verificar el tipo de promoción que tiene el producto
        final bool tienePromocionGratis = producto.cantidadGratisDescuento != null && 
                                        producto.cantidadGratisDescuento! > 0;
        
        final bool tieneDescuentoPorcentual = producto.porcentajeDescuento != null && 
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
          'tienePromocion': producto.liquidacion || tienePromocionGratis || tieneDescuentoPorcentual,
        });
      }
      
      // Actualizar el estado
      setState(() {
        _productos = productosFormateados;
        _productosLoaded = true;
        _categorias = categoriasUnicas.toList()..sort();
        _isLoadingProductos = false;
      });
      
      debugPrint('Productos cargados: ${_productos.length}');
      debugPrint('Categorías detectadas: ${_categorias.length}');
      debugPrint('Productos con promociones: ${productosFormateados.where((p) => p['tienePromocion'] == true).length}');
      
      // Añadir información detallada sobre las promociones para debug
      final int productosLiquidacion = productosFormateados.where((p) => p['enLiquidacion'] == true).length;
      final int productosPromoGratis = productosFormateados.where((p) => p['tienePromocionGratis'] == true).length;
      final int productosDescuentoPorcentual = productosFormateados.where((p) => p['tieneDescuentoPorcentual'] == true).length;
      
      debugPrint('Detalle de promociones:');
      debugPrint('- Productos en liquidación: $productosLiquidacion');
      debugPrint('- Productos con promo "Lleva y Paga": $productosPromoGratis');
      debugPrint('- Productos con descuento porcentual: $productosDescuentoPorcentual');
      
      // Mostrar ejemplos de cada tipo de promoción para verificación
      if (productosLiquidacion > 0) {
        final Map<String, dynamic> ejemploLiquidacion = productosFormateados.firstWhere((p) => p['enLiquidacion'] == true);
        debugPrint('Ejemplo liquidación: ${ejemploLiquidacion['nombre']} - Precio: ${ejemploLiquidacion['precio']} - Precio liquidación: ${ejemploLiquidacion['precioLiquidacion']}');
      }
      
      if (productosPromoGratis > 0) {
        final Map<String, dynamic> ejemploPromoGratis = productosFormateados.firstWhere((p) => p['tienePromocionGratis'] == true);
        debugPrint('Ejemplo promo gratis: ${ejemploPromoGratis['nombre']} - Lleva: ${ejemploPromoGratis['cantidadMinima']} - Gratis: ${ejemploPromoGratis['cantidadGratis']}');
      }
      
      if (productosDescuentoPorcentual > 0) {
        final Map<String, dynamic> ejemploDescuento = productosFormateados.firstWhere((p) => p['tieneDescuentoPorcentual'] == true);
        debugPrint('Ejemplo descuento %: ${ejemploDescuento['nombre']} - Cantidad mínima: ${ejemploDescuento['cantidadMinima']} - Descuento: ${ejemploDescuento['descuentoPorcentaje']}%');
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      
      setState(() {
        _isLoadingProductos = false;
      });
      
      debugPrint('Error al cargar productos: $e');
      
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar productos: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }
  
  // Cargar clientes desde la API usando ClientesApi
  Future<void> _cargarClientes() async {
    if (_clientesLoaded) {
      return; // Evitar cargar múltiples veces
    }
    
    setState(() => _isLoading = true);
    
    try {
      debugPrint('Cargando clientes desde la API...');
      
      // Obtener los clientes desde la API
      final List<Cliente> clientesData = await _clientesApi.getClientes(
        pageSize: 100, // Obtener más clientes por página
        sortBy: 'denominacion', // Ordenar por nombre
      );
      
      if (!mounted) {
        return;
      }
      
      setState(() {
        _clientes = clientesData;
        _clientesLoaded = true;
        debugPrint('Clientes cargados: ${_clientes.length}');
      });
    } catch (e) {
      debugPrint('Error al cargar clientes: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar clientes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // Calcular el total de la venta
  double get _totalVenta {
    double total = 0;
    for (final Map<String, dynamic> producto in _productosVenta) {
      final int cantidad = producto['cantidad'];
      final double precio = producto['precioVenta'] ?? 
          (producto['enLiquidacion'] == true && producto['precioLiquidacion'] != null 
              ? (producto['precioLiquidacion'] as num).toDouble() 
              : (producto['precio'] as num).toDouble());
      
      total += precio * cantidad;
    }
    return total;
  }
  
  // Agregar producto a la venta
  void _agregarProducto(Map<String, dynamic> producto) {
    // Verificar disponibilidad de stock antes de agregar el producto
    final int stockDisponible = producto['stock'] ?? 0;
    
    if (stockDisponible <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay stock disponible de ${producto['nombre']}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Determinar el precio correcto según si está en liquidación o no
    final bool enLiquidacion = producto['enLiquidacion'] ?? false;
    final double precioFinal = enLiquidacion && producto['precioLiquidacion'] != null 
        ? (producto['precioLiquidacion'] as num).toDouble() 
        : (producto['precio'] as num).toDouble();
    
    setState(() {
      // Verificar si el producto ya está en la venta
      final int index = _productosVenta.indexWhere((Map<String, dynamic> p) => p['id'] == producto['id']);
      
      if (index >= 0) {
        // Si ya existe, verificar que no exceda el stock disponible
        final int cantidadActual = _productosVenta[index]['cantidad'];
        
        if (cantidadActual < stockDisponible) {
          // Solo incrementar si hay stock suficiente
          _productosVenta[index]['cantidad']++;
          // Aplicar descuentos basados en la nueva cantidad
          _aplicarDescuentosPorCantidad(index);
        } else {
          // Mostrar mensaje indicando que se alcanzó el límite del stock
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se puede agregar más ${producto['nombre']}. Stock máximo: $stockDisponible'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Si no existe, agregarlo con cantidad 1
        _productosVenta.add(<String, dynamic>{
          ...producto,
          'cantidad': 1,
          'stockDisponible': stockDisponible,
          'precioVenta': precioFinal, // Guardar el precio final para cálculos
        });
        
        // Aplicar descuentos si corresponde (para cantidad 1)
        final int nuevoIndex = _productosVenta.length - 1;
        _aplicarDescuentosPorCantidad(nuevoIndex);
      }
    });
  }
  
  // Eliminar producto de la venta
  void _eliminarProducto(int index) {
    setState(() {
      _productosVenta.removeAt(index);
    });
  }
  
  // Cambiar cantidad de un producto
  void _cambiarCantidad(int index, int cantidad) {
    if (cantidad <= 0) {
      _eliminarProducto(index);
      return;
    }
    
    // Verificar que la nueva cantidad no exceda el stock disponible
    final int stockDisponible = _productosVenta[index]['stockDisponible'] ?? 
                               _productosVenta[index]['stock'] ?? 0;
    
    if (cantidad > stockDisponible) {
      // Mostrar mensaje de error y limitar la cantidad al stock disponible
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay suficiente stock. Disponible: $stockDisponible ${_productosVenta[index]['nombre']}'),
          backgroundColor: Colors.orange,
        ),
      );
      
      // Establecer la cantidad al máximo disponible
      setState(() {
        _productosVenta[index]['cantidad'] = stockDisponible;
      });
      return;
    }
    
    setState(() {
      _productosVenta[index]['cantidad'] = cantidad;
      
      // Reiniciar el estado de promociones si la cantidad cambió
      final Map<String, dynamic> producto = _productosVenta[index];
      final bool tienePromocionGratis = producto['tienePromocionGratis'] ?? false;
      final int cantidadMinima = producto['cantidadMinima'] ?? 0;
      
      // Si tiene promoción de regalo y la cantidad está por debajo del mínimo, resetear el estado 
      if (tienePromocionGratis && cantidadMinima > 0 && cantidad < cantidadMinima) {
        producto['promocionActivada'] = false;
      }
      
      // Calcular y aplicar descuentos según la cantidad (si corresponde)
      _aplicarDescuentosPorCantidad(index);
    });
  }
  
  // Método para calcular y aplicar descuentos basados en la cantidad
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
      final double precioLiquidacion = (producto['precioLiquidacion'] as num).toDouble();
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
      
      if (cantidad >= cantidadMinima && cantidadMinima > 0 && cantidadGratis > 0) {
        // Solo marcar como que la promoción está activada para visualización
        producto['promocionActivada'] = true;
        
        // Solo actualizar el mensaje si no hay otro descuento aplicado o es más relevante
        if (!descuentoAplicado) {
          final int promocionesCompletas = cantidad ~/ cantidadMinima;
          final int unidadesGratis = promocionesCompletas * cantidadGratis;
          mensajeDescuento = '$unidadesGratis unidades gratis serán incluidas por el servidor';
          descuentoAplicado = true;
        }
      } else {
        // Si ya no cumple con la cantidad mínima, desactivar la promoción
        producto['promocionActivada'] = false;
      }
    }
    
    // Verificar si tiene descuento porcentual (solo para información visual)
    final bool tieneDescuentoPorcentual = producto['tieneDescuentoPorcentual'] ?? false;
    if (tieneDescuentoPorcentual && !descuentoAplicado) {
      final int cantidadMinima = producto['cantidadMinima'] ?? 0;
      final int porcentaje = producto['descuentoPorcentaje'] ?? 0;
      
      if (cantidad >= cantidadMinima && cantidadMinima > 0 && porcentaje > 0) {
        // El server aplicará este descuento, solo mostrar el mensaje
        mensajeDescuento = '$porcentaje% de descuento será aplicado por el servidor';
        descuentoAplicado = true;
      }
    }
    
    // Actualizar el precio de venta y el mensaje de descuento
    _productosVenta[index]['precioVenta'] = precioFinal;
    _productosVenta[index]['descuentoAplicado'] = descuentoAplicado;
    _productosVenta[index]['mensajeDescuento'] = mensajeDescuento;
    
    // Mostrar mensaje al usuario si se aplicó algún descuento (con animación)
    if (descuentoAplicado && mensajeDescuento.isNotEmpty) {
      _mostrarMensajePromocionConAnimacion(producto['nombre'], mensajeDescuento);
    }
  }
  
  // Limpiar la venta actual
  void _limpiarVenta() {
    setState(() {
      _productosVenta.clear();
      _clienteSeleccionado = null;
    });
  }
  
  // Mostrar diálogo para seleccionar cliente
  void _mostrarDialogoClientes() {
    // Asegurarse de que los clientes estén cargados
    if (!_clientesLoaded) {
      _cargarClientes();
    }
    
    // Resetear el controlador de búsqueda
    _clienteSearchController.text = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, setState) {
          // Filtrar clientes según la búsqueda
          List<Cliente> clientesFiltrados = _clientes;
          
          if (_clienteSearchController.text.isNotEmpty) {
            final String query = _clienteSearchController.text.toLowerCase();
            clientesFiltrados = _clientes.where((Cliente cliente) {
              return cliente.denominacion.toLowerCase().contains(query) || 
                     cliente.numeroDocumento.toLowerCase().contains(query);
            }).toList();
          }
          
          return AlertDialog(
            title: const Text('Seleccionar Cliente'),
            content: SingleChildScrollView( // Usar SingleChildScrollView para responsividad
              child: SizedBox( // SizedBox para limitar el ancho máximo si es necesario
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Ajustar al contenido verticalmente
                  children: <Widget>[
                    // Campo de búsqueda
                    TextField(
                      controller: _clienteSearchController,
                      decoration: const InputDecoration(
                        labelText: 'Buscar por nombre o documento',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) {
                        // Actualizar la búsqueda en tiempo real
                        setState(() {}); // setState del StatefulBuilder
                      },
                    ),
                    const SizedBox(height: 16),
                    // Lista de clientes (sin Expanded, con shrinkWrap)
                    _isLoading && !_clientesLoaded
                        ? const Center(
                            child: Padding( // Añadir padding para el indicador
                              padding: EdgeInsets.symmetric(vertical: 32.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : clientesFiltrados.isEmpty
                          ? const Center(
                              child: Padding( // Añadir padding para el mensaje
                                padding: EdgeInsets.symmetric(vertical: 32.0),
                                child: Text('No se encontraron clientes con esa búsqueda'),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true, // Esencial dentro de SingleChildScrollView/Column
                              physics: const NeverScrollableScrollPhysics(), // Evitar scroll anidado
                              itemCount: clientesFiltrados.length,
                              itemBuilder: (BuildContext context, int index) {
                                final Cliente cliente = clientesFiltrados[index];
                                return ListTile(
                                  title: Text(cliente.denominacion),
                                  subtitle: Text('Doc: ${cliente.numeroDocumento}'),
                                  onTap: () {
                                    // Actualizar el cliente seleccionado
                                    this.setState(() { // setState del _VentasColabScreenState
                                      _clienteSeleccionado = cliente;
                                    });
                                    Navigator.pop(context); // Cerrar diálogo
                                  },
                                );
                              },
                            ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => _mostrarDialogoNuevoCliente(),
                child: const Text('Nuevo Cliente'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // Mostrar diálogo para crear nuevo cliente
  void _mostrarDialogoNuevoCliente() {
    final TextEditingController denominacionController = TextEditingController();
    final TextEditingController numeroDocumentoController = TextEditingController();
    final TextEditingController telefonoController = TextEditingController();
    final TextEditingController direccionController = TextEditingController();
    final TextEditingController correoController = TextEditingController();
    
    // Cerrar diálogo anterior
    Navigator.pop(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validar campos obligatorios
              if (denominacionController.text.isEmpty || numeroDocumentoController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nombre y número de documento son obligatorios'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Cerrar el diálogo
              Navigator.pop(context);
              
              // Mostrar indicador de carga
              setState(() => _isLoading = true);
              
              try {
                // Crear cliente en la API
                final Cliente nuevoCliente = await _clientesApi.createCliente(<String, dynamic>{
                  'tipoDocumentoId': 1,
                  'numeroDocumento': numeroDocumentoController.text,
                  'denominacion': denominacionController.text,
                  'telefono': telefonoController.text,
                  'direccion': direccionController.text,
                  'correo': correoController.text,
                });
                
                // Actualizar la lista de clientes y seleccionar el nuevo cliente
                setState(() {
                  _clientes.add(nuevoCliente);
                  _clienteSeleccionado = nuevoCliente;
                  _isLoading = false;
                });
                
                // Mostrar mensaje de éxito
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cliente ${nuevoCliente.denominacion} creado exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                debugPrint('Error al crear cliente: $e');
                
                setState(() => _isLoading = false);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al crear cliente: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
  
  // Mostrar diálogo para buscar productos
  void _mostrarDialogoProductos() {
    // Asegurarse de que los productos estén cargados
    if (!_productosLoaded) {
      _cargarProductos();
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      'Buscar Producto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              Expanded(
                  child: BusquedaProductoWidget(
                    productos: _productos,
                    categorias: _categorias,
                    isLoading: _isLoadingProductos,
                    sucursalId: _sucursalId,
                    onProductoSeleccionado: (Map<String, dynamic> producto) {
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
    final bool enLiquidacion = producto['enLiquidacion'] ?? false;
    final bool tienePromocionGratis = producto['tienePromocionGratis'] ?? false;
    final bool tieneDescuentoPorcentual = producto['tieneDescuentoPorcentual'] ?? false;
    
    // Si no hay promociones, agregar directamente
    if (!enLiquidacion && !tienePromocionGratis && !tieneDescuentoPorcentual) {
      Navigator.pop(context);
      _agregarProducto(producto);
      return;
    }
    
    // Mostrar diálogo con los detalles de promoción
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF222222),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                producto['nombre'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Todas las promociones son aplicadas automáticamente por el servidor',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Promociones disponibles:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                
                if (enLiquidacion)
                  _buildPromocionLiquidacionCard(producto),
                  
                if (tienePromocionGratis) ...<Widget>[
                  const SizedBox(height: 16),
                  _buildPromocionGratisCard(producto),
                ],
                
                if (tieneDescuentoPorcentual) ...<Widget>[
                  const SizedBox(height: 16),
                  _buildPromocionDescuentoCard(producto),
                ],
                
                if ((enLiquidacion && tienePromocionGratis) || 
                    (enLiquidacion && tieneDescuentoPorcentual) ||
                    (tienePromocionGratis && tieneDescuentoPorcentual)) ...<Widget>[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: <Widget>[
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Este producto tiene múltiples promociones. El servidor aplicará la más beneficiosa para el cliente.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar diálogo de promoción
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context); // Cerrar diálogo de promoción
                Navigator.pop(context); // Cerrar diálogo de búsqueda
                _agregarProducto(producto);
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }
  
  // Método para mostrar la promoción de liquidación
  Widget _buildPromocionLiquidacionCard(Map<String, dynamic> producto) {
    final double precioOriginal = (producto['precio'] as num).toDouble();
    final double precioLiquidacion = producto['precioLiquidacion'] is num 
        ? (producto['precioLiquidacion'] as num).toDouble() 
        : precioOriginal;
    
    // Calcular el porcentaje de descuento
    final double ahorro = precioOriginal - precioLiquidacion;
    final int porcentaje = precioOriginal > 0 
        ? ((ahorro / precioOriginal) * 100).round() 
        : 0;
    
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
  void _mostrarMensajePromocionConAnimacion(String nombreProducto, String mensaje) {
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
    final double precio = producto['precioVenta'] ?? 
        (producto['enLiquidacion'] == true && producto['precioLiquidacion'] != null 
            ? (producto['precioLiquidacion'] as num).toDouble() 
            : (producto['precio'] as num).toDouble());
    final int stockDisponible = producto['stockDisponible'] ?? producto['stock'] ?? 0;
    final bool stockLimitado = cantidad >= stockDisponible;
    final bool promocionActivada = producto['promocionActivada'] == true;
    final bool tienePromocionGratis = producto['tienePromocionGratis'] ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: promocionActivada && tienePromocionGratis
            ? const BorderSide(color: Color(0xFF2E7D32), width: 1.5) // Borde verde oscuro para productos con promoción
            : (stockLimitado 
                ? const BorderSide(color: Colors.orange)
                : BorderSide.none),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                // Icono de regalo para productos con promoción activa
                if (promocionActivada && tienePromocionGratis)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.gift,
                        size: 14,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    producto['nombre'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: promocionActivada && tienePromocionGratis ? const Color(0xFF2E7D32) : null,
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
            if (promocionActivada && tienePromocionGratis)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: <Widget>[
                    const FaIcon(
                      FontAwesomeIcons.circleInfo,
                      size: 12,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'El servidor aplicará las unidades gratis automáticamente',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
            ),
          ],
        ),
      ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Text(
                  'S/ ${precio.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: promocionActivada && tienePromocionGratis ? FontWeight.bold : null,
                    color: promocionActivada && tienePromocionGratis ? const Color(0xFF2E7D32) : null,
                  ),
                ),
                const Spacer(),
                
                // Control de cantidad con indicador de stock
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: stockLimitado ? Colors.orange.withOpacity(0.2) : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: <Widget>[
                      // Botón para disminuir cantidad
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16),
                        onPressed: () => _cambiarCantidad(index, cantidad - 1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      
                      // Cantidad actual
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '$cantidad',
                          style: TextStyle(
                            color: stockLimitado ? Colors.orange : null,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      // Botón para aumentar cantidad (deshabilitado si se alcanza el stock)
                      IconButton(
                        icon: Icon(
                          Icons.add, 
                          size: 16,
                          color: stockLimitado ? Colors.orange.withOpacity(0.5) : null,
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
            
            // Mostrar información de stock disponible y promociones
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Disponible: $stockDisponible',
                  style: TextStyle(
                    fontSize: 12,
                    color: stockLimitado ? Colors.orange : Colors.green,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                
                // Solo mostrar el botón si el producto tiene promociones
                if (producto['enLiquidacion'] == true || 
                    producto['tienePromocionGratis'] == true || 
                    producto['tieneDescuentoPorcentual'] == true)
                  TextButton.icon(
                    onPressed: () => _mostrarDetallesPromocion(producto), 
                    icon: const FaIcon(FontAwesomeIcons.tags, size: 12),
                    label: const Text('Ver promociones', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
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
      setState(() {
        _isLoading = true;
        _loadingMessage = 'Verificando disponibilidad de stock...';
      });
      
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
          setState(() {
            _isLoading = false;
            _loadingMessage = '';
          });
          
          if (!mounted) {
            return;
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error con el ID del producto ${producto['nombre']}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        final int cantidad = producto['cantidad'];
        
        // Actualizar mensaje de loading
        if (mounted) {
          setState(() {
            _loadingMessage = 'Verificando stock de ${producto['nombre']}...';
          });
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
          setState(() {
            _isLoading = false;
            _loadingMessage = '';
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Stock insuficiente para ${productoActual.nombre}. Disponible: ${productoActual.stock}'),
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
        setState(() {
          _isLoading = false;
          _loadingMessage = '';
        });
        
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
    // Mostrar indicador de carga con más contexto para reducir ansiedad
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Enviando datos al servidor...';
    });

    try {
      // Actualizar mensaje para proporcionar retroalimentación del progreso
      if (mounted) {
        setState(() {
          _loadingMessage = 'Preparando detalles de la venta...';
        });
      }
      
      // Convertir los productos de la venta al formato esperado por la API
      final List<DetalleProforma> detalles = _productosVenta.map((Map<String, dynamic> producto) {
        // Manejar caso donde id puede ser entero o cadena
        final int productoId = producto['id'] is int ? 
            producto['id'] : int.parse(producto['id'].toString());
        
        // Usar el precio con descuentos aplicados si existe
        final double precioUnitario = producto['precioVenta'] ?? 
            (producto['enLiquidacion'] == true && producto['precioLiquidacion'] != null 
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
        setState(() {
          _loadingMessage = 'Comunicando con el servidor...';
        });
      }
      
      // Llamar a la API para crear la proforma - esta es la parte que potencialmente demora
      final Map<String, dynamic> respuesta = await _proformasApi.createProformaVenta(
        sucursalId: _sucursalId,
        nombre: 'Proforma ${_clienteSeleccionado!.denominacion}',
        total: _totalVenta,
        detalles: detalles,
        empleadoId: _empleadoId,
        clienteId: _clienteSeleccionado!.id, // Usar el ID del cliente seleccionado
      );
      
      if (!mounted) {
        return;
      }
      
      // Actualizar mensaje para proporcionar retroalimentación del progreso
      setState(() {
        _loadingMessage = 'Procesando respuesta...';
      });
      
      // Convertir la respuesta a un objeto estructurado
      final Proforma? proformaCreada = _proformasApi.parseProformaVenta(respuesta);
      
      // Recargar productos para reflejar el stock actualizado por el backend
      _productosLoaded = false;
      
      if (mounted) {
        setState(() {
          _loadingMessage = 'Actualizando inventario...';
        });
      _cargarProductos();
      }
      
      if (!mounted) {
        return;
      }
      
      // Cambiar estado antes de mostrar el diálogo
      setState(() {
        _isLoading = false;
        _loadingMessage = '';
      });
      
      // Mostrar diálogo de confirmación
      await showDialog(
        context: context,
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
                _limpiarVenta();
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      
      // Resetear estado de carga
      setState(() {
        _isLoading = false;
        _loadingMessage = '';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear la proforma: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Ir a la pantalla de historial de ventas
  void _irAHistorial() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (BuildContext context) => const HistorialVentasColabScreen()),
    );
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
    
    final String? codigoBarras = await Navigator.push(
      context,
      MaterialPageRoute(builder: (BuildContext context) => const BarcodeColabScreen()),
    );

    if (!mounted) {
      return;
    }

    if (codigoBarras != null) {
      // Buscar el producto por código de barras en la lista de productos
      final Map<String, dynamic> productoEncontrado = _productos.firstWhere(
        (Map<String, dynamic> p) => p['codigo'] == codigoBarras,
        orElse: () => <String, dynamic>{},
      );
      
      if (productoEncontrado.isNotEmpty) {
        _agregarProducto(productoEncontrado);
        if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Producto agregado: ${productoEncontrado['nombre']}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Si no se encuentra el producto, mostrar mensaje de error
        if (!mounted) {
          return;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto no encontrado con ese código'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcular el total de la venta
    final double total = _totalVenta;
    
    return _buildLoadingOverlay(
      Scaffold(
        appBar: AppBar(
          title: const Text('Ventas'),
          actions: <Widget>[
          IconButton(
              icon: const FaIcon(FontAwesomeIcons.clockRotateLeft),
            tooltip: 'Historial de Ventas',
            onPressed: _irAHistorial,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
            // Sección de cliente
            Card(
              margin: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                
              ),
              child: ListTile(
                leading: const FaIcon(FontAwesomeIcons.user),
                title: Text(
                  _clienteSeleccionado == null ? 'Cliente' : _clienteSeleccionado!.denominacion,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: _clienteSeleccionado == null 
                    ? const Text('Seleccionar Cliente') 
                    : Text('Doc: ${_clienteSeleccionado!.numeroDocumento}'),
                trailing: IconButton(
                  icon: const FaIcon(FontAwesomeIcons.userPlus),
                  onPressed: _mostrarDialogoClientes,
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
                  _productosVenta.isEmpty
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
                          padding: const EdgeInsets.only(bottom: 100), // Espacio para el botón de finalizar
                  itemCount: _productosVenta.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, dynamic> producto = _productosVenta[index];
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
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5),
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
                              'S/ ${total.toStringAsFixed(2)}',
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
                          onPressed: _productosVenta.isEmpty 
                              ? null 
                              : _limpiarVenta,
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
                      onPressed: _productosVenta.isEmpty || _clienteSeleccionado == null 
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
