import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/ventas_transfer_service.dart';
import 'barcode_colab.dart';
import 'historial_ventas_colab.dart';

class VentasColabScreen extends StatefulWidget {
  const VentasColabScreen({super.key});

  @override
  State<VentasColabScreen> createState() => _VentasColabScreenState();
}

class _VentasColabScreenState extends State<VentasColabScreen> {
  bool _isLoading = false;
  
  // Lista de productos en la venta actual
  final List<Map<String, dynamic>> _productosVenta = [];
  
  // Cliente seleccionado
  Map<String, dynamic>? _clienteSeleccionado;
  
  // Método de pago seleccionado
  String _metodoPago = 'EFECTIVO';
  
  // Lista de métodos de pago disponibles
  final List<String> _metodosPago = ['EFECTIVO', 'TARJETA', 'TRANSFERENCIA', 'YAPE'];
  
  // Controlador para el campo de búsqueda de productos
  final TextEditingController _searchController = TextEditingController();
  
  // Datos de ejemplo para clientes
  final List<Map<String, dynamic>> _clientes = [
    {'id': 1, 'nombre': 'Juan Pérez', 'documento': '12345678', 'telefono': '987654321'},
    {'id': 2, 'nombre': 'María García', 'documento': '87654321', 'telefono': '123456789'},
    {'id': 3, 'nombre': 'Carlos López', 'documento': '45678912', 'telefono': '789456123'},
  ];
  
  // Datos de ejemplo para productos
  final List<Map<String, dynamic>> _productos = [
    {
      'id': 1,
      'codigo': 'P001',
      'nombre': 'Casco MT Thunder',
      'precio': 299.99,
      'stock': 10,
      'categoria': 'Cascos',
    },
    {
      'id': 2,
      'codigo': 'P002',
      'nombre': 'Aceite Motul 5100',
      'precio': 89.99,
      'stock': 20,
      'categoria': 'Lubricantes',
    },
    {
      'id': 3,
      'codigo': 'P003',
      'nombre': 'Kit de Frenos Brembo',
      'precio': 850.00,
      'stock': 5,
      'categoria': 'Frenos',
    },
    {
      'id': 4,
      'codigo': 'P004',
      'nombre': 'Amortiguador YSS',
      'precio': 599.99,
      'stock': 8,
      'categoria': 'Suspensión',
    },
  ];
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      _metodoPago = 'EFECTIVO';
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
                child: ListView.builder(
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
        ],
      ),
    );
  }
  
  // Escanear producto con código de barras
  Future<void> _escanearProducto() async {
    final producto = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeColabScreen()),
    );

    if (producto != null) {
      _agregarProducto(producto);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Producto agregado: ${producto['nombre']}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  // Finalizar venta
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
    
    // Enviar la venta a la computadora
    _enviarVentaAComputadora();
  }
  
  // Método para enviar la venta a la computadora
  Future<void> _enviarVentaAComputadora() async {
    setState(() => _isLoading = true);
    
    try {
      // Preparar los datos de la venta
      final ventaData = {
        'cliente': _clienteSeleccionado,
        'productos': _productosVenta,
        'metodoPago': _metodoPago,
        'total': _totalVenta,
        'fecha': DateTime.now().toIso8601String(),
      };
      
      // Utilizar el servicio para enviar la venta a la computadora
      final ventasTransferService = VentasTransferService();
      final resultado = await ventasTransferService.enviarVentaAComputadora(ventaData);
      
      if (!mounted) return;
      
      if (resultado) {
        // Mostrar diálogo de confirmación
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Venta Enviada a Caja'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.send_to_mobile,
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
                Text('Método de pago: $_metodoPago'),
                const SizedBox(height: 16),
                const Text(
                  'La venta ha sido enviada a la caja para su procesamiento.',
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
      } else {
        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al enviar la venta a la caja'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
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
                          width: 1,
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
                const SizedBox(width: 16),
                // Selección de método de pago
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[700]!,
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _metodoPago,
                      dropdownColor: const Color(0xFF2D2D2D),
                      style: const TextStyle(color: Colors.white),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      items: _metodosPago.map((String metodo) {
                        return DropdownMenuItem<String>(
                          value: metodo,
                          child: Text(metodo),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _metodoPago = newValue;
                          });
                        }
                      },
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
                    onPressed: _escanearProducto,
                  ),
                ),
                const SizedBox(width: 8),
                // Botón para buscar producto
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const FaIcon(
                      FontAwesomeIcons.magnifyingGlass,
                      size: 16,
                    ),
                    label: const Text('Buscar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                    onPressed: _mostrarDialogoProductos,
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
