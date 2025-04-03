import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:flutter/material.dart';

/// Provider para gestionar sucursales
class SucursalProvider extends ChangeNotifier {
  // Estado para sucursales
  bool _isLoading = false;
  List<Sucursal> _sucursales = [];
  String _errorMessage = '';
  List<Sucursal> _todasLasSucursales = [];
  String _terminoBusqueda = '';

  // Getters
  bool get isLoading => _isLoading;
  List<Sucursal> get sucursales => _sucursales;
  String get errorMessage => _errorMessage;
  String get terminoBusqueda => _terminoBusqueda;

  /// Inicializa el provider cargando los datos necesarios
  void inicializar() {
    cargarSucursales();
  }

  /// Carga las sucursales disponibles
  Future<void> cargarSucursales() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final List<Sucursal> sucursales = await api.sucursales.getSucursales();

      _todasLasSucursales = sucursales;
      _aplicarFiltroBusqueda();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar sucursales: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Aplica el filtro de búsqueda a las sucursales
  void _aplicarFiltroBusqueda() {
    if (_terminoBusqueda.isEmpty) {
      _sucursales = List.from(_todasLasSucursales);
      return;
    }

    final String termino = _terminoBusqueda.toLowerCase();
    _sucursales = _todasLasSucursales.where((Sucursal sucursal) {
      final bool nombreMatch = sucursal.nombre.toLowerCase().contains(termino);
      final bool direccionMatch =
          sucursal.direccion?.toLowerCase().contains(termino) ?? false;
      return nombreMatch || direccionMatch;
    }).toList();
  }

  /// Actualiza el término de búsqueda y filtra las sucursales
  void actualizarBusqueda(String termino) {
    _terminoBusqueda = termino;
    _aplicarFiltroBusqueda();
    notifyListeners();
  }

  /// Limpia el término de búsqueda
  void limpiarBusqueda() {
    _terminoBusqueda = '';
    _aplicarFiltroBusqueda();
    notifyListeners();
  }

  /// Guarda una sucursal (nueva o actualizada)
  Future<String?> guardarSucursal(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final SucursalRequest request = SucursalRequest(
        nombre: data['nombre'],
        direccion: data['direccion'] ?? '',
        sucursalCentral: data['sucursalCentral'] ?? false,
        serieFactura: data['serieFactura'] as String?,
        numeroFacturaInicial: data['numeroFacturaInicial'] as int?,
        serieBoleta: data['serieBoleta'] as String?,
        numeroBoletaInicial: data['numeroBoletaInicial'] as int?,
        codigoEstablecimiento: data['codigoEstablecimiento'] as String?,
      );

      if (data['id'] != null) {
        await api.sucursales
            .updateSucursal(data['id'].toString(), request.toJson());
      } else {
        await api.sucursales.createSucursal(request.toJson());
      }

      await cargarSucursales();
      return null; // Sin error
    } catch (e) {
      return 'Error al guardar sucursal: $e'; // Devuelve el mensaje de error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Elimina una sucursal
  Future<String?> eliminarSucursal(Sucursal sucursal) async {
    _isLoading = true;
    notifyListeners();

    try {
      await api.sucursales.deleteSucursal(sucursal.id.toString());
      await cargarSucursales();
      return null; // Sin error
    } catch (e) {
      return 'Error al eliminar sucursal: $e'; // Devuelve el mensaje de error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Agrupa sucursales por tipo (central/no central)
  Map<String, List<Sucursal>> agruparSucursales() {
    final Map<String, List<Sucursal>> grupos = {
      'centrales': [],
      'noCentrales': [],
    };

    for (final Sucursal sucursal in _sucursales) {
      if (sucursal.sucursalCentral) {
        grupos['centrales']!.add(sucursal);
      } else {
        grupos['noCentrales']!.add(sucursal);
      }
    }

    return grupos;
  }

  /// Agrupa sucursales por tipo según nombre y atributos
  Map<String, List<Sucursal>> agruparSucursalesPorTipo(
      {List<Sucursal>? sucursales}) {
    final Map<String, List<Sucursal>> grupos = {
      'Centrales': [],
      'Sucursales': [],
    };

    final List<Sucursal> listaSucursales = sucursales ?? _sucursales;

    for (final Sucursal sucursal in listaSucursales) {
      if (sucursal.nombre.toLowerCase().contains('central') ||
          sucursal.nombre.toLowerCase().contains('principal') ||
          sucursal.sucursalCentral) {
        grupos['Centrales']!.add(sucursal);
      } else {
        grupos['Sucursales']!.add(sucursal);
      }
    }

    // Ordenamos por nombre dentro de cada grupo
    grupos['Centrales']!
        .sort((Sucursal a, Sucursal b) => a.nombre.compareTo(b.nombre));
    grupos['Sucursales']!
        .sort((Sucursal a, Sucursal b) => a.nombre.compareTo(b.nombre));

    return grupos;
  }

  /// Limpia los mensajes de error
  void limpiarErrores() {
    _errorMessage = '';
    notifyListeners();
  }
}

// Clase para la solicitud de creación/actualización de sucursal
class SucursalRequest {
  final String nombre;
  final String direccion;
  final bool sucursalCentral;
  final String? serieFactura;
  final int? numeroFacturaInicial;
  final String? serieBoleta;
  final int? numeroBoletaInicial;
  final String? codigoEstablecimiento;

  SucursalRequest({
    required this.nombre,
    required this.direccion,
    required this.sucursalCentral,
    this.serieFactura,
    this.numeroFacturaInicial,
    this.serieBoleta,
    this.numeroBoletaInicial,
    this.codigoEstablecimiento,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nombre': nombre,
      'direccion': direccion,
      'sucursalCentral': sucursalCentral,
      if (serieFactura != null && serieFactura!.isNotEmpty)
        'serieFactura': serieFactura,
      if (numeroFacturaInicial != null)
        'numeroFacturaInicial': numeroFacturaInicial,
      if (serieBoleta != null && serieBoleta!.isNotEmpty)
        'serieBoleta': serieBoleta,
      if (numeroBoletaInicial != null)
        'numeroBoletaInicial': numeroBoletaInicial,
      if (codigoEstablecimiento != null && codigoEstablecimiento!.isNotEmpty)
        'codigoEstablecimiento': codigoEstablecimiento,
    };
  }
}
