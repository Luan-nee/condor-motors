import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/movimiento.model.dart';
import 'package:condorsmotors/screens/colabs/widgets/movimiento_request_dialog.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MovimientosColabScreen extends StatefulWidget {
  const MovimientosColabScreen({super.key});

  @override
  State<MovimientosColabScreen> createState() => _MovimientosColabScreenState();
}

class _MovimientosColabScreenState extends State<MovimientosColabScreen> {
  bool _isLoading = false;
  String _selectedFilter = 'Todos';
  late final MovimientosApi _movimientosApi;
  List<Movimiento> _movimientos = <Movimiento>[];
  String? _sucursalId;
  int? _empleadoId;

  // Filtros disponibles
  final List<String> _filters = <String>[
    'Todos',
    'Pendientes',
    'Preparados',
    'Despachados',
    'Recibidos',
    'Anulados'
  ];

  // Usuario actual (se obtendrá de la sesión)

  @override
  void initState() {
    super.initState();
    _movimientosApi = api.movimientos;
    _obtenerDatosUsuario();
  }

  // Obtener datos del usuario y cargar movimientos
  Future<void> _obtenerDatosUsuario() async {
    setState(() => _isLoading = true);
    
    try {
      // Obtener datos del usuario autenticado
      final Map<String, dynamic>? userData = await api.authService.getUserData();
      if (userData != null) {
        setState(() {
          _sucursalId = userData['sucursalId']?.toString();
          _empleadoId = int.tryParse(userData['id']?.toString() ?? '0');
        });
        
        debugPrint('Usuario obtenido: ID=$_empleadoId, SucursalID=$_sucursalId');
      } else {
        debugPrint('No se pudieron obtener datos del usuario');
      }
    } catch (e) {
      debugPrint('Error al obtener datos del usuario: $e');
    } finally {
      // Cargar movimientos después de obtener los datos del usuario
      await _cargarMovimientos();
    }
  }

  // Cargar movimientos desde la API
  Future<void> _cargarMovimientos() async {
    if (_sucursalId == null) {
      debugPrint('No se puede cargar movimientos: ID de sucursal no disponible');
      setState(() => _isLoading = false);
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      debugPrint('Cargando movimientos para sucursal ID: $_sucursalId');
      
      // Determinar si se debe aplicar un filtro de estado
      String? estadoFiltro;
      if (_selectedFilter != 'Todos') {
        estadoFiltro = _selectedFilter.toUpperCase().replaceAll('ES', '');
      }
      
      // Obtener movimientos desde la API
      final List<Movimiento> movimientosData = await _movimientosApi.getMovimientos(
        sucursalId: _sucursalId,
        estado: estadoFiltro,
        forceRefresh: true, // Forzar actualización desde el servidor
      );
      
      if (!mounted) {
        return;
      }
      
      setState(() {
        _movimientos = movimientosData;
        _isLoading = false;
      });
      
      debugPrint('Movimientos cargados: ${_movimientos.length}');
    } catch (e) {
      debugPrint('Error al cargar movimientos: $e');
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar movimientos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Obtener movimientos filtrados según el filtro seleccionado
  List<Movimiento> _getMovimientosFiltrados() {
    if (_selectedFilter == 'Todos') {
      return _movimientos;
    }
    
    final String estadoFiltro = _selectedFilter.toUpperCase().replaceAll('ES', '');
    return _movimientos.where((Movimiento m) => m.estado == estadoFiltro).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<Movimiento> movimientosFiltrados = _getMovimientosFiltrados();
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Movimientos',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: <Widget>[
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
                children: <Widget>[
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
              itemBuilder: (BuildContext context) => _filters.map((String filter) {
                final bool isSelected = _selectedFilter == filter;
                Color? stateColor;
                if (filter != 'Todos') {
                  stateColor = _getEstadoColor(
                    filter.toUpperCase().replaceAll('ES', '')
                  );
                }
                
                return PopupMenuItem<String>(
                  value: filter,
                  child: Row(
                    children: <Widget>[
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
              onSelected: (String filter) {
                setState(() {
                  _selectedFilter = filter;
                });
                // Recargar movimientos si cambia el filtro
                if (filter != 'Todos') {
                  _cargarMovimientos();
                }
              },
            ),
          ),
          IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.arrowsRotate,
              color: Colors.white,
            ),
            onPressed: _cargarMovimientos,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
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
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const FaIcon(
                          FontAwesomeIcons.truck,
                          size: 20,
                          color: Color(0xFFE31E24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
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
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
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
                          children: <Widget>[
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
                        itemBuilder: (BuildContext context, int index) {
                          final Movimiento movimiento = movimientosFiltrados[index];
                          return _buildMovimientoCard(movimiento, isMobile);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_sucursalId == null || _empleadoId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: No se pudo obtener información del usuario'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          
          showDialog(
            context: context,
            builder: (BuildContext context) => MovimientoRequestDialog(
              onSave: (MovimientoStock movimientoData) async {
                try {
                  setState(() => _isLoading = true);
                  
                  // Crear movimiento usando la API
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Movimiento creado exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    
                    // Recargar movimientos para mostrar el nuevo
                    await _cargarMovimientos();
                  }
                } catch (e) {
                  debugPrint('Error al crear movimiento: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al crear movimiento: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    setState(() => _isLoading = false);
                  }
                }
              },
              usuarioId: _empleadoId.toString(),
              localId: int.parse(_sucursalId!),
            ),
          );
        },
        icon: const FaIcon(FontAwesomeIcons.plus),
        label: const Text('Nueva'),
        backgroundColor: const Color(0xFFE31E24),
      ),
    );
  }

  Widget _buildMovimientoCard(Movimiento movimiento, bool isMobile) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          // Encabezado del movimiento
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(movimiento.estado).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FaIcon(
                    _getEstadoIcon(movimiento.estado),
                    color: _getEstadoColor(movimiento.estado),
                    size: isMobile ? 16 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text(
                            'MOV${movimiento.id}',
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
                              color: _getEstadoColor(movimiento.estado).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              movimiento.estado,
                              style: TextStyle(
                                color: _getEstadoColor(movimiento.estado),
                                fontSize: isMobile ? 10 : 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Solicitado por: ${movimiento.solicitante ?? 'Desconocido'}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (movimiento.estado == 'DESPACHADO')
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
              children: <Widget>[
                if (movimiento.productos != null && movimiento.productos!.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: movimiento.productos!.length,
                    itemBuilder: (BuildContext context, int index) {
                      final DetalleProducto detalle = movimiento.productos![index];
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
                          children: <Widget>[
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
                                children: <Widget>[
                                  Text(
                                    detalle.nombre,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Código: ${detalle.codigo}',
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
                              children: <Widget>[
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
                                    'Cant: ${detalle.cantidad}',
                                    style: const TextStyle(
                                      color: Color(0xFFE31E24),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                if (detalle.cantidad > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Rec: ${detalle.cantidad}',
                                      style: TextStyle(
                                        color: Colors.green,
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
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No hay productos registrados para este movimiento',
                      style: TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(Movimiento movimiento, bool isMobile) {
    final List<Map<String, Object?>> steps = <Map<String, Object?>>[
      <String, Object?>{
        'title': 'Solicitado',
        'icon': FontAwesomeIcons.fileLines,
        'date': movimiento.salidaOrigen,
        'isCompleted': true,
      },
      <String, Object?>{
        'title': 'Preparado',
        'icon': FontAwesomeIcons.boxOpen,
        'date': null,
        'isCompleted': movimiento.estado == 'PREPARADO' || 
                       movimiento.estado == 'DESPACHADO' || 
                       movimiento.estado == 'RECIBIDO',
      },
      <String, Object?>{
        'title': 'Despachado',
        'icon': FontAwesomeIcons.truckFast,
        'date': null,
        'isCompleted': movimiento.estado == 'DESPACHADO' || 
                       movimiento.estado == 'RECIBIDO',
      },
      <String, Object?>{
        'title': 'Recibido',
        'icon': FontAwesomeIcons.check,
        'date': movimiento.llegadaDestino,
        'isCompleted': movimiento.estado == 'RECIBIDO',
      },
    ];

    return Row(
      children: steps.asMap().entries.map((MapEntry<int, Map<String, Object?>> entry) {
        final int index = entry.key;
        final Map<String, Object?> step = entry.value;
        final bool isLast = index == steps.length - 1;
        final DateTime? date = step['date'] as DateTime?;
        final String? formattedDate = date != null 
            ? '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}'
            : null;

        return Expanded(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
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
                    if (formattedDate != null)
                      Text(
                        formattedDate,
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
  void _showValidationDialog(Movimiento movimiento) {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
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
                children: <Widget>[
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
                  children: <Widget>[
                    // Información del movimiento
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                'Movimiento: MOV${movimiento.id}',
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
                                  color: _getEstadoColor(movimiento.estado)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  movimiento.estado,
                                  style: TextStyle(
                                    color: _getEstadoColor(movimiento.estado),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Solicitante: ${movimiento.solicitante ?? 'Sin información'}',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          Text(
                            'Origen: ${movimiento.nombreSucursalOrigen}',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          Text(
                            'Destino: ${movimiento.nombreSucursalDestino}',
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
                    if (movimiento.productos != null && movimiento.productos!.isNotEmpty)
                      ...movimiento.productos!.map<Widget>((DetalleProducto detalle) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D2D2D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: <Widget>[
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
                                  children: <Widget>[
                                    Text(
                                      detalle.nombre,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Código: ${detalle.codigo}',
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
                                  '${detalle.cantidad} unidades',
                                  style: const TextStyle(
                                    color: Color(0xFFE31E24),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                    else
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No hay productos registrados para este movimiento',
                          style: TextStyle(color: Colors.white54),
                          textAlign: TextAlign.center,
                        ),
                      ),
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
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _validarRecepcion(movimiento);
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
  
  // Método para validar la recepción de un movimiento
  Future<void> _validarRecepcion(Movimiento movimiento) async {
    setState(() => _isLoading = true);
    
    try {
      // Actualizar estado del movimiento a RECIBIDO
      await _movimientosApi.cambiarEstado(
        movimiento.id.toString(),
        'RECIBIDO',
        observacion: 'Recepción validada correctamente',
      );
      
      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recepción validada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Recargar movimientos
      await _cargarMovimientos();
    } catch (e) {
      debugPrint('Error al validar recepción: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al validar recepción: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }
} 