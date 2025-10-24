import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/foundation.dart';

/// Provider de sesión para centralizar el contexto de sucursal/usuario actual
/// - Expone la sucursal seleccionada y la lista de sucursales disponibles
/// - Ofrece helpers para cambiar/establecer sucursal
/// - Evita que cada provider de dominio duplique esta lógica
class SessionProvider extends ChangeNotifier {
  final SucursalRepository _sucursalRepository = SucursalRepository.instance;

  // Estado de sucursales
  List<Sucursal> _sucursales = <Sucursal>[];
  Sucursal? _sucursalSeleccionada;
  bool _isLoadingSucursales = false;
  String _errorMessage = '';

  // Constructor que se inicializa automáticamente
  SessionProvider() {
    // Inicializar automáticamente cuando se crea el provider
    Future<void>.microtask(() async {
      await inicializar();
    });
  }

  // Getters
  List<Sucursal> get sucursales => _sucursales;
  Sucursal? get sucursalSeleccionada => _sucursalSeleccionada;
  bool get isLoadingSucursales => _isLoadingSucursales;
  String get errorMessage => _errorMessage;

  /// Inicializa cargando sucursales. Si ya hay una seleccionada, la preserva.
  Future<void> inicializar() async {
    await cargarSucursales();
  }

  /// Carga las sucursales disponibles desde el repositorio
  Future<void> cargarSucursales() async {
    _isLoadingSucursales = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final List<Sucursal> data = await _sucursalRepository.getSucursales();
      data.sort((a, b) => a.nombre.compareTo(b.nombre));
      _sucursales = data;

      // Selección predeterminada si aún no existe
      if (_sucursalSeleccionada == null && _sucursales.isNotEmpty) {
        _sucursalSeleccionada = _sucursales.first;
      }

      _isLoadingSucursales = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[SessionProvider] Error al cargar sucursales: $e');
      _errorMessage = 'Error al cargar sucursales: $e';
      _isLoadingSucursales = false;
      notifyListeners();
    }
  }

  /// Cambia la sucursal seleccionada
  void seleccionarSucursal(Sucursal sucursal) {
    if (_sucursalSeleccionada?.id == sucursal.id) {
      return;
    }
    _sucursalSeleccionada = sucursal;
    notifyListeners();
  }

  /// Establece la sucursal seleccionada por ID, obteniendo datos del repositorio si no está en memoria
  Future<bool> establecerSucursalPorId(sucursalId) async {
    try {
      if (sucursalId == null) {
        return false;
      }
      final String idStr = sucursalId.toString();

      // Intentar resolver desde lista en memoria
      for (final s in _sucursales) {
        if (s.id.toString() == idStr) {
          _sucursalSeleccionada = s;
          notifyListeners();
          return true;
        }
      }

      // Intentar obtener datos completos desde el repositorio
      try {
        final Sucursal s = await _sucursalRepository.getSucursalData(
          idStr,
          useCache: false,
          forceRefresh: true,
        );
        _sucursalSeleccionada = s;

        // Añadir si no existe en la lista actual
        if (!_sucursales.any((x) => x.id.toString() == idStr)) {
          _sucursales
            ..add(s)
            ..sort((a, b) => a.nombre.compareTo(b.nombre));
        }
        notifyListeners();
        return true;
      } catch (e) {
        // Fallback: crear sucursal provisional desde el repositorio
        final Sucursal provisional =
            _sucursalRepository.createProvisionalSucursal(idStr);
        _sucursalSeleccionada = provisional;
        if (!_sucursales.any((x) => x.id.toString() == idStr)) {
          _sucursales.add(provisional);
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[SessionProvider] Error al establecer sucursal por ID: $e');
      return false;
    }
  }

  /// Limpia errores actuales
  void limpiarErrores() {
    if (_errorMessage.isEmpty) {
      return;
    }
    _errorMessage = '';
    notifyListeners();
  }
}
