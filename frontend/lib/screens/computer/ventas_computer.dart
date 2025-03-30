import 'dart:async';

import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/proforma.model.dart' as models;
import 'package:condorsmotors/screens/computer/widgets/form_proforma.dart' as form_widget show ProformaSaleDialog;
import 'package:condorsmotors/screens/computer/widgets/form_proforma.dart' show NumericKeypad, ProcessingDialog;
import 'package:condorsmotors/screens/computer/widgets/proforma_conversion_utils.dart';
import 'package:condorsmotors/screens/computer/widgets/proforma_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Clase utilitaria para operaciones con ventas y formateo de montos
/// 
/// Esta clase centraliza todas las operaciones de cálculo y formateo
/// relacionadas con ventas, precios y montos, lo que ayuda a mantener
/// la consistencia en toda la aplicación.
class VentasUtils {
  /// Calcula el subtotal para un producto (precio * cantidad)
  /// 
  /// Parámetros:
  /// - producto: Mapa con datos del producto que debe incluir 'precio' y 'cantidad'
  /// 
  /// Retorna el subtotal formateado a 2 decimales
  static double calcularSubtotal(Map<String, dynamic> producto) {
    final double precio = producto['precio'] as double;
    final int cantidad = producto['cantidad'] as int;
    return formatearMonto(precio * cantidad);
  }
  
  /// Calcula el total para una venta completa sumando los subtotales de todos sus productos
  /// 
  /// Parámetros:
  /// - productos: Lista de productos, cada uno debe contener 'precio' y 'cantidad'
  /// 
  /// Retorna el total formateado a 2 decimales
  static double calcularTotalVenta(List<dynamic> productos) {
    double total = 0;
    for (var producto in productos) {
      total += calcularSubtotal(producto);
    }
    return formatearMonto(total);
  }
  
  /// Formatea un monto a 2 decimales, evitando problemas de precisión
  static double formatearMonto(double monto) {
    return double.parse(monto.toStringAsFixed(2));
  }
  
  /// Formatea un monto como texto para mostrar, incluyendo el símbolo de moneda
  static String formatearMontoTexto(double monto) {
    return 'S/ ${monto.toStringAsFixed(2)}';
  }
}

// Definición de la clase Venta para manejar los datos
class Venta {
  final String id;
  final DateTime? fechaCreacion;
  final String estado;
  final double subtotal;
  final double igv;
  final double total;
  final double? descuentoTotal;
  final List<DetalleVenta> detalles;

  Venta({
    required this.id,
    this.fechaCreacion,
    required this.estado,
    required this.subtotal,
    required this.igv,
    required this.total,
    this.descuentoTotal,
    required this.detalles,
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      id: json['id'] ?? '',
      fechaCreacion: json['fecha_creacion'] != null 
          ? DateTime.parse(json['fecha_creacion']) 
          : null,
      estado: json['estado'] ?? 'PENDIENTE',
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      igv: (json['igv'] ?? 0.0).toDouble(),
      total: (json['total'] ?? 0.0).toDouble(),
      descuentoTotal: json['descuento_total'] != null 
          ? (json['descuento_total']).toDouble() 
          : null,
      detalles: (json['detalles'] as List<dynamic>?)
          ?.map((detalle) => DetalleVenta.fromJson(detalle))
          .toList() ?? <DetalleVenta>[],
    );
  }
}

class DetalleVenta {
  final String productoId;
  final int cantidad;
  final double subtotal;

  DetalleVenta({
    required this.productoId,
    required this.cantidad,
    required this.subtotal,
  });

  factory DetalleVenta.fromJson(Map<String, dynamic> json) {
    return DetalleVenta(
      productoId: json['producto_id'] ?? '',
      cantidad: json['cantidad'] ?? 0,
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
    );
  }
}

// Constantes para los estados de venta
class EstadosVenta {
  static const String pendiente = 'PENDIENTE';
  static const String completada = 'COMPLETADA';
  static const String anulada = 'ANULADA';
}

class SalesComputerScreen extends StatefulWidget {
  final int? sucursalId;
  final String nombreSucursal;

  const SalesComputerScreen({
    super.key,
    this.sucursalId,
    this.nombreSucursal = 'Sucursal',
  });

  @override
  State<SalesComputerScreen> createState() => _SalesComputerScreenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties..add(IntProperty('sucursalId', sucursalId))
    ..add(StringProperty('nombreSucursal', nombreSucursal));
  }
}

class _SalesComputerScreenState extends State<SalesComputerScreen> {
  late VentasApi _ventasApi;
  late ProformaVentaApi _proformasApi;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<Venta> _ventas = <Venta>[];
  List<models.Proforma> _proformasObj = <models.Proforma>[];
  List<Map<String, dynamic>> _proformasFormateadas = <Map<String, dynamic>>[];
  
  // Para actualización automática
  Timer? _actualizacionTimer;
  final int _intervaloActualizacion = 30; // Segundos
  
  // Datos de prueba para ventas pendientes - Será reemplazado con proformas reales
  final List<Map<String, dynamic>> _ventasPendientes = <Map<String, dynamic>>[];

  // Variables para el procesamiento de ventas pendientes
  Map<String, dynamic>? _ventaSeleccionada;
  String _montoIngresado = '';
  String _nombreCliente = '';
  String _tipoDocumento = 'Boleta';
  bool _procesandoPago = false;
  final FocusNode _montoFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _ventasApi = api.ventas;
    _proformasApi = api.proformas;
    
    // Cargar datos iniciales
    _cargarDatos();
    
    // Iniciar timer para actualización automática
    _iniciarActualizacionPeriodica();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _montoFocusNode.dispose();
    // Cancelar timer de actualización
    _actualizacionTimer?.cancel();
    super.dispose();
  }

  // Método para cargar datos iniciales
  Future<void> _cargarDatos() async {
    await Future.wait([
      _cargarVentas(),
      _cargarProformas(),
    ]);
  }

  // Método para manejar la entrada de teclas
  void _handleKeyPress(String key) {
    setState(() {
      if (key == '00') {
        _montoIngresado += '00';
      } else if (_montoIngresado == '0') {
        _montoIngresado = key;
      } else {
        _montoIngresado += key;
      }
    });
  }

  // Método para limpiar el monto
  void _clearAmount() {
    setState(() {
      if (_montoIngresado.isNotEmpty) {
        _montoIngresado = _montoIngresado.substring(0, _montoIngresado.length - 1);
      }
    });
  }

  // Método para cambiar el tipo de documento
  void _changeDocumentType(String type) {
    setState(() {
      _tipoDocumento = type;
    });
  }

  // Método para cambiar el nombre del cliente
  void _changeCustomerName(String name) {
    setState(() {
      _nombreCliente = name;
    });
  }

  Future<void> _cargarVentas() async {
    setState(() => _isLoading = true);
    try {
      // Obtener sucursalId de forma asíncrona si es necesario
      String? sucursalIdParam;
      if (widget.sucursalId != null) {
        sucursalIdParam = widget.sucursalId?.toString();
      } else {
        final int? sucId = await VentasPendientesUtils.obtenerSucursalId();
        sucursalIdParam = sucId?.toString();
      }
      
      final Map<String, dynamic> ventasResponse = await _ventasApi.getVentas(
        sucursalId: sucursalIdParam,
      );
      
      if (!mounted) {
        return;
      }
      
      final List<Venta> ventasList = <Venta>[];
      if (ventasResponse['data'] != null && ventasResponse['data'] is List) {
        for (var item in ventasResponse['data']) {
          ventasList.add(Venta.fromJson(item));
        }
      }
      
      setState(() {
        _ventas = ventasList;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar ventas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _anularVenta(Venta venta) async {
    try {
      await _ventasApi.anularVenta(
        venta.id,
        'Anulado por el usuario',
      );
      
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venta anulada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      
      await _cargarVentas();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al anular venta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Método para seleccionar una venta pendiente para procesar
  void _seleccionarVenta(Map<String, dynamic> venta) {
    debugPrint('Venta seleccionada: $venta');
    
    // Verificar si es una proforma
    final bool esProforma = VentasPendientesUtils.esProforma(
      venta['id'].toString(),
      tipoVenta: venta['tipoVenta'] as String?,
    );
    
    if (esProforma) {
      // Buscar la proforma en la lista de objetos
      final int? proformaId = VentasPendientesUtils.extraerIdProforma(venta['id'].toString());
      if (proformaId != null) {
        final models.Proforma proformaObj = _proformasObj.firstWhere(
          (models.Proforma p) => p.id == proformaId,
          orElse: () {
            throw Exception('No se encontró la proforma con ID: $proformaId');
          },
        );
        
        // Mostrar diálogo especializado para proformas
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => form_widget.ProformaSaleDialog(
            proforma: proformaObj,
            onConfirm: (Map<String, dynamic> ventaData) {
              Navigator.of(context).pop();
              setState(() {
                _ventaSeleccionada = ventaData;
                _montoIngresado = _ventaSeleccionada!['total'].toString();
                _nombreCliente = _ventaSeleccionada!['cliente']['nombre'];
              });
              _procesarPago();
            },
            onCancel: () {
              Navigator.of(context).pop();
            },
          ),
        );
        return;
      }
    }
    
    // Comportamiento normal para ventas que no son proformas
    setState(() {
      _ventaSeleccionada = venta;
      _montoIngresado = _ventaSeleccionada!['total'].toString();
      _nombreCliente = _ventaSeleccionada!['cliente']['nombre'];
    });
  }
  
  // Método para crear una copia profunda de una venta
  
  // Método para mostrar el formulario de ventas como un popup
  void _mostrarFormularioVenta(Map<String, dynamic> venta) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              // Cabecera del popup
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
                      FontAwesomeIcons.fileInvoiceDollar,
                      color: Color(0xFFE31E24),
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Procesar Venta',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.xmark,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _cancelarProcesamiento();
                      },
                    ),
                  ],
                ),
              ),
              
              // Cuerpo del popup (detalles de la venta y formulario)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Columna izquierda: Detalles de la venta
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D2D2D),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const CircleAvatar(
                                    backgroundColor: Color(0xFF4CAF50),
                                    child: FaIcon(
                                      FontAwesomeIcons.user,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          venta['cliente']['nombre'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Doc: ${venta['cliente']['documento']}',
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
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE31E24).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      VentasUtils.formatearMontoTexto(venta['total']),
                                      key: ValueKey('header-total-${venta['total']}'),
                                      style: const TextStyle(
                                        color: Color(0xFFE31E24),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: Colors.white24),
                              const SizedBox(height: 8),
                              
                              // Etiqueta de Productos
                              const Text(
                                'PRODUCTOS',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Lista de productos
                              Expanded(
                                child: ListView.builder(
                                  itemCount: (venta['productos'] as List<dynamic>).length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final producto = venta['productos'][index];
                                    final double subtotal = VentasUtils.calcularSubtotal(producto);
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1A1A1A),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.white12),
                                        ),
                                        child: Row(
                                          children: <Widget>[
                                            // Icono del producto
                                            Container(
                                              width: 40,
                                              height: 40,
                                              margin: const EdgeInsets.all(8.0),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Center(
                                                child: FaIcon(
                                                  FontAwesomeIcons.box,
                                                  color: Color(0xFF4CAF50),
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                            // Información del producto
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Text(
                                                      producto['nombre'] as String,
                                                      style: const TextStyle(
                                                        color: Colors.white, 
                                                        fontWeight: FontWeight.bold
                                                      ),
                                                    ),
                                                    Row(
                                                      children: <Widget>[
                                                        Text(
                                                          'Precio: S/ ${(producto['precio'] as double).toStringAsFixed(2)}',
                                                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            'x${producto['cantidad']}',
                                                            style: const TextStyle(
                                                              color: Color(0xFF4CAF50),
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // Control de cantidad
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                              child: Row(
                                                children: <Widget>[
                                                  // Botón disminuir
                                                  _buildQuantityButton(
                                                    icon: Icons.remove,
                                                    onPressed: () => _actualizarCantidadProducto(venta, index, -1),
                                                    enabled: producto['cantidad'] > 1,
                                                  ),
                                                  // Mostrar cantidad
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF2D2D2D),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      '${producto['cantidad']}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  // Botón aumentar
                                                  _buildQuantityButton(
                                                    icon: Icons.add,
                                                    onPressed: () => _actualizarCantidadProducto(venta, index, 1),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Subtotal
                                            Container(
                                              width: 80,
                                              padding: const EdgeInsets.all(8.0),
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                VentasUtils.formatearMontoTexto(subtotal),
                                                key: ValueKey('subtotal-$index-$subtotal'),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              
                              const Divider(color: Colors.white24),
                              
                              // Total
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  const Text(
                                    'TOTAL',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: <Widget>[
                                      Text(
                                        VentasUtils.formatearMontoTexto(venta['total']),
                                        key: ValueKey('total-${venta['total']}'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      if (_ventaSeleccionada != null && 
                                          _ventaSeleccionada!['total_original'] != null && 
                                          _ventaSeleccionada!['total_original'] != _ventaSeleccionada!['total'])
                                        Text(
                                          'Monto original: ${VentasUtils.formatearMontoTexto(_ventaSeleccionada!['total_original'])}',
                                          style: TextStyle(
                                            color: Colors.orange.shade300,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Columna derecha: Teclado numérico y opciones de pago
                      Expanded(
                        flex: 4,
                        child: NumericKeypad(
                          onKeyPressed: _handleKeyPress,
                          onClear: _clearAmount,
                          onSubmit: () {
                            Navigator.pop(context);
                            _procesarPago();
                          },
                          currentAmount: venta['total'].toString(),
                          paymentAmount: _montoIngresado,
                          customerName: _nombreCliente,
                          documentType: _tipoDocumento,
                          onCustomerNameChanged: _changeCustomerName,
                          onDocumentTypeChanged: _changeDocumentType,
                          isProcessing: _procesandoPago,
                          minAmount: venta['total'],
                          onCharge: (double monto) {
                            debugPrint('Monto recibido para cobrar: $monto');
                            Navigator.pop(context);
                            _procesarPago();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Método para procesar el pago de una venta
  Future<void> _procesarPago() async {
    if (_ventaSeleccionada == null) {
      return;
    }
    
    debugPrint('Procesando pago para venta: ${_ventaSeleccionada!['id']} con monto: $_montoIngresado');
    setState(() => _procesandoPago = true);
    
    try {
      // Determinar si es una proforma que debemos convertir
      final bool esProforma = VentasPendientesUtils.esProforma(
        _ventaSeleccionada!['id'].toString(),
        tipoVenta: _ventaSeleccionada!['tipoVenta'] as String?,
      );
      
      if (esProforma) {
        // Extraer ID numérico de la proforma
        final int? proformaId = VentasPendientesUtils.extraerIdProforma(_ventaSeleccionada!['id'].toString());
        if (proformaId != null) {
          await _convertirProformaAVenta(proformaId, _ventaSeleccionada!);
        }
      } else {
        // Proceso original para ventas normales
        await _actualizarProductosVenta();
        
        // Mostrar dialog de procesamiento
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => ProcessingDialog(documentType: _tipoDocumento),
          );
        }
        
        // Simular procesamiento (aquí harías la llamada a la API)
        await Future.delayed(const Duration(seconds: 2));
        
        debugPrint('Pago procesado exitosamente');
        debugPrint('Marcando venta como procesada');
        
        // Cerrar dialog de procesamiento
        if (mounted) {
          Navigator.of(context).pop();
          
          // Mostrar mensaje de éxito
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Pago procesado exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
      
      // Reiniciar estado
      setState(() {
        _ventaSeleccionada = null;
        _montoIngresado = '';
        _nombreCliente = '';
        _tipoDocumento = 'Boleta';
        _procesandoPago = false;
      });
      
      // Recargar ventas y proformas
      await _cargarVentas();
      await _cargarProformas();
    } catch (e) {
      debugPrint('Error al procesar pago: $e');
      
      if (mounted) {
        // Cerrar dialog de procesamiento si está abierto
        Navigator.of(context, rootNavigator: true).popUntil(
          (Route route) => route.isFirst || route.settings.name == 'ventas_dialog'
        );
        
        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
        
        setState(() => _procesandoPago = false);
      }
    }
  }
  
  // Método para actualizar productos de la venta (cantidades modificadas)
  Future<void> _actualizarProductosVenta() async {
    if (_ventaSeleccionada == null) {
      return;
    }
    
    try {
      debugPrint('Actualizando cantidades de productos para venta: ${_ventaSeleccionada!['id']}');
      
      // Crear estructura de datos para enviar a la API
      final Map<String, dynamic> ventaData = <String, dynamic>{
        'productos': _ventaSeleccionada!['productos'].map((producto) {
          return <String, dynamic>{
            'id': producto['id'],
            'cantidad': producto['cantidad'],
            'precio': producto['precio'],
          };
        }).toList(),
        'total': _ventaSeleccionada!['total'],
      };
      
      // Actualizar la venta en la API
      await _ventasApi.updateVenta(_ventaSeleccionada!['id'], ventaData);
      
      debugPrint('Cantidades de productos actualizadas correctamente');
      
    } catch (e) {
      debugPrint('Error al actualizar cantidades de productos: $e');
      throw Exception('No se pudieron actualizar las cantidades de productos: $e');
    }
  }

  // Método para cancelar procesamiento de venta
  void _cancelarProcesamiento() {
    setState(() {
      _ventaSeleccionada = null;
      _montoIngresado = '';
      _nombreCliente = '';
      _tipoDocumento = 'Boleta';
      _procesandoPago = false;
    });
  }

  // Método para actualizar la cantidad de un producto
  void _actualizarCantidadProducto(Map<String, dynamic> venta, int index, int cambio) {
    setState(() {
      final producto = venta['productos'][index];
      final int cantidadActual = producto['cantidad'] as int;
      final int nuevaCantidad = cantidadActual + cambio;
      
      // Asegurar que la cantidad no sea menor que 1
      if (nuevaCantidad >= 1) {
        producto['cantidad'] = nuevaCantidad;
        
        // Recalcular el total de la venta usando la clase utilitaria
        venta['total'] = VentasUtils.calcularTotalVenta(venta['productos']);
        
        // Si hay una venta seleccionada, actualizarla también
        if (_ventaSeleccionada != null && _ventaSeleccionada!['id'] == venta['id']) {
          _ventaSeleccionada = Map<String, dynamic>.from(venta);
        }
        
        debugPrint('Cantidad actualizada para ${producto['nombre']}: $nuevaCantidad');
        debugPrint('Nuevo total de la venta: ${venta['total']}');
      }
    });
    
    // Forzar una actualización más explícita
    // Usamos una variable local para capturar el estado actual
    final Map<String, dynamic>? ventaSeleccionadaActual = _ventaSeleccionada;
    
    if (mounted) {
      Future.delayed(Duration.zero, () {
        // Verificar si el widget sigue montado después del delay
        if (!mounted) {
          return;
        }
        
        // Forzar una reconstrucción completa del widget actual
        setState(() {});
        
        // Forzar reconstrucción del diálogo si está abierto
        if (ventaSeleccionadaActual != null && mounted) {
          // Verificar si el contexto es válido antes de usarlo
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
            _mostrarFormularioVenta(ventaSeleccionadaActual);
          }
        }
      });
    }
  }
  // Modificar la referencia a _formatearMonto para usar la clase utilitaria

  // Widget para botones de cantidad
  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return Material(
      color: enabled ? const Color(0xFF2D2D2D) : Colors.grey.withOpacity(0.3),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 16,
            color: enabled ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  // Método para cargar proformas de venta
  Future<void> _cargarProformas({bool silencioso = false}) async {
    try {
      if (!silencioso) {
        setState(() {
          _isLoading = true;
        });
      }
      
      final int? sucursalId = await VentasPendientesUtils.obtenerSucursalId();
      if (sucursalId == null) {
        debugPrint('Error: No se pudo obtener el ID de sucursal');
        return;
      }
      
      // Configurar para obtención en tiempo real - sin caché
      final Map<String, dynamic> proformasResponse = await _proformasApi.getProformasVenta(
        sucursalId: sucursalId.toString(),
        forceRefresh: true, // Forzar actualización para obtener datos frescos
        useCache: false,     // No usar caché
      );
      
      if (!mounted) {
        return;
      }
      
      final List<models.Proforma> proformasObj = _proformasApi.parseProformasVenta(proformasResponse);
      
      // Filtrar solo proformas pendientes
      final List<models.Proforma> proformasFiltradas = proformasObj
          .where((models.Proforma p) => p.estado == models.EstadoProforma.pendiente)
          .toList();
      
      debugPrint('🔄 Proformas cargadas: ${proformasObj.length}, pendientes: ${proformasFiltradas.length}');
      
      // Convertir proformas a formato para mostrar en la UI
      final List<Map<String, dynamic>> proformasFormateadas = 
          VentasPendientesUtils.convertirProformasAVentasPendientes(proformasFiltradas);
      
      // Registrar información sobre promociones en las proformas
      int proformasConPromociones = 0;
      for (final models.Proforma proforma in proformasFiltradas) {
        final List<models.DetalleProforma> detallesConPromociones = proforma.detalles
            .where((models.DetalleProforma d) => _tienePromocion(d))
            .toList();
        
        if (detallesConPromociones.isNotEmpty) {
          proformasConPromociones++;
          debugPrint('Proforma #${proforma.id} tiene ${detallesConPromociones.length} productos con promociones');
        }
      }
      
      debugPrint('Proformas con promociones: $proformasConPromociones');
      
      setState(() {
        _proformasObj = proformasFiltradas;
        _proformasFormateadas = proformasFormateadas;
      });
    } catch (e) {
      debugPrint('❌ Error al cargar proformas: $e');
      // Mostrar mensaje de error en un snackbar (solo si no es silencioso)
      if (mounted && !silencioso) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar proformas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted && !silencioso) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Verificar si un detalle de proforma tiene promociones
  bool _tienePromocion(models.DetalleProforma detalle) {
    if (detalle.producto == null) {
      return false;
    }
    
    final Producto producto = detalle.producto!;
    
    // Verificar si tiene liquidación
    if (producto.liquidacion && producto.precioOferta != null) {
      return true;
    }
    
    // Verificar promoción de unidades gratis
    if (producto.cantidadMinimaDescuento != null && 
        producto.cantidadMinimaDescuento! > 0 &&
        producto.cantidadGratisDescuento != null && 
        producto.cantidadGratisDescuento! > 0) {
      return true;
    }
    
    // Verificar descuento porcentual
    if (producto.cantidadMinimaDescuento != null && 
        producto.cantidadMinimaDescuento! > 0 &&
        producto.porcentajeDescuento != null && 
        producto.porcentajeDescuento! > 0) {
      return true;
    }
    
    return false;
  }
  
  // Método para convertir proforma a venta
  Future<void> _convertirProformaAVenta(
    int proformaId, 
    Map<String, dynamic> ventaData
  ) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Obtener sucursalId
      final int? sucursalId = await VentasPendientesUtils.obtenerSucursalId();
      if (sucursalId == null) {
        debugPrint('Error: No se pudo obtener el ID de sucursal');
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo obtener el ID de sucursal'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Preparar tipo de documento (BOLETA o FACTURA)
      final String tipoDocumento = ventaData['tipoDocumento'] as String? ?? 'BOLETA';
      
      // Procesar la conversión usando la clase de utilidad
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => ProcessingDialog(documentType: tipoDocumento.toLowerCase()),
      );
      
      final bool exito = await ProformaConversionManager.convertirProformaAVenta(
        context: context,
        sucursalId: sucursalId.toString(),
        proformaId: proformaId,
        tipoDocumento: tipoDocumento,
        onSuccess: () {
          debugPrint('Proforma #$proformaId convertida exitosamente a $tipoDocumento');
          _cargarVentas();
          _cargarProformas();
        },
      );
      
      // Cerrar diálogo de procesamiento (la clase ProformaConversionManager ya se encarga de esto)
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      if (!exito) {
        debugPrint('No se pudo convertir la proforma #$proformaId a venta');
      }
      
    } catch (e) {
      debugPrint('Error al convertir proforma a venta: $e');
      
      // Cerrar diálogo de procesamiento si está abierto
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al convertir proforma a venta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Iniciar actualización periódica de proformas
  void _iniciarActualizacionPeriodica() {
    // Cancelar timer existente si hay uno
    _actualizacionTimer?.cancel();
    
    // Crear nuevo timer para actualizar cada _intervaloActualizacion segundos
    _actualizacionTimer = Timer.periodic(
      Duration(seconds: _intervaloActualizacion), 
      (_) => _actualizarProformasEnTiempoReal()
    );
    
    debugPrint('🔄 Timer de actualización de proformas iniciado (cada $_intervaloActualizacion segundos)');
  }
  
  // Actualizar solo proformas en tiempo real
  Future<void> _actualizarProformasEnTiempoReal() async {
    debugPrint('🔄 Actualizando proformas en tiempo real...');
    try {
      // No cambiar estado de _isLoading para no mostrar spinner
      // Solo recargar proformas en silencio
      await _cargarProformas(silencioso: true);
    } catch (e) {
      debugPrint('❌ Error al actualizar proformas en tiempo real: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.cashRegister,
                size: 20,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sistema de Ventas - ${widget.nombreSucursal}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar ventas',
            onPressed: _cargarVentas,
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.fileInvoiceDollar, size: 20),
            tooltip: 'Recargar proformas',
            onPressed: _cargarProformas,
          ),
        ],
      ),
      body: Row(
        children: <Widget>[
          // Panel izquierdo: Ventas pendientes y proformas
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: PendingSalesWidget(
                onSaleSelected: _seleccionarVenta,
                ventasPendientes: <Map<String, dynamic>>[..._ventasPendientes, ..._proformasFormateadas],
                onReload: _cargarProformas,
                intervaloActualizacion: _intervaloActualizacion,
              ),
            ),
          ),
          
          // Panel derecho: Historial de ventas
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'HISTORIAL DE VENTAS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _ventas.length,
                          itemBuilder: (BuildContext context, int index) {
                            final Venta venta = _ventas[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              color: const Color(0xFF2D2D2D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ExpansionTile(
                                collapsedIconColor: Colors.white,
                                iconColor: Colors.white,
                                title: Text(
                                  'Venta #${venta.id}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Fecha: ${_formatDateTime(venta.fechaCreacion)}',
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                    Text(
                                      'Estado: ${venta.estado}',
                                      style: TextStyle(
                                        color: venta.estado == EstadosVenta.completada
                                            ? Colors.green
                                            : venta.estado == EstadosVenta.anulada
                                                ? Colors.red
                                                : Colors.orange,
                                      ),
                                    ),
                                    Text(
                                      'Total: S/ ${VentasUtils.formatearMontoTexto(venta.total)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        const Text(
                                          'Detalles de la Venta',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...venta.detalles.map((DetalleVenta detalle) => ListTile(
                                          title: Text(
                                            'Producto #${detalle.productoId}',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                          subtitle: Text(
                                            'Cantidad: ${detalle.cantidad}',
                                            style: TextStyle(color: Colors.grey[400]),
                                          ),
                                          trailing: Text(
                                            'S/ ${detalle.subtotal.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )),
                                        const Divider(color: Colors.white24),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            const Text(
                                              'Subtotal:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              'S/ ${venta.subtotal.toStringAsFixed(2)}',
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            const Text(
                                              'IGV:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              'S/ ${venta.igv.toStringAsFixed(2)}',
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                          ],
                                        ),
                                        if (venta.descuentoTotal != null) ...<Widget>[
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: <Widget>[
                                              const Text(
                                                'Descuento:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                'S/ ${venta.descuentoTotal!.toStringAsFixed(2)}',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            const Text(
                                              'Total:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              VentasUtils.formatearMontoTexto(venta.total),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Color(0xFF4CAF50),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: <Widget>[
                                            ElevatedButton.icon(
                                              onPressed: () {
                                              },
                                              icon: const Icon(Icons.receipt),
                                              label: const Text('Generar Boleta'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF2196F3),
                                              ),
                                            ),
                                            ElevatedButton.icon(
                                              onPressed: () {
                                              },
                                              icon: const Icon(Icons.description),
                                              label: const Text('Generar Factura'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF9C27B0),
                                              ),
                                            ),
                                            if (venta.estado != EstadosVenta.anulada)
                                              ElevatedButton.icon(
                                                onPressed: () => _anularVenta(venta),
                                                icon: const Icon(Icons.cancel),
                                                label: const Text('Anular'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFFE31E24),
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
                          },
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

  String _formatDateTime(DateTime? date) {
    if (date == null) {
      return 'No disponible';
    }
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}

/// Widget para mostrar ventas pendientes y proformas
class PendingSalesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> ventasPendientes;
  final Function(Map<String, dynamic>) onSaleSelected;
  final VoidCallback onReload;
  final int intervaloActualizacion;

  const PendingSalesWidget({
    super.key,
    required this.ventasPendientes,
    required this.onSaleSelected,
    required this.onReload,
    this.intervaloActualizacion = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Encabezado con título y botón de recarga
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: [
                const Text(
                  'VENTAS PENDIENTES',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sync,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tiempo real ($intervaloActualizacion s)',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: onReload,
              tooltip: 'Recargar ahora',
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Lista de ventas pendientes
        Expanded(
          child: ventasPendientes.isEmpty
              ? const Center(
                  child: Text(
                    'No hay ventas pendientes',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  itemCount: ventasPendientes.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, dynamic> venta = ventasPendientes[index];
                    final String tipoVenta = venta['tipoVenta'] as String? ?? 'Venta';
                    final bool esProforma = tipoVenta.toLowerCase() == 'proforma';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: const Color(0xFF2D2D2D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: esProforma ? const Color(0xFFE31E24) : Colors.transparent,
                          width: esProforma ? 1 : 0,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => onSaleSelected(venta),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              // Encabezado de la venta
                              Row(
                                children: <Widget>[
                                  Icon(
                                    esProforma 
                                        ? Icons.file_copy_outlined 
                                        : Icons.shopping_cart,
                                    color: esProforma 
                                        ? const Color(0xFFE31E24) 
                                        : Colors.green,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '${esProforma ? 'Proforma' : 'Venta'} #${venta['id']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8, 
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: esProforma 
                                          ? const Color(0xFFE31E24).withOpacity(0.2) 
                                          : Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'S/ ${venta['total']}',
                                      style: TextStyle(
                                        color: esProforma 
                                            ? const Color(0xFFE31E24) 
                                            : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Información del cliente
                              if (venta.containsKey('cliente') && venta['cliente'] != null)
                                Text(
                                  'Cliente: ${venta['cliente']['nombre'] ?? 'Sin nombre'}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                              
                              // Fecha de creación
                              if (venta.containsKey('fechaCreacion') && venta['fechaCreacion'] != null)
                                Text(
                                  'Fecha: ${venta['fechaCreacion']}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                
                              // Etiquetas o información adicional
                              const SizedBox(height: 8),
                              Row(
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8, 
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      esProforma ? 'Pendiente de conversión' : 'Pendiente de pago',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<VoidCallback>.has('onReload', onReload))
      ..add(IterableProperty<Map<String, dynamic>>('ventasPendientes', ventasPendientes))
      ..add(ObjectFlagProperty<Function(Map<String, dynamic> p1)>.has('onSaleSelected', onSaleSelected))
      ..add(IntProperty('intervaloActualizacion', intervaloActualizacion));
  }
} 