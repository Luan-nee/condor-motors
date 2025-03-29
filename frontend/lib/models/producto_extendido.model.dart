import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/productos_utils.dart';
import 'producto.model.dart';
import 'sucursal.model.dart';

/// Modelo extendido de producto que incluye disponibilidad en sucursales
class ProductoExtendido {
  final Producto producto;
  final List<ProductoEnSucursal> disponibilidad;
  final int totalSucursales;
  final int sucursalesDisponibles;
  final int sucursalesStockBajo;
  final int sucursalesAgotadas;
  final int sucursalesNoDisponible;

  ProductoExtendido({
    required this.producto,
    required this.disponibilidad,
    this.totalSucursales = 0,
    this.sucursalesDisponibles = 0,
    this.sucursalesStockBajo = 0,
    this.sucursalesAgotadas = 0,
    this.sucursalesNoDisponible = 0,
  });

  /// Crea un objeto ProductoExtendido a partir de un Producto y una lista de sucursales
  /// consultando la API para determinar la disponibilidad del producto en cada sucursal
  static Future<ProductoExtendido> fromProducto({
    required Producto producto,
    required List<Sucursal> sucursales,
  }) async {
    try {
      final List<ProductoEnSucursal> disponibilidad = await ProductosUtils.obtenerProductoEnSucursales(
        productoId: producto.id,
        sucursales: sucursales,
      );

      // Calcular estadísticas de disponibilidad
      int disponibles = 0;
      int stockBajo = 0;
      int agotadas = 0;
      int noDisponible = 0;

      for (final item in disponibilidad) {
        if (!item.disponible) {
          noDisponible++;
        } else if (item.producto.stock <= 0) {
          agotadas++;
        } else if (item.producto.tieneStockBajo()) {
          stockBajo++;
        } else {
          disponibles++;
        }
      }

      return ProductoExtendido(
        producto: producto,
        disponibilidad: disponibilidad,
        totalSucursales: disponibilidad.length,
        sucursalesDisponibles: disponibles,
        sucursalesStockBajo: stockBajo,
        sucursalesAgotadas: agotadas,
        sucursalesNoDisponible: noDisponible,
      );
    } catch (e) {
      debugPrint('Error al cargar disponibilidad del producto: $e');
      return ProductoExtendido(
        producto: producto,
        disponibilidad: [],
      );
    }
  }

  /// Obtiene la disponibilidad del producto en una sucursal específica
  ProductoEnSucursal? getDisponibilidadEnSucursal(String sucursalId) {
    try {
      return disponibilidad.firstWhere((d) => d.sucursal.id.toString() == sucursalId);
    } catch (e) {
      return null;
    }
  }

  /// Verifica si el producto está disponible en al menos una sucursal central
  bool isDisponibleEnAlgunaSucursalCentral() {
    return disponibilidad.any((d) => 
      d.disponible && 
      d.producto.stock > 0 && 
      d.sucursal.sucursalCentral
    );
  }

  /// Verifica si el producto tiene stock bajo en todas las sucursales donde está disponible
  bool tieneStockBajoEnTodas() {
    if (disponibilidad.isEmpty) return false;
    
    final sucursalesConProducto = disponibilidad.where((d) => d.disponible);
    if (sucursalesConProducto.isEmpty) return false;
    
    return sucursalesConProducto.every((d) => d.producto.tieneStockBajo());
  }

  /// Obtiene una lista de sucursales ordenadas por prioridad:
  /// 1. Con stock y sucursales centrales primero
  /// 2. Con stock pero no centrales
  /// 3. Sin stock pero disponibles
  /// 4. No disponibles
  List<ProductoEnSucursal> getSucursalesOrdenadasPorDisponibilidad() {
    return disponibilidad.toList()
      ..sort((a, b) {
        // Primero productos disponibles con stock
        if (a.disponible && a.producto.stock > 0 && !(b.disponible && b.producto.stock > 0)) {
          return -1;
        }
        if (b.disponible && b.producto.stock > 0 && !(a.disponible && a.producto.stock > 0)) {
          return 1;
        }
        
        // Luego por sucursal central
        if (a.sucursal.sucursalCentral && !b.sucursal.sucursalCentral) {
          return -1;
        }
        if (b.sucursal.sucursalCentral && !a.sucursal.sucursalCentral) {
          return 1;
        }
        
        // Luego por cantidad de stock (mayor a menor)
        if (a.disponible && b.disponible) {
          return b.producto.stock.compareTo(a.producto.stock);
        }
        
        return a.sucursal.nombre.compareTo(b.sucursal.nombre);
      });
  }

  /// Obtiene la suma total de stock del producto en todas las sucursales
  int getTotalStock() {
    return disponibilidad
        .where((d) => d.disponible)
        .fold(0, (sum, item) => sum + item.producto.stock);
  }

  /// Calcula la desviación estándar de stock entre sucursales
  /// para detectar problemas de distribución
  double getStockDesviacionEstandar() {
    final sucursalesConProducto = disponibilidad.where((d) => d.disponible).toList();
    if (sucursalesConProducto.length <= 1) return 0;
    
    final stockValues = sucursalesConProducto.map((d) => d.producto.stock).toList();
    final media = stockValues.reduce((a, b) => a + b) / stockValues.length;
    
    final sumCuadrados = stockValues.fold(0.0, (sum, item) => 
      sum + (item - media) * (item - media)
    );
    
    return (sumCuadrados / stockValues.length) >= 0 
        ? math.sqrt(sumCuadrados / stockValues.length)
        : 0;
  }
} 