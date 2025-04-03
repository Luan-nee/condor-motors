// Importamos la variable global api
import 'package:condorsmotors/models/movimiento.model.dart';
import 'package:condorsmotors/providers/admin/movimiento.admin.provider.dart';
import 'package:condorsmotors/screens/admin/widgets/movimiento/movimiento_detail_dialog.dart'; // Importamos el nuevo widget unificado
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
  String _filtroEstado = 'Todos';
  String? _filtroSucursal;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

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

    final MovimientoProvider movimientoProvider =
        Provider.of<MovimientoProvider>(context, listen: false);

    await movimientoProvider.cargarMovimientos(
      sucursalId: _filtroSucursal,
      estado: _filtroEstado,
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
      forceRefresh: forceRefresh,
    );

    // Si hay error, mostrar snackbar
    if (movimientoProvider.errorMensaje != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(movimientoProvider.errorMensaje!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MovimientoProvider>(
        builder: (context, movimientoProvider, child) {
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
                              value: _filtroEstado,
                              dropdownColor: const Color(0xFF2D2D2D),
                              style: const TextStyle(color: Colors.white),
                              underline: const SizedBox(),
                              items: <DropdownMenuItem<String>>[
                                const DropdownMenuItem(
                                    value: 'Todos',
                                    child: Text('Todos los estados')),
                                ...movimientoProvider
                                    .obtenerEstadosDetalle()
                                    .entries
                                    .map(
                                      (MapEntry<String, String> e) =>
                                          DropdownMenuItem(
                                              value: e.key,
                                              child: Text(e.value)),
                                    ),
                              ],
                              onChanged: (String? value) {
                                if (value != null) {
                                  setState(() => _filtroEstado = value);
                                  _cargarMovimientos(forceRefresh: true);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      // Botón de refrescar
                      ElevatedButton.icon(
                        icon: const FaIcon(FontAwesomeIcons.arrowsRotate,
                            size: 16, color: Colors.white),
                        label: const Text('Actualizar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0075FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                        onPressed: () => _cargarMovimientos(forceRefresh: true),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Indicador de carga o error
              if (movimientoProvider.cargando)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      color: Color(0xFFE31E24),
                    ),
                  ),
                )
              else if (movimientoProvider.errorMensaje != null)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        movimientoProvider.errorMensaje!,
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
              else if (movimientoProvider.movimientos.isEmpty)
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
                // Tabla de movimientos
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
                          // Encabezado de la tabla
                          Container(
                            color: const Color(0xFF2D2D2D),
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 20),
                            child: const Row(
                              children: <Widget>[
                                // Fecha solicitada (15%)
                                Expanded(
                                  flex: 15,
                                  child: Row(
                                    children: <Widget>[
                                      FaIcon(
                                        FontAwesomeIcons.calendar,
                                        color: Color(0xFFE31E24),
                                        size: 14,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Fecha solicitada',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // ID (15%)
                                Expanded(
                                  flex: 15,
                                  child: Row(
                                    children: <Widget>[
                                      FaIcon(
                                        FontAwesomeIcons.calendar,
                                        color: Color(0xFFE31E24),
                                        size: 14,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Fecha recibida',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Origen (20%)
                                Expanded(
                                  flex: 20,
                                  child: Text(
                                    'Origen',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Destino (20%)
                                Expanded(
                                  flex: 20,
                                  child: Text(
                                    'Destino',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Estado (15%)
                                Expanded(
                                  flex: 15,
                                  child: Text(
                                    'Estado',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Columna para acciones
                                SizedBox(
                                  width: 60,
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

                          // Filas de movimientos
                          ...movimientoProvider.movimientos.map((Movimiento
                                  movimiento) =>
                              InkWell(
                                // Eliminamos el onTap para no abrir al hacer clic en cualquier parte de la fila
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 20),
                                  child: Row(
                                    children: <Widget>[
                                      // Fecha solicitada
                                      Expanded(
                                        flex: 15,
                                        child: Row(
                                          children: <Widget>[
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2D2D2D),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Center(
                                                child: FaIcon(
                                                  FontAwesomeIcons.calendar,
                                                  color: Color(0xFFE31E24),
                                                  size: 14,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              _formatFecha(
                                                  movimiento.salidaOrigen),
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // ID
                                      Expanded(
                                        flex: 15,
                                        child: Row(
                                          children: <Widget>[
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2D2D2D),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Center(
                                                child: FaIcon(
                                                  FontAwesomeIcons.calendar,
                                                  color: Color(0xFFE31E24),
                                                  size: 14,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              _formatFecha(
                                                  movimiento.llegadaDestino),
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Origen
                                      Expanded(
                                        flex: 20,
                                        child: Text(
                                          movimiento.nombreSucursalOrigen,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ),
                                      // Destino
                                      Expanded(
                                        flex: 20,
                                        child: Text(
                                          movimiento.nombreSucursalDestino,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ),
                                      // Estado
                                      Expanded(
                                        flex: 15,
                                        child:
                                            _buildEstadoCell(movimiento.estado),
                                      ),
                                      // Columna de acciones
                                      SizedBox(
                                        width: 60,
                                        child: Center(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF222222),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: const Color(0xFFE31E24)
                                                    .withOpacity(0.2),
                                              ),
                                            ),
                                            child: IconButton(
                                              onPressed: () =>
                                                  _mostrarDetalleMovimiento(
                                                      movimiento),
                                              icon: const FaIcon(
                                                FontAwesomeIcons
                                                    .magnifyingGlass,
                                                color: Color(0xFFE31E24),
                                                size: 14,
                                              ),
                                              tooltip: 'Ver detalles',
                                              constraints: const BoxConstraints(
                                                minWidth: 36,
                                                minHeight: 36,
                                              ),
                                              padding: EdgeInsets.zero,
                                              splashRadius: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
    });
  }

  // Función para mostrar el detalle de un movimiento
  void _mostrarDetalleMovimiento(Movimiento movimiento) async {
    // Verificar si estamos montados
    if (!mounted) {
      return;
    }

    debugPrint(
        '🔍 Iniciando visualización de detalles para movimiento #${movimiento.id}');

    // Usamos el nuevo widget que maneja internamente los estados
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return MovimientoDetailDialog(movimiento: movimiento);
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

  Widget _buildEstadoCell(String estado) {
    final MovimientoProvider movimientoProvider =
        Provider.of<MovimientoProvider>(context, listen: false);
    final Map<String, dynamic> estiloEstado =
        movimientoProvider.obtenerEstiloEstado(estado);

    final Color backgroundColor = estiloEstado['backgroundColor'];
    final Color textColor = estiloEstado['textColor'];
    final IconData iconData = estiloEstado['iconData'];
    final String tooltipText = estiloEstado['tooltipText'];
    final String estadoDisplay = estiloEstado['estadoDisplay'];

    return Container(
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: Tooltip(
        message: tooltipText,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: textColor.withOpacity(0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FaIcon(
                iconData,
                color: textColor,
                size: 12,
              ),
              const SizedBox(width: 8),
              Text(
                estadoDisplay,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
