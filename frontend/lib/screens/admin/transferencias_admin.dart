// Importamos la variable global api
import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:condorsmotors/providers/admin/transferencias.admin.riverpod.dart';
import 'package:condorsmotors/screens/admin/widgets/movimiento/transferencia_detail_dialog.dart'; // Importamos el nuevo widget unificado
import 'package:condorsmotors/utils/transferencias_utils.dart';
import 'package:condorsmotors/widgets/paginador.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class MovimientosAdminScreen extends ConsumerStatefulWidget {
  const MovimientosAdminScreen({super.key});

  @override
  ConsumerState<MovimientosAdminScreen> createState() => _MovimientosAdminScreenState();
}

class _MovimientosAdminScreenState extends ConsumerState<MovimientosAdminScreen> {
  @override
  void initState() {
    super.initState();
    // Cargamos los movimientos cuando se inicializa la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarMovimientos();
    });
  }

  Future<void> _cargarMovimientos({bool forceRefresh = false}) async {
    if (!mounted) {
      return;
    }

    final notifier = ref.read(transferenciasAdminProvider.notifier);
    final state = ref.read(transferenciasAdminProvider);

    // Actualizamos los filtros en el notifier
    notifier.actualizarFiltros(
      fechaInicio: state.fechaInicio,
      fechaFin: state.fechaFin,
    );

    await notifier.cargarTransferencias(
      forceRefresh: forceRefresh,
    );

    // Si hay error, mostrar snackbar
    if (ref.read(transferenciasAdminProvider).errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(transferenciasAdminProvider).errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transferenciasAdminProvider);
    final notifier = ref.read(transferenciasAdminProvider.notifier);

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
                Row(
                  children: <Widget>[
                    const FaIcon(
                      FontAwesomeIcons.truck,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'INVENTARIO',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'transferencias de inventario',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Filtros
                Row(
                  children: <Widget>[
                    // Filtro por estado (Compacto como Productos Admin)
                    SizedBox(
                      height: 46,
                      width: 46,
                      child: Tooltip(
                        message: 'Filtrar por estado',
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: state.selectedFilter != 'Todos'
                                ? const Color(0xFFE31E24).withValues(alpha: 0.1)
                                : const Color(0xFF2D2D2D),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: state.selectedFilter != 'Todos'
                                  ? const Color(0xFFE31E24)
                                  : Colors.transparent,
                            ),
                          ),
                          child: PopupMenuButton<String>(
                            initialValue: state.selectedFilter,
                            icon: FaIcon(
                              FontAwesomeIcons.filter,
                              size: 14,
                              color: state.selectedFilter != 'Todos'
                                  ? const Color(0xFFE31E24)
                                  : Colors.white54,
                            ),
                            onSelected: notifier.cambiarFiltro,
                            offset: const Offset(0, 46),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'Todos',
                                child: Text('Todos los estados',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 13)),
                              ),
                              ...['Pedido', 'Enviado', 'Recibido'].map(
                                (f) => PopupMenuItem(
                                  value: f,
                                  child: Text(f,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botón Recargar (Compacto como Productos Admin)
                    SizedBox(
                      height: 46,
                      width: 46,
                      child: Tooltip(
                        message:
                            state.isLoading ? 'Recargando...' : 'Recargar datos',
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D2D2D),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: state.isLoading
                              ? null
                              : notifier.recargarDatos,
                          child: state.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const FaIcon(FontAwesomeIcons.arrowsRotate,
                                  size: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ],
            ),
              const SizedBox(height: 32),

              // Tabla de movimientos con paginación
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Encabezado de la tabla dentro del mismo Container
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF2D2D2D),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        child: const Row(
                          children: <Widget>[
                            // Fechas (25%)
                            Expanded(
                              flex: 25,
                              child: Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.calendar,
                                    color: Color(0xFFE31E24),
                                    size: 14,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Fechas',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Sucursales (30%)
                            Expanded(
                              flex: 30,
                              child: Text(
                                'Sucursales',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Estado y Progreso (40%)
                            Expanded(
                              flex: 40,
                              child: Center(
                                child: Text(
                                  'Estado y Progreso',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            // Acciones (5%)
                            SizedBox(
                              width: 32,
                              child: Center(
                                child: Text(
                                  'Acciones',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              ...state.transferencias
                                  .map(_buildTransferenciaRow),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Paginador
              Container(
                margin: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Paginador(
                      paginacion: state.paginacion,
                      backgroundColor: const Color(0xFF1A1A1A),
                      textColor: Colors.white,
                      accentColor: const Color(0xFFE31E24),
                      radius: 8,
                      mostrarOrdenacion: true,
                      camposParaOrdenar: const [
                        {'value': 'salidaOrigen', 'label': 'Fecha de Salida'},
                        {
                          'value': 'llegadaDestino',
                          'label': 'Fecha de Llegada'
                        },
                        {
                          'value': 'fechaCreacion',
                          'label': 'Fecha de Creación'
                        },
                        {
                          'value': 'fechaActualizacion',
                          'label': 'Fecha de Actualización'
                        },
                        {'value': 'estado', 'label': 'Estado'},
                      ],
                      onPageChange: () async {
                        await notifier.cargarTransferencias();
                      },
                      onPageChanged: (page) async {
                        await notifier.cambiarPagina(page);
                      },
                      onPageSizeChanged: (pageSize) async {
                        await notifier.cambiarTamanoPagina(pageSize);
                      },
                      onSortByChanged: (sortBy) async {
                        await notifier.cambiarOrdenarPor(sortBy);
                      },
                      onOrderChanged: (order) async {
                        await notifier.cambiarOrden(order);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  // Función para mostrar el detalle de un movimiento
  Future<void> _mostrarDetalleMovimiento(
      TransferenciaInventario transferencia) async {
    if (!mounted) {
      return;
    }

    debugPrint(
        'Iniciando visualización de detalles para transferencia #${transferencia.id}');

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return TransferenciaDetailDialog(transferencia: transferencia);
      },
    );

    debugPrint('Diálogo de detalles cerrado correctamente');
  }

  // Formato de fecha
  String _formatFecha(DateTime? fecha) {
    if (fecha == null) {
      return 'N/A';
    }
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
    } catch (e) {
      return 'N/A';
    }
  }

  // Actualizar el widget de la fila de transferencia
  Widget _buildTransferenciaRow(TransferenciaInventario transferencia) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: <Widget>[
          // Fechas (25%)
          Expanded(
            flex: 25,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: Color(0xFFE31E24)),
                    const SizedBox(width: 4),
                    Text(_formatFecha(transferencia.fechaCreacion),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13)),
                    const SizedBox(width: 4),
                    const Text('Creado',
                        style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.update, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(_formatFecha(transferencia.fechaActualizacion),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13)),
                    const SizedBox(width: 4),
                    const Text('Actualizado',
                        style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                if (transferencia.salidaOrigen != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward,
                          size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(_formatFecha(transferencia.salidaOrigen),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                      const SizedBox(width: 4),
                      const Text('Salida',
                          style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ],
                if (transferencia.llegadaDestino != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.arrow_downward,
                          size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(_formatFecha(transferencia.llegadaDestino),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                      const SizedBox(width: 4),
                      const Text('Llegada',
                          style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Sucursales (30%)
          Expanded(
            flex: 30,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transferencia.nombreSucursalOrigen ?? 'N/A',
                        style: TextStyle(
                          color: transferencia.nombreSucursalOrigen != null
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Origen',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward,
                    color: Colors.grey,
                    size: 16,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transferencia.nombreSucursalDestino,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Destino',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Timeline (40%)
          Expanded(
            flex: 40,
            child: Center(
              child: _buildCompactTimeline(transferencia),
            ),
          ),

          // Acciones (5%)
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: IconButton(
              onPressed: () => _mostrarDetalleMovimiento(transferencia),
              icon: const FaIcon(
                FontAwesomeIcons.magnifyingGlass,
                color: Color(0xFFE31E24),
                size: 14,
              ),
              tooltip: 'Ver detalles',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              splashRadius: 20,
            ),
          ),
        ],
      ),
    );
  }

  // Timeline compacto horizontal
  Widget _buildCompactTimeline(TransferenciaInventario transferencia) {
    final steps = TransferenciasUtils.getTransferenciaSteps(transferencia);
    const double iconSize = 14;
    const double containerSize = 24;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: steps.asMap().entries.map((entry) {
        final int index = entry.key;
        final Map<String, dynamic> step = entry.value;
        final bool isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: containerSize,
                          height: containerSize,
                          decoration: BoxDecoration(
                            color: step['isCompleted'] as bool
                                ? (step['color'] as Color)
                                    .withValues(alpha: 0.1)
                                : const Color(0xFF1A1A1A),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: step['isCompleted'] as bool
                                  ? step['color'] as Color
                                  : Colors.grey[800]!,
                              width: 1.5,
                            ),
                          ),
                        ),
                        FaIcon(
                          step['icon'] as IconData,
                          size: iconSize,
                          color: step['isCompleted'] as bool
                              ? step['color'] as Color
                              : Colors.grey[600],
                        ),
                        if (step['isCompleted'] as bool)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: step['color'] as Color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                              child: const FaIcon(
                                FontAwesomeIcons.check,
                                size: 6,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step['title'] as String,
                      style: TextStyle(
                        color: step['isCompleted'] as bool
                            ? Colors.white
                            : Colors.grey[600],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 1,
                    color: step['isCompleted'] as bool
                        ? step['color'] as Color
                        : Colors.grey[800],
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
