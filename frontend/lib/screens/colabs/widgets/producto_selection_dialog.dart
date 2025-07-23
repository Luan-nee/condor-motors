import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductoSelectionDialog extends StatefulWidget {
  final List<DetalleProducto> productosSeleccionados;
  final String sucursalId;

  const ProductoSelectionDialog({
    super.key,
    required this.productosSeleccionados,
    required this.sucursalId,
  });

  @override
  State<ProductoSelectionDialog> createState() =>
      _ProductoSelectionDialogState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<DetalleProducto>(
          'productosSeleccionados', productosSeleccionados))
      ..add(StringProperty('sucursalId', sucursalId));
  }
}

class _ProductoSelectionDialogState extends State<ProductoSelectionDialog> {
  bool _isLoading = true;
  String? _error;
  final List<Producto> _productos = [];
  final TextEditingController _searchController = TextEditingController();
  final Map<int, int> _cantidades = {};

  @override
  void initState() {
    super.initState();
    _loadProductos();
    // Inicializar cantidades con productos ya seleccionados
    for (final producto in widget.productosSeleccionados) {
      _cantidades[producto.id] = producto.cantidad;
    }
  }

  Future<void> _loadProductos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Cargar productos desde la API
      // _productos = await api.productos.getProductosPorSucursal(widget.sucursalId);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Producto> _getFilteredProductos() {
    final String query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      return _productos;
    }

    return _productos
        .where((p) =>
            p.nombre.toLowerCase().contains(query) ||
            p.sku.toLowerCase().contains(query) ||
            p.categoria.toLowerCase().contains(query) ||
            p.marca.toLowerCase().contains(query))
        .toList();
  }

  void _updateCantidad(int productoId, int cantidad) {
    setState(() {
      if (cantidad > 0) {
        _cantidades[productoId] = cantidad;
      } else {
        _cantidades.remove(productoId);
      }
    });
  }

  List<DetalleProducto> _getProductosSeleccionados() {
    return _cantidades.entries.map((entry) {
      final producto = _productos.firstWhere((p) => p.id == entry.key);
      return DetalleProducto(
        id: producto.id,
        nombre: producto.nombre,
        codigo: producto.sku,
        cantidad: entry.value,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Optimizado: calcular lista filtrada una sola vez
    final List<Producto> filteredProductos = _getFilteredProductos();
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
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
              children: <Widget>[
                const FaIcon(
                  FontAwesomeIcons.boxOpen,
                  size: 20,
                  color: Color(0xFFE31E24),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Seleccionar Productos',
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE31E24)),
                ),
                filled: true,
                fillColor: const Color(0xFF2D2D2D),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Flexible(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const FaIcon(
                              FontAwesomeIcons.triangleExclamation,
                              color: Colors.orange,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error al cargar productos:\n$_error',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white54),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: _loadProductos,
                              icon: const FaIcon(
                                FontAwesomeIcons.arrowsRotate,
                                size: 14,
                              ),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _productos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                FaIcon(
                                  FontAwesomeIcons.boxOpen,
                                  size: 48,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay productos disponibles',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredProductos.length,
                            itemBuilder: (context, index) {
                              final producto = filteredProductos[index];
                              final int cantidad =
                                  _cantidades[producto.id] ?? 0;
                              final bool isSelected = cantidad > 0;

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D2D2D),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFE31E24)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(
                                    producto.nombre,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        '${producto.sku} - ${producto.marca}',
                                        style:
                                            TextStyle(color: Colors.grey[400]),
                                      ),
                                      Text(
                                        'Stock: ${producto.stock}',
                                        style: TextStyle(
                                          color: producto.tieneStockBajo()
                                              ? Colors.orange
                                              : Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE31E24)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const FaIcon(
                                      FontAwesomeIcons.box,
                                      color: Color(0xFFE31E24),
                                      size: 16,
                                    ),
                                  ),
                                  trailing: SizedBox(
                                    width: 120,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: <Widget>[
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          color: Colors.white54,
                                          onPressed: cantidad > 0
                                              ? () => _updateCantidad(
                                                  producto.id, cantidad - 1)
                                              : null,
                                        ),
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFFE31E24)
                                                    .withValues(alpha: 0.1)
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              cantidad.toString(),
                                              style: TextStyle(
                                                color: isSelected
                                                    ? const Color(0xFFE31E24)
                                                    : Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          color: Colors.white54,
                                          onPressed: () => _updateCantidad(
                                              producto.id, cantidad + 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Productos seleccionados: ${_cantidades.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _cantidades.isEmpty
                          ? null
                          : () => Navigator.pop(
                              context, _getProductosSeleccionados()),
                      icon: const FaIcon(FontAwesomeIcons.check, size: 16),
                      label: const Text('Confirmar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31E24),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                      ),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
