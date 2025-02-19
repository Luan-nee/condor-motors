import 'package:flutter/material.dart';
import './api.service.dart';

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
    if (producto != null) 'producto': producto!.toJson(),
    if (local != null) 'local': local!.toJson(),
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

class StockApi {
  final ApiService _api;

  StockApi(this._api);

  // Listar stocks con filtros según documentación
  Future<List<Stock>> getStocks({
    String? localId,
    String? productoId,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, String>{
        if (localId != null) 'local_id': localId,
        if (productoId != null) 'producto_id': productoId,
        'skip': skip.toString(),
        'limit': limit.toString(),
      };

      final response = await _api.request(
        endpoint: '/stocks',
        method: 'GET',
        queryParams: queryParams,
      );

      if (response == null) return [];

      if (response is List) {
        return response.map((json) => Stock.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error al obtener stocks: $e');
      rethrow;
    }
  }

  // Obtener stock específico
  Future<Stock?> getStock(String localId, String productoId) async {
    try {
      final response = await _api.request(
        endpoint: '/stocks/$localId/$productoId',
        method: 'GET',
        queryParams: const {},
      );

      if (response == null) return null;
      return Stock.fromJson(response);
    } catch (e) {
      debugPrint('Error al obtener stock específico: $e');
      rethrow;
    }
  }

  // Crear/Actualizar stock
  Future<Stock> updateStock({
    required String productoId,
    required String localId,
    required int cantidad,
  }) async {
    try {
      if (cantidad < 0) {
        throw Exception('La cantidad no puede ser negativa');
      }

      final response = await _api.request(
        endpoint: '/stocks',
        method: 'POST',
        body: {
          'producto_id': int.parse(productoId),
          'local_id': int.parse(localId),
          'cantidad': cantidad,
        },
        queryParams: const {},
      );

      return Stock.fromJson(response);
    } catch (e) {
      debugPrint('Error al actualizar stock: $e');
      rethrow;
    }
  }

  // Ajustar stock (incrementar/decrementar)
  Future<Stock> adjustStock({
    required String localId,
    required String productoId,
    required int cantidad,
  }) async {
    try {
      final response = await _api.request(
        endpoint: '/stocks/$localId/$productoId/ajustar',
        method: 'PUT',
        queryParams: {
          'cantidad': cantidad.toString(),
        },
      );

      return Stock.fromJson(response);
    } catch (e) {
      debugPrint('Error al ajustar stock: $e');
      rethrow;
    }
  }

  // Obtener productos con bajo stock
  Future<List<Stock>> getLowStockProducts(String localId) async {
    try {
      final stocks = await getStocks(
        localId: localId,
        limit: 100,
      );

      // Filtrar productos con stock bajo (menos de 10 unidades)
      return stocks.where((stock) => stock.cantidad < 10).toList();
    } catch (e) {
      debugPrint('Error al obtener productos con bajo stock: $e');
      return [];
    }
  }

  // Verificar disponibilidad de stock
  Future<bool> checkStockAvailability({
    required String localId,
    required String productId,
    required int cantidad,
  }) async {
    try {
      final stock = await getStock(localId, productId);
      return stock != null && stock.cantidad >= cantidad;
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

