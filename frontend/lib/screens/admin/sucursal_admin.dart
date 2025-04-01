import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/providers/admin/sucursal.provider.dart';
import 'package:condorsmotors/screens/admin/widgets/sucursal/sucursal_detalles.dart';
import 'package:condorsmotors/screens/admin/widgets/sucursal/sucursal_form.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

// La clase Sucursal ha sido reemplazada por la importación de '../../models/sucursal.model.dart'
// La clase SucursalRequest ha sido movida al provider de sucursales

class SucursalAdminScreen extends StatefulWidget {
  const SucursalAdminScreen({super.key});

  @override
  State<SucursalAdminScreen> createState() => _SucursalAdminScreenState();
}

class _SucursalAdminScreenState extends State<SucursalAdminScreen>
    with SingleTickerProviderStateMixin {
  late SucursalProvider _sucursalProvider;
  bool _mostrarAgrupados = true;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Estado para controlar el modo edición

  // Controladores para la lista
  final ScrollController _scrollController = ScrollController();

  // Filtros avanzados
  bool _mostrarFiltrosAvanzados = false;
  String _filtroTipo = 'Todos';
  final List<String> _opcionesTipo = ['Todos', 'Central', 'Local'];

  // Estado de la lista
  bool _isListScrollable = false;

  @override
  void initState() {
    super.initState();
    _sucursalProvider = Provider.of<SucursalProvider>(context, listen: false);
    _sucursalProvider.inicializar();

    // Configurar animaciones
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // Escuchar cambios en el scroll para mostrar botón "ir arriba"
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Actualizar estado para mostrar/ocultar botón de scroll
    final bool isScrollable = _scrollController.position.maxScrollExtent > 0;
    if (isScrollable != _isListScrollable) {
      setState(() {
        _isListScrollable = isScrollable;
      });
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuad,
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _mostrarFormularioSucursal([Sucursal? sucursal]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: SucursalForm(
              sucursal: sucursal,
              onSave: _guardarSucursal,
              onCancel: () => Navigator.of(context).pop(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _guardarSucursal(Map<String, dynamic> data) async {
    final String? error = await _sucursalProvider.guardarSucursal(data);

    if (!mounted) {
      return;
    }

    // Cerramos el diálogo después de guardar
    Navigator.of(context).pop();

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sucursal guardada exitosamente'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFE31E24),
        ),
      );
    }
  }

  Future<void> _confirmarEliminarSucursal(Sucursal sucursal) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content:
            Text('¿Está seguro de eliminar la sucursal "${sucursal.nombre}"?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (!mounted) {
      return;
    }

    if (confirm == true) {
      final String? error = await _sucursalProvider.eliminarSucursal(sucursal);

      if (!mounted) {
        return;
      }

      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Sucursal "${sucursal.nombre}" eliminada correctamente'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: const Color(0xFFE31E24),
          ),
        );
      }
    }
  }

  void _toggleFiltrosAvanzados() {
    setState(() {
      _mostrarFiltrosAvanzados = !_mostrarFiltrosAvanzados;
    });
  }

  List<Sucursal> _aplicarFiltrosAvanzados(List<Sucursal> sucursales) {
    if (_filtroTipo == 'Todos') {
      return sucursales;
    }

    bool esCentral = _filtroTipo == 'Central';
    return sucursales.where((s) => s.sucursalCentral == esCentral).toList();
  }

  // Método para obtener icono según la sucursal
  IconData _getIconForSucursal(Sucursal sucursal) {
    // Primero revisamos si es sucursal central
    if (sucursal.sucursalCentral) {
      return FontAwesomeIcons.building;
    }

    // Luego revisamos el nombre
    final String nombre = sucursal.nombre.toLowerCase();
    if (nombre.contains('central') || nombre.contains('principal')) {
      return FontAwesomeIcons.building;
    } else if (nombre.contains('taller')) {
      return FontAwesomeIcons.screwdriverWrench;
    } else if (nombre.contains('almacén') ||
        nombre.contains('almacen') ||
        nombre.contains('bodega')) {
      return FontAwesomeIcons.warehouse;
    } else if (nombre.contains('tienda') || nombre.contains('venta')) {
      return FontAwesomeIcons.store;
    }
    return FontAwesomeIcons.locationDot;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SucursalProvider>(builder: (context, provider, child) {
      // Pantalla principal de listado de sucursales
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF212121),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Gestión de Sucursales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Administre las sucursales y locales de la empresa',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.filter, size: 16),
              tooltip: 'Filtros avanzados',
              onPressed: _toggleFiltrosAvanzados,
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 16),
              tooltip: 'Actualizar datos',
              onPressed: provider.cargarSucursales,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Agregar nueva sucursal',
              onPressed: () => _mostrarFormularioSucursal(),
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            // Encabezado con estadísticas y búsqueda
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Row(
                        children: <Widget>[
                          FaIcon(
                            FontAwesomeIcons.buildingUser,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'GESTIÓN DE SUCURSALES',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Tooltip(
                        message: '${provider.sucursales.length} sucursales',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D2D2D),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            provider.sucursales.length.toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Buscar sucursal',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.5)),
                      labelStyle:
                          TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: provider.actualizarBusqueda,
                  ),

                  // Filtros avanzados (expandibles)
                  if (_mostrarFiltrosAvanzados) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Filtros Avanzados',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text(
                                'Tipo de Sucursal:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2D2D2D),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: _filtroTipo,
                                      dropdownColor: const Color(0xFF2D2D2D),
                                      style:
                                          const TextStyle(color: Colors.white),
                                      items: _opcionesTipo.map((String item) {
                                        return DropdownMenuItem<String>(
                                          value: item,
                                          child: Text(item),
                                        );
                                      }).toList(),
                                      onChanged: (String? value) {
                                        if (value != null) {
                                          setState(() {
                                            _filtroTipo = value;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  // Switch para agrupar/desagrupar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          FaIcon(
                            _mostrarAgrupados
                                ? FontAwesomeIcons.layerGroup
                                : FontAwesomeIcons.list,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Agrupar por tipo',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _mostrarAgrupados,
                        onChanged: (bool value) {
                          setState(() {
                            _mostrarAgrupados = value;
                          });
                        },
                        activeColor: const Color(0xFFE31E24),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Sección de resultados y contenido principal
            Expanded(
              child: Stack(
                children: [
                  if (provider.isLoading && provider.sucursales.isEmpty)
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFE31E24)),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Cargando sucursales...',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    )
                  else if (provider.errorMessage.isNotEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const FaIcon(
                            FontAwesomeIcons.circleExclamation,
                            color: Color(0xFFE31E24),
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.errorMessage,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE31E24),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            onPressed: provider.cargarSucursales,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  else if (provider.sucursales.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const FaIcon(
                            FontAwesomeIcons.building,
                            color: Colors.white24,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.terminoBusqueda.isEmpty
                                ? 'No hay sucursales para mostrar'
                                : 'No se encontraron sucursales con "${provider.terminoBusqueda}"',
                            style: const TextStyle(color: Colors.white54),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          if (provider.terminoBusqueda.isNotEmpty)
                            TextButton.icon(
                              onPressed: provider.limpiarBusqueda,
                              icon: const Icon(Icons.clear),
                              label: const Text('Limpiar búsqueda'),
                            )
                          else
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE31E24),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _mostrarFormularioSucursal(),
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar sucursal'),
                            ),
                        ],
                      ),
                    )
                  else
                    FadeTransition(
                      opacity: _animation,
                      child: _mostrarAgrupados
                          ? _buildAgrupadas(provider)
                          : _buildListaCompleta(provider),
                    ),

                  // Botón flotante para subir cuando la lista es larga
                  if (_isListScrollable)
                    Positioned(
                      right: 20,
                      bottom: 80,
                      child: AnimatedOpacity(
                        opacity: _isListScrollable ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: FloatingActionButton.small(
                          heroTag: 'scrollToTop',
                          backgroundColor: Colors.black.withOpacity(0.6),
                          onPressed: _scrollToTop,
                          child: const Icon(Icons.keyboard_arrow_up, size: 20),
                        ),
                      ),
                    ),

                  // Indicador de carga cuando está actualizando pero ya tiene datos
                  if (provider.isLoading && provider.sucursales.isNotEmpty)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 3,
                        child: const LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFE31E24),
          foregroundColor: Colors.white,
          onPressed: () => _mostrarFormularioSucursal(),
          tooltip: 'Agregar sucursal',
          child: const Icon(Icons.add),
        ),
      );
    });
  }

  Widget _buildAgrupadas(SucursalProvider provider) {
    // Aplicamos filtros avanzados a la lista de sucursales
    final List<Sucursal> sucursalesFiltradas =
        _aplicarFiltrosAvanzados(provider.sucursales);

    final Map<String, List<Sucursal>> grupos =
        provider.agruparSucursalesPorTipo(sucursales: sucursalesFiltradas);
    final List<Sucursal> sucursalesCentrales =
        grupos['Centrales'] ?? <Sucursal>[];
    final List<Sucursal> sucursalesNoCentrales =
        grupos['Sucursales'] ?? <Sucursal>[];

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: <Widget>[
        // Mostrar resumen de resultados si hay filtros aplicados
        if (_filtroTipo != 'Todos' || provider.terminoBusqueda.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.filter,
                  color: Colors.white54,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mostrando ${sucursalesFiltradas.length} de ${provider.sucursales.length} sucursales',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (provider.terminoBusqueda.isNotEmpty ||
                    _filtroTipo != 'Todos')
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 30),
                    ),
                    onPressed: () {
                      provider.limpiarBusqueda();
                      setState(() {
                        _filtroTipo = 'Todos';
                      });
                    },
                    icon: const Icon(Icons.clear, size: 14),
                    label: const Text('Limpiar filtros',
                        style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),

        // Construimos los grupos que tienen elementos
        if (sucursalesCentrales.isNotEmpty) ...<Widget>[
          _buildGrupoHeader('Sucursales Centrales', sucursalesCentrales.length),
          _buildTablaSucursales(sucursalesCentrales),
        ],
        if (sucursalesNoCentrales.isNotEmpty) ...<Widget>[
          if (sucursalesCentrales.isNotEmpty) const SizedBox(height: 16),
          _buildGrupoHeader('Sucursales', sucursalesNoCentrales.length),
          _buildTablaSucursales(sucursalesNoCentrales),
        ],
        // Espaciado extra al final para evitar que el FAB cubra el último elemento
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildTablaSucursales(List<Sucursal> sucursales) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        margin: EdgeInsets.zero,
        color: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Encabezado de la tabla
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF2A2A2A),
              child: Row(
                children: [
                  const SizedBox(width: 36), // Espacio para el icono
                  Expanded(
                    flex: 3,
                    child: Text(
                      'NOMBRE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      'DIRECCIÓN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 110), // Espacio para acciones
                ],
              ),
            ),

            // Filas de la tabla
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sucursales.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: Color(0xFF333333),
              ),
              itemBuilder: (context, index) {
                final Sucursal sucursal = sucursales[index];
                return _buildFilaSucursal(sucursal);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaSucursal(Sucursal sucursal) {
    final IconData icon = _getIconForSucursal(sucursal);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _mostrarDetallesSucursal(sucursal),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icono
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: sucursal.sucursalCentral
                      ? const Color(0xFFE31E24).withOpacity(0.1)
                      : const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FaIcon(
                  icon,
                  color: sucursal.sucursalCentral
                      ? const Color(0xFFE31E24)
                      : Colors.white70,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Nombre
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sucursal.nombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (sucursal.sucursalCentral)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE31E24).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'CENTRAL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE31E24),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Dirección
              Expanded(
                flex: 4,
                child: Text(
                  sucursal.direccion ?? 'Sin dirección registrada',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontStyle: sucursal.direccion == null
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Acciones
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.eye,
                      size: 16,
                      color: Colors.white70,
                    ),
                    tooltip: 'Ver detalles',
                    onPressed: () => _mostrarDetallesSucursal(sucursal),
                  ),
                  IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.penToSquare,
                      size: 16,
                      color: Colors.white70,
                    ),
                    tooltip: 'Editar sucursal',
                    onPressed: () => _mostrarFormularioSucursal(sucursal),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      size: 18,
                      color: Colors.red,
                    ),
                    tooltip: 'Eliminar sucursal',
                    onPressed: () => _confirmarEliminarSucursal(sucursal),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetallesSucursal(Sucursal sucursal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SucursalDetalles(
              sucursal: sucursal,
              onEdit: () {
                Navigator.of(context).pop();
                _mostrarFormularioSucursal(sucursal);
              },
              onDelete: () {
                Navigator.of(context).pop();
                _confirmarEliminarSucursal(sucursal);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrupoHeader(String titulo, int cantidad) {
    return Container(
      color: const Color(0xFF2D2D2D),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: [
              FaIcon(
                titulo.contains('Central')
                    ? FontAwesomeIcons.building
                    : FontAwesomeIcons.store,
                color: titulo.contains('Central')
                    ? const Color(0xFFE31E24)
                    : Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: TextStyle(
                  color: titulo.contains('Central')
                      ? const Color(0xFFE31E24)
                      : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              cantidad.toString(),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaCompleta(SucursalProvider provider) {
    // Aplicamos filtros avanzados
    final List<Sucursal> sucursalesFiltradas =
        _aplicarFiltrosAvanzados(provider.sucursales);

    return Column(
      children: [
        // Mostrar resumen de resultados si hay filtros aplicados
        if (_filtroTipo != 'Todos' || provider.terminoBusqueda.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.filter,
                  color: Colors.white54,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mostrando ${sucursalesFiltradas.length} de ${provider.sucursales.length} sucursales',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (provider.terminoBusqueda.isNotEmpty ||
                    _filtroTipo != 'Todos')
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 30),
                    ),
                    onPressed: () {
                      provider.limpiarBusqueda();
                      setState(() {
                        _filtroTipo = 'Todos';
                      });
                    },
                    icon: const Icon(Icons.clear, size: 14),
                    label: const Text('Limpiar filtros',
                        style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),

        // Lista principal
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Card(
              margin: EdgeInsets.zero,
              color: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Encabezado de la tabla
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    color: const Color(0xFF2A2A2A),
                    child: Row(
                      children: [
                        const SizedBox(width: 36), // Espacio para el icono
                        Expanded(
                          flex: 3,
                          child: Text(
                            'NOMBRE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            'DIRECCIÓN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                        const SizedBox(width: 110), // Espacio para acciones
                      ],
                    ),
                  ),

                  // Lista de sucursales
                  Expanded(
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: sucursalesFiltradas.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        color: Color(0xFF333333),
                      ),
                      itemBuilder: (context, index) {
                        final Sucursal sucursal = sucursalesFiltradas[index];
                        return _buildFilaSucursal(sucursal);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SucursalFormDialog extends StatefulWidget {
  final Sucursal? sucursal;
  final Function(Map<String, dynamic>) onSave;

  const SucursalFormDialog({
    super.key,
    this.sucursal,
    required this.onSave,
  });

  @override
  State<SucursalFormDialog> createState() => _SucursalFormDialogState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Sucursal?>('sucursal', sucursal))
      ..add(ObjectFlagProperty<Function(Map<String, dynamic>)>.has(
          'onSave', onSave));
  }
}

class _SucursalFormDialogState extends State<SucursalFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _serieFacturaController = TextEditingController();
  final TextEditingController _numeroFacturaInicialController =
      TextEditingController();
  final TextEditingController _serieBoletaController = TextEditingController();
  final TextEditingController _numeroBoletaInicialController =
      TextEditingController();
  final TextEditingController _codigoEstablecimientoController =
      TextEditingController();
  bool _sucursalCentral = false;

  @override
  void initState() {
    super.initState();
    if (widget.sucursal != null) {
      _nombreController.text = widget.sucursal!.nombre;
      _direccionController.text = widget.sucursal!.direccion ?? '';
      _sucursalCentral = widget.sucursal!.sucursalCentral;
      _serieFacturaController.text = widget.sucursal!.serieFactura ?? '';
      _numeroFacturaInicialController.text =
          widget.sucursal!.numeroFacturaInicial?.toString() ?? '1';
      _serieBoletaController.text = widget.sucursal!.serieBoleta ?? '';
      _numeroBoletaInicialController.text =
          widget.sucursal!.numeroBoletaInicial?.toString() ?? '1';
      _codigoEstablecimientoController.text =
          widget.sucursal!.codigoEstablecimiento ?? '';
    } else {
      // Valores predeterminados para nuevas sucursales
      _numeroFacturaInicialController.text = '1';
      _numeroBoletaInicialController.text = '1';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esNuevaSucursal = widget.sucursal == null;

    return AlertDialog(
      title: Text(
        esNuevaSucursal ? 'Nueva Sucursal' : 'Editar Sucursal',
        style: const TextStyle(
          color: Color(0xFFE31E24),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej: Sucursal Principal',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  hintText: 'Ej: Av. Principal 123',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'La dirección es requerida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Configuración de facturación - Sección
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Configuración de Facturación',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    // Serie de Factura
                    TextFormField(
                      controller: _serieFacturaController,
                      decoration: const InputDecoration(
                        labelText: 'Serie de Factura',
                        hintText: 'Ej: F001',
                        prefixIcon: Icon(Icons.receipt_long),
                        helperText: 'Debe empezar con F y tener 4 caracteres',
                      ),
                      validator: (String? value) {
                        if (value != null && value.isNotEmpty) {
                          if (!value.startsWith('F') || value.length != 4) {
                            return 'La serie debe empezar con F y tener 4 caracteres';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    // Número de Factura Inicial
                    TextFormField(
                      controller: _numeroFacturaInicialController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Factura Inicial',
                        hintText: 'Ej: 1',
                        prefixIcon: Icon(Icons.format_list_numbered),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (String? value) {
                        if (value != null && value.isNotEmpty) {
                          if (int.tryParse(value) == null ||
                              int.parse(value) < 1) {
                            return 'Debe ser un número positivo';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Serie de Boleta
                    TextFormField(
                      controller: _serieBoletaController,
                      decoration: const InputDecoration(
                        labelText: 'Serie de Boleta',
                        hintText: 'Ej: B001',
                        prefixIcon: Icon(Icons.receipt),
                        helperText: 'Debe empezar con B y tener 4 caracteres',
                      ),
                      validator: (String? value) {
                        if (value != null && value.isNotEmpty) {
                          if (!value.startsWith('B') || value.length != 4) {
                            return 'La serie debe empezar con B y tener 4 caracteres';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    // Número de Boleta Inicial
                    TextFormField(
                      controller: _numeroBoletaInicialController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Boleta Inicial',
                        hintText: 'Ej: 1',
                        prefixIcon: Icon(Icons.format_list_numbered),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (String? value) {
                        if (value != null && value.isNotEmpty) {
                          if (int.tryParse(value) == null ||
                              int.parse(value) < 1) {
                            return 'Debe ser un número positivo';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Código de Establecimiento
                    TextFormField(
                      controller: _codigoEstablecimientoController,
                      decoration: const InputDecoration(
                        labelText: 'Código de Establecimiento',
                        hintText: 'Ej: EST001',
                        prefixIcon: Icon(Icons.store),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Sucursal Central'),
                subtitle: const Text(
                    'Las sucursales centrales tienen permisos especiales'),
                value: _sucursalCentral,
                activeColor: const Color(0xFFE31E24),
                onChanged: (bool value) =>
                    setState(() => _sucursalCentral = value),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE31E24),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final Map<String, Object> data = <String, Object>{
                if (widget.sucursal != null) 'id': widget.sucursal!.id,
                'nombre': _nombreController.text,
                'direccion': _direccionController.text,
                'sucursalCentral': _sucursalCentral,
                if (_serieFacturaController.text.isNotEmpty)
                  'serieFactura': _serieFacturaController.text,
                if (_numeroFacturaInicialController.text.isNotEmpty)
                  'numeroFacturaInicial':
                      int.parse(_numeroFacturaInicialController.text),
                if (_serieBoletaController.text.isNotEmpty)
                  'serieBoleta': _serieBoletaController.text,
                if (_numeroBoletaInicialController.text.isNotEmpty)
                  'numeroBoletaInicial':
                      int.parse(_numeroBoletaInicialController.text),
                if (_codigoEstablecimientoController.text.isNotEmpty)
                  'codigoEstablecimiento':
                      _codigoEstablecimientoController.text,
              };
              widget.onSave(data);
              Navigator.pop(context);
            }
          },
          icon: Icon(esNuevaSucursal ? Icons.add : Icons.save),
          label: Text(esNuevaSucursal ? 'Crear' : 'Guardar'),
        ),
      ],
    );
  }
}
