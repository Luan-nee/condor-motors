import 'package:condorsmotors/models/ventas.model.dart';
import 'package:condorsmotors/providers/admin/ventas.admin.riverpod.dart';
import 'package:condorsmotors/screens/admin/widgets/slide_sucursal.dart';
import 'package:condorsmotors/screens/admin/widgets/venta/venta_detalle_dialog.dart';
import 'package:condorsmotors/widgets/paginador.dart';
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

  @override
  Widget build(BuildContext context) {
    // Escuchar mensajes de error
    ref..listen(ventasAdminProvider.select((s) => s.errorMessage), (prev, next) {
      if (next != null && next.isNotEmpty) {
        context.showErrorToast(next);
      }
    })

    // Escuchar mensajes de éxito
    ..listen(ventasAdminProvider.select((s) => s.successMessage), (prev, next) {
      if (next != null && next.isNotEmpty) {
        context.showSuccessToast(next);
      }
    });

    return Scaffold(
      body: Row(
        children: [
          // Panel izquierdo: Contenido principal (70%)
          const Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VentasAdminHeader(),
                Expanded(
                  child: _VentasAdminContent(),
                ),
              ],
            ),
          ),

          // Panel derecho: Selector de sucursales (30%) - Optimizado
          Container(
            width: 350,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(
                left: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: const _VentasAdminSidebar(),
          ),
        ],
      ),
    );
  }
}

// --- SUB-WIDGETS PARA OPTIMIZACIÓN ---

class _VentasAdminHeader extends ConsumerWidget {
  const _VentasAdminHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ventasAdminProvider);
    final notifier = ref.read(ventasAdminProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const FaIcon(
            FontAwesomeIcons.fileInvoiceDollar,
            color: Color(0xFFE31E24),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            state.selectedSucursal?.nombre ?? 'Todas las sucursales',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _buildSearchField(state, notifier),
          ),
          const SizedBox(width: 16),
          // Selector de ordenamiento
          _buildSortDropdown(state, notifier),
          const SizedBox(width: 16),
          // Botón de recargar ventas (Estandarizado 46x46)
          _buildReloadButton(state, notifier),
        ],
      ),
    );
  }

  Widget _buildSearchField(VentasAdminState state, VentasAdmin notifier) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          hintText: 'Buscar por cliente, documento o serie...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.5),
            size: 18,
          ),
          suffixIcon: state.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 16),
                  onPressed: () => notifier.actualizarBusqueda(''),
                )
              : null,
        ),
        onChanged: notifier.actualizarBusqueda,
      ),
    );
  }

  Widget _buildSortDropdown(VentasAdminState state, VentasAdmin notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: '${state.sortBy}_${state.order}',
          dropdownColor: const Color(0xFF1A1A1A),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
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
          onChanged: (String? val) {
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
      height: 46,
      width: 46,
      child: Tooltip(
        message: state.isLoadingVentas ? 'Recargando...' : 'Recargar ventas',
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A1A),
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            elevation: 0,
          ),
          onPressed: state.isLoadingVentas ? null : () => notifier.cargarVentas(),
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
    );
  }
}

class _VentasAdminContent extends ConsumerWidget {
  const _VentasAdminContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ventasAdminProvider);
    final notifier = ref.read(ventasAdminProvider.notifier);

    if (state.isLoadingVentas && state.ventas.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE31E24)),
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

  Widget _buildVentasTable(BuildContext context, VentasAdminState state, VentasAdmin notifier, WidgetRef ref) {
    if (state.ventas.isEmpty && !state.isLoadingVentas) {
      return const Center(
        child: Text('No se encontraron ventas', style: TextStyle(color: Colors.white54)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.2), // Fecha
          1: FlexColumnWidth(1.5), // Documento
          2: FlexColumnWidth(2),   // Cliente
          3: FlexColumnWidth(),   // Total
          4: FlexColumnWidth(1.5), // Estado
          5: FixedColumnWidth(80),  // Acciones
        },
        children: [
          _buildTableHeader(),
          ...state.ventas.map((v) => _buildTableRow(context, v, notifier, state, ref)),
        ],
      ),
    );
  }

  TableRow _buildTableHeader() {
    return const TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      children: [
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('FECHA', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12))),
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('DOCUMENTO', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12))),
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('CLIENTE', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12))),
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('TOTAL', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12))),
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('ESTADO', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12))),
        Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12))),
      ],
    );
  }

  TableRow _buildTableRow(BuildContext context, Venta v, VentasAdmin notifier, VentasAdminState state, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);

    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(dateFormat.format(v.fechaCreacion), style: const TextStyle(color: Colors.white, fontSize: 13))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('${v.serieDocumento}-${v.numeroDocumento}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(v.nombreCliente ?? 'CLIENTE VARIOS', style: const TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis)),
        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(currencyFormat.format(v.calcularTotal()), style: const TextStyle(color: Color(0xFFE31E24), fontSize: 13, fontWeight: FontWeight.bold))),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getEstadoColor(v.declarada ? 'ACEPTADO' : 'PENDIENTE').withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _getEstadoColor(v.declarada ? 'ACEPTADO' : 'PENDIENTE').withValues(alpha: 0.2)),
            ),
            child: Text(
              (v.declarada ? 'ACEPTADO-SUNAT' : 'PENDIENTE'),
              style: TextStyle(color: _getEstadoColor(v.declarada ? 'ACEPTADO' : 'PENDIENTE'), fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.white54, size: 18),
                onPressed: () => _mostrarDetalle(context, v, ref),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              if (!v.declarada)
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.fileSignature, color: Colors.blue, size: 16),
                  onPressed: state.isActionLoading ? null : () => notifier.declararVenta(v.id.toString()),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),
        ),
      ],
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
        onDeclararPressed: (id) => ref.read(ventasAdminProvider.notifier).declararVenta(id),
      ),
    );
  }
}

class _VentasAdminSidebar extends ConsumerWidget {
  const _VentasAdminSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ventasAdminProvider);
    final notifier = ref.read(ventasAdminProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SlideSucursal(
            sucursales: state.sucursales,
            sucursalSeleccionada: state.selectedSucursal,
            onSucursalSelected: notifier.seleccionarSucursal,
            onRecargarSucursales: notifier.cargarSucursales,
            isLoading: state.isLoadingSucursales,
          ),
        ),
      ],
    );
  }
}
