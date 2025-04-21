import 'package:condorsmotors/models/cliente.model.dart';
import 'package:condorsmotors/models/pedido.model.dart';
import 'package:condorsmotors/repositories/cliente.repository.dart';
import 'package:condorsmotors/repositories/pedido.repository.dart';
import 'package:flutter/foundation.dart';

/// Provider para gestionar pedidos exclusivos en la UI de administración
///
/// Se encarga de mantener el estado de los pedidos y comunicarse con el repositorio
class PedidoAdminProvider extends ChangeNotifier {
  final PedidoRepository _repository = PedidoRepository.instance;
  final ClienteRepository _clienteRepository = ClienteRepository.instance;

  bool _isLoading = false;
  List<PedidoExclusivo> _pedidos = [];
  String _filtroEstado = 'Todos';
  String _searchQuery = '';
  PedidoExclusivo? _pedidoSeleccionado;
  String? _errorMessage;

  final Map<int, Cliente> _clientes = {};

  /// Indica si hay una operación en curso
  bool get isLoading => _isLoading;

  /// Lista de pedidos exclusivos filtrados
  List<PedidoExclusivo> get pedidos => _filtrarPedidos();

  /// Lista completa de pedidos sin filtrar
  List<PedidoExclusivo> get pedidosCompletos => _pedidos;

  /// Filtro de estado actual
  String get filtroEstado => _filtroEstado;

  /// Consulta de búsqueda actual
  String get searchQuery => _searchQuery;

  /// Pedido seleccionado actualmente
  PedidoExclusivo? get pedidoSeleccionado => _pedidoSeleccionado;

  /// Mensaje de error si existe
  String? get errorMessage => _errorMessage;

  /// Estados disponibles para los pedidos
  final List<String> estadosPedido = [
    'Todos',
    'Pendiente',
    'Procesando',
    'Completado',
    'Cancelado'
  ];

  /// Establece el filtro de estado
  set filtroEstado(String estado) {
    _filtroEstado = estado;
    notifyListeners();
  }

  /// Establece la consulta de búsqueda
  set searchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Selecciona un pedido
  void seleccionarPedido(PedidoExclusivo? pedido) {
    _pedidoSeleccionado = pedido;
    notifyListeners();
  }

  /// Carga los pedidos exclusivos desde el repositorio
  Future<void> cargarPedidos() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String? estadoFiltrado =
          _filtroEstado != 'Todos' ? _filtroEstado.toLowerCase() : null;

      final pedidos =
          await _repository.getPedidosExclusivos(filtroEstado: estadoFiltrado);

      _pedidos = pedidos;
      // Obtener IDs únicos de clientes
      final clienteIds = _pedidos.map((p) => p.clienteId).toSet();
      for (final id in clienteIds) {
        if (!_clientes.containsKey(id)) {
          try {
            final cliente =
                await _clienteRepository.obtenerCliente(id.toString());
            _clientes[id] = cliente;
          } catch (e) {
            debugPrint('No se pudo cargar cliente $id: $e');
          }
        }
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar pedidos: $e';
      _isLoading = false;
      debugPrint('Error en PedidoAdminProvider.cargarPedidos: $e');
      notifyListeners();
    }
  }

  /// Crea un nuevo pedido exclusivo
  Future<bool> crearPedido(PedidoExclusivo pedido) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nuevoPedido = await _repository.createPedidoExclusivo(pedido);
      _pedidos.add(nuevoPedido);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al crear pedido: $e';
      _isLoading = false;
      debugPrint('Error en PedidoAdminProvider.crearPedido: $e');
      notifyListeners();
      return false;
    }
  }

  /// Actualiza un pedido existente
  Future<bool> actualizarPedido(int id, PedidoExclusivo pedido) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updatePedidoExclusivo(id, pedido);
      // Recarga la lista completa desde el backend para evitar errores de mapeo
      await cargarPedidos();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar pedido: $e';
      _isLoading = false;
      debugPrint('Error en PedidoAdminProvider.actualizarPedido: $e');
      notifyListeners();
      return false;
    }
  }

  /// Elimina un pedido existente
  Future<bool> eliminarPedido(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final eliminado = await _repository.deletePedidoExclusivo(id);

      if (eliminado) {
        // Eliminar de la lista local
        _pedidos.removeWhere((p) => p.id == id);

        // Si el pedido eliminado era el seleccionado, deseleccionarlo
        if (_pedidoSeleccionado?.id == id) {
          _pedidoSeleccionado = null;
        }
      }

      _isLoading = false;
      notifyListeners();
      return eliminado;
    } catch (e) {
      _errorMessage = 'Error al eliminar pedido: $e';
      _isLoading = false;
      debugPrint('Error en PedidoAdminProvider.eliminarPedido: $e');
      notifyListeners();
      return false;
    }
  }

  /// Filtra los pedidos según los criterios actuales
  List<PedidoExclusivo> _filtrarPedidos() {
    if (_searchQuery.isEmpty) {
      return _pedidos;
    }
    return _pedidos.where((pedido) {
      final query = _searchQuery.toLowerCase();
      return pedido.descripcion.toLowerCase().contains(query) ||
          pedido.denominacion.toLowerCase().contains(query) ||
          pedido.nombre.toLowerCase().contains(query);
    }).toList();
  }

  /// Limpia el estado actual del provider
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _pedidoSeleccionado = null;
    _searchQuery = '';
    _filtroEstado = 'Todos';
    notifyListeners();
  }

  /// Obtiene el cliente asociado a un ID
  Cliente? getCliente(int id) => _clientes[id];
}
