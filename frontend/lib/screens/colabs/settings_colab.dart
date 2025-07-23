import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsColabScreen extends StatefulWidget {
  const SettingsColabScreen({super.key});

  @override
  State<SettingsColabScreen> createState() => _SettingsColabScreenState();
}

class _SettingsColabScreenState extends State<SettingsColabScreen> {
  bool _notificacionesTransferencias = true;
  bool _loading = true;
  bool _yaPidioPermiso = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificacionesTransferencias =
          prefs.getBool('notificaciones_transferencias') ?? true;
      _yaPidioPermiso = prefs.getBool('notificaciones_permiso_pedido') ?? false;
      _loading = false;
    });
  }

  Future<void> _updateNotificaciones(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificaciones_transferencias', value);
    setState(() {
      _notificacionesTransferencias = value;
    });

    // Solicitar permiso en Android 13+ solo la primera vez que se activa
    if (value && Platform.isAndroid && !_yaPidioPermiso) {
      final plugin = FlutterLocalNotificationsPlugin();
      final androidImplementation =
          plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await androidImplementation?.requestNotificationsPermission();
      await prefs.setBool('notificaciones_permiso_pedido', true);
      setState(() {
        _yaPidioPermiso = true;
      });
      if (granted == false && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se concedió el permiso de notificaciones.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: const Color(0xFF2D2D2D),
      ),
      backgroundColor: const Color(0xFF1A1A1A),
      body: ListView(
        children: [
          SwitchListTile.adaptive(
            value: _notificacionesTransferencias,
            onChanged: _updateNotificaciones,
            title: const Text(
              'Notificaciones de transferencias',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Recibir notificaciones push cuando haya nuevos movimientos recibidos',
              style: TextStyle(color: Colors.white70),
            ),
            activeColor: const Color(0xFFE31E24),
            tileColor: const Color(0xFF2D2D2D),
          ),
        ],
      ),
    );
  }
}
