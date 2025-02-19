import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../services/storage_service.dart';
import '../models/movement.dart';
import 'package:flutter/material.dart';

class ApiService {
  // URL base según la documentación
  static const String baseUrl = 'http://localhost:8000';
  late StorageService _storage;
  bool _initialized = false;
  bool _isOnline = false;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  bool get isOnline => _isOnline;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      _storage = await StorageService.init();
      _initialized = true;
    }
  }

  // Verificar estado de la API según documentación
  Future<bool> checkApiStatus() async {
    try {
      debugPrint('Verificando estado de API en: $baseUrl/health');
      
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5)); // Timeout recomendado

      debugPrint('Respuesta del servidor: ${response.statusCode}');
      debugPrint('Cuerpo de respuesta: ${response.body}');

      // Verificar respuesta según documentación
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Validar estructura de respuesta según documentación
        if (data['status'] == 'ok' && 
            data['version'] != null && 
            data['database'] == 'connected') {
          _isOnline = true;
          debugPrint('API Status: Online (v${data['version']})');
          return true;
        }
      }

      // Error 503 según documentación
      if (response.statusCode == 503) {
        final error = jsonDecode(response.body);
        debugPrint('API Error: ${error['detail']}');
        throw Exception(error['detail']);
      }

      _isOnline = false;
      return false;
    } catch (e) {
      _isOnline = false;
      debugPrint('Error al verificar API: $e');
      return false;
    }
  }

  // Método base para peticiones HTTP con retry
  Future<dynamic> request({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    required Map<String, String> queryParams,
  }) async {
    try {
      // Verificar estado de la API antes de cada petición
      if (!await checkApiStatus()) {
        throw Exception('No se puede conectar al servidor. Por favor, inténtelo más tarde.');
      }

      final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
      debugPrint('Realizando petición $method a: $uri');
      
      final defaultHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final finalHeaders = {...defaultHeaders, ...?headers};

      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: finalHeaders)
              .timeout(const Duration(seconds: 10));
          break;
        case 'POST':
          response = await http.post(
            uri, 
            headers: finalHeaders,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(const Duration(seconds: 10));
          break;
        case 'PUT':
          response = await http.put(
            uri, 
            headers: finalHeaders,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(const Duration(seconds: 10));
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: finalHeaders)
              .timeout(const Duration(seconds: 10));
          break;
        default:
          throw Exception('Método no soportado: $method');
      }

      // Verificar si recibimos HTML en lugar de JSON
      if (response.body.contains('<!DOCTYPE')) {
        throw Exception('El servidor no está respondiendo correctamente');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return null;
        return jsonDecode(response.body);
      }

      // Manejar errores según la documentación
      try {
        final error = jsonDecode(response.body);
        throw ApiException(
          statusCode: response.statusCode,
          message: error['detail'] ?? 'Error desconocido',
        );
      } catch (e) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Error de conexión: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      debugPrint('Error en request: $e');
      if (e is ApiException) rethrow;
      throw Exception('Error de conexión: $e');
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
    throw Exception('Error después de $maxRetries intentos');
  }

  // Obtener información del vendedor
  Future<Map<String, dynamic>> getVendorInfo() async {
    try {
      // TODO: Implementar llamada real a la API
      // Simulación de respuesta
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'id': 1,
        'name': 'Juan Pérez',
        'role': 'vendedor',
        'code': 'V001'
      };
    } catch (e) {
      throw Exception('Error al obtener información del vendedor');
    }
  }

  // Enviar productos a la computadora principal
  Future<void> sendProductsToComputer(List<Product> products) async {
    try {
      // TODO: Implementar llamada real a la API
      // Simulación de envío
      await Future.delayed(const Duration(seconds: 1));
      
      // Aquí iría el código real para enviar los productos
      final data = {
        'products': products.map((p) => {
          'id': p.id,
          'name': p.name,
          'codigo': p.codigo,
          'price': p.price,
          'stock': p.stock,
          'description': p.description,
          'category': p.category,
          'marca': p.marca,
        }).toList(),
        'timestamp': DateTime.now().toIso8601String(),
        'vendorId': 'V001',
      };

      // Ejemplo de cómo sería la llamada real a la API
      /*
      final response = await http.post(
        Uri.parse('$baseUrl/send-products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al enviar productos');
      }
      */

    } catch (e) {
      throw Exception('Error al enviar productos a la computadora: $e');
    }
  }

  // Obtener productos
  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/productos?saltar=0&limite=100'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Error al obtener productos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener productos: $e');
    }
  }

  // Login con la API
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'nombre_usuario': username,
          'contrasena': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'id': data['id'],
          'nombre_usuario': data['nombre_usuario'],
          'nombre_completo': data['nombre_completo'],
          'rol': data['rol'],
          'lugar': data['lugar'],
          'fecha_pago': data['fecha_pago'],
          'fecha_creacion': data['fecha_creacion'],
          'activo': data['activo'],
        };
      } else if (response.statusCode == 401) {
        throw Exception('Credenciales inválidas');
      } else {
        throw Exception('Error en el servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al intentar iniciar sesión: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getVentas() async {
    try {
      // TODO: Implementar llamada real a la API
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        {
          'id': 1,
          'fecha': '2024-02-20',
          'total': 1500.00,
          'ganancia': 300.00,
          'productos': [
            {
              'id': 1,
              'cantidad': 2,
              'precio': 750.00,
              'ganancia': 150.00,
            }
          ],
        },
        // Más ventas de ejemplo...
      ];
    } catch (e) {
      throw Exception('Error al obtener ventas');
    }
  }

  // Crear producto
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> product) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/productos'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'nombre': product['nombre'],
          'codigo': product['codigo'],
          'precio': product['precio'],
          'precio_compra': product['precio_compra'],
          'existencias': product['existencias'],
          'descripcion': product['descripcion'],
          'categoria': product['categoria'],
          'marca': product['marca'],
          'local_id': product['local_id'],
          'es_liquidacion': product['es_liquidacion'],
          'reglas_descuento': product['reglas_descuento'],
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al crear producto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al crear producto: $e');
    }
  }

  // Obtener movimientos
  Future<List<Movement>> getMovements() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/movimientos?saltar=0&limite=100'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Movement.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener movimientos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener movimientos: $e');
    }
  }

  // Crear movimiento
  Future<Movement> createMovement(Movement movement) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/movimientos'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'producto_id': movement.productoId,
          'cantidad': movement.cantidad,
          'fecha_movimiento': movement.fechaMovimiento.toIso8601String(),
          'sucursal_origen': movement.sucursalOrigen,
          'sucursal_destino': movement.sucursalDestino,
          'estado': movement.estado,
        }),
      );

      if (response.statusCode == 200) {
        return Movement.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al crear movimiento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al crear movimiento: $e');
    }
  }

  // Actualizar estado de movimiento
  Future<void> updateMovementStatus(int movementId, String newStatus) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/movimientos/$movementId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'estado': newStatus}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar estado: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al actualizar estado: $e');
    }
  }

  // Guardar producto
  Future<void> saveProduct(Product product) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/productos'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'nombre': product.nombre,
          'descripcion': product.descripcion,
          'precio': product.precio,
          'precio_compra': product.precioCompra,
          'existencias': product.existencias,
          'categoria': product.categoria,
          'marca': product.marca,
          'codigo': product.codigo,
          'local_id': product.localId,
          'es_liquidacion': product.esLiquidacion,
          'reglas_descuento': product.reglasDescuento.map((r) => r.toJson()).toList(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al guardar el producto: ${response.statusCode}');
      }

      // Actualizar almacenamiento local
      await _ensureInitialized();
      if (product.id == 0) {
        final lastId = await _storage.getLastProductId();
        final newProduct = Product(
          id: lastId + 1,
          nombre: product.nombre,
          codigo: product.codigo,
          precio: product.precio,
          precioCompra: product.precioCompra,
          existencias: product.existencias,
          descripcion: product.descripcion,
          categoria: product.categoria,
          marca: product.marca,
          esLiquidacion: product.esLiquidacion,
          localId: product.localId,
          reglasDescuento: product.reglasDescuento,
          fechaCreacion: DateTime.now(),
          fechaActualizacion: DateTime.now(),
        );
        await _storage.addProduct(newProduct);
      } else {
        await _storage.updateProduct(product);
      }
    } catch (e) {
      throw Exception('Error al guardar el producto: $e');
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
} 