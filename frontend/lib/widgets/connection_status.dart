import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Widget que muestra el estado de la conexión al servidor
/// y permite reintentar la conexión automáticamente
class ConnectionStatusWidget extends StatefulWidget {
  final Widget child;
  
  const ConnectionStatusWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> {
  bool _isConnected = true;
  bool _isRetrying = false;
  String _errorMessage = '';
  Timer? _retryTimer;
  int _retryCount = 0;
  final int _maxRetries = 5;
  
  @override
  void initState() {
    super.initState();
    _checkConnection();
  }
  
  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }
  
  /// Verifica la conexión al servidor
  Future<void> _checkConnection() async {
    try {
      // Obtener la URL del servidor desde preferencias
      final prefs = await SharedPreferences.getInstance();
      String serverUrl = prefs.getString('server_url') ?? 'http://localhost:3000';
      
      // Hacer un ping simple al servidor
      final response = await http.get(
        Uri.parse(serverUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      // Considerar conectado si obtenemos cualquier respuesta
      final bool isConnected = response.statusCode > 0;
      
      if (!_isConnected && isConnected && mounted) {
        setState(() {
          _isConnected = true;
          _isRetrying = false;
          _retryCount = 0;
          _errorMessage = '';
        });
      } else if (_isConnected && !isConnected && mounted) {
        setState(() {
          _isConnected = false;
          _errorMessage = 'El servidor respondió con código ${response.statusCode}';
          
          // Si no estamos ya reintentando, iniciar el temporizador de reintento
          if (!_isRetrying) {
            _startRetryTimer();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _errorMessage = e.toString();
          
          // Si no estamos ya reintentando, iniciar el temporizador de reintento
          if (!_isRetrying) {
            _startRetryTimer();
          }
        });
      }
    }
  }
  
  /// Inicia un temporizador para reintentar la conexión
  void _startRetryTimer() {
    setState(() {
      _isRetrying = true;
    });
    
    // Cancelar el temporizador anterior si existe
    _retryTimer?.cancel();
    
    // Crear un nuevo temporizador para reintentar cada 5 segundos
    _retryTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _retryCount++;
      _checkConnection();
      
      // Si superamos el número máximo de reintentos, detener el temporizador
      if (_retryCount >= _maxRetries) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isRetrying = false;
          });
        }
      }
    });
  }
  
  /// Maneja el reintento manual
  void _handleManualRetry() {
    setState(() {
      _isRetrying = true;
      _retryCount = 0;
    });
    
    _checkConnection();
  }
  
  @override
  Widget build(BuildContext context) {
    // Usar Directionality para resolver el problema de dirección de texto
    return Directionality(
      // Dirección de texto de izquierda a derecha
      textDirection: TextDirection.ltr,
      child: Stack(
        // Especificar alineación explícita para evitar problemas con Directionality
        alignment: Alignment.center,
        children: [
          widget.child,
          if (!_isConnected)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  color: Colors.red.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Problema de conexión con el servidor. ${_isRetrying ? "Reintentando..." : ""}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!_isRetrying)
                        TextButton.icon(
                          onPressed: _handleManualRetry,
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text(
                            'Reintentar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      if (_isRetrying)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 