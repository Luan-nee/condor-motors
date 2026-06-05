import 'package:condorsmotors/models/cliente.model.dart';
import 'package:condorsmotors/models/pedido.model.dart';
import 'package:condorsmotors/providers/admin/pedidos.admin.riverpod.dart';
import 'package:condorsmotors/screens/admin/widgets/pedido/detalle_pedido.dart';
import 'package:condorsmotors/screens/admin/widgets/pedido/form_pedido.dart';
import 'package:condorsmotors/screens/admin/widgets/pedido/pedido_search_bar.dart';
import 'package:condorsmotors/screens/admin/widgets/pedido/pedido_table.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:condorsmotors/utils/logger.dart';
import 'package:condorsmotors/widgets/common/error_banner.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PedidoAdminScreen extends ConsumerStatefulWidget {
  const PedidoAdminScreen({super.key});

  @override
  ConsumerState<PedidoAdminScreen> createState() => _PedidoAdminScreenState();
}

class _PedidoAdminScreenState extends ConsumerState<PedidoAdminScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Estado local para filtrado
  String _filtroEstado = 'Todos';
  String _searchQuery = '';

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
    _searchController.addListener(_onSearchChanged);
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

  /// Dispara la recarga de pedidos mediante el notifier
  void _cargarPedidos() {
    ref.read(pedidosAdminProvider.notifier).cargarPedidos(filtroEstado: _filtroEstado);
  }

  /// Solicita eliminar un pedido al notifier
  Future<bool> _eliminarPedido(int id) {
    return ref.read(pedidosAdminProvider.notifier).eliminarPedido(id);
  }

  /// Filtra los pedidos según los criterios actuales
  List<PedidoExclusivo> _filtrarPedidos(List<PedidoExclusivo> pedidos) {
    if (_searchQuery.isEmpty) {
      return pedidos;
    }
    return pedidos.where((pedido) {
      final query = _searchQuery.toLowerCase();
      return pedido.descripcion.toLowerCase().contains(query) ||
          pedido.denominacion.toLowerCase().contains(query) ||
          pedido.nombre.toLowerCase().contains(query);
    }).toList();
  }

  /// Obtiene el cliente asociado a un ID desde la caché reactiva
  Cliente? _getCliente(Map<int, Cliente> clientesMap, int id) => clientesMap[id];

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
    final state = ref.watch(pedidosAdminProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkSurface,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: state.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
          error: (err, stack) => Center(
            child: ErrorBanner(
              message: 'Error al cargar pedidos: $err',
              onClose: _cargarPedidos,
            ),
          ),
          data: (data) {
            final pedidosFiltrados = _filtrarPedidos(data.pedidos);
            final isLoading = state.isLoading;

            return Column(
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
                            backgroundColor: AppTheme.surfaceColor,
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
                            backgroundColor: AppTheme.primaryColor,
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
                PedidoSearchBar(
                  controller: _searchController,
                  filtroEstado: _filtroEstado,
                  onFiltroChanged: (value) {
                    setState(() {
                      _filtroEstado = value;
                    });
                    ref.read(pedidosAdminProvider.notifier).cargarPedidos(filtroEstado: value);
                  },
                  estadosPedido: estadosPedido,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: PedidoTable(
                    pedidos: pedidosFiltrados,
                    isLoading: isLoading,
                    getCliente: (id) => _getCliente(data.clientes, id),
                    onViewDetails: _mostrarDetallePedido,
                    onEdit: (pedido) => _mostrarFormularioPedido(pedido: pedido),
                    onDelete: _confirmarEliminarPedido,
                    onNew: _mostrarFormularioPedido,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
