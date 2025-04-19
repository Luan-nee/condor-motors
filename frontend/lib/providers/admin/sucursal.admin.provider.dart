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
  final List<String> tiposSucursal = ['Sucursal', 'Central'];
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

  /// Limpia el caché del repositorio y recarga los datos
  Future<void> limpiarCacheYRecargar() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Limpiar el caché del repositorio
      _sucursalRepository.invalidateCache();

      // Recargar los datos frescos
      await cargarSucursales();

      debugPrint('Caché de sucursales limpiado y datos recargados');
    } catch (e) {
      _errorMessage = 'Error al limpiar caché: $e';
      debugPrint('Error limpiando caché: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

      // Validar series y códigos únicos solo si se proporcionan
      if (data['serieFactura'] != null &&
          data['serieFactura'].toString().isNotEmpty) {
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

      if (data['serieBoleta'] != null &&
          data['serieBoleta'].toString().isNotEmpty) {
        if (!isSerieBoletaDisponible(data['serieBoleta']) &&
            (data['id'] == null ||
                _sucursales
                        .firstWhere((s) => s.serieBoleta == data['serieBoleta'])
                        .id !=
                    data['id'])) {
          return 'La serie de boleta ya está en uso';
        }
      }

      if (data['codigoEstablecimiento'] != null &&
          data['codigoEstablecimiento'].toString().isNotEmpty) {
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

      if (data['id'] != null) {
        // Estamos actualizando una sucursal existente
        // Buscar la sucursal actual para comparar cambios
        final sucursalId = data['id'].toString();
        final sucursalActual = _todasLasSucursales.firstWhere(
          (s) => s.id.toString() == sucursalId,
          orElse: () => throw Exception('Sucursal no encontrada'),
        );

        // Crear un mapa solo con los campos que han cambiado
        final Map<String, dynamic> camposModificados = {};

        // Nombre - convertir a string para comparar correctamente
        if (data['nombre'].toString() != sucursalActual.nombre) {
          camposModificados['nombre'] = data['nombre'].toString();
          debugPrint(
              'Campo nombre modificado: ${data['nombre']} != ${sucursalActual.nombre}');
        }

        // Dirección - usar toString y manejar posibles nulos
        final direccionNueva = data['direccion']?.toString() ?? '';
        final direccionActual = sucursalActual.direccion ?? '';
        if (direccionNueva != direccionActual) {
          // Solo incluir la dirección en los cambios si no está vacía o si explícitamente
          // se está cambiando de un valor a vacío
          if (direccionNueva.isNotEmpty ||
              (direccionActual.isNotEmpty && direccionNueva.isEmpty)) {
            camposModificados['direccion'] = direccionNueva;
            debugPrint(
                'Campo dirección modificado: $direccionNueva != $direccionActual');
          }
        }

        // Tipo de sucursal - convertir explícitamente a boolean
        final bool sucursalCentralNueva = data['sucursalCentral'] == true;
        if (sucursalCentralNueva != sucursalActual.sucursalCentral) {
          camposModificados['sucursalCentral'] = sucursalCentralNueva;
          debugPrint(
              'Campo sucursalCentral modificado: $sucursalCentralNueva != ${sucursalActual.sucursalCentral}');
        }

        // Serie Factura - comparar como strings
        final serieFacturaNueva = data['serieFactura']?.toString() ?? '';
        final serieFacturaActual = sucursalActual.serieFactura ?? '';
        if (serieFacturaNueva != serieFacturaActual) {
          // Solo incluir si no está vacía o si explícitamente se está cambiando de un valor a vacío
          if (serieFacturaNueva.isNotEmpty ||
              (serieFacturaActual.isNotEmpty && serieFacturaNueva.isEmpty)) {
            camposModificados['serieFactura'] = serieFacturaNueva;
            debugPrint(
                'Campo serieFactura modificado: $serieFacturaNueva != $serieFacturaActual');
          }
        }

        // Número Factura Inicial - convertir a entero para comparar
        final int? numeroFacturaInicialNuevo =
            data['numeroFacturaInicial'] != null
                ? int.parse(data['numeroFacturaInicial'].toString())
                : null;
        final int? numeroFacturaInicialActual =
            sucursalActual.numeroFacturaInicial;
        if (numeroFacturaInicialNuevo != numeroFacturaInicialActual) {
          if (numeroFacturaInicialNuevo != null) {
            camposModificados['numeroFacturaInicial'] =
                numeroFacturaInicialNuevo;
            debugPrint(
                'Campo numeroFacturaInicial modificado: $numeroFacturaInicialNuevo != $numeroFacturaInicialActual');
          }
        }

        // Serie Boleta - comparar como strings
        final serieBoletaNueva = data['serieBoleta']?.toString() ?? '';
        final serieBoletaActual = sucursalActual.serieBoleta ?? '';
        if (serieBoletaNueva != serieBoletaActual) {
          // Solo incluir si no está vacía o si explícitamente se está cambiando de un valor a vacío
          if (serieBoletaNueva.isNotEmpty ||
              (serieBoletaActual.isNotEmpty && serieBoletaNueva.isEmpty)) {
            camposModificados['serieBoleta'] = serieBoletaNueva;
            debugPrint(
                'Campo serieBoleta modificado: $serieBoletaNueva != $serieBoletaActual');
          }
        }

        // Número Boleta Inicial - convertir a entero para comparar
        final int? numeroBoletaInicialNuevo =
            data['numeroBoletaInicial'] != null
                ? int.parse(data['numeroBoletaInicial'].toString())
                : null;
        final int? numeroBoletaInicialActual =
            sucursalActual.numeroBoletaInicial;
        if (numeroBoletaInicialNuevo != numeroBoletaInicialActual) {
          if (numeroBoletaInicialNuevo != null) {
            camposModificados['numeroBoletaInicial'] = numeroBoletaInicialNuevo;
            debugPrint(
                'Campo numeroBoletaInicial modificado: $numeroBoletaInicialNuevo != $numeroBoletaInicialActual');
          }
        }

        // Código Establecimiento - comparar como strings
        final codigoEstablecimientoNuevo =
            data['codigoEstablecimiento']?.toString() ?? '';
        final codigoEstablecimientoActual =
            sucursalActual.codigoEstablecimiento ?? '';
        if (codigoEstablecimientoNuevo != codigoEstablecimientoActual) {
          // Solo incluir si no está vacía o si explícitamente se está cambiando de un valor a vacío
          if (codigoEstablecimientoNuevo.isNotEmpty ||
              (codigoEstablecimientoActual.isNotEmpty &&
                  codigoEstablecimientoNuevo.isEmpty)) {
            camposModificados['codigoEstablecimiento'] =
                codigoEstablecimientoNuevo;
            debugPrint(
                'Campo codigoEstablecimiento modificado: $codigoEstablecimientoNuevo != $codigoEstablecimientoActual');
          }
        }

        // Solo enviar la solicitud si hay campos modificados
        if (camposModificados.isNotEmpty) {
          debugPrint(
              'Enviando campos modificados: ${camposModificados.keys.join(', ')}');
          await _sucursalRepository.updateSucursal(
              sucursalId, camposModificados);
        } else {
          debugPrint(
              'No hay cambios que actualizar en la sucursal $sucursalId');
        }
      } else {
        // Es una nueva sucursal, enviar todos los datos
        final SucursalRequest request = SucursalRequest(
          nombre: data['nombre'],
          direccion: data['direccion'],
          sucursalCentral: data['sucursalCentral'] ?? false,
          serieFactura: data['serieFactura'] as String?,
          numeroFacturaInicial: data['numeroFacturaInicial'] as int?,
          serieBoleta: data['serieBoleta'] as String?,
          numeroBoletaInicial: data['numeroBoletaInicial'] as int?,
          codigoEstablecimiento: data['codigoEstablecimiento'] as String?,
        );

        await _sucursalRepository.createSucursal(request.toJson());
      }

      // Limpiar el caché después de la operación
      _sucursalRepository.invalidateCache();
      await cargarSucursales();

      debugPrint('Sucursal guardada y caché limpiado');
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

      // Limpiar el caché después de la operación
      _sucursalRepository.invalidateCache();
      await cargarSucursales();

      debugPrint('Sucursal eliminada y caché limpiado');
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
      // Priorizar la propiedad sucursalCentral
      if (sucursal.sucursalCentral) {
        grupos['Centrales']!.add(sucursal);
      }
      // Como respaldo, también considerar el nombre para compatibilidad
      else if (sucursal.nombre.toLowerCase().contains('central') ||
          sucursal.nombre.toLowerCase().contains('principal')) {
        grupos['Centrales']!.add(sucursal);
        // Registrar inconsistencia para depuración
        debugPrint(
            '⚠️ Sucursal con nombre de central pero no marcada como central: ${sucursal.nombre}');
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
  final String? direccion;
  final bool sucursalCentral;
  final String? serieFactura;
  final int? numeroFacturaInicial;
  final String? serieBoleta;
  final int? numeroBoletaInicial;
  final String? codigoEstablecimiento;

  SucursalRequest({
    required this.nombre,
    this.direccion,
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
      if (direccion != null && direccion!.isNotEmpty) 'direccion': direccion,
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
