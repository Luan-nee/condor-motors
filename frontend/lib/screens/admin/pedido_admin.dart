import 'package:condorsmotors/models/cliente.model.dart';
import 'package:condorsmotors/models/pedido.model.dart';
import 'package:condorsmotors/repositories/cliente.repository.dart';
import 'package:condorsmotors/repositories/pedido.repository.dart';
import 'package:condorsmotors/screens/admin/widgets/pedido/detalle_pedido.dart';
import 'package:condorsmotors/screens/admin/widgets/pedido/form_pedido.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:condorsmotors/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class PedidoAdminScreen extends StatefulWidget {
  const PedidoAdminScreen({super.key});

  @override
  State<PedidoAdminScreen> createState() => _PedidoAdminScreenState();
}

class _PedidoAdminScreenState extends State<PedidoAdminScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Estado local
  bool _isLoading = false;
  List<PedidoExclusivo> _pedidos = [];
  String _filtroEstado = 'Todos';
  String _searchQuery = '';
  PedidoExclusivo? _pedidoSeleccionado;
  String? _errorMessage;
  final Map<int, Cliente> _clientes = {};

  // Repositorios
  final PedidoRepository _repository = PedidoRepository.instance;
  final ClienteRepository _clienteRepository = ClienteRepository.instance;

  // Estados disponibles para los pedidos
  final List<String> estadosPedido = [
    'Todos',
    'Pendiente',
    'Procesando',
    'Completado',
    'Cancelado'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPedidos();

      // Escuchar los cambios en el campo de búsqueda
      _searchController.addListener(_onSearchChanged);
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  /// Carga los pedidos exclusivos desde el repositorio
  Future<void> _cargarPedidos() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String? estadoFiltrado =
          _filtroEstado != 'Todos' ? _filtroEstado.toLowerCase() : null;

      final pedidos =
          await _repository.getPedidosExclusivos(filtroEstado: estadoFiltrado);

      setState(() {
        _pedidos = pedidos;
      });

      // Obtener IDs únicos de clientes
      final clienteIds = _pedidos.map((p) => p.clienteId).toSet();
      for (final id in clienteIds) {
        if (!_clientes.containsKey(id)) {
          try {
            final cliente =
                await _clienteRepository.obtenerCliente(id.toString());
            setState(() {
              _clientes[id] = cliente;
            });
          } catch (e) {
            debugPrint('No se pudo cargar cliente $id: $e');
          }
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar pedidos: $e';
        _isLoading = false;
      });
      debugPrint('Error en PedidoAdminProvider.cargarPedidos: $e');
    }
  }

  /// Elimina un pedido existente
  Future<bool> _eliminarPedido(int id) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final eliminado = await _repository.deletePedidoExclusivo(id);

      if (eliminado) {
        // Eliminar de la lista local
        setState(() {
          _pedidos.removeWhere((p) => p.id == id);

          // Si el pedido eliminado era el seleccionado, deseleccionarlo
          if (_pedidoSeleccionado?.id == id) {
            _pedidoSeleccionado = null;
          }
        });
      }

      setState(() {
        _isLoading = false;
      });
      return eliminado;
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al eliminar pedido: $e';
        _isLoading = false;
      });
      debugPrint('Error en PedidoAdminProvider.eliminarPedido: $e');
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
  void _reset() {
    setState(() {
      _isLoading = false;
      _errorMessage = null;
      _pedidoSeleccionado = null;
      _searchQuery = '';
      _filtroEstado = 'Todos';
    });
  }

  /// Obtiene el cliente asociado a un ID
  Cliente? _getCliente(int id) => _clientes[id];

  void _mostrarDetallePedido(PedidoExclusivo pedido) {
    showDialog(
      context: context,
      builder: (context) => DetallePedidoWidget(
        pedido: pedido,
        onUpdate: _cargarPedidos,
      ),
    );
  }

  void _mostrarFormularioPedido({PedidoExclusivo? pedido}) {
    showDialog(
      context: context,
      builder: (context) => FormPedidoWidget(
        pedido: pedido,
        onSave: _cargarPedidos,
      ),
    );
  }

  Future<void> _confirmarEliminarPedido(PedidoExclusivo pedido) async {
    if (pedido.id == null) {
      return;
    }

    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
            '¿Está seguro de eliminar el pedido exclusivo "${pedido.descripcion}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmacion == true) {
      try {
        final success = await _eliminarPedido(pedido.id!);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pedido eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        logError('Error al eliminar pedido', e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar pedido: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pedidos = _filtrarPedidos();
    final isLoading = _isLoading;
    final errorMessage = _errorMessage ?? '';

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    FaIcon(
                      FontAwesomeIcons.truckFast,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'PEDIDOS',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'exclusivos',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    ElevatedButton.icon(
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const FaIcon(
                              FontAwesomeIcons.arrowsRotate,
                              size: 16,
                              color: Colors.white,
                            ),
                      label: Text(
                        isLoading ? 'Recargando...' : 'Recargar',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D2D2D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed: isLoading ? null : _cargarPedidos,
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const FaIcon(FontAwesomeIcons.plus,
                          size: 16, color: Colors.white),
                      label: const Text('Nuevo Pedido'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31E24),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      onPressed: _mostrarFormularioPedido,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSearchBar(),
            if (errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: _reset,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : pedidos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const FaIcon(
                                  FontAwesomeIcons.boxOpen,
                                  color: Colors.grey,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay pedidos exclusivos disponibles',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  icon: const FaIcon(
                                    FontAwesomeIcons.plus,
                                    size: 14,
                                  ),
                                  label: const Text('Crear pedido'),
                                  onPressed: _mostrarFormularioPedido,
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                // Encabezado de la tabla
                                Container(
                                  decoration: const BoxDecoration(
                                    color: AppTheme.cardColor,
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(
                                            AppTheme.mediumRadius)),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 20),
                                  child: const Row(
                                    children: <Widget>[
                                      Expanded(
                                        flex: 30,
                                        child: Text('Descripción',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                      ),
                                      Expanded(
                                        flex: 25,
                                        child: Text('Cliente',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                      ),
                                      Expanded(
                                        flex: 15,
                                        child: Text('Sucursal',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                      ),
                                      Expanded(
                                        flex: 15,
                                        child: Text('Fecha',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                      ),
                                      Expanded(
                                        flex: 15,
                                        child: Text('Monto Adelantado',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                      ),
                                      Expanded(
                                        flex: 15,
                                        child: Text('Recojo',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                      ),
                                      Expanded(
                                        flex: 15,
                                        child: Text('Detalles',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                      ),
                                      Expanded(
                                        flex: 20,
                                        child: Text('Acciones',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                      ),
                                    ],
                                  ),
                                ),
                                // Filas de pedidos
                                ...pedidos.map((pedido) => Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.white
                                                .withValues(alpha: 0.1),
                                          ),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 20),
                                      child: Row(
                                        children: <Widget>[
                                          Expanded(
                                            flex: 25,
                                            child: Text(pedido.descripcion,
                                                style: const TextStyle(
                                                    color: Colors.white)),
                                          ),
                                          Expanded(
                                            flex: 20,
                                            child: Text(
                                                _getCliente(pedido.clienteId)
                                                        ?.denominacion ??
                                                    pedido.clienteId.toString(),
                                                style: const TextStyle(
                                                    color: Colors.white)),
                                          ),
                                          Expanded(
                                            flex: 15,
                                            child: Text(
                                                pedido.nombre.isNotEmpty
                                                    ? pedido.nombre
                                                    : 'Sucursal ${pedido.sucursalId}',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                    color: Colors.white)),
                                          ),
                                          Expanded(
                                            flex: 15,
                                            child: Text(
                                                DateFormat('dd/MM/yyyy').format(
                                                    pedido.fechaCreacion),
                                                style: const TextStyle(
                                                    color: Colors.white)),
                                          ),
                                          Expanded(
                                            flex: 15,
                                            child: Text(
                                                'S/ ${pedido.montoAdelantado}',
                                                style: const TextStyle(
                                                    color: Colors.white)),
                                          ),
                                          Expanded(
                                            flex: 15,
                                            child: Text(pedido.fechaRecojo,
                                                style: const TextStyle(
                                                    color: Colors.white)),
                                          ),
                                          Expanded(
                                            flex: 15,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const FaIcon(
                                                    FontAwesomeIcons.box,
                                                    size: 12,
                                                    color: Color(0xFFE31E24)),
                                                const SizedBox(width: 6),
                                                Text(
                                                    '${pedido.detallesReserva.length}',
                                                    style: const TextStyle(
                                                        color:
                                                            Color(0xFFE31E24),
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 20,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                IconButton(
                                                  icon: const FaIcon(
                                                      FontAwesomeIcons.eye,
                                                      color: Colors.white54,
                                                      size: 16),
                                                  onPressed: () =>
                                                      _mostrarDetallePedido(
                                                          pedido),
                                                  constraints:
                                                      const BoxConstraints(
                                                          minWidth: 30,
                                                          minHeight: 30),
                                                  padding: EdgeInsets.zero,
                                                ),
                                                IconButton(
                                                  icon: const FaIcon(
                                                      FontAwesomeIcons
                                                          .penToSquare,
                                                      color: Colors.white54,
                                                      size: 16),
                                                  onPressed: () =>
                                                      _mostrarFormularioPedido(
                                                          pedido: pedido),
                                                  constraints:
                                                      const BoxConstraints(
                                                          minWidth: 30,
                                                          minHeight: 30),
                                                  padding: EdgeInsets.zero,
                                                ),
                                                IconButton(
                                                  icon: const FaIcon(
                                                      FontAwesomeIcons.trash,
                                                      color: Colors.red,
                                                      size: 16),
                                                  onPressed: () =>
                                                      _confirmarEliminarPedido(
                                                          pedido),
                                                  constraints:
                                                      const BoxConstraints(
                                                          minWidth: 30,
                                                          minHeight: 30),
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                              ],
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar pedidos',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _filtroEstado,
            items: estadosPedido.map((estado) {
              return DropdownMenuItem<String>(
                value: estado,
                child: Text(estado),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _filtroEstado = value;
                });
                _cargarPedidos();
              }
            },
            hint: const Text('Estado'),
          ),
        ],
      ),
    );
  }
}
