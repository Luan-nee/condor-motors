import 'dart:math' as math;

import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/empleado.model.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:flutter/material.dart';

/// Provider para el dashboard de administración
class DashboardProvider extends ChangeNotifier {
  // Estado
  bool _isLoading = true;
  String _sucursalSeleccionadaId = '';

  // Datos del dashboard
  List<Sucursal> _sucursales = [];
  List<Producto> _productos = [];
  double _totalVentas = 0;
  double _totalGanancias = 0;
  int _totalEmpleados = 0;
  int _productosAgotados = 0;

  // Datos para gráficos
  final List<double> _ventasMensuales = [];

  // Mapa para agrupar productos por sucursal
  Map<String, List<Producto>> _productosPorSucursal = {};

  // Getters
  bool get isLoading => _isLoading;
  String get sucursalSeleccionadaId => _sucursalSeleccionadaId;
  List<Sucursal> get sucursales => _sucursales;
  List<Producto> get productos => _productos;
  double get totalVentas => _totalVentas;
  double get totalGanancias => _totalGanancias;
  int get totalEmpleados => _totalEmpleados;
  int get productosAgotados => _productosAgotados;
  Map<String, List<Producto>> get productosPorSucursal => _productosPorSucursal;
  List<double> get ventasMensuales => _ventasMensuales;

  /// Inicializa el provider cargando todos los datos necesarios
  void inicializar() {
    _loadData();
  }

  /// Carga todos los datos del dashboard
  Future<void> _loadData() async {
    setLoading(true);

    try {
      // Cargar sucursales primero
      final List<Sucursal> sucursalesResponse =
          await api.sucursales.getSucursales();

      final List<Sucursal> sucursalesList = [];
      final List<Sucursal> centralesList = [];

      for (Sucursal sucursal in sucursalesResponse) {
        sucursalesList.add(sucursal);
        if (sucursal.sucursalCentral) {
          centralesList.add(sucursal);
        }
      }

      // Guardamos las sucursales primero para que estén disponibles en otros métodos
      _sucursales = sucursalesList;

      // Establecer la sucursal seleccionada: central si existe, o la primera disponible
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
          _loadVentasStats(),
        ]);
      }

      setLoading(false);
    } catch (e) {
      debugPrint('Error cargando datos iniciales: $e');
      setLoading(false);
    }
  }

  /// Carga los productos para todas las sucursales
  Future<void> _loadProductos() async {
    try {
      // Mapa para organizar productos por sucursal
      final Map<String, List<Producto>> productosBySucursal = {};

      // Inicializar listas vacías para cada sucursal
      for (Sucursal sucursal in _sucursales) {
        productosBySucursal[sucursal.id.toString()] = [];
      }

      // Cargar productos para la sucursal seleccionada primero
      final PaginatedResponse<Producto> paginatedProductos =
          await api.productos.getProductos(
        sucursalId: _sucursalSeleccionadaId,
        pageSize: 100, // Aumentar límite para tener más datos precisos
      );

      int agotados = 0;

      // Procesar los datos de productos de la sucursal seleccionada
      for (Producto producto in paginatedProductos.items) {
        if (producto.stock <= 0) {
          agotados++;
        }

        // Agregar al mapa de productos por sucursal
        if (productosBySucursal.containsKey(_sucursalSeleccionadaId)) {
          productosBySucursal[_sucursalSeleccionadaId]!.add(producto);
        }
      }

      // Cargar productos para todas las sucursales en paralelo
      final List<Future<void>> futures = [];

      for (Sucursal sucursal in _sucursales) {
        if (sucursal.id.toString() != _sucursalSeleccionadaId) {
          futures.add(_loadProductosPorSucursal(sucursal, productosBySucursal));
        }
      }

      // Esperar a que todas las cargas terminen
      await Future.wait(futures);

      _productos = paginatedProductos.items;
      _productosAgotados = agotados;
      _productosPorSucursal = productosBySucursal;
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando productos: $e');
    }
  }

  /// Carga productos para una sucursal específica
  Future<void> _loadProductosPorSucursal(Sucursal sucursal,
      Map<String, List<Producto>> productosBySucursal) async {
    try {
      final PaginatedResponse<Producto> sucProducts =
          await api.productos.getProductos(
        sucursalId: sucursal.id.toString(),
        pageSize: 100, // Aumentar límite para tener más datos precisos
      );
      productosBySucursal[sucursal.id.toString()] = sucProducts.items;
    } catch (e) {
      debugPrint('Error cargando productos para sucursal ${sucursal.id}: $e');
      // En caso de error, mantenemos la lista vacía
      productosBySucursal[sucursal.id.toString()] = [];
    }
  }

  /// Carga los empleados
  Future<void> _loadEmpleados() async {
    try {
      final List<Empleado> empleados = await api.empleados.getEmpleados();
      _totalEmpleados = empleados.length;
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando empleados: $e');
    }
  }

  /// Carga estadísticas de ventas (simulado)
  Future<void> _loadVentasStats() async {
    try {
      // Simulando datos de ventas mensuales
      // En una implementación real, estos datos vendrían de la API
      _ventasMensuales.clear();
      final math.Random random = math.Random();

      // Base de ventas con patrón creciente y algunas fluctuaciones
      final double baseVentas = 3500.0;
      final double maxFluctuacion = 800.0;
      final double tendenciaCrecimiento = 300.0;

      // Generar datos para los últimos 7 meses
      for (int i = 0; i < 6; i++) {
        final double ventaMes = baseVentas +
            (tendenciaCrecimiento * i) +
            (random.nextDouble() * maxFluctuacion - maxFluctuacion / 2);
        _ventasMensuales.add(ventaMes);
      }

      // El mes actual (simulado como algo mayor para mostrar crecimiento)
      _totalVentas = baseVentas +
          (tendenciaCrecimiento * 6) +
          (random.nextDouble() * maxFluctuacion);
      _ventasMensuales.add(_totalVentas);

      // Calcular ganancias (30% de las ventas)
      _totalGanancias = _totalVentas * 0.3;

      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando estadísticas de ventas: $e');
    }
  }

  /// Obtiene el promedio de ventas de los últimos meses
  double getVentasPromedio() {
    if (_ventasMensuales.isEmpty) return 0;
    return _ventasMensuales.reduce((a, b) => a + b) / _ventasMensuales.length;
  }

  /// Calcula el porcentaje de crecimiento comparando el último mes con el anterior
  String getCrecimientoPorcentual() {
    if (_ventasMensuales.length < 2) return "0%";

    final double ultimoMes = _ventasMensuales.last;
    final double penultimoMes = _ventasMensuales[_ventasMensuales.length - 2];

    final double crecimiento =
        ((ultimoMes - penultimoMes) / penultimoMes) * 100;

    return "${crecimiento.toStringAsFixed(1)}%";
  }

  /// Proyecta las ventas para el próximo mes basado en la tendencia
  double getProyeccionVentas() {
    if (_ventasMensuales.length < 2) return _totalVentas;

    // Usamos una proyección lineal simple basada en los últimos dos meses
    final double ultimoMes = _ventasMensuales.last;
    final double penultimoMes = _ventasMensuales[_ventasMensuales.length - 2];
    final double tendencia = ultimoMes - penultimoMes;

    // Proyección con un poco de optimismo (+10%)
    return ultimoMes + tendencia * 1.1;
  }

  /// Cambia la sucursal seleccionada y recarga los datos
  Future<void> cambiarSucursal(String sucursalId) async {
    if (sucursalId != _sucursalSeleccionadaId) {
      _sucursalSeleccionadaId = sucursalId;
      notifyListeners();

      await Future.wait([
        _loadProductos(),
        _loadVentasStats(),
      ]);
    }
  }

  /// Actualiza el estado de carga y notifica a los listeners
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Recarga todos los datos del dashboard
  Future<void> recargarDatos() async {
    await _loadData();
  }
}

// Un modelo básico para el widget de estadísticas del Dashboard
class DashboardItemInfo {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color bgColor;

  DashboardItemInfo({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.bgColor,
  });
}
