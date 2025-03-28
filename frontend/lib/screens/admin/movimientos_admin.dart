import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../api/index.api.dart';
import '../../api/protected/movimientos.api.dart'; // Importación para acceder a MovimientosApi.estadosDetalle
// Importamos la variable global api
import '../../main.dart' show api;
import '../../models/movimiento.model.dart';
import 'widgets/movimiento_detail_dialog.dart'; // Importamos el nuevo widget unificado

class MovimientosAdminScreen extends StatefulWidget {
  const MovimientosAdminScreen({super.key});

  @override
  State<MovimientosAdminScreen> createState() => _MovimientosAdminScreenState();
}

class _MovimientosAdminScreenState extends State<MovimientosAdminScreen> {
  List<Movimiento> _movimientos = [];
  bool _cargando = true;
  String _filtroEstado = 'Todos';
  String? _filtroSucursal;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    _cargarMovimientos();
  }

  Future<void> _cargarMovimientos({bool forceRefresh = false}) async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _errorMensaje = null;
      });
    }

    try {
      final movimientos = await api.movimientos.getMovimientos(
        sucursalId: _filtroSucursal,
        estado: _filtroEstado != 'Todos' ? _filtroEstado.toUpperCase() : null,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _movimientos = movimientos;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMensaje = 'Error al cargar las transferencias: $e';
          _cargando = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMensaje!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.truck,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                  children: [
                    // Filtro por estado
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      margin: const EdgeInsets.only(right: 12),
                      child: Row(
                        children: [
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
                            items: [
                              const DropdownMenuItem(
                                  value: 'Todos',
                                  child: Text('Todos los estados')),
                              ...MovimientosApi.estadosDetalle.entries.map(
                                (e) => DropdownMenuItem(
                                    value: e.key, child: Text(e.value)),
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
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.arrowsRotate,
                          size: 16, color: Colors.white),
                      onPressed: () => _cargarMovimientos(forceRefresh: true),
                      tooltip: 'Refrescar datos',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Indicador de carga o error
            if (_cargando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Color(0xFFE31E24),
                  ),
                ),
              )
            else if (_errorMensaje != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _errorMensaje!,
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
            else if (_movimientos.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                        onPressed: () => _cargarMovimientos(forceRefresh: true),
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
                      children: [
                        // Encabezado de la tabla
                        Container(
                          color: const Color(0xFF2D2D2D),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          child: const Row(
                            children: [
                              // Fecha solicitada (15%)
                              Expanded(
                                flex: 15,
                                child: Row(
                                  children: [
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
                              // // ID (15%)
                              // Expanded(
                              //   flex: 15,
                              //   child: Text(
                              //     'ID',
                              //     style: TextStyle(
                              //       color: Colors.white,
                              //       fontWeight: FontWeight.bold,
                              //     ),
                              //   ),
                              // ),
                              // Solicitante (15%)
                              // Expanded(
                              //   flex: 15,
                              //   child: Text(
                              //     'Solicitante',
                              //     style: TextStyle(
                              //       color: Colors.white,
                              //       fontWeight: FontWeight.bold,
                              //     ),
                              //   ),
                              // ),
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
                        ..._movimientos.map((movimiento) => InkWell(
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
                                  children: [
                                    // Fecha solicitada
                                    Expanded(
                                      flex: 15,
                                      child: Row(
                                        children: [
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
                                    // Expanded(
                                    //   flex: 15,
                                    //   child: Text(
                                    //     movimiento.id.toString(),
                                    //     style: const TextStyle(color: Colors.white),
                                    //   ),
                                    // ),
                                    // // Solicitante
                                    // Expanded(
                                    //   flex: 15,
                                    //   child: Row(
                                    //     children: [
                                    //       Container(
                                    //         padding: const EdgeInsets.symmetric(
                                    //           horizontal: 12,
                                    //           vertical: 6,
                                    //         ),
                                    //         decoration: BoxDecoration(
                                    //           color: const Color(0xFF2D2D2D),
                                    //           borderRadius: BorderRadius.circular(8),
                                    //         ),
                                    //         child: Row(
                                    //           mainAxisSize: MainAxisSize.min,
                                    //           children: [
                                    //             const FaIcon(
                                    //               FontAwesomeIcons.user,
                                    //               color: Colors.white54,
                                    //               size: 12,
                                    //             ),
                                    //             const SizedBox(width: 8),
                                    //             Text(
                                    //               movimiento.solicitante ?? 'N/A',
                                    //               style: const TextStyle(
                                    //                 color: Colors.white,
                                    //                 fontSize: 13,
                                    //               ),
                                    //             ),
                                    //           ],
                                    //         ),
                                    //       ),
                                    //     ],
                                    //   ),
                                    // ),
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
                                              FontAwesomeIcons.magnifyingGlass,
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
  }

  // Función para mostrar el detalle de un movimiento
  void _mostrarDetalleMovimiento(Movimiento movimiento) async {
    // Verificar si estamos montados
    if (!mounted) return;

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
    if (fecha == null) return 'N/A';
    try {
      return DateFormat('dd/MM/yyyy').format(fecha);
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  Widget _buildEstadoCell(String estado) {
    Color backgroundColor;
    Color textColor = Colors.white;
    IconData iconData;
    String tooltipText;
    final String estadoDisplay =
        MovimientosApi.estadosDetalle[estado] ?? estado;

    switch (estado.toUpperCase()) {
      case 'COMPLETADO':
        backgroundColor = const Color(0xFF2D8A3B).withOpacity(0.15);
        textColor = const Color(0xFF4CAF50);
        iconData = FontAwesomeIcons.circleCheck;
        tooltipText = 'Movimiento completado';
        break;
      case 'EN_PROCESO':
        backgroundColor = const Color(0xFFFFA000).withOpacity(0.15);
        textColor = const Color(0xFFFFA000);
        iconData = FontAwesomeIcons.clockRotateLeft;
        tooltipText = 'En proceso';
        break;
      case 'ENTREGADO':
        backgroundColor = const Color(0xFF009688).withOpacity(0.15);
        textColor = const Color(0xFF009688);
        iconData = FontAwesomeIcons.truckRampBox;
        tooltipText = 'Entregado';
        break;
      case 'EN_TRANSITO':
        backgroundColor = const Color(0xFF1976D2).withOpacity(0.15);
        textColor = const Color(0xFF1976D2);
        iconData = FontAwesomeIcons.truckMoving;
        tooltipText = 'En tránsito';
        break;
      case 'PENDIENTE':
      default:
        backgroundColor = const Color(0xFF757575).withOpacity(0.15);
        textColor = const Color(0xFF9E9E9E);
        iconData = FontAwesomeIcons.hourglassHalf;
        tooltipText = 'Pendiente';
    }

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
            children: [
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
