import 'dart:async';
import 'package:condorsmotors/components/transferencia_notificacion.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'transferencias.colab.riverpod.g.dart';

class TransferenciasColabState {
  final bool isLoading;
  final String? errorMessage;
  final List<TransferenciaInventario> transferencias;
  final String? sucursalId;
  final int? empleadoId;
  final String selectedFilter;
  final List<DetalleProducto> productosSeleccionados;
  final List<Producto> productosParaTransferir;
  final List<Producto> productosBajoStockParaTransferir;
  final TransferenciaInventario? detalleTransferenciaActual;
  final String searchQuery;
  final String filtroCategoria;
  final String ordenarPor;
  final String orden;
  final bool soloStockBajo;
  final bool soloStockPositivo;
  final double? precioMinimo;
  final double? precioMaximo;
  final int paginaActual;
  final int tamanoPagina;
  final int userPreferredPageSize;
  final Paginacion? paginacion;

  TransferenciasColabState({
    this.isLoading = false,
    this.errorMessage,
    this.transferencias = const [],
    this.sucursalId,
    this.empleadoId,
    this.selectedFilter = 'Todos',
    this.productosSeleccionados = const [],
    this.productosParaTransferir = const [],
    this.productosBajoStockParaTransferir = const [],
    this.detalleTransferenciaActual,
    this.searchQuery = '',
    this.filtroCategoria = 'Todos',
    this.ordenarPor = 'nombre',
    this.orden = 'asc',
    this.soloStockBajo = false,
    this.soloStockPositivo = false,
    this.precioMinimo,
    this.precioMaximo,
    this.paginaActual = 1,
    this.tamanoPagina = 25,
    this.userPreferredPageSize = 25,
    this.paginacion,
  });

  TransferenciasColabState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<TransferenciaInventario>? transferencias,
    String? sucursalId,
    int? empleadoId,
    String? selectedFilter,
    List<DetalleProducto>? productosSeleccionados,
    List<Producto>? productosParaTransferir,
    List<Producto>? productosBajoStockParaTransferir,
    TransferenciaInventario? detalleTransferenciaActual,
    String? searchQuery,
    String? filtroCategoria,
    String? ordenarPor,
    String? orden,
    bool? soloStockBajo,
    bool? soloStockPositivo,
    double? precioMinimo,
    double? precioMaximo,
    int? paginaActual,
    int? tamanoPagina,
    int? userPreferredPageSize,
    Paginacion? paginacion,
  }) {
    return TransferenciasColabState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      transferencias: transferencias ?? this.transferencias,
      sucursalId: sucursalId ?? this.sucursalId,
      empleadoId: empleadoId ?? this.empleadoId,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      productosSeleccionados:
          productosSeleccionados ?? this.productosSeleccionados,
      productosParaTransferir:
          productosParaTransferir ?? this.productosParaTransferir,
      productosBajoStockParaTransferir: productosBajoStockParaTransferir ??
          this.productosBajoStockParaTransferir,
      detalleTransferenciaActual:
          detalleTransferenciaActual ?? this.detalleTransferenciaActual,
      searchQuery: searchQuery ?? this.searchQuery,
      filtroCategoria: filtroCategoria ?? this.filtroCategoria,
      ordenarPor: ordenarPor ?? this.ordenarPor,
      orden: orden ?? this.orden,
      soloStockBajo: soloStockBajo ?? this.soloStockBajo,
      soloStockPositivo: soloStockPositivo ?? this.soloStockPositivo,
      precioMinimo: precioMinimo ?? this.precioMinimo,
      precioMaximo: precioMaximo ?? this.precioMaximo,
      paginaActual: paginaActual ?? this.paginaActual,
      tamanoPagina: tamanoPagina ?? this.tamanoPagina,
      userPreferredPageSize: userPreferredPageSize ?? this.userPreferredPageSize,
      paginacion: paginacion ?? this.paginacion,
    );
  }
}

@riverpod
class TransferenciasColab extends _$TransferenciasColab {
  late final TransferenciaRepository _transferenciaRepository;
  late final ProductoRepository _productoRepository;
  Timer? _pollingTimer;
  int? _ultimoIdTransferenciaRecibida;

  @override
  TransferenciasColabState build() {
    _transferenciaRepository = TransferenciaRepository.instance;
    _productoRepository = ProductoRepository.instance;

    ref.onDispose(() {
      _pollingTimer?.cancel();
    });

    return TransferenciasColabState();
  }

  Future<void> inicializar() async {
    await _obtenerDatosUsuario();
  }

  Future<void> _obtenerDatosUsuario() async {
    state = state.copyWith(isLoading: true);
    try {
      final Map<String, dynamic>? userData =
          await _transferenciaRepository.getUserData();
      if (userData != null) {
        state = state.copyWith(
          sucursalId: userData['sucursalId']?.toString(),
          empleadoId: int.tryParse(userData['id']?.toString() ?? '0'),
        );
        await cargarTransferencias();
      } else {
        state = state.copyWith(
            errorMessage: 'No se pudieron obtener datos del usuario',
            isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Error al obtener datos del usuario: $e',
          isLoading: false);
    }
  }

  Future<void> cargarTransferencias({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true);
    try {
      // Usamos la preferencia guardada del usuario como base para la petición
      int requestPageSize = state.userPreferredPageSize;

      final paginatedResponse =
          await _transferenciaRepository.getTransferencias(
        page: state.paginaActual,
        pageSize: requestPageSize,
        sortBy: state.ordenarPor,
        order: state.orden,
        forceRefresh: forceRefresh,
      );

      // Ajuste inteligente del tamaño de página si hay pocos elementos
      int actualPageSize = state.tamanoPagina;
      if (paginatedResponse.totalItems > 0 &&
          paginatedResponse.totalItems < actualPageSize) {
        actualPageSize = paginatedResponse.totalItems;
      }

      state = state.copyWith(
        transferencias: paginatedResponse.items,
        paginacion: paginatedResponse.paginacion.copyWith(pageSize: actualPageSize),
        tamanoPagina: actualPageSize,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Error al cargar transferencias: $e', isLoading: false);
    }
  }

  Future<TransferenciaInventario> obtenerDetalleTransferencia(String id) async {
    try {
      return await _transferenciaRepository.getTransferencia(id);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al obtener detalle: $e');
      rethrow;
    }
  }

  Future<void> cargarDetalleTransferencia(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      final transferencia = await _transferenciaRepository.getTransferencia(id);
      state = state.copyWith(
          detalleTransferenciaActual: transferencia, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<ComparacionTransferencia> obtenerComparacionTransferencia(
      String id) async {
    if (state.sucursalId == null) {
      throw Exception('No se ha establecido la sucursal de origen');
    }
    try {
      return await _transferenciaRepository.compararTransferencia(
        id: id,
        sucursalOrigenId: int.parse(state.sucursalId!),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al comparar: $e');
      rethrow;
    }
  }

  Future<bool> crearTransferencia(
    int sucursalDestinoId,
    List<DetalleProducto> productos,
  ) async {
    if (state.sucursalId == null) {
      state = state.copyWith(
          errorMessage: 'ID de sucursal no disponible', isLoading: false);
      return false;
    }
    state = state.copyWith(isLoading: true);
    try {
      final items = productos
          .map((p) => {
                'productoId': p.id,
                'cantidad': p.cantidad,
              })
          .toList();

      final nuevaTransferencia =
          await _transferenciaRepository.createTransferencia(
        sucursalDestinoId: sucursalDestinoId,
        items: items,
      );

      _transferenciaRepository.invalidateCache(state.sucursalId);

      state = state.copyWith(
        transferencias: [nuevaTransferencia, ...state.transferencias],
        productosSeleccionados: [],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Error al crear transferencia: $e', isLoading: false);
      return false;
    }
  }

  void agregarProducto(DetalleProducto producto) {
    if (state.productosSeleccionados.any((p) => p.id == producto.id)) {
      state = state.copyWith(errorMessage: 'El producto ya está en la lista');
      return;
    }
    state = state.copyWith(
        productosSeleccionados: [...state.productosSeleccionados, producto]);
  }

  int getCantidadTotalProductosSeleccionados() {
    return state.productosSeleccionados.fold(0, (sum, p) => sum + p.cantidad);
  }

  void removerProducto(int productoId) {
    state = state.copyWith(
      productosSeleccionados: state.productosSeleccionados
          .where((p) => p.id != productoId)
          .toList(),
    );
  }

  void actualizarCantidadProducto(int productoId, int nuevaCantidad) {
    state = state.copyWith(
      productosSeleccionados: state.productosSeleccionados.map((p) {
        if (p.id == productoId) {
          return DetalleProducto(
            id: p.id,
            nombre: p.nombre,
            codigo: p.codigo,
            cantidad: nuevaCantidad,
            producto: p.producto,
          );
        }
        return p;
      }).toList(),
    );
  }

  Future<void> validarRecepcion(TransferenciaInventario transferencia) async {
    state = state.copyWith(isLoading: true);
    try {
      await _transferenciaRepository.recibirTransferencia(
        transferencia.id.toString(),
      );
      await cargarTransferencias();
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Error al validar recepción: $e', isLoading: false);
    }
  }

  Future<void> enviarTransferencia(
      TransferenciaInventario transferencia) async {
    state = state.copyWith(isLoading: true);
    try {
      if (state.sucursalId == null) {
        throw Exception('SucursalID nulo');
      }
      await _transferenciaRepository.enviarTransferencia(
        transferencia.id.toString(),
        sucursalOrigenId: int.parse(state.sucursalId!),
      );
      await cargarTransferencias();
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Error al enviar transferencia: $e', isLoading: false);
    }
  }

  Future<void> cambiarFiltro(String filtro) async {
    state = state.copyWith(selectedFilter: filtro);
    await cargarTransferencias();
  }

  List<TransferenciaInventario> getTransferenciasFiltradas() {
    if (state.selectedFilter == 'Todos') {
      return state.transferencias;
    }

    return state.transferencias.where((t) {
      final estadoFiltro = EstadoTransferencia.values.firstWhere(
        (e) => e.nombre == state.selectedFilter,
        orElse: () => EstadoTransferencia.pedido,
      );
      return t.estado == estadoFiltro;
    }).toList();
  }

  Future<PaginatedResponse<Producto>> obtenerProductosFiltrados({
    required String sucursalId,
    int? page,
    int? pageSize,
    bool useCache = false,
  }) async {
    try {
      if (state.soloStockBajo) {
        return await _productoRepository.getProductosConStockBajo(
          sucursalId: sucursalId,
          page: page ?? 1,
          pageSize: pageSize ?? 20,
          sortBy: state.ordenarPor,
          useCache: useCache,
        );
      }
      return await _productoRepository.getProductos(
        sucursalId: sucursalId,
        page: page ?? 1,
        pageSize: pageSize ?? 20,
        sortBy: state.ordenarPor,
        order: state.orden,
        filterType: state.filtroCategoria != 'Todos' ? 'categoria' : null,
        filterValue:
            state.filtroCategoria != 'Todos' ? state.filtroCategoria : null,
        stockBajo: state.soloStockPositivo ? true : null,
        useCache: useCache,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al filtrar: $e');
      rethrow;
    }
  }

  Future<void> cargarProductosParaFormulario({
    String? sucursalId,
    bool resetPaginacion = false,
  }) async {
    final targetSucursalId = sucursalId ?? state.sucursalId;
    if (targetSucursalId == null) {
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      if (resetPaginacion) {
        state = state.copyWith(paginaActual: 1);
      }

      // 1. Cargar productos con stock bajo (siempre se cargan para el formulario)
      final responseStockBajo =
          await _productoRepository.getProductosConStockBajo(
        sucursalId: targetSucursalId,
        pageSize: 100,
        sortBy: 'stock',
        useCache: false,
      );

      // 2. Cargar productos normales filtrados
      final responseNormales = await _productoRepository.getProductos(
        sucursalId: targetSucursalId,
        page: state.paginaActual,
        pageSize: state.tamanoPagina,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        filterType: state.filtroCategoria != 'Todos' ? 'categoria' : null,
        filterValue:
            state.filtroCategoria != 'Todos' ? state.filtroCategoria : null,
        sortBy: state.ordenarPor,
        order: state.orden,
        useCache: false,
      );

      state = state.copyWith(
        productosBajoStockParaTransferir: responseStockBajo.items,
        productosParaTransferir: responseNormales.items,
        paginacion: responseNormales.paginacion,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error al cargar productos para formulario: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar productos: $e',
      );
    }
  }

  void actualizarFiltros({
    String? searchQuery,
    String? categoria,
    String? ordenarPor,
    String? orden,
    bool? soloStockBajo,
    bool? soloStockPositivo,
    double? precioMinimo,
    double? precioMaximo,
  }) {
    state = state.copyWith(
      searchQuery: searchQuery ?? state.searchQuery,
      filtroCategoria: categoria ?? state.filtroCategoria,
      ordenarPor: ordenarPor ?? state.ordenarPor,
      orden: orden ?? state.orden,
      soloStockBajo: soloStockBajo ?? state.soloStockBajo,
      soloStockPositivo: soloStockPositivo ?? state.soloStockPositivo,
      precioMinimo: precioMinimo ?? state.precioMinimo,
      precioMaximo: precioMaximo ?? state.precioMaximo,
    );
  }

  void restablecerFiltros() {
    state = state.copyWith(
      searchQuery: '',
      filtroCategoria: 'Todos',
      ordenarPor: 'nombre',
      orden: 'asc',
      soloStockBajo: false,
      soloStockPositivo: false,
    );
  }

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final prefs = await SharedPreferences.getInstance();
      final notificationsActive =
          prefs.getBool('notificaciones_transferencias') ?? true;
      if (!notificationsActive) {
        return;
      }

      try {
        await cargarTransferencias();
        final filtradas = getTransferenciasFiltradas();
        if (filtradas.isNotEmpty) {
          final nueva = filtradas.first;
          if (_ultimoIdTransferenciaRecibida == null ||
              nueva.id > _ultimoIdTransferenciaRecibida!) {
            await TransferenciaNotificacion.showTransferenciaNotification(
              title: 'Nueva transferencia recibida',
              body: 'Has recibido una nueva transferencia (ID: ${nueva.id})',
              id: nueva.id,
            );
            _ultimoIdTransferenciaRecibida = nueva.id;
            await prefs.setInt('ultimo_id_transferencia_recibida', nueva.id);
          }
        }
      } catch (e) {
        debugPrint('Error polling: $e');
      }
    });
  }

  Future<void> cambiarPagina(int nuevaPagina) async {
    state = state.copyWith(paginaActual: nuevaPagina);
    await cargarTransferencias();
  }

  Future<void> cambiarTamanoPagina(int nuevoTamano) async {
    state = state.copyWith(
      userPreferredPageSize: nuevoTamano,
      tamanoPagina: nuevoTamano, 
      paginaActual: 1
    );
    await cargarTransferencias();
  }
}
