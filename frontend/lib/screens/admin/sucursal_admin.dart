import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/providers/admin/sucursal.admin.riverpod.dart';
import 'package:condorsmotors/screens/admin/widgets/sucursal/sucursal_detalles.dart';
import 'package:condorsmotors/screens/admin/widgets/sucursal/sucursal_form.dart';
import 'package:condorsmotors/screens/admin/widgets/sucursal/sucursal_header.dart';
import 'package:condorsmotors/screens/admin/widgets/sucursal/sucursal_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// La clase Sucursal ha sido reemplazada por la importación de '../../models/sucursal.model.dart'
// La clase SucursalRequest ha sido movida al provider de sucursales

class SucursalAdminScreen extends ConsumerStatefulWidget {
  const SucursalAdminScreen({super.key});

  @override
  ConsumerState<SucursalAdminScreen> createState() =>
      _SucursalAdminScreenState();
}

class _SucursalAdminScreenState extends ConsumerState<SucursalAdminScreen>
    with SingleTickerProviderStateMixin {
  bool _mostrarAgrupados = true;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Estado para controlar el modo edición

  // Controladores para la lista
  final ScrollController _scrollController = ScrollController();

  // Filtros avanzados
  bool _mostrarFiltrosAvanzados = false;
  String _filtroTipo = 'Todos';

  // Estado de la lista
  bool _isListScrollable = false;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // Inicializar de manera asíncrona
      Future<void>.microtask(() async {
        await ref.read(sucursalAdminProvider.notifier).inicializar();
      });
      _isInitialized = true;
    }
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

  Future<void> _recargarDatos() async {
    final notifier = ref.read(sucursalAdminProvider.notifier);
    await notifier.limpiarCacheYRecargar();

    if (!mounted) {
      return;
    }

    final state = ref.read(sucursalAdminProvider);
    if (state.errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage),
          backgroundColor: const Color(0xFFE31E24),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos recargados exitosamente'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
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
    final String? error =
        await ref.read(sucursalAdminProvider.notifier).guardarSucursal(data);

    if (!mounted) {
      return;
    }

    // Cerramos el diálogo después de guardar
    Navigator.of(context).pop();

    if (error == null) {
      // Si no hubo error, recargamos explícitamente la caché
      await ref.read(sucursalAdminProvider.notifier).limpiarCacheYRecargar();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sucursal guardada exitosamente'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: const Color(0xFFE31E24),
          ),
        );
      }
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
      final String? error = await ref
          .read(sucursalAdminProvider.notifier)
          .eliminarSucursal(sucursal);

      if (!mounted) {
        return;
      }

      if (error == null) {
        // Si no hubo error, recargamos explícitamente la caché
        await ref.read(sucursalAdminProvider.notifier).limpiarCacheYRecargar();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Sucursal "${sucursal.nombre}" eliminada correctamente'),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: const Color(0xFFE31E24),
            ),
          );
        }
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

  @override
  Widget build(BuildContext context) {
    debugPrint('[SucursalAdminScreen] build ejecutado');
    final state = ref.watch(sucursalAdminProvider);
    final notifier = ref.read(sucursalAdminProvider.notifier);

    // Pantalla principal de listado de sucursales
    return Scaffold(
      body: Column(
        children: <Widget>[
          SucursalHeader(
            totalSucursales: state.sucursales.length,
            isLoading: state.isLoading,
            terminoBusqueda: state.terminoBusqueda,
            onSearchChanged: notifier.actualizarBusqueda,
            onReload: _recargarDatos,
            onAddNew: _mostrarFormularioSucursal,
            onToggleFiltros: _toggleFiltrosAvanzados,
            mostrarFiltrosAvanzados: _mostrarFiltrosAvanzados,
            filtroTipo: _filtroTipo,
            onFiltroTipoChanged: (String? value) {
              if (value != null) {
                setState(() => _filtroTipo = value);
              }
            },
            mostrarAgrupados: _mostrarAgrupados,
            onToggleAgrupados: (bool value) =>
                setState(() => _mostrarAgrupados = value),
          ),

          // Sección de resultados y contenido principal
          Expanded(
            child: Stack(
              children: [
                if (state.isLoading && state.sucursales.isEmpty)
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Cargando sucursales...',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  )
                else if (state.errorMessage.isNotEmpty)
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
                          state.errorMessage,
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
                          onPressed: notifier.cargarSucursales,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                else if (state.sucursales.isEmpty)
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
                          state.terminoBusqueda.isEmpty
                              ? 'No hay sucursales para mostrar'
                              : 'No se encontraron sucursales con "${state.terminoBusqueda}"',
                          style: const TextStyle(color: Colors.white54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (state.terminoBusqueda.isNotEmpty)
                          TextButton.icon(
                            onPressed: notifier.limpiarBusqueda,
                            icon: const Icon(Icons.clear),
                            label: const Text('Limpiar búsqueda'),
                          )
                        else
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE31E24),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _mostrarFormularioSucursal,
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
                        ? _buildAgrupadas(state, notifier)
                        : _buildListaCompleta(state),
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
                        backgroundColor: Colors.black.withValues(alpha: 0.6),
                        onPressed: _scrollToTop,
                        child: const Icon(Icons.keyboard_arrow_up, size: 20),
                      ),
                    ),
                  ),

                // Indicador de carga cuando está actualizando pero ya tiene datos
                if (state.isLoading && state.sucursales.isNotEmpty)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: 3,
                      child: LinearProgressIndicator(
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
        onPressed: _mostrarFormularioSucursal,
        tooltip: 'Agregar sucursal',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAgrupadas(SucursalAdminState state, SucursalAdmin notifier) {
    final List<Sucursal> sucursalesFiltradas =
        _aplicarFiltrosAvanzados(state.sucursales);

    final Map<String, List<Sucursal>> grupos =
        notifier.agruparSucursalesPorTipo();
    final List<Sucursal> sucursalesCentrales =
        grupos['Centrales'] ?? <Sucursal>[];
    final List<Sucursal> sucursalesNoCentrales =
        grupos['Sucursales'] ?? <Sucursal>[];

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: <Widget>[
        if (_filtroTipo != 'Todos' || state.terminoBusqueda.isNotEmpty)
          _buildFiltroHeader(state, notifier, sucursalesFiltradas.length),

        if (sucursalesCentrales.isNotEmpty) ...<Widget>[
          _buildGrupoHeader('Sucursales Centrales', sucursalesCentrales.length),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SucursalTable(
              sucursales: sucursalesCentrales,
              onDetails: _mostrarDetallesSucursal,
              onEdit: _mostrarFormularioSucursal,
              onDelete: _confirmarEliminarSucursal,
              shrinkWrap: true,
            ),
          ),
        ],
        if (sucursalesNoCentrales.isNotEmpty) ...<Widget>[
          if (sucursalesCentrales.isNotEmpty) const SizedBox(height: 16),
          _buildGrupoHeader('Sucursales', sucursalesNoCentrales.length),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SucursalTable(
              sucursales: sucursalesNoCentrales,
              onDetails: _mostrarDetallesSucursal,
              onEdit: _mostrarFormularioSucursal,
              onDelete: _confirmarEliminarSucursal,
              shrinkWrap: true,
            ),
          ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildFiltroHeader(
      SucursalAdminState state, SucursalAdmin notifier, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          const FaIcon(FontAwesomeIcons.filter, color: Colors.white54, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mostrando $count de ${state.sucursales.length} sucursales',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 30),
            ),
            onPressed: () {
              notifier.limpiarBusqueda();
              setState(() => _filtroTipo = 'Todos');
            },
            icon: const Icon(Icons.clear, size: 14),
            label: const Text('Limpiar filtros', style: TextStyle(fontSize: 12)),
          ),
        ],
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

  Widget _buildListaCompleta(SucursalAdminState state) {
    final List<Sucursal> sucursalesFiltradas =
        _aplicarFiltrosAvanzados(state.sucursales);

    return Column(
      children: [
        if (_filtroTipo != 'Todos' || state.terminoBusqueda.isNotEmpty)
          _buildFiltroHeader(
              state,
              ref.read(sucursalAdminProvider.notifier),
              sucursalesFiltradas.length),
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SucursalTable(
              sucursales: sucursalesFiltradas,
              onDetails: _mostrarDetallesSucursal,
              onEdit: _mostrarFormularioSucursal,
              onDelete: _confirmarEliminarSucursal,
              scrollController: _scrollController,
            ),
          ),
        ),
      ],
    );
  }
}


