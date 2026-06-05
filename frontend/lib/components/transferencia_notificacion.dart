import 'dart:convert';
import 'dart:io';

import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Servicio de notificaciones para transferencias de inventario.
///
/// Patron: Facade sobre [FlutterLocalNotificationsPlugin].
/// En Windows, las notificaciones toast se delegan al paquete win_toast via
/// la inicializacion del plugin con [WindowsInitializationSettings].
///
/// Complejidad: O(1) por llamada — operaciones de I/O asincronas sin iteracion.
class TransferenciaNotificacion {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initTransferenciaNotifications({
    required void Function(Map<String, dynamic>? payload) onSelect,
  }) async {
    if (_initialized) {
      return;
    }

    // En Windows usamos WindowsInitializationSettings con el GUID del toast activator.
    // En Android usamos AndroidInitializationSettings con el icono de notificacion.
    InitializationSettings initSettings;

    if (Platform.isWindows) {
      const WindowsInitializationSettings windowsInit =
          WindowsInitializationSettings(
        appName: 'CondorMotors',
        appUserModelId: 'condor_motors_app',
        guid: '936C39FC-6BBC-4A57-B8F8-7C627E401B2F',
      );
      initSettings = const InitializationSettings(windows: windowsInit);
    } else if (Platform.isAndroid) {
      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('ic_stat_notify');
      const DarwinInitializationSettings iosInit =
          DarwinInitializationSettings();
      initSettings = const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
    } else {
      const DarwinInitializationSettings iosInit =
          DarwinInitializationSettings();
      initSettings = const InitializationSettings(iOS: iosInit);
    }

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        final payload =
            details.payload != null ? jsonDecode(details.payload!) : null;
        onSelect(payload);
      },
    );
    _initialized = true;
  }

  static Future<void> showTransferenciaNotification({
    required String title,
    required String body,
    required int id,
    String? payload,
  }) async {
    NotificationDetails details;

    if (Platform.isWindows) {
      // Windows: sin NotificationDetails adicionales — el plugin usa XML toast interno.
      const WindowsNotificationDetails windowsDetails =
          WindowsNotificationDetails();
      details = const NotificationDetails(windows: windowsDetails);
    } else {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'transferencias_channel',
        'Transferencias',
        channelDescription: 'Notificaciones de nuevas transferencias',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_stat_notify',
      );
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
      details = const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
    }

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Notificacion para transferencia en estado 'pedido'
  static Future<void> showTransferenciaPedido(TransferenciaInventario t,
      {String? sucursalSolicitante}) async {
    final cantidadProductos = t.productos?.length ?? 0;
    final String sucursal = t.nombreSucursalDestino;
    final payload = jsonEncode({
      'id': t.id,
      'tipo': 'pedido',
      'sucursalSolicitante': sucursal,
      'productos': cantidadProductos,
    });
    final body = cantidadProductos > 0
        ? '$sucursal solicita $cantidadProductos producto${cantidadProductos == 1 ? '' : 's'} para transferencia.'
        : '$sucursal solicita productos para transferencia.';
    await showTransferenciaNotification(
      title: 'Nueva solicitud de transferencia',
      body: body,
      id: t.id,
      payload: payload,
    );
  }

  /// Notificacion para transferencia en estado 'enviado' a la sucursal actual
  static Future<void> showTransferenciaEnviada(TransferenciaInventario t,
      {String? sucursalSolicitante}) async {
    final cantidadProductos = t.productos?.length ?? 0;
    final String sucursal = t.nombreSucursalOrigen ?? 'Sucursal desconocida';
    final payload = jsonEncode({
      'id': t.id,
      'tipo': 'enviado',
      'sucursalSolicitante': sucursal,
      'productos': cantidadProductos,
    });
    final body = cantidadProductos > 0
        ? '$sucursal ha enviado $cantidadProductos producto${cantidadProductos == 1 ? '' : 's'} a tu sucursal.'
        : '$sucursal ha enviado productos a tu sucursal.';
    await showTransferenciaNotification(
      title: 'Transferencia en camino',
      body: body,
      id: t.id,
      payload: payload,
    );
  }
}
