// Importamos el API global
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/providers/admin/stock.admin.provider.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Producto>('producto', producto))
      ..add(StringProperty('sucursalId', sucursalId))
      ..add(StringProperty('sucursalNombre', sucursalNombre));
  }
}

class _StockDetallesDialogState extends State<StockDetallesDialog> {
  bool _isUpdating = false;
  String? _error;
  late int _stockActual;
  late int _stockMinimo;
  late int _stockNuevo;
  late TextEditingController _stockController;
  bool _mostrarAdvertencia = false;
  late StockProvider _stockProvider;

  // Instancias de repositorios
  final ProductoRepository _productoRepository = ProductoRepository.instance;

  // Variables para controlar la aparición de botones rápidos
  int _contadorClicsAumentar = 0;
  bool _mostrarBotonesRapidos = false;

  // Nuevas variables para gestionar liquidación
  bool _enLiquidacion = false;
  late double _precioLiquidacion;
  late TextEditingController _precioLiquidacionController;
  bool _mostrarSeccionLiquidacion = false;

  @override
  void initState() {
    super.initState();
    _stockActual = widget.producto.stock;
    _stockMinimo = widget.producto.stockMinimo ?? 0;
    _stockNuevo = _stockActual;
    _stockController = TextEditingController(text: '0');

    // Inicializar variables de liquidación
    _enLiquidacion = widget.producto.liquidacion;
    _precioLiquidacion = widget.producto.precioOferta ??
        widget.producto.precioVenta * 0.9; // Por defecto 10% descuento
    _precioLiquidacionController =
        TextEditingController(text: _precioLiquidacion.toStringAsFixed(2));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stockProvider = Provider.of<StockProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _stockController.dispose();
    _precioLiquidacionController.dispose();
    super.dispose();
  }

  Future<void> _actualizarStock() async {
    if (_stockNuevo == _stockActual) {
      return;
    }

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
      // Usar el repositorio en lugar de la API directamente
      await _productoRepository.agregarStock(
        sucursalId: widget.sucursalId,
        productoId: widget.producto.id,
        cantidad: cantidadAAgregar,
      );

      if (!mounted) {
        return;
      }

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
      if (!mounted) {
        return;
      }

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

  // Método para gestionar liquidación
  Future<void> _gestionarLiquidacion() async {
    // Validación de precio de liquidación
    if (_enLiquidacion) {
      final double? precioLiquidacion =
          double.tryParse(_precioLiquidacionController.text);
      if (precioLiquidacion == null || precioLiquidacion <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'El precio de liquidación debe ser un número válido mayor a 0'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Verificar que el precio de liquidación sea menor al precio de venta
      if (precioLiquidacion >= widget.producto.precioVenta) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'El precio de liquidación debe ser menor al precio de venta'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isUpdating = true;
      _error = null;
    });

    try {
      // Usar el repositorio en lugar de la API directamente
      final Producto? productoActualizado =
          await _productoRepository.setLiquidacion(
        sucursalId: widget.sucursalId,
        productoId: widget.producto.id,
        enLiquidacion: _enLiquidacion,
        precioLiquidacion: _enLiquidacion
            ? double.parse(_precioLiquidacionController.text)
            : null,
      );

      if (!mounted || productoActualizado == null) {
        return;
      }

      setState(() {
        _isUpdating = false;
      });

      // Actualizar la UI con los datos del producto actualizado
      Navigator.of(context)
          .pop(productoActualizado); // Devolver el producto actualizado

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_enLiquidacion
              ? 'Producto puesto en liquidación correctamente'
              : 'Liquidación removida correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Error al gestionar liquidación: ${e.toString()}';
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
    final Color statusColor = _getStockStatusColor(_stockActual, _stockMinimo);
    final IconData statusIcon = _getStockStatusIcon(_stockActual, _stockMinimo);
    final String statusText = _getStockStatusText(_stockActual, _stockMinimo);

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 10,
      child: Container(
        width: 800,
        height:
            580, // Aumentamos la altura para acomodar la sección de liquidación
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Título y cierre
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
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

            Divider(color: Colors.white.withValues(alpha: 0.2)),

            const SizedBox(height: 16),

            // Contenido principal con ScrollView
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Información del producto y stock
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Detalles del producto
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _buildInfoSection(
                                'Información del Producto',
                                FontAwesomeIcons.box,
                                <Widget>[
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
                                <Widget>[
                                  _buildInfoRow(
                                      'Stock Actual', _stockActual.toString(),
                                      color: statusColor),
                                  _buildInfoRow(
                                      'Stock Mínimo', _stockMinimo.toString()),
                                  _buildInfoRow('Estado', statusText,
                                      icon: statusIcon, color: statusColor),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Información de precios y liquidación
                              _buildInfoSection(
                                'Información de Precios',
                                FontAwesomeIcons.tag,
                                <Widget>[
                                  _buildInfoRow(
                                    'Precio Compra',
                                    widget.producto.getPrecioCompraFormateado(),
                                  ),
                                  _buildInfoRow(
                                    'Precio Venta',
                                    widget.producto.getPrecioVentaFormateado(),
                                  ),
                                  if (widget.producto.precioOferta != null)
                                    _buildInfoRow(
                                      'Precio Oferta',
                                      widget.producto
                                          .getPrecioOfertaFormateado()!,
                                      color: Colors.orange,
                                    ),
                                  _buildInfoRow(
                                    'Estado Liquidación',
                                    widget.producto.liquidacion
                                        ? 'En liquidación'
                                        : 'Precio normal',
                                    color: widget.producto.liquidacion
                                        ? Colors.orange
                                        : null,
                                    icon: widget.producto.liquidacion
                                        ? FontAwesomeIcons.fire
                                        : null,
                                  ),
                                  if (widget.producto.liquidacion)
                                    _buildInfoRow(
                                      'Precio Actual',
                                      widget.producto
                                          .getPrecioActualFormateado(),
                                      color: Colors.orange,
                                    ),
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

                    const SizedBox(height: 16),

                    // Sección para gestionar liquidación
                    _buildGestionLiquidacion(),
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
      children: <Widget>[
        Row(
          children: <Widget>[
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
        children: <Widget>[
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (icon != null) ...<Widget>[
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

  // Widget para gestionar liquidación
  Widget _buildGestionLiquidacion() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Título y botón para expandir/colapsar
          InkWell(
            onTap: () {
              setState(() {
                _mostrarSeccionLiquidacion = !_mostrarSeccionLiquidacion;
              });
            },
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.fire,
                    size: 16,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Gestión de Liquidación',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Icon(
                  _mostrarSeccionLiquidacion
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white70,
                ),
              ],
            ),
          ),

          // Contenido expandible
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _mostrarSeccionLiquidacion ? null : 0,
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: _mostrarSeccionLiquidacion ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _mostrarSeccionLiquidacion
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: 16),

                        // Descripción de liquidación
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Row(
                                children: <Widget>[
                                  FaIcon(
                                    FontAwesomeIcons.circleInfo,
                                    size: 14,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Información sobre liquidación',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Al activar la liquidación, el producto utilizará el precio de oferta como precio de venta principal. '
                                'Esto aplica un descuento especial para liquidar inventario. '
                                'El precio de liquidación debe ser menor al precio de venta regular.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Switch para activar/desactivar liquidación
                        Row(
                          children: <Widget>[
                            const Text(
                              'Activar liquidación',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Switch(
                              value: _enLiquidacion,
                              onChanged: (bool value) {
                                setState(() {
                                  _enLiquidacion = value;
                                });
                              },
                              activeColor: Colors.orange,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Campo para precio de liquidación (visible solo si liquidación está activa)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: _enLiquidacion ? null : 0,
                          curve: Curves.easeInOut,
                          child: AnimatedOpacity(
                            opacity: _enLiquidacion ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: _enLiquidacion
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      const Text(
                                        'Precio de liquidación',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller:
                                            _precioLiquidacionController,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        style: const TextStyle(
                                            color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: 'Precio de liquidación',
                                          hintText:
                                              'Ingrese el precio de liquidación',
                                          border: const OutlineInputBorder(),
                                          filled: true,
                                          fillColor: const Color(0xFF1A1A1A),
                                          labelStyle: const TextStyle(
                                              color: Colors.white70),
                                          hintStyle: const TextStyle(
                                              color: Colors.white30),
                                          prefixText: 'S/ ',
                                          prefixStyle: const TextStyle(
                                              color: Colors.white70),
                                          helperText:
                                              'Debe ser menor a S/ ${widget.producto.precioVenta.toStringAsFixed(2)}',
                                          helperStyle: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.6)),
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      // Comparación de precios
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1A1A1A),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          children: <Widget>[
                                            _buildPrecioComparacion(
                                              'Precio Regular',
                                              widget.producto.precioVenta,
                                              Colors.white,
                                            ),
                                            const SizedBox(height: 8),
                                            _buildPrecioComparacion(
                                              'Precio Liquidación',
                                              double.tryParse(
                                                      _precioLiquidacionController
                                                          .text) ??
                                                  0,
                                              Colors.orange,
                                            ),
                                            const SizedBox(height: 8),
                                            _buildPrecioComparacion(
                                              'Descuento',
                                              widget.producto.precioVenta -
                                                  (double.tryParse(
                                                          _precioLiquidacionController
                                                              .text) ??
                                                      0),
                                              Colors.green,
                                              isDescuento: true,
                                              precioOriginal:
                                                  widget.producto.precioVenta,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Botones para guardar/cancelar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            ElevatedButton(
                              onPressed: _isUpdating
                                  ? null
                                  : () {
                                      setState(() {
                                        _enLiquidacion =
                                            widget.producto.liquidacion;
                                        _precioLiquidacionController.text =
                                            (widget.producto.precioOferta ??
                                                    (widget.producto
                                                            .precioVenta *
                                                        0.9))
                                                .toStringAsFixed(2);
                                      });
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade800,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed:
                                  _isUpdating ? null : _gestionarLiquidacion,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
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
                                  : Text(_enLiquidacion
                                      ? 'Guardar Liquidación'
                                      : 'Quitar Liquidación'),
                            ),
                          ],
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar comparación de precios
  Widget _buildPrecioComparacion(String label, double precio, Color color,
      {bool isDescuento = false, double? precioOriginal}) {
    // Calcular porcentaje de descuento
    String porcentajeDescuento = '';
    if (isDescuento && precioOriginal != null && precioOriginal > 0) {
      final double porcentaje = (precio / precioOriginal) * 100;
      porcentajeDescuento = ' (${porcentaje.toStringAsFixed(1)}%)';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        Text(
          'S/ ${precio.toStringAsFixed(2)}$porcentajeDescuento',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
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
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
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
            children: <Widget>[
              Column(
                children: <Widget>[
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
                children: <Widget>[
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
            onChanged: (String value) {
              // Validar que sea un número
              if (value.isEmpty) {
                setState(() {
                  _stockNuevo = _stockActual;
                  _mostrarAdvertencia = false;
                });
                return;
              }

              final int? cantidad = int.tryParse(value);
              if (cantidad != null) {
                final int nuevoStock = _stockActual + cantidad;
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
            children: <Widget>[
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
                        children: <Widget>[
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
            children: <Widget>[
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
                children: <Widget>[
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
                        color: Colors.white.withValues(alpha: 0.8),
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

  // Métodos auxiliares que usan el provider
  Color _getStockStatusColor(int stockActual, int stockMinimo) {
    final StockStatus status =
        _stockProvider.getStockStatus(stockActual, stockMinimo);
    switch (status) {
      case StockStatus.agotado:
        return Colors.red.shade800;
      case StockStatus.stockBajo:
        return const Color(0xFFE31E24);
      case StockStatus.disponible:
        return Colors.green;
    }
  }

  IconData _getStockStatusIcon(int stockActual, int stockMinimo) {
    final StockStatus status =
        _stockProvider.getStockStatus(stockActual, stockMinimo);
    switch (status) {
      case StockStatus.agotado:
        return FontAwesomeIcons.ban;
      case StockStatus.stockBajo:
        return FontAwesomeIcons.triangleExclamation;
      case StockStatus.disponible:
        return FontAwesomeIcons.check;
    }
  }

  String _getStockStatusText(int stockActual, int stockMinimo) {
    final StockStatus status =
        _stockProvider.getStockStatus(stockActual, stockMinimo);
    switch (status) {
      case StockStatus.agotado:
        return 'Agotado';
      case StockStatus.stockBajo:
        return 'Stock bajo';
      case StockStatus.disponible:
        return 'Disponible';
    }
  }
}
