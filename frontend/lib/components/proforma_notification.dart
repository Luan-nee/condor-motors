import 'dart:io';

import 'package:condorsmotors/models/proforma.model.dart';
import 'package:condorsmotors/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:win_toast/win_toast.dart';

/// Clase que maneja las notificaciones para nuevas proformas
/// en Windows 10/11 usando win_toast.
class ProformaNotification {
  static final ProformaNotification _instance =
      ProformaNotification._internal();

  // Bandera para controlar si las notificaciones están habilitadas
  bool _notificationsEnabled = true;
  bool _isInitialized = false;

  // Control de limitación para evitar spam de notificaciones
  DateTime? _lastNotificationTime;
  final Set<int> _recentlyNotifiedProformaIds = {};
  final int _notificationThrottleSeconds =
      5; // Limitar frecuencia de notificaciones

  // Singleton pattern
  factory ProformaNotification() {
    return _instance;
  }

  ProformaNotification._internal();

  /// Verifica si la plataforma actual permite mostrar notificaciones de Windows.
  bool get _canShowWindowsNotifications => !kIsWeb && Platform.isWindows;

  /// Inicializa el sistema de notificaciones
  Future<void> init() async {
    if (_canShowWindowsNotifications) {
      try {
        // Inicializar la biblioteca de notificaciones de Windows
        final bool initialized = await WinToast.instance().initialize(
          aumId: 'com.condorsmotors.app',
          displayName: 'TiendaPeru',
          iconPath: '', // Dejar vacío por ahora
          clsid:
              '936C39FC-6BBC-4A57-B8F8-7C627E401B2F', // Debe coincidir con msix_config
        );

        _isInitialized = initialized;
        _notificationsEnabled = initialized;

        if (initialized) {
          Logger.info(
              'Sistema de notificaciones para proformas inicializado correctamente');
        } else {
          Logger.warn('No se pudo inicializar el sistema de notificaciones');
          _notificationsEnabled = false;
        }
      } catch (e) {
        Logger.error('Error al inicializar sistema de notificaciones: $e');
        _notificationsEnabled = false;
      }
    } else {
      _notificationsEnabled = false;
      Logger.debug(
          'Notificaciones de Windows no disponibles en esta plataforma');
    }
  }

  /// Verifica si las notificaciones están habilitadas y la plataforma lo permite
  bool get isEnabled =>
      _notificationsEnabled && _isInitialized && _canShowWindowsNotifications;

  /// Habilita o deshabilita las notificaciones
  void setNotificationsEnabled({required bool enabled}) {
    _notificationsEnabled = enabled;
    Logger.debug(
        'Notificaciones ${enabled ? 'habilitadas' : 'deshabilitadas'}');
  }

  /// Verifica si una proforma ya fue notificada recientemente para evitar duplicados
  bool _fueNotificadaRecientemente(int proformaId) {
    // Verificar si la proforma está en el conjunto de notificadas recientemente
    return _recentlyNotifiedProformaIds.contains(proformaId);
  }

  /// Registra una proforma como notificada recientemente
  void _registrarProformaNotificada(int proformaId) {
    // Actualizar el timestamp de la última notificación
    _lastNotificationTime = DateTime.now();

    // Añadir el ID a la lista de notificadas recientemente
    _recentlyNotifiedProformaIds.add(proformaId);

    // Limpiar IDs antiguos después de un tiempo (30 minutos)
    Future.delayed(const Duration(minutes: 30), () {
      _recentlyNotifiedProformaIds.remove(proformaId);
    });
  }

  /// Verifica si debemos limitar la frecuencia de notificaciones
  bool _deberiaLimitarNotificaciones() {
    if (_lastNotificationTime == null) {
      return false;
    }

    final ahora = DateTime.now();
    final diferencia = ahora.difference(_lastNotificationTime!).inSeconds;

    return diferencia < _notificationThrottleSeconds;
  }

  /// Verifica si se puede enviar una notificación para una proforma específica.
  /// Considera si ya fue notificada recientemente y si se debe limitar la frecuencia.
  bool _puedeNotificar(int proformaId, {bool aplicarLimitacion = true}) {
    if (_fueNotificadaRecientemente(proformaId)) {
      Logger.debug('Notificación duplicada omitida para proforma #$proformaId');
      return false;
    }
    if (aplicarLimitacion && _deberiaLimitarNotificaciones()) {
      Logger.debug(
          'Notificación limitada por frecuencia para proforma #$proformaId');
      return false;
    }
    return true;
  }

  /// Intenta mostrar una notificación de Windows y maneja errores comunes.
  Future<void> _attemptShowNotification({
    required Proforma proforma,
    required String title,
    required String body,
    required String tagPrefix,
    required String logMessage,
  }) async {
    try {
      await _showWindowsNotification(
        title: title,
        body: body,
        tag: '$tagPrefix${proforma.id}',
      );
      _registrarProformaNotificada(proforma.id);
      Logger.info('Notificación enviada: $logMessage #${proforma.id}');
    } catch (e) {
      Logger.error(
          'Error al mostrar notificación ($logMessage #${proforma.id}): $e');
    }
  }

  /// Notifica sobre una nueva proforma creada
  Future<void> notifyNewProforma(Proforma proforma) async {
    if (!isEnabled || !_puedeNotificar(proforma.id)) {
      return;
    }

    final String message =
        'Se ha creado la proforma #${proforma.id} por un valor de S/ ${proforma.total.toStringAsFixed(2)}';
    await _attemptShowNotification(
      proforma: proforma,
      title: 'Nueva Proforma Creada',
      body: message,
      tagPrefix: 'new_proforma_',
      logMessage: 'Nueva proforma',
    );
  }

  /// Notifica sobre una proforma convertida a venta
  Future<void> notifyProformaConverted(Proforma proforma) async {
    if (!isEnabled || !_puedeNotificar(proforma.id, aplicarLimitacion: false)) {
      return;
    }

    final String message =
        'La proforma #${proforma.id} ha sido convertida a venta';
    await _attemptShowNotification(
      proforma: proforma,
      title: 'Proforma Convertida',
      body: message,
      tagPrefix: 'converted_proforma_',
      logMessage: 'Proforma convertida',
    );
  }

  /// Notifica sobre una proforma pendiente de revisar (nueva) si el módulo computer está activo
  Future<void> notifyNewProformaPending(
      Proforma proforma, String clienteName) async {
    if (!isEnabled || !_puedeNotificar(proforma.id)) {
      return;
    }

    final String message = clienteName.isNotEmpty
        ? '¡NUEVA PROFORMA! Cliente: $clienteName - Monto: S/ ${proforma.total.toStringAsFixed(2)}'
        : '¡NUEVA PROFORMA PENDIENTE! Monto: S/ ${proforma.total.toStringAsFixed(2)}';
    await _attemptShowNotification(
      proforma: proforma,
      title: 'Nueva Proforma #${proforma.id}',
      body: message,
      tagPrefix: 'pending_proforma_',
      logMessage: 'Proforma pendiente',
    );
  }

  /// Limpia el historial de notificaciones recientes
  void limpiarHistorialNotificaciones() {
    _recentlyNotifiedProformaIds.clear();
    _lastNotificationTime = null;
    Logger.debug('Historial de notificaciones limpiado');
  }

  /// Muestra una notificación en Windows usando win_toast
  Future<void> _showWindowsNotification({
    required String title,
    required String body,
    required String tag,
  }) async {
    if (!_isInitialized) {
      Logger.warn('Intento de mostrar notificación sin inicializar.');
      return;
    }

    try {
      // Usar XML para definir la notificación con una prioridad mayor
      final String xmlContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<toast launch="action=viewProforma&amp;proformaId=$tag" scenario="urgent">
   <visual>
      <binding template="ToastGeneric">
         <text hint-style="title" hint-maxLines="1">$title</text>
         <text hint-style="body" hint-maxLines="2">$body</text>
         <text placement="attribution">TiendaPeru - Sistema de Proformas</text>
      </binding>
   </visual>
   <actions>
      <action content="Ver detalles" activationType="foreground" arguments="action=viewProforma&amp;proformaId=$tag" />
      <action content="Marcar como visto" activationType="background" arguments="action=markSeen&amp;proformaId=$tag" />
   </actions>
   <audio src="ms-winsoundevent:Notification.Default" loop="false" />
</toast>
      ''';

      // Mostrar notificación usando el método de XML personalizado
      await WinToast.instance().showCustomToast(xml: xmlContent);

      Logger.debug('Notificación Windows mostrada: $title');
    } catch (e) {
      Logger.error('Error interno mostrando notificación de Windows: $e');
      throw Exception('Error al mostrar la notificación de Windows: $e');
    }
  }
}
