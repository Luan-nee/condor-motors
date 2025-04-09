import 'dart:async';

import 'package:condorsmotors/main.dart' show api, proformaNotification;
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/proforma.model.dart';
import 'package:condorsmotors/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider para gestionar el estado y lógica de negocio de las proformas
/// en la versión de computadora de la aplicación.
class ProformaComputerProvider extends ChangeNotifier {
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

  /// Carga las proformas desde la API
  Future<void> loadProformas({int? sucursalId, bool silencioso = false}) async {
    if (_isLoading && !silencioso) {
      return;
    }

    if (!silencioso) {
      _isLoading = true;
      _errorMessage = null;
      // Usar microtask para evitar llamar a notifyListeners durante el build
      Future.microtask(() {
        notifyListeners();
      });
    }

    try {
      // Obtener el ID de sucursal
      String? sucursalIdStr = await _getSucursalId(sucursalId);
      if (sucursalIdStr == null) {
        if (!silencioso) {
          _errorMessage = 'No se pudo determinar la sucursal del usuario';
          _isLoading = false;
          // Usar microtask para evitar llamar a notifyListeners durante el build
          Future.microtask(() {
            notifyListeners();
          });
        }
        return;
      }

      final response = await api.proformas.getProformasVenta(
        sucursalId: sucursalIdStr,
        page: _currentPage,
        forceRefresh: true, // Forzar actualización desde el servidor
        useCache: false, // No usar caché
      );

      if (response.isNotEmpty) {
        final proformas = api.proformas.parseProformasVenta(response);

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
        Future.microtask(() {
          notifyListeners();
        });
      } else {
        if (!silencioso) {
          _errorMessage = 'No se pudo cargar las proformas';
          _isLoading = false;
          // Usar microtask para evitar llamar a notifyListeners durante el build
          Future.microtask(() {
            notifyListeners();
          });
        }
      }
    } catch (e) {
      Logger.error('Error al cargar proformas: $e');
      if (!silencioso) {
        _errorMessage = 'Error: $e';
        _isLoading = false;
        // Usar microtask para evitar llamar a notifyListeners durante el build
        Future.microtask(() {
          notifyListeners();
        });
      }
    }
  }

  /// Cambia la página actual y recarga las proformas
  void setPage(int page, {int? sucursalId}) {
    _currentPage = page;
    // Usar microtask para evitar llamar a notifyListeners durante el build
    Future.microtask(() {
      notifyListeners();
    });
    loadProformas(sucursalId: sucursalId);
  }

  /// Selecciona una proforma
  void selectProforma(Proforma proforma) {
    _selectedProforma = proforma;
    // Usar microtask para evitar llamar a notifyListeners durante el build
    Future.microtask(() {
      notifyListeners();
    });
  }

  /// Deselecciona la proforma actual
  void clearSelectedProforma() {
    _selectedProforma = null;
    // Usar microtask para evitar llamar a notifyListeners durante el build
    Future.microtask(() {
      notifyListeners();
    });
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

      // Invalidar caché antes de la conversión
      api.proformas.invalidateCache(sucursalIdStr);

      // Obtener un ID de tipo de documento para BOLETA de manera independiente
      int tipoDocumentoId =
          await api.documentos.getTipoDocumentoId(sucursalIdStr, 'BOLETA');
      Logger.debug('ID para BOLETA: $tipoDocumentoId');

      // Obtener ID del tipoTax para gravado (18% IGV)
      int tipoTaxId = await api.documentos.getGravadoTaxId(sucursalIdStr);
      Logger.debug('ID para tipo Tax Gravado: $tipoTaxId');

      // Obtener detalles de la proforma
      final proformaResponse = await api.proformas.getProformaVenta(
        sucursalId: sucursalIdStr,
        proformaId: proforma.id,
        forceRefresh: true, // Forzar actualización desde el servidor
      );

      if (proformaResponse.isEmpty ||
          !proformaResponse.containsKey('data') ||
          proformaResponse['data'] == null) {
        Logger.error('No se pudo obtener información de la proforma');
        return false;
      }

      final proformaData = proformaResponse['data'];
      final List<dynamic> detalles = proformaData['detalles'] ?? [];

      if (detalles.isEmpty) {
        Logger.error(
            'La proforma no tiene productos, no se puede convertir a venta');
        return false;
      }

      // Transformar los detalles para la venta
      final List<Map<String, dynamic>> detallesVenta = [];
      for (final dynamic detalle in detalles) {
        if (detalle == null || !detalle.containsKey('productoId')) {
          continue;
        }

        detallesVenta.add({
          'productoId': detalle['productoId'],
          'cantidad':
              detalle['cantidadPagada'] ?? detalle['cantidadTotal'] ?? 1,
          'tipoTaxId': tipoTaxId,
          'aplicarOferta':
              detalle['descuento'] != null && detalle['descuento'] > 0
        });
      }

      if (detallesVenta.isEmpty) {
        Logger.error('No hay productos válidos para convertir');
        return false;
      }

      // Obtener cliente (intentar usar el de la proforma o uno predeterminado)
      int clienteId = 1; // Cliente por defecto
      if (proformaData.containsKey('clienteId') &&
          proformaData['clienteId'] != null) {
        clienteId =
            int.tryParse(proformaData['clienteId'].toString()) ?? clienteId;
      } else if (proformaData.containsKey('cliente') &&
          proformaData['cliente'] is Map &&
          proformaData['cliente'].containsKey('id')) {
        clienteId =
            int.tryParse(proformaData['cliente']['id'].toString()) ?? clienteId;
      }

      // Obtener empleadoId
      int? empleadoId;
      final userData = await api.authService.getUserData();
      if (userData != null && userData.containsKey('empleadoId')) {
        empleadoId = int.tryParse(userData['empleadoId'].toString());
      }

      if (empleadoId == null) {
        // Buscar un empleado de la sucursal
        final empleados =
            await api.empleados.getEmpleadosPorSucursal(sucursalIdStr);
        if (empleados.isNotEmpty) {
          empleadoId = int.tryParse(empleados.first.id);
        }
      }

      if (empleadoId == null) {
        Logger.error('No se pudo obtener un ID de empleado válido');
        return false;
      }

      // Crear los datos para la venta
      final Map<String, dynamic> ventaData = {
        'observaciones': 'Convertida desde Proforma #${proforma.id}',
        'tipoDocumentoId': tipoDocumentoId,
        'detalles': detallesVenta,
        'clienteId': clienteId,
        'empleadoId': empleadoId,
      };

      // Crear la venta
      final ventaResponse = await api.ventas.createVenta(
        ventaData,
        sucursalId: sucursalIdStr,
      );

      if (ventaResponse['status'] != 'success') {
        Logger.error(
            'Error al crear venta: ${ventaResponse['error'] ?? ventaResponse['message'] ?? "Error desconocido"}');
        return false;
      }

      // Actualizar el estado de la proforma
      await api.proformas.updateProformaVenta(
        sucursalId: sucursalIdStr,
        proformaId: proforma.id,
        estado: 'convertida',
      );

      // Recargar proformas para actualizar la lista
      await loadProformas(sucursalId: sucursalId);

      // Si la proforma convertida es la seleccionada, deseleccionarla
      if (_selectedProforma != null && _selectedProforma!.id == proforma.id) {
        clearSelectedProforma();
      }

      // Ejecutar callback de éxito si existe
      if (onSuccess != null) {
        onSuccess();
      }

      return true;
    } catch (e) {
      Logger.error('Error al convertir proforma a venta: $e');
      return false;
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

      final response = await api.proformas.deleteProformaVenta(
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
        '⏱️ Intervalo de actualización cambiado a $_intervaloActualizacion segundos');
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
        '🔄 Stream de proformas iniciado (cada $_intervaloActualizacion segundos)');
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
    Logger.info('🔄 Stream de proformas cerrado completamente');
  }

  /// Pausa las actualizaciones en tiempo real
  void pausarActualizacionesEnTiempoReal() {
    _cerrarStream();
    Logger.info('🔄 Actualizaciones en tiempo real pausadas completamente');
  }

  /// Reanuda las actualizaciones en tiempo real
  void reanudarActualizacionesEnTiempoReal(int? sucursalId) {
    _iniciarStreamProformas(sucursalId);
    Logger.info('🔄 Actualizaciones en tiempo real reanudadas');
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
      final response = await api.proformas.getProformasVenta(
        sucursalId: sucursalIdStr,
        pageSize: 30, // Aumentar tamaño para tener más visibilidad
        forceRefresh: true, // Forzar actualización desde el servidor
        useCache: false, // No usar caché
      );

      if (response.isNotEmpty) {
        return api.proformas.parseProformasVenta(response);
      }
      return [];
    } catch (e) {
      Logger.error('❌ Error al obtener proformas en tiempo real: $e');
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
        Future.microtask(() {
          notifyListeners();
        });
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
      Logger.error('❌ Error al enviar notificación: $e');
    }
  }

  /// Obtiene el ID de la sucursal (del parámetro o del usuario)
  Future<String?> _getSucursalId(int? sucursalIdParam) async {
    if (sucursalIdParam != null) {
      // Usar el sucursalId pasado como parámetro
      return sucursalIdParam.toString();
    } else {
      // Obtener el ID de sucursal del usuario
      final userData = await api.authService.getUserData();
      if (userData == null || !userData.containsKey('sucursalId')) {
        Logger.error('No se pudo determinar la sucursal del usuario');
        return null;
      }
      return userData['sucursalId'].toString();
    }
  }
}
