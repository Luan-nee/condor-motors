import 'dart:async';

import 'package:condorsmotors/main.dart' show proformaNotification;
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/proforma.model.dart';
import 'package:condorsmotors/providers/computer/ventas.computer.provider.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:condorsmotors/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider para gestionar el estado y lógica de negocio de las proformas
/// en la versión de computadora de la aplicación.
class ProformaComputerProvider extends ChangeNotifier {
  // Repositorios para acceder a los diferentes recursos
  final ProformaRepository _proformaRepository = ProformaRepository.instance;
  final SucursalRepository _sucursalRepository = SucursalRepository.instance;
  final VentaRepository _ventaRepository = VentaRepository.instance;
  late final VentasComputerProvider _ventasProvider;

  int _currentPage = 1;
  String? _errorMessage;
  bool _hayNuevasProformas = false;
  int _intervaloActualizacion = 8; // Segundos entre actualizaciones
  bool _isLoading = false;
  bool _actualizacionAutomaticaActiva = true;
  Paginacion? _paginacion;
  List<Proforma> _proformas = [];
  Set<int> _proformasIds = {}; // Para seguimiento de nuevas proformas
  Stream<List<Proforma>>? _proformasStream;
  // Para streaming en tiempo real
  StreamController<List<Proforma>>? _proformasStreamController;
  Timer? _actualizacionTimer;
  StreamSubscription<List<Proforma>>? _proformasSubscription;
  Proforma? _selectedProforma;

  static const List<int> intervalosDisponibles = [8, 15, 30];
  static const String actualizacionAutomaticaKey =
      'proforma_actualizacion_automatica';

  /// Constructor que recibe el VentasComputerProvider
  ProformaComputerProvider(VentasComputerProvider ventasProvider) {
    _ventasProvider = ventasProvider;
    // Asegurar que la configuración de impresión esté cargada
    _ventasProvider.cargarConfiguracionImpresion().then((_) {
      Logger.debug(
          'Configuración de impresión cargada en ProformaComputerProvider');
      Logger.debug('- Formato A4: ${_ventasProvider.imprimirFormatoA4}');
      Logger.debug(
          '- Formato Ticket: ${_ventasProvider.imprimirFormatoTicket}');
      Logger.debug('- Impresión directa: ${_ventasProvider.impresionDirecta}');
      Logger.debug(
          '- Impresora seleccionada: ${_ventasProvider.impresoraSeleccionada}');
    });
  }

  @override
  void dispose() {
    _cerrarStream();
    _actualizacionTimer?.cancel();
    super.dispose();
  }

  // Getters
  bool get actualizacionAutomaticaActiva => _actualizacionAutomaticaActiva;
  List<Proforma> get proformas => _proformas;
  Proforma? get selectedProforma => _selectedProforma;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Paginacion? get paginacion => _paginacion;
  int get currentPage => _currentPage;
  int get intervaloActualizacion => _intervaloActualizacion;
  bool get hayNuevasProformas => _hayNuevasProformas;
  Stream<List<Proforma>>? get proformasStream => _proformasStream;

  /// Inicializa el provider con la configuración necesaria
  Future<void> initialize(int? sucursalId) async {
    // Cargar estado de actualización automática
    await _cargarEstadoActualizacionAutomatica();

    // Cargar proformas iniciales
    await loadProformas(sucursalId: sucursalId);

    // Iniciar stream si la actualización automática está activa
    if (_actualizacionAutomaticaActiva) {
      _iniciarStreamProformas(sucursalId);
    }
  }

  /// Carga el estado guardado de actualización automática
  Future<void> _cargarEstadoActualizacionAutomatica() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _actualizacionAutomaticaActiva =
          prefs.getBool(actualizacionAutomaticaKey) ?? true;
      notifyListeners();
      Logger.info(
          'Estado de actualización automática cargado: $_actualizacionAutomaticaActiva');
    } catch (e) {
      Logger.error('Error al cargar estado de actualización automática: $e');
    }
  }

  /// Guarda el estado de actualización automática
  Future<void> _guardarEstadoActualizacionAutomatica(bool estado) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(actualizacionAutomaticaKey, estado);
      Logger.info('Estado de actualización automática guardado: $estado');
    } catch (e) {
      Logger.error('Error al guardar estado de actualización automática: $e');
    }
  }

  /// Cambia el estado de actualización automática
  Future<void> toggleActualizacionAutomatica(int? sucursalId) async {
    _actualizacionAutomaticaActiva = !_actualizacionAutomaticaActiva;
    await _guardarEstadoActualizacionAutomatica(_actualizacionAutomaticaActiva);

    if (_actualizacionAutomaticaActiva) {
      reanudarActualizacionesEnTiempoReal(sucursalId);
    } else {
      pausarActualizacionesEnTiempoReal();
      // Realizar una última actualización manual
      await loadProformas(sucursalId: sucursalId);
    }

    notifyListeners();
  }

  /// Carga las proformas desde el repositorio
  Future<void> loadProformas({int? sucursalId, bool silencioso = false}) async {
    if (_isLoading && !silencioso) {
      return;
    }

    if (!silencioso) {
      _isLoading = true;
      _errorMessage = null;
      // Usar microtask para evitar llamar a notifyListeners durante el build
      Future.microtask(notifyListeners);
    }

    try {
      // Obtener el ID de sucursal
      String? sucursalIdStr = await _getSucursalId(sucursalId);
      if (sucursalIdStr == null) {
        if (!silencioso) {
          _errorMessage = 'No se pudo determinar la sucursal del usuario';
          _isLoading = false;
          // Usar microtask para evitar llamar a notifyListeners durante el build
          Future.microtask(notifyListeners);
        }
        return;
      }

      final response = await _proformaRepository.getProformas(
        sucursalId: sucursalIdStr,
        page: _currentPage,
        forceRefresh: true, // Forzar actualización desde el servidor
        useCache: false, // No usar caché
      );

      if (response.isNotEmpty) {
        final proformas = _proformaRepository.parseProformas(response);

        // Extraer información de paginación
        final Map<String, dynamic>? paginacionJson = response['pagination'];
        Paginacion? paginacionObj;

        // Crear un objeto Paginacion compatible con ProformaListWidget
        if (paginacionJson != null) {
          final total = paginacionJson['total'] as int? ?? 0;
          final int currentPage = paginacionJson['page'] as int? ?? 1;
          final int pageSize = paginacionJson['pageSize'] as int? ?? 10;
          final int totalPages = (total / pageSize).ceil();
          final bool hasNext = currentPage < totalPages;
          final bool hasPrev = currentPage > 1;

          // Crear objeto de paginación usando el modelo compartido
          paginacionObj = Paginacion(
            totalItems: total,
            totalPages: totalPages,
            currentPage: currentPage,
            hasNext: hasNext,
            hasPrev: hasPrev,
          );
        }

        _proformas = proformas;
        // Almacenar IDs para seguimiento de nuevas proformas
        _proformasIds = proformas.map((p) => p.id).toSet();
        _paginacion = paginacionObj;
        _isLoading = false;
        _hayNuevasProformas = false; // Resetear indicador al cargar manualmente

        // Si la proforma seleccionada ya no está en la lista, deseleccionarla
        if (_selectedProforma != null &&
            !_proformas.any((p) => p.id == _selectedProforma!.id)) {
          _selectedProforma = null;
        }

        // Usar microtask para evitar llamar a notifyListeners durante el build
        Future.microtask(notifyListeners);
      } else {
        if (!silencioso) {
          _errorMessage = 'No se pudo cargar las proformas';
          _isLoading = false;
          // Usar microtask para evitar llamar a notifyListeners durante el build
          Future.microtask(notifyListeners);
        }
      }
    } catch (e) {
      Logger.error('Error al cargar proformas: $e');
      if (!silencioso) {
        _errorMessage = 'Error: $e';
        _isLoading = false;
        // Usar microtask para evitar llamar a notifyListeners durante el build
        Future.microtask(notifyListeners);
      }
    }
  }

  /// Cambia la página actual y recarga las proformas
  void setPage(int page, {int? sucursalId}) {
    _currentPage = page;
    // Usar microtask para evitar llamar a notifyListeners durante el build
    Future.microtask(notifyListeners);
    loadProformas(sucursalId: sucursalId);
  }

  /// Selecciona una proforma
  void selectProforma(Proforma proforma) {
    _selectedProforma = proforma;
    // Usar microtask para evitar llamar a notifyListeners durante el build
    Future.microtask(notifyListeners);
  }

  /// Deselecciona la proforma actual
  void clearSelectedProforma() {
    _selectedProforma = null;
    // Usar microtask para evitar llamar a notifyListeners durante el build
    Future.microtask(notifyListeners);
  }

  /// Maneja la conversión de una proforma a venta sin necesidad de un BuildContext
  Future<bool> handleConvertToSale(Proforma proforma, int? sucursalId,
      {VoidCallback? onSuccess}) async {
    try {
      // Obtener el ID de sucursal
      String? sucursalIdStr = await _getSucursalId(sucursalId);
      if (sucursalIdStr == null) {
        Logger.error('No se pudo determinar la sucursal del usuario');
        return false;
      }

      // Limpiar cachés antes de la conversión
      _limpiarCaches(sucursalIdStr);

      // Usar el repositorio para convertir la proforma a venta
      final ventaResponse = await _proformaRepository.convertirAVenta(
        sucursalId: sucursalIdStr,
        proforma: proforma,
      );

      if (ventaResponse['status'] == 'success') {
        // Limpiar cachés después de la conversión exitosa
        _limpiarCaches(sucursalIdStr);

        // Intentar declarar la venta ante SUNAT si se creó correctamente
        final ventaDeclarada =
            await _declararVentaRecienCreada(ventaResponse, sucursalIdStr);

        // Si la venta fue declarada exitosamente, intentar imprimir
        if (ventaDeclarada) {
          await _imprimirVentaDeclarada(ventaResponse, sucursalIdStr);
        }

        // Recargar datos completos
        await _recargarDatosCompletos(sucursalIdStr, sucursalId);

        // Si la proforma convertida es la seleccionada, deseleccionarla siempre,
        // ya que ahora no existe más en el sistema
        if (_selectedProforma != null && _selectedProforma!.id == proforma.id) {
          clearSelectedProforma();
        }

        // Ejecutar callback de éxito si existe
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

  /// Declara una venta recién creada ante SUNAT
  Future<bool> _declararVentaRecienCreada(
      Map<String, dynamic> ventaResponse, String sucursalId) async {
    try {
      // Obtener el ID de la venta desde la respuesta
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

      // Llamar al endpoint de declaración
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

  /// Imprime la venta recién declarada según la configuración
  Future<void> _imprimirVentaDeclarada(
      Map<String, dynamic> ventaResponse, String sucursalId) async {
    try {
      // Obtener la venta completa con sus documentos
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

      // Obtener la URL del PDF según el formato configurado
      String? pdfUrl;
      if (_ventasProvider.imprimirFormatoTicket) {
        pdfUrl = ventaCompleta.documentoFacturacion!.linkPdfTicket;
        Logger.debug('🎫 Usando formato ticket para impresión');
      } else {
        pdfUrl = ventaCompleta.documentoFacturacion!.linkPdfA4;
        Logger.debug('Usando formato A4 para impresión');
      }

      if (pdfUrl == null) {
        Logger.error('No se encontró URL del PDF para imprimir');
        return;
      }

      Logger.debug('Configuración de impresión:');
      Logger.debug('- Formato A4: ${_ventasProvider.imprimirFormatoA4}');
      Logger.debug(
          '- Formato Ticket: ${_ventasProvider.imprimirFormatoTicket}');
      Logger.debug('- Impresión directa: ${_ventasProvider.impresionDirecta}');
      Logger.debug(
          '- Impresora seleccionada: ${_ventasProvider.impresoraSeleccionada}');

      // Usar el VentasComputerProvider para imprimir
      await _ventasProvider.imprimirDocumentoPdf(
        pdfUrl,
        '${ventaCompleta.serieDocumento}-${ventaCompleta.numeroDocumento}_${_ventasProvider.imprimirFormatoTicket ? "TICKET" : "A4"}',
      );

      Logger.debug('Documento enviado a imprimir automáticamente');
    } catch (e) {
      Logger.error('Error al imprimir venta declarada: $e');
    }
  }

  /// Limpia todos los cachés relevantes
  void _limpiarCaches(String sucursalId) {
    try {
      // Invalidar caché de proformas para la sucursal específica
      _proformaRepository
        ..invalidateCache(sucursalId)
        // Invalidar caché global de proformas
        ..invalidateCache();
      Logger.debug('Caché de proformas invalidado para sucursal $sucursalId');

      // Invalidar caché de ventas para la sucursal específica
      _ventaRepository
        ..invalidateCache(sucursalId)
        // Invalidar caché global de ventas
        ..invalidateCache();
      Logger.debug('Caché de ventas invalidado para sucursal $sucursalId');

      // Invalidar caché de sucursales
      _sucursalRepository.invalidateCache();
      Logger.debug('Caché de sucursales invalidado');
    } catch (e) {
      Logger.error('Error al limpiar cachés: $e');
    }
  }

  /// Recarga todos los datos necesarios después de convertir una proforma
  Future<void> _recargarDatosCompletos(
      String sucursalIdStr, int? sucursalId) async {
    try {
      // Recargar datos de la sucursal
      await _sucursalRepository.getSucursalData(sucursalIdStr,
          forceRefresh: true);
      Logger.debug('Datos de sucursal recargados: $sucursalIdStr');

      // Recargar proformas específicas para esta sucursal
      await loadProformas(sucursalId: sucursalId);
      Logger.debug('Lista de proformas recargada para sucursal $sucursalIdStr');

      // Recargar lista de ventas para mantener coherencia
      await _ventaRepository.getVentas(
        sucursalId: sucursalIdStr,
        useCache: false,
        forceRefresh: true,
      );
      Logger.debug('Lista de ventas recargada para sucursal $sucursalIdStr');
    } catch (e) {
      Logger.error('Error al recargar datos completos: $e');
      // Asegurarse de que al menos se recarguen las proformas
      await loadProformas(sucursalId: sucursalId);
    }
  }

  /// Elimina una proforma
  Future<bool> deleteProforma(Proforma proforma, int? sucursalId) async {
    try {
      // Obtener el ID de sucursal
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
        // Recargar proformas
        await loadProformas(sucursalId: sucursalId);

        // Si la proforma eliminada es la seleccionada, deseleccionarla
        if (_selectedProforma != null && _selectedProforma!.id == proforma.id) {
          clearSelectedProforma();
        }
      }

      return exito;
    } catch (e) {
      Logger.error('Error al eliminar proforma: $e');
      return false;
    }
  }

  /// Cambia el intervalo de actualización y reinicia el stream si está activo
  void setIntervaloActualizacion(int nuevoIntervalo, int? sucursalId) {
    if (!intervalosDisponibles.contains(nuevoIntervalo)) {
      return;
    }

    _intervaloActualizacion = nuevoIntervalo;

    // Si hay un timer activo, reiniciar el stream con el nuevo intervalo
    if (_actualizacionTimer != null) {
      _iniciarStreamProformas(sucursalId);
    }

    notifyListeners();
    Logger.info(
        'Intervalo de actualización cambiado a $_intervaloActualizacion segundos');
  }

  /// Inicia un stream para actualización de proformas en tiempo real
  void _iniciarStreamProformas(int? sucursalId) {
    // Cerrar stream existente si hay uno
    _cerrarStream();

    // Crear nuevo stream controller
    _proformasStreamController = StreamController<List<Proforma>>.broadcast();
    _proformasStream = _proformasStreamController?.stream;

    // Usar Timer en lugar de Stream.periodic para mejor control
    _actualizacionTimer = Timer.periodic(
      Duration(seconds: _intervaloActualizacion),
      (_) async {
        if (_proformasStreamController?.isClosed ?? true) {
          return;
        }
        final proformas = await _fetchProformasRealTime(sucursalId);
        _proformasStreamController?.add(proformas);
      },
    );

    // Suscribirse al stream para procesar nuevas proformas
    _proformasSubscription = _proformasStream?.listen((proformasActualizadas) {
      _procesarProformasActualizadas(proformasActualizadas, sucursalId);
    });

    Logger.info(
        'Stream de proformas iniciado (cada $_intervaloActualizacion segundos)');
  }

  /// Cierra el stream y las suscripciones actuales
  void _cerrarStream() {
    _actualizacionTimer?.cancel();
    _actualizacionTimer = null;
    _proformasSubscription?.cancel();
    _proformasSubscription = null;
    _proformasStreamController?.close();
    _proformasStreamController = null;
    _proformasStream = null;
    Logger.info('Stream de proformas cerrado completamente');
  }

  /// Pausa las actualizaciones en tiempo real
  void pausarActualizacionesEnTiempoReal() {
    _cerrarStream();
    Logger.info('Actualizaciones en tiempo real pausadas completamente');
  }

  /// Reanuda las actualizaciones en tiempo real
  void reanudarActualizacionesEnTiempoReal(int? sucursalId) {
    _iniciarStreamProformas(sucursalId);
    Logger.info('Actualizaciones en tiempo real reanudadas');
    // Cargar proformas inmediatamente
    loadProformas(sucursalId: sucursalId);
  }

  /// Obtiene proformas en tiempo real sin afectar el estado de carga de la UI
  Future<List<Proforma>> _fetchProformasRealTime(int? sucursalId) async {
    try {
      // Obtener el ID de sucursal
      String? sucursalIdStr = await _getSucursalId(sucursalId);
      if (sucursalIdStr == null) {
        return [];
      }

      // Obtener proformas sin modificar el estado de carga
      final response = await _proformaRepository.getProformas(
        sucursalId: sucursalIdStr,
        pageSize: 30, // Aumentar tamaño para tener más visibilidad
        forceRefresh: true, // Forzar actualización desde el servidor
        useCache: false, // No usar caché
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

  /// Procesa las proformas actualizadas para detectar nuevas
  void _procesarProformasActualizadas(
      List<Proforma> proformasActualizadas, int? sucursalId) {
    if (proformasActualizadas.isEmpty) {
      return;
    }

    // Verificar si hay nuevas proformas comparando con los IDs conocidos
    Set<int> nuevosIds = proformasActualizadas.map((p) => p.id).toSet();
    Set<int> proformasNuevas = nuevosIds.difference(_proformasIds);

    if (proformasNuevas.isNotEmpty) {
      Logger.info(
          '🔔 Se detectaron ${proformasNuevas.length} nuevas proformas en tiempo real!');

      // Mostrar notificación para cada nueva proforma
      for (var id in proformasNuevas) {
        final nuevaProforma =
            proformasActualizadas.firstWhere((p) => p.id == id);

        // Mostrar notificación en Windows
        _notificarNuevaProforma(nuevaProforma);
      }

      // Actualizar estado para mostrar indicador de nuevas proformas
      _hayNuevasProformas = true;

      // Actualizar lista completa de proformas silenciosamente y programar
      // la notificación de cambios para después del frame actual
      loadProformas(sucursalId: sucursalId, silencioso: true).then((_) {
        // Usar microtask para asegurarnos de que notifyListeners no se llama
        // durante la fase de build
        Future.microtask(notifyListeners);
      });
    }
  }

  /// Muestra notificación para una nueva proforma
  Future<void> _notificarNuevaProforma(Proforma proforma) async {
    try {
      // Verificar que la notificación esté habilitada
      if (proformaNotification.isEnabled) {
        await proformaNotification.notifyNewProformaPending(
          proforma,
          proforma.getNombreCliente(),
        );
        Logger.info(
            '🔔 Notificación enviada para nueva proforma #${proforma.id}');
      }
    } catch (e) {
      Logger.error('Error al enviar notificación: $e');
    }
  }

  /// Obtiene el ID de la sucursal (del parámetro o del usuario)
  Future<String?> _getSucursalId(int? sucursalIdParam) async {
    if (sucursalIdParam != null) {
      // Usar el sucursalId pasado como parámetro
      return sucursalIdParam.toString();
    } else {
      // Obtener el ID de sucursal del usuario a través del repositorio
      return _proformaRepository.getCurrentSucursalId();
    }
  }
}
