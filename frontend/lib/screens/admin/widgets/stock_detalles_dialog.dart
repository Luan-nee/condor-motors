import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../main.dart' show api; // Importamos el API global
import '../../../models/producto.model.dart';
import '../utils/stock_utils.dart';

/// Diálogo para mostrar los detalles de stock de un producto
class StockDetallesDialog extends StatefulWidget {
  final Producto producto;
  final String sucursalId;
  final String sucursalNombre;

  const StockDetallesDialog({
    super.key,
    required this.producto,
    required this.sucursalId,
    required this.sucursalNombre,
  });

  @override
  State<StockDetallesDialog> createState() => _StockDetallesDialogState();
}

class _StockDetallesDialogState extends State<StockDetallesDialog> {
  bool _isUpdating = false;
  String? _error;
  late int _stockActual;
  late int _stockMinimo;
  late int _stockNuevo;
  late TextEditingController _stockController;
  bool _mostrarAdvertencia = false;

  // Variables para controlar la aparición de botones rápidos
  int _contadorClicsAumentar = 0;
  bool _mostrarBotonesRapidos = false;

  @override
  void initState() {
    super.initState();
    _stockActual = widget.producto.stock;
    _stockMinimo = widget.producto.stockMinimo ?? 0;
    _stockNuevo = _stockActual;
    _stockController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _actualizarStock() async {
    if (_stockNuevo == _stockActual) return;

    if (_stockNuevo < _stockActual) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Por seguridad, solo se permite agregar stock mediante entradas, no reducirlo'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _stockNuevo = _stockActual;
      });
      return;
    }

    final int cantidadAAgregar = _stockNuevo - _stockActual;

    setState(() {
      _isUpdating = true;
      _error = null;
    });

    try {
      // Usar la API real para agregar stock
      await api.productos.agregarStock(
        sucursalId: widget.sucursalId,
        productoId: widget.producto.id,
        cantidad: cantidadAAgregar,
      );

      if (!mounted) return;

      setState(() {
        _stockActual = _stockNuevo;
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = 'Error al actualizar stock: ${e.toString()}';
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor =
        StockUtils.getStockStatusColor(_stockActual, _stockMinimo);
    final statusIcon =
        StockUtils.getStockStatusIcon(_stockActual, _stockMinimo);
    final statusText =
        StockUtils.getStockStatusText(_stockActual, _stockMinimo);

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 10,
      child: Container(
        width: 800,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título y cierre
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detalle de Stock: ${widget.producto.nombre}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Cerrar',
                ),
              ],
            ),

            const SizedBox(height: 8),

            Divider(color: Colors.white.withOpacity(0.2)),

            const SizedBox(height: 16),

            // Contenido principal con ScrollView
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del producto y stock
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Detalles del producto
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoSection(
                                'Información del Producto',
                                FontAwesomeIcons.box,
                                [
                                  _buildInfoRow('SKU', widget.producto.sku),
                                  _buildInfoRow(
                                      'Categoría', widget.producto.categoria),
                                  _buildInfoRow('Marca', widget.producto.marca),
                                  _buildInfoRow(
                                      'Sucursal', widget.sucursalNombre),
                                  if (widget.producto.descripcion != null)
                                    _buildInfoRow('Descripción',
                                        widget.producto.descripcion!),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Información de stock
                              _buildInfoSection(
                                'Información de Stock',
                                FontAwesomeIcons.chartLine,
                                [
                                  _buildInfoRow(
                                      'Stock Actual', _stockActual.toString(),
                                      color: statusColor),
                                  _buildInfoRow(
                                      'Stock Mínimo', _stockMinimo.toString()),
                                  _buildInfoRow('Estado', statusText,
                                      icon: statusIcon, color: statusColor),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Ajuste de stock
                        Expanded(
                          flex: 4,
                          child: _buildAjusteStock(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sección de información con título y lista de filas
  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FaIcon(
              icon,
              size: 16,
              color: const Color(0xFFE31E24),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  // Fila de información con etiqueta y valor
  Widget _buildInfoRow(String label, String value,
      {IconData? icon, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (icon != null) ...[
            FaIcon(
              icon,
              size: 14,
              color: color ?? Colors.white70,
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? Colors.white,
                fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para ajustar el stock
  Widget _buildAjusteStock() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Agregar Stock',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),

          // Valor actual y nuevo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  const Text(
                    'Actual',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _stockActual.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              const Icon(
                Icons.arrow_forward,
                color: Colors.white30,
              ),
              const SizedBox(width: 20),
              Column(
                children: [
                  const Text(
                    'Nuevo',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _stockNuevo.toString(),
                    style: TextStyle(
                      color: _stockNuevo != _stockActual
                          ? const Color(0xFFE31E24)
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Campo para ingresar manualmente la cantidad
          TextField(
            controller: _stockController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Cantidad a agregar',
              hintText: 'Ingrese la cantidad',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              labelStyle: const TextStyle(color: Colors.white70),
              hintStyle: const TextStyle(color: Colors.white30),
              errorText:
                  _mostrarAdvertencia ? 'Valor muy alto, ¿está seguro?' : null,
            ),
            onChanged: (value) {
              // Validar que sea un número
              if (value.isEmpty) {
                setState(() {
                  _stockNuevo = _stockActual;
                  _mostrarAdvertencia = false;
                });
                return;
              }

              final cantidad = int.tryParse(value);
              if (cantidad != null) {
                final nuevoStock = _stockActual + cantidad;
                setState(() {
                  _stockNuevo = nuevoStock;
                  _mostrarAdvertencia = cantidad > 100;
                });
              }
            },
          ),

          const SizedBox(height: 16),

          // Controles para ajustar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón para reducir la cantidad a agregar
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.circleMinus,
                    color: Colors.white),
                onPressed: _isUpdating || (_stockNuevo <= _stockActual)
                    ? null
                    : () {
                        setState(() {
                          _stockNuevo--;
                          _stockController.text =
                              (_stockNuevo - _stockActual).toString();
                          _mostrarAdvertencia =
                              (_stockNuevo - _stockActual) > 100;
                          // Reiniciar contador de clics cuando reducimos
                          _contadorClicsAumentar = 0;
                          _mostrarBotonesRapidos = false;
                        });
                      },
                tooltip: 'Reducir cantidad a agregar',
              ),
              const SizedBox(width: 16),
              // Botón para aumentar la cantidad a agregar
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.circlePlus,
                    color: Colors.white),
                onPressed: _isUpdating
                    ? null
                    : () {
                        setState(() {
                          _stockNuevo++;
                          _stockController.text =
                              (_stockNuevo - _stockActual).toString();
                          _mostrarAdvertencia =
                              (_stockNuevo - _stockActual) > 100;

                          // Incrementar contador de clics para mostrar botones rápidos
                          _contadorClicsAumentar++;

                          // Después de 4 clics, mostrar botones rápidos
                          if (_contadorClicsAumentar >= 5 &&
                              !_mostrarBotonesRapidos) {
                            _mostrarBotonesRapidos = true;
                          }
                        });
                      },
                tooltip: 'Aumentar cantidad',
              ),
            ],
          ),

          // Botones de incremento rápido (aparecen después de 4 clics)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _mostrarBotonesRapidos ? 50 : 0,
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: _mostrarBotonesRapidos ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _mostrarBotonesRapidos
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Botón +5
                          ElevatedButton.icon(
                            icon: const FaIcon(
                              FontAwesomeIcons.plus,
                              size: 12,
                            ),
                            label: const Text('+5'),
                            onPressed: _isUpdating
                                ? null
                                : () {
                                    setState(() {
                                      _stockNuevo += 5;
                                      _stockController.text =
                                          (_stockNuevo - _stockActual)
                                              .toString();
                                      _mostrarAdvertencia =
                                          (_stockNuevo - _stockActual) > 100;
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3E3E3E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Botón +10
                          ElevatedButton.icon(
                            icon: const FaIcon(
                              FontAwesomeIcons.plus,
                              size: 12,
                            ),
                            label: const Text('+10'),
                            onPressed: _isUpdating
                                ? null
                                : () {
                                    setState(() {
                                      _stockNuevo += 10;
                                      _stockController.text =
                                          (_stockNuevo - _stockActual)
                                              .toString();
                                      _mostrarAdvertencia =
                                          (_stockNuevo - _stockActual) > 100;
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3E3E3E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          const SizedBox(height: 24),

          // Botón para guardar cambios
          Row(
            children: [
              // Botón para cancelar
              if (_stockNuevo != _stockActual)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton(
                      onPressed: _isUpdating
                          ? null
                          : () {
                              setState(() {
                                _stockNuevo = _stockActual;
                                _stockController.text = '0';
                                _mostrarAdvertencia = false;
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ),

              // Botón para guardar
              Expanded(
                flex: _stockNuevo != _stockActual ? 2 : 1,
                child: ElevatedButton(
                  onPressed: _isUpdating || _stockNuevo == _stockActual
                      ? null
                      : _actualizarStock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31E24),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    disabledBackgroundColor: Colors.grey.shade800,
                    disabledForegroundColor: Colors.white54,
                  ),
                  child: _isUpdating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Agregar Stock'),
                ),
              ),
            ],
          ),

          // Mensaje de advertencia para valores grandes
          if (_mostrarAdvertencia)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.triangleExclamation,
                    color: Color(0xFFE31E24),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Está agregando una cantidad considerable. Verifique antes de confirmar.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
