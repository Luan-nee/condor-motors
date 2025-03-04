import 'package:flutter/foundation.dart';
import 'main.api.dart';

class Producto {
  final int id;
  final String codigo;
  final String nombre;
  final String descripcion;
  final String marca;
  final String categoria;
  final double precioNormal;
  final double precioCompra;
  final double? precioMayorista;
  final double? precioDescuento;
  final DateTime? fechaDescuento;
  final String? imagen;
  final bool activo;
  final DateTime fechaCreacion;
  final DateTime? fechaModificacion;

  Producto.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      codigo = json['codigo'],
      nombre = json['nombre'],
      descripcion = json['descripcion'],
      marca = json['marca'],
      categoria = json['categoria'],
      precioNormal = json['precio_normal'].toDouble(),
      precioCompra = json['precio_compra'].toDouble(),
      precioMayorista = json['precio_mayorista']?.toDouble(),
      precioDescuento = json['precio_descuento']?.toDouble(),
      fechaDescuento = json['fecha_descuento'] != null 
        ? DateTime.parse(json['fecha_descuento'])
        : null,
      imagen = json['imagen'],
      activo = json['activo'] ?? true,
      fechaCreacion = DateTime.parse(json['fecha_creacion']),
      fechaModificacion = json['fecha_modificacion'] != null
        ? DateTime.parse(json['fecha_modificacion'])
        : null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'codigo': codigo,
    'nombre': nombre,
    'descripcion': descripcion,
    'marca': marca,
    'categoria': categoria,
    'precio_normal': precioNormal,
    'precio_compra': precioCompra,
    'precio_mayorista': precioMayorista,
    'precio_descuento': precioDescuento,
    'fecha_descuento': fechaDescuento?.toIso8601String(),
    'imagen': imagen,
    'activo': activo,
  };
}

class ProductosApi {
  final ApiService _api;
  final String _endpoint = '/productos';

  ProductosApi(this._api);

  // Obtener todos los productos
  Future<List<Producto>> getProductos() async {
    try {
      final response = await _api.request(
        endpoint: _endpoint,
        method: 'GET',
      );

      if (response == null) return [];
      return (response as List)
        .map((json) => Producto.fromJson(json))
        .toList();
    } catch (e) {
      debugPrint('Error al obtener productos: $e');
      return [];
    }
  }

  // Obtener un producto por ID
  Future<Producto?> getProducto(int id) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'GET',
      );

      if (response == null || (response as List).isEmpty) return null;
      return Producto.fromJson(response[0]);
    } catch (e) {
      debugPrint('Error al obtener producto: $e');
      return null;
    }
  }

  // Crear un nuevo producto
  Future<Producto?> createProducto(Map<String, dynamic> producto) async {
    try {
      // Validaciones básicas
      if (!producto.containsKey('nombre') ||
          !producto.containsKey('codigo') ||
          !producto.containsKey('precio_normal') ||
          !producto.containsKey('precio_compra')) {
        throw Exception('Faltan campos requeridos');
      }

      // Establecer fecha de creación
      producto['fecha_creacion'] = DateTime.now().toIso8601String();

      final response = await _api.request(
        endpoint: _endpoint,
        method: 'POST',
        body: producto,
      );

      if (response == null || (response as List).isEmpty) return null;
      return Producto.fromJson(response[0]);
    } catch (e) {
      debugPrint('Error al crear producto: $e');
      return null;
    }
  }

  // Actualizar un producto
  Future<bool> updateProducto(int id, Map<String, dynamic> producto) async {
    try {
      // Establecer fecha de modificación
      producto['fecha_modificacion'] = DateTime.now().toIso8601String();

      await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'PATCH',
        body: producto,
      );
      return true;
    } catch (e) {
      debugPrint('Error al actualizar producto: $e');
      return false;
    }
  }

  // Eliminar un producto (desactivar)
  Future<bool> deleteProducto(int id) async {
    try {
      await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'PATCH',
        body: {
          'activo': false,
          'fecha_modificacion': DateTime.now().toIso8601String(),
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error al eliminar producto: $e');
      return false;
    }
  }

  // Buscar productos
  Future<List<Producto>> searchProductos(String query) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint?or=(nombre.ilike.*$query*,codigo.ilike.*$query*,descripcion.ilike.*$query*)&activo=eq.true',
        method: 'GET',
      );

      if (response == null) return [];
      return (response as List)
        .map((json) => Producto.fromJson(json))
        .toList();
    } catch (e) {
      debugPrint('Error al buscar productos: $e');
      return [];
    }
  }

  // Obtener productos por categoría
  Future<List<Producto>> getProductosPorCategoria(String categoria) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint?categoria=eq.$categoria&activo=eq.true',
        method: 'GET',
      );

      if (response == null) return [];
      return (response as List)
        .map((json) => Producto.fromJson(json))
        .toList();
    } catch (e) {
      debugPrint('Error al obtener productos por categoría: $e');
      return [];
    }
  }

  // Obtener productos por marca
  Future<List<Producto>> getProductosPorMarca(String marca) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint?marca=eq.$marca&activo=eq.true',
        method: 'GET',
      );

      if (response == null) return [];
      return (response as List)
        .map((json) => Producto.fromJson(json))
        .toList();
    } catch (e) {
      debugPrint('Error al obtener productos por marca: $e');
      return [];
    }
  }

  // Obtener productos por local
  Future<List<Producto>> getProductosPorLocal(String local) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint?local=eq.$local&activo=eq.true',
        method: 'GET',
      );

      if (response == null) return [];
      return (response as List)
        .map((json) => Producto.fromJson(json))
        .toList();
    } catch (e) {
      debugPrint('Error al obtener productos por local: $e');
      return [];
    }
  }

  // Actualizar stock mínimo
  Future<void> updateStockMinimo(int id, int stockMinimo) async {
    try {
      await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'PUT',
        body: {'stock_minimo': stockMinimo},
      );
    } catch (e) {
      debugPrint('Error al actualizar stock mínimo: $e');
      rethrow;
    }
  }

  // Actualizar precios
  Future<void> updatePrecios(int id, {
    double? precioNormal,
    double? precioCompra,
    double? precioMayorista,
    double? precioOferta,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (precioNormal != null) updates['precio_normal'] = precioNormal;
      if (precioCompra != null) updates['precio_compra'] = precioCompra;
      if (precioMayorista != null) updates['precio_mayorista'] = precioMayorista;
      if (precioOferta != null) updates['precio_oferta'] = precioOferta;

      if (updates.isEmpty) return;

      await _api.request(
        endpoint: '$_endpoint?id=eq.$id',
        method: 'PUT',
        body: updates,
      );
    } catch (e) {
      debugPrint('Error al actualizar precios: $e');
      rethrow;
    }
  }

  Future<List<Producto>> getProductosBajoStock() async {
    try {
      final response = await _api.request(
        endpoint: '/productos/bajo-stock',
        method: 'GET',
        queryParams: const {},
      );

      if (response is List) {
        return (response)
          .map((json) => Producto.fromJson(json))
          .toList();
      }
      throw Exception('Formato de respuesta inválido');
    } catch (e) {
      debugPrint('Error al obtener productos con bajo stock: $e');
      rethrow;
    }
  }

  Future<List<Producto>> getProductosMasVendidos() async {
    try {
      final response = await _api.request(
        endpoint: '/productos/mas-vendidos',
        method: 'GET',
        queryParams: const {},
      );

      if (response is List) {
        return (response)
          .map((json) => Producto.fromJson(json))
          .toList();
      }
      throw Exception('Formato de respuesta inválido');
    } catch (e) {
      debugPrint('Error al obtener productos más vendidos: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getVentas() async {
    try {
      final response = await _api.request(
        endpoint: '/ventas/resumen',
        method: 'GET',
        queryParams: const {},
      );
      return response;
    } catch (e) {
      debugPrint('Error al obtener resumen de ventas: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getInfoVendedor() async {
    try {
      final response = await _api.request(
        endpoint: '/usuarios/perfil',
        method: 'GET',
        queryParams: const {},
      );
      return response;
    } catch (e) {
      debugPrint('Error al obtener información del vendedor: $e');
      rethrow;
    }
  }

  Future<void> crearSolicitudVenta(Map<String, dynamic> datosVenta) async {
    try {
      await _api.request(
        endpoint: '/ventas-pendientes',
        method: 'POST',
        queryParams: const {},
        body: datosVenta,
      );
    } catch (e) {
      debugPrint('Error al crear solicitud de venta: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getExistencias(String idLocal) async {
    try {
      final response = await _api.request(
        endpoint: '/stocks',
        method: 'GET',
        queryParams: {
          'local_id': idLocal,
        },
      );

      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      throw Exception('Formato de respuesta inválido');
    } catch (e) {
      debugPrint('Error al obtener existencias: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getExistenciasProducto(String idLocal, String idProducto) async {
    try {
      final response = await _api.request(
        endpoint: '/stocks/$idLocal/$idProducto',
        method: 'GET',
        queryParams: const {},
      );
      return response;
    } catch (e) {
      debugPrint('Error al obtener existencias del producto: $e');
      rethrow;
    }
  }
}
