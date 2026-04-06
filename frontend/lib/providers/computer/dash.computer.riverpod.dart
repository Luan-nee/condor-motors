import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/repositories/empleado.repository.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:condorsmotors/repositories/sucursal.repository.dart';
import 'package:condorsmotors/repositories/venta.repository.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dash.computer.riverpod.g.dart';

class DashComputerState {
  final bool isLoading;
  final String errorMessage;
  final List<dynamic> ultimasVentas;
  final List<Map<String, dynamic>> productosStockBajo;
  final int? sucursalId;
  final String nombreSucursal;
  final Paginacion paginacion;

  const DashComputerState({
    this.isLoading = false,
    this.errorMessage = '',
    this.ultimasVentas = const [],
    this.productosStockBajo = const [],
    this.sucursalId,
    this.nombreSucursal = 'Sucursal',
    this.paginacion = Paginacion.emptyPagination,
  });

  DashComputerState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<dynamic>? ultimasVentas,
    List<Map<String, dynamic>>? productosStockBajo,
    int? sucursalId,
    String? nombreSucursal,
    Paginacion? paginacion,
  }) {
    return DashComputerState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      ultimasVentas: ultimasVentas ?? this.ultimasVentas,
      productosStockBajo: productosStockBajo ?? this.productosStockBajo,
      sucursalId: sucursalId ?? this.sucursalId,
      nombreSucursal: nombreSucursal ?? this.nombreSucursal,
      paginacion: paginacion ?? this.paginacion,
    );
  }
}

@Riverpod(keepAlive: true)
class DashComputer extends _$DashComputer {
  final ProductoRepository _productoRepository = ProductoRepository.instance;
  final VentaRepository _ventaRepository = VentaRepository.instance;
  final EmpleadoRepository _empleadoRepository = EmpleadoRepository.instance;
  final SucursalRepository _sucursalRepository = SucursalRepository.instance;

  @override
  DashComputerState build() {
    return const DashComputerState();
  }

  Map<String, dynamic> _productoToMap(Producto producto) {
    return {
      'id': producto.id,
      'sku': producto.sku,
      'nombre': producto.nombre,
      'descripcion': producto.descripcion,
      'stockMinimo': producto.stockMinimo,
      'stock': producto.stock,
      'stockBajo': producto.stockBajo,
      'categoria': producto.categoria,
      'marca': producto.marca,
      'color': producto.color,
    };
  }

  /// Inicializa el provider obteniendo los datos del usuario y su sucursal
  Future<void> inicializar() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: '');
      debugPrint('Inicializando DashComputer...');

      // Obtener datos del usuario autenticado
      final userData = await _empleadoRepository.getUserData();
      if (userData == null) {
        throw Exception('No se encontraron datos del usuario autenticado');
      }

      // Extraer ID de sucursal del usuario y convertirlo a int
      final dynamic rawSucursalId = userData['sucursalId'];
      if (rawSucursalId == null) {
        throw Exception('El usuario no tiene una sucursal asignada');
      }

      int? sucursalIdParsed;
      if (rawSucursalId is int) {
        sucursalIdParsed = rawSucursalId;
      } else if (rawSucursalId is String) {
        sucursalIdParsed = int.tryParse(rawSucursalId);
        if (sucursalIdParsed == null) {
          throw Exception('ID de sucursal inválido: $rawSucursalId');
        }
      } else {
        throw Exception(
            'Tipo de ID de sucursal no soportado: ${rawSucursalId.runtimeType}');
      }

      String nombreSucursal = 'Sucursal';
      // Obtener nombre de la sucursal
      try {
        final sucursalData = await _sucursalRepository
            .getSucursalData(sucursalIdParsed.toString());
        nombreSucursal = sucursalData.nombre;
      } catch (e) {
        debugPrint('No se pudo obtener el nombre de la sucursal: $e');
        nombreSucursal = 'Sucursal $sucursalIdParsed';
      }

      state = state.copyWith(
        sucursalId: sucursalIdParsed,
        nombreSucursal: nombreSucursal,
      );

      // Cargar datos iniciales
      await cargarDatos();
    } catch (e) {
      debugPrint('Error en inicialización: $e');
      state = state.copyWith(
        errorMessage: 'Error al inicializar: $e',
        isLoading: false,
      );
    }
  }

  /// Carga los datos del dashboard
  Future<void> cargarDatos() async {
    if (state.sucursalId == null) {
      state = state.copyWith(
        errorMessage: 'No hay una sucursal seleccionada',
      );
      return;
    }

    try {
      state = state.copyWith(isLoading: true, errorMessage: '');

      // Cargar últimas ventas usando la API de ventas
      final ventasResponse = await _ventaRepository.getVentas(
        sucursalId: state.sucursalId.toString(),
        pageSize: 5,
        forceRefresh: true,
      );

      List<dynamic> ultimasVentas = [];
      Paginacion paginacion = Paginacion.emptyPagination;

      // Procesar la respuesta
      if (ventasResponse['data'] != null && ventasResponse['data'] is List) {
        ultimasVentas = ventasResponse['data'];
      }

      // Actualizar paginación si existe
      if (ventasResponse['pagination'] != null) {
        paginacion = Paginacion.fromApiResponse(ventasResponse);
      }

      // Cargar solo productos con stock bajo
      List<Map<String, dynamic>> productosStockBajo = [];
      try {
        final productosResponse = await _productoRepository.getProductos(
          sucursalId: state.sucursalId.toString(),
          stockBajo: true,
        );

        productosStockBajo =
            productosResponse.items.map(_productoToMap).toList();
      } catch (e) {
        debugPrint('Error al cargar productos con stock bajo: $e');
      }

      state = state.copyWith(
        ultimasVentas: ultimasVentas,
        paginacion: paginacion,
        productosStockBajo: productosStockBajo,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error al cargar datos: $e');
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }
}
