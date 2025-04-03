import 'dart:async';

import 'package:condorsmotors/main.dart' show api, proformaNotification;
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/proforma.model.dart';
import 'package:condorsmotors/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Provider para gestionar el estado y lógica de negocio de las proformas
/// en la versión de computadora de la aplicación.
class ProformaComputerProvider extends ChangeNotifier {
  List<Proforma> _proformas = [];
  Set<int> _proformasIds = {}; // Para seguimiento de nuevas proformas
  Proforma? _selectedProforma;
  bool _isLoading = false;
  String? _errorMessage;
  Paginacion? _paginacion;
  int _currentPage = 1;

  // Para actualización automática
  Timer? _actualizacionTimer;
  final int _intervaloActualizacion = 10; // Segundos
  bool _hayNuevasProformas = false;

  // Getters
  List<Proforma> get proformas => _proformas;
  Proforma? get selectedProforma => _selectedProforma;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Paginacion? get paginacion => _paginacion;
  int get currentPage => _currentPage;
  int get intervaloActualizacion => _intervaloActualizacion;
  bool get hayNuevasProformas => _hayNuevasProformas;

  /// Inicializa el provider con la configuración necesaria
  Future<void> initialize(int? sucursalId) async {
    // Cargar proformas iniciales
    await loadProformas(sucursalId: sucursalId);

    // Iniciar timer para actualización automática
    _iniciarActualizacionPeriodica(sucursalId);
  }

  /// Inicia un timer para actualizar las proformas periódicamente
  void _iniciarActualizacionPeriodica(int? sucursalId) {
    // Cancelar timer existente si hay uno
    _actualizacionTimer?.cancel();

    // Crear nuevo timer para actualizar cada _intervaloActualizacion segundos
    _actualizacionTimer = Timer.periodic(
        Duration(seconds: _intervaloActualizacion),
        (_) => _verificarNuevasProformas(sucursalId));

    Logger.info(
        '🔄 Timer de actualización de proformas iniciado (cada $_intervaloActualizacion segundos)');
  }

  @override
  void dispose() {
    // Cancelar el timer al destruir el provider
    _actualizacionTimer?.cancel();
    super.dispose();
  }

  /// Verifica si hay nuevas proformas sin interferir con la UI
  Future<void> _verificarNuevasProformas(int? sucursalId) async {
    Logger.debug('🔍 Verificando nuevas proformas...');
    try {
      // Obtener el ID de sucursal
      String? sucursalIdStr = await _getSucursalId(sucursalId);
      if (sucursalIdStr == null) {
        return;
      }

      // Obtener proformas sin modificar el estado de carga
      final response = await api.proformas.getProformasVenta(
        sucursalId: sucursalIdStr,
        pageSize: 20, // Aumentar tamaño para tener más visibilidad
        forceRefresh: true, // Forzar actualización desde el servidor
        useCache: false, // No usar caché
      );

      if (response.isNotEmpty) {
        final nuevasProformas = api.proformas.parseProformasVenta(response);

        // Verificar si hay nuevas proformas comparando con los IDs conocidos
        Set<int> nuevosIds = nuevasProformas.map((p) => p.id).toSet();
        Set<int> proformasNuevas = nuevosIds.difference(_proformasIds);

        if (proformasNuevas.isNotEmpty) {
          Logger.info(
              '🔔 Se encontraron ${proformasNuevas.length} nuevas proformas!');

          // Notificar por cada nueva proforma encontrada
          for (var id in proformasNuevas) {
            final nuevaProforma = nuevasProformas.firstWhere((p) => p.id == id);

            // Mostrar notificación en Windows
            await proformaNotification.notifyNewProformaPending(
              nuevaProforma,
              nuevaProforma.getNombreCliente(),
            );

            // Actualizar estado para mostrar indicador de nuevas proformas
            _hayNuevasProformas = true;
            notifyListeners();
          }

          // Actualizar lista completa de proformas silenciosamente
          await loadProformas(sucursalId: sucursalId, silencioso: true);
        } else {
          Logger.debug('✓ No se encontraron nuevas proformas');
        }
      }
    } catch (e) {
      Logger.error('❌ Error al verificar nuevas proformas: $e');
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

  /// Carga las proformas desde la API
  Future<void> loadProformas({int? sucursalId, bool silencioso = false}) async {
    if (_isLoading && !silencioso) {
      return;
    }

    if (!silencioso) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      // Obtener el ID de sucursal
      String? sucursalIdStr = await _getSucursalId(sucursalId);
      if (sucursalIdStr == null) {
        if (!silencioso) {
          _errorMessage = 'No se pudo determinar la sucursal del usuario';
          _isLoading = false;
          notifyListeners();
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

        notifyListeners();
      } else {
        if (!silencioso) {
          _errorMessage = 'No se pudo cargar las proformas';
          _isLoading = false;
          notifyListeners();
        }
      }
    } catch (e) {
      Logger.error('Error al cargar proformas: $e');
      if (!silencioso) {
        _errorMessage = 'Error: $e';
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Cambia la página actual y recarga las proformas
  void setPage(int page, {int? sucursalId}) {
    _currentPage = page;
    notifyListeners();
    loadProformas(sucursalId: sucursalId);
  }

  /// Selecciona una proforma
  void selectProforma(Proforma proforma) {
    _selectedProforma = proforma;
    notifyListeners();
  }

  /// Deselecciona la proforma actual
  void clearSelectedProforma() {
    _selectedProforma = null;
    notifyListeners();
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
}
