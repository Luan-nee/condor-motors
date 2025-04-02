import 'dart:math' show min;

import 'package:condorsmotors/models/ventas.model.dart';
import 'package:condorsmotors/providers/admin/ventas.provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VentaDetalleDialog extends StatefulWidget {
  final dynamic venta;
  final bool isLoadingFullData;
  final Function(String)? onDeclararPressed;

  const VentaDetalleDialog({
    super.key,
    required this.venta,
    this.isLoadingFullData = false,
    this.onDeclararPressed,
  });

  @override
  State<VentaDetalleDialog> createState() => _VentaDetalleDialogState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('venta', venta))
      ..add(DiagnosticsProperty<bool>('isLoadingFullData', isLoadingFullData))
      ..add(ObjectFlagProperty<Function(String)?>.has(
          'onDeclararPressed', onDeclararPressed));
  }
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

  // Obtener referencia al provider
  VentasProvider get _ventasProvider =>
      Provider.of<VentasProvider>(context, listen: false);

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
      _animationController
        ..reset()
        ..forward();
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
      // Usar el método del provider para calcular total
      total = _ventasProvider.calcularTotalVenta(widget.venta);
    } else {
      total = widget.venta.calcularTotal();
    }

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: min(MediaQuery.of(context).size.width * 0.05, 24.0),
        vertical: min(MediaQuery.of(context).size.height * 0.05, 24.0),
      ),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _opacityAnimation,
            child: Stack(
              children: [
                Container(
                  width: min(MediaQuery.of(context).size.width * 0.9, 900),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
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
    // Verificar si existe documento PDF usando el provider
    final bool tienePdf = _ventasProvider.tienePdfDisponible(widget.venta);

    // Obtener estado de declarada/anulada
    final bool declarada = widget.venta is Venta
        ? widget.venta.declarada
        : (widget.venta is Map ? widget.venta['declarada'] ?? false : false);

    final bool anulada = widget.venta is Venta
        ? widget.venta.anulada
        : (widget.venta is Map ? widget.venta['anulada'] ?? false : false);

    // Obtener URL del PDF usando el provider
    final String? pdfLink = _ventasProvider.obtenerUrlPdf(widget.venta);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: FaIcon(
                      tienePdf
                          ? FontAwesomeIcons.filePdf
                          : FontAwesomeIcons.fileInvoice,
                      color: Color(0xFFE31E24),
                      size: 16,
                    ),
                  ),
                ),
                // Indicador visual para declarada/anulada si es aplicable
                if (declarada || anulada)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: anulada
                            ? Colors.red
                            : (declarada ? Colors.green : Colors.transparent),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
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
        Row(
          children: [
            if (tienePdf)
              IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.filePdf,
                  color: Colors.blue,
                  size: 18,
                ),
                tooltip: 'Ver PDF',
                onPressed: () => pdfLink != null
                    ? _ventasProvider.abrirPdf(pdfLink, context)
                    : null,
              ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white54),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
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
    // Extraer información adicional
    final bool declarada = isVenta
        ? widget.venta.declarada
        : (isMap ? widget.venta['declarada'] ?? false : false);

    final bool anulada = isVenta
        ? widget.venta.anulada
        : (isMap ? widget.venta['anulada'] ?? false : false);

    // Obtener hora de emisión
    final String horaEmision = isVenta
        ? widget.venta.horaEmision
        : (isMap ? widget.venta['horaEmision'] ?? '' : '');

    // Obtener información del empleado
    final String empleado = isVenta
        ? (widget.venta.empleadoDetalle != null
            ? widget.venta.empleadoDetalle!.getNombreCompleto()
            : 'No especificado')
        : (isMap && widget.venta['empleado'] != null
            ? '${widget.venta['empleado']['nombre']} ${widget.venta['empleado']['apellidos']}'
            : 'No especificado');

    // Obtener información de la sucursal
    final String sucursal = isVenta
        ? (widget.venta.sucursalDetalle?.nombre ?? 'No especificada')
        : (isMap && widget.venta['sucursal'] != null
            ? widget.venta['sucursal']['nombre'] ?? 'No especificada'
            : 'No especificada');

    // Determinar si estamos en pantalla pequeña
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

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
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: isSmallScreen ? double.infinity : 180,
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
                  SizedBox(
                    width: isSmallScreen ? double.infinity : 180,
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
                            color: _ventasProvider
                                .getEstadoColor(estadoText)
                                .withOpacity(
                                    widget.isLoadingFullData ? 0.1 : 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                estadoText,
                                style: TextStyle(
                                  color: _ventasProvider
                                      .getEstadoColor(estadoText),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              if (declarada || anulada)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color:
                                          anulada ? Colors.red : Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: isSmallScreen ? double.infinity : 180,
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
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: isSmallScreen ? double.infinity : 180,
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
                  SizedBox(
                    width: isSmallScreen ? double.infinity : 180,
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
                  SizedBox(
                    width: isSmallScreen ? double.infinity : 180,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hora Emisión',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            key: ValueKey<String>('hora-$horaEmision'),
                            horaEmision.isNotEmpty
                                ? horaEmision
                                : 'No registrado',
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

              const SizedBox(height: 16),

              // Tercera fila
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: isSmallScreen ? double.infinity : 180,
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
                  SizedBox(
                    width: isSmallScreen ? double.infinity : 180,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Empleado',
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
                                'empleado-${empleado.hashCode}'),
                            empleado,
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
                  SizedBox(
                    width: isSmallScreen ? double.infinity : 180,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sucursal',
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
                                'sucursal-${sucursal.hashCode}'),
                            sucursal,
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

              // Sección de estados adicionales
              if (declarada || anulada)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: anulada
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        FaIcon(
                          anulada
                              ? FontAwesomeIcons.ban
                              : FontAwesomeIcons.check,
                          color: anulada ? Colors.red : Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            anulada
                                ? 'Esta venta ha sido anulada'
                                : 'Esta venta ha sido declarada a SUNAT',
                            style: TextStyle(
                              color: anulada ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
    // Definir una altura máxima para la lista de productos
    final double maxProductListHeight =
        MediaQuery.of(context).size.height * 0.3;

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
            maxHeight: maxProductListHeight,
            minHeight: min(detalles.length * 50.0, maxProductListHeight),
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
              // Usar physics NeverScrollableScrollPhysics si hay pocos elementos
              physics: detalles.length <= 3
                  ? const NeverScrollableScrollPhysics()
                  : const ClampingScrollPhysics(),
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
    // Verificar el estado de la venta para mostrar botones apropiados
    final bool isMap = widget.venta is Map;
    final bool isVenta = widget.venta is Venta;

    // Obtener el ID de la venta
    final String idVenta =
        isMap ? widget.venta['id'].toString() : widget.venta.id.toString();

    // Verificar si la venta está declarada o anulada
    final bool declarada = isVenta
        ? widget.venta.declarada
        : (isMap ? widget.venta['declarada'] ?? false : false);

    final bool anulada = isVenta
        ? widget.venta.anulada
        : (isMap ? widget.venta['anulada'] ?? false : false);

    // Verificar si tiene PDF usando el provider
    final bool tienePdf = _ventasProvider.tienePdfDisponible(widget.venta);
    final String? pdfLink = _ventasProvider.obtenerUrlPdf(widget.venta);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Botón para declarar venta (solo si no está declarada ni anulada)
        if (!declarada && !anulada && widget.onDeclararPressed != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              icon: const FaIcon(
                FontAwesomeIcons.receipt,
                size: 16,
              ),
              label: const Text('Declarar a SUNAT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D8B95),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // Confirmar antes de declarar
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmar Declaración'),
                    content: const Text(
                      '¿Está seguro que desea declarar esta venta a SUNAT? '
                      'Esta acción no se puede deshacer.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onDeclararPressed!(idVenta);
                        },
                        child: const Text('Declarar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

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
            if (tienePdf && pdfLink != null) {
              // Usar el método del provider para imprimir
              _ventasProvider.imprimirDocumentoPdf(
                pdfLink,
                'Venta_${_ventasProvider.obtenerNumeroDocumento(widget.venta)}',
                context,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'La venta debe ser declarada primero para generar el PDF'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
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
            : (index * 0.05 > 0.5 ? 0.5 : index * 0.5);
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
}
