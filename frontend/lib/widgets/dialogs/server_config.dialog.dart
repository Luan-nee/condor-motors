import 'package:condorsmotors/api/index.api.dart'
    show updateBaseUrl, serverConfigs;
import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';

class ServerConfigDialog extends StatefulWidget {
  final String currentServerIp;

  const ServerConfigDialog({
    super.key,
    required this.currentServerIp,
  });

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _ipController;
  late final TextEditingController _portController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.currentServerIp);
    _portController = TextEditingController(text: '3000');
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(String ip, {int? port}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await updateBaseUrl(ip, port: port);
      
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Servidor actualizado a: $ip${port != null ? ':$port' : ''}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // El reinicio de la app recargará todo el árbol de widgets y restablecerá la conexión de red
      Restart.restartApp();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el servidor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configuración del Servidor'),
      content: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Seleccione un servidor predefinido:',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  ...serverConfigs.map(
                    (Map<String, dynamic> config) => ListTile(
                      title: Text(
                        config['port'] != null
                            ? '${config['url']}:${config['port']}'
                            : config['url'] as String,
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _handleSave(
                          config['url'] as String,
                          port: config['port'] as int?,
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Text(
                    'O ingrese una dirección personalizada:',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 7,
                        child: TextFormField(
                          controller: _ipController,
                          decoration: InputDecoration(
                            labelText: 'Dirección del Servidor',
                            hintText: 'Ej: localhost o 192.168.1.66',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.text,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _portController,
                          decoration: InputDecoration(
                            labelText: 'Puerto',
                            hintText: '3000',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Para desarrollo local (PC): localhost o 127.0.0.1\n'
                    '• Para emuladores Android: 10.0.2.2\n'
                    '• Para dispositivos físicos: IP de tu PC en la red WiFi\n'
                    '• Puerto por defecto: 3000\n'
                    '• Para dominios HTTPS no es necesario el puerto',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
      actions: _isLoading
          ? null
          : <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final String newIp = _ipController.text.trim();
                  final String portText = _portController.text.trim();

                  if (newIp.isNotEmpty) {
                    Navigator.pop(context);
                    int? port;
                    if (portText.isNotEmpty && !newIp.startsWith('https://')) {
                      port = int.tryParse(portText);
                    }
                    _handleSave(newIp, port: port);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
    );
  }
}
