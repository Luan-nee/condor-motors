import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/producto.model.dart';
import 'package:flutter/material.dart';

class DashboardComputerProvider extends ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';
  List<dynamic> _ultimasVentas = [];
  List<Map<String, dynamic>> _productosStockBajo = [];
  int? _sucursalId;
  String _nombreSucursal = 'Sucursal';

  // Estado de paginación
  Paginacion _paginacion = Paginacion(
    totalItems: 0,
    totalPages: 1,
    currentPage: 1,
    hasNext: false,
    hasPrev: false,
  );

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<dynamic> get ultimasVentas => _ultimasVentas;
  List<Map<String, dynamic>> get productosStockBajo => _productosStockBajo;
  int? get sucursalId => _sucursalId;
  String get nombreSucursal => _nombreSucursal;
  Paginacion get paginacion => _paginacion;

  /// Convierte un Producto a Map<String, dynamic>
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
      _setLoading(true);
      debugPrint('🔄 Inicializando DashboardComputerProvider...');

      // Obtener datos del usuario autenticado
      final userData = await api.auth.getUserData();
      if (userData == null) {
        throw Exception('No se encontraron datos del usuario autenticado');
      }

      debugPrint('👤 Datos de usuario obtenidos: ${userData.toString()}');

      // Extraer ID de sucursal del usuario y convertirlo a int
      final dynamic rawSucursalId = userData['sucursalId'];
      if (rawSucursalId == null) {
        throw Exception('El usuario no tiene una sucursal asignada');
      }

      // Convertir a int de manera segura
      if (rawSucursalId is int) {
        _sucursalId = rawSucursalId;
      } else if (rawSucursalId is String) {
        _sucursalId = int.tryParse(rawSucursalId);
        if (_sucursalId == null) {
          throw Exception('ID de sucursal inválido: $rawSucursalId');
        }
      } else {
        throw Exception(
            'Tipo de ID de sucursal no soportado: ${rawSucursalId.runtimeType}');
      }

      // Obtener nombre de la sucursal
      try {
        final sucursalData =
            await api.sucursales.getSucursalData(_sucursalId.toString());
        _nombreSucursal = sucursalData.nombre;
      } catch (e) {
        debugPrint('⚠️ No se pudo obtener el nombre de la sucursal: $e');
        _nombreSucursal = 'Sucursal $_sucursalId';
      }

      debugPrint(
          '🏢 Sucursal configurada: $_nombreSucursal (ID: $_sucursalId)');

      // Cargar datos iniciales
      await cargarDatos();
    } catch (e) {
      debugPrint('❌ Error en inicialización: $e');
      _errorMessage = 'Error al inicializar: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Carga los datos del dashboard
  Future<void> cargarDatos() async {
    if (_sucursalId == null) {
      _errorMessage = 'No hay una sucursal seleccionada';
      notifyListeners();
      return;
    }

    try {
      _setLoading(true);
      _errorMessage = '';

      // Cargar últimas ventas usando la API de ventas
      final ventasResponse = await api.ventas.getVentas(
        sucursalId: _sucursalId.toString(),
        pageSize: 5,
        forceRefresh: true,
      );

      // Procesar la respuesta
      if (ventasResponse['data'] != null && ventasResponse['data'] is List) {
        _ultimasVentas = ventasResponse['data'];
      }

      // Actualizar paginación si existe
      if (ventasResponse['pagination'] != null) {
        _paginacion = Paginacion.fromApiResponse(ventasResponse);
      }

      // Cargar solo productos con stock bajo
      try {
        final productosResponse = await api.productos.getProductos(
          sucursalId: _sucursalId.toString(),
          stockBajo: true,
          pageSize: 10, // Limitamos a 10 productos para el dashboard
        );

        _productosStockBajo = productosResponse.items
            .map((producto) => _productoToMap(producto))
            .toList();
        debugPrint(
            '✅ Productos con stock bajo cargados: ${_productosStockBajo.length}');
      } catch (e) {
        debugPrint('❌ Error al cargar productos con stock bajo: $e');
        _productosStockBajo = [];
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error al cargar datos: $e');
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
