import 'package:condorsmotors/models/ventas.model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class VentaDetalleDialog extends StatefulWidget {
  final dynamic venta;
  final bool isLoadingFullData;

  const VentaDetalleDialog({
    super.key,
    required this.venta,
    this.isLoadingFullData = false,
  });

  @override
  State<VentaDetalleDialog> createState() => _VentaDetalleDialogState();
}

class _VentaDetalleDialogState extends State<VentaDetalleDialog>
    with SingleTickerProviderStateMixin {
  final NumberFormat _formatoMoneda = NumberFormat.currency(
    symbol: 'S/ ',
    decimalDigits: 2,
  );
  final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

  // Controlador de animación
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(VentaDetalleDialog oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si cambiaron los datos o el estado de carga, animar
    if (oldWidget.venta != widget.venta ||
        oldWidget.isLoadingFullData != widget.isLoadingFullData) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Verificar si es un objeto Map o un objeto Venta
    final bool isMap = widget.venta is Map;
    final bool isVenta = widget.venta is Venta;

    // Extraer información común según el tipo
    final String idVenta =
        isMap ? widget.venta['id'].toString() : widget.venta.id.toString();
    final DateTime fechaCreacion = isMap
        ? (widget.venta['fechaCreacion'] != null
            ? DateTime.parse(widget.venta['fechaCreacion'])
            : (widget.venta['fecha_creacion'] != null
                ? DateTime.parse(widget.venta['fecha_creacion'])
                : DateTime.now()))
        : widget.venta.fechaCreacion;

    final String serie = isMap
        ? (widget.venta['serieDocumento'] ?? '').toString()
        : widget.venta.serieDocumento;

    final String numero = isMap
        ? (widget.venta['numeroDocumento'] ?? '').toString()
        : widget.venta.numeroDocumento;

    // Manejar el caso donde el estado puede venir como objeto o como string
    String estadoText;
    if (isMap) {
      if (widget.venta['estado'] is Map) {
        // Formato del ejemplo JSON
        estadoText = ((widget.venta['estado'] as Map)['nombre'] ?? 'PENDIENTE')
            .toString()
            .toUpperCase();
      } else {
        estadoText =
            (widget.venta['estado'] ?? 'PENDIENTE').toString().toUpperCase();
      }
    } else {
      estadoText = isVenta ? widget.venta.estado.toText() : 'PENDIENTE';
    }

    // Datos del documento
    final String tipoDocumento = isMap
        ? (widget.venta['tipoDocumento'] ?? '').toString()
        : (isVenta ? (widget.venta.tipoDocumento ?? '') : '');

    // Datos del cliente
    final clienteNombre = isMap
        ? (widget.venta['cliente'] != null
            ? widget.venta['cliente']['denominacion'] ??
                'Cliente no especificado'
            : 'Cliente no especificado')
        : isVenta && widget.venta.clienteDetalle != null
            ? widget.venta.clienteDetalle!.denominacion
            : 'Cliente no especificado';

    // Obtener los detalles de la venta
    List<dynamic> detalles;
    if (isMap) {
      // Primero intentamos con 'detallesVenta' como en el ejemplo JSON
      if (widget.venta['detallesVenta'] is List) {
        detalles = widget.venta['detallesVenta'];
      }
      // Luego con 'detalles' como alternativa
      else if (widget.venta['detalles'] is List) {
        detalles = widget.venta['detalles'];
      } else {
        detalles = [];
      }
    } else {
      detalles = widget.venta.detalles;
    }

    // Calcular el total
    double total = 0.0;
    if (isMap) {
      // Intentar obtener el total del formato del ejemplo JSON
      if (widget.venta['totalesVenta'] != null &&
          widget.venta['totalesVenta']['totalVenta'] != null) {
        final totalValue = widget.venta['totalesVenta']['totalVenta'];
        if (totalValue is String) {
          total = double.tryParse(totalValue) ?? 0.0;
        } else {
          total = (totalValue ?? 0.0).toDouble();
        }
      } else {
        // Fallback al método existente
        total = _calcularTotal(widget.venta);
      }
    } else {
      total = widget.venta.calcularTotal();
    }

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _opacityAnimation,
            child: Stack(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabecera del diálogo
                      _buildHeader(
                          serie, numero, idVenta, fechaCreacion, context),

                      const SizedBox(height: 24),

                      // Información general
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: widget.isLoadingFullData
                                  ? Colors.black.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.2),
                              blurRadius: widget.isLoadingFullData ? 5 : 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: _buildInformacionGeneral(
                          estadoText,
                          idVenta,
                          total,
                          tipoDocumento,
                          serie,
                          numero,
                          clienteNombre,
                          isMap,
                          isVenta,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Listado de productos con animación
                      AnimatedOpacity(
                        opacity: widget.isLoadingFullData ? 0.7 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: _buildProductList(detalles, isMap, context),
                      ),

                      const SizedBox(height: 24),

                      // Botones de acción
                      _buildActionButtons(context),
                    ],
                  ),
                ),

                // Indicador de carga superpuesto cuando isLoadingFullData es true
                if (widget.isLoadingFullData)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE31E24),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Cargando datos completos...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Builder para la cabecera del diálogo
  Widget _buildHeader(String serie, String numero, String idVenta,
      DateTime fechaCreacion, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.fileInvoice,
                  color: Color(0xFFE31E24),
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serie.isNotEmpty && numero.isNotEmpty
                      ? '$serie-$numero'
                      : 'Venta #$idVenta',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatoFecha.format(fechaCreacion),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white54),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  // Builder para la sección de información general
  Widget _buildInformacionGeneral(
    String estadoText,
    String idVenta,
    double total,
    String tipoDocumento,
    String serie,
    String numero,
    String clienteNombre,
    bool isMap,
    bool isVenta,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Información General',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (widget.isLoadingFullData)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Datos principales con animación
        AnimatedOpacity(
          opacity: widget.isLoadingFullData ? 0.8 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Primera fila: ID, estado, total
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ID de Venta',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          idVenta,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estado',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getEstadoColor(estadoText).withOpacity(
                                widget.isLoadingFullData ? 0.1 : 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            estadoText,
                            style: TextStyle(
                              color: _getEstadoColor(estadoText),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.1),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            key: ValueKey<String>('total-$total'),
                            _formatoMoneda.format(total),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Segunda fila
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tipo de Documento',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            key: ValueKey<String>('tipo-$tipoDocumento'),
                            tipoDocumento,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Serie-Número',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          serie.isNotEmpty && numero.isNotEmpty
                              ? '$serie-$numero'
                              : 'No registrado',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cliente',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            key: ValueKey<String>(
                                'cliente-${clienteNombre.hashCode}'),
                            clienteNombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Builder para la lista de productos
  Widget _buildProductList(
      List<dynamic> detalles, bool isMap, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Líneas de Productos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),

        // Cabecera de la tabla
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 16,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF2D2D2D),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Producto',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Cant.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'Precio',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),

        // Lista de productos animada
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.3,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            border: Border.all(
              color: const Color(0xFF2D2D2D),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: ListView.builder(
              key: ValueKey<int>(detalles.length),
              shrinkWrap: true,
              itemCount: detalles.length,
              itemBuilder: (context, index) {
                final detalle = detalles[index];
                return _buildDetalleItem(detalle, isMap, index);
              },
            ),
          ),
        ),
      ],
    );
  }

  // Builder para botones de acción
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          icon: const FaIcon(
            FontAwesomeIcons.print,
            size: 16,
          ),
          label: const Text('Imprimir'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D2D2D),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Función en desarrollo'),
                backgroundColor: Colors.orange,
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          child: const Text('Cerrar'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  // Widget para cada línea de detalle con animación de entrada
  Widget _buildDetalleItem(detalle, bool isMap, int index) {
    // Adaptación para la estructura de detallesVenta del ejemplo JSON
    final String nombre =
        isMap ? detalle['nombre'] ?? 'Producto sin nombre' : detalle.nombre;

    final int cantidad = isMap
        ? (detalle['cantidad'] is String
            ? int.tryParse(detalle['cantidad']) ?? 0
            : detalle['cantidad'] ?? 0)
        : detalle.cantidad;

    // Adaptación para los precios según el formato del ejemplo JSON
    final double precio = isMap
        ? (detalle['precioConIgv'] is String
            ? double.tryParse(detalle['precioConIgv']) ?? 0.0
            : (detalle['precioConIgv'] ?? 0.0).toDouble())
        : detalle.precioConIgv;

    final double total = isMap
        ? (detalle['total'] is String
            ? double.tryParse(detalle['total']) ?? 0.0
            : (detalle['total'] ?? 0.0).toDouble())
        : detalle.total;

    // Animación que entra con retraso basado en el índice para un efecto secuencial
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final double delayFactor = widget.isLoadingFullData
            ? 0.0
            : (index * 0.05 > 0.5 ? 0.5 : index * 0.05);
        final double startValue = widget.isLoadingFullData ? 0.7 : 0.0;
        final double opacity = _animationController.value > delayFactor
            ? startValue +
                ((_animationController.value - delayFactor) /
                        (1 - delayFactor)) *
                    (1 - startValue)
            : startValue;

        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFF2D2D2D),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                nombre,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Expanded(
              child: Text(
                cantidad.toString(),
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Text(
                _formatoMoneda.format(precio),
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              child: Text(
                _formatoMoneda.format(total),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Obtener el color según el estado de la venta
  Color _getEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'COMPLETADA':
        return Colors.green;
      case 'ANULADA':
        return Colors.red;
      case 'DECLARADA':
        return Colors.blue;
      case 'ACEPTADO-SUNAT':
        return Colors.green;
      case 'ACEPTADO ANTE LA SUNAT':
        return Colors.green;
      case 'PENDIENTE':
      default:
        return Colors.orange;
    }
  }

  // Calcular el total de la venta
  double _calcularTotal(Map<String, dynamic> venta) {
    // Primero intentamos con el formato del ejemplo JSON (totalesVenta)
    if (venta.containsKey('totalesVenta') && venta['totalesVenta'] != null) {
      if (venta['totalesVenta']['totalVenta'] != null) {
        final value = venta['totalesVenta']['totalVenta'];
        if (value is String) {
          return double.tryParse(value) ?? 0.0;
        } else {
          return (value ?? 0.0).toDouble();
        }
      }
    }

    // Luego intentamos con el formato anterior
    if (venta.containsKey('total')) {
      final value = venta['total'];
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      } else {
        return (value ?? 0.0).toDouble();
      }
    } else if (venta.containsKey('subtotal') && venta.containsKey('igv')) {
      final subtotal = venta['subtotal'] is String
          ? double.tryParse(venta['subtotal']) ?? 0.0
          : (venta['subtotal'] ?? 0.0).toDouble();
      final igv = venta['igv'] is String
          ? double.tryParse(venta['igv']) ?? 0.0
          : (venta['igv'] ?? 0.0).toDouble();
      return subtotal + igv;
    }

    // Si no hay total, intentamos sumando los detalles
    double totalCalculado = 0.0;
    if (venta.containsKey('detallesVenta') && venta['detallesVenta'] is List) {
      for (var detalle in venta['detallesVenta']) {
        if (detalle is Map && detalle.containsKey('total')) {
          final total = detalle['total'] is String
              ? double.tryParse(detalle['total']) ?? 0.0
              : (detalle['total'] ?? 0.0).toDouble();
          totalCalculado += total;
        }
      }
      return totalCalculado;
    }

    return 0.0;
  }
}
