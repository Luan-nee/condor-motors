import 'dart:io';

import 'package:condorsmotors/models/color.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/categoria.repository.dart';
import 'package:condorsmotors/repositories/color.repository.dart';
import 'package:condorsmotors/repositories/marcas.repository.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/components/productos_form_categoria.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/components/productos_form_informacion.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/components/productos_form_promociones.dart';
import 'package:condorsmotors/screens/admin/widgets/producto/components/productos_form_sucursales.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:condorsmotors/utils/productos_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
      ..add(
        ObjectFlagProperty<Function(Map<String, dynamic>)>.has(
          'onSave',
          onSave,
        ),
      )
      ..add(IterableProperty<Sucursal>('sucursales', sucursales))
      ..add(
        DiagnosticsProperty<Sucursal?>(
          'sucursalSeleccionada',
          sucursalSeleccionada,
        ),
      );
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

  File? _selectedImageFile;
  String? _previewImageUrl;

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
    _sucursalSeleccionada =
        widget.sucursalSeleccionada ??
        (widget.sucursales.isNotEmpty ? widget.sucursales.first : null);

    // Obtener el provider e inicializar datos
    _initProvider();

    // Inicializar preview de imagen si el producto tiene foto
    if (widget.producto?.pathFoto != null &&
        widget.producto!.pathFoto!.isNotEmpty) {
      _previewImageUrl = widget.producto!.pathFoto;
    }

    // Agregar listeners para detectar cambios e interactividad en tiempo real
    _nombreController.addListener(_onFieldChanged);
    _descripcionController.addListener(_onFieldChanged);
    _precioVentaController.addListener(_onFieldChanged);
    _stockController.addListener(_onFieldChanged);
    _skuController.addListener(_onFieldChanged);
    _marcaController.addListener(_onFieldChanged);
    _precioCompraController.addListener(_onFieldChanged);
    _colorController.addListener(_onFieldChanged);
    _stockMinimoController.addListener(_onFieldChanged);
    _precioOfertaController.addListener(_onFieldChanged);
    _cantidadMinimaDescuentoController.addListener(_onFieldChanged);
    _porcentajeDescuentoController.addListener(_onFieldChanged);
    _cantidadGratisDescuentoController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool _hasChanges() {
    if (widget.producto == null) {
      // Para un producto nuevo, se habilita "Guardar" tan pronto como el nombre no esté vacío.
      return _nombreController.text.trim().isNotEmpty;
    }

    final Producto prod = widget.producto!;

    // 1. Campos de texto
    final bool nombreChanged = _nombreController.text.trim() != prod.nombre.trim();
    final bool descripcionChanged = _descripcionController.text.trim() != (prod.descripcion ?? '').trim();

    final double initialPrecioCompra = prod.precioCompra;
    final double currentPrecioCompra = double.tryParse(_precioCompraController.text) ?? 0.0;
    final bool precioCompraChanged = currentPrecioCompra != initialPrecioCompra;

    final double initialPrecioVenta = prod.precioVenta;
    final double currentPrecioVenta = double.tryParse(_precioVentaController.text) ?? 0.0;
    final bool precioVentaChanged = currentPrecioVenta != initialPrecioVenta;

    final int initialStock = prod.stock;
    final int currentStock = int.tryParse(_stockController.text) ?? 0;
    final bool stockChanged = currentStock != initialStock;

    final String initialSku = prod.sku;
    final bool skuChanged = _skuController.text.trim() != initialSku.trim();

    final String initialMarca = prod.marca;
    final bool marcaChanged = _marcaController.text.trim() != initialMarca.trim();

    final String initialColor = prod.color ?? '';
    final String currentColor = _colorSeleccionado?.nombre ?? _colorController.text;
    final bool colorChanged = currentColor.trim() != initialColor.trim();

    final int? initialStockMinimo = prod.stockMinimo;
    final int? currentStockMinimo = int.tryParse(_stockMinimoController.text);
    final bool stockMinimoChanged = currentStockMinimo != initialStockMinimo;

    // 2. Categoría
    final String initialCategoria = prod.categoria;
    final bool categoriaChanged = _categoriaSeleccionada != initialCategoria;

    // 3. Liquidación (independiente)
    final bool initialLiquidacion = prod.liquidacion;
    final bool liquidacionChanged = _liquidacionActiva != initialLiquidacion;

    // 4. Precio Oferta si la liquidación está activa
    final double? initialPrecioOferta = prod.precioOferta;
    final double? currentPrecioOferta = double.tryParse(_precioOfertaController.text);
    final bool precioOfertaChanged = _liquidacionActiva && (currentPrecioOferta != initialPrecioOferta);

    // 5. Tipo Promoción y sus valores específicos
    final String initialTipoPromo = (prod.cantidadGratisDescuento != null && prod.cantidadGratisDescuento! > 0)
        ? 'gratis'
        : (prod.cantidadMinimaDescuento != null && prod.cantidadMinimaDescuento! > 0)
            ? 'descuentoPorcentual'
            : 'ninguna';
    final bool tipoPromoChanged = _tipoPromocionSeleccionada != initialTipoPromo;

    bool promoValuesChanged = false;
    if (_tipoPromocionSeleccionada == 'gratis') {
      final int? initialGratis = prod.cantidadGratisDescuento;
      final int? currentGratis = int.tryParse(_cantidadGratisDescuentoController.text);
      promoValuesChanged = currentGratis != initialGratis;
    } else if (_tipoPromocionSeleccionada == 'descuentoPorcentual') {
      final int? initialMinima = prod.cantidadMinimaDescuento;
      final int? currentMinima = int.tryParse(_cantidadMinimaDescuentoController.text);
      final int? initialPorcentaje = prod.porcentajeDescuento;
      final int? currentPorcentaje = int.tryParse(_porcentajeDescuentoController.text);
      promoValuesChanged = (currentMinima != initialMinima) || (currentPorcentaje != initialPorcentaje);
    }

    // 6. Imagen seleccionada
    final bool imageChanged = _selectedImageFile != null;

    return nombreChanged ||
        descripcionChanged ||
        precioCompraChanged ||
        precioVentaChanged ||
        stockChanged ||
        skuChanged ||
        marcaChanged ||
        colorChanged ||
        stockMinimoChanged ||
        categoriaChanged ||
        liquidacionChanged ||
        precioOfertaChanged ||
        tipoPromoChanged ||
        promoValuesChanged ||
        imageChanged;
  }

  Future<void> _initProvider() async {
    // Cargar datos usando repositorios directamente
    setState(() {
      _isLoadingCategorias = true;
      _isLoadingMarcas = true;
      _isLoadingColores = true;
    });

    try {
      // Cargar categorías, marcas y colores desde repositorios
      final categoriaRepository = CategoriaRepository.instance;
      final marcaRepository = MarcaRepository.instance;
      final colorRepository = ColorRepository.instance;

      final categorias = await categoriaRepository.getCategorias();
      final marcas = await marcaRepository.getMarcas();
      final colores = await colorRepository.getColores();

      setState(() {
        // Obtener categorías
        _categorias = categorias.map((c) => c.nombre).toList();
        _isLoadingCategorias = false;

        // Establecer la categoría seleccionada
        if (widget.producto != null &&
            _categorias.contains(widget.producto!.categoria)) {
          _categoriaSeleccionada = widget.producto!.categoria;
        } else if (_categorias.isNotEmpty) {
          _categoriaSeleccionada = _categorias.first;
        }

        // Obtener marcas
        _marcas = marcas.map((m) => m.nombre).toList();
        _marcas.sort();
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

        // Obtener colores desde el endpoint real
        _colores = colores;
        _isLoadingColores = false;

        // Si estamos editando un producto con color, seleccionarlo
        final producto = widget.producto;
        if (producto != null &&
            producto.color != null &&
            producto.color!.isNotEmpty) {
          // Buscar el color por nombre
          _colorSeleccionado = _colores.firstWhere(
            (color) => color.nombre == producto.color,
            orElse: () => _colores.first,
          );
        } else if (_colores.isNotEmpty) {
          // Seleccionar el primer color por defecto
          _colorSeleccionado = _colores.first;
        }
      });

      // Si estamos editando un producto existente, cargar la disponibilidad en otras sucursales
      if (widget.producto != null) {
        _cargarSucursalesCompartidas(widget.producto!.id);
      }
    } catch (e) {
      debugPrint('Error al inicializar datos del formulario: $e');
      setState(() {
        _isLoadingCategorias = false;
        _isLoadingMarcas = false;
        _isLoadingColores = false;
      });
    }
  }

  // Método para cargar las sucursales que comparten el producto
  Future<void> _cargarSucursalesCompartidas(int productoId) async {
    setState(() => _isLoadingSucursalesCompartidas = true);

    try {
      // Usar ProductosUtils para obtener información del producto en todas las sucursales
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

  // Método para recargar datos después de guardar
  Future<void> _recargarDatos() async {
    try {
      // Recargar sucursales compartidas si estamos editando un producto existente
      if (widget.producto != null) {
        await _cargarSucursalesCompartidas(widget.producto!.id);
      }

      // Nota: Los repositorios se actualizan automáticamente en las próximas consultas
      debugPrint('ProductosForm: Datos recargados correctamente');
    } catch (e) {
      debugPrint('Error al recargar datos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isHorizontal = screenSize.width > screenSize.height;
    final bool isWideScreen = screenSize.width > 600;

    return Dialog(
      backgroundColor: AppTheme.darkSurface,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWideScreen ? screenSize.width * 0.1 : 16,
        vertical: isWideScreen ? screenSize.height * 0.1 : 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Container(
        width: isWideScreen ? screenSize.width * 0.8 : screenSize.width,
        constraints: BoxConstraints(
          maxWidth: 1200,
          maxHeight: isHorizontal
              ? screenSize.height * 0.9
              : screenSize.height * 0.8,
        ),
        child: Column(
          children: <Widget>[
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.deepSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  const FaIcon(
                    FontAwesomeIcons.boxOpen,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.producto == null
                        ? 'Nuevo Producto'
                        : 'Editar Producto',
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
              decoration: const BoxDecoration(
                color: AppTheme.deepSurface,
                borderRadius: BorderRadius.vertical(
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
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _hasChanges() ? _handleSave : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                      disabledForegroundColor: Colors.white30,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    icon: Icon(widget.producto != null ? Icons.save : Icons.add),
                    label: Text(widget.producto != null ? 'Guardar' : 'Crear'),
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


  Widget _buildBasicInfoSection() {
    return ProductosFormInformacion(
      producto: widget.producto,
      nombreController: _nombreController,
      descripcionController: _descripcionController,
      precioCompraController: _precioCompraController,
      precioVentaController: _precioVentaController,
      stockController: _stockController,
      stockMinimoController: _stockMinimoController,
      skuController: _skuController,
      selectedImageFile: _selectedImageFile,
      previewImageUrl: _previewImageUrl,
      onPickImage: _pickImage,
      onRemoveImage: () {
        setState(() {
          _selectedImageFile = null;
          _previewImageUrl = null;
        });
      },
    );
  }

  Widget _buildCategorySection() {
    return ProductosFormCategoria(
      isLoadingCategorias: _isLoadingCategorias,
      isLoadingMarcas: _isLoadingMarcas,
      isLoadingColores: _isLoadingColores,
      categorias: _categorias,
      marcas: _marcas,
      colores: _colores,
      categoriaSeleccionada: _categoriaSeleccionada,
      marcaController: _marcaController,
      colorController: _colorController,
      colorSeleccionado: _colorSeleccionado,
      onCategoriaChanged: (String value) {
        setState(() {
          _categoriaSeleccionada = value;
        });
      },
      onMarcaChanged: (String value) {
        setState(() {
          _marcaController.text = value;
        });
      },
      onColorChanged: (ColorApp? value) {
        setState(() {
          _colorSeleccionado = value;
          if (value != null) {
            _colorController.text = value.nombre;
          } else {
            _colorController.text = '';
          }
        });
      },
      onRetryLoad: _initProvider,
    );
  }

  Widget _buildDiscountSection() {
    return ProductosFormPromociones(
      initialLiquidacionActiva: _liquidacionActiva,
      initialTipoPromocionSeleccionada: _tipoPromocionSeleccionada,
      precioVentaController: _precioVentaController,
      precioOfertaController: _precioOfertaController,
      cantidadMinimaDescuentoController: _cantidadMinimaDescuentoController,
      porcentajeDescuentoController: _porcentajeDescuentoController,
      cantidadGratisDescuentoController: _cantidadGratisDescuentoController,
      onLiquidacionActivaChanged: (bool val) {
        setState(() {
          _liquidacionActiva = val;
        });
      },
      onTipoPromocionSeleccionadaChanged: (String val) {
        setState(() {
          _tipoPromocionSeleccionada = val;
        });
      },
    );
  }

  Widget _buildSharedBranchesSection() {
    return ProductosFormSucursales(
      isLoadingSucursalesCompartidas: _isLoadingSucursalesCompartidas,
      sucursalesCompartidas: _sucursalesCompartidas,
      sucursalSeleccionada: _sucursalSeleccionada,
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

      // Preparar los datos del producto
      final Map<String, dynamic> productoData = {
        'nombre': _nombreController.text,
        'descripcion': _descripcionController.text,
        'precioCompra': double.tryParse(_precioCompraController.text) ?? 0,
        'precioVenta': double.tryParse(_precioVentaController.text) ?? 0,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'stockMinimo': int.tryParse(_stockMinimoController.text),
        'categoria': _categoriaSeleccionada,
        'marca': _marcaController.text,
        'color': _colorSeleccionado?.nombre ?? _colorController.text,
        'liquidacion': _liquidacionActiva,
        'precioOferta': _liquidacionActiva
            ? double.tryParse(_precioOfertaController.text)
            : null,
        'cantidadMinimaDescuento': _tipoPromocionSeleccionada != 'ninguna'
            ? int.tryParse(_cantidadMinimaDescuentoController.text)
            : null,
        'porcentajeDescuento':
            _tipoPromocionSeleccionada == 'descuentoPorcentual'
            ? int.tryParse(_porcentajeDescuentoController.text)
            : null,
        'cantidadGratisDescuento': _tipoPromocionSeleccionada == 'gratis'
            ? int.tryParse(_cantidadGratisDescuentoController.text)
            : null,
      };

      // Ejecutar en función asíncrona para evitar bloquear la UI
      Future<void> saveProducto() async {
        try {
          // Mostrar indicador de progreso en la UI
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Guardando y actualizando datos...'),
                  ],
                ),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 30),
              ),
            );
          }

          // Guardar el producto usando el repositorio
          final productoRepository = ProductoRepository.instance;
          final sucursalId = _sucursalSeleccionada!.id.toString();

          Producto? productoGuardado;

          if (widget.producto == null) {
            // Crear nuevo producto
            productoGuardado = await productoRepository.createProducto(
              sucursalId: sucursalId,
              productoData: productoData,
              fotoFile: _selectedImageFile,
            );
          } else {
            // Actualizar producto existente
            productoGuardado = await productoRepository.updateProducto(
              sucursalId: sucursalId,
              productoId: widget.producto!.id,
              productoData: productoData,
              fotoFile: _selectedImageFile,
            );
          }

          if (productoGuardado == null) {
            throw Exception('Error al guardar el producto');
          }

          // Invalidar caché para forzar actualización
          // Si estamos editando un producto existente, invalidar caché de todas las sucursales
          // ya que el producto puede existir en múltiples sucursales
          if (widget.producto != null) {
            // Invalidar caché global de productos para asegurar que todos los datos estén actualizados
            productoRepository
                .invalidateCache(); // Sin parámetro = invalidar todo
            debugPrint(
              'ProductosForm: Caché global invalidada para producto existente',
            );
          } else {
            // Para productos nuevos, solo invalidar la sucursal actual
            productoRepository.invalidateCache(sucursalId);
            debugPrint(
              'ProductosForm: Caché invalidada para sucursal: $sucursalId',
            );
          }

          // Mensaje de depuración al limpiar la caché
          debugPrint('ProductosForm: Producto guardado. Actualizando datos...');

          // Recargar datos si estamos editando un producto existente
          if (widget.producto != null) {
            await _recargarDatos();
          }

          debugPrint('ProductosForm: Datos actualizados correctamente');

          if (mounted) {
            // Limpiar cualquier SnackBar existente
            ScaffoldMessenger.of(context).clearSnackBars();

            // Mostrar mensaje de éxito
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Producto guardado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );

            // Pasar callback con el producto actualizado si está disponible
            widget.onSave(productoData);

            // Cerrar el diálogo y notificar a la vista padre que debe actualizarse
            Navigator.pop(context, true);
          }
        } catch (e) {
          debugPrint('ProductosForm: ERROR al guardar producto: $e');

          if (mounted) {
            // Limpiar cualquier SnackBar existente
            ScaffoldMessenger.of(context).clearSnackBars();

            // Mostrar mensaje de error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al guardar producto: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }

      // Iniciar el proceso de guardado
      saveProducto();
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedImageFile = File(result.files.single.path!);
        _previewImageUrl = null;
      });
    }
  }

  @override
  void dispose() {
    _nombreController.removeListener(_onFieldChanged);
    _descripcionController.removeListener(_onFieldChanged);
    _precioVentaController.removeListener(_onFieldChanged);
    _stockController.removeListener(_onFieldChanged);
    _skuController.removeListener(_onFieldChanged);
    _marcaController.removeListener(_onFieldChanged);
    _precioCompraController.removeListener(_onFieldChanged);
    _colorController.removeListener(_onFieldChanged);
    _stockMinimoController.removeListener(_onFieldChanged);
    _precioOfertaController.removeListener(_onFieldChanged);
    _cantidadMinimaDescuentoController.removeListener(_onFieldChanged);
    _porcentajeDescuentoController.removeListener(_onFieldChanged);
    _cantidadGratisDescuentoController.removeListener(_onFieldChanged);

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
