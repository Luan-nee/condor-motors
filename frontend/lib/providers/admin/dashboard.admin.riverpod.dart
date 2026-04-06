import 'dart:async';
import 'package:condorsmotors/models/empleado.model.dart';
import 'package:condorsmotors/models/estadisticas.model.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/empleado.repository.dart';
import 'package:condorsmotors/repositories/estadistica.repository.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:condorsmotors/repositories/sucursal.repository.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard.admin.riverpod.g.dart';

class VentaReciente {
  final String fecha;
  final String factura;
  final String? tipoDocumento;
  final String? sucursalNombre;
  final double monto;
  final String estado;

  VentaReciente({
    required this.fecha,
    required this.factura,
    this.tipoDocumento,
    this.sucursalNombre,
    required this.monto,
    required this.estado,
  });

  factory VentaReciente.fromJson(Map<String, dynamic> json) {
    return VentaReciente(
      fecha: json['fecha'] ?? '',
      factura: json['factura'] ?? '',
      tipoDocumento: json['tipoDocumento'],
      sucursalNombre: json['sucursalNombre'],
      monto: (json['monto'] ?? 0).toDouble(),
      estado: json['estado'] ?? 'Pendiente',
    );
  }
}

class DashboardAdminState {
  final bool isLoading;
  final String sucursalSeleccionadaId;
  final bool isLoadingSucursales;
  final bool isLoadingProductos;
  final bool isLoadingEmpleados;
  final bool isLoadingEstadisticas;
  final bool isLoadingVentasRecientes;
  final List<Sucursal> sucursales;
  final List<dynamic> productos;
  final int totalEmpleados;
  final int productosAgotados;
  final List<VentaReciente> ventasRecientes;
  final ResumenEstadisticas? resumenEstadisticas;
  final String? errorMessage;

  DashboardAdminState({
    this.isLoading = true,
    this.sucursalSeleccionadaId = '',
    this.isLoadingSucursales = false,
    this.isLoadingProductos = false,
    this.isLoadingEmpleados = false,
    this.isLoadingEstadisticas = false,
    this.isLoadingVentasRecientes = false,
    this.sucursales = const [],
    this.productos = const [],
    this.totalEmpleados = 0,
    this.productosAgotados = 0,
    this.ventasRecientes = const [],
    this.resumenEstadisticas,
    this.errorMessage,
  });

  DashboardAdminState copyWith({
    bool? isLoading,
    String? sucursalSeleccionadaId,
    bool? isLoadingSucursales,
    bool? isLoadingProductos,
    bool? isLoadingEmpleados,
    bool? isLoadingEstadisticas,
    bool? isLoadingVentasRecientes,
    List<Sucursal>? sucursales,
    List<dynamic>? productos,
    int? totalEmpleados,
    int? productosAgotados,
    List<VentaReciente>? ventasRecientes,
    ResumenEstadisticas? resumenEstadisticas,
    String? errorMessage,
  }) {
    return DashboardAdminState(
      isLoading: isLoading ?? this.isLoading,
      sucursalSeleccionadaId:
          sucursalSeleccionadaId ?? this.sucursalSeleccionadaId,
      isLoadingSucursales: isLoadingSucursales ?? this.isLoadingSucursales,
      isLoadingProductos: isLoadingProductos ?? this.isLoadingProductos,
      isLoadingEmpleados: isLoadingEmpleados ?? this.isLoadingEmpleados,
      isLoadingEstadisticas:
          isLoadingEstadisticas ?? this.isLoadingEstadisticas,
      isLoadingVentasRecientes:
          isLoadingVentasRecientes ?? this.isLoadingVentasRecientes,
      sucursales: sucursales ?? this.sucursales,
      productos: productos ?? this.productos,
      totalEmpleados: totalEmpleados ?? this.totalEmpleados,
      productosAgotados: productosAgotados ?? this.productosAgotados,
      ventasRecientes: ventasRecientes ?? this.ventasRecientes,
      resumenEstadisticas: resumenEstadisticas ?? this.resumenEstadisticas,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

@riverpod
class DashboardAdmin extends _$DashboardAdmin {
  late final ProductoRepository _productoRepository;
  late final SucursalRepository _sucursalRepository;
  late final EmpleadoRepository _empleadoRepository;
  late final EstadisticaRepository _estadisticaRepository;

  @override
  DashboardAdminState build() {
    _productoRepository = ProductoRepository.instance;
    _sucursalRepository = SucursalRepository.instance;
    _empleadoRepository = EmpleadoRepository.instance;
    _estadisticaRepository = EstadisticaRepository.instance;

    return DashboardAdminState();
  }

  Future<void> inicializar() async {
    if (!state.isLoading) {
      state = state.copyWith(isLoading: true);
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      state = state.copyWith(isLoadingSucursales: true);
      final List<Sucursal> sucursalesResponse =
          await _sucursalRepository.getSucursales();
      state = state.copyWith(isLoadingSucursales: false);

      final List<Sucursal> centralesList = sucursalesResponse
          .where((sucursal) => sucursal.sucursalCentral)
          .toList();

      String sucursalId = '';
      if (centralesList.isNotEmpty) {
        sucursalId = centralesList.first.id.toString();
      } else if (sucursalesResponse.isNotEmpty) {
        sucursalId = sucursalesResponse.first.id.toString();
      }

      state = state.copyWith(
        sucursales: sucursalesResponse,
        sucursalSeleccionadaId: sucursalId,
      );

      if (sucursalId.isNotEmpty) {
        await Future.wait([
          _loadProductos(),
          _loadEmpleados(),
          _loadEstadisticas(),
        ]);
      }
    } catch (e) {
      debugPrint('Error cargando datos iniciales: $e');
      state = state.copyWith(isLoadingSucursales: false);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _loadProductos() async {
    state = state.copyWith(isLoadingProductos: true);
    try {
      final PaginatedResponse<dynamic> paginatedProductos =
          await _productoRepository.getProductos(
        sucursalId: state.sucursalSeleccionadaId,
        pageSize: 100,
      );

      int agotados = 0;
      for (dynamic producto in paginatedProductos.items) {
        if (producto.stock <= 0) {
          agotados++;
        }
      }

      state = state.copyWith(
        productos: paginatedProductos.items,
        productosAgotados: agotados,
        isLoadingProductos: false,
      );
    } catch (e) {
      debugPrint('Error cargando productos: $e');
      state = state.copyWith(isLoadingProductos: false);
    }
  }

  Future<void> _loadEmpleados() async {
    state = state.copyWith(isLoadingEmpleados: true);
    try {
      final EmpleadosPaginados empleadosPaginados =
          await _empleadoRepository.getEmpleados();
      state = state.copyWith(
        totalEmpleados: empleadosPaginados.empleados.length,
        isLoadingEmpleados: false,
      );
    } catch (e) {
      debugPrint('Error cargando empleados: $e');
      state = state.copyWith(isLoadingEmpleados: false);
    }
  }

  Future<void> _loadEstadisticas() async {
    state = state.copyWith(isLoadingEstadisticas: true);
    try {
      final ResumenEstadisticas resumen =
          await _estadisticaRepository.getResumenEstadisticasTyped();
      state = state.copyWith(
        resumenEstadisticas: resumen,
        isLoadingEstadisticas: false,
      );
      await _loadUltimasVentas();
    } catch (e) {
      debugPrint('Error al procesar el resumen de estadísticas: $e');
      state = state.copyWith(isLoadingEstadisticas: false);
    }
  }

  Future<void> _loadUltimasVentas() async {
    state = state.copyWith(isLoadingVentasRecientes: true);
    try {
      final ultimasVentas = await _estadisticaRepository.getUltimasVentas();
      if (ultimasVentas.isNotEmpty) {
        final ventasProcesadas = ultimasVentas.map((venta) {
          final fechaFormateada =
              venta.fechaEmision != null && venta.horaEmision != null
                  ? "${venta.fechaEmision} ${venta.horaEmision}"
                  : "Fecha no disponible";
          final facturaFormateada =
              venta.serieDocumento != null && venta.numeroDocumento != null
                  ? "${venta.serieDocumento}-${venta.numeroDocumento}"
                  : "Doc. sin número";
          return VentaReciente(
            fecha: fechaFormateada,
            factura: facturaFormateada,
            tipoDocumento: venta.tipoDocumento,
            sucursalNombre: venta.sucursal.nombre,
            monto: venta.totalesVenta.totalVenta,
            estado: venta.estado.nombre,
          );
        }).toList();
        state = state.copyWith(
          ventasRecientes: ventasProcesadas,
          isLoadingVentasRecientes: false,
        );
      } else {
        state = state.copyWith(
          ventasRecientes: [],
          isLoadingVentasRecientes: false,
        );
      }
    } catch (e) {
      debugPrint('Error al cargar últimas ventas: $e');
      state = state.copyWith(
        ventasRecientes: [],
        isLoadingVentasRecientes: false,
      );
    }
  }

  Future<void> cambiarSucursal(String sucursalId) async {
    if (sucursalId != state.sucursalSeleccionadaId) {
      state =
          state.copyWith(sucursalSeleccionadaId: sucursalId, isLoading: true);
      try {
        await Future.wait([
          _loadProductos(),
          _loadEstadisticas(),
        ]);
      } finally {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> recargarDatos() async {
    state = state.copyWith(isLoading: true);
    try {
      await _loadData();
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
