// Importamos la variable global api
import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:condorsmotors/providers/admin/transferencias.admin.provider.dart';
import 'package:condorsmotors/screens/admin/widgets/movimiento/transferencia_detail_dialog.dart'; // Importamos el nuevo widget unificado
import 'package:condorsmotors/utils/transferencias_utils.dart';
import 'package:condorsmotors/widgets/paginador.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MovimientosAdminScreen extends StatefulWidget {
  const MovimientosAdminScreen({super.key});

  @override
  State<MovimientosAdminScreen> createState() => _MovimientosAdminScreenState();
}

class _MovimientosAdminScreenState extends State<MovimientosAdminScreen> {
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

    final TransferenciasProvider transferenciasProvider =
        Provider.of<TransferenciasProvider>(context, listen: false);

    // Actualizamos los filtros en el provider
    transferenciasProvider.actualizarFiltros(
      fechaInicio: transferenciasProvider.fechaInicio,
      fechaFin: transferenciasProvider.fechaFin,
    );

    await transferenciasProvider.cargarTransferencias(
      forceRefresh: forceRefresh,
    );

    // Si hay error, mostrar snackbar
    if (transferenciasProvider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(transferenciasProvider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Botón de refrescar
  Widget _buildRefreshButton(TransferenciasProvider transferenciasProvider) {
    return ElevatedButton.icon(
      icon: transferenciasProvider.isLoading
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
        transferenciasProvider.isLoading ? 'Recargando...' : 'Recargar',
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
      onPressed: transferenciasProvider.isLoading
          ? null
          : () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await transferenciasProvider.recargarDatos();

              if (!mounted) return;

              if (transferenciasProvider.errorMessage != null) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(transferenciasProvider.errorMessage!),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Datos recargados exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransferenciasProvider>(
        builder: (context, transferenciasProvider, child) {
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
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Filtros
                  Row(
                    children: <Widget>[
                      // Filtro por estado
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        margin: const EdgeInsets.only(right: 12),
                        child: Row(
                          children: <Widget>[
                            const FaIcon(
                              FontAwesomeIcons.filter,
                              color: Color(0xFFE31E24),
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: transferenciasProvider.selectedFilter,
                              dropdownColor: const Color(0xFF2D2D2D),
                              style: const TextStyle(color: Colors.white),
                              underline: const SizedBox(),
                              items: <DropdownMenuItem<String>>[
                                const DropdownMenuItem(
                                    value: 'Todos',
                                    child: Text('Todos los estados')),
                                ...transferenciasProvider.filters
                                    .where((filter) => filter != 'Todos')
                                    .map(
                                      (String filter) => DropdownMenuItem(
                                          value: filter, child: Text(filter)),
                                    ),
                              ],
                              onChanged: (String? value) {
                                if (value != null) {
                                  transferenciasProvider.cambiarFiltro(value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      // Botón de refrescar
                      _buildRefreshButton(transferenciasProvider),
                      ElevatedButton.icon(
                        icon: transferenciasProvider.isLoading
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
                          transferenciasProvider.isLoading
                              ? 'Recargando...'
                              : 'Recargar',
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
                        onPressed: transferenciasProvider.isLoading
                            ? null
                            : () async {
                                await transferenciasProvider.recargarDatos();
                                if (mounted &&
                                    transferenciasProvider.errorMessage !=
                                        null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          transferenciasProvider.errorMessage!),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Datos recargados exitosamente'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Encabezado de la tabla
              Container(
                color: const Color(0xFF2D2D2D),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  children: const <Widget>[
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

              // Indicador de carga o error
              if (transferenciasProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      color: Color(0xFFE31E24),
                    ),
                  ),
                )
              else if (transferenciasProvider.errorMessage != null)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        transferenciasProvider.errorMessage!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _cargarMovimientos(forceRefresh: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE31E24),
                        ),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              else if (transferenciasProvider.transferencias.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const FaIcon(
                          FontAwesomeIcons.boxOpen,
                          color: Colors.white38,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay transferencias disponibles',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              _cargarMovimientos(forceRefresh: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE31E24),
                          ),
                          child: const Text('Refrescar'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // Tabla de movimientos con paginación
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                ...transferenciasProvider.transferencias.map(
                                    (TransferenciaInventario transferencia) =>
                                        _buildTransferenciaRow(transferencia)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Paginador
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        child: Paginador(
                          paginacionProvider:
                              transferenciasProvider.paginacionProvider,
                          backgroundColor: const Color(0xFF1A1A1A),
                          textColor: Colors.white,
                          accentColor: const Color(0xFFE31E24),
                          radius: 8,
                          mostrarOrdenacion: true,
                          camposParaOrdenar: const [
                            {
                              'value': 'salidaOrigen',
                              'label': 'Fecha de Salida'
                            },
                            {
                              'value': 'llegadaDestino',
                              'label': 'Fecha de Llegada'
                            },
                            {'value': 'estado', 'label': 'Estado'},
                          ],
                          onPageChange: () async {
                            await transferenciasProvider.cargarTransferencias();
                          },
                          onPageChanged: (page) async {
                            await transferenciasProvider.cambiarPagina(page);
                          },
                          onPageSizeChanged: (pageSize) async {
                            await transferenciasProvider
                                .cambiarTamanoPagina(pageSize);
                          },
                          onSortByChanged: (sortBy) async {
                            await transferenciasProvider
                                .cambiarOrdenarPor(sortBy);
                          },
                          onOrderChanged: (order) async {
                            await transferenciasProvider.cambiarOrden(order);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  // Función para mostrar el detalle de un movimiento
  void _mostrarDetalleMovimiento(TransferenciaInventario transferencia) async {
    if (!mounted) {
      return;
    }

    debugPrint(
        '🔍 Iniciando visualización de detalles para transferencia #${transferencia.id}');

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return TransferenciaDetailDialog(transferencia: transferencia);
      },
    );

    debugPrint('✅ Diálogo de detalles cerrado correctamente');
  }

  // Formato de fecha
  String _formatFecha(DateTime? fecha) {
    if (fecha == null) {
      return 'N/A';
    }
    try {
      return DateFormat('dd/MM/yyyy').format(fecha);
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  // Actualizar el widget de la fila de transferencia
  Widget _buildTransferenciaRow(TransferenciaInventario transferencia) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: <Widget>[
          // Fechas (25%)
          Expanded(
            flex: 25,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.calendar,
                        color: Color(0xFFE31E24),
                        size: 14,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.arrowUp,
                            size: 10,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatFecha(transferencia.salidaOrigen),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.arrowDown,
                            size: 10,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatFecha(transferencia.llegadaDestino),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
                              : Colors.white.withOpacity(0.5),
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
                                ? (step['color'] as Color).withOpacity(0.1)
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
