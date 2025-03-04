# 📦 API Productos - Condors Motos

## Endpoints Protegidos

### Listar Productos
```http
GET /api/productos
Authorization: Bearer {token}
```

#### Parámetros de Query
- `categoria_id`: Filtrar por categoría
- `marca_id`: Filtrar por marca
- `local_id`: Filtrar por local

#### Respuesta Exitosa (200 OK)
```json
[
    {
        "id": 1,
        "codigo": "P001",
        "nombre": "Aceite Motor",
        "descripcion": "Aceite sintético para motor",
        "precio_normal": 45.90,
        "precio_compra": 35.00,
        "precio_mayorista": 40.00,
        "stock_minimo": 10,
        "categoria_nombre": "Lubricantes",
        "marca_nombre": "Motul",
        "stock_actual": 25
    }
]
```

### Obtener Producto
```http
GET /api/productos/{id}
Authorization: Bearer {token}
```

### Crear Producto
```http
POST /api/productos
Authorization: Bearer {token}
Content-Type: application/json

{
    "codigo": "P001",
    "nombre": "Aceite Motor",
    "descripcion": "Aceite sintético para motor",
    "precio_normal": 45.90,
    "precio_compra": 35.00,
    "precio_mayorista": 40.00,
    "stock_minimo": 10,
    "categoria_id": 1,
    "marca_id": 1,
    "local_id": 1
}
```

### Actualizar Producto
```http
PUT /api/productos/{id}
Authorization: Bearer {token}
Content-Type: application/json

{
    "precio_normal": 47.90,
    "precio_mayorista": 42.00,
    "stock_minimo": 15
}
```

### Eliminar Producto
```http
DELETE /api/productos/{id}
Authorization: Bearer {token}
```

## Permisos
- ADMINISTRADOR: Acceso total
- COLABORADOR: Ver productos
- VENDEDOR: Ver productos
- COMPUTADORA: Ver productos

## Implementación en Flutter

### Servicio de Productos
```dart
class ProductoService {
  final ApiService _api;

  ProductoService(this._api);

  Future<List<Producto>> getProductos({
    int? categoriaId,
    int? marcaId,
    int? localId,
  }) async {
    final queryParams = {
      if (categoriaId != null) 'categoria_id': categoriaId.toString(),
      if (marcaId != null) 'marca_id': marcaId.toString(),
      if (localId != null) 'local_id': localId.toString(),
    };

    final response = await _api.get(
      '/productos',
      queryParameters: queryParams,
    );
    
    return (response as List)
        .map((json) => Producto.fromJson(json))
        .toList();
  }

  Future<Producto> createProducto(ProductoCreate producto) async {
    final response = await _api.post('/productos', producto.toJson());
    return Producto.fromJson(response);
  }

  Future<Producto> updateProducto(int id, ProductoUpdate producto) async {
    final response = await _api.put(
      '/productos/$id',
      producto.toJson(),
    );
    return Producto.fromJson(response);
  }

  Future<void> deleteProducto(int id) async {
    await _api.delete('/productos/$id');
  }
}

### Ejemplo de Uso
```dart
class ProductosScreen extends StatelessWidget {
  final ProductoService _productoService;

  Future<void> _loadProductos() async {
    try {
      final productos = await _productoService.getProductos(
        categoriaId: 1,
        localId: currentLocal.id,
      );
      // Actualizar UI con productos
    } catch (e) {
      // Manejar error
    }
  }

  Future<void> _createProducto() async {
    try {
      final producto = await _productoService.createProducto(
        ProductoCreate(
          codigo: 'P001',
          nombre: 'Nuevo Producto',
          // ... otros campos
        ),
      );
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
- 404: Producto no encontrado
- 422: Datos inválidos
