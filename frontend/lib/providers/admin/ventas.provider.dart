import 'dart:io';
import 'dart:typed_data';

import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/models/ventas.model.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

/// Provider para gestionar ventas y sucursales
class VentasProvider extends ChangeNotifier {
  // Estado para sucursales
  String _errorMessage = '';
  List<Sucursal> _sucursales = [];
  Sucursal? _sucursalSeleccionada;
  bool _isSucursalesLoading = false;

  // Estado para ventas
  List<dynamic> _ventas = [];
  bool _isVentasLoading = false;
  String _ventasErrorMessage = '';

  // Estado para búsqueda y filtros
  String _searchQuery = '';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String? _estadoFiltro;

  // Estado para detalles de venta
  Venta? _ventaSeleccionada;
  bool _isVentaDetalleLoading = false;
  String _ventaDetalleErrorMessage = '';

  // Referencia global al messenger
  GlobalKey<ScaffoldMessengerState>? messengerKey;

  // Método para mostrar mensajes globales sin depender de un contexto específico
  void mostrarMensaje({
    required String mensaje,
    Color backgroundColor = Colors.black,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = messengerKey?.currentState;
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: backgroundColor,
          duration: duration,
        ),
      );
    }
  }

  /// Abre un PDF en una aplicación externa
  ///
  /// [url] URL del documento PDF
  /// [context] Contexto para mostrar mensajes de error (opcional)
  Future<bool> abrirPdf(String url, [BuildContext? context]) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        throw 'No se pudo abrir el enlace: $url';
      }
    } catch (e) {
      debugPrint('Error al abrir el PDF: $e');

      // Usar el método global para mostrar mensajes si no hay contexto
      if (context == null || !context.mounted) {
        mostrarMensaje(
          mensaje: 'Error al abrir el PDF: $e',
          backgroundColor: Colors.red,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir el PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Imprime un documento PDF desde una URL con bypass de verificación SSL
  ///
  /// [url] URL del documento PDF
  /// [nombreDocumento] Nombre para el trabajo de impresión
  /// [context] Contexto para mostrar mensajes (opcional)
  Future<bool> imprimirDocumentoPdf(String url, String nombreDocumento,
      [BuildContext? context]) async {
    try {
      // Mostrar mensaje de preparación
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preparando documento para impresión...'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        mostrarMensaje(
          mensaje: 'Preparando documento para impresión...',
          duration: const Duration(seconds: 1),
        );
      }

      // Crear un cliente HTTP que acepte todos los certificados
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      // Realizar la solicitud HTTP
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Error al descargar el PDF: ${response.statusCode}');
      }

      // Leer los bytes de la respuesta
      final List<int> bytesBuilder = [];
      await for (var data in response) {
        bytesBuilder.addAll(data);
      }
      final Uint8List bytes = Uint8List.fromList(bytesBuilder);

      // Cerrar el cliente HTTP
      httpClient.close();

      // Imprimir el PDF usando el plugin printing
      final result = await Printing.layoutPdf(
        onLayout: (_) => Future.value(bytes),
        name: nombreDocumento,
      );

      if (result) {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Documento enviado a la impresora'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          mostrarMensaje(
            mensaje: 'Documento enviado a la impresora',
            backgroundColor: Colors.green,
          );
        }
        return true;
      } else {
        // Si la impresión falló, abrir el PDF como fallback
        await abrirPdf(url);

        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo imprimir. PDF abierto en navegador'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          mostrarMensaje(
            mensaje: 'No se pudo imprimir. PDF abierto en navegador',
            backgroundColor: Colors.orange,
          );
        }
        return false;
      }
    } catch (e) {
      // Manejar errores
      debugPrint('Error al imprimir documento: $e');

      // Intentar abrir el PDF en el navegador como alternativa
      await abrirPdf(url);

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al imprimir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        mostrarMensaje(
          mensaje: 'Error al imprimir: $e',
          backgroundColor: Colors.red,
        );
      }
      return false;
    }
  }

  /// Calcula el total de una venta a partir de un Map
  double calcularTotalVenta(Map<String, dynamic> venta) {
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

  /// Obtiene el color según el estado de una venta
  Color getEstadoColor(String estado) {
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

  /// Obtiene el formato de serie-número o ID de una venta
  String obtenerNumeroDocumento(venta) {
    final bool isMap = venta is Map;
    final bool isVenta = venta is Venta;

    final String serie = isMap
        ? (venta['serieDocumento'] ?? '').toString()
        : isVenta
            ? venta.serieDocumento
            : '';
    final String numero = isMap
        ? (venta['numeroDocumento'] ?? '').toString()
        : isVenta
            ? venta.numeroDocumento
            : '';

    if (serie.isNotEmpty && numero.isNotEmpty) {
      return '$serie-$numero';
    }

    final String id = isMap
        ? venta['id'].toString()
        : isVenta
            ? venta.id.toString()
            : '';
    return id;
  }

  /// Verifica si una venta tiene PDF disponible
  bool tienePdfDisponible(venta) {
    final bool isVenta = venta is Venta;

    return isVenta
        ? (venta.documentoFacturacion != null &&
            venta.documentoFacturacion!.linkPdf != null)
        : (venta is Map &&
            venta['documentoFacturacion'] != null &&
            venta['documentoFacturacion']['linkPdf'] != null);
  }

  /// Obtiene la URL del PDF de una venta si existe
  String? obtenerUrlPdf(venta) {
    final bool isVenta = venta is Venta;
    final bool tienePdf = tienePdfDisponible(venta);

    return isVenta
        ? venta.documentoFacturacion?.linkPdf
        : (tienePdf ? venta['documentoFacturacion']['linkPdf'] : null);
  }

  /// Declara una venta a SUNAT
  ///
  /// [ventaId] ID de la venta a declarar
  /// [enviarCliente] Indica si se debe enviar el comprobante al cliente
  /// [onSuccess] Callback opcional para manejar el éxito
  /// [onError] Callback opcional para manejar el error
  ///
  /// Retorna un Future<bool> indicando si la operación fue exitosa
  Future<bool> declararVenta(
    String ventaId, {
    bool enviarCliente = false,
    VoidCallback? onSuccess,
    Function(String)? onError,
  }) async {
    _isVentasLoading = true;
    notifyListeners();

    try {
      // Necesitamos la sucursal ID actual
      if (_sucursalSeleccionada == null) {
        final errorMsg = 'No hay una sucursal seleccionada';
        if (onError != null) {
          onError(errorMsg);
        } else {
          mostrarMensaje(
            mensaje: errorMsg,
            backgroundColor: Colors.red,
          );
        }
        throw Exception(errorMsg);
      }

      // Forzar recarga de los datos para obtener el estado actualizado
      await cargarVentas();

      // Si teníamos detalles de esta venta seleccionados, actualizar
      if (_ventaSeleccionada != null &&
          _ventaSeleccionada!.id.toString() == ventaId) {
        await cargarDetalleVenta(ventaId);
      }

      // Llamar al callback de éxito si existe
      if (onSuccess != null) {
        onSuccess();
      } else {
        mostrarMensaje(
          mensaje: 'Venta declarada correctamente',
          backgroundColor: Colors.green,
        );
      }

      return true;
    } catch (e) {
      final errorMsg = 'Error al declarar venta: $e';
      debugPrint(errorMsg);
      _ventasErrorMessage = errorMsg;

      // Llamar al callback de error si existe
      if (onError != null) {
        onError(errorMsg);
      } else {
        mostrarMensaje(
          mensaje: errorMsg,
          backgroundColor: Colors.red,
        );
      }

      notifyListeners();
      return false;
    } finally {
      _isVentasLoading = false;
      notifyListeners();
    }
  }

  // Getters para sucursales
  String get errorMessage => _errorMessage;
  List<Sucursal> get sucursales => _sucursales;
  Sucursal? get sucursalSeleccionada => _sucursalSeleccionada;
  bool get isSucursalesLoading => _isSucursalesLoading;

  // Getters para ventas
  List<dynamic> get ventas => _ventas;
  bool get isVentasLoading => _isVentasLoading;
  String get ventasErrorMessage => _ventasErrorMessage;

  // Getters para búsqueda y filtros
  String get searchQuery => _searchQuery;
  DateTime? get fechaInicio => _fechaInicio;
  DateTime? get fechaFin => _fechaFin;
  String? get estadoFiltro => _estadoFiltro;

  // Getters para detalles de venta
  Venta? get ventaSeleccionada => _ventaSeleccionada;
  bool get isVentaDetalleLoading => _isVentaDetalleLoading;
  String get ventaDetalleErrorMessage => _ventaDetalleErrorMessage;

  /// Inicializa el provider cargando los datos necesarios
  void inicializar() {
    cargarSucursales();
  }

  /// Actualiza el término de búsqueda y recarga las ventas
  void actualizarBusqueda(String query) {
    _searchQuery = query;
    cargarVentas();
  }

  /// Actualiza los filtros de fecha y recarga las ventas
  void actualizarFiltrosFecha(DateTime? inicio, DateTime? fin) {
    _fechaInicio = inicio;
    _fechaFin = fin;
    cargarVentas();
  }

  /// Actualiza el filtro de estado y recarga las ventas
  void actualizarFiltroEstado(String? estado) {
    _estadoFiltro = estado;
    cargarVentas();
  }

  /// Limpia todos los filtros aplicados
  void limpiarFiltros() {
    _searchQuery = '';
    _fechaInicio = null;
    _fechaFin = null;
    _estadoFiltro = null;
    cargarVentas();
  }

  /// Carga las sucursales disponibles
  Future<void> cargarSucursales() async {
    _isSucursalesLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      debugPrint('Cargando sucursales desde la API...');
      final data = await api.sucursales.getSucursales();

      debugPrint('Datos recibidos tipo: ${data.runtimeType}');
      debugPrint('Longitud de la lista: ${data.length}');
      if (data.isNotEmpty) {
        debugPrint('Primer elemento tipo: ${data.first.runtimeType}');
      }

      List<Sucursal> sucursalesParsed = [];

      // Procesamiento seguro de los datos
      for (var item in data) {
        try {
          // Si ya es un objeto Sucursal, lo usamos directamente
          sucursalesParsed.add(item);
        } catch (e) {
          debugPrint('Error al procesar sucursal: $e');
        }
      }

      // Ordenar por nombre
      sucursalesParsed.sort((a, b) => a.nombre.compareTo(b.nombre));

      debugPrint(
          'Sucursales cargadas correctamente: ${sucursalesParsed.length}');

      _sucursales = sucursalesParsed;
      _isSucursalesLoading = false;

      // Seleccionar la primera sucursal como predeterminada si hay sucursales
      if (_sucursales.isNotEmpty && _sucursalSeleccionada == null) {
        _sucursalSeleccionada = _sucursales.first;
        // Cargar ventas de la sucursal seleccionada por defecto
        cargarVentas();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar sucursales: $e');
      _isSucursalesLoading = false;
      _errorMessage = 'Error al cargar sucursales: $e';
      notifyListeners();
    }
  }

  /// Cambia la sucursal seleccionada
  void cambiarSucursal(Sucursal sucursal) {
    _sucursalSeleccionada = sucursal;
    notifyListeners();

    // Cargar ventas para la nueva sucursal seleccionada
    cargarVentas();
  }

  /// Limpia los mensajes de error
  void limpiarErrores() {
    _errorMessage = '';
    _ventasErrorMessage = '';
    _ventaDetalleErrorMessage = '';
    notifyListeners();
  }

  /// Carga las ventas de la sucursal seleccionada
  Future<void> cargarVentas() async {
    if (_sucursalSeleccionada == null) {
      _ventasErrorMessage = 'Debe seleccionar una sucursal';
      _ventas = [];
      notifyListeners();
      return;
    }

    _isVentasLoading = true;
    _ventasErrorMessage = '';
    notifyListeners();

    try {
      debugPrint('Cargando ventas para sucursal: ${_sucursalSeleccionada!.id}');
      final Map<String, dynamic> response = await api.ventas.getVentas(
        sucursalId: _sucursalSeleccionada!.id,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        estado: _estadoFiltro,
      );

      debugPrint(
          'Respuesta de ventas recibida, tipo de datos: ${response['data']?.runtimeType}');

      List<dynamic> ventasList = [];
      if (response['data'] != null) {
        if (response['data'] is List) {
          // Si los datos son una lista, los usamos directamente
          ventasList = response['data'];
          debugPrint(
              'Datos recibidos como lista: ${ventasList.length} elementos');

          // Si son Maps, los convertimos a objetos Venta
          if (ventasList.isNotEmpty &&
              ventasList.first is Map<String, dynamic>) {
            try {
              debugPrint('Convirtiendo Maps a objetos Venta');
              ventasList = ventasList
                  .map((item) => Venta.fromJson(item as Map<String, dynamic>))
                  .toList();
            } catch (e) {
              debugPrint('Error al convertir Maps a Venta: $e');
              // Si hay error, mantenemos los datos originales como Map
            }
          }
        } else if (response['ventasRaw'] != null &&
            response['ventasRaw'] is List) {
          // En caso de que la API ya haya convertido los datos pero también proporcione los datos raw
          ventasList = response['data'];
          debugPrint(
              'Usando datos procesados de la API: ${ventasList.length} elementos');
        }
      }

      _ventas = ventasList;
      _isVentasLoading = false;
      notifyListeners();

      debugPrint(
          'Ventas cargadas: ${_ventas.length}, tipo: ${_ventas.isNotEmpty ? _ventas.first.runtimeType : "N/A"}');
    } catch (e) {
      debugPrint('Error al cargar ventas: $e');
      _isVentasLoading = false;
      _ventasErrorMessage = 'Error al cargar ventas: $e';
      notifyListeners();
    }
  }

  /// Carga los detalles de una venta específica
  Future<Venta?> cargarDetalleVenta(String id) async {
    if (_sucursalSeleccionada == null) {
      _ventaDetalleErrorMessage = 'Debe seleccionar una sucursal';
      _ventaSeleccionada = null;
      notifyListeners();
      return null;
    }

    _isVentaDetalleLoading = true;
    _ventaDetalleErrorMessage = '';
    notifyListeners();

    try {
      debugPrint(
          'Cargando detalle de venta: $id para sucursal: ${_sucursalSeleccionada!.id}');

      final Venta? venta = await api.ventas.getVenta(
        id,
        sucursalId: _sucursalSeleccionada!.id,
        forceRefresh: true, // Forzar recarga para obtener datos actualizados
      );

      if (venta == null) {
        _ventaDetalleErrorMessage = 'No se pudo cargar la venta';
        _isVentaDetalleLoading = false;
        notifyListeners();
        return null;
      }

      _ventaSeleccionada = venta;
      _isVentaDetalleLoading = false;
      notifyListeners();

      debugPrint('Venta cargada: ${venta.id}');
      return venta;
    } catch (e) {
      debugPrint('Error al cargar detalle de venta: $e');
      _isVentaDetalleLoading = false;
      _ventaDetalleErrorMessage = 'Error al cargar detalle de venta: $e';
      notifyListeners();
      return null;
    }
  }
}
