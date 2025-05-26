import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:condorsmotors/screens/colabs/widgets/transferencias/transferencia_form_list_colab.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TransferenciaFormColab extends StatefulWidget {
  final Function(int sucursalDestinoId, List<DetalleProducto> productos) onSave;
  final String sucursalId;

  const TransferenciaFormColab({
    super.key,
    required this.onSave,
    required this.sucursalId,
  });

  @override
  State<TransferenciaFormColab> createState() => _TransferenciaFormColabState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<
          Function(int sucursalDestinoId,
              List<DetalleProducto> productos)>.has('onSave', onSave))
      ..add(StringProperty('sucursalId', sucursalId));
  }
}

class _TransferenciaFormColabState extends State<TransferenciaFormColab> {
  final List<DetalleProducto> _productosSeleccionados = [];
  bool _isLoading = false;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<DetalleProducto>(
          'productosSeleccionados', _productosSeleccionados))
      ..add(ObjectFlagProperty<Function(int, List<DetalleProducto>)>.has(
          'onSave', widget.onSave));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: size.width * 0.95,
        height: size.height * 0.95,
        constraints: const BoxConstraints(
          minWidth: 300,
          minHeight: 400,
          maxWidth: 900,
          maxHeight: 900,
        ),
        child: Column(
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
                    FontAwesomeIcons.truck,
                    size: 20,
                    color: Color(0xFFE31E24),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Nueva Transferencia',
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Sección de Productos
                    _buildProductosSection(),
                  ],
                ),
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
                mainAxisAlignment: MainAxisAlignment.end,
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
                    onPressed: _isLoading || _productosSeleccionados.isEmpty
                        ? null
                        : _handleSave,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const FaIcon(FontAwesomeIcons.check, size: 16),
                    label: Text(_isLoading ? 'Guardando...' : 'Guardar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
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

  Widget _buildProductosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text(
              'Productos',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            TextButton.icon(
              onPressed: _selectProductos,
              icon: const FaIcon(
                FontAwesomeIcons.plus,
                size: 14,
                color: Color(0xFFE31E24),
              ),
              label: const Text(
                'Agregar',
                style: TextStyle(
                  color: Color(0xFFE31E24),
                  fontSize: 14,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_productosSeleccionados.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'No hay productos seleccionados',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _productosSeleccionados.length,
            itemBuilder: (context, index) {
              final producto = _productosSeleccionados[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: <Widget>[
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
                        children: <Widget>[
                          Text(
                            producto.nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (producto.codigo != null)
                            Text(
                              'Código: ${producto.codigo}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE31E24).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Cant: ${producto.cantidad}',
                        style: const TextStyle(
                          color: Color(0xFFE31E24),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red[300],
                      onPressed: () => _removeProducto(index),
                      padding: const EdgeInsets.only(left: 8),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _selectProductos() async {
    setState(() => _isLoading = true);
    try {
      final result = await showDialog<List<DetalleProducto>>(
        context: context,
        builder: (BuildContext context) => TransferenciaFormListColab(
          sucursalId: widget.sucursalId,
          productosSeleccionados: _productosSeleccionados,
        ),
      );
      if (result != null) {
        setState(() {
          _productosSeleccionados
            ..clear()
            ..addAll(result);
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar productos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removeProducto(int index) {
    setState(() {
      _productosSeleccionados.removeAt(index);
    });
  }

  void _handleSave() {
    if (_productosSeleccionados.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      widget.onSave(int.parse(widget.sucursalId), _productosSeleccionados);
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
