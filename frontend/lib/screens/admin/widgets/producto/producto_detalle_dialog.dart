import 'package:condorsmotors/models/color.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/providers/admin/producto.admin.provider.dart';
import 'package:condorsmotors/utils/productos_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class ProductoDetalleDialog extends StatefulWidget {
  final Producto producto;
  final List<Sucursal> sucursales;
  final Function(Producto)? onSave;

  const ProductoDetalleDialog({
    super.key,
    required this.producto,
    required this.sucursales,
    this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required Producto producto,
    required List<Sucursal> sucursales,
    required Future<void> Function(Producto) onSave,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => ProductoDetalleDialog(
        producto: producto,
        sucursales: sucursales,
        onSave: (Producto productoActualizado) {
          // Solo notificamos que se actualizó el producto sin volver a guardarlo
          onSave(productoActualizado);
        },
      ),
    );
  }

  @override
  State<ProductoDetalleDialog> createState() => _ProductoDetalleDialogState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Producto>('producto', producto))
      ..add(IterableProperty<Sucursal>('sucursales', sucursales))
      ..add(ObjectFlagProperty<Function(Producto)?>.has('onSave', onSave));
  }
}

class _ProductoDetalleDialogState extends State<ProductoDetalleDialog>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  List<ProductoEnSucursal> _sucursalesCompartidas = <ProductoEnSucursal>[];
  ColorApp? _colorProducto;
  String _error = '';

  // Controlador para pestañas
  late TabController _atributosTabController;

  @override
  void initState() {
    super.initState();
    _cargarDetallesProducto();
    _cargarColores();

    // Inicializar controlador de pestañas
    _atributosTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _atributosTabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDetallesProducto() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final ProductoProvider productoProvider =
          Provider.of<ProductoProvider>(context, listen: false);

      // Usar el método del provider y obtener el resultado
      final List<ProductoEnSucursal> sucursales =
          await productoProvider.obtenerProductoEnSucursales(
        productoId: widget.producto.id,
        sucursales: widget.sucursales,
      );

      // Verificar si hay un error en el provider después de la operación
      if (productoProvider.errorMessage != null) {
        throw Exception(productoProvider.errorMessage);
      }

      if (mounted) {
        setState(() {
          _sucursalesCompartidas = sucursales;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              'No se pudieron cargar los detalles del producto: ${e.toString().replaceAll('Exception: ', '')}';
          _isLoading = false;
        });
        debugPrint('Error al cargar detalles del producto: $e');
      }
    }
  }

  Future<void> _cargarColores() async {
    try {
      final ProductoProvider productoProvider =
          Provider.of<ProductoProvider>(context, listen: false);

      if (mounted) {
        setState(() {
          // Si el producto tiene color, buscar la coincidencia usando el provider
          if (widget.producto.color != null &&
              widget.producto.color!.isNotEmpty) {
            _colorProducto =
                productoProvider.obtenerColorPorNombre(widget.producto.color!);
          }
        });
      }
    } catch (e) {
      debugPrint('Error al cargar colores: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el ancho de la pantalla para responsive
    final double screenWidth = MediaQuery.of(context).size.width;
    // Determinar si es pantalla pequeña (< 800px)
    final bool isPantallaReducida = screenWidth < 800;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 1000,
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Encabezado común
            _buildHeader(context),
            const SizedBox(height: 16),

            // Información básica del producto (destacada arriba)
            _buildProductoBasicInfo(isPantallaReducida),
            const SizedBox(height: 16),

            // Contenido principal (ocupa todo el ancho)
            Expanded(
              child: _buildTabBars(isPantallaReducida),
            ),

            const SizedBox(height: 16),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        const Expanded(
          child: Text(
            'Detalles del Producto en Sucursales',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white70, size: 26),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  // Nuevo método para mostrar solo la información básica del producto
  Widget _buildProductoBasicInfo(bool isPantallaReducida) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      color: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Imagen del producto o ícono
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: widget.producto.pathFoto != null &&
                      widget.producto.pathFoto!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.producto.pathFoto!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(FontAwesomeIcons.box,
                                size: 32, color: Colors.white24),
                      ),
                    )
                  : Center(
                      child: FaIcon(
                        FontAwesomeIcons.box,
                        size: 32,
                        color: widget.producto.tieneStockBajo()
                            ? const Color(0xFFE31E24).withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            // Información principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          widget.producto.nombre,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (widget.producto.liquidacion) ...<Widget>[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              FaIcon(
                                FontAwesomeIcons.tag,
                                size: 12,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'EN LIQUIDACIÓN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <Widget>[
                        _buildTag('SKU: ${widget.producto.sku}',
                            fontFamily: 'monospace'),
                        const SizedBox(width: 8),
                        _buildTag(widget.producto.categoria),
                        const SizedBox(width: 8),
                        _buildTag(widget.producto.marca),
                        if (widget.producto.color != null &&
                            widget.producto.color!.isNotEmpty) ...<Widget>[
                          const SizedBox(width: 8),
                          _buildColorTag(
                              widget.producto.color!, _colorProducto),
                        ],
                      ],
                    ),
                  ),
                  if (widget.producto.descripcion != null &&
                      widget.producto.descripcion!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      widget.producto.descripcion!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nuevo método para combinar ambas barras de pestañas
  Widget _buildTabBars(bool isPantallaReducida) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      color: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Contenedor para todas las pestañas
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isPantallaReducida ? 12.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Título "Detalles"
                  const Row(
                    children: <Widget>[
                      FaIcon(
                        FontAwesomeIcons.circleInfo,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Detalles',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pestañas
                  Container(
                    height: isPantallaReducida ? 40 : 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: TabBar(
                      controller: _atributosTabController,
                      isScrollable: true,
                      indicatorColor: const Color(0xFFE31E24),
                      indicatorSize: TabBarIndicatorSize.label,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      padding: EdgeInsets.symmetric(
                          horizontal: isPantallaReducida ? 4 : 8),
                      labelPadding: EdgeInsets.symmetric(
                          horizontal: isPantallaReducida ? 8 : 12),
                      tabs: <Widget>[
                        Tab(
                          height: isPantallaReducida ? 34 : 40,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              FaIcon(FontAwesomeIcons.moneyBillWave,
                                  size: isPantallaReducida ? 14 : 16,
                                  color: Colors.green.shade700),
                              SizedBox(width: isPantallaReducida ? 4 : 8),
                              const Text('Precios',
                                  style: TextStyle(fontSize: 15)),
                            ],
                          ),
                        ),
                        Tab(
                          height: isPantallaReducida ? 34 : 40,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              FaIcon(FontAwesomeIcons.boxOpen,
                                  size: isPantallaReducida ? 14 : 16,
                                  color: const Color(0xFFE31E24)),
                              SizedBox(width: isPantallaReducida ? 4 : 8),
                              const Text('Stock',
                                  style: TextStyle(fontSize: 15)),
                            ],
                          ),
                        ),
                        Tab(
                          height: isPantallaReducida ? 34 : 40,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              FaIcon(FontAwesomeIcons.chartPie,
                                  size: isPantallaReducida ? 14 : 16,
                                  color: Colors.blue),
                              SizedBox(width: isPantallaReducida ? 4 : 8),
                              const Text('Estadísticas',
                                  style: TextStyle(fontSize: 15)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Área para mostrar el contenido combinado de las pestañas
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Card(
                        margin: EdgeInsets.zero,
                        color: const Color(0xFF1A1A1A),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        child: TabBarView(
                          controller: _atributosTabController,
                          children: <Widget>[
                            // Pestaña de Precios (ahora con descuentos y precios por sucursal)
                            _buildPreciosTab(isPantallaReducida),

                            // Pestaña de Stock (con lista de sucursales integrada)
                            _buildStockConSucursales(isPantallaReducida),

                            // Pestaña de Estadísticas
                            _buildEstadisticasTab(isPantallaReducida),
                          ],
                        ),
                      ),
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

  // Nueva pestaña de estadísticas
  Widget _buildEstadisticasTab(bool isPantallaReducida) {
    // Obtener el provider una sola vez para todas las operaciones
    Provider.of<ProductoProvider>(context, listen: false);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isPantallaReducida ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Sección de estadísticas generales
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Estadísticas Generales',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Indicadores de estadísticas
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: <Widget>[
                      _buildCompactEstadistica(
                        'Sucursales',
                        _isLoading ? '...' : '${_sucursalesCompartidas.length}',
                        icon: FontAwesomeIcons.store,
                        color: Colors.blue,
                        isSmall: isPantallaReducida,
                      ),
                      _buildCompactEstadistica(
                        'Con stock',
                        _isLoading ? '...' : '${_obtenerCantidadConStock()}',
                        icon: FontAwesomeIcons.boxOpen,
                        color: Colors.green,
                        isSmall: isPantallaReducida,
                      ),
                      _buildCompactEstadistica(
                        'Stock bajo',
                        _isLoading ? '...' : '${_obtenerCantidadStockBajo()}',
                        icon: FontAwesomeIcons.triangleExclamation,
                        color: const Color(0xFFE31E24),
                        isSmall: isPantallaReducida,
                      ),
                      _buildCompactEstadistica(
                        'Agotado',
                        _isLoading ? '...' : '${_obtenerCantidadAgotados()}',
                        icon: FontAwesomeIcons.ban,
                        color: Colors.red.shade800,
                        isSmall: isPantallaReducida,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Información adicional
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Información Adicional',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Información adicional que estaba en la tercera pestaña
                  if (isPantallaReducida) _buildInfoAdicionalWrap() else _buildInfoAdicionalRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Métodos auxiliares para calcular estadísticas (mejora la legibilidad y reutilización)
  int _obtenerCantidadConStock() {
    return _sucursalesCompartidas
        .where((s) => s.disponible && s.producto.stock > 0)
        .length;
  }

  int _obtenerCantidadStockBajo() {
    return _sucursalesCompartidas
        .where((s) => s.disponible && s.producto.tieneStockBajo())
        .length;
  }

  int _obtenerCantidadAgotados() {
    return _sucursalesCompartidas
        .where((s) => s.disponible && s.producto.stock <= 0)
        .length;
  }

  // Estadística en formato compacto
  Widget _buildCompactEstadistica(String label, String valor,
      {required IconData icon, required Color color, bool isSmall = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FaIcon(
            icon,
            size: isSmall ? 12 : 14,
            color: color,
          ),
          SizedBox(width: isSmall ? 4 : 6),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontSize: isSmall ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: isSmall ? 3 : 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: isSmall ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        TextButton(
          child: const Text(
            'Cerrar',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  // Pestaña de Precios - Quitar la edición de liquidación
  Widget _buildPreciosTab(bool isPantallaReducida) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isPantallaReducida ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Sección de precios
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Información de Precios',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isPantallaReducida) _buildPreciosWrap() else _buildPreciosRow(),
                ],
              ),
            ),

            // Mostrar sección de liquidación en modo solo visualización
            if (widget.producto.liquidacion ||
                widget.producto.cantidadMinimaDescuento != null ||
                widget.producto.porcentajeDescuento != null) ...<Widget>[
              const SizedBox(height: 16),
              // Llamamos a nuestra función de visualización de promociones
              _buildPromocionesInfo(),
            ],

            // Divisor
            const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 1),

            // Título de sección de precios por sucursal
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 16, 0, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Precios por Sucursal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Lista de precios por sucursal
            _buildPreciosPorSucursal(),
          ],
        ),
      ),
    );
  }

  // Construye la lista de precios por sucursal
  Widget _buildPreciosPorSucursal() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              color: Color(0xFFE31E24),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _error,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar', style: TextStyle(fontSize: 15)),
              onPressed: _cargarDetallesProducto,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE31E24),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Mostramos todas las sucursales disponibles
    final List<ProductoEnSucursal> sucursalesDisponibles =
        _sucursalesCompartidas
            .where((ProductoEnSucursal s) => s.disponible)
            .toList();

    if (sucursalesDisponibles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FaIcon(
              FontAwesomeIcons.store,
              size: 48,
              color: Colors.white24,
            ),
            SizedBox(height: 16),
            Text(
              'Este producto no está disponible en ninguna sucursal.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: sucursalesDisponibles.length,
      separatorBuilder: (BuildContext context, int index) => const Divider(
        color: Colors.white10,
        height: 1,
      ),
      itemBuilder: (BuildContext context, int index) {
        final ProductoEnSucursal sucursalInfo = sucursalesDisponibles[index];
        return _buildPreciosSucursalTile(sucursalInfo);
      },
    );
  }

  // Tile para mostrar precios por sucursal
  Widget _buildPreciosSucursalTile(ProductoEnSucursal sucursalInfo) {
    final Producto producto = sucursalInfo.producto;
    final Sucursal sucursal = sucursalInfo.sucursal;
    final bool esCentral = sucursal.sucursalCentral;
    final bool tieneOferta = producto.estaEnOferta();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Contenedor coloreado para sucursal central
          if (esCentral)
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(width: 4),
          const SizedBox(width: 12),

          // Información principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Nombre de sucursal y etiqueta central
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        sucursal.nombre,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (esCentral)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: Colors.blue,
                          ),
                        ),
                        child: const Text(
                          'CENTRAL',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Información de precios en formato de tarjetas
                Row(
                  children: <Widget>[
                    // Precio compra
                    _buildPrecioChip(
                      'Compra',
                      producto.getPrecioCompraFormateado(),
                      Colors.blue,
                      FontAwesomeIcons.cartShopping,
                    ),
                    const SizedBox(width: 8),

                    // Precio venta
                    _buildPrecioChip(
                      'Venta',
                      producto.getPrecioVentaFormateado(),
                      Colors.green,
                      FontAwesomeIcons.tag,
                    ),

                    // Precio liquidación (sólo si tiene)
                    if (tieneOferta) ...[
                      const SizedBox(width: 8),
                      _buildPrecioChip(
                        'Liquidación',
                        producto.getPrecioOfertaFormateado() ?? 'N/A',
                        Colors.amber,
                        FontAwesomeIcons.percent,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                // Margen y ganancia
                Row(
                  children: <Widget>[
                    // Ganancia
                    Text(
                      'Ganancia: ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      ProductosUtils.formatearPrecio(producto.getGanancia()),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Margen
                    Text(
                      'Margen: ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      ProductosUtils.formatearPorcentaje(
                          producto.getMargenPorcentaje()),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
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

  // Widget para crear una tarjeta con precio
  Widget _buildPrecioChip(
      String label, String precio, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FaIcon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.9),
                ),
              ),
              Text(
                precio,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Nueva función para mostrar el resumen de las promociones en la pestaña de precios
  Widget _buildPromocionesInfo() {
    final Producto producto = widget.producto;
    final bool enLiquidacion = producto.liquidacion;
    final bool tienePromocionGratis =
        producto.cantidadGratisDescuento != null &&
            producto.cantidadGratisDescuento! > 0;
    final bool tieneDescuentoPorcentual =
        producto.cantidadMinimaDescuento != null &&
            producto.cantidadMinimaDescuento! > 0 &&
            producto.porcentajeDescuento != null &&
            producto.porcentajeDescuento! > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Mostrar resumen de cada promoción activa
        if (enLiquidacion)
          _buildResumenPromocion(
              'Liquidación Activa',
              'Precio de liquidación: ${producto.getPrecioOfertaFormateado() ?? "N/A"}',
              Colors.amber,
              FontAwesomeIcons.tag),

        if (tienePromocionGratis) ...<Widget>[
          if (enLiquidacion) const SizedBox(height: 8),
          _buildResumenPromocion(
              'Promoción: Lleva y Paga',
              'Lleva ${producto.cantidadMinimaDescuento}, paga ${producto.cantidadMinimaDescuento! - producto.cantidadGratisDescuento!}',
              Colors.green,
              FontAwesomeIcons.gift),
        ],

        if (tieneDescuentoPorcentual) ...<Widget>[
          if (enLiquidacion || tienePromocionGratis) const SizedBox(height: 8),
          _buildResumenPromocion(
              'Descuento por Cantidad',
              '${producto.porcentajeDescuento}% al comprar ${producto.cantidadMinimaDescuento} o más',
              Colors.blue,
              FontAwesomeIcons.percent),
        ],
      ],
    );
  }

  // Método auxiliar para construir el resumen de cada promoción
  Widget _buildResumenPromocion(
      String titulo, String descripcion, Color color, IconData icono) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: <Widget>[
          FaIcon(
            icono,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  descripcion,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Métodos para la pestaña de precios
  Widget _buildPreciosRow() {
    return Row(
      children: <Widget>[
        Expanded(
            child: _buildAtributo(
                'Precio compra', widget.producto.getPrecioCompraFormateado())),
        Expanded(
            child: _buildAtributo(
                'Precio venta', widget.producto.getPrecioVentaFormateado())),
        if (widget.producto.estaEnOferta())
          Expanded(
              child: _buildAtributo('Precio de liquidación',
                  widget.producto.getPrecioOfertaFormateado() ?? '',
                  color: Colors.amber)),
        Expanded(
            child: _buildAtributo('Ganancia',
                ProductosUtils.formatearPrecio(widget.producto.getGanancia()))),
        Expanded(
            child: _buildAtributo(
                'Margen',
                ProductosUtils.formatearPorcentaje(
                    widget.producto.getMargenPorcentaje()))),
      ],
    );
  }

  Widget _buildPreciosWrap() {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: <Widget>[
          SizedBox(
              width: 150,
              child: _buildAtributo('Precio compra',
                  widget.producto.getPrecioCompraFormateado())),
          SizedBox(
              width: 150,
              child: _buildAtributo(
                  'Precio venta', widget.producto.getPrecioVentaFormateado())),
          if (widget.producto.estaEnOferta())
            SizedBox(
                width: 150,
                child: _buildAtributo('Precio liquidación',
                    widget.producto.getPrecioOfertaFormateado() ?? '',
                    color: Colors.amber)),
          SizedBox(
              width: 150,
              child: _buildAtributo(
                  'Ganancia',
                  ProductosUtils.formatearPrecio(
                      widget.producto.getGanancia()))),
          SizedBox(
              width: 150,
              child: _buildAtributo(
                  'Margen',
                  ProductosUtils.formatearPorcentaje(
                      widget.producto.getMargenPorcentaje()))),
        ],
      ),
    );
  }

  // Métodos para la pestaña de stock
  Widget _buildStockConSucursales(bool isPantallaReducida) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Información básica de stock del producto
          Padding(
            padding: EdgeInsets.all(isPantallaReducida ? 12.0 : 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Información de Stock',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Cambiamos a formato similar a precios (en 4 columnas o wrap)
                  if (isPantallaReducida) _buildStockWrap() else _buildStockRow(),
                ],
              ),
            ),
          ),

          // Divisor
          const Divider(color: Colors.white24, height: 1),

          // Título de sección con filtros
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Stock por Sucursal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Lista de sucursales filtradas (sin Expanded para permitir scroll)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildSucursalesLista(),
          ),
        ],
      ),
    );
  }

  Widget _buildSucursalesLista() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              color: Color(0xFFE31E24),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _error,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar', style: TextStyle(fontSize: 15)),
              onPressed: _cargarDetallesProducto,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE31E24),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Ya no usamos filtrado, mostramos todas las sucursales disponibles
    final List<ProductoEnSucursal> sucursalesDisponibles =
        _sucursalesCompartidas
            .where((ProductoEnSucursal s) => s.disponible)
            .toList();

    if (sucursalesDisponibles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FaIcon(
              FontAwesomeIcons.store,
              size: 48,
              color: Colors.white24,
            ),
            SizedBox(height: 16),
            Text(
              'Este producto no está disponible en ninguna sucursal.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: sucursalesDisponibles.length,
      separatorBuilder: (BuildContext context, int index) => const Divider(
        color: Colors.white10,
        height: 1,
      ),
      itemBuilder: (BuildContext context, int index) {
        final ProductoEnSucursal sucursalInfo = sucursalesDisponibles[index];
        return _buildCompactSucursalTile(sucursalInfo);
      },
    );
  }

  // Versión compacta del tile de sucursal
  Widget _buildCompactSucursalTile(ProductoEnSucursal sucursalInfo) {
    final bool disponible = sucursalInfo.disponible;
    final Producto producto = sucursalInfo.producto;
    final Sucursal sucursal = sucursalInfo.sucursal;

    final bool stockBajo = disponible && producto.tieneStockBajo();
    final bool agotado = disponible && producto.stock <= 0;
    final bool esCentral = sucursal.sucursalCentral;

    Color indicadorColor = Colors.green;
    IconData statusIcon = FontAwesomeIcons.check;
    String statusText = 'Disponible';

    if (!disponible) {
      indicadorColor = Colors.grey;
      statusIcon = FontAwesomeIcons.ban;
      statusText = 'No disponible';
    } else if (agotado) {
      indicadorColor = Colors.red.shade800;
      statusIcon = FontAwesomeIcons.ban;
      statusText = 'Agotado';
    } else if (stockBajo) {
      indicadorColor = const Color(0xFFE31E24);
      statusIcon = FontAwesomeIcons.triangleExclamation;
      statusText = 'Stock bajo';
    }

    // Versión compacta del tile
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: <Widget>[
          // Indicador de estado (barra vertical)
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: indicadorColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // Información principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Nombre de sucursal y etiqueta central
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        sucursal.nombre,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (esCentral)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: Colors.blue,
                          ),
                        ),
                        child: const Text(
                          'CENTRAL',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),

                // Dirección en formato compacto
                Text(
                  sucursal.direccion ?? 'Sin dirección registrada',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                    fontStyle: sucursal.direccion != null
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Etiquetas de información en una sola fila
                Row(
                  children: <Widget>[
                    // Estado (Disponible, Stock bajo, etc.)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: indicadorColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: indicadorColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          FaIcon(
                            statusIcon,
                            size: 10,
                            color: indicadorColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: indicadorColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (disponible) ...<Widget>[
                      const SizedBox(width: 8),

                      // Stock
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text(
                              'Stock: ',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${producto.stock}',
                              style: TextStyle(
                                color: indicadorColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (producto.stockMinimo != null)
                              Text(
                                '/${producto.stockMinimo}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Métodos para la pestaña de stock
  Widget _buildStockRow() {
    return Row(
      children: <Widget>[
        Expanded(
            child: _buildAtributo('Stock actual', '${widget.producto.stock}',
                color: widget.producto.tieneStockBajo()
                    ? const Color(0xFFE31E24)
                    : null)),
        Expanded(
            child: _buildAtributo('Stock mínimo',
                '${widget.producto.stockMinimo ?? "No definido"}')),
        Expanded(
            child: _buildAtributo(
                'Estado',
                widget.producto.tieneStockBajo()
                    ? 'Stock bajo'
                    : (widget.producto.stock <= 0 ? 'Agotado' : 'Disponible'),
                color: widget.producto.tieneStockBajo()
                    ? const Color(0xFFE31E24)
                    : (widget.producto.stock <= 0
                        ? Colors.red
                        : Colors.green))),
      ],
    );
  }

  Widget _buildStockWrap() {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: <Widget>[
          SizedBox(
              width: 150,
              child: _buildAtributo('Stock actual', '${widget.producto.stock}',
                  color: widget.producto.tieneStockBajo()
                      ? const Color(0xFFE31E24)
                      : null)),
          SizedBox(
              width: 150,
              child: _buildAtributo('Stock mínimo',
                  '${widget.producto.stockMinimo ?? "No definido"}')),
          SizedBox(
              width: 150,
              child: _buildAtributo(
                  'Estado',
                  widget.producto.tieneStockBajo()
                      ? 'Stock bajo'
                      : (widget.producto.stock <= 0 ? 'Agotado' : 'Disponible'),
                  color: widget.producto.tieneStockBajo()
                      ? const Color(0xFFE31E24)
                      : (widget.producto.stock <= 0
                          ? Colors.red
                          : Colors.green))),
        ],
      ),
    );
  }

  // Métodos para la pestaña de información adicional
  Widget _buildInfoAdicionalRow() {
    return Row(
      children: <Widget>[
        Expanded(child: _buildAtributo('ID', '${widget.producto.id}')),
        if (widget.producto.detalleProductoId != null)
          Expanded(
              child: _buildAtributo(
                  'ID Detalle', '${widget.producto.detalleProductoId}')),
        Expanded(
            child: _buildAtributo('Fecha creación',
                '${widget.producto.fechaCreacion.day}/${widget.producto.fechaCreacion.month}/${widget.producto.fechaCreacion.year}')),
        // Expandir para llenar espacio
        Expanded(child: Container()),
      ],
    );
  }

  Widget _buildInfoAdicionalWrap() {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: <Widget>[
          SizedBox(
              width: 150,
              child:
                  _buildAtributo('ID del producto', '${widget.producto.id}')),
          if (widget.producto.detalleProductoId != null)
            SizedBox(
                width: 150,
                child: _buildAtributo(
                    'ID Detalle', '${widget.producto.detalleProductoId}')),
          SizedBox(
              width: 150,
              child: _buildAtributo('Fecha creación',
                  '${widget.producto.fechaCreacion.day}/${widget.producto.fechaCreacion.month}/${widget.producto.fechaCreacion.year}')),
        ],
      ),
    );
  }

  // Widget para crear una etiqueta con valor
  Widget _buildAtributo(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.white,
          ),
        ),
      ],
    );
  }

  // Widget para crear una etiqueta/tag
  Widget _buildTag(String text, {String? fontFamily}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontFamily: fontFamily,
          color: Colors.white70,
        ),
      ),
    );
  }

  // Widget para crear una etiqueta de color con muestra visual
  Widget _buildColorTag(String colorNombre, ColorApp? colorApp) {
    // Determinar el color a mostrar
    Color colorVisual = Colors.grey;

    if (colorApp != null) {
      // Si tenemos el objeto de color, usar su método toColor()
      colorVisual = colorApp.toColor();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Muestra visual del color
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: colorVisual,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Nombre del color
          Text(
            colorNombre,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          // Código hexadecimal (si está disponible)
          if (colorApp?.hex != null && colorApp!.hex!.isNotEmpty) ...<Widget>[
            const SizedBox(width: 4),
            Text(
              colorApp.hex!.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: Colors.white54,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
