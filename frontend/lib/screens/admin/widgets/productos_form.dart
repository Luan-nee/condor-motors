import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../main.dart' show api;
import '../../../models/color.model.dart';
import '../../../models/producto.model.dart';
import '../../../models/sucursal.model.dart';
import '../utils/productos_utils.dart';

class ProductosFormDialogAdmin extends StatefulWidget {
  final Producto? producto;
  final Function(Map<String, dynamic>) onSave;
  final List<Sucursal> sucursales;
  final Sucursal? sucursalSeleccionada;

  const ProductosFormDialogAdmin({
    super.key,
    this.producto,
    required this.onSave,
    required this.sucursales,
    this.sucursalSeleccionada,
  });

  @override
  State<ProductosFormDialogAdmin> createState() =>
      _ProductosFormDialogAdminState();
}

class _ProductosFormDialogAdminState extends State<ProductosFormDialogAdmin> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _precioVentaController;
  late TextEditingController _stockController;
  late TextEditingController _skuController;
  late TextEditingController _marcaController;
  late TextEditingController _precioCompraController;
  late TextEditingController _colorController;
  late TextEditingController _stockMinimoController;
  late TextEditingController _precioOfertaController;
  late TextEditingController _cantidadMinimaDescuentoController;
  late TextEditingController _porcentajeDescuentoController;

  String _categoriaSeleccionada = '';
  Sucursal? _sucursalSeleccionada;
  ColorApp? _colorSeleccionado;
  bool _isLoadingCategorias = false;
  bool _isLoadingMarcas = false;
  bool _isLoadingColores = false;
  bool _isLoadingSucursalesCompartidas = false;
  List<ProductoEnSucursal> _sucursalesCompartidas = [];

  // Listas para categorías, marcas y colores
  List<String> _categorias = [];
  List<String> _marcas = [];
  List<ColorApp> _colores = [];

  @override
  void initState() {
    super.initState();
    final producto = widget.producto;
    _nombreController = TextEditingController(text: producto?.nombre);
    _descripcionController = TextEditingController(text: producto?.descripcion);
    _precioVentaController = TextEditingController(
      text: producto?.precioVenta.toString() ?? '0.00',
    );
    _stockController = TextEditingController(
      text: producto?.stock.toString() ?? '0',
    );
    _skuController = TextEditingController(text: producto?.sku);
    _marcaController = TextEditingController(text: producto?.marca);
    _precioCompraController = TextEditingController(
      text: producto?.precioCompra.toString() ?? '0.00',
    );
    _colorController = TextEditingController(text: producto?.color ?? '');
    _stockMinimoController = TextEditingController(
      text: producto?.stockMinimo?.toString() ?? '',
    );
    _precioOfertaController = TextEditingController(
      text: producto?.precioOferta?.toString() ?? '',
    );
    _cantidadMinimaDescuentoController = TextEditingController(
      text: producto?.cantidadMinimaDescuento?.toString() ?? '',
    );
    _porcentajeDescuentoController = TextEditingController(
      text: producto?.porcentajeDescuento?.toString() ?? '',
    );

    // Inicializar la sucursal seleccionada
    _sucursalSeleccionada = widget.sucursalSeleccionada ??
        (widget.sucursales.isNotEmpty ? widget.sucursales.first : null);

    // Cargar categorías, marcas y colores
    _cargarCategorias();
    _cargarMarcas();
    _cargarColores();

    // Si estamos editando un producto existente, cargar la disponibilidad en otras sucursales
    if (producto != null) {
      _cargarSucursalesCompartidas(producto.id);
    }
  }

  // Método para cargar las categorías desde la API
  Future<void> _cargarCategorias() async {
    setState(() => _isLoadingCategorias = true);

    try {
      final categorias = await ProductosUtils.obtenerCategorias();

      if (mounted) {
        setState(() {
          _categorias = categorias;
          _isLoadingCategorias = false;

          // Establecer la categoría seleccionada
          if (widget.producto != null &&
              categorias.contains(widget.producto!.categoria)) {
            _categoriaSeleccionada = widget.producto!.categoria;
          } else if (categorias.isNotEmpty) {
            _categoriaSeleccionada = categorias.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error al cargar categorías: $e');

      if (mounted) {
        setState(() => _isLoadingCategorias = false);
      }
    }
  }

  // Método para cargar las marcas desde la API
  Future<void> _cargarMarcas() async {
    setState(() => _isLoadingMarcas = true);

    try {
      final marcas = await ProductosUtils.obtenerMarcas();

      if (mounted) {
        setState(() {
          _marcas = marcas;
          _isLoadingMarcas = false;

          // Si la marca actual no está en la lista y hay una marca seleccionada
          if (widget.producto != null &&
              !marcas.contains(widget.producto!.marca) &&
              _marcaController.text.isNotEmpty) {
            // Añadir la marca actual a la lista para evitar problemas
            _marcas.add(widget.producto!.marca);
            _marcas.sort(); // Mantener orden alfabético
          }
        });
      }
    } catch (e) {
      debugPrint('Error al cargar marcas: $e');

      if (mounted) {
        setState(() => _isLoadingMarcas = false);
      }
    }
  }

  // Método para cargar los colores desde la API
  Future<void> _cargarColores() async {
    setState(() => _isLoadingColores = true);

    try {
      final colores = await api.colores.getColores();

      if (mounted) {
        setState(() {
          _colores = colores;
          _isLoadingColores = false;

          // Si estamos editando un producto con color, seleccionarlo
          if (widget.producto?.color != null && widget.producto!.color!.isNotEmpty) {
            // Buscar el color por nombre
            try {
              _colorSeleccionado = _colores.firstWhere(
                (color) => color.nombre.toLowerCase() == widget.producto!.color!.toLowerCase(),
              );
            } catch (e) {
              // Si no encuentra coincidencia, usar el primer color disponible
              _colorSeleccionado = _colores.isNotEmpty ? _colores.first : null;
            }
          } else if (_colores.isNotEmpty) {
            // Seleccionar el primer color por defecto
            _colorSeleccionado = _colores.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error al cargar colores: $e');

      if (mounted) {
        setState(() => _isLoadingColores = false);
      }
    }
  }

  // Método para cargar las sucursales que comparten el producto
  Future<void> _cargarSucursalesCompartidas(int productoId) async {
    setState(() => _isLoadingSucursalesCompartidas = true);

    try {
      final sucursalesCompartidas =
          await ProductosUtils.obtenerProductoEnSucursales(
        productoId: productoId,
        sucursales: widget.sucursales,
      );

      if (mounted) {
        setState(() {
          _sucursalesCompartidas = sucursalesCompartidas;
          _isLoadingSucursalesCompartidas = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar sucursales compartidas: $e');

      if (mounted) {
        setState(() => _isLoadingSucursalesCompartidas = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isHorizontal = screenSize.width > screenSize.height;
    final isWideScreen = screenSize.width > 600;

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWideScreen ? screenSize.width * 0.1 : 16,
        vertical: isWideScreen ? screenSize.height * 0.1 : 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Container(
        width: isWideScreen ? screenSize.width * 0.8 : screenSize.width,
        constraints: BoxConstraints(
          maxWidth: 1200,
          maxHeight:
              isHorizontal ? screenSize.height * 0.9 : screenSize.height * 0.8,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.boxOpen,
                    color: Color(0xFFE31E24),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.producto == null
                        ? 'NUEVO PRODUCTO'
                        : 'EDITAR PRODUCTO',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: isHorizontal && isWideScreen
                      ? _buildTwoColumnLayout()
                      : _buildOneColumnLayout(),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('CANCELAR'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('GUARDAR'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOneColumnLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBasicInfoSection(),
        const SizedBox(height: 32),
        _buildPricingSection(),
        const SizedBox(height: 32),
        _buildCategorySection(),
        const SizedBox(height: 32),
        _buildDiscountSection(),
        const SizedBox(height: 32),
        // Mostrar sección de sucursales compartidas solo si estamos editando un producto existente
        if (widget.producto != null) ...[
          const SizedBox(height: 32),
          _buildSharedBranchesSection(),
        ],
      ],
    );
  }

  Widget _buildTwoColumnLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 32),
              _buildPricingSection(),
              // Mostrar sección de sucursales compartidas solo si estamos editando un producto existente
              if (widget.producto != null) ...[
                const SizedBox(height: 32),
                _buildSharedBranchesSection(),
              ],
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategorySection(),
              const SizedBox(height: 32),
              _buildDiscountSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        FaIcon(
          icon,
          color: const Color(0xFFE31E24),
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  InputDecoration _getInputDecoration(String label, {String? prefixText}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      prefixText: prefixText,
      prefixStyle: const TextStyle(color: Colors.white),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE31E24)),
      ),
      filled: true,
      fillColor: const Color(0xFF2D2D2D),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Información Básica', FontAwesomeIcons.circleInfo),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nombreController,
          decoration: _getInputDecoration('Nombre'),
          style: const TextStyle(color: Colors.white),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descripcionController,
          decoration: _getInputDecoration('Descripción'),
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        // Cuando es un producto existente, el SKU es de solo lectura
        // Cuando es un producto nuevo, el campo no aparece (el backend lo generará)
        widget.producto != null 
          ? TextFormField(
              controller: _skuController,
              decoration: _getInputDecoration('SKU (no editable)').copyWith(
                filled: true,
                fillColor: const Color(0xFF222222),
                prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54, size: 20),
              ),
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
              enabled: false, // Campo deshabilitado para edición
              readOnly: true, // Solo lectura
            )
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SKU generado automáticamente',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'El código SKU será asignado por el sistema automáticamente al guardar el producto.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Precios y Stock', FontAwesomeIcons.moneyBill),
        const SizedBox(height: 16),
        TextFormField(
          controller: _precioCompraController,
          decoration:
              _getInputDecoration('Precio de Compra', prefixText: 'S/ '),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _precioVentaController,
          decoration: _getInputDecoration('Precio de Venta', prefixText: 'S/ '),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Campo requerido';
            final venta = double.tryParse(value!) ?? 0;
            final compra = double.tryParse(_precioCompraController.text) ?? 0;
            if (venta <= compra) {
              return 'El precio de venta debe ser mayor al de compra';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _precioOfertaController,
          decoration:
              _getInputDecoration('Precio de liquidación', prefixText: 'S/ '),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _stockController,
          decoration: _getInputDecoration('Stock'),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _stockMinimoController,
          decoration: _getInputDecoration('Stock Mínimo (opcional)'),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder(
          valueListenable: _precioVentaController,
          builder: (context, precioVentaText, child) {
            return ValueListenableBuilder(
                valueListenable: _precioCompraController,
                builder: (context, precioCompraText, _) {
                  final venta = double.tryParse(precioVentaText.text) ?? 0;
                  final compra = double.tryParse(precioCompraText.text) ?? 0;
                  final ganancia = venta - compra;
                  final porcentaje = compra > 0 ? (ganancia / compra) * 100 : 0;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ganancia:',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'S/ ${ganancia.toStringAsFixed(2)} (${porcentaje.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            color: ganancia > 0
                                ? Colors.green[400]
                                : const Color(0xFFE31E24),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                });
          },
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Categorización', FontAwesomeIcons.tag),
        const SizedBox(height: 16),
        // Dropdown de Marca
        if (_isLoadingMarcas)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: CircularProgressIndicator(
                color: Color(0xFFE31E24),
                strokeWidth: 3,
              ),
            ),
          )
        else
          _marcas.isNotEmpty
              ? DropdownButtonFormField<String>(
                  value: _marcaController.text.isEmpty ||
                          !_marcas.contains(_marcaController.text)
                      ? _marcas.first
                      : _marcaController.text,
                  decoration: _getInputDecoration('Marca'),
                  dropdownColor: const Color(0xFF2D2D2D),
                  style: const TextStyle(color: Colors.white),
                  isExpanded: true,
                  items: _marcas.map((marca) {
                    return DropdownMenuItem(
                      value: marca,
                      child: Text(
                        marca,
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _marcaController.text = value;
                      });
                    }
                  },
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Seleccione una marca' : null,
                )
              : TextFormField(
                  controller: _marcaController,
                  decoration: _getInputDecoration('Marca'),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Campo requerido' : null,
                ),
        const SizedBox(height: 16),
        // Dropdown de Categoría
        if (_isLoadingCategorias)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: CircularProgressIndicator(
                color: Color(0xFFE31E24),
                strokeWidth: 3,
              ),
            ),
          )
        else
          _categorias.isNotEmpty
              ? DropdownButtonFormField<String>(
                  value: _categoriaSeleccionada.isEmpty ||
                          !_categorias.contains(_categoriaSeleccionada)
                      ? _categorias.first
                      : _categoriaSeleccionada,
                  decoration: _getInputDecoration('Categoría'),
                  dropdownColor: const Color(0xFF2D2D2D),
                  style: const TextStyle(color: Colors.white),
                  isExpanded: true,
                  items: _categorias.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(
                        category,
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _categoriaSeleccionada = value;
                      });
                    }
                  },
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Seleccione una categoría'
                      : null,
                )
              : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No se pudieron cargar las categorías. Por favor, intente nuevamente.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _cargarCategorias,
                        child: const Text(
                          'Reintentar',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        const SizedBox(height: 16),
        // Dropdown de Color (reemplazando el campo de texto)
        if (_isLoadingColores)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: CircularProgressIndicator(
                color: Color(0xFFE31E24),
                strokeWidth: 3,
              ),
            ),
          )
        else if (_colores.isNotEmpty)
          DropdownButtonFormField<ColorApp>(
            value: _colorSeleccionado,
            decoration: _getInputDecoration('Color'),
            dropdownColor: const Color(0xFF2D2D2D),
            style: const TextStyle(color: Colors.white),
            isExpanded: true,
            items: _colores.map((color) {
              return DropdownMenuItem(
                value: color,
                child: Row(
                  children: [
                    // Muestra una vista previa del color
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color.toColor(),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nombre del color
                    Expanded(
                      child: Text(
                        color.nombre,
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (ColorApp? value) {
              setState(() {
                _colorSeleccionado = value;
                if (value != null) {
                  _colorController.text = value.nombre;
                } else {
                  _colorController.text = '';
                }
              });
            },
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_outlined,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No se pudieron cargar los colores. Se usará el valor manual.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _cargarColores,
                  child: const Text(
                    'Reintentar',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDiscountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Descuentos', FontAwesomeIcons.percent),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cantidadMinimaDescuentoController,
          decoration:
              _getInputDecoration('Cantidad mínima para descuento (opcional)'),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _porcentajeDescuentoController,
          decoration:
              _getInputDecoration('Porcentaje de descuento (%) (opcional)'),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildSharedBranchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
            'Sucursales que Comparten este Producto', FontAwesomeIcons.sitemap),
        const SizedBox(height: 16),
        if (_isLoadingSucursalesCompartidas)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFE31E24),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Consultando disponibilidad en otras sucursales...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          )
        else if (_sucursalesCompartidas.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white54),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Este producto no se comparte con otras sucursales',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
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
                // Encabezado con contadores
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCounter(
                        'Total Sucursales',
                        _sucursalesCompartidas.length.toString(),
                        FontAwesomeIcons.store,
                        Colors.blue,
                      ),
                      _buildCounter(
                        'Con Stock',
                        _sucursalesCompartidas
                            .where((s) => s.disponible && s.producto.stock > 0)
                            .length
                            .toString(),
                        FontAwesomeIcons.boxOpen,
                        Colors.green,
                      ),
                      _buildCounter(
                        'Stock Bajo',
                        _sucursalesCompartidas
                            .where((s) =>
                                s.disponible && s.producto.tieneStockBajo())
                            .length
                            .toString(),
                        FontAwesomeIcons.triangleExclamation,
                        const Color(0xFFE31E24),
                      ),
                      _buildCounter(
                        'Agotados',
                        _sucursalesCompartidas
                            .where(
                                (s) => !s.disponible || s.producto.stock <= 0)
                            .length
                            .toString(),
                        FontAwesomeIcons.ban,
                        Colors.red.shade800,
                      ),
                    ],
                  ),
                ),

                // Lista de sucursales
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sucursalesCompartidas.length,
                  itemBuilder: (context, index) {
                    final productoEnSucursal = _sucursalesCompartidas[index];
                    return _buildSucursalItem(productoEnSucursal);
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCounter(String label, String count, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSucursalItem(ProductoEnSucursal item) {
    final bool isCurrentBranch = _sucursalSeleccionada?.id == item.sucursal.id;
    final bool isLowStock = item.disponible && item.producto.tieneStockBajo();

    Color statusColor = Colors.green;
    String statusText = 'Disponible';
    IconData statusIcon = FontAwesomeIcons.check;

    if (!item.disponible) {
      statusColor = Colors.red.shade800;
      statusText = 'No disponible';
      statusIcon = FontAwesomeIcons.ban;
    } else if (item.producto.stock <= 0) {
      statusColor = Colors.red.shade800;
      statusText = 'Agotado';
      statusIcon = FontAwesomeIcons.ban;
    } else if (isLowStock) {
      statusColor = const Color(0xFFE31E24);
      statusText = 'Stock bajo';
      statusIcon = FontAwesomeIcons.triangleExclamation;
    }

    // Versión compacta del tile
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentBranch
            ? const Color(0xFFE31E24).withOpacity(0.1)
            : const Color(0xFF222222),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentBranch
              ? const Color(0xFFE31E24)
              : Colors.white.withOpacity(0.1),
          width: isCurrentBranch ? 2 : 1,
        ),
      ),
      child: ExpansionTile(
        leading: Icon(
          item.sucursal.sucursalCentral ? Icons.star : Icons.store,
          color: item.sucursal.sucursalCentral ? Colors.amber : Colors.white54,
        ),
        title: Text(
          item.sucursal.nombre,
          style: TextStyle(
            color: isCurrentBranch ? const Color(0xFFE31E24) : Colors.white,
            fontWeight: isCurrentBranch ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          item.sucursal.direccion,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor.withOpacity(0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    statusIcon,
                    color: statusColor,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          ],
        ),
        children: [
          if (item.disponible)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProductInfoRow(
                      'Stock',
                      '${item.producto.stock} unidades',
                      FontAwesomeIcons.boxOpen),
                  const SizedBox(height: 8),
                  _buildProductInfoRow(
                      'Stock mínimo',
                      '${item.producto.stockMinimo} unidades',
                      FontAwesomeIcons.arrowDown),
                  const SizedBox(height: 8),
                  _buildProductInfoRow(
                      'Precio compra',
                      item.producto.getPrecioCompraFormateado(),
                      FontAwesomeIcons.tag),
                  const SizedBox(height: 8),
                  _buildProductInfoRow(
                      'Precio venta',
                      item.producto.getPrecioVentaFormateado(),
                      FontAwesomeIcons.tag),
                  if (item.producto.estaEnOferta()) ...[
                    const SizedBox(height: 8),
                    _buildProductInfoRow(
                        'Precio de liquidación',
                        item.producto.getPrecioOfertaFormateado() ?? '',
                        FontAwesomeIcons.percent),
                  ],
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade800.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.shade800.withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.triangleExclamation,
                      color: Colors.red,
                      size: 16,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Este producto no está disponible en esta sucursal. Puede añadirlo desde la gestión de inventario.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        FaIcon(
          icon,
          size: 14,
          color: Colors.white54,
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_sucursalSeleccionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debe seleccionar una sucursal'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final productoData = <String, dynamic>{
        if (widget.producto != null) 'id': widget.producto!.id,
        'nombre': _nombreController.text,
        // El SKU sólo se envía si estamos creando un nuevo producto
        // (aunque ahora se maneja automáticamente en el backend)
        'descripcion': _descripcionController.text,
        'marca': _marcaController.text,
        'categoria': _categoriaSeleccionada,
        'precioVenta': double.parse(_precioVentaController.text),
        'precioCompra': double.parse(_precioCompraController.text),
        'stock': int.parse(_stockController.text),
        'color': _colorSeleccionado?.nombre ?? _colorController.text,
        if (_precioOfertaController.text.isNotEmpty)
          'precioOferta': double.parse(_precioOfertaController.text),
        if (_stockMinimoController.text.isNotEmpty)
          'stockMinimo': int.parse(_stockMinimoController.text),
        if (_cantidadMinimaDescuentoController.text.isNotEmpty)
          'cantidadMinimaDescuento':
              int.parse(_cantidadMinimaDescuentoController.text),
        if (_porcentajeDescuentoController.text.isNotEmpty)
          'porcentajeDescuento': int.parse(_porcentajeDescuentoController.text),
      };

      widget.onSave(productoData);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioVentaController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    _marcaController.dispose();
    _precioCompraController.dispose();
    _colorController.dispose();
    _stockMinimoController.dispose();
    _precioOfertaController.dispose();
    _cantidadMinimaDescuentoController.dispose();
    _porcentajeDescuentoController.dispose();
    super.dispose();
  }
}
