// ignore_for_file: unused_element

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

// Definición de la clase ApiException
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException: $message (Status Code: $statusCode)';
}

class ApiService {
  final String baseUrl;
  final String apiKey;
  final String authToken;
  bool _initialized = false;
  bool _isOnline = false;
  final _logger = Logger('ApiService');

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal({
    this.baseUrl = 'https://zswmttrmawqmmilepwve.supabase.co/rest/v1',
    this.apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpzd210dHJtYXdxbW1pbGVwd3ZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDEwMDYyNzUsImV4cCI6MjA1NjU4MjI3NX0.9sFhepJDwEB59MRyFyGK8dMHH6Dvl9O4FZvExMqA5ok',
    this.authToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpzd210dHJtYXdxbW1pbGVwd3ZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDEwMDYyNzUsImV4cCI6MjA1NjU4MjI3NX0.9sFhepJDwEB59MRyFyGK8dMHH6Dvl9O4FZvExMqA5ok'
  });

  Map<String, String> get headers => {
    'apikey': apiKey,
    'Authorization': 'Bearer $authToken',
    'Content-Type': 'application/json',
    'Prefer': 'return=minimal'
  };

  bool get isOnline => _isOnline;

  Future<void> init() async {
    if (!_initialized) {
      _initialized = true;
    }
  }

  // Método para establecer el token
  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Método para limpiar el token
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // Verificar estado de la API según documentación
  Future<bool> checkApiStatus() async {
    try {
      _logger.info('Verificando estado de API en: $baseUrl/version');
      
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          _isOnline = true;
          return true;
        }
      }

      _isOnline = false;
      return false;
    } catch (e) {
      _isOnline = false;
      _logger.severe('Error al verificar API: $e');
      return false;
    }
  }

  // Método para reintento automático
  Future<T> withRetry<T>(Future<T> Function() operation, {int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts == maxRetries) rethrow;
        await Future.delayed(Duration(seconds: attempts));
        await checkApiStatus();
      }
    }
    throw ApiException(
      statusCode: 500,
      message: 'Error después de $maxRetries intentos',
    );
  }

  // Método base para peticiones HTTP
  Future<dynamic> request({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);

    try {
      late http.Response response;

      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: jsonEncode(body));
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: jsonEncode(body));
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw Exception('Método no soportado');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return null;
        return jsonDecode(response.body);
      }

      throw Exception('Error ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('Error en request: $e');
      rethrow;
    }
  }
}
