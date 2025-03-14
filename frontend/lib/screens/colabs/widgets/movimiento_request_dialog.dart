import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Clase para simular la estructura de un movimiento
class MovimientoStock {
  final int id;
  final String tipo;
  final String estado;
  final int localOrigenId;
  final int localDestinoId;
  final String solicitanteId;
  final List<Map<String, dynamic>> detalles;
  final DateTime fechaSolicitud;
  final DateTime? fechaPreparacion;
  final DateTime? fechaDespacho;
  final DateTime? fechaRecepcion;
  final DateTime? fechaAnulacion;

  MovimientoStock({
    required this.id,
    required this.tipo,
    required this.estado,
    required this.localOrigenId,
    required this.localDestinoId,
    required this.solicitanteId,
    required this.detalles,
    required this.fechaSolicitud,
    this.fechaPreparacion,
    this.fechaDespacho,
    this.fechaRecepcion,
    this.fechaAnulacion,
  });
}

class MovimientoRequestDialog extends StatefulWidget {
  final Function(MovimientoStock) onSave;
  final String usuarioId;
  final int localId;

  const MovimientoRequestDialog({
    super.key,
    required this.onSave,
    required this.usuarioId,
    required this.localId,
  });

  @override
  State<MovimientoRequestDialog> createState() => _MovimientoRequestDialogState();
}

class _MovimientoRequestDialogState extends State<MovimientoRequestDialog> {
  final _cantidadController = TextEditingController();
  
  Map<String, dynamic>? _productoSeleccionado;
  String? _destinoSeleccionado;
  bool _isLoading = false;
  
  // Lista temporal de productos seleccionados
  final List<Map<String, dynamic>> _productosSeleccionados = [];
  
  // Datos de ejemplo para productos
  final List<Map<String, dynamic>> _productos = [
    {
      'id': 1,
      'codigo': 'CAS001',
      'nombre': 'Casco MT Thunder',
      'descripcion': 'Casco integral de alta seguridad',
      'precio': 299.99,
      'stock': 5,
      'stockMinimo': 10,
      'categoria': 'Cascos',
      'marca': 'MT Helmets',
      'estado': 'BAJO_STOCK',
    },
    {
      'id': 2,
      'codigo': 'ACE001',
      'nombre': 'Aceite Motul 5100',
      'descripcion': 'Aceite sintético 4T 15W50',
      'precio': 89.99,
      'stock': 0,
      'stockMinimo': 20,
      'categoria': 'Lubricantes',
      'marca': 'Motul',
      'estado': 'AGOTADO',
    },
    {
      'id': 3,
      'codigo': 'LLA001',
      'nombre': 'Llanta Pirelli Diablo',
      'descripcion': 'Llanta deportiva de alto rendimiento',
      'precio': 450.00,
      'stock': 8,
      'stockMinimo': 5,
      'categoria': 'Llantas',
      'marca': 'Pirelli',
      'estado': 'NORMAL',
    },
    {
      'id': 4,
      'codigo': 'FRE001',
      'nombre': 'Kit de Frenos Brembo',
      'descripcion': 'Kit completo de frenos de alta calidad',
      'precio': 850.00,
      'stock': 12,
      'stockMinimo': 8,
      'categoria': 'Frenos',
      'marca': 'Brembo',
      'estado': 'NORMAL',
    },
    {
      'id': 5,
      'codigo': 'SUS001',
      'nombre': 'Amortiguador YSS',
      'descripcion': 'Amortiguador de alto rendimiento',
      'precio': 599.99,
      'stock': 4,
      'stockMinimo': 6,
      'categoria': 'Suspensión',
      'marca': 'YSS',
      'estado': 'BAJO_STOCK',
    }
  ];
  
  // Lista de sucursales disponibles
  final List<Map<String, dynamic>> _sucursales = [
    {
      'id': 1,
      'nombre': 'Central Principal',
      'direccion': 'Av. La Marina 123, San Miguel',
      'telefono': '987654321',
      'tipo': 'central',
      'icon': FontAwesomeIcons.warehouse,
      'estado': true
    },
    {
      'id': 2,
      'nombre': 'Sucursal San Miguel',
      'direccion': 'Av. Universitaria 456, San Miguel',
      'telefono': '987654322',
      'tipo': 'sucursal',
      'icon': FontAwesomeIcons.store,
      'estado': true
    },
    {
      'id': 3,
      'nombre': 'Sucursal Los Olivos',
      'direccion': 'Av. Antúnez de Mayolo 789, Los Olivos',
      'telefono': '987654323',
      'tipo': 'sucursal',
      'icon': FontAwesomeIcons.store,
      'estado': true
    }
  ];
  
  // Sucursal actual
  String get _sucursalActual {
    final sucursal = _sucursales.firstWhere(
      (s) => s['id'] == widget.localId,
      orElse: () => _sucursales.first,
    );
    return sucursal['nombre'] as String;
  }
  
  List<Map<String, dynamic>> get _sucursalesDisponibles => _sucursales
      .where((sucursal) => sucursal['nombre'] != _sucursalActual)
      .toList();

  // Método para agregar un producto a la lista temporal
  void _agregarProducto() {
    if (_productoSeleccionado == null || _cantidadController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione un producto y especifique la cantidad'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cantidad = int.tryParse(_cantidadController.text);
    if (cantidad == null || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La cantidad debe ser un número mayor a cero'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar si el producto ya está en la lista
    final productoExistente = _productosSeleccionados.firstWhere(
      (p) => p['producto']['id'] == _productoSeleccionado!['id'],
      orElse: () => {},
    );

    setState(() {
      if (productoExistente.isNotEmpty) {
        // Actualizar cantidad si ya existe
        productoExistente['cantidad'] = cantidad;
      } else {
        // Agregar nuevo producto a la lista
        _productosSeleccionados.add({
          'producto': _productoSeleccionado!,
          'cantidad': cantidad,
        });
      }
      
      // Limpiar selección
      _productoSeleccionado = null;
      _cantidadController.clear();
    });
  }

  // Método para eliminar un producto de la lista temporal
  void _eliminarProducto(int index) {
    setState(() {
      _productosSeleccionados.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (_productosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe agregar al menos un producto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_destinoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione una sucursal destino'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Simular creación de movimiento
      await Future.delayed(const Duration(milliseconds: 800));
      
      final movimiento = MovimientoStock(
        id: DateTime.now().millisecondsSinceEpoch,
        tipo: 'TRASLADO',
        estado: 'PENDIENTE',
        localOrigenId: widget.localId,
        localDestinoId: int.parse(_destinoSeleccionado!),
        solicitanteId: widget.usuarioId,
        detalles: _productosSeleccionados.map((item) => {
          'producto_id': item['producto']['id'],
          'cantidad': item['cantidad'],
          'estado': 'PENDIENTE',
          'producto': item['producto'], // Incluir datos del producto para mostrar
        }).toList(),
        fechaSolicitud: DateTime.now(),
      );

      if (!mounted) return;
      
      // Notificar éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud creada correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Cerrar diálogo y retornar el movimiento creado
      Navigator.of(context).pop();
      widget.onSave(movimiento);
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear solicitud: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: isMobile ? double.infinity : 600,
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF2D2D2D),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.boxOpen,
                    color: Color(0xFFE31E24),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Nueva Solicitud',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Contenido
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información de origen y destino
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información de la Solicitud',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.warehouse,
                                size: 16,
                                color: Color(0xFFE31E24),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Origen: $_sucursalActual',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _destinoSeleccionado,
                            dropdownColor: const Color(0xFF2D2D2D),
                            decoration: const InputDecoration(
                              labelText: 'Sucursal Destino',
                              labelStyle: TextStyle(color: Colors.white54),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFFE31E24)),
                              ),
                              prefixIcon: FaIcon(
                                FontAwesomeIcons.store,
                                size: 16,
                                color: Color(0xFFE31E24),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            items: _sucursalesDisponibles.map((sucursal) {
                              return DropdownMenuItem(
                                value: sucursal['id'].toString(),
                                child: Text(sucursal['nombre'] as String),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _destinoSeleccionado = value);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selector de productos
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Productos a Solicitar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _agregarProducto,
                                icon: const FaIcon(
                                  FontAwesomeIcons.plus,
                                  size: 14,
                                  color: Color(0xFFE31E24),
                                ),
                                label: const Text(
                                  'Agregar',
                                  style: TextStyle(color: Color(0xFFE31E24)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _productoSeleccionado,
                            dropdownColor: const Color(0xFF2D2D2D),
                            decoration: const InputDecoration(
                              labelText: 'Seleccionar Producto',
                              labelStyle: TextStyle(color: Colors.white54),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFFE31E24)),
                              ),
                              prefixIcon: FaIcon(
                                FontAwesomeIcons.box,
                                size: 16,
                                color: Color(0xFFE31E24),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            items: _productos.map((producto) {
                              return DropdownMenuItem(
                                value: producto,
                                child: Text('${producto['codigo']} - ${producto['nombre']}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _productoSeleccionado = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _cantidadController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Cantidad',
                              labelStyle: TextStyle(color: Colors.white54),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFFE31E24)),
                              ),
                              prefixIcon: FaIcon(
                                FontAwesomeIcons.hashtag,
                                size: 16,
                                color: Color(0xFFE31E24),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lista de productos seleccionados
                    if (_productosSeleccionados.isNotEmpty) ...[
                      const Text(
                        'Productos Agregados',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(_productosSeleccionados.length, (index) {
                        final item = _productosSeleccionados[index];
                        final producto = item['producto'] as Map<String, dynamic>;
                        final cantidad = item['cantidad'] as int;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D2D2D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE31E24).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const FaIcon(
                                  FontAwesomeIcons.box,
                                  color: Color(0xFFE31E24),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      producto['nombre'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${producto['codigo']} - ${producto['marca']}',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE31E24).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$cantidad unidades',
                                  style: const TextStyle(
                                    color: Color(0xFFE31E24),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const FaIcon(
                                  FontAwesomeIcons.trash,
                                  color: Color(0xFFE31E24),
                                  size: 16,
                                ),
                                onPressed: () => _eliminarProducto(index),
                              ),
                            ],
                          ),
                        );
                      }),
                    ] else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.boxOpen,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'No hay productos agregados',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Botones de acción
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF2D2D2D),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _productosSeleccionados.isEmpty || _destinoSeleccionado == null
                        ? null
                        : _handleSubmit,
                    icon: _isLoading
                        ? Container(
                            width: 16,
                            height: 16,
                            margin: const EdgeInsets.only(right: 8),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const FaIcon(FontAwesomeIcons.paperPlane, size: 16),
                    label: Text(_isLoading ? 'Enviando...' : 'Enviar Solicitud'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }
} 