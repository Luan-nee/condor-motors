import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/models/ventas.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ventas.computer.riverpod.g.dart';

class VentasComputerState {
  final String errorMessage;
  final List<Sucursal> sucursales;
  final Sucursal? sucursalSeleccionada;
  final bool isSucursalesLoading;

  final List<Venta> ventas;
  final bool isVentasLoading;
  final String ventasErrorMessage;

  final String searchQuery;

  final Venta? ventaSeleccionada;
  final bool isVentaDetalleLoading;
  final String ventaDetalleErrorMessage;

  final Paginacion paginacion;
  final int itemsPerPage;
  final String orden;
  final String? ordenarPor;

  const VentasComputerState({
    this.errorMessage = '',
    this.sucursales = const [],
    this.sucursalSeleccionada,
    this.isSucursalesLoading = false,
    this.ventas = const [],
    this.isVentasLoading = false,
    this.ventasErrorMessage = '',
    this.searchQuery = '',
    this.ventaSeleccionada,
    this.isVentaDetalleLoading = false,
    this.ventaDetalleErrorMessage = '',
    this.paginacion = Paginacion.emptyPagination,
    this.itemsPerPage = 10,
    this.orden = 'desc',
    this.ordenarPor = 'fechaCreacion',
  });

  VentasComputerState copyWith({
    String? errorMessage,
    List<Sucursal>? sucursales,
    Sucursal? sucursalSeleccionada,
    bool? isSucursalesLoading,
    List<Venta>? ventas,
    bool? isVentasLoading,
    String? ventasErrorMessage,
    String? searchQuery,
    Venta? ventaSeleccionada,
    bool? isVentaDetalleLoading,
    String? ventaDetalleErrorMessage,
    Paginacion? paginacion,
    int? itemsPerPage,
    String? orden,
    String? ordenarPor,
  }) {
    return VentasComputerState(
      errorMessage: errorMessage ?? this.errorMessage,
      sucursales: sucursales ?? this.sucursales,
      sucursalSeleccionada: sucursalSeleccionada ?? this.sucursalSeleccionada,
      isSucursalesLoading: isSucursalesLoading ?? this.isSucursalesLoading,
      ventas: ventas ?? this.ventas,
      isVentasLoading: isVentasLoading ?? this.isVentasLoading,
      ventasErrorMessage: ventasErrorMessage ?? this.ventasErrorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      ventaSeleccionada: ventaSeleccionada ?? this.ventaSeleccionada,
      isVentaDetalleLoading:
          isVentaDetalleLoading ?? this.isVentaDetalleLoading,
      ventaDetalleErrorMessage:
          ventaDetalleErrorMessage ?? this.ventaDetalleErrorMessage,
      paginacion: paginacion ?? this.paginacion,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      orden: orden ?? this.orden,
      ordenarPor: ordenarPor ?? this.ordenarPor,
    );
  }
}

@Riverpod(keepAlive: true)
class VentasComputer extends _$VentasComputer {
  final VentaRepository _ventaRepository = VentaRepository.instance;
  final SucursalRepository _sucursalRepository = SucursalRepository.instance;
  GlobalKey<ScaffoldMessengerState>? messengerKey;

  // Getters para comodidad
  String get errorMessage => state.errorMessage;
  List<Sucursal> get sucursales => state.sucursales;
  Sucursal? get sucursalSeleccionada => state.sucursalSeleccionada;
  bool get isSucursalesLoading => state.isSucursalesLoading;
  List<Venta> get ventas => state.ventas;
  bool get isVentasLoading => state.isVentasLoading;
  String get ventasErrorMessage => state.ventasErrorMessage;
  String get searchQuery => state.searchQuery;
  Venta? get ventaSeleccionada => state.ventaSeleccionada;
  bool get isVentaDetalleLoading => state.isVentaDetalleLoading;
  String get ventaDetalleErrorMessage => state.ventaDetalleErrorMessage;
  Paginacion get paginacion => state.paginacion;
  int get itemsPerPage => state.itemsPerPage;
  String get orden => state.orden;
  String? get ordenarPor => state.ordenarPor;

  @override
  VentasComputerState build() {
    Future.microtask(inicializar);
    return const VentasComputerState();
  }

  Future<void> inicializar({GlobalKey<ScaffoldMessengerState>? key}) async {
    try {
      debugPrint('Inicializando VentasComputer Riverpod...');

      if (key != null) {
        messengerKey = key;
      }

      final userData = await _ventaRepository.getUserData();
      if (userData == null) {
        throw Exception('No se encontraron datos del usuario autenticado');
      }

      final sucursalId = userData['sucursalId'];
      if (sucursalId == null) {
        throw Exception('El usuario no tiene una sucursal asignada');
      }

      await establecerSucursalPorId(sucursalId);
      await cargarVentas();
    } catch (e) {
      debugPrint('Error en inicialización: $e');
      state = state.copyWith(errorMessage: 'Error al inicializar: $e');
    }
  }

  void actualizarBusqueda(String query) {
    state = state.copyWith(searchQuery: query);
    cargarVentas();
  }

  Future<void> cargarSucursales() async {
    state = state.copyWith(isSucursalesLoading: true, errorMessage: '');

    try {
      final data = await _sucursalRepository.getSucursales();
      List<Sucursal> sucursalesParsed = [];

      for (var item in data) {
        try {
          sucursalesParsed.add(item);
        } catch (e) {
          debugPrint('Error al procesar sucursal: $e');
        }
      }

      sucursalesParsed.sort((a, b) => a.nombre.compareTo(b.nombre));

      Sucursal? seleccionada = state.sucursalSeleccionada;
      if (sucursalesParsed.isNotEmpty && seleccionada == null) {
        seleccionada = sucursalesParsed.first;
      }

      state = state.copyWith(
        sucursales: sucursalesParsed,
        isSucursalesLoading: false,
        sucursalSeleccionada: seleccionada,
      );

      if (seleccionada != null) {
        cargarVentas();
      }
    } catch (e) {
      debugPrint('Error al cargar sucursales: $e');
      state = state.copyWith(
        isSucursalesLoading: false,
        errorMessage: 'Error al cargar sucursales: $e',
      );
    }
  }

  Future<bool> establecerSucursalPorId(sucursalId) async {
    try {
      if (sucursalId == null) {
        return false;
      }

      String sucursalIdStr = sucursalId.toString();
      try {
        final sucursalCompleta = await _sucursalRepository.getSucursalData(
          sucursalIdStr,
          useCache: false,
          forceRefresh: true,
        );

        List<Sucursal> nuevasSucursales = List.from(state.sucursales);
        if (!nuevasSucursales.any((s) => s.id.toString() == sucursalIdStr)) {
          nuevasSucursales = [sucursalCompleta];
        }

        state = state.copyWith(
          sucursalSeleccionada: sucursalCompleta,
          sucursales: nuevasSucursales,
        );
        return true;
      } catch (e) {
        final sucursalProvisional =
            _sucursalRepository.createProvisionalSucursal(sucursalIdStr);
        state = state.copyWith(
          sucursalSeleccionada: sucursalProvisional,
          sucursales: [sucursalProvisional],
        );
        return true;
      }
    } catch (e) {
      debugPrint('Error al establecer sucursal por ID: $e');
      return false;
    }
  }

  void cambiarSucursal(Sucursal sucursal) {
    state = state.copyWith(sucursalSeleccionada: sucursal);
    cargarVentas();
  }

  void limpiarErrores() {
    state = state.copyWith(
      errorMessage: '',
      ventasErrorMessage: '',
      ventaDetalleErrorMessage: '',
    );
  }

  void _actualizarPaginacion(int totalItems) {
    final int totalPages = (totalItems / state.itemsPerPage).ceil();
    final int currentPage = state.paginacion.currentPage > totalPages
        ? totalPages
        : state.paginacion.currentPage;

    final paginacion = Paginacion(
      totalItems: totalItems,
      totalPages: totalPages > 0 ? totalPages : 1,
      currentPage: currentPage > 0 ? currentPage : 1,
      hasNext: currentPage < totalPages,
      hasPrev: currentPage > 1,
    );

    state = state.copyWith(paginacion: paginacion);
  }

  Future<void> cargarVentas({int? sucursalId}) async {
    if (state.sucursalSeleccionada == null) {
      state = state.copyWith(
          ventasErrorMessage: 'Debe seleccionar una sucursal', ventas: []);
      return;
    }

    state = state.copyWith(isVentasLoading: true, ventasErrorMessage: '');

    try {
      final response = await _ventaRepository.getVentas(
        sucursalId: sucursalId ?? state.sucursalSeleccionada!.id,
        page: state.paginacion.currentPage,
        pageSize: state.itemsPerPage,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        sortBy: state.ordenarPor,
        order: state.orden,
        forceRefresh: true,
      );

      List<Venta> nuevasVentas = [];

      if (response.containsKey('data') && response['data'] is List) {
        final rawList = response['data'] as List<dynamic>;
        nuevasVentas = rawList
            .map((item) {
              try {
                if (item is Venta) {
                  return item;
                }
                if (item is Map<String, dynamic>) {
                  return Venta.fromJson(item);
                }
                return null;
              } catch (e) {
                return null;
              }
            })
            .whereType<Venta>()
            .toList();
      }

      state = state.copyWith(ventas: nuevasVentas);

      if (response.containsKey('pagination') && response['pagination'] is Map) {
        final Map<String, dynamic> paginationMap =
            Map<String, dynamic>.from(response['pagination'] as Map);
        try {
          final int totalItems = paginationMap['totalItems'] as int? ?? 0;
          final int totalPages = paginationMap['totalPages'] as int? ?? 1;
          final int currentPage = paginationMap['currentPage'] as int? ?? 1;

          state = state.copyWith(
            paginacion: Paginacion(
              totalItems: totalItems,
              totalPages: totalPages > 0 ? totalPages : 1,
              currentPage: currentPage > 0 ? currentPage : 1,
              hasNext: currentPage < totalPages,
              hasPrev: currentPage > 1,
            ),
          );
        } catch (e) {
          if (paginationMap.containsKey('totalItems')) {
            final dynamic totalItems = paginationMap['totalItems'];
            _actualizarPaginacion(totalItems is int
                ? totalItems
                : int.tryParse(totalItems.toString()) ?? nuevasVentas.length);
          } else {
            _actualizarPaginacion(nuevasVentas.length);
          }
        }
      } else if (response.containsKey('total')) {
        final dynamic total = response['total'];
        _actualizarPaginacion(total is int
            ? total
            : int.tryParse(total.toString()) ?? nuevasVentas.length);
      } else {
        _actualizarPaginacion(nuevasVentas.length);
      }

      state = state.copyWith(isVentasLoading: false);
    } catch (e) {
      state = state.copyWith(
          isVentasLoading: false,
          ventasErrorMessage: 'Error al cargar ventas: $e');
    }
  }

  Future<Venta?> cargarDetalleVenta(String id) async {
    if (state.sucursalSeleccionada == null) {
      state = state.copyWith(
          ventaDetalleErrorMessage: 'Debe seleccionar una sucursal');
      return null;
    }

    state = state.copyWith(
        isVentaDetalleLoading: true, ventaDetalleErrorMessage: '');

    try {
      final Venta? venta = await _ventaRepository.getVenta(
        id,
        sucursalId: state.sucursalSeleccionada!.id,
        forceRefresh: true,
      );

      if (venta == null) {
        state = state.copyWith(
            ventaDetalleErrorMessage: 'No se pudo cargar la venta',
            isVentaDetalleLoading: false);
        return null;
      }

      state = state.copyWith(
          ventaSeleccionada: venta, isVentaDetalleLoading: false);
      return venta;
    } catch (e) {
      state = state.copyWith(
          isVentaDetalleLoading: false,
          ventaDetalleErrorMessage: 'Error al cargar detalle de venta: $e');
      return null;
    }
  }

  Future<void> cambiarPagina(int nuevaPagina) async {
    if (nuevaPagina < 1 || nuevaPagina > state.paginacion.totalPages) {
      return;
    }

    state = state.copyWith(
      paginacion: Paginacion(
        totalItems: state.paginacion.totalItems,
        totalPages: state.paginacion.totalPages,
        currentPage: nuevaPagina,
        hasNext: nuevaPagina < state.paginacion.totalPages,
        hasPrev: nuevaPagina > 1,
      ),
    );
    await cargarVentas();
  }

  Future<void> cambiarItemsPorPagina(int nuevoTamano) async {
    if (nuevoTamano < 1 || nuevoTamano > 200) {
      return;
    }

    state = state.copyWith(
      itemsPerPage: nuevoTamano,
      paginacion: Paginacion(
        totalItems: state.paginacion.totalItems,
        totalPages: (state.paginacion.totalItems / nuevoTamano).ceil(),
        currentPage: 1,
        hasNext: state.paginacion.totalItems > nuevoTamano,
        hasPrev: false,
      ),
    );
    await cargarVentas();
  }

  Future<void> cambiarOrdenarPor(String? campo) async {
    state = state.copyWith(ordenarPor: campo);
    await cargarVentas();
  }

  Future<void> cambiarOrden(String nuevoOrden) async {
    if (nuevoOrden != 'asc' && nuevoOrden != 'desc') {
      return;
    }
    state = state.copyWith(orden: nuevoOrden);
    await cargarVentas();
  }

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
      final String? sucursalIdStr = await _getCurrentSucursalId(sucursalId);
      if (sucursalIdStr == null) {
        return {
          'status': 'error',
          'message': 'No se pudo determinar la sucursal para la venta'
        };
      }
      if (clienteId <= 0) {
        return {'status': 'error', 'message': 'Se requiere un cliente válido'};
      }
      if (empleadoId <= 0) {
        return {'status': 'error', 'message': 'Se requiere un empleado válido'};
      }
      if (detalles.isEmpty) {
        return {
          'status': 'error',
          'message': 'La venta debe contener al menos un producto'
        };
      }

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
        'detalles': detalles.map((d) => d.toCreateJson()).toList(),
      };

      final response = await _ventaRepository.createVenta(ventaData,
          sucursalId: sucursalIdStr);
      await cargarVentas(sucursalId: int.tryParse(sucursalIdStr));
      return response;
    } catch (e) {
      return {'status': 'error', 'message': 'Error al crear la venta: $e'};
    }
  }

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
        sku: sku);
  }

  Future<String?> _getCurrentSucursalId(int? sucursalId) async {
    if (sucursalId != null) {
      return sucursalId.toString();
    }
    if (state.sucursalSeleccionada != null) {
      return state.sucursalSeleccionada!.id.toString();
    }
    return _ventaRepository.getCurrentSucursalId();
  }

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
            duration: duration),
      );
    }
  }

  Color getEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'COMPLETADA':
      case 'ACEPTADO-SUNAT':
      case 'ACEPTADO ANTE LA SUNAT':
        return Colors.green;
      case 'ANULADA':
        return Colors.red;
      case 'CANCELADA':
        return Colors.orange.shade900;
      case 'DECLARADA':
        return Colors.blue;
      case 'PENDIENTE':
      default:
        return Colors.orange;
    }
  }

  bool tienePdfTicketDisponible(Venta venta) {
    return venta.documentoFacturacion != null &&
        venta.documentoFacturacion!.linkPdfTicket != null;
  }

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

  bool estaVentaCancelada(Venta venta) {
    return venta.cancelada;
  }

  Future<bool> declararVenta(
    String ventaId, {
    bool enviarCliente = false,
    VoidCallback? onSuccess,
    Function(String)? onError,
  }) async {
    state = state.copyWith(isVentasLoading: true);

    try {
      if (state.sucursalSeleccionada == null) {
        const errorMsg = 'No hay una sucursal seleccionada';
        if (onError != null) {
          onError(errorMsg);
        } else {
          mostrarMensaje(mensaje: errorMsg, backgroundColor: Colors.red);
        }
        throw Exception(errorMsg);
      }

      final result = await _ventaRepository.declararVenta(
        ventaId,
        sucursalId: state.sucursalSeleccionada!.id,
        enviarCliente: enviarCliente,
      );

      if (result['status'] != 'success') {
        final errorMsg = result['message'] ?? 'Error al declarar la venta';
        if (onError != null) {
          onError(errorMsg);
        } else {
          mostrarMensaje(mensaje: errorMsg, backgroundColor: Colors.red);
        }
        state = state.copyWith(isVentasLoading: false);
        return false;
      }

      await cargarVentas();

      if (state.ventaSeleccionada != null &&
          state.ventaSeleccionada!.id.toString() == ventaId) {
        await cargarDetalleVenta(ventaId);
      }

      if (onSuccess != null) {
        onSuccess();
      } else {
        mostrarMensaje(
            mensaje: 'Venta declarada correctamente a SUNAT',
            backgroundColor: Colors.green);
      }

      state = state.copyWith(isVentasLoading: false);
      return true;
    } catch (e) {
      final errorMsg = 'Error al declarar venta: $e';
      if (onError != null) {
        onError(errorMsg);
      } else {
        mostrarMensaje(mensaje: errorMsg, backgroundColor: Colors.red);
      }
      state =
          state.copyWith(ventasErrorMessage: errorMsg, isVentasLoading: false);
      return false;
    }
  }
}
