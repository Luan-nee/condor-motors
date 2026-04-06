import 'dart:async';

import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:condorsmotors/providers/colabs/transferencias.colab.riverpod.dart';
import 'package:condorsmotors/screens/colabs/widgets/transferencias/transferencia_filter_bar.dart';
import 'package:condorsmotors/screens/colabs/widgets/transferencias/transferencia_product_card.dart';
import 'package:condorsmotors/widgets/paginador.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TransferenciaFormListColab extends ConsumerStatefulWidget {
  final String sucursalId;
  final List<DetalleProducto> productosSeleccionados;

  const TransferenciaFormListColab({
    super.key,
    required this.sucursalId,
    required this.productosSeleccionados,
  });

  @override
  ConsumerState<TransferenciaFormListColab> createState() =>
      _TransferenciaFormListColabState();
}

class _TransferenciaFormListColabState
    extends ConsumerState<TransferenciaFormListColab> {
  final TextEditingController _searchController = TextEditingController();
  final List<DetalleProducto> _localSelection = [];
  Timer? _debounce;

  // Estados de UI
  bool _isSearchExpanded = false;
  bool _isCategoriaExpanded = false;
  bool _isOrdenamientoExpanded = false;
  bool _isStockBajoExpanded = true;

  @override
  void initState() {
    super.initState();
    _localSelection.addAll(widget.productosSeleccionados);

    // Inicializar filtros en el provider basándose en el estado actual si es necesario
    // o simplemente cargar con los defaults del provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController..removeListener(_onSearchChanged)
    ..dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(transferenciasColabProvider.notifier).actualizarFiltros(
            searchQuery: _searchController.text,
          );
      _loadData(resetPaginacion: true);
    });
  }

  Future<void> _loadData({bool resetPaginacion = false}) async {
    await ref.read(transferenciasColabProvider.notifier).cargarProductosParaFormulario(
          sucursalId: widget.sucursalId,
          resetPaginacion: resetPaginacion,
        );
  }

  void _updateQuantity(int productoId, String nombre, String? codigo, int newCantidad) {
    setState(() {
      final index = _localSelection.indexWhere((p) => p.id == productoId);
      if (index >= 0) {
        if (newCantidad <= 0) {
          _localSelection.removeAt(index);
        } else {
          _localSelection[index] = _localSelection[index].copyWith(cantidad: newCantidad);
        }
      } else if (newCantidad > 0) {
        _localSelection.add(DetalleProducto(
          id: productoId,
          nombre: nombre,
          codigo: codigo,
          cantidad: newCantidad,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transferenciasColabProvider);
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: size.width * 0.95,
        height: size.height * 0.95,
        constraints: const BoxConstraints(
          minWidth: 300,
          minHeight: 400,
          maxWidth: 900,
          maxHeight: 900,
        ),
        child: Column(
          children: [
            _buildHeader(),
            TransferenciaFilterBar(
              isSearchExpanded: _isSearchExpanded,
              isCategoriaExpanded: _isCategoriaExpanded,
              isOrdenamientoExpanded: _isOrdenamientoExpanded,
              searchController: _searchController,
              filtroCategoria: state.filtroCategoria,
              ordenarPor: state.ordenarPor,
              orden: state.orden,
              onToggleSearch: () => setState(() => _isSearchExpanded = !_isSearchExpanded),
              onToggleCategoria: () => setState(() => _isCategoriaExpanded = !_isCategoriaExpanded),
              onToggleOrdenamiento: () => setState(() => _isOrdenamientoExpanded = !_isOrdenamientoExpanded),
              onCategoriaChanged: (val) {
                ref.read(transferenciasColabProvider.notifier).actualizarFiltros(categoria: val);
                _loadData(resetPaginacion: true);
              },
              onOrdenarPorChanged: (val) {
                ref.read(transferenciasColabProvider.notifier).actualizarFiltros(ordenarPor: val);
                _loadData();
              },
              onOrdenChanged: (val) {
                ref.read(transferenciasColabProvider.notifier).actualizarFiltros(orden: val);
                _loadData();
              },
              onClearFilters: () {
                _searchController.clear();
                ref.read(transferenciasColabProvider.notifier).restablecerFiltros();
                _loadData(resetPaginacion: true);
              },
              onSearch: () => _loadData(resetPaginacion: true),
              hasActiveFilters: state.searchQuery.isNotEmpty ||
                  state.filtroCategoria != 'Todos' ||
                  state.ordenarPor != 'nombre' ||
                  state.orden != 'asc',
            ),
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
                      ),
                    )
                  : _buildProductList(state),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const FaIcon(FontAwesomeIcons.box, size: 20, color: Color(0xFFE31E24)),
          const SizedBox(width: 8),
          const Text(
            'Seleccionar Productos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(TransferenciasColabState state) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (state.productosBajoStockParaTransferir.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE31E24).withValues(alpha: 0.3),
              ),
            ),
            child: ExpansionTile(
              initiallyExpanded: _isStockBajoExpanded,
              onExpansionChanged: (expanded) => setState(() => _isStockBajoExpanded = expanded),
              title: Row(
                children: [
                  const Text(
                    'Productos con Stock Bajo',
                    style: TextStyle(
                      color: Color(0xFFE31E24),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildBadge(state.productosBajoStockParaTransferir.length.toString()),
                ],
              ),
              iconColor: const Color(0xFFE31E24),
              collapsedIconColor: const Color(0xFFE31E24),
              children: state.productosBajoStockParaTransferir.map((p) => _buildItem(p, true)).toList(),
            ),
          ),
        if (state.productosParaTransferir.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Otros Productos',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ...state.productosParaTransferir.map((p) => _buildItem(p, false)),
        ],
        if (state.productosParaTransferir.isEmpty && state.productosBajoStockParaTransferir.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'No se encontraron productos',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ),
        if (state.paginacion != null && state.paginacion!.totalPages > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Paginador(
              paginacion: state.paginacion!,
              onPageChanged: (page) {
                ref.read(transferenciasColabProvider.notifier).cambiarPagina(page);
                _loadData();
              },
              onPageSizeChanged: (pageSize) {
                ref.read(transferenciasColabProvider.notifier).cambiarTamanoPagina(pageSize);
                _loadData(resetPaginacion: true);
              },
              backgroundColor: const Color(0xFF2D2D2D),
              textColor: Colors.white,
              accentColor: const Color(0xFFE31E24),
            ),
          ),
      ],
    );
  }

  Widget _buildItem(p, bool isBajoStock) {
    final int currentQty = _localSelection.firstWhere(
      (sel) => sel.id == p.id,
      orElse: () => DetalleProducto(id: p.id, nombre: p.nombre, cantidad: 0),
    ).cantidad;

    return TransferenciaProductCard(
      producto: p,
      isBajoStock: isBajoStock,
      cantidadSeleccionada: currentQty,
      onCantidadChanged: (newQty) => _updateQuantity(p.id, p.nombre, p.sku, newQty),
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE31E24).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE31E24),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _localSelection.isEmpty ? null : () => Navigator.pop(context, _localSelection),
            icon: const FaIcon(FontAwesomeIcons.check, size: 16),
            label: const Text('Confirmar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31E24),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
