import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/models/ventas.model.dart';
import 'package:condorsmotors/providers/print.provider.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

/// Provider para gestionar ventas y sucursales
class VentasComputerProvider extends ChangeNotifier {
  // Claves para SharedPreferences
  static const String keyImprimirFormatoA4 = 'imprimir_formato_a4';
  static const String keyImprimirFormatoTicket = 'imprimir_formato_ticket';
  static const String keyAbrirPdfDespuesDeImprimir =
      'abrir_pdf_despues_imprimir';
  static const String keyImpresionDirecta = 'impresion_directa';
  static const String keyImpresoraSeleccionada = 'impresora_seleccionada';

  // Repositorios
  final VentaRepository _ventaRepository = VentaRepository.instance;
  final SucursalRepository _sucursalRepository = SucursalRepository.instance;
  final PrintProvider _printProvider = PrintProvider.instance;

  // Estado para sucursales
  String _errorMessage = '';
  List<Sucursal> _sucursales = [];
  Sucursal? _sucursalSeleccionada;
  bool _isSucursalesLoading = false;

  // Estado para ventas
  List<Venta> _ventas = []; // Usar tipo específico Venta
  bool _isVentasLoading = false;
  String _ventasErrorMessage = '';

  // Estado para búsqueda
  String _searchQuery = '';

  // Estado para detalles de venta
  Venta? _ventaSeleccionada;
  bool _isVentaDetalleLoading = false;
  String _ventaDetalleErrorMessage = '';

  // Estado para paginación
  Paginacion _paginacion = Paginacion.emptyPagination;
  int _itemsPerPage = 10;
  String _orden = 'desc'; // Descendente para mostrar más recientes primero
  String? _ordenarPor =
      'fechaCreacion'; // Ordenar por fecha de creación por defecto

  // Referencia global al messenger
  GlobalKey<ScaffoldMessengerState>? messengerKey;

  // Estado de configuración de impresión

  // Getters para configuración de impresión - delegados a PrintProvider
  bool get imprimirFormatoA4 => _printProvider.imprimirFormatoA4;
  bool get imprimirFormatoTicket => _printProvider.imprimirFormatoTicket;
  bool get abrirPdfDespuesDeImprimir =>
      _printProvider.abrirPdfDespuesDeImprimir;
  bool get impresionDirecta => _printProvider.impresionDirecta;
  String? get impresoraSeleccionada => _printProvider.impresoraSeleccionada;
  List<Printer> get impresorasDisponibles =>
      _printProvider.impresorasDisponibles;

  /// Obtiene la impresora seleccionada actual
  Printer? obtenerImpresoraSeleccionada() {
    return _printProvider.obtenerImpresoraSeleccionada();
  }

  /// Carga la lista de impresoras disponibles
  Future<void> cargarImpresoras() async {
    await _printProvider.cargarImpresoras();
    notifyListeners();
  }

  /// Carga la configuración de impresión desde SharedPreferences
  Future<void> cargarConfiguracionImpresion() async {
    await _printProvider.cargarConfiguracion();
    notifyListeners();
  }

  /// Guarda la configuración de impresión en SharedPreferences
  Future<void> guardarConfiguracionImpresion({
    bool? imprimirFormatoA4,
    bool? imprimirFormatoTicket,
    bool? abrirPdfDespuesDeImprimir,
    bool? impresionDirecta,
    String? impresoraSeleccionada,
    double? margenIzquierdo,
    double? margenDerecho,
    double? margenSuperior,
    double? margenInferior,
    double? anchoTicket,
    double? escalaTicket,
    bool? rotacionAutomatica,
    bool? ajusteAutomatico,
  }) async {
    await _printProvider.guardarConfiguracion(
      imprimirFormatoA4: imprimirFormatoA4,
      imprimirFormatoTicket: imprimirFormatoTicket,
      abrirPdfDespuesDeImprimir: abrirPdfDespuesDeImprimir,
      impresionDirecta: impresionDirecta,
      impresoraSeleccionada: impresoraSeleccionada,
      margenIzquierdo: margenIzquierdo,
      margenDerecho: margenDerecho,
      margenSuperior: margenSuperior,
      margenInferior: margenInferior,
      anchoTicket: anchoTicket,
      escalaTicket: escalaTicket,
      rotacionAutomatica: rotacionAutomatica,
      ajusteAutomatico: ajusteAutomatico,
    );
    notifyListeners();
  }

  /// Restaura la configuración de impresión a valores por defecto
  Future<void> restaurarConfiguracionImpresion() async {
    await _printProvider.restaurarConfiguracionPorDefecto();
    notifyListeners();
  }

  // Método para mostrar mensajes globales sin depender de un contexto específico
  void mostrarMensaje({
    required String mensaje,
    Color backgroundColor = Colors.black,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (_printProvider.messengerKey == null && messengerKey != null) {
      _printProvider.messengerKey = messengerKey;
    }

    _printProvider.mostrarMensaje(
      mensaje: mensaje,
      backgroundColor: backgroundColor,
      duration: duration,
    );
  }

  /// Abre un PDF en una aplicación externa
  ///
  /// [url] URL del documento PDF
  /// [context] Contexto para mostrar mensajes de error (opcional)
  Future<bool> abrirPdf(String url, [BuildContext? context]) {
    return _printProvider.abrirPdf(url, context);
  }

  /// Imprime un documento PDF desde una URL con bypass de verificación SSL
  ///
  /// [url] URL del documento PDF
  /// [nombreDocumento] Nombre para el trabajo de impresión
  /// [context] Contexto para mostrar mensajes (opcional)
  Future<bool> imprimirDocumentoPdf(String url, String nombreDocumento,
      [BuildContext? context]) {
    return _printProvider.imprimirDocumentoPdf(url, nombreDocumento, context);
  }

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
        const errorMsg = 'No hay una sucursal seleccionada';
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

  // Getters para búsqueda
  String get searchQuery => _searchQuery;

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
  Future<void> inicializar({GlobalKey<ScaffoldMessengerState>? key}) async {
    try {
      debugPrint('Inicializando VentasComputerProvider...');

      if (key != null) {
        messengerKey = key;
        // Inicializar PrintProvider con la misma key
        await _printProvider.inicializar(key: key);
      }

      // Obtener datos del usuario autenticado usando el repositorio
      final userData = await _ventaRepository.getUserData();
      if (userData == null) {
        throw Exception('No se encontraron datos del usuario autenticado');
      }

      debugPrint('👤 Datos de usuario obtenidos: ${userData.toString()}');

      // Extraer ID de sucursal del usuario
      final sucursalId = userData['sucursalId'];
      if (sucursalId == null) {
        throw Exception('El usuario no tiene una sucursal asignada');
      }

      debugPrint('🏢 ID de sucursal del usuario: $sucursalId');

      // Establecer la sucursal del usuario
      await establecerSucursalPorId(sucursalId);

      // Cargar ventas iniciales
      await cargarVentas();
    } catch (e) {
      debugPrint('Error en inicialización: $e');
      _errorMessage = 'Error al inicializar: $e';
      notifyListeners();
    }
  }

  /// Actualiza el término de búsqueda y recarga las ventas
  void actualizarBusqueda(String query) {
    _searchQuery = query;
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

  /// Establece una sucursal directamente por su ID
  Future<bool> establecerSucursalPorId(sucursalId) async {
    try {
      if (sucursalId == null) {
        debugPrint('ID de sucursal no proporcionado');
        return false;
      }

      String sucursalIdStr = sucursalId.toString();
      debugPrint('Estableciendo sucursal por ID: $sucursalIdStr');

      // Intentar obtener datos completos de la sucursal usando el repositorio
      try {
        final sucursalCompleta = await _sucursalRepository.getSucursalData(
          sucursalIdStr,
          useCache: false,
          forceRefresh: true,
        );

        debugPrint('Datos de sucursal obtenidos: ${sucursalCompleta.nombre}');
        _sucursalSeleccionada = sucursalCompleta;

        // Agregar a la lista si no está ya
        if (!_sucursales.any((s) => s.id.toString() == sucursalIdStr)) {
          _sucursales = [sucursalCompleta];
        }

        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('No se pudieron obtener datos completos de sucursal: $e');

        // Crear una sucursal provisional con datos mínimos utilizando el repositorio
        final sucursalProvisional =
            _sucursalRepository.createProvisionalSucursal(sucursalIdStr);

        _sucursalSeleccionada = sucursalProvisional;
        _sucursales = [sucursalProvisional];

        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error al establecer sucursal por ID: $e');
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
  Future<void> cargarVentas({int? sucursalId}) async {
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
        sucursalId: sucursalId ?? _sucursalSeleccionada!.id,
        page: _paginacion.currentPage,
        pageSize: _itemsPerPage,
        search: _searchQuery.isEmpty ? null : _searchQuery,
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

  /// Crea una venta nueva con productos personalizados
  Future<Map<String, dynamic>> crearVentaPersonalizada({
    required int? sucursalId,
    required int clienteId,
    required int empleadoId,
    required int tipoDocumentoId,
    required List<DetalleVenta> detalles,
    String? observaciones,
    int monedaId = 1,
    int metodoPagoId = 1,
    DateTime? fechaEmision,
    String? horaEmision,
  }) async {
    try {
      // Verificar sucursal
      final String? sucursalIdStr = await _getCurrentSucursalId(sucursalId);
      if (sucursalIdStr == null) {
        return {
          'status': 'error',
          'message': 'No se pudo determinar la sucursal para la venta',
        };
      }

      // Verificar cliente
      if (clienteId <= 0) {
        return {
          'status': 'error',
          'message': 'Se requiere un cliente válido',
        };
      }

      // Verificar empleado
      if (empleadoId <= 0) {
        return {
          'status': 'error',
          'message': 'Se requiere un empleado válido',
        };
      }

      // Verificar detalles
      if (detalles.isEmpty) {
        return {
          'status': 'error',
          'message': 'La venta debe contener al menos un producto',
        };
      }

      // Estructurar datos de la API
      final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
      final DateFormat timeFormat = DateFormat('HH:mm:ss');
      final DateTime now = DateTime.now();

      final Map<String, dynamic> ventaData = {
        'observaciones': observaciones,
        'tipoDocumentoId': tipoDocumentoId,
        'monedaId': monedaId,
        'metodoPagoId': metodoPagoId,
        'clienteId': clienteId,
        'empleadoId': empleadoId,
        'fechaEmision': fechaEmision != null
            ? dateFormat.format(fechaEmision)
            : dateFormat.format(now),
        'horaEmision': horaEmision ?? timeFormat.format(now),
        'detalles': detalles.map((detalle) => detalle.toCreateJson()).toList(),
      };

      // Llamar a la API para crear la venta
      final response = await _ventaRepository.createVenta(
        ventaData,
        sucursalId: sucursalIdStr,
      );

      // Recargar la lista de ventas después de crear una nueva
      await cargarVentas(sucursalId: int.tryParse(sucursalIdStr));

      return response;
    } catch (e) {
      debugPrint('Error al crear venta personalizada: $e');
      return {
        'status': 'error',
        'message': 'Error al crear la venta: $e',
      };
    }
  }

  /// Crea un detalle para productos personalizados (sin registro previo)
  DetalleVenta crearDetallePersonalizado({
    required String nombre,
    required int cantidad,
    required double precio,
    required int tipoTaxId,
    String sku = '',
  }) {
    return DetalleVenta.personalizado(
      nombre: nombre,
      cantidad: cantidad,
      precio: precio,
      tipoTaxId: tipoTaxId,
      sku: sku,
    );
  }

  /// Obtiene el ID de la sucursal actual
  Future<String?> _getCurrentSucursalId(int? sucursalId) async {
    if (sucursalId != null) {
      return sucursalId.toString();
    }

    if (_sucursalSeleccionada != null) {
      return _sucursalSeleccionada!.id.toString();
    }

    return _ventaRepository.getCurrentSucursalId();
  }
}
