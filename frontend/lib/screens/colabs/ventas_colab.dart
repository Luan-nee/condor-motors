import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/index.api.dart';
import '../../main.dart' show api;
import 'barcode_colab.dart';
import 'historial_ventas_colab.dart';

class VentasColabScreen extends StatefulWidget {
  const VentasColabScreen({super.key});

  @override
  State<VentasColabScreen> createState() => _VentasColabScreenState();
}

class _VentasColabScreenState extends State<VentasColabScreen> {
  bool _isLoading = false;
  late final StocksApi _stocksApi;
  late final ProformaVentaApi _proformasApi;
  String _sucursalId = '9'; // Valor por defecto, se actualizará al inicializar
  int _empleadoId = 1; // Valor por defecto, se actualizará al inicializar
  List<Map<String, dynamic>> _productos = []; // Lista de productos obtenidos de la API
  bool _productosLoaded = false; // Flag para controlar si ya se cargaron los productos
  
  // Lista de productos en la venta actual
  final List<Map<String, dynamic>> _productosVenta = [];
  
  // Cliente seleccionado
  Map<String, dynamic>? _clienteSeleccionado;
  
  // Controlador para el campo de búsqueda de productos
  final TextEditingController _searchController = TextEditingController();
  
  // Datos de ejemplo para clientes
  final List<Map<String, dynamic>> _clientes = [
    {'id': 1, 'nombre': 'Juan Pérez', 'documento': '12345678', 'telefono': '987654321'},
    {'id': 2, 'nombre': 'María García', 'documento': '87654321', 'telefono': '123456789'},
    {'id': 3, 'nombre': 'Carlos López', 'documento': '45678912', 'telefono': '789456123'},
  ];
  
  @override
  void initState() {
    super.initState();
    _stocksApi = api.stocks;
    _proformasApi = api.proformas;
    
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
      // Cargar productos después de configurar la sucursal
      await _cargarProductos();
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Cargar productos desde la API
  Future<void> _cargarProductos() async {
    if (_productosLoaded) return; // Evitar cargar múltiples veces
    
    setState(() => _isLoading = true);
    
    try {
      debugPrint('Cargando productos para sucursal ID: $_sucursalId (Sucursal del vendedor)');
      
      final stocksResponse = await _stocksApi.getStockBySucursal(
        sucursalId: _sucursalId,
      );
      
      if (!mounted) return;
      
      final List<Map<String, dynamic>> productosFormateados = [];
      
      for (var item in stocksResponse) {
        // Convertir cada producto al formato esperado por la UI
        productosFormateados.add({
          'id': item['id'].toString(),
          'codigo': item['codigo'] ?? 'SIN-COD',
          'nombre': item['nombre'] ?? 'Producto sin nombre',
          'precio': (item['precioVenta'] ?? 0.0).toDouble(),
          'stock': item['stockActual'] ?? 0,
          'categoria': item['categoria'] is Map 
              ? item['categoria']['nombre'] 
              : (item['categoria'] as String? ?? 'Sin categoría'),
        });
      }
          
      setState(() {
        _productos = productosFormateados;
        _productosLoaded = true;
        _isLoading = false;
      });
      
      debugPrint('Productos cargados: ${_productos.length}');
    } catch (e) {
      if (!mounted) return;
      
      debugPrint('Error al cargar productos: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar productos: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      setState(() => _isLoading = false);
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Cliente'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _clientes.length,
            itemBuilder: (context, index) {
              final cliente = _clientes[index];
              return ListTile(
                title: Text(cliente['nombre']),
                subtitle: Text('Doc: ${cliente['documento']}'),
                onTap: () {
                  setState(() {
                    _clienteSeleccionado = cliente;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar creación de nuevo cliente
              Navigator.pop(context);
            },
            child: const Text('Nuevo Cliente'),
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
      builder: (context) => AlertDialog(
        title: const Text('Buscar Producto'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Buscar por nombre o código',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  // Actualizar la búsqueda en tiempo real
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading && !_productosLoaded
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _productos.isEmpty
                        ? const Center(
                            child: Text('No hay productos disponibles'),
                          )
                        : ListView.builder(
                            itemCount: _productos.length,
                            itemBuilder: (context, index) {
                              final producto = _productos[index];
                              // Filtrar por búsqueda
                              if (_searchController.text.isNotEmpty &&
                                  !producto['nombre'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) &&
                                  !producto['codigo'].toString().toLowerCase().contains(_searchController.text.toLowerCase())) {
                                return const SizedBox.shrink();
                              }
                              
                              return ListTile(
                                title: Text(producto['nombre']),
                                subtitle: Text('Código: ${producto['codigo']} - Stock: ${producto['stock']}'),
                                trailing: Text('S/ ${producto['precio'].toStringAsFixed(2)}'),
                                onTap: () {
                                  _agregarProducto(producto);
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
          if (!_productosLoaded || _isLoading)
            TextButton(
              onPressed: _cargarProductos,
              child: const Text('Recargar'),
            ),
        ],
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto agregado: ${productoEncontrado['nombre']}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Si no se encuentra el producto, mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto no encontrado: $codigoBarras'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Método para finalizar venta
  void _finalizarVenta() {
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
    
    // Crear proforma en lugar de enviar directamente
    _crearProformaVenta();
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
        nombre: 'Proforma ${_clienteSeleccionado!['nombre']}',
        total: _totalVenta,
        detalles: detalles,
        empleadoId: _empleadoId,
      );
      
      if (!mounted) return;
      
      // Convertir la respuesta a un objeto estructurado
      final proformaCreada = _proformasApi.parseProformaVenta(respuesta);
      
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
              Text('Cliente: ${_clienteSeleccionado!['nombre']}'),
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
              setState(() => _productosLoaded = false);
              _cargarProductos();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recargando productos...'),
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
          // Información del cliente y método de pago
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Selección de cliente
                Expanded(
                  child: InkWell(
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
                            child: Text(
                              _clienteSeleccionado != null
                                  ? _clienteSeleccionado!['nombre']
                                  : 'Seleccionar Cliente',
                              style: TextStyle(
                                color: _clienteSeleccionado != null
                                    ? Colors.white
                                    : Colors.white70,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Botones de acción
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Botón para escanear producto
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const FaIcon(
                      FontAwesomeIcons.barcode,
                      size: 16,
                    ),
                    label: const Text('Escanear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                    onPressed: _isLoading ? null : _escanearProducto,
                  ),
                ),
                const SizedBox(width: 8),
                // Botón para buscar producto
                Expanded(
                  child: ElevatedButton.icon(
                    icon: _isLoading && !_productosLoaded
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const FaIcon(
                            FontAwesomeIcons.magnifyingGlass,
                            size: 16,
                          ),
                    label: Text(_isLoading && !_productosLoaded ? 'Cargando...' : 'Buscar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                    onPressed: _isLoading ? null : _mostrarDialogoProductos,
                  ),
                ),
                const SizedBox(width: 8),
                // Botón para limpiar venta
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const FaIcon(
                      FontAwesomeIcons.trash,
                      size: 16,
                    ),
                    label: const Text('Limpiar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                    onPressed: _limpiarVenta,
                  ),
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
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(isMobile ? 8 : 16),
                        itemCount: _productosVenta.length,
                        itemBuilder: (context, index) {
                          final producto = _productosVenta[index];
                          final subtotal = producto['precio'] * producto['cantidad'];
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2D2D),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: Container(
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
                              title: Text(
                                producto['nombre'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Precio: S/ ${producto['precio'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Controles de cantidad
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    color: Colors.white70,
                                    onPressed: () => _cambiarCantidad(index, producto['cantidad'] - 1),
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
                                  ),
                                  const SizedBox(width: 8),
                                  // Subtotal
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'S/ ${subtotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () => _eliminarProducto(index),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Total y botón de finalizar venta
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
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
                  icon: const FaIcon(
                    FontAwesomeIcons.check,
                    size: 16,
                  ),
                  label: const Text('Finalizar Venta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  onPressed: _finalizarVenta,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
