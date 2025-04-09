import 'package:condorsmotors/models/transferencias.model.dart';
import 'package:condorsmotors/providers/colabs/transferencias.colab.provider.dart';
import 'package:condorsmotors/screens/colabs/widgets/transferencias/transferencia_detalle_colab.dart';
import 'package:condorsmotors/screens/colabs/widgets/transferencias/transferencia_form_colab.dart';
import 'package:condorsmotors/utils/transferencias_utils.dart';
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
    debugPrint(
        'Construyendo body con ${transferenciasFiltradas.length} transferencias');
    debugPrint('Estado de carga: ${provider.isLoading}');
    debugPrint('Filtro seleccionado: ${provider.selectedFilter}');

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
                            'No hay transferencias ${provider.selectedFilter != 'Todos' ? 'en estado ${provider.selectedFilter.toLowerCase()}' : 'disponibles'}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => provider.cargarTransferencias(),
                            icon: const FaIcon(FontAwesomeIcons.arrowsRotate),
                            label: const Text('Recargar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE31E24),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.cargarTransferencias(),
                      color: const Color(0xFFE31E24),
                      child: ListView.builder(
                        padding: EdgeInsets.all(isMobile ? 8 : 16),
                        itemCount: transferenciasFiltradas.length +
                            (transferenciasFiltradas.any((t) =>
                                    t.estado == EstadoTransferencia.enviado &&
                                    provider.sucursalId != null &&
                                    t.sucursalDestinoId.toString() ==
                                        provider.sucursalId)
                                ? 1
                                : 0),
                        itemBuilder: (BuildContext context, int index) {
                          // Obtener las transferencias para validar
                          final transferenciasParaValidar =
                              transferenciasFiltradas
                                  .where((t) =>
                                      t.estado == EstadoTransferencia.enviado &&
                                      provider.sucursalId != null &&
                                      t.sucursalDestinoId.toString() ==
                                          provider.sucursalId)
                                  .toList();

                          final transferenciasNormales = transferenciasFiltradas
                              .where((t) =>
                                  !(t.estado == EstadoTransferencia.enviado &&
                                      provider.sucursalId != null &&
                                      t.sucursalDestinoId.toString() ==
                                          provider.sucursalId))
                              .toList();

                          // Si hay transferencias para validar y estamos en el índice del separador
                          if (transferenciasParaValidar.isNotEmpty &&
                              index == transferenciasParaValidar.length) {
                            return Container(
                              margin: EdgeInsets.symmetric(
                                  vertical: isMobile ? 8 : 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D2D2D),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.clockRotateLeft,
                                    size: 16,
                                    color: Color(0xFFE31E24),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Otras transferencias',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Determinar qué transferencia mostrar basado en el índice
                          final TransferenciaInventario transferencia;
                          if (index < transferenciasParaValidar.length) {
                            // Mostrar transferencia para validar
                            transferencia = transferenciasParaValidar[index];
                          } else {
                            // Mostrar transferencia normal, ajustando el índice para saltar el separador
                            final normalIndex = index -
                                (transferenciasParaValidar.isEmpty
                                    ? 0
                                    : transferenciasParaValidar.length + 1);
                            if (normalIndex >= 0 &&
                                normalIndex < transferenciasNormales.length) {
                              transferencia =
                                  transferenciasNormales[normalIndex];
                            } else {
                              // Este caso no debería ocurrir, pero por seguridad retornamos un widget vacío
                              return const SizedBox.shrink();
                            }
                          }

                          debugPrint(
                              'Construyendo transferencia #${transferencia.id}');
                          return _buildTransferenciaCard(
                              transferencia, isMobile, provider);
                        },
                      ),
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
                        TransferenciasUtils.getEstadoColor(transferencia.estado)
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FaIcon(
                    TransferenciasUtils.getEstadoIcon(transferencia.estado),
                    color: TransferenciasUtils.getEstadoColor(
                        transferencia.estado),
                    size: isMobile ? 16 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            'TRF${transferencia.id}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: TransferenciasUtils.getEstadoColor(
                                      transferencia.estado)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              transferencia.estado.nombre,
                              style: TextStyle(
                                color: TransferenciasUtils.getEstadoColor(
                                    transferencia.estado),
                                fontSize: isMobile ? 10 : 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                          if (transferencia.productos != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: TransferenciasUtils
                                  .getProductCountBadgeStyle(),
                              child: Text(
                                '${transferencia.productos!.length} productos',
                                style: const TextStyle(
                                  color: Color(0xFFE31E24),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                MouseRegion(
                  child: IconButton(
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
                  ),
                ),
                if (transferencia.estado == EstadoTransferencia.enviado &&
                    _provider.sucursalId != null &&
                    transferencia.sucursalDestinoId.toString() ==
                        _provider.sucursalId)
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
          const Divider(color: Color(0xFF1A1A1A), height: 1),
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: _buildTimeline(transferencia, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(TransferenciaInventario transferencia, bool isMobile) {
    final steps = TransferenciasUtils.getTransferenciaSteps(transferencia);
    final double iconSize = isMobile ? 16 : 20;
    final double fontSize = isMobile ? 12 : 14;
    final double containerSize = isMobile ? 36 : 44;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: steps.asMap().entries.map((entry) {
          final int index = entry.key;
          final Map<String, dynamic> step = entry.value;
          final bool isLast = index == steps.length - 1;
          final DateTime? date = step['date'] as DateTime?;
          final String? formattedDate =
              date != null ? '${date.day}/${date.month}/${date.year}' : null;

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
                                width: 2,
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
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: step['color'] as Color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF1A1A1A),
                                    width: 2,
                                  ),
                                ),
                                child: FaIcon(
                                  FontAwesomeIcons.check,
                                  size: iconSize * 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step['title'] as String,
                        style: TextStyle(
                          color: step['isCompleted'] as bool
                              ? Colors.white
                              : Colors.grey[600],
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        step['subtitle'] as String,
                        style: TextStyle(
                          color: step['isCompleted'] as bool
                              ? Colors.grey[400]
                              : Colors.grey[700],
                          fontSize: fontSize - 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (formattedDate != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (step['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            formattedDate,
                            style: TextStyle(
                              color: step['color'] as Color,
                              fontSize: fontSize - 2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: step['isCompleted'] as bool
                          ? step['color'] as Color
                          : Colors.grey[800],
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showValidationDialog(TransferenciaInventario transferencia) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) =>
          FutureBuilder<TransferenciaInventario>(
        future:
            _provider.obtenerDetalleTransferencia(transferencia.id.toString()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
              ),
            );
          }

          if (snapshot.hasError) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2D2D2D),
              title: const Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.circleExclamation,
                    color: Color(0xFFE31E24),
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Error',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Error al cargar los detalles: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          }

          final TransferenciaInventario detalleTransferencia = snapshot.data!;

          return Dialog(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(
                                    'Transferencia: TRF${detalleTransferencia.id}',
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
                                      color: _getEstadoColor(
                                              detalleTransferencia.estado)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      detalleTransferencia.estado.nombre,
                                      style: TextStyle(
                                        color: _getEstadoColor(
                                            detalleTransferencia.estado),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Origen: ${detalleTransferencia.nombreSucursalOrigen}',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              Text(
                                'Destino: ${detalleTransferencia.nombreSucursalDestino}',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              if (detalleTransferencia.salidaOrigen != null)
                                Text(
                                  'Fecha de Salida: ${detalleTransferencia.salidaOrigen!.day}/${detalleTransferencia.salidaOrigen!.month}/${detalleTransferencia.salidaOrigen!.year}',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Productos a recibir:',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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
                                '${detalleTransferencia.productos?.length ?? 0} productos',
                                style: const TextStyle(
                                  color: Color(0xFFE31E24),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (detalleTransferencia.productos != null &&
                            detalleTransferencia.productos!.isNotEmpty)
                          ...detalleTransferencia.productos!
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
                                      color: const Color(0xFFE31E24)
                                          .withOpacity(0.1),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                      color: const Color(0xFFE31E24)
                                          .withOpacity(0.1),
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
                          final bool? confirmar = await showDialog<bool>(
                            context: dialogContext,
                            builder: (BuildContext confirmContext) =>
                                AlertDialog(
                              backgroundColor: const Color(0xFF2D2D2D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: const Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.triangleExclamation,
                                    color: Color(0xFFE31E24),
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Confirmar Recepción',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              content: const Text(
                                '¿Está seguro que desea validar la recepción de esta transferencia? Esta acción no se puede deshacer.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(confirmContext),
                                  child: const Text(
                                    'Cancelar',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      Navigator.pop(confirmContext, true),
                                  icon: const FaIcon(
                                    FontAwesomeIcons.check,
                                    size: 16,
                                  ),
                                  label: const Text('Confirmar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF43A047),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirmar == true) {
                            Navigator.pop(dialogContext);
                            await _validarRecepcion(detalleTransferencia);
                          }
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
          );
        },
      ),
    );
  }

  Future<void> _validarRecepcion(TransferenciaInventario transferencia) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
          ),
        ),
      );

      await _provider.validarRecepcion(transferencia);

      // Cerrar indicador de carga
      if (mounted) {
        Navigator.pop(context);
      }

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transferencia recibida correctamente'),
            backgroundColor: Color(0xFF43A047),
          ),
        );
      }
    } catch (e) {
      // Cerrar indicador de carga
      if (mounted) {
        Navigator.pop(context);
      }

      // Mostrar mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al validar recepción: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getEstadoColor(EstadoTransferencia estado) {
    return TransferenciasUtils.getEstadoColor(estado);
  }

  IconData _getEstadoIcon(EstadoTransferencia estado) {
    return TransferenciasUtils.getEstadoIcon(estado);
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
