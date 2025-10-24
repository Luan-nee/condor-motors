import 'package:condorsmotors/models/cliente.model.dart';
import 'package:condorsmotors/utils/busqueda_cliente_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BusquedaClienteWidget extends StatefulWidget {
  final List<Cliente> clientes;
  final Function(Cliente) onClienteSeleccionado;
  final Function() onNuevoCliente;
  final VoidCallback? onRefrescarClientes;
  final bool isLoading;

  const BusquedaClienteWidget({
    super.key,
    required this.clientes,
    required this.onClienteSeleccionado,
    required this.onNuevoCliente,
    this.onRefrescarClientes,
    this.isLoading = false,
  });

  @override
  State<BusquedaClienteWidget> createState() => _BusquedaClienteWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Cliente>('clientes', clientes))
      ..add(ObjectFlagProperty<Function(Cliente)>.has(
          'onClienteSeleccionado', onClienteSeleccionado))
      ..add(
          ObjectFlagProperty<Function()>.has('onNuevoCliente', onNuevoCliente))
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading))
      ..add(ObjectFlagProperty<VoidCallback?>.has(
          'onRefrescarClientes', onRefrescarClientes));
  }
}

class _BusquedaClienteWidgetState extends State<BusquedaClienteWidget>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _searchAnimationController;
  bool _isSearchExpanded = false;

  late AnimationController _tipoDocumentoAnimationController;
  bool _isTipoDocumentoExpanded = false;

  List<Cliente> _clientesFiltrados = <Cliente>[];
  TipoDocumento _tipoDocumentoSeleccionado = TipoDocumento.todos;

  // Colores para el tema oscuro
  final Color darkBackground = const Color(0xFF1A1A1A);
  final Color darkSurface = const Color(0xFF2D2D2D);

  @override
  void initState() {
    super.initState();

    // Inicializar controladores de animación
    _searchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _tipoDocumentoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _filtrarClientes();
  }

  @override
  void didUpdateWidget(BusquedaClienteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clientes != widget.clientes) {
      _filtrarClientes();
    }
  }

  void _filtrarClientes() {
    setState(() {
      _clientesFiltrados = BusquedaClienteUtils.filtrarClientes(
        clientes: widget.clientes,
        filtroTexto: _searchController.text,
        tipoDocumento: _tipoDocumentoSeleccionado,
        debugMode: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: darkBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: darkSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildMobileFilters(),
          ),

          // Resumen de filtros activos
          _buildFilterSummary(),

          // Lista de clientes
          Expanded(
            child: _buildClientesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilters() {
    // Verificar si hay algún filtro activo
    final bool hayFiltrosActivos =
        _tipoDocumentoSeleccionado != TipoDocumento.todos ||
            _searchController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Fila de botones (siempre visible)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              // Botón de tipo de documento
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _isTipoDocumentoExpanded
                      ? Colors.blue.withValues(alpha: 0.2)
                      : darkBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isTipoDocumentoExpanded
                            ? Icons.badge
                            : Icons.badge_outlined,
                        color: _isTipoDocumentoExpanded ||
                                _tipoDocumentoSeleccionado !=
                                    TipoDocumento.todos
                            ? Colors.blue
                            : Colors.white70,
                        size: 20,
                      ),
                      if (!_isTipoDocumentoExpanded &&
                          _tipoDocumentoSeleccionado !=
                              TipoDocumento.todos) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  onPressed: _toggleTipoDocumento,
                  tooltip: _isTipoDocumentoExpanded
                      ? 'Cerrar tipo de documento'
                      : 'Tipo de documento',
                ),
              ),

              // Botón de búsqueda
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _isSearchExpanded
                      ? Colors.orange.withValues(alpha: 0.2)
                      : darkBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isSearchExpanded ? Icons.close : Icons.search,
                        color: _isSearchExpanded ||
                                _searchController.text.isNotEmpty
                            ? Colors.orange
                            : Colors.white70,
                        size: 20,
                      ),
                      if (!_isSearchExpanded &&
                          _searchController.text.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  onPressed: _toggleSearch,
                  tooltip: _isSearchExpanded ? 'Cerrar búsqueda' : 'Buscar',
                ),
              ),

              // Botón de nuevo cliente
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.userPlus,
                    color: Colors.green,
                    size: 16,
                  ),
                  onPressed: widget.onNuevoCliente,
                  tooltip: 'Nuevo cliente',
                ),
              ),

              // Botón de limpiar filtros
              if (hayFiltrosActivos)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.filter_list_off,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: _restablecerFiltros,
                    tooltip: 'Limpiar filtros',
                  ),
                ),
            ],
          ),
        ),

        // Contenido expandido
        if (_isTipoDocumentoExpanded) _buildTipoDocumentoExpandido(),
        if (_isSearchExpanded) _buildSearchExpandido(),
      ],
    );
  }

  Widget _buildTipoDocumentoExpandido() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra con título
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.badge,
                  color: Colors.blue,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tipo de Documento',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _toggleTipoDocumento,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          // Lista de tipos de documento
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TipoDocumento.values.map((TipoDocumento tipo) {
                final bool isSelected = tipo == _tipoDocumentoSeleccionado;
                final Color color = _getColorForTipoDocumento(tipo);

                return FilterChip(
                  selected: isSelected,
                  label: Text(
                    BusquedaClienteUtils.getNombreTipoDocumento(tipo),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  avatar: Icon(
                    _getIconForTipoDocumento(tipo),
                    size: 16,
                    color: isSelected ? Colors.white : color,
                  ),
                  backgroundColor: darkBackground,
                  selectedColor: color.withValues(alpha: 0.8),
                  checkmarkColor: Colors.white,
                  onSelected: (bool selected) {
                    setState(() {
                      _tipoDocumentoSeleccionado =
                          selected ? tipo : TipoDocumento.todos;
                    });
                    _filtrarClientes();
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchExpandido() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra con título
          Container(
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  color: Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Buscar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _toggleSearch,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          // Campo de búsqueda
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o documento...',
                hintStyle: const TextStyle(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white38, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        color: Colors.white60,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          _searchController.clear();
                          _filtrarClientes();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => _filtrarClientes(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Mostrar filtro de tipo de documento si hay uno activo
          if (_tipoDocumentoSeleccionado != TipoDocumento.todos)
            _buildActiveFilter(
              icon: _getIconForTipoDocumento(_tipoDocumentoSeleccionado),
              label:
                  'Tipo: ${BusquedaClienteUtils.getNombreTipoDocumento(_tipoDocumentoSeleccionado)}',
              color: _getColorForTipoDocumento(_tipoDocumentoSeleccionado),
              onClear: () {
                setState(() {
                  _tipoDocumentoSeleccionado = TipoDocumento.todos;
                });
                _filtrarClientes();
              },
            ),

          // Mostrar filtro de búsqueda si hay uno
          if (_searchController.text.isNotEmpty)
            _buildActiveFilter(
              icon: Icons.search,
              label: 'Búsqueda: "${_searchController.text}"',
              color: Colors.orange,
              onClear: () {
                _searchController.clear();
                _filtrarClientes();
              },
            ),

          Text(
            'Mostrando ${_clientesFiltrados.length} ${_clientesFiltrados.length == 1 ? 'cliente' : 'clientes'}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilter({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onClear,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 14,
            color: Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onClear,
            child: const Icon(
              Icons.close,
              size: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientesList() {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_clientesFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.person_search,
              size: 48,
              color: Colors.white30,
            ),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron clientes',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otra búsqueda o crea un nuevo cliente',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onNuevoCliente,
              icon: const FaIcon(FontAwesomeIcons.userPlus, size: 14),
              label: const Text('Crear Cliente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _clientesFiltrados.length,
      itemBuilder: (BuildContext context, int index) {
        final Cliente cliente = _clientesFiltrados[index];
        final TipoDocumento tipoDoc =
            BusquedaClienteUtils.detectarTipoDocumento(cliente.numeroDocumento);
        final Color colorTipoDoc = _getColorForTipoDocumento(tipoDoc);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: colorTipoDoc.withValues(alpha: 0.3),
            ),
          ),
          child: InkWell(
            onTap: () => widget.onClienteSeleccionado(cliente),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  // Avatar con iniciales y clickeable
                  GestureDetector(
                    onTap: () => _mostrarDetallesCliente(context, cliente),
                    child: Hero(
                      tag: 'avatar_${cliente.id}',
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorTipoDoc.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorTipoDoc.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(cliente.denominacion),
                            style: TextStyle(
                              color: colorTipoDoc,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Información del cliente
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          cliente.denominacion,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            Icon(
                              _getIconForTipoDocumento(tipoDoc),
                              size: 14,
                              color: colorTipoDoc,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${BusquedaClienteUtils.getNombreTipoDocumento(tipoDoc)}: ${cliente.numeroDocumento}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Flecha de selección
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarDetallesCliente(BuildContext context, Cliente cliente) {
    final TipoDocumento tipoDoc =
        BusquedaClienteUtils.detectarTipoDocumento(cliente.numeroDocumento);
    final Color colorTipoDoc = _getColorForTipoDocumento(tipoDoc);

    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Encabezado con avatar y nombre
              Row(
                children: <Widget>[
                  Hero(
                    tag: 'avatar_${cliente.id}',
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: colorTipoDoc.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorTipoDoc.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(cliente.denominacion),
                          style: TextStyle(
                            color: colorTipoDoc,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          cliente.denominacion,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${cliente.id}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Información detallada
              _buildDetalleItem(
                icon: Icons.badge,
                color: colorTipoDoc,
                titulo: cliente.nombre,
                subtitulo: cliente.numeroDocumento,
              ),
              const SizedBox(height: 16),

              _buildDetalleItem(
                icon: Icons.location_on,
                color: Colors.red,
                titulo: 'Dirección',
                subtitulo: cliente.direccion ?? 'No especificada',
              ),
              const SizedBox(height: 16),

              if (cliente.correo != null && cliente.correo!.isNotEmpty)
                _buildDetalleItem(
                  icon: Icons.email,
                  color: Colors.blue,
                  titulo: 'Correo electrónico',
                  subtitulo: cliente.correo!,
                ),
              if (cliente.correo != null && cliente.correo!.isNotEmpty)
                const SizedBox(height: 16),

              if (cliente.telefono != null && cliente.telefono!.isNotEmpty)
                _buildDetalleItem(
                  icon: Icons.phone,
                  color: Colors.green,
                  titulo: 'Teléfono',
                  subtitulo: cliente.telefono!,
                ),
              if (cliente.telefono != null && cliente.telefono!.isNotEmpty)
                const SizedBox(height: 16),

              // Fechas
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildDetalleItem(
                      icon: Icons.calendar_today,
                      color: Colors.orange,
                      titulo: 'Creado',
                      subtitulo: _formatearFecha(cliente.fechaCreacion),
                      small: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDetalleItem(
                      icon: Icons.update,
                      color: Colors.purple,
                      titulo: 'Actualizado',
                      subtitulo: _formatearFecha(cliente.fechaActualizacion),
                      small: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              // Botón de seleccionar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onClienteSeleccionado(cliente);
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Seleccionar Cliente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorTipoDoc,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetalleItem({
    required IconData icon,
    required Color color,
    required String titulo,
    required String subtitulo,
    bool small = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: small ? 16 : 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                titulo,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: small ? 12 : 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitulo,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: small ? 13 : 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) {
      return 'No disponible';
    }

    final List<String> meses = <String>[
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic'
    ];

    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
  }

  String _getInitials(String name) {
    if (name.isEmpty) {
      return '';
    }
    final List<String> nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  IconData _getIconForTipoDocumento(TipoDocumento tipo) {
    switch (tipo) {
      case TipoDocumento.dni:
        return Icons.badge;
      case TipoDocumento.cedula:
        return Icons.credit_card;
      case TipoDocumento.ruc:
        return Icons.business;
      case TipoDocumento.pasaporte:
        return Icons.book;
      case TipoDocumento.otros:
        return Icons.more_horiz;
      case TipoDocumento.todos:
        return Icons.people;
    }
  }

  Color _getColorForTipoDocumento(TipoDocumento tipo) {
    final String colorHex = BusquedaClienteUtils.getColorTipoDocumento(tipo);
    return Color(int.parse(colorHex.substring(1, 7), radix: 16) + 0xFF000000);
  }

  void _toggleTipoDocumento() {
    if (!_isTipoDocumentoExpanded && _isSearchExpanded) {
      _toggleSearch();
    }

    setState(() {
      _isTipoDocumentoExpanded = !_isTipoDocumentoExpanded;
      if (_isTipoDocumentoExpanded) {
        _tipoDocumentoAnimationController.forward();
      } else {
        _tipoDocumentoAnimationController.reverse();
      }
    });
  }

  void _toggleSearch() {
    if (!_isSearchExpanded && _isTipoDocumentoExpanded) {
      _toggleTipoDocumento();
    }

    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (_isSearchExpanded) {
        _searchAnimationController.forward();
      } else {
        _searchAnimationController.reverse();
        if (_searchController.text.isNotEmpty) {
          _searchController.clear();
          _filtrarClientes();
        }
      }
    });
  }

  void _restablecerFiltros() {
    // Cerrar dropdowns expandidos
    if (_isTipoDocumentoExpanded) {
      _toggleTipoDocumento();
    }
    if (_isSearchExpanded) {
      _toggleSearch();
    }

    setState(() {
      _tipoDocumentoSeleccionado = TipoDocumento.todos;
      _searchController.clear();
    });

    _filtrarClientes();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filtros restablecidos'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchAnimationController.dispose();
    _tipoDocumentoAnimationController.dispose();
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('darkBackground', darkBackground))
      ..add(ColorProperty('darkSurface', darkSurface));
  }
}
