import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:condorsmotors/providers/admin/sucursal.admin.riverpod.dart';
import 'package:condorsmotors/screens/colabs/widgets/transferencias/transferencia_form_list_colab.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TransferenciaFormColab extends ConsumerStatefulWidget {
  final Function(int sucursalDestinoId, List<DetalleProducto> productos) onSave;
  final String sucursalId;

  const TransferenciaFormColab({
    super.key,
    required this.onSave,
    required this.sucursalId,
  });

  @override
  ConsumerState<TransferenciaFormColab> createState() =>
      _TransferenciaFormColabState();

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

class _TransferenciaFormColabState extends ConsumerState<TransferenciaFormColab> {
  final List<DetalleProducto> _productosSeleccionados = [];
  int? _sucursalDestinoId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Cargar sucursales al inicio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sucursalAdminProvider.notifier).cargarSucursales();
    });
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<DetalleProducto>(
          'productosSeleccionados', _productosSeleccionados))
      ..add(IntProperty('sucursalDestinoId', _sucursalDestinoId))
      ..add(ObjectFlagProperty<Function(int, List<DetalleProducto>)>.has(
          'onSave', widget.onSave));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final sucursalesState = ref.watch(sucursalAdminProvider);

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
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildSucursalSection(sucursalesState),
                    const SizedBox(height: 24),
                    _buildProductosSection(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
    );
  }

  Widget _buildSucursalSection(SucursalAdminState state) {
    final availableSucursales = state.todasLasSucursales.where((s) => s.id.toString() != widget.sucursalId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sucursal Destino',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _sucursalDestinoId,
              isExpanded: true,
              hint: const Text('Seleccionar sucursal destino', style: TextStyle(color: Colors.white54)),
              dropdownColor: const Color(0xFF2D2D2D),
              elevation: 4,
              style: const TextStyle(color: Colors.white),
              items: availableSucursales.map((s) {
                return DropdownMenuItem<int>(
                  value: int.tryParse(s.id),
                  child: Text(s.nombre),
                );
              }).toList(),
              onChanged: (val) => setState(() => _sucursalDestinoId = val),
            ),
          ),
        ),
        if (state.isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
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
            onPressed: _isLoading || _productosSeleccionados.isEmpty || _sucursalDestinoId == null
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
                        color: const Color(0xFFE31E24).withValues(alpha: 0.1),
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
                        color: const Color(0xFFE31E24).withValues(alpha: 0.1),
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

  Future<void> _selectProductos() async {
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
    if (_productosSeleccionados.isEmpty || _sucursalDestinoId == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      widget.onSave(_sucursalDestinoId!, _productosSeleccionados);
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
