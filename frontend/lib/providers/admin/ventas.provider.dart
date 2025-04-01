import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/models/ventas.model.dart';
import 'package:flutter/material.dart';

/// Provider para gestionar ventas y sucursales
class VentasProvider extends ChangeNotifier {
  // Estado para sucursales
  String _errorMessage = '';
  List<Sucursal> _sucursales = [];
  Sucursal? _sucursalSeleccionada;
  bool _isSucursalesLoading = false;

  // Estado para ventas
  List<dynamic> _ventas = [];
  bool _isVentasLoading = false;
  String _ventasErrorMessage = '';

  // Estado para detalles de venta
  Venta? _ventaSeleccionada;
  bool _isVentaDetalleLoading = false;
  String _ventaDetalleErrorMessage = '';

  // Getters para sucursales
  String get errorMessage => _errorMessage;
  List<Sucursal> get sucursales => _sucursales;
  Sucursal? get sucursalSeleccionada => _sucursalSeleccionada;
  bool get isSucursalesLoading => _isSucursalesLoading;

  // Getters para ventas
  List<dynamic> get ventas => _ventas;
  bool get isVentasLoading => _isVentasLoading;
  String get ventasErrorMessage => _ventasErrorMessage;

  // Getters para detalles de venta
  Venta? get ventaSeleccionada => _ventaSeleccionada;
  bool get isVentaDetalleLoading => _isVentaDetalleLoading;
  String get ventaDetalleErrorMessage => _ventaDetalleErrorMessage;

  /// Inicializa el provider cargando los datos necesarios
  void inicializar() {
    cargarSucursales();
  }

  /// Carga las sucursales disponibles
  Future<void> cargarSucursales() async {
    _isSucursalesLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      debugPrint('Cargando sucursales desde la API...');
      final data = await api.sucursales.getSucursales();

      debugPrint('Datos recibidos tipo: ${data.runtimeType}');
      debugPrint('Longitud de la lista: ${data.length}');
      if (data.isNotEmpty) {
        debugPrint('Primer elemento tipo: ${data.first.runtimeType}');
      }

      List<Sucursal> sucursalesParsed = [];

      // Procesamiento seguro de los datos
      for (var item in data) {
        try {
          // Si ya es un objeto Sucursal, lo usamos directamente
          sucursalesParsed.add(item);
        } catch (e) {
          debugPrint('Error al procesar sucursal: $e');
        }
      }

      // Ordenar por nombre
      sucursalesParsed.sort((a, b) => a.nombre.compareTo(b.nombre));

      debugPrint(
          'Sucursales cargadas correctamente: ${sucursalesParsed.length}');

      _sucursales = sucursalesParsed;
      _isSucursalesLoading = false;

      // Seleccionar la primera sucursal como predeterminada si hay sucursales
      if (_sucursales.isNotEmpty && _sucursalSeleccionada == null) {
        _sucursalSeleccionada = _sucursales.first;
        // Cargar ventas de la sucursal seleccionada por defecto
        cargarVentas();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar sucursales: $e');
      _isSucursalesLoading = false;
      _errorMessage = 'Error al cargar sucursales: $e';
      notifyListeners();
    }
  }

  /// Cambia la sucursal seleccionada
  void cambiarSucursal(Sucursal sucursal) {
    _sucursalSeleccionada = sucursal;
    notifyListeners();

    // Cargar ventas para la nueva sucursal seleccionada
    cargarVentas();
  }

  /// Limpia los mensajes de error
  void limpiarErrores() {
    _errorMessage = '';
    _ventasErrorMessage = '';
    _ventaDetalleErrorMessage = '';
    notifyListeners();
  }

  /// Carga las ventas de la sucursal seleccionada
  Future<void> cargarVentas() async {
    if (_sucursalSeleccionada == null) {
      _ventasErrorMessage = 'Debe seleccionar una sucursal';
      _ventas = [];
      notifyListeners();
      return;
    }

    _isVentasLoading = true;
    _ventasErrorMessage = '';
    notifyListeners();

    try {
      debugPrint('Cargando ventas para sucursal: ${_sucursalSeleccionada!.id}');
      final Map<String, dynamic> response = await api.ventas.getVentas(
        sucursalId: _sucursalSeleccionada!.id,
      );

      debugPrint(
          'Respuesta de ventas recibida, tipo de datos: ${response['data']?.runtimeType}');

      List<dynamic> ventasList = [];
      if (response['data'] != null) {
        if (response['data'] is List) {
          // Si los datos son una lista, los usamos directamente
          ventasList = response['data'];
          debugPrint(
              'Datos recibidos como lista: ${ventasList.length} elementos');

          // Si son Maps, los convertimos a objetos Venta
          if (ventasList.isNotEmpty &&
              ventasList.first is Map<String, dynamic>) {
            try {
              debugPrint('Convirtiendo Maps a objetos Venta');
              ventasList = ventasList
                  .map((item) => Venta.fromJson(item as Map<String, dynamic>))
                  .toList();
            } catch (e) {
              debugPrint('Error al convertir Maps a Venta: $e');
              // Si hay error, mantenemos los datos originales como Map
            }
          }
        } else if (response['ventasRaw'] != null &&
            response['ventasRaw'] is List) {
          // En caso de que la API ya haya convertido los datos pero también proporcione los datos raw
          ventasList = response['data'];
          debugPrint(
              'Usando datos procesados de la API: ${ventasList.length} elementos');
        }
      }

      _ventas = ventasList;
      _isVentasLoading = false;
      notifyListeners();

      debugPrint(
          'Ventas cargadas: ${_ventas.length}, tipo: ${_ventas.isNotEmpty ? _ventas.first.runtimeType : "N/A"}');
    } catch (e) {
      debugPrint('Error al cargar ventas: $e');
      _isVentasLoading = false;
      _ventasErrorMessage = 'Error al cargar ventas: $e';
      notifyListeners();
    }
  }

  /// Carga los detalles de una venta específica
  Future<Venta?> cargarDetalleVenta(String id) async {
    if (_sucursalSeleccionada == null) {
      _ventaDetalleErrorMessage = 'Debe seleccionar una sucursal';
      _ventaSeleccionada = null;
      notifyListeners();
      return null;
    }

    _isVentaDetalleLoading = true;
    _ventaDetalleErrorMessage = '';
    notifyListeners();

    try {
      debugPrint(
          'Cargando detalle de venta: $id para sucursal: ${_sucursalSeleccionada!.id}');

      final Venta? venta = await api.ventas.getVenta(
        id,
        sucursalId: _sucursalSeleccionada!.id,
        forceRefresh: true, // Forzar recarga para obtener datos actualizados
      );

      if (venta == null) {
        _ventaDetalleErrorMessage = 'No se pudo cargar la venta';
        _isVentaDetalleLoading = false;
        notifyListeners();
        return null;
      }

      _ventaSeleccionada = venta;
      _isVentaDetalleLoading = false;
      notifyListeners();

      debugPrint('Venta cargada: ${venta.id}');
      return venta;
    } catch (e) {
      debugPrint('Error al cargar detalle de venta: $e');
      _isVentaDetalleLoading = false;
      _ventaDetalleErrorMessage = 'Error al cargar detalle de venta: $e';
      notifyListeners();
      return null;
    }
  }
}
