import 'dart:io';
import 'dart:typed_data';

import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/models/ventas.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

/// Provider para gestionar ventas y sucursales
class VentasProvider extends ChangeNotifier {
  // Repositorios
  final VentaRepository _ventaRepository = VentaRepository.instance;
  final SucursalRepository _sucursalRepository = SucursalRepository.instance;

  // Estado para sucursales
  String _errorMessage = '';
  List<Sucursal> _sucursales = [];
  Sucursal? _sucursalSeleccionada;
  bool _isSucursalesLoading = false;

  // Estado para ventas
  List<Venta> _ventas = []; // Usar tipo específico Venta
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

  // Estado para paginación
  Paginacion _paginacion = Paginacion(
    totalItems: 0,
    totalPages: 1,
    currentPage: 1,
    hasNext: false,
    hasPrev: false,
  );
  int _itemsPerPage = 10;
  String _orden = 'desc';
  String? _ordenarPor = 'fechaCreacion'; // Ordenar por fecha por defecto

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

  // --- Métodos Helper Eliminados ---
  // La lógica de calcularTotalVenta, obtenerNumeroDocumento, tienePdfDisponible,
  // y obtenerUrlPdf debe residir en el modelo Venta o ser accedida directamente
  // desde sus propiedades.

  /// Obtiene el color según el estado de una venta (se mantiene por ser UI-related)
  Color getEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'COMPLETADA':
      case 'ACEPTADO-SUNAT':
      case 'ACEPTADO ANTE LA SUNAT':
        return Colors.green;
      case 'ANULADA':
        return Colors.red;
      case 'CANCELADA':
        return Colors.orange.shade900; // Nuevo estado para ventas canceladas
      case 'DECLARADA':
        return Colors.blue;
      case 'PENDIENTE':
      default:
        return Colors.orange;
    }
  }

  /// Verifica si una venta tiene PDF en formato ticket disponible
  bool tienePdfTicketDisponible(Venta venta) {
    return venta.documentoFacturacion != null &&
        venta.documentoFacturacion!.linkPdfTicket != null;
  }

  /// Obtiene la URL del PDF de una venta en el formato solicitado
  String? obtenerUrlPdf(Venta venta, {bool formatoTicket = false}) {
    if (venta.documentoFacturacion == null) {
      return null;
    }

    if (formatoTicket) {
      return venta.documentoFacturacion!.linkPdfTicket ??
          venta.documentoFacturacion!.linkPdf;
    }
    return venta.documentoFacturacion!.linkPdfA4 ??
        venta.documentoFacturacion!.linkPdf;
  }

  /// Verifica si una venta está cancelada
  bool estaVentaCancelada(Venta venta) {
    return venta.cancelada;
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

      // Llamar al repositorio para declarar la venta
      final result = await _ventaRepository.declararVenta(
        ventaId,
        sucursalId: _sucursalSeleccionada!.id,
        enviarCliente: enviarCliente,
      );

      // Verificar si la respuesta es exitosa
      if (result['status'] != 'success') {
        final errorMsg = result['message'] ?? 'Error al declarar la venta';
        if (onError != null) {
          onError(errorMsg);
        } else {
          mostrarMensaje(
            mensaje: errorMsg,
            backgroundColor: Colors.red,
          );
        }
        return false;
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
          mensaje: 'Venta declarada correctamente a SUNAT',
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
  List<Venta> get ventas => _ventas; // Usar tipo específico Venta
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

  // Getters para paginación
  Paginacion get paginacion => _paginacion;
  int get itemsPerPage => _itemsPerPage;
  String get orden => _orden;
  String? get ordenarPor => _ordenarPor;

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
      debugPrint('Cargando sucursales desde el repositorio...');
      final data = await _sucursalRepository.getSucursales();

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

  /// Establece una sucursal directamente por su ID sin necesidad de cargar la lista completa
  /// Útil cuando el usuario tiene permisos para una sucursal específica pero no para listar todas
  Future<bool> establecerSucursalPorId(sucursalId) async {
    try {
      if (sucursalId == null) {
        debugPrint('⚠️ ID de sucursal no proporcionado');
        return false;
      }

      String sucursalIdStr = sucursalId.toString();
      debugPrint('🔍 Estableciendo sucursal por ID: $sucursalIdStr');

      // Primero verificar si la sucursal ya está en nuestra lista cargada
      if (_sucursales.isNotEmpty) {
        for (var sucursal in _sucursales) {
          if (sucursal.id.toString() == sucursalIdStr) {
            debugPrint(
                '✅ Sucursal encontrada en lista local, seleccionando: ${sucursal.nombre}');
            _sucursalSeleccionada = sucursal;
            notifyListeners();
            return true;
          }
        }
      }

      // Intentar obtener los datos de la sucursal a través del repositorio
      try {
        debugPrint('🔄 Intentando obtener datos completos de la sucursal');
        final sucursalCompleta = await _sucursalRepository.getSucursalData(
          sucursalIdStr,
          useCache: false,
          forceRefresh: true,
        );

        // Si se pudo obtener, usar esta sucursal
        debugPrint(
            '✅ Datos de sucursal obtenidos con éxito: ${sucursalCompleta.nombre}');
        _sucursalSeleccionada = sucursalCompleta;

        // Agregar a la lista si no está ya
        if (!_sucursales.any((s) => s.id.toString() == sucursalIdStr)) {
          _sucursales.add(sucursalCompleta);
        }
      } catch (e) {
        // Si hay error al obtener datos completos, usar una sucursal provisional
        debugPrint(
            '⚠️ No se pudieron obtener datos completos, usando información mínima: $e');

        // Crear una sucursal provisional con el repositorio
        final sucursalProvisional =
            _sucursalRepository.createProvisionalSucursal(sucursalIdStr);
        _sucursalSeleccionada = sucursalProvisional;
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error al establecer sucursal por ID: $e');
      return false;
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

  /// Actualiza la información de paginación basándose en los resultados
  void _actualizarPaginacion(int totalItems) {
    final int totalPages = (totalItems / _itemsPerPage).ceil();
    final int currentPage = _paginacion.currentPage > totalPages
        ? totalPages
        : _paginacion.currentPage;

    _paginacion = Paginacion(
      totalItems: totalItems,
      totalPages: totalPages > 0 ? totalPages : 1,
      currentPage: currentPage > 0 ? currentPage : 1,
      hasNext: currentPage < totalPages,
      hasPrev: currentPage > 1,
    );
  }

  /// Carga las ventas según los filtros actuales
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
      // Llamar al repositorio para obtener las ventas
      final response = await _ventaRepository.getVentas(
        sucursalId: _sucursalSeleccionada!.id,
        page: _paginacion.currentPage,
        pageSize: _itemsPerPage,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        estado: _estadoFiltro,
        sortBy: _ordenarPor,
        order: _orden,
        forceRefresh: true,
      );

      debugPrint('Respuesta recibida: ${response.keys.join(', ')}');

      // Procesar la respuesta para obtener List<Venta>
      if (response.containsKey('data') && response['data'] is List) {
        final rawList = response['data'] as List<dynamic>;
        _ventas = rawList
            .map((item) {
              try {
                // Si ya es Venta, devolverlo. Si es Map, intentar convertir.
                if (item is Venta) {
                  return item;
                } else if (item is Map<String, dynamic>) {
                  // Asumiendo que Venta.fromJson existe y maneja la estructura
                  return Venta.fromJson(item);
                } else {
                  debugPrint(
                      'Item inesperado en la lista de ventas: ${item.runtimeType}');
                  return null; // Marcar para filtrar
                }
              } catch (e) {
                debugPrint(
                    'Error al convertir venta Map a Venta: $e - Item: $item');
                return null; // Marcar para filtrar
              }
            })
            .whereType<
                Venta>() // Filtrar los nulos (errores o tipos inesperados)
            .toList();
        debugPrint('Ventas convertidas a List<Venta>: ${_ventas.length}');
      } else {
        _ventas =
            []; // Limpiar si no hay datos o la clave 'data' no existe/no es lista
        debugPrint(
            'No se encontraron datos de ventas en la respuesta o el formato es incorrecto.');
      }

      // Actualizar información de paginación si está disponible en la respuesta
      if (response.containsKey('pagination') &&
          response['pagination'] is Map<String, dynamic>) {
        // Extraer el mapa para depuración
        final Map<String, dynamic> paginationMap =
            Map<String, dynamic>.from(response['pagination'] as Map);
        debugPrint('Datos de paginación recibidos: $paginationMap');

        try {
          // Crear una instancia de Paginacion con valores predeterminados
          // en caso de que falten campos en el mapa
          final int totalItems = paginationMap['totalItems'] as int? ?? 0;
          final int totalPages = paginationMap['totalPages'] as int? ?? 1;
          final int currentPage = paginationMap['currentPage'] as int? ?? 1;

          _paginacion = Paginacion(
            totalItems: totalItems,
            totalPages: totalPages > 0 ? totalPages : 1,
            currentPage: currentPage > 0 ? currentPage : 1,
            hasNext: currentPage < totalPages,
            hasPrev: currentPage > 1,
          );

          debugPrint('Paginación convertida correctamente: $_paginacion');
        } catch (e) {
          debugPrint('Error al procesar paginación: $e');
          // Si falla, usar el método de respaldo
          if (paginationMap.containsKey('totalItems')) {
            final dynamic totalItems = paginationMap['totalItems'];
            _actualizarPaginacion(totalItems is int
                ? totalItems
                : int.tryParse(totalItems.toString()) ?? _ventas.length);
          } else {
            _actualizarPaginacion(_ventas.length);
          }
        }
      } else if (response.containsKey('total')) {
        final dynamic total = response['total'];
        _actualizarPaginacion(total is int
            ? total
            : int.tryParse(total.toString()) ?? _ventas.length);
      } else {
        _actualizarPaginacion(_ventas.length);
      }

      _isVentasLoading = false;
      notifyListeners();

      debugPrint(
          'Ventas cargadas: ${_ventas.length}, tipo: ${_ventas.isNotEmpty ? _ventas.first.runtimeType : "N/A"}');
      debugPrint('Paginación final: $_paginacion');
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

      final Venta? venta = await _ventaRepository.getVenta(
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

  /// Cambia la página actual de resultados
  Future<void> cambiarPagina(int nuevaPagina) async {
    if (nuevaPagina < 1 || nuevaPagina > _paginacion.totalPages) {
      return; // No hacer nada si la página solicitada está fuera de rango
    }

    _paginacion = Paginacion(
      totalItems: _paginacion.totalItems,
      totalPages: _paginacion.totalPages,
      currentPage: nuevaPagina,
      hasNext: nuevaPagina < _paginacion.totalPages,
      hasPrev: nuevaPagina > 1,
    );

    notifyListeners();

    // Recargar los datos con la nueva página
    await cargarVentas();
  }

  /// Cambia el número de elementos por página
  Future<void> cambiarItemsPorPagina(int nuevoTamano) async {
    if (nuevoTamano < 1 || nuevoTamano > 200) {
      return; // Validar límites razonables
    }

    _itemsPerPage = nuevoTamano;

    // Resetear a la primera página cuando cambiamos el tamaño
    _paginacion = Paginacion(
      totalItems: _paginacion.totalItems,
      totalPages: (_paginacion.totalItems / nuevoTamano).ceil(),
      currentPage: 1,
      hasNext: _paginacion.totalItems > nuevoTamano,
      hasPrev: false,
    );

    notifyListeners();

    // Recargar los datos con el nuevo tamaño de página
    await cargarVentas();
  }

  /// Cambia el campo por el cual ordenar
  Future<void> cambiarOrdenarPor(String? campo) async {
    _ordenarPor = campo;
    notifyListeners();

    // Recargar datos con la nueva ordenación
    await cargarVentas();
  }

  /// Cambia la dirección de ordenación (asc/desc)
  Future<void> cambiarOrden(String nuevoOrden) async {
    if (nuevoOrden != 'asc' && nuevoOrden != 'desc') {
      return; // Solo aceptar valores válidos
    }

    _orden = nuevoOrden;
    notifyListeners();

    // Recargar datos con la nueva dirección de ordenación
    await cargarVentas();
  }
}
