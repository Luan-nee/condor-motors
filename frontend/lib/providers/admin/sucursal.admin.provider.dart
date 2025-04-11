import 'package:condorsmotors/models/sucursal.model.dart';
// Importar el repositorio
import 'package:condorsmotors/repositories/sucursal.repository.dart';
import 'package:flutter/material.dart';

/// Provider para gestionar sucursales
class SucursalProvider extends ChangeNotifier {
  // Instancia del repositorio de sucursales
  final SucursalRepository _sucursalRepository = SucursalRepository.instance;

  // Estado para sucursales
  bool _isLoading = false;
  List<Sucursal> _sucursales = [];
  String _errorMessage = '';
  List<Sucursal> _todasLasSucursales = [];
  String _terminoBusqueda = '';

  // Nuevos estados para ayuda en la interfaz
  final List<String> tiposSucursal = ['Local', 'Central'];
  final Map<String, String> prefijosDocumentos = {
    'factura': 'F',
    'boleta': 'B',
  };

  // Getters
  bool get isLoading => _isLoading;
  List<Sucursal> get sucursales => _sucursales;
  String get errorMessage => _errorMessage;
  String get terminoBusqueda => _terminoBusqueda;

  // Nuevos getters para ayuda en la interfaz
  List<String> get seriesFacturaDisponibles => _generarSeriesDisponibles('F');
  List<String> get seriesBoletaDisponibles => _generarSeriesDisponibles('B');
  List<String> get codigosEstablecimientoDisponibles =>
      _generarCodigosEstablecimiento();

  /// Inicializa el provider cargando los datos necesarios
  Future<void> inicializar() async {
    await cargarSucursales();
  }

  /// Genera series disponibles para documentos
  List<String> _generarSeriesDisponibles(String prefijo) {
    final Set<String> seriesUsadas = _sucursales
        .map((s) => prefijo == 'F' ? s.serieFactura : s.serieBoleta)
        .whereType<String>()
        .toSet();

    final List<String> seriesDisponibles = [];
    for (int i = 1; i <= 999; i++) {
      final String serie = '$prefijo${i.toString().padLeft(3, '0')}';
      if (!seriesUsadas.contains(serie)) {
        seriesDisponibles.add(serie);
      }
    }
    return seriesDisponibles;
  }

  /// Genera códigos de establecimiento disponibles
  List<String> _generarCodigosEstablecimiento() {
    final Set<String> codigosUsados = _sucursales
        .map((s) => s.codigoEstablecimiento)
        .whereType<String>()
        .toSet();

    final List<String> codigosDisponibles = [];
    for (int i = 1; i <= 999; i++) {
      final String codigo = 'E${i.toString().padLeft(3, '0')}';
      if (!codigosUsados.contains(codigo)) {
        codigosDisponibles.add(codigo);
      }
    }
    return codigosDisponibles;
  }

  /// Verifica si una serie de factura está disponible
  bool isSerieFacturaDisponible(String serie) {
    return !_sucursales.any((s) => s.serieFactura == serie);
  }

  /// Verifica si una serie de boleta está disponible
  bool isSerieBoletaDisponible(String serie) {
    return !_sucursales.any((s) => s.serieBoleta == serie);
  }

  /// Verifica si un código de establecimiento está disponible
  bool isCodigoEstablecimientoDisponible(String codigo) {
    return !_sucursales.any((s) => s.codigoEstablecimiento == codigo);
  }

  /// Obtiene el siguiente número disponible para facturas
  int getSiguienteNumeroFactura() {
    final List<int> numerosUsados =
        _sucursales.map((s) => s.numeroFacturaInicial ?? 1).toList();
    return numerosUsados.isEmpty
        ? 1
        : numerosUsados.reduce((a, b) => a > b ? a : b) + 1;
  }

  /// Obtiene el siguiente número disponible para boletas
  int getSiguienteNumeroBoleta() {
    final List<int> numerosUsados =
        _sucursales.map((s) => s.numeroBoletaInicial ?? 1).toList();
    return numerosUsados.isEmpty
        ? 1
        : numerosUsados.reduce((a, b) => a > b ? a : b) + 1;
  }

  /// Carga las sucursales disponibles
  Future<void> cargarSucursales() async {
    if (!_isLoading) {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
    }

    try {
      final List<Sucursal> sucursales =
          await _sucursalRepository.getSucursales();
      _todasLasSucursales = sucursales;
      _aplicarFiltroBusqueda();
    } catch (e) {
      _errorMessage = 'Error al cargar sucursales: $e';
      debugPrint('Error cargando sucursales: $e');
    } finally {
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

  /// Guarda una sucursal (nueva o actualizada) con validaciones mejoradas
  Future<String?> guardarSucursal(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Validaciones adicionales
      if (data['nombre']?.toString().trim().isEmpty ?? true) {
        return 'El nombre de la sucursal es requerido';
      }

      if (data['direccion']?.toString().trim().isEmpty ?? true) {
        return 'La dirección de la sucursal es requerida';
      }

      // Validar series y códigos únicos
      if (data['serieFactura'] != null) {
        if (!isSerieFacturaDisponible(data['serieFactura']) &&
            (data['id'] == null ||
                _sucursales
                        .firstWhere(
                            (s) => s.serieFactura == data['serieFactura'])
                        .id !=
                    data['id'])) {
          return 'La serie de factura ya está en uso';
        }
      }

      if (data['serieBoleta'] != null) {
        if (!isSerieBoletaDisponible(data['serieBoleta']) &&
            (data['id'] == null ||
                _sucursales
                        .firstWhere((s) => s.serieBoleta == data['serieBoleta'])
                        .id !=
                    data['id'])) {
          return 'La serie de boleta ya está en uso';
        }
      }

      if (data['codigoEstablecimiento'] != null) {
        if (!isCodigoEstablecimientoDisponible(data['codigoEstablecimiento']) &&
            (data['id'] == null ||
                _sucursales
                        .firstWhere((s) =>
                            s.codigoEstablecimiento ==
                            data['codigoEstablecimiento'])
                        .id !=
                    data['id'])) {
          return 'El código de establecimiento ya está en uso';
        }
      }

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
        await _sucursalRepository.updateSucursal(
            data['id'].toString(), request.toJson());
      } else {
        await _sucursalRepository.createSucursal(request.toJson());
      }

      await cargarSucursales();
      return null;
    } catch (e) {
      return 'Error al guardar sucursal: $e';
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
      await _sucursalRepository.deleteSucursal(sucursal.id.toString());
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
