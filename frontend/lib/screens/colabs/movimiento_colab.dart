import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'widgets/movimiento_request_dialog.dart';

class MovimientosColabScreen extends StatefulWidget {
  const MovimientosColabScreen({super.key});

  @override
  State<MovimientosColabScreen> createState() => _MovimientosColabScreenState();
}

class _MovimientosColabScreenState extends State<MovimientosColabScreen> {
  bool _isLoading = false;
  String _selectedFilter = 'Todos';

  // Datos de ejemplo para movimientos
  final List<Map<String, dynamic>> _movimientos = [
    {
      'id': 1,
      'codigo': 'MOV001',
      'fechaSolicitud': '2024-03-15 10:00',
      'fechaPreparacion': '2024-03-15 11:00',
      'fechaDespacho': '2024-03-15 14:00',
      'fechaRecepcion': null,
      'estado': 'DESPACHADO',
      'origen': {
        'id': 1,
        'nombre': 'Central Principal',
        'tipo': 'central',
      },
      'destino': {
        'id': 2,
        'nombre': 'Sucursal San Miguel',
        'tipo': 'sucursal',
      },
      'solicitante': {
        'id': 1,
        'nombre': 'Juan Pérez',
        'rol': 'Vendedor',
      },
      'detalles': [
        {
          'producto': {
            'id': 1,
            'codigo': 'CAS001',
            'nombre': 'Casco MT Thunder',
            'marca': 'MT Helmets',
          },
          'cantidad': 5,
          'cantidadRecibida': null,
          'estado': 'DESPACHADO',
        }
      ],
    },
    {
      'id': 2,
      'codigo': 'MOV002',
      'fechaSolicitud': '2024-03-14 15:00',
      'fechaPreparacion': null,
      'fechaDespacho': null,
      'fechaRecepcion': null,
      'estado': 'PENDIENTE',
      'origen': {
        'id': 1,
        'nombre': 'Central Principal',
        'tipo': 'central',
      },
      'destino': {
        'id': 3,
        'nombre': 'Sucursal Los Olivos',
        'tipo': 'sucursal',
      },
      'solicitante': {
        'id': 2,
        'nombre': 'María García',
        'rol': 'Vendedor',
      },
      'detalles': [
        {
          'producto': {
            'id': 2,
            'codigo': 'ACE001',
            'nombre': 'Aceite Motul 5100',
            'marca': 'Motul',
          },
          'cantidad': 10,
          'cantidadRecibida': null,
          'estado': 'PENDIENTE',
        }
      ],
    },
  ];

  // Filtros disponibles
  final List<String> _filters = [
    'Todos',
    'Pendientes',
    'Preparados',
    'Despachados',
    'Recibidos',
    'Anulados'
  ];

  // Usuario actual (simulado)
  final Map<String, dynamic> _currentUser = {
    'id': '1',
    'nombre': 'Juan Pérez',
    'rol': 'Colaborador',
    'sucursalId': 1
  };

  // Obtener movimientos filtrados según el filtro seleccionado
  List<Map<String, dynamic>> _getMovimientosFiltrados() {
    if (_selectedFilter == 'Todos') {
      return _movimientos;
    }
    return _movimientos.where((m) => 
      m['estado'] == _selectedFilter.toUpperCase().replaceAll('ES', '')
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final movimientosFiltrados = _getMovimientosFiltrados();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Movimientos',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Filtro desplegable
          Theme(
            data: Theme.of(context).copyWith(
              popupMenuTheme: PopupMenuThemeData(
                color: const Color(0xFF2D2D2D),
                textStyle: const TextStyle(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            child: PopupMenuButton<String>(
              icon: Stack(
                children: [
                  const Icon(Icons.filter_list, color: Colors.white),
                  if (_selectedFilter != 'Todos')
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE31E24),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: 'Filtrar por estado',
              itemBuilder: (context) => _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                Color? stateColor;
                if (filter != 'Todos') {
                  stateColor = _getEstadoColor(
                    filter.toUpperCase().replaceAll('ES', '')
                  );
                }
                
                return PopupMenuItem<String>(
                  value: filter,
                  child: Row(
                    children: [
                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.check, size: 18, color: Colors.white),
                        ),
                      if (stateColor != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: stateColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      Text(filter),
                    ],
                  ),
                );
              }).toList(),
              onSelected: (filter) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),
          ),
          IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.arrowsRotate,
              color: Colors.white,
            ),
            onPressed: () {
    setState(() {
      _isLoading = true;
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
                });
              });
            },
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con título y estado actual
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.truck,
                          size: 20,
                          color: Color(0xFFE31E24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                            const Text(
                              'MOVIMIENTOS',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                  Text(
                              'gestión de movimientos',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_selectedFilter != 'Todos')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                          color: _getEstadoColor(
                            _selectedFilter.toUpperCase().replaceAll('ES', '')
                          ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                            color: _getEstadoColor(
                              _selectedFilter.toUpperCase().replaceAll('ES', '')
                            ),
                        width: 1,
                      ),
                    ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(
                              _getEstadoIcon(
                                _selectedFilter.toUpperCase().replaceAll('ES', '')
                              ),
                              size: 14,
                              color: _getEstadoColor(
                                _selectedFilter.toUpperCase().replaceAll('ES', '')
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedFilter,
                      style: TextStyle(
                                color: _getEstadoColor(
                                  _selectedFilter.toUpperCase().replaceAll('ES', '')
                      ),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                    ),
                  ),
                ],
              ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de movimientos
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
                    ),
                  )
                : movimientosFiltrados.isEmpty
                    ? Center(
            child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
              children: [
                            FaIcon(
                              FontAwesomeIcons.boxOpen,
                              size: 48,
                              color: Colors.grey[600],
                            ),
                const SizedBox(height: 16),
                            Text(
                              'No hay movimientos ${_selectedFilter != 'Todos' ? _selectedFilter.toLowerCase() : ''}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(isMobile ? 8 : 16),
                        itemCount: movimientosFiltrados.length,
                        itemBuilder: (context, index) {
                          final movimiento = movimientosFiltrados[index];
                          return _buildMovimientoCard(movimiento, isMobile);
                        },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => MovimientoRequestDialog(
              onSave: (movimiento) {
                setState(() {
                  _movimientos.insert(0, {
                    'id': movimiento.id,
                    'codigo': 'MOV${movimiento.id}',
                    'fechaSolicitud': movimiento.fechaSolicitud.toString(),
                    'fechaPreparacion': null,
                    'fechaDespacho': null,
                    'fechaRecepcion': null,
                    'estado': movimiento.estado,
                    'origen': {
                      'id': movimiento.localOrigenId,
                      'nombre': 'Central Principal',
                      'tipo': 'central',
                    },
                    'destino': {
                      'id': movimiento.localDestinoId,
                      'nombre': 'Sucursal San Miguel',
                      'tipo': 'sucursal',
                    },
                    'solicitante': {
                      'id': int.parse(movimiento.solicitanteId),
                      'nombre': _currentUser['nombre'],
                      'rol': _currentUser['rol'],
                    },
                    'detalles': movimiento.detalles,
                  });
                });
              },
              usuarioId: _currentUser['id'],
              localId: _currentUser['sucursalId'],
            ),
          );
        },
        icon: const FaIcon(FontAwesomeIcons.plus),
        label: const Text('Nueva'),
        backgroundColor: const Color(0xFFE31E24),
      ),
    );
  }

  Widget _buildMovimientoCard(Map<String, dynamic> movimiento, bool isMobile) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Encabezado del movimiento
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Row(
            children: [
              Container(
                  padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: _getEstadoColor(movimiento['estado']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FaIcon(
                    _getEstadoIcon(movimiento['estado']),
                    color: _getEstadoColor(movimiento['estado']),
                    size: isMobile ? 16 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            movimiento['codigo'],
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                  decoration: BoxDecoration(
                              color: _getEstadoColor(movimiento['estado']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              movimiento['estado'],
                              style: TextStyle(
                                color: _getEstadoColor(movimiento['estado']),
                                fontSize: isMobile ? 10 : 12,
                                fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
                        'Solicitado por: ${movimiento['solicitante']['nombre']}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (movimiento['estado'] == 'DESPACHADO')
                  ElevatedButton.icon(
                    onPressed: () => _showValidationDialog(movimiento),
                    icon: FaIcon(FontAwesomeIcons.check, size: isMobile ? 14 : 16),
                    label: Text(
                      'Validar',
                      style: TextStyle(fontSize: isMobile ? 12 : 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 16,
                        vertical: isMobile ? 4 : 8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Línea de tiempo
          Padding(
            padding: EdgeInsets.all(isMobile ? 8 : 16),
            child: _buildTimeline(movimiento, isMobile),
          ),

          // Detalles de productos
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              unselectedWidgetColor: Colors.grey[600],
              colorScheme: ColorScheme.dark(
                primary: Colors.grey[400]!,
              ),
            ),
            child: ExpansionTile(
              title: Text(
                'Productos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: movimiento['detalles'].length,
                  itemBuilder: (context, index) {
                    final detalle = movimiento['detalles'][index];
                    final producto = detalle['producto'];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE31E24).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const FaIcon(
                              FontAwesomeIcons.box,
                              color: Color(0xFFE31E24),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  producto['nombre'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${producto['codigo']} - ${producto['marca']}',
            style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE31E24).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Cant: ${detalle['cantidad']}',
                                  style: const TextStyle(
                                    color: Color(0xFFE31E24),
                                    fontWeight: FontWeight.bold,
              fontSize: 12,
                                  ),
                                ),
                              ),
                              if (detalle['cantidadRecibida'] != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: detalle['cantidadRecibida'] == detalle['cantidad']
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Rec: ${detalle['cantidadRecibida']}',
                                    style: TextStyle(
                                      color: detalle['cantidadRecibida'] == detalle['cantidad']
                                          ? Colors.green
                                          : Colors.orange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(Map<String, dynamic> movimiento, bool isMobile) {
    final steps = [
      {
        'title': 'Solicitado',
        'icon': FontAwesomeIcons.fileLines,
        'date': movimiento['fechaSolicitud'],
        'isCompleted': true,
      },
      {
        'title': 'Preparado',
        'icon': FontAwesomeIcons.boxOpen,
        'date': movimiento['fechaPreparacion'],
        'isCompleted': movimiento['fechaPreparacion'] != null,
      },
      {
        'title': 'Despachado',
        'icon': FontAwesomeIcons.truckFast,
        'date': movimiento['fechaDespacho'],
        'isCompleted': movimiento['fechaDespacho'] != null,
      },
      {
        'title': 'Recibido',
        'icon': FontAwesomeIcons.check,
        'date': movimiento['fechaRecepcion'],
        'isCompleted': movimiento['fechaRecepcion'] != null,
      },
    ];

    return Row(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: isMobile ? 24 : 32,
                      height: isMobile ? 24 : 32,
                      decoration: BoxDecoration(
                        color: step['isCompleted'] as bool
                            ? const Color(0xFFE31E24)
                            : const Color(0xFF1A1A1A),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: step['isCompleted'] as bool
                              ? const Color(0xFFE31E24)
                              : Colors.grey[600]!,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: FaIcon(
                          step['icon'] as IconData,
                          color: step['isCompleted'] as bool
                              ? Colors.white
                              : Colors.grey[600],
                          size: isMobile ? 12 : 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step['title'] as String,
                      style: TextStyle(
                        color: step['isCompleted'] as bool
                            ? Colors.white
                            : Colors.grey[600],
                        fontSize: isMobile ? 10 : 12,
                      ),
                    ),
                    if (step['date'] != null)
                      Text(
                        step['date'] as String,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isMobile ? 9 : 10,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
      height: 2,
                    color: step['isCompleted'] as bool
                        ? const Color(0xFFE31E24)
                        : Colors.grey[800],
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'PENDIENTE':
        return Colors.orange;
      case 'PREPARADO':
        return Colors.blue;
      case 'DESPACHADO':
        return Colors.purple;
      case 'RECIBIDO':
        return Colors.green;
      case 'ANULADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case 'PENDIENTE':
        return FontAwesomeIcons.clock;
      case 'PREPARADO':
        return FontAwesomeIcons.boxOpen;
      case 'DESPACHADO':
        return FontAwesomeIcons.truckFast;
      case 'RECIBIDO':
        return FontAwesomeIcons.check;
      case 'ANULADO':
        return FontAwesomeIcons.ban;
      default:
        return FontAwesomeIcons.question;
    }
  }

  // Mostrar diálogo para validar recepción
  void _showValidationDialog(Map<String, dynamic> movimiento) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
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
                  const FaIcon(
                    FontAwesomeIcons.clipboardCheck,
                    size: 20,
                    color: Color(0xFFE31E24),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Validar Recepción',
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
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del movimiento
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Movimiento: ${movimiento['codigo']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getEstadoColor(movimiento['estado'])
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  movimiento['estado'],
                                  style: TextStyle(
                                    color: _getEstadoColor(movimiento['estado']),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Origen: ${movimiento['origen']['nombre']}',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          Text(
                            'Destino: ${movimiento['destino']['nombre']}',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          Text(
                            'Solicitante: ${movimiento['solicitante']['nombre']}',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Productos a recibir:',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
                    const SizedBox(height: 8),
                    // Lista de productos
                    ...movimiento['detalles'].map<Widget>((detalle) {
                      final producto = detalle['producto'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE31E24).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const FaIcon(
                                FontAwesomeIcons.box,
                                color: Color(0xFFE31E24),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    producto['nombre'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${producto['codigo']} - ${producto['marca']}',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
          ),
        ],
      ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE31E24).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${detalle['cantidad']} unidades',
                                style: const TextStyle(
                                  color: Color(0xFFE31E24),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            Container(
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
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 8),
            ElevatedButton.icon(
                    onPressed: () {
                      // Simular validación de recepción
                      setState(() {
                        movimiento['estado'] = 'RECIBIDO';
                        movimiento['fechaRecepcion'] = DateTime.now().toString();
                        for (var detalle in movimiento['detalles']) {
                          detalle['estado'] = 'RECIBIDO';
                          detalle['cantidadRecibida'] = detalle['cantidad'];
                        }
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Recepción validada correctamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const FaIcon(FontAwesomeIcons.check, size: 16),
                    label: const Text('Confirmar Recepción'),
              style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 