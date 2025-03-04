# 🔄 API Movimientos - Condors Motos

## Endpoints Protegidos

### Listar Movimientos
```http
GET /api/movimientos
Authorization: Bearer {token}
```

#### Parámetros de Query
- `skip`: Número de registros a saltar (paginación)
- `limit`: Número de registros a retornar (paginación)
- `estado`: Filtrar por estado (SOLICITANDO, PREPARADO, RECIBIDO, APROBADO)
- `local_origen_id`: Filtrar por local de origen
- `local_destino_id`: Filtrar por local de destino

#### Respuesta Exitosa (200 OK)
```json
{
    "total": 100,
    "items": [
        {
            "id": 1,
            "estado": "APROBADO",
            "fecha_movimiento": "2024-03-21T10:30:00",
            "usuario_nombre": "Juan Pérez",
            "aprobador_nombre": "Admin Sistema",
            "origen_nombre": "Central Lima",
            "destino_nombre": "Sucursal Norte",
            "detalles": [
                {
                    "id": 1,
                    "producto_nombre": "Aceite Motul",
                    "cantidad": 10,
                    "cantidad_recibida": 10,
                    "estado": "RECIBIDO"
                }
            ]
        }
    ],
    "page": 1,
    "pages": 10
}
```

### Obtener Movimiento
```http
GET /api/movimientos/{id}
Authorization: Bearer {token}
```

### Actualizar Movimiento
```http
PUT /api/movimientos/{id}
Authorization: Bearer {token}
Content-Type: application/json

{
    "estado": "PREPARADO",
    "observaciones": "Stock verificado"
}
```

### Aprobar Movimiento
```http
PUT /api/movimientos/{id}/aprobar
Authorization: Bearer {token}
```

## Permisos
- ADMINISTRADOR: Acceso total
- COLABORADOR: Ver movimientos
- VENDEDOR: Ver movimientos de su local
- COMPUTADORA: Sin acceso

## Implementación en Flutter

### Servicio de Movimientos
```dart
class MovimientoService {
  final ApiService _api;

  MovimientoService(this._api);

  Future<PaginatedResponse<Movimiento>> getMovimientos({
    int page = 1,
    int limit = 10,
    String? estado,
    int? localOrigenId,
    int? localDestinoId,
  }) async {
    final queryParams = {
      'skip': ((page - 1) * limit).toString(),
      'limit': limit.toString(),
      if (estado != null) 'estado': estado,
      if (localOrigenId != null) 'local_origen_id': localOrigenId.toString(),
      if (localDestinoId != null) 'local_destino_id': localDestinoId.toString(),
    };

    final response = await _api.get(
      '/movimientos',
      queryParameters: queryParams,
    );
    
    return PaginatedResponse.fromJson(
      response,
      (json) => Movimiento.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Movimiento> updateMovimiento(int id, MovimientoUpdate movimiento) async {
    final response = await _api.put(
      '/movimientos/$id',
      movimiento.toJson(),
    );
    return Movimiento.fromJson(response);
  }

  Future<Movimiento> aprobarMovimiento(int id) async {
    final response = await _api.put('/movimientos/$id/aprobar', {});
    return Movimiento.fromJson(response);
  }
}

### Ejemplo de Uso
```dart
class MovimientosScreen extends StatelessWidget {
  final MovimientoService _movimientoService;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;

  Future<void> _loadMovimientos() async {
    try {
      final response = await _movimientoService.getMovimientos(
        page: _currentPage,
        localOrigenId: currentLocal.id,
      );
      // Actualizar UI con response.items
      // Actualizar paginación con response.total y response.pages
    } catch (e) {
      // Manejar error
    }
  }

  Future<void> _aprobarMovimiento(int id) async {
    try {
      await _movimientoService.aprobarMovimiento(id);
      // Actualizar UI
    } catch (e) {
      // Manejar error
    }
  }
}
```

## Códigos de Error
- 401: No autorizado
- 403: Permiso denegado
- 404: Movimiento no encontrado
- 422: Datos inválidos 