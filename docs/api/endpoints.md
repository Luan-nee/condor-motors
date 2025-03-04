# 🚀 Endpoints API Condors Motos

## URL Base
```
http://localhost:8000
```

## Configuración en Flutter/Dart

### 1. Dependencias Necesarias
Agregar en `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.0
  shared_preferences: ^2.2.2  # Para almacenar el token
  dio: ^5.4.0  # Opcional, para manejo avanzado de requests
```

### 2. Configuración Base
```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:8000';
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) {
    return {
      ...headers,
      'Authorization': 'Bearer $token',
    };
  }
}
```

## Estructura de Endpoints

### 1. Autenticación y Usuarios
- [Documentación Completa de Usuarios](/docs/api/usuarios.md)
```http
POST   /api/usuarios/login     # Iniciar sesión
GET    /api/usuarios          # Listar usuarios
POST   /api/usuarios          # Crear usuario
GET    /api/usuarios/{id}     # Obtener usuario
PUT    /api/usuarios/{id}     # Actualizar usuario
```

### 2. Productos
- [Documentación Completa de Productos](/docs/api/productos.md)
```http
GET    /api/productos         # Listar productos
POST   /api/productos         # Crear producto
GET    /api/productos/{id}    # Obtener producto
PUT    /api/productos/{id}    # Actualizar producto
DELETE /api/productos/{id}    # Eliminar producto
```

### 3. Stock
- [Documentación Completa de Stock](/docs/api/stock.md)
```http
GET    /api/stocks                           # Listar stocks
GET    /api/stocks/{local_id}/{producto_id}  # Obtener stock específico
POST   /api/stocks                           # Crear/Actualizar stock
PUT    /api/stocks/{local_id}/{producto_id}  # Ajustar stock
```

### 4. Movimientos
- [Documentación Completa de Movimientos](/docs/api/movimientos.md)
```http
GET    /api/movimientos              # Listar movimientos
POST   /api/movimientos              # Crear movimiento
GET    /api/movimientos/{id}         # Obtener movimiento
PUT    /api/movimientos/{id}/aprobar # Aprobar movimiento
```

### 5. Ventas
- [Documentación Completa de Ventas](/docs/api/ventas.md)
```http
GET    /api/ventas          # Listar ventas
POST   /api/ventas          # Crear venta
GET    /api/ventas/{id}     # Obtener venta
PUT    /api/ventas/{id}     # Actualizar venta
```

## Estado del Sistema
```http
GET    /api/health          # Verificar estado del sistema
```

## Ejemplo de Uso en Flutter/Dart

### Servicio Base
```dart
// lib/services/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class ApiService {
  final String baseUrl = ApiConfig.baseUrl;
  String? _token;

  Future<void> setToken(String token) async {
    _token = token;
    // Guardar token en SharedPreferences
  }

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _token != null ? ApiConfig.getAuthHeaders(_token!) : ApiConfig.headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw _handleError(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _token != null ? ApiConfig.getAuthHeaders(_token!) : ApiConfig.headers,
      body: json.encode(data),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw _handleError(response);
  }

  Exception _handleError(http.Response response) {
    switch (response.statusCode) {
      case 401:
        return UnauthorizedException();
      case 403:
        return ForbiddenException();
      case 404:
        return NotFoundException();
      default:
        return ApiException(
          'Error ${response.statusCode}: ${response.body}'
        );
    }
  }
}

class UnauthorizedException implements Exception {}
class ForbiddenException implements Exception {}
class NotFoundException implements Exception {}
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
}

## Notas Importantes
1. Todos los endpoints requieren autenticación (excepto /login y /health)
2. Las respuestas están en formato JSON
3. Los errores siguen un formato estándar
4. Usar siempre HTTPS en producción
5. Manejar el token JWT en el almacenamiento seguro del dispositivo
6. Implementar interceptores para refrescar el token cuando sea necesario 
