import 'dart:async';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/sucursal.repository.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sucursal.admin.riverpod.g.dart';

class SucursalAdminState {
  final bool isLoading;
  final List<Sucursal> sucursales;
  final String errorMessage;
  final List<Sucursal> todasLasSucursales;
  final String terminoBusqueda;

  SucursalAdminState({
    this.isLoading = false,
    this.sucursales = const [],
    this.errorMessage = '',
    this.todasLasSucursales = const [],
    this.terminoBusqueda = '',
  });

  SucursalAdminState copyWith({
    bool? isLoading,
    List<Sucursal>? sucursales,
    String? errorMessage,
    List<Sucursal>? todasLasSucursales,
    String? terminoBusqueda,
  }) {
    return SucursalAdminState(
      isLoading: isLoading ?? this.isLoading,
      sucursales: sucursales ?? this.sucursales,
      errorMessage: errorMessage ?? this.errorMessage,
      todasLasSucursales: todasLasSucursales ?? this.todasLasSucursales,
      terminoBusqueda: terminoBusqueda ?? this.terminoBusqueda,
    );
  }
}

@riverpod
class SucursalAdmin extends _$SucursalAdmin {
  late final SucursalRepository _sucursalRepository;

  @override
  SucursalAdminState build() {
    _sucursalRepository = SucursalRepository.instance;
    return SucursalAdminState();
  }

  Future<void> inicializar() async {
    await cargarSucursales();
  }

  List<String> getSeriesFacturaDisponibles() => _generarSeriesDisponibles('F');
  List<String> getSeriesBoletaDisponibles() => _generarSeriesDisponibles('B');
  List<String> getCodigosEstablecimientoDisponibles() =>
      _generarCodigosEstablecimiento();

  List<String> _generarSeriesDisponibles(String prefijo) {
    final Set<String> seriesUsadas = state.todasLasSucursales
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

  List<String> _generarCodigosEstablecimiento() {
    final Set<String> codigosUsados = state.todasLasSucursales
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

  int getSiguienteNumeroFactura() {
    final List<int> numerosUsados = state.todasLasSucursales
        .map((s) => s.numeroFacturaInicial ?? 1)
        .toList();
    return numerosUsados.isEmpty
        ? 1
        : numerosUsados.reduce((a, b) => a > b ? a : b) + 1;
  }

  int getSiguienteNumeroBoleta() {
    final List<int> numerosUsados = state.todasLasSucursales
        .map((s) => s.numeroBoletaInicial ?? 1)
        .toList();
    return numerosUsados.isEmpty
        ? 1
        : numerosUsados.reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<void> cargarSucursales() async {
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final List<Sucursal> sucursales =
          await _sucursalRepository.getSucursales();
      state = state.copyWith(
        todasLasSucursales: sucursales,
        isLoading: false,
      );
      _aplicarFiltroBusqueda();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al cargar sucursales: $e',
        isLoading: false,
      );
      debugPrint('Error cargando sucursales: $e');
    }
  }

  void _aplicarFiltroBusqueda() {
    if (state.terminoBusqueda.isEmpty) {
      state = state.copyWith(sucursales: List.from(state.todasLasSucursales));
      return;
    }

    final String termino = state.terminoBusqueda.toLowerCase();
    final filtered = state.todasLasSucursales.where((Sucursal sucursal) {
      final bool nombreMatch = sucursal.nombre.toLowerCase().contains(termino);
      final bool direccionMatch =
          sucursal.direccion?.toLowerCase().contains(termino) ?? false;
      return nombreMatch || direccionMatch;
    }).toList();
    state = state.copyWith(sucursales: filtered);
  }

  void actualizarBusqueda(String termino) {
    state = state.copyWith(terminoBusqueda: termino);
    _aplicarFiltroBusqueda();
  }

  void limpiarBusqueda() {
    state = state.copyWith(terminoBusqueda: '');
    _aplicarFiltroBusqueda();
  }

  Future<void> limpiarCacheYRecargar() async {
    state = state.copyWith(isLoading: true);
    try {
      _sucursalRepository.invalidateCache();
      await cargarSucursales();
      debugPrint('Caché de sucursales limpiado y datos recargados');
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al limpiar caché: $e',
        isLoading: false,
      );
      debugPrint('Error limpiando caché: $e');
    }
  }

  Future<String?> guardarSucursal(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);

    try {
      final String? validationError = Sucursal.validateSucursalData(data);
      if (validationError != null) {
        state = state.copyWith(isLoading: false);
        return validationError;
      }

      if (data['serieFactura']?.toString().isNotEmpty ?? false) {
        if (!Sucursal.isSerieFacturaDisponible(
            data['serieFactura'], state.todasLasSucursales,
            excludeId: data['id'])) {
          state = state.copyWith(isLoading: false);
          return 'La serie de factura ya está en uso';
        }
      }

      if (data['serieBoleta']?.toString().isNotEmpty ?? false) {
        if (!Sucursal.isSerieBoletaDisponible(
            data['serieBoleta'], state.todasLasSucursales,
            excludeId: data['id'])) {
          state = state.copyWith(isLoading: false);
          return 'La serie de boleta ya está en uso';
        }
      }

      if (data['codigoEstablecimiento']?.toString().isNotEmpty ?? false) {
        if (!Sucursal.isCodigoEstablecimientoDisponible(
            data['codigoEstablecimiento'], state.todasLasSucursales,
            excludeId: data['id'])) {
          state = state.copyWith(isLoading: false);
          return 'El código de establecimiento ya está en uso';
        }
      }

      if (data['id'] != null) {
        final sucursalId = data['id'].toString();
        final sucursalActual = state.todasLasSucursales.firstWhere(
          (s) => s.id.toString() == sucursalId,
          orElse: () => throw Exception('Sucursal no encontrada'),
        );

        final Map<String, dynamic> camposModificados = {};

        if (data['nombre'].toString() != sucursalActual.nombre) {
          camposModificados['nombre'] = data['nombre'].toString();
        }

        final direccionNueva = data['direccion']?.toString() ?? '';
        final direccionActual = sucursalActual.direccion ?? '';
        if (direccionNueva != direccionActual) {
          if (direccionNueva.isNotEmpty ||
              (direccionActual.isNotEmpty && direccionNueva.isEmpty)) {
            camposModificados['direccion'] = direccionNueva;
          }
        }

        final bool sucursalCentralNueva = data['sucursalCentral'] == true;
        if (sucursalCentralNueva != sucursalActual.sucursalCentral) {
          camposModificados['sucursalCentral'] = sucursalCentralNueva;
        }

        final serieFacturaNueva = data['serieFactura']?.toString() ?? '';
        final serieFacturaActual = sucursalActual.serieFactura ?? '';
        if (serieFacturaNueva != serieFacturaActual) {
          if (serieFacturaNueva.isNotEmpty ||
              (serieFacturaActual.isNotEmpty && serieFacturaNueva.isEmpty)) {
            camposModificados['serieFactura'] = serieFacturaNueva;
          }
        }

        final int? numeroFacturaInicialNuevo =
            data['numeroFacturaInicial'] != null
                ? int.tryParse(data['numeroFacturaInicial'].toString())
                : null;
        if (numeroFacturaInicialNuevo != sucursalActual.numeroFacturaInicial &&
            numeroFacturaInicialNuevo != null) {
          camposModificados['numeroFacturaInicial'] = numeroFacturaInicialNuevo;
        }

        final serieBoletaNueva = data['serieBoleta']?.toString() ?? '';
        final serieBoletaActual = sucursalActual.serieBoleta ?? '';
        if (serieBoletaNueva != serieBoletaActual) {
          if (serieBoletaNueva.isNotEmpty ||
              (serieBoletaActual.isNotEmpty && serieBoletaNueva.isEmpty)) {
            camposModificados['serieBoleta'] = serieBoletaNueva;
          }
        }

        final int? numeroBoletaInicialNuevo =
            data['numeroBoletaInicial'] != null
                ? int.tryParse(data['numeroBoletaInicial'].toString())
                : null;
        if (numeroBoletaInicialNuevo != sucursalActual.numeroBoletaInicial &&
            numeroBoletaInicialNuevo != null) {
          camposModificados['numeroBoletaInicial'] = numeroBoletaInicialNuevo;
        }

        final codigoEstablecimientoNuevo =
            data['codigoEstablecimiento']?.toString() ?? '';
        final codigoEstablecimientoActual =
            sucursalActual.codigoEstablecimiento ?? '';
        if (codigoEstablecimientoNuevo != codigoEstablecimientoActual) {
          if (codigoEstablecimientoNuevo.isNotEmpty ||
              (codigoEstablecimientoActual.isNotEmpty &&
                  codigoEstablecimientoNuevo.isEmpty)) {
            camposModificados['codigoEstablecimiento'] =
                codigoEstablecimientoNuevo;
          }
        }

        if (camposModificados.isNotEmpty) {
          await _sucursalRepository.updateSucursal(
              sucursalId, camposModificados);
        }
      } else {
        final requestData = {
          'nombre': data['nombre'],
          'direccion': data['direccion'],
          'sucursalCentral': data['sucursalCentral'] ?? false,
          'serieFactura': data['serieFactura'] as String?,
          'numeroFacturaInicial': data['numeroFacturaInicial'] as int?,
          'serieBoleta': data['serieBoleta'] as String?,
          'numeroBoletaInicial': data['numeroBoletaInicial'] as int?,
          'codigoEstablecimiento': data['codigoEstablecimiento'] as String?,
        };
        await _sucursalRepository.createSucursal(requestData);
      }

      _sucursalRepository.invalidateCache();
      await cargarSucursales();
      return null;
    } catch (e) {
      return 'Error al guardar sucursal: $e';
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<String?> eliminarSucursal(Sucursal sucursal) async {
    state = state.copyWith(isLoading: true);
    try {
      await _sucursalRepository.deleteSucursal(sucursal.id.toString());
      _sucursalRepository.invalidateCache();
      await cargarSucursales();
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return 'Error al eliminar sucursal: $e';
    }
  }

  Map<String, List<Sucursal>> agruparSucursalesPorTipo() {
    final Map<String, List<Sucursal>> grupos = {
      'Centrales': [],
      'Sucursales': [],
    };

    for (final Sucursal sucursal in state.sucursales) {
      if (sucursal.sucursalCentral) {
        grupos['Centrales']!.add(sucursal);
      } else if (sucursal.nombre.toLowerCase().contains('central') ||
          sucursal.nombre.toLowerCase().contains('principal')) {
        grupos['Centrales']!.add(sucursal);
      } else {
        grupos['Sucursales']!.add(sucursal);
      }
    }

    grupos['Centrales']!
        .sort((Sucursal a, Sucursal b) => a.nombre.compareTo(b.nombre));
    grupos['Sucursales']!
        .sort((Sucursal a, Sucursal b) => a.nombre.compareTo(b.nombre));

    return grupos;
  }

  void limpiarErrores() {
    state = state.copyWith(errorMessage: '');
  }
}
