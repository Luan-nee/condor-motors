import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/categoria.model.dart';
import 'package:condorsmotors/models/color.model.dart';
import 'package:condorsmotors/models/marca.model.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/providers/admin/producto.provider.dart';
import 'package:condorsmotors/utils/productos_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Producto?>('producto', producto))
      ..add(ObjectFlagProperty<Function(Map<String, dynamic>)>.has(
          'onSave', onSave))
      ..add(IterableProperty<Sucursal>('sucursales', sucursales))
      ..add(DiagnosticsProperty<Sucursal?>(
          'sucursalSeleccionada', sucursalSeleccionada));
  }
}

class _ProductosFormDialogAdminState extends State<ProductosFormDialogAdmin> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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
  late TextEditingController _cantidadGratisDescuentoController;

  String _categoriaSeleccionada = '';
  Sucursal? _sucursalSeleccionada;
  ColorApp? _colorSeleccionado;
  bool _isLoadingCategorias = false;
  bool _isLoadingMarcas = false;
  bool _isLoadingColores = false;
  bool _isLoadingSucursalesCompartidas = false;
  List<ProductoEnSucursal> _sucursalesCompartidas = <ProductoEnSucursal>[];

  // Gestión de liquidación (independiente de otras promociones)
  bool _liquidacionActiva = false;

  // Tipo de promoción seleccionada
  String _tipoPromocionSeleccionada = 'ninguna';

  // Listas para categorías, marcas y colores
  List<String> _categorias = <String>[];
  List<String> _marcas = <String>[];
  List<ColorApp> _colores = <ColorApp>[];

  // Mapas para almacenar los IDs correspondientes a los nombres
  Map<String, Map<String, Object>> _categoriasMap =
      <String, Map<String, Object>>{};
  Map<String, Map<String, Object>> _marcasMap = <String, Map<String, Object>>{};

  @override
  void initState() {
    super.initState();
    final Producto? producto = widget.producto;
    _nombreController = TextEditingController(text: producto?.nombre);
    _descripcionController = TextEditingController(text: producto?.descripcion);
    _precioVentaController = TextEditingController(
      text: producto?.precioVenta.toString() ?? '0.00',
    );
    _stockController = TextEditingController(
      text: producto?.stock.toString() ?? '0',
    );
    _skuController = TextEditingController(text: producto?.sku);
    _marcaController = TextEditingController(
      text: producto?.marca ?? '', // Inicialmente vacío
    );
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
    _cantidadGratisDescuentoController = TextEditingController(
      text: producto?.cantidadGratisDescuento?.toString() ?? '',
    );

    // Inicializar liquidación (independiente)
    _liquidacionActiva = producto?.liquidacion ?? false;

    // Inicializar tipo de promoción según datos del producto
    if (producto?.cantidadGratisDescuento != null &&
        producto!.cantidadGratisDescuento! > 0) {
      _tipoPromocionSeleccionada = 'gratis';
    } else if (producto?.cantidadMinimaDescuento != null &&
        producto!.cantidadMinimaDescuento! > 0 &&
        producto.porcentajeDescuento != null &&
        producto.porcentajeDescuento! > 0) {
      _tipoPromocionSeleccionada = 'descuentoPorcentual';
    } else {
      _tipoPromocionSeleccionada = 'ninguna';
    }

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
      Provider.of<ProductoProvider>(context, listen: false);

      // Obtenemos las categorías como objetos tipados
      final List<Categoria> categoriasList =
          await api.categorias.getCategoriasObjetos(useCache: false);

      if (mounted) {
        setState(() {
          // Extraer nombres para la lista desplegable
          _categorias = categoriasList
              .map<String>((Categoria cat) => cat.nombre)
              .where((String nombre) => nombre.isNotEmpty)
              .toList();
          _categorias.sort(); // Mantener orden alfabético

          // Crear un mapa para fácil acceso a los IDs por nombre
          _categoriasMap = <String, Map<String, Object>>{
            for (Categoria cat in categoriasList)
              cat.nombre: <String, Object>{'id': cat.id, 'nombre': cat.nombre}
          };

          _isLoadingCategorias = false;

          // Establecer la categoría seleccionada
          if (widget.producto != null &&
              _categorias.contains(widget.producto!.categoria)) {
            _categoriaSeleccionada = widget.producto!.categoria;
          } else if (_categorias.isNotEmpty) {
            _categoriaSeleccionada = _categorias.first;
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
      // Obtenemos las marcas como objetos tipados
      final ResultadoPaginado<Marca> marcasResult =
          await api.marcas.getMarcasPaginadas(useCache: false);

      // Extraemos la lista de marcas del resultado paginado
      final List<Marca> marcasList = marcasResult.items;

      if (mounted) {
        setState(() {
          // Extraer nombres para la lista desplegable
          _marcas = marcasList
              .map<String>((Marca marca) => marca.nombre)
              .where((String nombre) => nombre.isNotEmpty)
              .toList();
          _marcas.sort(); // Mantener orden alfabético

          // Crear un mapa para fácil acceso a los IDs por nombre
          _marcasMap = <String, Map<String, Object>>{
            for (Marca marca in marcasList)
              marca.nombre: <String, Object>{
                'id': marca.id,
                'nombre': marca.nombre
              }
          };

          _isLoadingMarcas = false;

          // Si la marca actual no está en la lista y hay una marca seleccionada
          if (widget.producto != null &&
              !_marcas.contains(widget.producto!.marca) &&
              _marcaController.text.isNotEmpty) {
            // Añadir la marca actual a la lista para evitar problemas
            _marcas
              ..add(widget.producto!.marca)
              ..sort(); // Mantener orden alfabético
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
      final List<ColorApp> colores = await api.colores.getColores();

      if (mounted) {
        setState(() {
          _colores = colores;
          _isLoadingColores = false;

          // Si estamos editando un producto con color, seleccionarlo
          if (widget.producto?.color != null &&
              widget.producto!.color!.isNotEmpty) {
            // Buscar el color por nombre
            try {
              _colorSeleccionado = _colores.firstWhere(
                (ColorApp color) =>
                    color.nombre.toLowerCase() ==
                    widget.producto!.color!.toLowerCase(),
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
      final List<ProductoEnSucursal> sucursalesCompartidas =
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
    final Size screenSize = MediaQuery.of(context).size;
    final bool isHorizontal = screenSize.width > screenSize.height;
    final bool isWideScreen = screenSize.width > 600;

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
          children: <Widget>[
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
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
                children: <Widget>[
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
      children: <Widget>[
        _buildBasicInfoSection(),
        const SizedBox(height: 32),
        _buildPricingSection(),
        const SizedBox(height: 32),
        _buildCategorySection(),
        const SizedBox(height: 32),
        _buildDiscountSection(),
        const SizedBox(height: 32),
        // Mostrar sección de sucursales compartidas solo si estamos editando un producto existente
        if (widget.producto != null) ...<Widget>[
          const SizedBox(height: 32),
          _buildSharedBranchesSection(),
        ],
      ],
    );
  }

  Widget _buildTwoColumnLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildBasicInfoSection(),
              const SizedBox(height: 32),
              _buildPricingSection(),
              // Mostrar sección de sucursales compartidas solo si estamos editando un producto existente
              if (widget.producto != null) ...<Widget>[
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
            children: <Widget>[
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
      children: <Widget>[
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

  InputDecoration _getInputDecoration(String label,
      {String? prefixText, String? helperText, Widget? suffixIcon}) {
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
      helperText: helperText,
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionTitle('Información Básica', FontAwesomeIcons.circleInfo),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nombreController,
          decoration: _getInputDecoration('Nombre'),
          style: const TextStyle(color: Colors.white),
          validator: (String? value) =>
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
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: Colors.white54, size: 20),
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
                  children: <Widget>[
                    const Icon(Icons.info_outline,
                        color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
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
    // Verificar si estamos en modo edición (producto ya existe)
    final bool esEdicion = widget.producto != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionTitle('Precios y Stock', FontAwesomeIcons.moneyBill),
        const SizedBox(height: 16),
        TextFormField(
          controller: _precioCompraController,
          decoration:
              _getInputDecoration('Precio de Compra', prefixText: 'S/ '),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          validator: (String? value) =>
              value?.isEmpty ?? true ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _precioVentaController,
          decoration: _getInputDecoration('Precio de Venta', prefixText: 'S/ '),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          validator: (String? value) {
            if (value?.isEmpty ?? true) {
              return 'Campo requerido';
            }
            final double venta = double.tryParse(value!) ?? 0;
            final double compra =
                double.tryParse(_precioCompraController.text) ?? 0;
            if (venta <= compra) {
              return 'El precio de venta debe ser mayor al de compra';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Añadir campo de precio de liquidación
        Row(
          children: [
            // Switch para activar/desactivar liquidación
            Switch(
              value: _liquidacionActiva,
              onChanged: (value) {
                setState(() {
                  _liquidacionActiva = value;
                });
              },
              activeColor: const Color(0xFFE31E24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Producto en liquidación',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        if (_liquidacionActiva) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _precioOfertaController,
            decoration:
                _getInputDecoration('Precio de liquidación', prefixText: 'S/ '),
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            validator: _liquidacionActiva
                ? (String? value) {
                    if (value?.isEmpty ?? true) {
                      return 'El precio de liquidación es requerido';
                    }
                    final double oferta = double.tryParse(value!) ?? 0;
                    final double venta =
                        double.tryParse(_precioVentaController.text) ?? 0;
                    final double compra =
                        double.tryParse(_precioCompraController.text) ?? 0;
                    if (oferta >= venta) {
                      return 'El precio debe ser menor al precio de venta';
                    }
                    if (oferta < compra) {
                      return 'El precio no puede ser menor al de compra';
                    }
                    return null;
                  }
                : null,
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: _stockController,
          decoration: _getInputDecoration(
            'Stock',
            helperText: esEdicion
                ? 'Para modificar el stock, utilice la gestión de inventario'
                : null,
            suffixIcon: esEdicion
                ? const Tooltip(
                    message:
                        'El stock solo puede ser modificado mediante entradas de inventario',
                    child: Icon(
                      FontAwesomeIcons.circleInfo,
                      size: 16,
                      color: Colors.amber,
                    ),
                  )
                : null,
          ),
          style: TextStyle(
            color: esEdicion ? Colors.white.withOpacity(0.6) : Colors.white,
          ),
          keyboardType: TextInputType.number,
          readOnly: esEdicion, // Deshabilitar edición para productos existentes
          enabled: !esEdicion, // Solo habilitado para nuevos productos
          validator: (String? value) =>
              value?.isEmpty ?? true ? 'Campo requerido' : null,
        ),

        // Mensaje informativo sobre gestión de stock
        if (esEdicion) ...<Widget>[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.amber.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: <Widget>[
                const FaIcon(
                  FontAwesomeIcons.triangleExclamation,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Gestión de Stock',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'El stock no puede editarse directamente. Para modificar el stock de este producto, por favor use el "Control de stock" desde la pantalla de Inventario.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
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
          builder: (BuildContext context, TextEditingValue precioVentaText,
              Widget? child) {
            return ValueListenableBuilder(
                valueListenable: _precioCompraController,
                builder: (BuildContext context,
                    TextEditingValue precioCompraText, _) {
                  final double venta =
                      double.tryParse(precioVentaText.text) ?? 0;
                  final double compra =
                      double.tryParse(precioCompraText.text) ?? 0;
                  final double ganancia = venta - compra;
                  final num porcentaje =
                      compra > 0 ? (ganancia / compra) * 100 : 0;

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
                      children: <Widget>[
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
      children: <Widget>[
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
                      ? 'Seleccione una marca' // Valor por defecto
                      : _marcaController.text,
                  decoration: _getInputDecoration('Marca'),
                  dropdownColor: const Color(0xFF2D2D2D),
                  style: const TextStyle(color: Colors.white),
                  isExpanded: true,
                  items: <String>['Seleccione una marca', ..._marcas]
                      .map((String marca) {
                    return DropdownMenuItem(
                      value: marca,
                      child: Text(
                        marca,
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    if (value != null && value != 'Seleccione una marca') {
                      setState(() {
                        _marcaController.text = value;
                      });
                    }
                  },
                  validator: (String? value) => value == null ||
                          value.isEmpty ||
                          value == 'Seleccione una marca'
                      ? 'Seleccione una marca'
                      : null,
                )
              : TextFormField(
                  controller: _marcaController,
                  decoration: _getInputDecoration('Marca'),
                  style: const TextStyle(color: Colors.white),
                  validator: (String? value) =>
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
                  items: _categorias.map((String category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(
                        category,
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        _categoriaSeleccionada = value;
                      });
                    }
                  },
                  validator: (String? value) => value?.isEmpty ?? true
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
                    children: <Widget>[
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
            items: _colores.map((ColorApp color) {
              return DropdownMenuItem(
                value: color,
                child: Row(
                  children: <Widget>[
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
              children: <Widget>[
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
      children: <Widget>[
        _buildSectionTitle(
            'Promociones y Descuentos', FontAwesomeIcons.percent),
        const SizedBox(height: 16),

        // Sección de liquidación (siempre visible)
        _buildLiquidacionSection(),

        const SizedBox(height: 24),

        // Selector de tipo de promoción adicional
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: const <Widget>[
                  FaIcon(
                    FontAwesomeIcons.bullhorn,
                    size: 16,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Promoción adicional',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Además de la liquidación, puede aplicar uno de estos tipos de promoción:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 10),

              // Opciones de tipo de promoción
              _buildPromoTypeOption(
                'ninguna',
                'Sin promoción adicional',
                'El producto no tendrá descuentos adicionales a la liquidación.',
                FontAwesomeIcons.ban,
                Colors.grey,
              ),
              const SizedBox(height: 8),
              _buildPromoTypeOption(
                'gratis',
                'Productos gratis',
                'Tipo: "Lleva X, Y gratis" - Ejemplo: Lleva 5, paga 4.',
                FontAwesomeIcons.gift,
                Colors.green,
              ),
              const SizedBox(height: 8),
              _buildPromoTypeOption(
                'descuentoPorcentual',
                'Descuento porcentual',
                'Aplica un porcentaje de descuento al comprar cierta cantidad.',
                FontAwesomeIcons.percent,
                Colors.blue,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Campos específicos según el tipo de promoción seleccionado
        if (_tipoPromocionSeleccionada == 'gratis')
          _buildProductosGratisFields(),
        if (_tipoPromocionSeleccionada == 'descuentoPorcentual')
          _buildDescuentoPorcentualFields(),
      ],
    );
  }

  // Sección de liquidación separada (siempre visible)
  Widget _buildLiquidacionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _liquidacionActiva
            ? Colors.amber.withOpacity(0.08)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _liquidacionActiva
              ? Colors.amber.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: const <Widget>[
                  FaIcon(
                    FontAwesomeIcons.tag,
                    size: 16,
                    color: Colors.amber,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Liquidación',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _liquidacionActiva,
                onChanged: (bool value) {
                  setState(() {
                    _liquidacionActiva = value;
                  });
                },
                activeColor: Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_liquidacionActiva) ...<Widget>[
            TextFormField(
              controller: _precioOfertaController,
              decoration: _getInputDecoration(
                'Precio de liquidación',
                prefixText: 'S/ ',
                helperText: 'Precio especial para liquidar este producto',
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              validator: (String? value) {
                if (_liquidacionActiva) {
                  if (value == null || value.isEmpty) {
                    return 'El precio de liquidación es obligatorio';
                  }
                  try {
                    final double precio = double.parse(value);
                    if (precio <= 0) {
                      return 'El precio debe ser mayor a cero';
                    }
                    final double precioVenta =
                        double.tryParse(_precioVentaController.text) ?? 0;
                    if (precio >= precioVenta) {
                      return 'El precio de liquidación debe ser menor al precio de venta';
                    }
                  } catch (e) {
                    return 'Ingrese un número válido';
                  }
                }
                return null;
              },
            ),

            // Mostrar comparación de precios
            const SizedBox(height: 12),
            ValueListenableBuilder(
              valueListenable: _precioOfertaController,
              builder:
                  (BuildContext context, TextEditingValue precioOfertaText, _) {
                return ValueListenableBuilder(
                  valueListenable: _precioVentaController,
                  builder: (BuildContext context,
                      TextEditingValue precioVentaText, _) {
                    final double precioVenta =
                        double.tryParse(precioVentaText.text) ?? 0;
                    final double precioOferta =
                        double.tryParse(precioOfertaText.text) ?? 0;

                    if (precioOferta <= 0 || precioVenta <= 0) {
                      return Container();
                    }

                    final double ahorro = precioVenta - precioOferta;
                    final num porcentaje =
                        precioVenta > 0 ? (ahorro / precioVenta) * 100 : 0;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Precio original: S/ ${precioVenta.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Precio liquidación: S/ ${precioOferta.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${porcentaje.toStringAsFixed(0)}% descuento',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ] else ...<Widget>[
            Text(
              'Active esta opción para establecer un precio especial de liquidación. '
              'El producto se mostrará como "En liquidación" en todas las vistas.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPromoTypeOption(String value, String title, String description,
      IconData icon, Color color) {
    final bool isSelected = _tipoPromocionSeleccionada == value;

    return InkWell(
      onTap: () {
        setState(() {
          _tipoPromocionSeleccionada = value;

          // Si seleccionamos una opción diferente, resetear los campos
          if (value != 'gratis') {
            _cantidadGratisDescuentoController.text = '';
          }

          if (value != 'descuentoPorcentual') {
            _porcentajeDescuentoController.text = '';
          }

          if (value == 'ninguna') {
            _cantidadMinimaDescuentoController.text = '';
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.2)
              : Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 24,
              child: Radio<String>(
                value: value,
                groupValue: _tipoPromocionSeleccionada,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _tipoPromocionSeleccionada = newValue;
                    });
                  }
                },
                activeColor: color,
                fillColor: WidgetStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) {
                  return states.contains(WidgetState.selected)
                      ? color
                      : Colors.white70;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      FaIcon(
                        icon,
                        size: 14,
                        color: isSelected ? color : Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
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

  Widget _buildProductosGratisFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: const <Widget>[
              FaIcon(
                FontAwesomeIcons.gift,
                size: 16,
                color: Colors.green,
              ),
              SizedBox(width: 8),
              Text(
                'Configuración de Productos Gratis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: _cantidadMinimaDescuentoController,
                  decoration: _getInputDecoration(
                    'Cantidad mínima a comprar',
                    helperText: 'Ejemplo: 5 unidades',
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  validator: (String? value) {
                    if (_tipoPromocionSeleccionada == 'gratis') {
                      if (value == null || value.isEmpty) {
                        return 'Campo requerido';
                      }
                      final int? cantidad = int.tryParse(value);
                      if (cantidad == null || cantidad <= 0) {
                        return 'Cantidad inválida';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cantidadGratisDescuentoController,
                  decoration: _getInputDecoration(
                    'Cantidad gratis',
                    helperText: 'Ejemplo: 1 unidad',
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  validator: (String? value) {
                    if (_tipoPromocionSeleccionada == 'gratis') {
                      if (value == null || value.isEmpty) {
                        return 'Campo requerido';
                      }
                      final int? cantidadGratis = int.tryParse(value);
                      if (cantidadGratis == null || cantidadGratis <= 0) {
                        return 'Cantidad inválida';
                      }

                      final int cantidadMinima = int.tryParse(
                              _cantidadMinimaDescuentoController.text) ??
                          0;
                      if (cantidadGratis >= cantidadMinima) {
                        return 'Debe ser menor a la cantidad mínima';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Vista previa de la promoción
          ValueListenableBuilder(
            valueListenable: _cantidadMinimaDescuentoController,
            builder:
                (BuildContext context, TextEditingValue cantidadMinimaText, _) {
              return ValueListenableBuilder(
                valueListenable: _cantidadGratisDescuentoController,
                builder: (BuildContext context,
                    TextEditingValue cantidadGratisText, _) {
                  final int cantidadMinima =
                      int.tryParse(cantidadMinimaText.text) ?? 0;
                  final int cantidadGratis =
                      int.tryParse(cantidadGratisText.text) ?? 0;

                  if (cantidadMinima > 0 &&
                      cantidadGratis > 0 &&
                      cantidadGratis < cantidadMinima) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: <Widget>[
                          const FaIcon(
                            FontAwesomeIcons.circleInfo,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Promoción: Compra ${cantidadMinima + cantidadGratis} al precio de $cantidadMinima',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'El cliente obtendrá $cantidadGratis ${cantidadGratis == 1 ? 'unidad gratis' : 'unidades gratis'} por la compra de $cantidadMinima unidades.',
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
                    );
                  }
                  return Container();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDescuentoPorcentualFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: const <Widget>[
              FaIcon(
                FontAwesomeIcons.percent,
                size: 16,
                color: Colors.blue,
              ),
              SizedBox(width: 8),
              Text(
                'Configuración de Descuento Porcentual',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: _cantidadMinimaDescuentoController,
                  decoration: _getInputDecoration(
                    'Cantidad mínima a comprar',
                    helperText: 'Ejemplo: 3 unidades',
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  validator: (String? value) {
                    if (_tipoPromocionSeleccionada == 'descuentoPorcentual') {
                      if (value == null || value.isEmpty) {
                        return 'Campo requerido';
                      }
                      final int? cantidad = int.tryParse(value);
                      if (cantidad == null || cantidad <= 0) {
                        return 'Cantidad inválida';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _porcentajeDescuentoController,
                  decoration: _getInputDecoration(
                    'Porcentaje de descuento',
                    helperText: 'Ejemplo: 10%',
                    suffixIcon: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('%', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  validator: (String? value) {
                    if (_tipoPromocionSeleccionada == 'descuentoPorcentual') {
                      if (value == null || value.isEmpty) {
                        return 'Campo requerido';
                      }
                      final int? porcentaje = int.tryParse(value);
                      if (porcentaje == null ||
                          porcentaje <= 0 ||
                          porcentaje >= 100) {
                        return 'Porcentaje inválido (1-99)';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Vista previa de la promoción
          ValueListenableBuilder(
            valueListenable: _cantidadMinimaDescuentoController,
            builder:
                (BuildContext context, TextEditingValue cantidadMinimaText, _) {
              return ValueListenableBuilder(
                valueListenable: _porcentajeDescuentoController,
                builder:
                    (BuildContext context, TextEditingValue porcentajeText, _) {
                  final int cantidadMinima =
                      int.tryParse(cantidadMinimaText.text) ?? 0;
                  final int porcentaje = int.tryParse(porcentajeText.text) ?? 0;

                  if (cantidadMinima > 0 &&
                      porcentaje > 0 &&
                      porcentaje < 100) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: <Widget>[
                          const FaIcon(
                            FontAwesomeIcons.circleInfo,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Promoción: Al comprar $cantidadMinima tendras $porcentaje% de descuento',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Container();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSharedBranchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionTitle(
            'Sucursales que Comparten este Producto', FontAwesomeIcons.sitemap),
        const SizedBox(height: 16),
        if (_isLoadingSucursalesCompartidas)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: <Widget>[
                  CircularProgressIndicator(
                    color: Color(0xFF1C7AC7),
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
              children: <Widget>[
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
              children: <Widget>[
                // Encabezado con contadores
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      _buildCounter(
                        'Total Sucursales',
                        _sucursalesCompartidas.length.toString(),
                        FontAwesomeIcons.store,
                        Colors.blue,
                      ),
                      _buildCounter(
                        'Con Stock',
                        _sucursalesCompartidas
                            .where((ProductoEnSucursal s) =>
                                s.disponible && s.producto.stock > 0)
                            .length
                            .toString(),
                        FontAwesomeIcons.boxOpen,
                        Colors.green,
                      ),
                      _buildCounter(
                        'Stock Bajo',
                        _sucursalesCompartidas
                            .where((ProductoEnSucursal s) =>
                                s.disponible && s.producto.tieneStockBajo())
                            .length
                            .toString(),
                        FontAwesomeIcons.triangleExclamation,
                        const Color(0xFFE31E24),
                      ),
                      _buildCounter(
                        'Agotados',
                        _sucursalesCompartidas
                            .where((ProductoEnSucursal s) =>
                                !s.disponible || s.producto.stock <= 0)
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
                  itemBuilder: (BuildContext context, int index) {
                    final ProductoEnSucursal productoEnSucursal =
                        _sucursalesCompartidas[index];
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
      children: <Widget>[
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
            ? const Color.fromARGB(255, 30, 155, 227).withOpacity(0.1)
            : const Color(0xFF222222),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentBranch
              ? const Color.fromARGB(255, 30, 197, 227).withOpacity(0.1)
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
            color: isCurrentBranch
                ? const Color.fromARGB(255, 139, 207, 230)
                : Colors.white,
            fontWeight: isCurrentBranch ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          item.sucursal.direccion ?? 'Sin dirección registrada',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontStyle: item.sucursal.direccion != null
                ? FontStyle.normal
                : FontStyle.italic,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
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
                children: <Widget>[
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
        children: <Widget>[
          if (item.disponible)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
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
                  if (item.producto.estaEnOferta()) ...<Widget>[
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
                  children: <Widget>[
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
      children: <Widget>[
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

      // Verificar si estamos en modo edición
      final bool esNuevoProducto = widget.producto == null;

      // Construir el cuerpo de la solicitud
      final Map<String, dynamic> productoData = <String, dynamic>{
        if (widget.producto != null) 'id': widget.producto!.id,
        'nombre': _nombreController.text,
        'descripcion': _descripcionController.text,
        'marca': _marcaController.text,
        'categoria': _categoriaSeleccionada,
        'precioVenta': double.parse(_precioVentaController.text),
        'precioCompra': double.parse(_precioCompraController.text),
        // Solo incluir stock para productos nuevos
        if (esNuevoProducto) 'stock': int.parse(_stockController.text),

        // Liquidación (campo independiente)
        'liquidacion': _liquidacionActiva,

        // Por defecto, valores nulos para los campos opcionales
        'cantidadMinimaDescuento': null,
        'cantidadGratisDescuento': null,
        'porcentajeDescuento': null,
        'precioOferta': null,
      };

      // Si está en liquidación, incluir precio de oferta
      if (_liquidacionActiva && _precioOfertaController.text.isNotEmpty) {
        productoData['precioOferta'] =
            double.parse(_precioOfertaController.text);
      }

      // Aplicar configuración según el tipo de promoción seleccionada
      switch (_tipoPromocionSeleccionada) {
        case 'gratis':
          if (_cantidadMinimaDescuentoController.text.isNotEmpty) {
            productoData['cantidadMinimaDescuento'] =
                int.parse(_cantidadMinimaDescuentoController.text);
          }
          if (_cantidadGratisDescuentoController.text.isNotEmpty) {
            productoData['cantidadGratisDescuento'] =
                int.parse(_cantidadGratisDescuentoController.text);
          }
          break;

        case 'descuentoPorcentual':
          if (_cantidadMinimaDescuentoController.text.isNotEmpty) {
            productoData['cantidadMinimaDescuento'] =
                int.parse(_cantidadMinimaDescuentoController.text);
          }
          if (_porcentajeDescuentoController.text.isNotEmpty) {
            productoData['porcentajeDescuento'] =
                int.parse(_porcentajeDescuentoController.text);
          }
          break;
      }

      // Stock mínimo (opcional)
      if (_stockMinimoController.text.isNotEmpty) {
        productoData['stockMinimo'] = int.parse(_stockMinimoController.text);
      }

      // Buscar y añadir el ID de categoría si está disponible
      if (_categoriasMap.containsKey(_categoriaSeleccionada)) {
        final Map<String, Object>? categoriaInfo =
            _categoriasMap[_categoriaSeleccionada];
        if (categoriaInfo != null && categoriaInfo['id'] != null) {
          final String idStr = categoriaInfo['id'].toString();
          final int? id = int.tryParse(idStr);
          if (id != null) {
            productoData['categoriaId'] = id;
            debugPrint(
                'ProductosForm: Categoría $_categoriaSeleccionada con ID válido: $id');
          } else {
            debugPrint(
                'ProductosForm: Advertencia - ID de categoría no válido: $idStr');
          }
        }
      }

      // Buscar y añadir el ID de marca si está disponible
      final String marcaText = _marcaController.text;
      if (_marcasMap.containsKey(marcaText)) {
        final Map<String, Object>? marcaInfo = _marcasMap[marcaText];
        if (marcaInfo != null && marcaInfo['id'] != null) {
          final String idStr = marcaInfo['id'].toString();
          final int? id = int.tryParse(idStr);
          if (id != null) {
            productoData['marcaId'] = id;
            debugPrint('ProductosForm: Marca $marcaText con ID válido: $id');
          } else {
            debugPrint(
                'ProductosForm: Advertencia - ID de marca no válido: $idStr');
          }
        }
      }

      // Manejar el color correctamente
      if (_colorSeleccionado != null) {
        // ColorApp.id ya es int según la definición del modelo
        productoData['colorId'] = _colorSeleccionado!.id;
        debugPrint(
            'ProductosForm: Color ${_colorSeleccionado!.nombre} con ID: ${_colorSeleccionado!.id}');

        // Incluir también el nombre para claridad
        productoData['color'] = _colorSeleccionado!.nombre;
      } else if (_colorController.text.isNotEmpty) {
        // Si solo tenemos texto pero no ID, enviar solo el nombre
        productoData['color'] = _colorController.text;
        // No enviar colorId si no tenemos un ID válido
      }

      // Añadir mensajes de depuración para rastrear los datos
      debugPrint('ProductosForm: Datos preparados para guardar:');
      debugPrint(
          'ProductosForm: Sucursal seleccionada: ${_sucursalSeleccionada?.id}');
      debugPrint('ProductosForm: Producto ID: ${widget.producto?.id}');
      debugPrint('ProductosForm: Es nuevo producto: $esNuevoProducto');

      // Mostrar datos completos para depuración
      debugPrint('ProductosForm: === DATOS COMPLETOS DEL PRODUCTO ===');
      productoData.forEach((String key, value) {
        final String tipo = value?.runtimeType.toString() ?? 'null';
        debugPrint('ProductosForm:   - $key: $value (Tipo: $tipo)');
      });
      debugPrint('ProductosForm: === FIN DATOS PRODUCTO ===');

      // Obtener el provider
      final ProductoProvider productoProvider =
          Provider.of<ProductoProvider>(context, listen: false);
      _sucursalSeleccionada!.id.toString();

      // Mostrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guardando producto...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );

      // Ejecutar en función asíncrona para evitar bloquear la UI
      Future<void> saveProducto() async {
        try {
          final bool resultado = await productoProvider.guardarProducto(
              productoData, esNuevoProducto);

          if (resultado) {
            // Mostrar mensaje de éxito si todavía estamos montados
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Producto guardado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            }

            // Si aún tenemos el onSave callback del widget padre, llamarlo para compatibilidad
            widget.onSave(productoData);
            debugPrint(
                'ProductosForm: Callback onSave ejecutado para compatibilidad');
          } else if (mounted && productoProvider.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(productoProvider.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          debugPrint('ProductosForm: ERROR al guardar producto: $e');

          // Mostrar mensaje de error si todavía estamos montados
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al guardar producto: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }

      // Iniciar el proceso de guardado sin esperar (no bloqueamos la UI)
      saveProducto();

      // Cerrar el diálogo
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
    _cantidadGratisDescuentoController.dispose();
    super.dispose();
  }
}
