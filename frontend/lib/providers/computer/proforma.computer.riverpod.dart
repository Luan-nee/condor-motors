import 'dart:async';

import 'package:condorsmotors/main.dart' show proformaNotification;
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/proforma.model.dart';
import 'package:condorsmotors/providers/print.riverpod.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:condorsmotors/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'proforma.computer.riverpod.g.dart';

class ProformaComputerState {
  final int currentPage;
  final String? errorMessage;
  final bool hayNuevasProformas;
  final int intervaloActualizacion;
  final bool isLoading;
  final bool actualizacionAutomaticaActiva;
  final Paginacion? paginacion;
  final List<Proforma> proformas;
  final Set<int> proformasIds;
  final Stream<List<Proforma>>? proformasStream;
  final Proforma? selectedProforma;

  const ProformaComputerState({
    this.currentPage = 1,
    this.errorMessage,
    this.hayNuevasProformas = false,
    this.intervaloActualizacion = 8,
    this.isLoading = false,
    this.actualizacionAutomaticaActiva = true,
    this.paginacion,
    this.proformas = const [],
    this.proformasIds = const {},
    this.proformasStream,
    this.selectedProforma,
  });

  ProformaComputerState copyWith({
    int? currentPage,
    String? errorMessage,
    bool? hayNuevasProformas,
    int? intervaloActualizacion,
    bool? isLoading,
    bool? actualizacionAutomaticaActiva,
    Paginacion? paginacion,
    List<Proforma>? proformas,
    Set<int>? proformasIds,
    Stream<List<Proforma>>? proformasStream,
    Proforma? selectedProforma,
  }) {
    return ProformaComputerState(
      currentPage: currentPage ?? this.currentPage,
      errorMessage: errorMessage ??
          this.errorMessage, // To clear, we need to pass a specific value, but we can manage it. We'll add error clearing directly.
      hayNuevasProformas: hayNuevasProformas ?? this.hayNuevasProformas,
      intervaloActualizacion:
          intervaloActualizacion ?? this.intervaloActualizacion,
      isLoading: isLoading ?? this.isLoading,
      actualizacionAutomaticaActiva:
          actualizacionAutomaticaActiva ?? this.actualizacionAutomaticaActiva,
      paginacion: paginacion ?? this.paginacion,
      proformas: proformas ?? this.proformas,
      proformasIds: proformasIds ?? this.proformasIds,
      proformasStream: proformasStream ?? this.proformasStream,
      selectedProforma: selectedProforma ?? this.selectedProforma,
    );
  }
}

@Riverpod(keepAlive: true)
class ProformaComputer extends _$ProformaComputer {
  final ProformaRepository _proformaRepository = ProformaRepository.instance;
  final SucursalRepository _sucursalRepository = SucursalRepository.instance;
  final VentaRepository _ventaRepository = VentaRepository.instance;

  StreamController<List<Proforma>>? _proformasStreamController;
  Timer? _actualizacionTimer;
  StreamSubscription<List<Proforma>>? _proformasSubscription;

  static const List<int> intervalosDisponibles = [8, 15, 30];
  static const String actualizacionAutomaticaKey =
      'proforma_actualizacion_automatica';

  @override
  ProformaComputerState build() {
    ref.onDispose(() {
      _cerrarStream();
      _actualizacionTimer?.cancel();
    });
    return const ProformaComputerState();
  }

  bool get actualizacionAutomaticaActiva => state.actualizacionAutomaticaActiva;
  List<Proforma> get proformas => state.proformas;
  Proforma? get selectedProforma => state.selectedProforma;
  bool get isLoading => state.isLoading;
  String? get errorMessage => state.errorMessage;
  Paginacion? get paginacion => state.paginacion;
  int get currentPage => state.currentPage;
  int get intervaloActualizacion => state.intervaloActualizacion;
  bool get hayNuevasProformas => state.hayNuevasProformas;
  Stream<List<Proforma>>? get proformasStream => state.proformasStream;

  Future<void> initialize(int? sucursalId) async {
    await _cargarEstadoActualizacionAutomatica();
    await loadProformas(sucursalId: sucursalId);
    if (state.actualizacionAutomaticaActiva) {
      _iniciarStreamProformas(sucursalId);
    }
  }

  Future<void> _cargarEstadoActualizacionAutomatica() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final activa = prefs.getBool(actualizacionAutomaticaKey) ?? true;
      state = state.copyWith(actualizacionAutomaticaActiva: activa);
      Logger.info('Estado de actualización automática cargado: $activa');
    } catch (e) {
      Logger.error('Error al cargar estado de actualización automática: $e');
    }
  }

  Future<void> _guardarEstadoActualizacionAutomatica(bool estado) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(actualizacionAutomaticaKey, estado);
      Logger.info('Estado de actualización automática guardado: $estado');
    } catch (e) {
      Logger.error('Error al guardar estado de actualización automática: $e');
    }
  }

  Future<void> toggleActualizacionAutomatica(int? sucursalId) async {
    final newState = !state.actualizacionAutomaticaActiva;
    state = state.copyWith(actualizacionAutomaticaActiva: newState);
    await _guardarEstadoActualizacionAutomatica(newState);

    if (newState) {
      reanudarActualizacionesEnTiempoReal(sucursalId);
    } else {
      pausarActualizacionesEnTiempoReal();
      await loadProformas(sucursalId: sucursalId);
    }
  }

  Future<void> loadProformas({int? sucursalId, bool silencioso = false}) async {
    if (state.isLoading && !silencioso) {
      return;
    }

    if (!silencioso) {
      state = state.copyWith(isLoading: true, errorMessage: '');
    }

    try {
      String? sucursalIdStr = await _getSucursalId(sucursalId);
      if (sucursalIdStr == null) {
        if (!silencioso) {
          state = state.copyWith(
              errorMessage: 'No se pudo determinar la sucursal del usuario',
              isLoading: false);
        }
        return;
      }

      final response = await _proformaRepository.getProformas(
        sucursalId: sucursalIdStr,
        page: state.currentPage,
        pageSize: 25, // Estandarizado a 25
        forceRefresh: true,
        useCache: false,
      );

      if (response.isNotEmpty) {
        final proformas = _proformaRepository.parseProformas(response);

        final Map<String, dynamic>? paginacionJson = response['pagination'];
        Paginacion? paginacionObj;

        if (paginacionJson != null) {
          final total = paginacionJson['total'] as int? ?? 0;
          final int currentPage = paginacionJson['page'] as int? ?? 1;
          final int pageSize = paginacionJson['pageSize'] as int? ?? 25;
          final int totalPages = (total / pageSize).ceil();
          final bool hasNext = currentPage < totalPages;
          final bool hasPrev = currentPage > 1;

          // Ajuste inteligente
          int actualPageSize = pageSize;
          if (total > 0 && total < actualPageSize) {
            actualPageSize = total;
          }

          paginacionObj = Paginacion(
            totalItems: total,
            totalPages: totalPages > 0 ? totalPages : 1,
            currentPage: currentPage > 0 ? currentPage : 1,
            hasNext: hasNext,
            hasPrev: hasPrev,
            pageSize: actualPageSize, // Incluir el ajuste
          );
        }

        final proformasIds = proformas.map((p) => p.id).toSet();

        Proforma? newSelected = state.selectedProforma;
        if (newSelected != null &&
            !proformas.any((p) => p.id == newSelected!.id)) {
          newSelected = null;
        }

        state = state.copyWith(
          proformas: proformas,
          proformasIds: proformasIds,
          paginacion: paginacionObj,
          isLoading: false,
          hayNuevasProformas: false,
          selectedProforma: newSelected,
        );
      } else {
        if (!silencioso) {
          state = state.copyWith(
              errorMessage: 'No se pudo cargar las proformas',
              isLoading: false);
        }
      }
    } catch (e) {
      Logger.error('Error al cargar proformas: $e');
      if (!silencioso) {
        state = state.copyWith(errorMessage: 'Error: $e', isLoading: false);
      }
    }
  }

  void setPage(int page, {int? sucursalId}) {
    state = state.copyWith(currentPage: page);
    loadProformas(sucursalId: sucursalId);
  }

  void selectProforma(Proforma proforma) {
    state = state.copyWith(selectedProforma: proforma);
  }

  void clearSelectedProforma() {
    state = state.copyWith();
  }

  Future<bool> handleConvertToSale(Proforma proforma, int? sucursalId,
      {VoidCallback? onSuccess}) async {
    try {
      String? sucursalIdStr = await _getSucursalId(sucursalId);
      if (sucursalIdStr == null) {
        Logger.error('No se pudo determinar la sucursal del usuario');
        return false;
      }

      _limpiarCaches(sucursalIdStr);

      final ventaResponse = await _proformaRepository.convertirAVenta(
        sucursalId: sucursalIdStr,
        proforma: proforma,
      );

      if (ventaResponse['status'] == 'success') {
        _limpiarCaches(sucursalIdStr);

        final ventaDeclarada =
            await _declararVentaRecienCreada(ventaResponse, sucursalIdStr);

        if (ventaDeclarada) {
          await _imprimirVentaDeclarada(ventaResponse, sucursalIdStr);
        }

        await _recargarDatosCompletos(sucursalIdStr, sucursalId);

        if (state.selectedProforma != null &&
            state.selectedProforma!.id == proforma.id) {
          clearSelectedProforma();
        }

        if (onSuccess != null) {
          onSuccess();
        }

        return true;
      } else {
        Logger.error(
            'Error en respuesta al convertir a venta: ${ventaResponse['message'] ?? "Error desconocido"}');
        return false;
      }
    } catch (e) {
      Logger.error('Error al convertir proforma a venta: $e');
      return false;
    }
  }

  Future<bool> _declararVentaRecienCreada(
      Map<String, dynamic> ventaResponse, String sucursalId) async {
    try {
      int? ventaId;

      if (ventaResponse.containsKey('data') &&
          ventaResponse['data'] is Map<String, dynamic> &&
          ventaResponse['data'].containsKey('id')) {
        ventaId = int.tryParse(ventaResponse['data']['id'].toString());
      }

      if (ventaId == null) {
        Logger.error(
            'No se pudo obtener el ID de la venta creada para declararla');
        return false;
      }

      Logger.debug('Declarando venta #$ventaId ante SUNAT');

      final Map<String, dynamic> declaracionResponse =
          await _ventaRepository.declararVenta(
        ventaId.toString(),
        sucursalId: sucursalId,
      );

      if (declaracionResponse['status'] == 'success') {
        Logger.debug('Venta #$ventaId declarada correctamente ante SUNAT');
        return true;
      } else {
        final String errorMsg = declaracionResponse['error'] ??
            declaracionResponse['message'] ??
            'Error desconocido';
        Logger.error('Error al declarar venta #$ventaId: $errorMsg');
        return false;
      }
    } catch (e) {
      Logger.error('Error al declarar venta recién creada: $e');
      return false;
    }
  }

  Future<void> _imprimirVentaDeclarada(
      Map<String, dynamic> ventaResponse, String sucursalId) async {
    try {
      final ventaId = ventaResponse['data']['id'].toString();
      final ventaCompleta = await _ventaRepository.getVenta(
        ventaId,
        sucursalId: sucursalId,
        forceRefresh: true,
      );

      if (ventaCompleta == null || ventaCompleta.documentoFacturacion == null) {
        Logger.error(
            'No se pudo obtener la información de la venta para imprimir');
        return;
      }

      final printState = ref.read(printConfigProvider);

      String? pdfUrl;
      if (printState.imprimirFormatoTicket) {
        pdfUrl = ventaCompleta.documentoFacturacion!.linkPdfTicket;
        Logger.debug('Usando formato ticket para impresión');
      } else {
        pdfUrl = ventaCompleta.documentoFacturacion!.linkPdfA4;
        Logger.debug('Usando formato A4 para impresión');
      }

      if (pdfUrl == null) {
        Logger.error('No se encontró URL del PDF para imprimir');
        return;
      }

      await ref.read(printConfigProvider.notifier).imprimirDocumentoPdf(
            pdfUrl,
            '${ventaCompleta.serieDocumento}-${ventaCompleta.numeroDocumento}_${printState.imprimirFormatoTicket ? "TICKET" : "A4"}',
          );

      Logger.debug('Documento enviado a imprimir automáticamente');
    } catch (e) {
      Logger.error('Error al imprimir venta declarada: $e');
    }
  }

  void _limpiarCaches(String sucursalId) {
    try {
      _proformaRepository
        ..invalidateCache(sucursalId)
        ..invalidateCache();
      Logger.debug('Caché de proformas invalidado para sucursal $sucursalId');

      _ventaRepository
        ..invalidateCache(sucursalId)
        ..invalidateCache();
      Logger.debug('Caché de ventas invalidado para sucursal $sucursalId');

      _sucursalRepository.invalidateCache();
      Logger.debug('Caché de sucursales invalidado');
    } catch (e) {
      Logger.error('Error al limpiar cachés: $e');
    }
  }

  Future<void> _recargarDatosCompletos(
      String sucursalIdStr, int? sucursalId) async {
    try {
      await _sucursalRepository.getSucursalData(sucursalIdStr,
          forceRefresh: true);
      Logger.debug('Datos de sucursal recargados: $sucursalIdStr');

      await loadProformas(sucursalId: sucursalId);
      Logger.debug('Lista de proformas recargada para sucursal $sucursalIdStr');

      await _ventaRepository.getVentas(
        sucursalId: sucursalIdStr,
        useCache: false,
        forceRefresh: true,
      );
      Logger.debug('Lista de ventas recargada para sucursal $sucursalIdStr');
    } catch (e) {
      Logger.error('Error al recargar datos completos: $e');
      await loadProformas(sucursalId: sucursalId);
    }
  }

  Future<bool> deleteProforma(Proforma proforma, int? sucursalId) async {
    try {
      String? sucursalIdStr = await _getSucursalId(sucursalId);
      if (sucursalIdStr == null) {
        return false;
      }

      final response = await _proformaRepository.deleteProforma(
        sucursalId: sucursalIdStr,
        proformaId: proforma.id,
      );

      final bool exito =
          response.containsKey('status') && response['status'] == 'success';

      if (exito) {
        await loadProformas(sucursalId: sucursalId);

        if (state.selectedProforma != null &&
            state.selectedProforma!.id == proforma.id) {
          clearSelectedProforma();
        }
      }

      return exito;
    } catch (e) {
      Logger.error('Error al eliminar proforma: $e');
      return false;
    }
  }

  void setIntervaloActualizacion(int nuevoIntervalo, int? sucursalId) {
    if (!intervalosDisponibles.contains(nuevoIntervalo)) {
      return;
    }

    state = state.copyWith(intervaloActualizacion: nuevoIntervalo);

    if (_actualizacionTimer != null) {
      _iniciarStreamProformas(sucursalId);
    }

    Logger.info(
        'Intervalo de actualización cambiado a $nuevoIntervalo segundos');
  }

  void _iniciarStreamProformas(int? sucursalId) {
    _cerrarStream();

    _proformasStreamController = StreamController<List<Proforma>>.broadcast();
    state = state.copyWith(proformasStream: _proformasStreamController?.stream);

    _actualizacionTimer = Timer.periodic(
      Duration(seconds: state.intervaloActualizacion),
      (_) async {
        if (_proformasStreamController?.isClosed ?? true) {
          return;
        }
        final proformas = await _fetchProformasRealTime(sucursalId);
        _proformasStreamController?.add(proformas);
      },
    );

    _proformasSubscription =
        state.proformasStream?.listen((proformasActualizadas) {
      _procesarProformasActualizadas(proformasActualizadas, sucursalId);
    });

    Logger.info(
        'Stream de proformas iniciado (cada ${state.intervaloActualizacion} segundos)');
  }

  void _cerrarStream() {
    _actualizacionTimer?.cancel();
    _actualizacionTimer = null;
    _proformasSubscription?.cancel();
    _proformasSubscription = null;
    _proformasStreamController?.close();
    _proformasStreamController = null;
    state = state.copyWith();
    Logger.info('Stream de proformas cerrado completamente');
  }

  void pausarActualizacionesEnTiempoReal() {
    _cerrarStream();
    Logger.info('Actualizaciones en tiempo real pausadas completamente');
  }

  void reanudarActualizacionesEnTiempoReal(int? sucursalId) {
    _iniciarStreamProformas(sucursalId);
    Logger.info('Actualizaciones en tiempo real reanudadas');
    loadProformas(sucursalId: sucursalId);
  }

  Future<List<Proforma>> _fetchProformasRealTime(int? sucursalId) async {
    try {
      String? sucursalIdStr = await _getSucursalId(sucursalId);
      if (sucursalIdStr == null) {
        return [];
      }

      final response = await _proformaRepository.getProformas(
        sucursalId: sucursalIdStr,
        pageSize: 30,
        forceRefresh: true,
        useCache: false,
      );

      if (response.isNotEmpty) {
        return _proformaRepository.parseProformas(response);
      }
      return [];
    } catch (e) {
      Logger.error('Error al obtener proformas en tiempo real: $e');
      return [];
    }
  }

  void _procesarProformasActualizadas(
      List<Proforma> proformasActualizadas, int? sucursalId) {
    if (proformasActualizadas.isEmpty) {
      return;
    }

    Set<int> nuevosIds = proformasActualizadas.map((p) => p.id).toSet();
    Set<int> proformasNuevas = nuevosIds.difference(state.proformasIds);

    if (proformasNuevas.isNotEmpty) {
      Logger.info(
          'Se detectaron ${proformasNuevas.length} nuevas proformas en tiempo real!');

      for (var id in proformasNuevas) {
        final nuevaProforma =
            proformasActualizadas.firstWhere((p) => p.id == id);
        _notificarNuevaProforma(nuevaProforma);
      }

      state = state.copyWith(hayNuevasProformas: true);

      loadProformas(sucursalId: sucursalId, silencioso: true);
    }
  }

  Future<void> _notificarNuevaProforma(Proforma proforma) async {
    try {
      if (proformaNotification.isEnabled) {
        await proformaNotification.notifyNewProformaPending(
          proforma,
          proforma.getNombreCliente(),
        );
        Logger.info('Notificación enviada para nueva proforma #${proforma.id}');
      }
    } catch (e) {
      Logger.error('Error al enviar notificación: $e');
    }
  }

  Future<String?> _getSucursalId(int? sucursalIdParam) async {
    if (sucursalIdParam != null) {
      return sucursalIdParam.toString();
    } else {
      return _proformaRepository.getCurrentSucursalId();
    }
  }
}
