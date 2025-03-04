import 'package:flutter/material.dart';
import 'main.api.dart';

// Modelos según documentación
class Stock {
  final int id;
  final int productoId;
  final int localId;
  final int cantidad;
  final DateTime ultimaActualizacion;
  final Producto? producto;
  final Local? local;

  Stock.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      productoId = json['producto_id'],
      localId = json['local_id'],
      cantidad = json['cantidad'],
      ultimaActualizacion = DateTime.parse(json['ultima_actualizacion']),
      producto = json['producto'] != null 
        ? Producto.fromJson(json['producto']) 
        : null,
      local = json['local'] != null 
        ? Local.fromJson(json['local']) 
        : null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'producto_id': productoId,
    'local_id': localId,
    'cantidad': cantidad,
    'ultima_actualizacion': ultimaActualizacion.toIso8601String(),
  };
}

class Producto {
  final int id;
  final String nombre;
  final String codigo;
  final String marca;
  final String categoria;
  final double precio;

  Producto.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      nombre = json['nombre'],
      codigo = json['codigo'],
      marca = json['marca'],
      categoria = json['categoria'],
      precio = json['precio'].toDouble();

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'codigo': codigo,
    'marca': marca,
    'categoria': categoria,
    'precio': precio,
  };
}

class Local {
  final int id;
  final String nombre;
  final String tipo;

  Local.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      nombre = json['nombre'],
      tipo = json['tipo'];

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'tipo': tipo,
  };
}

class StocksApi {
  final ApiService _api;
  final String _endpoint = '/stocks';

  StocksApi(this._api);

  // Obtener stock por local y producto
  Future<Stock?> getStock(int localId, int productoId) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint?local_id=eq.$localId&producto_id=eq.$productoId',
        method: 'GET',
      );

      if (response == null || (response as List).isEmpty) return null;
      return Stock.fromJson(response[0]);
    } catch (e) {
      debugPrint('Error al obtener stock: $e');
      return null;
    }
  }

  // Obtener todos los stocks de un local
  Future<List<Stock>> getStocks({
    required int localId,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{
        'local_id': 'eq.$localId',
      };

      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      final response = await _api.request(
        endpoint: _endpoint,
        method: 'GET',
        queryParams: queryParams,
      );

      if (response == null) return [];
      return List<Map<String, dynamic>>.from(response)
        .map((json) => Stock.fromJson(json))
        .toList();
    } catch (e) {
      debugPrint('Error al obtener stocks: $e');
      return [];
    }
  }

  // Actualizar stock
  Future<Stock> updateStock({
    required int localId,
    required int productoId,
    required int cantidad,
  }) async {
    try {
      final response = await _api.request(
        endpoint: '$_endpoint?local_id=eq.$localId&producto_id=eq.$productoId',
        method: 'PATCH',
        body: {
          'cantidad': cantidad,
          'ultima_actualizacion': DateTime.now().toIso8601String(),
        },
      );

      return Stock.fromJson(response[0]);
    } catch (e) {
      debugPrint('Error al actualizar stock: $e');
      rethrow;
    }
  }

  // Ajustar stock (incrementar/decrementar)
  Future<Stock> adjustStock({
    required int localId,
    required int productoId,
    required int cantidad,
  }) async {
    try {
      final stock = await getStock(localId, productoId);
      if (stock == null) {
        throw Exception('Stock no encontrado');
      }

      return await updateStock(
        localId: localId,
        productoId: productoId,
        cantidad: stock.cantidad + cantidad,
      );
    } catch (e) {
      debugPrint('Error al ajustar stock: $e');
      rethrow;
    }
  }

  // Obtener productos con bajo stock
  Future<List<Stock>> getLowStockProducts(int localId) async {
    try {
      final response = await _api.request(
        endpoint: '/rpc/get_low_stock_products',
        method: 'POST',
        body: {
          'p_local_id': localId,
        },
      );

      if (response == null) return [];

      return List<Map<String, dynamic>>.from(response).map((json) {
        // Crear un objeto Stock con la información necesaria
        return Stock.fromJson({
          'id': json['stock_id'],
          'producto_id': json['producto_id'],
          'local_id': localId,
          'cantidad': json['cantidad'],
          'ultima_actualizacion': DateTime.now().toIso8601String(),
          'producto': {
            'id': json['producto_id'],
            'codigo': json['codigo'],
            'nombre': json['nombre'],
            'marca': json['marca_nombre'],
            'categoria': json['categoria_nombre'],
            'precio': 0.0, // Este valor no viene en la función RPC
          },
        });
      }).toList();
    } catch (e) {
      debugPrint('Error al obtener productos con bajo stock: $e');
      return [];
    }
  }

  // Verificar disponibilidad de stock
  Future<bool> checkStockAvailability({
    required int localId,
    required int productoId,
    required int cantidad,
  }) async {
    try {
      final response = await _api.request(
        endpoint: '/rpc/check_stock_availability',
        method: 'POST',
        body: {
          'p_producto_id': productoId,
          'p_local_id': localId,
          'p_cantidad': cantidad,
        },
      );

      return response as bool;
    } catch (e) {
      debugPrint('Error al verificar disponibilidad: $e');
      return false;
    }
  }

  // Validar permisos según rol
  bool canModifyStock(String rol) {
    switch (rol.toUpperCase()) {
      case 'ADMINISTRADOR':
      case 'COLABORADOR':
        return true;
      default:
        return false;
    }
  }

  bool canViewStock(String rol) {
    return true; // Todos los roles pueden ver stock según documentación
  }
}

