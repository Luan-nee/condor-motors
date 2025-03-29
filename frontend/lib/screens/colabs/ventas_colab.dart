import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/index.api.dart';
import '../../main.dart' show api;
import '../../models/cliente.model.dart'; // Importamos el modelo de Cliente
// Importamos la API de proformas para usar DetalleProforma
import 'barcode_colab.dart';
import 'historial_ventas_colab.dart';
import 'widgets/busqueda_producto.dart';

class VentasColabScreen extends StatefulWidget {
  const VentasColabScreen({super.key});

  @override
  State<VentasColabScreen> createState() => _VentasColabScreenState();
}

class _VentasColabScreenState extends State<VentasColabScreen> {
  bool _isLoading = false;
  late final ProductosApi _productosApi;
  late final ProformaVentaApi _proformasApi;
  late final ClientesApi _clientesApi; // Agregamos la API de clientes
  String _sucursalId = '9'; // Valor por defecto, se actualizará al inicializar
  int _empleadoId = 1; // Valor por defecto, se actualizará al inicializar
  List<Map<String, dynamic>> _productos = []; // Lista de productos obtenidos de la API
  bool _productosLoaded = false; // Flag para controlar si ya se cargaron los productos
  
  // Lista de productos en la venta actual
  final List<Map<String, dynamic>> _productosVenta = [];
  
  // Cliente seleccionado (cambiamos de Map a Cliente)
  Cliente? _clienteSeleccionado;
  
  // Lista de clientes cargados desde la API
  List<Cliente> _clientes = [];
  bool _clientesLoaded = false;
  
  // Controlador para el campo de búsqueda de productos
  final TextEditingController _searchController = TextEditingController();
  
  // Controlador para el campo de búsqueda de clientes
  final TextEditingController _clienteSearchController = TextEditingController();
  
  // Agregar las variables faltantes
  List<String> _categorias = ['Todas']; // Lista de categorías de productos
  bool _isLoadingProductos = false; // Flag para indicar si se están cargando productos
  
  @override
  void initState() {
    super.initState();
    _productosApi = api.productos;
    _proformasApi = api.proformas;
    _clientesApi = api.clientes; // Inicializamos la API de clientes
    
    // Configurar los datos iniciales y cargar productos
    _configurarDatosIniciales();
  }

  // Método para configurar los datos iniciales de manera asíncrona
  Future<void> _configurarDatosIniciales() async {
    setState(() => _isLoading = true);
    
    try {
      // Obtener el ID de sucursal del usuario autenticado usando await
      final userData = await api.authService.getUserData();
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
      await Future.wait([
        _cargarProductos(),
        _cargarClientes(),
      ]);
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _clienteSearchController.dispose(); // Eliminamos también el controlador de búsqueda de clientes
    super.dispose();
  }
  
  // Cargar productos desde la API usando ProductosApi
  Future<void> _cargarProductos() async {
    if (_productosLoaded) return; // Evitar cargar múltiples veces
    
    setState(() {
      _isLoading = true;
      _isLoadingProductos = true;
    });
    
    try {
      debugPrint('Cargando productos para sucursal ID: $_sucursalId (Sucursal del vendedor)');
      
      // Usar el método mejorado getProductosPorFiltros para obtener datos más relevantes
      final response = await _productosApi.getProductosPorFiltros(
        sucursalId: _sucursalId,
        stockPositivo: true, // Mostrar solo productos con stock disponible
        pageSize: 100, // Obtener más productos por página
      );
      
      if (!mounted) return;
      
      final List<Map<String, dynamic>> productosFormateados = [];
      final Set<String> categoriasSet = {};
      
      // Procesar la lista de productos obtenida
      for (var producto in response.items) {
        // Extraer categorías únicas
        if (producto.categoria.isNotEmpty) {
          categoriasSet.add(producto.categoria);
        }
        
        // Calcular el precio actual considerando liquidación
        final double precioActual = producto.liquidacion && producto.precioOferta != null
            ? producto.precioOferta!
            : producto.precioVenta;
        
        // Verificar promociones disponibles
        final bool enLiquidacion = producto.liquidacion;
        final bool tienePromocionGratis = producto.cantidadGratisDescuento != null && producto.cantidadGratisDescuento! > 0;
        final bool tieneDescuentoPorcentual = producto.cantidadMinimaDescuento != null && 
                                       producto.cantidadMinimaDescuento! > 0 &&
                                       producto.porcentajeDescuento != null && 
                                       producto.porcentajeDescuento! > 0;
        
        // Convertir cada producto al formato esperado por la UI
        productosFormateados.add({
          'id': producto.id.toString(),
          'codigo': producto.sku,
          'nombre': producto.nombre,
          'precio': producto.precioVenta,
          'precioOriginal': producto.precioVenta,
          'precioActual': precioActual,
          'stock': producto.stock,
          'categoria': producto.categoria,
          // Añadir datos de promociones
          'liquidacion': enLiquidacion,
          'precioLiquidacion': producto.precioOferta,
          'descuentoPorcentaje': producto.porcentajeDescuento,
          'cantidadMinima': producto.cantidadMinimaDescuento,
          'cantidadGratis': producto.cantidadGratisDescuento,
          // Flags para saber qué promociones tiene
          'enLiquidacion': enLiquidacion,
          'tienePromocionGratis': tienePromocionGratis,
          'tieneDescuentoPorcentual': tieneDescuentoPorcentual,
        });
      }
          
      setState(() {
        _productos = productosFormateados;
        _productosLoaded = true;
        _isLoading = false;
        _isLoadingProductos = false;
        _categorias = ['Todas', ...categoriasSet.toList()..sort()];
      });
      
      debugPrint('Productos cargados: ${_productos.length}');
      debugPrint('Categorías cargadas: ${_categorias.length - 1}');
    } catch (e) {
      if (!mounted) return;
      
      debugPrint('Error al cargar productos: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar productos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      setState(() {
        _isLoading = false;
        _isLoadingProductos = false;
      });
    }
  }
  
  // Cargar clientes desde la API usando ClientesApi
  Future<void> _cargarClientes() async {
    if (_clientesLoaded) return; // Evitar cargar múltiples veces
    
    setState(() => _isLoading = true);
    
    try {
      debugPrint('Cargando clientes desde la API...');
      
      // Obtener los clientes desde la API
      final clientesData = await _clientesApi.getClientes(
        pageSize: 100, // Obtener más clientes por página
        sortBy: 'denominacion', // Ordenar por nombre
      );
      
      if (!mounted) return;
      
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
    return _productosVenta.fold(0, (total, producto) => 
      total + (producto['precio'] * producto['cantidad']));
  }
  
  // Agregar producto a la venta
  void _agregarProducto(Map<String, dynamic> producto) {
    setState(() {
      // Verificar si el producto ya está en la venta
      final index = _productosVenta.indexWhere((p) => p['id'] == producto['id']);
      
      if (index >= 0) {
        // Si ya existe, incrementar la cantidad
        _productosVenta[index]['cantidad']++;
      } else {
        // Si no existe, agregarlo con cantidad 1
        _productosVenta.add({
          ...producto,
          'cantidad': 1,
        });
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
    
    setState(() {
      _productosVenta[index]['cantidad'] = cantidad;
    });
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Filtrar clientes según la búsqueda
          List<Cliente> clientesFiltrados = _clientes;
          
          if (_clienteSearchController.text.isNotEmpty) {
            final query = _clienteSearchController.text.toLowerCase();
            clientesFiltrados = _clientes.where((cliente) {
              return cliente.denominacion.toLowerCase().contains(query) || 
                     cliente.numeroDocumento.toLowerCase().contains(query);
            }).toList();
          }
          
          return AlertDialog(
            title: const Text('Seleccionar Cliente'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  // Campo de búsqueda
                  TextField(
                    controller: _clienteSearchController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar por nombre o documento',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) {
                      // Actualizar la búsqueda en tiempo real
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  // Lista de clientes
                  Expanded(
                    child: _isLoading && !_clientesLoaded
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : clientesFiltrados.isEmpty
                        ? const Center(
                            child: Text('No se encontraron clientes con esa búsqueda'),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: clientesFiltrados.length,
                            itemBuilder: (context, index) {
                              final cliente = clientesFiltrados[index];
                              return ListTile(
                                title: Text(cliente.denominacion),
                                subtitle: Text('Doc: ${cliente.numeroDocumento}'),
                                onTap: () {
                                  // Actualizar el cliente seleccionado
                                  this.setState(() {
                                    _clienteSeleccionado = cliente;
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
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
    final denominacionController = TextEditingController();
    final numeroDocumentoController = TextEditingController();
    final telefonoController = TextEditingController();
    final direccionController = TextEditingController();
    final correoController = TextEditingController();
    
    // Cerrar diálogo anterior
    Navigator.pop(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
        actions: [
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
                final nuevoCliente = await _clientesApi.createCliente({
                  'tipoDocumentoId': 1, // DNI por defecto
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
            children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                    onProductoSeleccionado: (producto) {
                                  Navigator.pop(context);
                      _agregarProducto(producto);
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
  
  // Widget auxiliar para mostrar chips de promociones
  Widget _buildPromoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  // Método para construir la información de promociones de un producto
  Widget _buildPromocionesInfo(Map<String, dynamic> producto) {
    // Verificar las promociones del producto
    final bool enLiquidacion = producto['enLiquidacion'] ?? false;
    final bool tienePromocionGratis = producto['tienePromocionGratis'] ?? false;
    final bool tieneDescuentoPorcentual = producto['tieneDescuentoPorcentual'] ?? false;
    
    // Si no hay promociones, no mostrar nada
    if (!enLiquidacion && !tienePromocionGratis && !tieneDescuentoPorcentual) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Wrap(
        spacing: 6,
        children: [
          if (enLiquidacion)
            _buildPromoChip('Liquidación', Colors.amber),
          if (tienePromocionGratis)
            _buildPromoChip(
              'Lleva ${producto['cantidadMinima']}, paga ${producto['cantidadMinima'] - producto['cantidadGratis']}',
              Colors.green
            ),
          if (tieneDescuentoPorcentual)
            _buildPromoChip(
              '${producto['descuentoPorcentaje']}% x ${producto['cantidadMinima']}+ unid.', 
              Colors.blue
              ),
            ],
          ),
    );
  }
  
  // Método para construir un elemento de la lista de productos en venta
  Widget _buildProductoVentaItem(BuildContext context, int index) {
    final producto = _productosVenta[index];
    final subtotal = producto['precio'] * producto['cantidad'];
    
    // Verificar si tiene liquidación para mostrar precio tachado
    final bool enLiquidacion = producto['enLiquidacion'] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono del producto
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.box,
                    color: Color(0xFF4CAF50),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Información del producto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto['nombre'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // Mostrar precio (con precio de liquidación si aplica)
                      Row(
                        children: [
                          if (enLiquidacion && producto['precioLiquidacion'] != null) ...[
                            Text(
                              'S/ ${producto['precio'].toStringAsFixed(2)}',
                              style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'S/ ${producto['precioLiquidacion'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ] else ...[
                            Text(
                              'S/ ${producto['precio'].toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.grey[300],
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      // Mostrar información de promociones
                      _buildPromocionesInfo(producto),
                    ],
                  ),
                ),
                
                // Controles de cantidad y eliminación
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Controles de cantidad
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: Colors.white70,
                          onPressed: () => _cambiarCantidad(index, producto['cantidad'] - 1),
                          iconSize: 20,
                        ),
                        Text(
                          '${producto['cantidad']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          color: Colors.white70,
                          onPressed: () => _cambiarCantidad(index, producto['cantidad'] + 1),
                          iconSize: 20,
                        ),
                      ],
                    ),
                    
                    // Subtotal
                    Text(
                      'S/ ${subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Botón eliminar
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _eliminarProducto(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Escanear producto con código de barras
  Future<void> _escanearProducto() async {
    // Asegurarse de que los productos estén cargados
    if (!_productosLoaded) {
      await _cargarProductos();
    }
    
    if (!mounted) return;
    
    final codigoBarras = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeColabScreen()),
    );

    if (!mounted) return;

    if (codigoBarras != null && codigoBarras is String) {
      // Buscar el producto por código de barras en la lista de productos
      final productoEncontrado = _productos.firstWhere(
        (p) => p['codigo'] == codigoBarras,
        orElse: () => {},
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Producto no encontrado: $codigoBarras'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  // Método para finalizar venta
  void _finalizarVenta() async {
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
    
    try {
      // Verificar stock de productos antes de crear la proforma
      for (var producto in _productosVenta) {
        final int productoId = int.parse(producto['id']);
        final int cantidad = producto['cantidad'];
        
        // Obtener producto actualizado para verificar stock
        final productoActual = await _productosApi.getProducto(
          sucursalId: _sucursalId,
          productoId: productoId,
          useCache: false, // No usar caché para obtener datos actualizados
        );
        
        if (!mounted) return;
        
        if (productoActual.stock < cantidad) {
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
    setState(() => _isLoading = true);
    
    try {
      // Convertir los productos de la venta al formato esperado por la API
      final List<DetalleProforma> detalles = _productosVenta.map((producto) {
        return DetalleProforma(
          productoId: int.parse(producto['id'].toString()),
          nombre: producto['nombre'],
          cantidad: producto['cantidad'],
          subtotal: producto['precio'] * producto['cantidad'],
          precioUnitario: producto['precio'],
        );
      }).toList();
      
      // Llamar a la API para crear la proforma
      final respuesta = await _proformasApi.createProformaVenta(
        sucursalId: _sucursalId,
        nombre: 'Proforma ${_clienteSeleccionado!.denominacion}',
        total: _totalVenta,
        detalles: detalles,
        empleadoId: _empleadoId,
        clienteId: _clienteSeleccionado!.id, // Usar el ID del cliente seleccionado
      );
      
      if (!mounted) return;
      
      // Convertir la respuesta a un objeto estructurado
      final proformaCreada = _proformasApi.parseProformaVenta(respuesta);
      
      // Actualizar stock de productos involucrados en la proforma
      await _actualizarStockProductos();
      
      if (!mounted) return;
      
      // Mostrar diálogo de confirmación
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Proforma Creada Exitosamente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              if (proformaCreada != null) ...[
                const SizedBox(height: 8),
                Text('Proforma ID: ${proformaCreada.id}'),
              ],
              const SizedBox(height: 16),
              const Text(
                'La proforma ha sido creada y podrá ser procesada en caja.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _limpiarVenta();
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear la proforma: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // Método para actualizar el stock de los productos después de crear la proforma
  Future<void> _actualizarStockProductos() async {
    try {
      for (var producto in _productosVenta) {
        final int productoId = int.parse(producto['id']);
        final int cantidad = producto['cantidad'];
        
        // Usar la API de productos para disminuir el stock
        await _productosApi.disminuirStock(
          sucursalId: _sucursalId,
          productoId: productoId,
          cantidad: cantidad,
          motivo: 'Proforma de venta generada',
        );
        
        debugPrint('Stock actualizado para producto ID $productoId: -$cantidad unidades');
      }
      
      // Recargar productos para reflejar el nuevo stock
      _productosLoaded = false;
      await _cargarProductos();
      
    } catch (e) {
      debugPrint('Error al actualizar stock de productos: $e');
      // No lanzamos excepción aquí para que no interrumpa el flujo de la creación de proforma
      // pero mostramos una notificación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Advertencia: No se pudo actualizar el stock de algunos productos: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
  
  // Ir a la pantalla de historial de ventas
  void _irAHistorial() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistorialVentasColabScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.cashRegister,
                size: 20,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Nueva Venta',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Botón para recargar productos
          IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.arrowsRotate,
              color: Colors.white,
              size: 20,
            ),
            tooltip: 'Recargar Productos',
            onPressed: () {
              setState(() {
                _productosLoaded = false;
                _clientesLoaded = false; // También recargar clientes
              });
              _cargarProductos();
              _cargarClientes();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recargando datos...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
          // Botón para ir al historial
          IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.clockRotateLeft,
              color: Colors.white,
              size: 20,
            ),
            tooltip: 'Historial de Ventas',
            onPressed: _irAHistorial,
          ),
        ],
      ),
      body: Column(
        children: [
          // Información del cliente y acciones principales
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                // Selección de cliente
                GestureDetector(
                    onTap: _mostrarDialogoClientes,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[700]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.user,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cliente',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                              _clienteSeleccionado != null
                                  ? _clienteSeleccionado!.denominacion
                                  : 'Seleccionar Cliente',
                              style: TextStyle(
                                color: _clienteSeleccionado != null
                                    ? Colors.white
                                    : Colors.white70,
                                  fontWeight: _clienteSeleccionado != null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            ),
                          ),
                          const Icon(
                          Icons.person_search,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Botones de acción principales
                Row(
              children: [
                    // Botón para escanear
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
                      foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                        icon: const FaIcon(FontAwesomeIcons.barcode, size: 16),
                        label: const Text('Escanear'),
                    onPressed: _isLoading ? null : _escanearProducto,
                  ),
                ),
                const SizedBox(width: 8),
                    // Botón para buscar
                Expanded(
                      flex: 2,
                  child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: _isLoadingProductos
                        ? const SizedBox(
                                width: 16, height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                            : const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 16),
                        label: Text(_isLoadingProductos ? 'Cargando...' : 'Buscar Productos'),
                    onPressed: _isLoading ? null : _mostrarDialogoProductos,
                  ),
                ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de productos en la venta
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                    ),
                  )
                : _productosVenta.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.cartShopping,
                              size: 48,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay productos en la venta',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Escanea o busca productos para agregarlos',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2196F3),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 16),
                              label: const Text('Buscar Productos'),
                              onPressed: _mostrarDialogoProductos,
                                      ),
                                    ],
                                  ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(isMobile ? 8 : 16),
                        itemCount: _productosVenta.length,
                        itemBuilder: _buildProductoVentaItem,
                      ),
          ),

          // Total y botones de acción
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                // Acciones secundarias
                if (_productosVenta.isNotEmpty)
                  Row(
                    children: [
                      // Botón para limpiar venta
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF424242),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const FaIcon(FontAwesomeIcons.trash, size: 14),
                          label: const Text('Limpiar'),
                          onPressed: _limpiarVenta,
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 12),
                
                // Total y botón finalizar
                Row(
              children: [
                // Total
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'S/ ${_totalVenta.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón de finalizar venta
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
