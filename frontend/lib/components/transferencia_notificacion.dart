import 'dart:convert';

import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('ic_stat_notify');
    final DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    final InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _notificationsPlugin.initialize(
      initSettings,
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
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Notificación para transferencia en estado 'pedido'
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

  /// Notificación para transferencia en estado 'enviado' a la sucursal actual
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
