import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:condorsmotors/providers/colabs/transferencias.colab.provider.dart';
import 'package:condorsmotors/screens/colabs/widgets/transferencias/transferencia_detalle_colab.dart';
import 'package:condorsmotors/screens/colabs/widgets/transferencias/transferencia_form_colab.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class TransferenciasColabScreen extends StatefulWidget {
  const TransferenciasColabScreen({super.key});

  @override
  State<TransferenciasColabScreen> createState() =>
      _TransferenciasColabScreenState();
}

class _TransferenciasColabScreenState extends State<TransferenciasColabScreen> {
  late final TransferenciasColabProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<TransferenciasColabProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  Future<void> _initData() async {
    await _provider.inicializar();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransferenciasColabProvider>(
      builder: (context, provider, child) {
        final List<TransferenciaInventario> transferenciasFiltradas =
            provider.getTransferenciasFiltradas();
        final double screenWidth = MediaQuery.of(context).size.width;
        final bool isMobile = screenWidth < 600;

        return Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF2D2D2D),
            title: const Text(
              'Transferencias',
              style: TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: <Widget>[
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
                      if (provider.selectedFilter != 'Todos')
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
                  itemBuilder: (BuildContext context) =>
                      provider.filters.map((String filter) {
                    final bool isSelected = provider.selectedFilter == filter;
                    Color? stateColor;
                    if (filter != 'Todos') {
                      final estado = EstadoTransferencia.values.firstWhere(
                        (e) => e.nombre == filter,
                        orElse: () => EstadoTransferencia.pedido,
                      );
                      stateColor = _getEstadoColor(estado);
                    }

                    return PopupMenuItem<String>(
                      value: filter,
                      child: Row(
                        children: <Widget>[
                          if (isSelected)
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(Icons.check,
                                  size: 18, color: Colors.white),
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
                    provider.cambiarFiltro(filter);
                  },
                ),
              ),
              IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.arrowsRotate,
                  color: Colors.white,
                ),
                onPressed: provider.cargarTransferencias,
                tooltip: 'Recargar',
              ),
            ],
          ),
          body: _buildBody(provider, transferenciasFiltradas, isMobile),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showCreateTransferenciaDialog(context),
            icon: const FaIcon(FontAwesomeIcons.plus),
            label: const Text('Nueva'),
            backgroundColor: const Color(0xFFE31E24),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    TransferenciasColabProvider provider,
    List<TransferenciaInventario> transferenciasFiltradas,
    bool isMobile,
  ) {
    return Column(
      children: <Widget>[
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
                            'TRANSFERENCIAS',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'gestión de transferencias',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (provider.selectedFilter != 'Todos')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getEstadoColor(
                            EstadoTransferencia.values.firstWhere(
                          (e) => e.nombre == provider.selectedFilter,
                          orElse: () => EstadoTransferencia.pedido,
                        )).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getEstadoColor(
                              EstadoTransferencia.values.firstWhere(
                            (e) => e.nombre == provider.selectedFilter,
                            orElse: () => EstadoTransferencia.pedido,
                          )),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          FaIcon(
                            _getEstadoIcon(
                                EstadoTransferencia.values.firstWhere(
                              (e) => e.nombre == provider.selectedFilter,
                              orElse: () => EstadoTransferencia.pedido,
                            )),
                            size: 14,
                            color: _getEstadoColor(
                                EstadoTransferencia.values.firstWhere(
                              (e) => e.nombre == provider.selectedFilter,
                              orElse: () => EstadoTransferencia.pedido,
                            )),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            provider.selectedFilter,
                            style: TextStyle(
                              color: _getEstadoColor(
                                  EstadoTransferencia.values.firstWhere(
                                (e) => e.nombre == provider.selectedFilter,
                                orElse: () => EstadoTransferencia.pedido,
                              )),
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
        Expanded(
          child: provider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
                  ),
                )
              : transferenciasFiltradas.isEmpty
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
                            'No hay transferencias ${provider.selectedFilter != 'Todos' ? provider.selectedFilter.toLowerCase() : ''}',
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
                      itemCount: transferenciasFiltradas.length,
                      itemBuilder: (BuildContext context, int index) {
                        final TransferenciaInventario transferencia =
                            transferenciasFiltradas[index];
                        return _buildTransferenciaCard(
                            transferencia, isMobile, provider);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildTransferenciaCard(
    TransferenciaInventario transferencia,
    bool isMobile,
    TransferenciasColabProvider provider,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        _getEstadoColor(transferencia.estado).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FaIcon(
                    _getEstadoIcon(transferencia.estado),
                    color: _getEstadoColor(transferencia.estado),
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
                            'TRF${transferencia.id}',
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
                              color: _getEstadoColor(transferencia.estado)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              transferencia.estado.nombre,
                              style: TextStyle(
                                color: _getEstadoColor(transferencia.estado),
                                fontSize: isMobile ? 10 : 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
                              '${transferencia.getCantidadTotal()} productos',
                              style: const TextStyle(
                                color: Color(0xFFE31E24),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sucursal Destino: ${transferencia.nombreSucursalDestino}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                      if (transferencia.nombreSucursalOrigen != null)
                        Text(
                          'Sucursal Origen: ${transferencia.nombreSucursalOrigen}',
                          style: TextStyle(
                            color: const Color(0xFF43A047),
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.eye,
                        color: Colors.white70,
                        size: 18,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransferenciaDetalleColab(
                              transferenciaid: transferencia.id.toString(),
                            ),
                          ),
                        );
                      },
                      tooltip: 'Ver detalle',
                    ),
                  ],
                ),
                if (transferencia.estado == EstadoTransferencia.enviado)
                  ElevatedButton.icon(
                    onPressed: () => _showValidationDialog(transferencia),
                    icon: FaIcon(FontAwesomeIcons.check,
                        size: isMobile ? 14 : 16),
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
          Padding(
            padding: EdgeInsets.all(isMobile ? 8 : 16),
            child: _buildTimeline(transferencia, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(TransferenciaInventario transferencia, bool isMobile) {
    final List<Map<String, Object?>> steps = <Map<String, Object?>>[
      <String, Object?>{
        'title': EstadoTransferencia.pedido.nombre,
        'icon': _getEstadoIcon(EstadoTransferencia.pedido),
        'date': transferencia.salidaOrigen,
        'isCompleted': true,
      },
      <String, Object?>{
        'title': EstadoTransferencia.enviado.nombre,
        'icon': _getEstadoIcon(EstadoTransferencia.enviado),
        'date': null,
        'isCompleted': transferencia.estado == EstadoTransferencia.enviado ||
            transferencia.estado == EstadoTransferencia.recibido,
      },
      <String, Object?>{
        'title': EstadoTransferencia.recibido.nombre,
        'icon': _getEstadoIcon(EstadoTransferencia.recibido),
        'date': transferencia.llegadaDestino,
        'isCompleted': transferencia.estado == EstadoTransferencia.recibido,
      },
    ];

    return Row(
      children: steps
          .asMap()
          .entries
          .map((MapEntry<int, Map<String, Object?>> entry) {
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

  void _showValidationDialog(TransferenciaInventario transferencia) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
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
                    onPressed: () => Navigator.pop(dialogContext),
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
                                'Transferencia: TRF${transferencia.id}',
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
                                  color: _getEstadoColor(transferencia.estado)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  transferencia.estado.nombre,
                                  style: TextStyle(
                                    color:
                                        _getEstadoColor(transferencia.estado),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Solicitante: Sin información',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          Text(
                            'Origen: ${transferencia.nombreSucursalOrigen}',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          Text(
                            'Destino: ${transferencia.nombreSucursalDestino}',
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
                    if (transferencia.productos != null &&
                        transferencia.productos!.isNotEmpty)
                      ...transferencia.productos!
                          .map<Widget>((DetalleProducto detalle) {
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
                                  color:
                                      const Color(0xFFE31E24).withOpacity(0.1),
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
                                    if (detalle.codigo != null)
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
                                  color:
                                      const Color(0xFFE31E24).withOpacity(0.1),
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
                          'No hay productos registrados para esta transferencia',
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
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      await _validarRecepcion(transferencia);
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

  Future<void> _validarRecepcion(TransferenciaInventario transferencia) async {
    await _provider.validarRecepcion(transferencia);
  }

  Color _getEstadoColor(EstadoTransferencia estado) {
    switch (estado) {
      case EstadoTransferencia.pedido:
        return Colors.orange;
      case EstadoTransferencia.enviado:
        return Colors.blue;
      case EstadoTransferencia.recibido:
        return const Color(0xFF43A047);
    }
  }

  IconData _getEstadoIcon(EstadoTransferencia estado) {
    switch (estado) {
      case EstadoTransferencia.pedido:
        return FontAwesomeIcons.clock;
      case EstadoTransferencia.enviado:
        return FontAwesomeIcons.truckFast;
      case EstadoTransferencia.recibido:
        return FontAwesomeIcons.checkDouble;
    }
  }

  Future<void> _showCreateTransferenciaDialog(BuildContext context) async {
    if (_provider.sucursalId == null || _provider.empleadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo obtener información del usuario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final BuildContext dialogContext = context;
    showDialog(
      context: dialogContext,
      builder: (BuildContext context) => TransferenciaFormColab(
        onSave: (int sucursalDestino, List<DetalleProducto> productos) async {
          try {
            final bool success = await _provider.crearTransferencia(
              sucursalDestino,
              productos,
            );

            if (context.mounted) {
              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Transferencia creada exitosamente'
                        : 'Error al crear la transferencia',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al crear transferencia: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        sucursalId: _provider.sucursalId!,
      ),
    );
  }
}
