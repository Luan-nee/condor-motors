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

  // Datos del dashboard
  List<Sucursal> _sucursales = [];
  List<dynamic> _productos = [];
  List<Map<String, dynamic>> _productosStockBajoDetalle = [];
  double _totalVentas = 0;
  double _totalGanancias = 0;
  double _ventasHoy = 0;
  double _ingresosHoy = 0;
  int _totalEmpleados = 0;
  int _productosStockBajo = 0;
  int _productosAgotados = 0;
  int _productosLiquidacion = 0;
  List<VentaReciente> _ventasRecientes = [];

  // Datos para gráficos
  final List<double> _ventasMensuales = [];

  // Mapa para agrupar productos por sucursal
  Map<String, List<dynamic>> _productosPorSucursal = {};

  // Estadísticas por sucursal
  final Map<String, Map<String, dynamic>> _estadisticasSucursales = {};

  // Resumen completo de estadísticas
  ResumenEstadisticas? _resumenEstadisticas;

  // Getters
  bool get isLoading => _isLoading;
  String get sucursalSeleccionadaId => _sucursalSeleccionadaId;
  List<Sucursal> get sucursales => _sucursales;
  List<dynamic> get productos => _productos;
  List<Map<String, dynamic>> get productosStockBajoDetalle =>
      _productosStockBajoDetalle;
  double get totalVentas => _totalVentas;
  double get totalGanancias => _totalGanancias;
  double get ventasHoy => _ventasHoy;
  double get ingresosHoy => _ingresosHoy;
  int get totalEmpleados => _totalEmpleados;
  int get productosStockBajo => _productosStockBajo;
  int get productosAgotados => _productosAgotados;
  int get productosLiquidacion => _productosLiquidacion;
  Map<String, List<dynamic>> get productosPorSucursal => _productosPorSucursal;
  List<double> get ventasMensuales => _ventasMensuales;
  List<VentaReciente> get ventasRecientes => _ventasRecientes;
  Map<String, Map<String, dynamic>> get estadisticasSucursales =>
      _estadisticasSucursales;
  ResumenEstadisticas? get resumenEstadisticas => _resumenEstadisticas;

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
      // Cargar sucursales primero usando el repositorio
      final List<Sucursal> sucursalesResponse =
          await _sucursalRepository.getSucursales();

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
          _loadEstadisticas(),
        ]);
      }
    } catch (e) {
      debugPrint('Error cargando datos iniciales: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Carga los productos para todas las sucursales
  Future<void> _loadProductos() async {
    try {
      // Mapa para organizar productos por sucursal
      final Map<String, List<dynamic>> productosBySucursal = {};

      // Inicializar listas vacías para cada sucursal
      for (Sucursal sucursal in _sucursales) {
        productosBySucursal[sucursal.id.toString()] = [];
      }

      // Cargar productos para la sucursal seleccionada primero usando el repositorio
      final PaginatedResponse<dynamic> paginatedProductos =
          await _productoRepository.getProductos(
        sucursalId: _sucursalSeleccionadaId,
        pageSize: 100, // Aumentar límite para tener más datos precisos
      );

      int agotados = 0;

      // Procesar los datos de productos de la sucursal seleccionada
      for (dynamic producto in paginatedProductos.items) {
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

  /// Carga los empleados
  Future<void> _loadEmpleados() async {
    try {
      final EmpleadosPaginados empleadosPaginados =
          await _empleadoRepository.getEmpleados();
      _totalEmpleados = empleadosPaginados.empleados.length;
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando empleados: $e');
    }
  }

  /// Carga estadísticas de ventas y productos
  Future<void> _loadEstadisticas() async {
    try {
      try {
        final ResumenEstadisticas resumen =
            await _estadisticaRepository.getResumenEstadisticasTyped();

        // Almacenar el resumen completo
        _resumenEstadisticas = resumen;

        // Procesar estadísticas de productos
        _productosStockBajo = resumen.productos.stockBajo;
        _productosLiquidacion = resumen.productos.liquidacion;

        // Procesar estadísticas de ventas usando los métodos seguros
        final ventasHoy = resumen.ventas.getVentasValue('hoy');
        final ventasEsteMes = resumen.ventas.getVentasValue('esteMes');
        final totalVentasHoy = resumen.ventas.getTotalVentasValue('hoy');
        final totalVentasEsteMes =
            resumen.ventas.getTotalVentasValue('esteMes');

        _ventasHoy = ventasHoy;
        _totalVentas = ventasEsteMes;
        _ingresosHoy = totalVentasHoy;
        _totalGanancias = totalVentasEsteMes;

        // Procesar estadísticas por sucursal (productos)
        for (final sucursalStat in resumen.productos.sucursales) {
          _estadisticasSucursales[sucursalStat.id.toString()] = {
            'stockBajo': sucursalStat.stockBajo,
            'liquidacion': sucursalStat.liquidacion,
          };
        }

        // Para productos con stock bajo simplemente cargaremos los datos resumidos
        // No necesitamos cargar detalles específicos ya que usaremos directamente el resumen
        debugPrint("Cargando datos resumidos de productos con stock bajo");
        _productosStockBajoDetalle = []; // Limpiamos detalles anteriores

        // Cargar las últimas ventas
        try {
          debugPrint("Cargando últimas ventas...");
          final ultimasVentas = await _estadisticaRepository.getUltimasVentas();
          debugPrint("Últimas ventas cargadas: ${ultimasVentas.length}");

          if (ultimasVentas.isNotEmpty) {
            // Convertir las últimas ventas al formato necesario para el widget
            _ventasRecientes = ultimasVentas.map((venta) {
              // Formatear la fecha y hora
              final fechaFormateada =
                  venta.fechaEmision != null && venta.horaEmision != null
                      ? "${venta.fechaEmision} ${venta.horaEmision}"
                      : "Fecha no disponible";

              // Formatear la factura
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

            debugPrint(
                "Ventas recientes procesadas: ${_ventasRecientes.length}");
          } else {
            debugPrint("No se encontraron últimas ventas");
            _ventasRecientes = [];
          }
        } catch (e) {
          debugPrint('Error al cargar últimas ventas: $e');
          _ventasRecientes = [];
        }

        notifyListeners();
      } catch (e) {
        debugPrint('Error al procesar el resumen de estadísticas: $e');
      }
    } catch (e) {
      debugPrint('Error al cargar estadísticas: $e');
    }
  }

  /// Carga los detalles de productos con stock bajo para mostrar en la tabla
  Future<void> _loadProductosStockBajoDetalle() async {
    try {
      debugPrint("Cargando detalles de productos con stock bajo...");
      _productosStockBajoDetalle = [];

      // Obtener productos con stock bajo
      final stockBajoResponse =
          await _estadisticaRepository.getProductosStockBajo(
        forceRefresh: true,
      );

      if (stockBajoResponse['status'] == 'success' &&
          stockBajoResponse['data'] != null) {
        final productosData = stockBajoResponse['data'];

        // Actualizar contadores globales
        _productosStockBajo = productosData['stockBajo'] is int
            ? productosData['stockBajo']
            : int.tryParse(productosData['stockBajo'].toString()) ?? 0;

        _productosLiquidacion = productosData['liquidacion'] is int
            ? productosData['liquidacion']
            : int.tryParse(productosData['liquidacion'].toString()) ?? 0;

        // Obtener detalles de productos con stock bajo usando el nuevo método
        final detallesProductos =
            await _estadisticaRepository.getDetallesProductosStockBajo(
          forceRefresh: true,
        );

        if (detallesProductos.isNotEmpty) {
          _productosStockBajoDetalle = detallesProductos;
          debugPrint(
              "Productos con stock bajo encontrados: ${_productosStockBajoDetalle.length}");
        } else {
          debugPrint(
              "No se encontraron detalles de productos, generando datos basados en estadísticas");

          // Si no hay detalles, generar datos a partir de las estadísticas generales
          if (productosData['sucursales'] != null &&
              productosData['sucursales'] is List) {
            for (final sucursal in productosData['sucursales']) {
              final String sucursalId = sucursal['id'].toString();
              final String sucursalNombre = sucursal['nombre'] ?? 'Sucursal';
              final int stockBajo = sucursal['stockBajo'] is int
                  ? sucursal['stockBajo']
                  : int.tryParse(sucursal['stockBajo'].toString()) ?? 0;

              // Si hay productos con stock bajo en esta sucursal
              if (stockBajo > 0) {
                _productosStockBajoDetalle.add({
                  'productoId': 'placeholder-$sucursalId',
                  'productoNombre': '$stockBajo producto(s) con stock bajo',
                  'stock': 1,
                  'stockMinimo': 10,
                  'sucursalId': sucursalId,
                  'sucursalNombre': sucursalNombre,
                  'categoria': 'Variadas',
                  'marca': 'Varias marcas',
                });
              }
            }
          }
        }
      } else {
        debugPrint("Error al obtener datos de productos con stock bajo");
      }

      // Ordenar por stock (menor primero)
      if (_productosStockBajoDetalle.isNotEmpty) {
        _productosStockBajoDetalle
            .sort((a, b) => (a['stock'] as int).compareTo(b['stock'] as int));
      }

      debugPrint(
          "Productos con stock bajo cargados: ${_productosStockBajoDetalle.length}");
    } catch (e) {
      debugPrint('Error al cargar detalles de productos con stock bajo: $e');
    }
  }

  /// Obtiene el promedio de ventas de los últimos meses
  double getVentasPromedio() {
    if (_ventasMensuales.isEmpty) {
      return 0;
    }
    return _ventasMensuales.reduce((a, b) => a + b) / _ventasMensuales.length;
  }

  /// Calcula el porcentaje de crecimiento comparando el último mes con el anterior
  String getCrecimientoPorcentual() {
    if (_ventasMensuales.length < 2) {
      return "0%";
    }

    final double ultimoMes = _ventasMensuales.last;
    final double penultimoMes = _ventasMensuales[_ventasMensuales.length - 2];

    if (penultimoMes == 0) {
      return "N/A";
    }

    final double crecimiento =
        ((ultimoMes - penultimoMes) / penultimoMes) * 100;
    return "${crecimiento.toStringAsFixed(1)}%";
  }

  /// Proyecta las ventas para el próximo mes basado en la tendencia actual
  double getProyeccionVentas() {
    if (_ventasMensuales.isEmpty) {
      return 0;
    }

    if (_ventasMensuales.length == 1) {
      return _ventasMensuales.first;
    }

    // Usamos una proyección lineal simple basada en los últimos dos meses
    final double ultimoMes = _ventasMensuales.last;
    final double penultimoMes = _ventasMensuales[_ventasMensuales.length - 2];
    final double tendencia = ultimoMes - penultimoMes;

    // Proyección conservadora
    return ultimoMes + (tendencia > 0 ? tendencia : 0);
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

  /// Actualiza el estado de carga
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
