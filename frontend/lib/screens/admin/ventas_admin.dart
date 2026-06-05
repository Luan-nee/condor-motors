import 'package:condorsmotors/models/ventas.model.dart';
import 'package:condorsmotors/providers/admin/ventas.admin.riverpod.dart';
import 'package:condorsmotors/screens/admin/widgets/venta/venta_detalle_dialog.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:condorsmotors/utils/debouncer.util.dart';
import 'package:condorsmotors/widgets/paginador.dart';
import 'package:condorsmotors/widgets/search_bar_admin.dart';
import 'package:condorsmotors/widgets/toast_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class VentasAdminScreen extends ConsumerStatefulWidget {
  const VentasAdminScreen({super.key});

  @override
  ConsumerState<VentasAdminScreen> createState() => _VentasAdminScreenState();
}

class _VentasAdminScreenState extends ConsumerState<VentasAdminScreen> {
  late final TextEditingController _searchController;
  final Debouncer _searchDebouncer =
      Debouncer(delay: const Duration(milliseconds: 350));

  // Estados de filtrado local
  String _filtroDocumento = 'todos'; // 'todos', 'boleta', 'factura'
  String _filtroDeclaracion = 'todos'; // 'todos', 'aceptado', 'pendiente'

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(ventasAdminProvider).searchQuery;
    _searchController = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebouncer.run(() {
      if (mounted) {
        ref.read(ventasAdminProvider.notifier).actualizarBusqueda(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar mensajes de error
    ref
      ..listen(ventasAdminProvider.select((s) => s.errorMessage), (prev, next) {
        if (next != null && next.isNotEmpty) {
          context.showErrorToast(next);
        }
      })

      // Escuchar mensajes de éxito
      ..listen(ventasAdminProvider.select((s) => s.successMessage),
          (prev, next) {
        if (next != null && next.isNotEmpty) {
          context.showSuccessToast(next);
        }
      });

    final state = ref.watch(ventasAdminProvider);

    // Filtrado local de alto rendimiento O(n)
    final ventasFiltradas = state.ventas.where((venta) {
      // 1. Filtrado por tipo de documento (Boleta / Factura)
      if (_filtroDocumento == 'boleta') {
        if (!venta.serieDocumento.toUpperCase().startsWith('B')) {
          return false;
        }
      } else if (_filtroDocumento == 'factura') {
        if (!venta.serieDocumento.toUpperCase().startsWith('F')) {
          return false;
        }
      }

      // 2. Filtrado por estado de declaración SUNAT
      if (_filtroDeclaracion == 'aceptado') {
        if (!venta.declarada) {
          return false;
        }
      } else if (_filtroDeclaracion == 'pendiente') {
        if (venta.declarada) {
          return false;
        }
      }

      return true;
    }).toList();

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VentasAdminHeader(
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
            filtroDocumento: _filtroDocumento,
            onFiltroDocumentoChanged: (val) {
              setState(() {
                _filtroDocumento = val;
              });
            },
            filtroDeclaracion: _filtroDeclaracion,
            onFiltroDeclaracionChanged: (val) {
              setState(() {
                _filtroDeclaracion = val;
              });
            },
          ),
          Expanded(
            child: _VentasAdminContent(ventas: ventasFiltradas),
          ),
        ],
      ),
    );
  }
}

// --- SUB-WIDGETS PARA OPTIMIZACIÓN ---

class _VentasAdminHeader extends ConsumerWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String filtroDocumento;
  final ValueChanged<String> onFiltroDocumentoChanged;
  final String filtroDeclaracion;
  final ValueChanged<String> onFiltroDeclaracionChanged;

  const _VentasAdminHeader({
    required this.searchController,
    required this.onSearchChanged,
    required this.filtroDocumento,
    required this.onFiltroDocumentoChanged,
    required this.filtroDeclaracion,
    required this.onFiltroDeclaracionChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ventasAdminProvider);
    final notifier = ref.read(ventasAdminProvider.notifier);

    final searchRow = Row(
      children: [
        // Buscador táctico HUD estilo productos_admin
        Expanded(
          child: SearchBarAdmin(
            controller: searchController,
            hintText: 'Buscar por cliente, documento o serie...',
            enabled: state.selectedSucursal != null,
            onChanged: onSearchChanged,
          ),
        ),
        const SizedBox(width: 8),

        // Botón de Filtro (PopupMenuButton con posicionamiento y alineación perfecta)
        PopupMenuButton<String>(
          tooltip: 'Filtrar ventas',
          offset: const Offset(0, 44),
          padding: EdgeInsets.zero,
          color: AppTheme.deepestSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          onSelected: (value) {
            if (value.startsWith('doc:')) {
              final docVal = value.substring(4);
              onFiltroDocumentoChanged(docVal);
            } else if (value.startsWith('sunat:')) {
              final sunatVal = value.substring(6);
              onFiltroDeclaracionChanged(sunatVal);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              enabled: false,
              child: Text(
                'TIPO DE DOCUMENTO',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  fontFamily: kFontFamily,
                ),
              ),
            ),
            PopupMenuItem<String>(
              value: 'doc:todos',
              child: Row(
                children: [
                  Icon(
                    filtroDocumento == 'todos'
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: filtroDocumento == 'todos'
                        ? AppTheme.primaryColor
                        : Colors.white38,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Todos los documentos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: kFontFamily,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'doc:boleta',
              child: Row(
                children: [
                  Icon(
                    filtroDocumento == 'boleta'
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: filtroDocumento == 'boleta'
                        ? AppTheme.primaryColor
                        : Colors.white38,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Boletas de Venta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: kFontFamily,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'doc:factura',
              child: Row(
                children: [
                  Icon(
                    filtroDocumento == 'factura'
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: filtroDocumento == 'factura'
                        ? AppTheme.primaryColor
                        : Colors.white38,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Facturas Electrónicas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: kFontFamily,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(height: 12),
            const PopupMenuItem<String>(
              enabled: false,
              child: Text(
                'ESTADO SUNAT',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  fontFamily: kFontFamily,
                ),
              ),
            ),
            PopupMenuItem<String>(
              value: 'sunat:todos',
              child: Row(
                children: [
                  Icon(
                    filtroDeclaracion == 'todos'
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: filtroDeclaracion == 'todos'
                        ? AppTheme.primaryColor
                        : Colors.white38,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Todos los estados',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: kFontFamily,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'sunat:aceptado',
              child: Row(
                children: [
                  Icon(
                    filtroDeclaracion == 'aceptado'
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: filtroDeclaracion == 'aceptado'
                        ? Colors.green
                        : Colors.white38,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Aceptados-SUNAT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: kFontFamily,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'sunat:pendiente',
              child: Row(
                children: [
                  Icon(
                    filtroDeclaracion == 'pendiente'
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: filtroDeclaracion == 'pendiente'
                        ? Colors.orange
                        : Colors.white38,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Pendientes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: kFontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ],
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: (filtroDocumento != 'todos' || filtroDeclaracion != 'todos')
                  ? AppTheme.primaryColor.withValues(alpha: 0.05)
                  : AppTheme.deepestSurface,
              borderRadius: BorderRadius.circular(AppTheme.smallRadius),
              border: Border.all(
                color: (filtroDocumento != 'todos' || filtroDeclaracion != 'todos')
                    ? AppTheme.primaryColor
                    : Colors.white.withValues(alpha: 0.08),
                width: (filtroDocumento != 'todos' || filtroDeclaracion != 'todos') ? 1.5 : 1.0,
              ),
            ),
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.filter,
                size: 14,
                color: (filtroDocumento != 'todos' || filtroDeclaracion != 'todos')
                    ? AppTheme.primaryColor
                    : Colors.white54,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Selector de ordenamiento estandarizado a 40px
        _buildSortDropdown(state, notifier),
        const SizedBox(width: 8),

        // Botón de recargar ventas estandarizado a 40x40
        _buildReloadButton(state, notifier),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: searchRow,
    );
  }

  Widget _buildSortDropdown(VentasAdminState state, VentasAdmin notifier) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.deepestSurface,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: '${state.sortBy}_${state.order}',
          dropdownColor: AppTheme.deepestSurface,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: kFontFamily,
          ),
          icon: const Icon(Icons.arrow_drop_down,
              color: Colors.white70, size: 18),
          isDense: true,
          items: const [
            DropdownMenuItem(
              value: 'fechaCreacion_desc',
              child: Text('Más recientes'),
            ),
            DropdownMenuItem(
              value: 'fechaCreacion_asc',
              child: Text('Más antiguas'),
            ),
            DropdownMenuItem(
              value: 'totalVenta_desc',
              child: Text('Mayor valor'),
            ),
            DropdownMenuItem(
              value: 'totalVenta_asc',
              child: Text('Menor valor'),
            ),
          ],
          onChanged: state.selectedSucursal == null
              ? null
              : (String? val) {
                  if (val != null) {
                    final split = val.split('_');
                    notifier.cambiarOrden(split[0], split[1]);
                  }
                },
        ),
      ),
    );
  }

  Widget _buildReloadButton(VentasAdminState state, VentasAdmin notifier) {
    return SizedBox(
      height: 40,
      width: 40,
      child: Tooltip(
        message: state.isLoadingVentas ? 'Recargando...' : 'Recargar ventas',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppTheme.deepestSurface,
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.smallRadius),
              hoverColor: Colors.white.withValues(alpha: 0.04),
              splashColor: Colors.white.withValues(alpha: 0.08),
              onTap: state.isLoadingVentas || state.selectedSucursal == null
                  ? null
                  : () => notifier.cargarVentas(),
              child: Center(
                child: state.isLoadingVentas
                    ? const SizedBox(
                        width: 18,
                        height: 18,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VentasAdminContent extends ConsumerWidget {
  final List<Venta> ventas;

  const _VentasAdminContent({required this.ventas});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ventasAdminProvider);
    final notifier = ref.read(ventasAdminProvider.notifier);

    if (state.isLoadingVentas && ventas.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (state.selectedSucursal == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.store, size: 48, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'Seleccione una sucursal para ver las ventas',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: _buildVentasTable(context, state, notifier, ref),
        ),
        if (state.paginacion.totalPages > 0)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Paginador(
              paginacion: state.paginacion,
              onPageChanged: notifier.cambiarPagina,
              onPageSizeChanged: notifier.cambiarTamanioPagina,
            ),
          ),
      ],
    );
  }

  Widget _buildVentasTable(BuildContext context, VentasAdminState state,
      VentasAdmin notifier, WidgetRef ref) {
    if (ventas.isEmpty && !state.isLoadingVentas) {
      return const Center(
        child: Text('No se encontraron ventas',
            style: TextStyle(color: Colors.white54)),
      );
    }

    return Column(
      children: [
        _buildTableHeaderLayout(),
        Expanded(
          child: ListView.builder(
            itemCount: ventas.length,
            itemBuilder: (context, index) {
              return _VentaTableRow(venta: ventas[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeaderLayout() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: const Row(
        children: [
          Expanded(
              flex: 12,
              child: Text('FECHA',
                  style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12))),
          Expanded(
              flex: 15,
              child: Text('DOCUMENTO',
                  style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12))),
          Expanded(
              flex: 20,
              child: Text('CLIENTE',
                  style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12))),
          Expanded(
              flex: 10,
              child: Text('TOTAL',
                  style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12))),
          Expanded(
              flex: 15,
              child: Text('ESTADO',
                  style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12))),
          SizedBox(
              width: 80,
              child: Text('',
                  style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12))),
        ],
      ),
    );
  }
}

class _VentaTableRow extends ConsumerWidget {
  final Venta venta;

  const _VentaTableRow({required this.venta});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat =
        NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);

    // ESCUCHA GRANULAR: Solo se reconstruye si el ID de esta fila es el que está cargando
    final bool isRowLoading = ref.watch(ventasAdminProvider
        .select((s) => s.loadingVentaId == venta.id.toString()));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 12,
            child: Text(dateFormat.format(venta.fechaCreacion),
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          Expanded(
            flex: 15,
            child: Text('${venta.serieDocumento}-${venta.numeroDocumento}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 20,
            child: Text(venta.nombreCliente ?? 'CLIENTE VARIOS',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 10,
            child: Text(currencyFormat.format(venta.calcularTotal()),
                style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 15,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getEstadoColor(
                          venta.declarada ? 'ACEPTADO' : 'PENDIENTE')
                      .withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: _getEstadoColor(
                              venta.declarada ? 'ACEPTADO' : 'PENDIENTE')
                          .withAlpha(51)),
                ),
                child: Text(
                  (venta.declarada ? 'ACEPTADO-SUNAT' : 'PENDIENTE'),
                  style: TextStyle(
                      color: _getEstadoColor(
                          venta.declarada ? 'ACEPTADO' : 'PENDIENTE'),
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility,
                      color: Colors.white54, size: 18),
                  onPressed: isRowLoading
                      ? null
                      : () => _mostrarDetalle(context, venta, ref),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                if (!venta.declarada)
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: isRowLoading
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue,
                            ),
                          )
                        : IconButton(
                            icon: const FaIcon(FontAwesomeIcons.fileSignature,
                                color: Colors.blue, size: 16),
                            onPressed: () => ref
                                .read(ventasAdminProvider.notifier)
                                .declararVenta(venta.id.toString()),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'ACEPTADO-SUNAT':
      case 'ACEPTADO ANTE LA SUNAT':
      case 'COMPLETADA':
        return Colors.green;
      case 'ANULADA':
      case 'RECHAZADA':
        return Colors.red;
      case 'PENDIENTE':
      default:
        return Colors.orange;
    }
  }

  void _mostrarDetalle(BuildContext context, Venta v, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => VentaDetalleDialog(
        venta: v,
        onDeclararPressed: (id) =>
            ref.read(ventasAdminProvider.notifier).declararVenta(id),
      ),
    );
  }
}
