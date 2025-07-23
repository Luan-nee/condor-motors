import 'package:condorsmotors/models/empleado.model.dart';
import 'package:condorsmotors/models/estadisticas.model.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/empleado.repository.dart';
import 'package:condorsmotors/repositories/estadistica.repository.dart';
// Importar los repositorios necesarios
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:condorsmotors/repositories/sucursal.repository.dart';
import 'package:flutter/material.dart';

/// Provider para el dashboard de administración
class DashboardProvider extends ChangeNotifier {
  // Instancias de repositorios
  final ProductoRepository _productoRepository = ProductoRepository.instance;
  final SucursalRepository _sucursalRepository = SucursalRepository.instance;
  final EmpleadoRepository _empleadoRepository = EmpleadoRepository.instance;
  final EstadisticaRepository _estadisticaRepository =
      EstadisticaRepository.instance;

  // Estado
  bool _isLoading = true;
  String _sucursalSeleccionadaId = '';

  // Estado de carga por sección
  bool _isLoadingSucursales = false;
  bool _isLoadingProductos = false;
  bool _isLoadingEmpleados = false;
  bool _isLoadingEstadisticas = false;
  bool _isLoadingVentasRecientes = false;

  // Datos del dashboard
  List<Sucursal> _sucursales = [];
  List<dynamic> _productos = [];
  int _totalEmpleados = 0;
  int _productosAgotados = 0;
  List<VentaReciente> _ventasRecientes = [];

  // Resumen completo de estadísticas
  ResumenEstadisticas? _resumenEstadisticas;

  // Getters
  bool get isLoading => _isLoading;
  String get sucursalSeleccionadaId => _sucursalSeleccionadaId;
  List<Sucursal> get sucursales => _sucursales;
  List<dynamic> get productos => _productos;
  int get totalEmpleados => _totalEmpleados;
  int get productosAgotados => _productosAgotados;
  List<VentaReciente> get ventasRecientes => _ventasRecientes;
  ResumenEstadisticas? get resumenEstadisticas => _resumenEstadisticas;

  // Getters de loading por sección
  bool get isLoadingSucursales => _isLoadingSucursales;
  bool get isLoadingProductos => _isLoadingProductos;
  bool get isLoadingEmpleados => _isLoadingEmpleados;
  bool get isLoadingEstadisticas => _isLoadingEstadisticas;
  bool get isLoadingVentasRecientes => _isLoadingVentasRecientes;

  /// Inicializa el provider cargando todos los datos necesarios
  Future<void> inicializar() async {
    if (!_isLoading) {
      _setLoading(true);
    }
    await _loadData();
  }

  /// Carga todos los datos del dashboard
  Future<void> _loadData() async {
    try {
      _setLoadingSucursales(true);
      final List<Sucursal> sucursalesResponse =
          await _sucursalRepository.getSucursales();
      _setLoadingSucursales(false);

      final List<Sucursal> sucursalesList = [];
      final List<Sucursal> centralesList = [];

      for (Sucursal sucursal in sucursalesResponse) {
        sucursalesList.add(sucursal);
        if (sucursal.sucursalCentral) {
          centralesList.add(sucursal);
        }
      }

      _sucursales = sucursalesList;

      String sucursalId = '';
      if (centralesList.isNotEmpty) {
        sucursalId = centralesList.first.id.toString();
      } else if (sucursalesList.isNotEmpty) {
        sucursalId = sucursalesList.first.id.toString();
      }

      if (sucursalId.isNotEmpty) {
        _sucursalSeleccionadaId = sucursalId;
        await Future.wait([
          _loadProductos(),
          _loadEmpleados(),
          _loadEstadisticas(),
        ]);
      }
    } catch (e) {
      debugPrint('Error cargando datos iniciales: $e');
      _setLoadingSucursales(false);
    } finally {
      _setLoading(false);
    }
  }

  /// Carga los productos para todas las sucursales
  Future<void> _loadProductos() async {
    _setLoadingProductos(true);
    try {
      final Map<String, List<dynamic>> productosBySucursal = {};
      for (Sucursal sucursal in _sucursales) {
        productosBySucursal[sucursal.id.toString()] = [];
      }
      final PaginatedResponse<dynamic> paginatedProductos =
          await _productoRepository.getProductos(
        sucursalId: _sucursalSeleccionadaId,
        pageSize: 100,
      );
      int agotados = 0;
      for (dynamic producto in paginatedProductos.items) {
        if (producto.stock <= 0) {
          agotados++;
        }
        if (productosBySucursal.containsKey(_sucursalSeleccionadaId)) {
          productosBySucursal[_sucursalSeleccionadaId]!.add(producto);
        }
      }
      final List<Future<void>> futures = [];
      for (Sucursal sucursal in _sucursales) {
        if (sucursal.id.toString() != _sucursalSeleccionadaId) {
          futures.add(_loadProductosPorSucursal(sucursal, productosBySucursal));
        }
      }
      await Future.wait(futures);
      _productos = paginatedProductos.items;
      _productosAgotados = agotados;
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando productos: $e');
    } finally {
      _setLoadingProductos(false);
    }
  }

  Future<void> _loadProductosPorSucursal(
      Sucursal sucursal, Map<String, List<dynamic>> productosBySucursal) async {
    try {
      final PaginatedResponse<dynamic> sucProducts =
          await _productoRepository.getProductos(
        sucursalId: sucursal.id.toString(),
        pageSize: 100,
      );
      productosBySucursal[sucursal.id.toString()] = sucProducts.items;
    } catch (e) {
      debugPrint('Error cargando productos para sucursal ${sucursal.id}: $e');
      productosBySucursal[sucursal.id.toString()] = [];
    }
  }

  Future<void> _loadEmpleados() async {
    _setLoadingEmpleados(true);
    try {
      final EmpleadosPaginados empleadosPaginados =
          await _empleadoRepository.getEmpleados();
      _totalEmpleados = empleadosPaginados.empleados.length;
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando empleados: $e');
    } finally {
      _setLoadingEmpleados(false);
    }
  }

  Future<void> _loadEstadisticas() async {
    _setLoadingEstadisticas(true);
    try {
      final ResumenEstadisticas resumen =
          await _estadisticaRepository.getResumenEstadisticasTyped();
      _resumenEstadisticas = resumen;
      notifyListeners();
      await _loadUltimasVentas();
    } catch (e) {
      debugPrint('Error al procesar el resumen de estadísticas: $e');
    } finally {
      _setLoadingEstadisticas(false);
    }
  }

  Future<void> _loadUltimasVentas() async {
    _setLoadingVentasRecientes(true);
    try {
      debugPrint("Cargando últimas ventas...");
      final ultimasVentas = await _estadisticaRepository.getUltimasVentas();
      debugPrint("Últimas ventas cargadas:  ${ultimasVentas.length}");
      if (ultimasVentas.isNotEmpty) {
        _ventasRecientes = ultimasVentas.map((venta) {
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
        debugPrint("Ventas recientes procesadas:  ${_ventasRecientes.length}");
      } else {
        debugPrint("No se encontraron últimas ventas");
        _ventasRecientes = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar últimas ventas: $e');
      _ventasRecientes = [];
      notifyListeners();
    } finally {
      _setLoadingVentasRecientes(false);
    }
  }

  // Métodos para actualizar flags de loading
  void _setLoadingSucursales(bool value) {
    if (_isLoadingSucursales != value) {
      _isLoadingSucursales = value;
      notifyListeners();
    }
  }

  void _setLoadingProductos(bool value) {
    if (_isLoadingProductos != value) {
      _isLoadingProductos = value;
      notifyListeners();
    }
  }

  void _setLoadingEmpleados(bool value) {
    if (_isLoadingEmpleados != value) {
      _isLoadingEmpleados = value;
      notifyListeners();
    }
  }

  void _setLoadingEstadisticas(bool value) {
    if (_isLoadingEstadisticas != value) {
      _isLoadingEstadisticas = value;
      notifyListeners();
    }
  }

  void _setLoadingVentasRecientes(bool value) {
    if (_isLoadingVentasRecientes != value) {
      _isLoadingVentasRecientes = value;
      notifyListeners();
    }
  }

  /// Cambia la sucursal seleccionada y recarga los datos
  Future<void> cambiarSucursal(String sucursalId) async {
    if (sucursalId != _sucursalSeleccionadaId) {
      _sucursalSeleccionadaId = sucursalId;
      notifyListeners();
      _setLoading(true);
      try {
        await Future.wait([
          _loadProductos(),
          _loadEstadisticas(),
        ]);
      } finally {
        _setLoading(false);
      }
    }
  }

  /// Actualiza el estado de carga global
  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  /// Recarga todos los datos del dashboard
  Future<void> recargarDatos() async {
    _setLoading(true);
    try {
      await _loadData();
    } finally {
      _setLoading(false);
    }
  }
}

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
