import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/categoria.model.dart';
import 'package:condorsmotors/models/color.model.dart';
import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/screens/colabs/widgets/list_busqueda_producto.dart';
import 'package:condorsmotors/utils/busqueda_producto_utils.dart'
    show BusquedaProductoUtils, TipoDescuento;
import 'package:condorsmotors/widgets/paginador.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BusquedaProductoWidget extends StatefulWidget {
  final List<Map<String, dynamic>> productos;
  final List<String> categorias; // Esta será una lista de fallback
  final Function(Map<String, dynamic>) onProductoSeleccionado;
  final bool isLoading;
  // Mantener sucursalId solo para información/referencia
  final String? sucursalId;

  const BusquedaProductoWidget({
    super.key,
    required this.productos,
    required this.onProductoSeleccionado,
    this.categorias = const <String>['Todas'],
    this.isLoading = false,
    this.sucursalId,
  });

  @override
  State<BusquedaProductoWidget> createState() => _BusquedaProductoWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Map<String, dynamic>>('productos', productos))
      ..add(IterableProperty<String>('categorias', categorias))
      ..add(ObjectFlagProperty<Function(Map<String, dynamic>)>.has(
          'onProductoSeleccionado', onProductoSeleccionado))
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading))
      ..add(StringProperty('sucursalId', sucursalId));
  }
}

class _BusquedaProductoWidgetState extends State<BusquedaProductoWidget>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _searchAnimationController;
  bool _isSearchExpanded = false;

  // Nuevos controladores y estados para dropdowns plegables
  late AnimationController _categoriaAnimationController;
  bool _isCategoriaExpanded = false;

  late AnimationController _promocionAnimationController;
  bool _isPromocionExpanded = false;

  String _filtroCategoria = 'Todos';
  List<Map<String, dynamic>> _productosFiltrados = <Map<String, dynamic>>[];

  // Lista de categorías cargadas desde la API
  List<Categoria> _categoriasFromApi = <Categoria>[];
  List<String> _categoriasList = <String>['Todos'];
  bool _loadingCategorias = false;

  // Lista de colores disponibles
  List<ColorApp> _colores = <ColorApp>[];

  // Paginación (local)
  int _itemsPorPagina = 10;
  int _paginaActual = 0;
  int _totalPaginas = 0;

  // Filtrado por tipo de descuento
  TipoDescuento _tipoDescuentoSeleccionado = TipoDescuento.todos;

  // Estado para indicar que estamos cargando
  bool _isLoadingLocal = false;

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

    _categoriaAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _promocionAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Inicializar productos filtrados con los productos proporcionados
    _productosFiltrados = List<Map<String, dynamic>>.from(widget.productos);

    // Configuramos los ítems por página después de que el widget esté renderizado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _actualizarItemsPorPaginaSegunDispositivo();
      _cargarCategorias();
      _cargarColores();
      _filtrarProductos(); // Esto actualizará _productosFiltrados con los filtros iniciales
    });
  }

  @override
  void didUpdateWidget(BusquedaProductoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambia la lista de productos, actualizar productos filtrados
    if (oldWidget.productos != widget.productos) {
      debugPrint(
          '📦 Actualizando productos: ${widget.productos.length} productos recibidos');
      _productosFiltrados = List<Map<String, dynamic>>.from(widget.productos);
      _filtrarProductos();
    }
  }

  /// Carga las categorías desde la API o usa las proporcionadas como fallback
  Future<void> _cargarCategorias() async {
    setState(() {
      _loadingCategorias = true;
    });

    try {
      // Intentar cargar desde API
      final List<Categoria> categoriasApi =
          await api.categorias.getCategoriasObjetos();

      // Usar el método de utilidades para combinar categorías
      final List<String> categoriasCombinadas =
          BusquedaProductoUtils.combinarCategorias(
        productos: widget.productos,
        categoriasFallback: widget.categorias,
        categoriasApi: categoriasApi,
      );

      setState(() {
        _categoriasFromApi = categoriasApi;
        _categoriasList = categoriasCombinadas;
        _loadingCategorias = false;
      });

      debugPrint('🔍 Categorías cargadas: ${categoriasCombinadas.length}');
    } catch (e) {
      debugPrint('🚨 Error al cargar categorías: $e');
      setState(() {
        _loadingCategorias = false;
        _categoriasList = <String>[
          'Todos'
        ]; // Al menos tener "Todos" como opción
      });
    }
  }

  /// Carga los colores desde la API
  Future<void> _cargarColores() async {
    try {
      final List<ColorApp> colores = await api.colores.getColores();
      setState(() {
        _colores = colores;
      });
      debugPrint('🎨 Colores cargados: ${colores.length}');
    } catch (e) {
      debugPrint('🚨 Error al cargar colores: $e');
    }
  }

  /// Método principal para filtrar productos
  void _filtrarProductos() {
    setState(() {
      _isLoadingLocal = true;
    });

    debugPrint('🔍 Iniciando filtrado de productos...');
    debugPrint(
        '📊 Total productos antes de filtrar: ${widget.productos.length}');

    final List<Map<String, dynamic>> resultados =
        BusquedaProductoUtils.filtrarProductos(
      productos: widget.productos,
      filtroTexto: _searchController.text.toLowerCase(),
      filtroCategoria: _filtroCategoria,
      tipoDescuento: _tipoDescuentoSeleccionado,
      debugMode: true,
    );

    debugPrint('✅ Productos filtrados: ${resultados.length}');

    setState(() {
      _productosFiltrados = resultados;
      _paginaActual = 0; // Reiniciar a primera página
      _calcularTotalPaginas();
      _isLoadingLocal = false;
    });

    // Depuración detallada del resultado
    debugPrint('📊 Resumen de filtrado:');
    debugPrint('- Productos totales: ${widget.productos.length}');
    debugPrint('- Productos filtrados: ${_productosFiltrados.length}');
    debugPrint('- Filtro categoría: $_filtroCategoria');
    debugPrint('- Filtro texto: "${_searchController.text}"');
    debugPrint('- Tipo descuento: $_tipoDescuentoSeleccionado');
  }

  void _calcularTotalPaginas() {
    final int totalProductos = _productosFiltrados.length;
    _totalPaginas = (totalProductos / _itemsPorPagina).ceil();
    if (_totalPaginas == 0) {
      _totalPaginas = 1; // Mínimo 1 página aunque esté vacía
    }
    debugPrint(
        '📊 Total páginas calculadas: $_totalPaginas (total productos: $totalProductos, items por página: $_itemsPorPagina)');
  }

  List<Map<String, dynamic>> _getProductosPaginaActual() {
    if (_productosFiltrados.isEmpty) {
      debugPrint('⚠️ No hay productos filtrados disponibles');
      return <Map<String, dynamic>>[];
    }

    final int inicio = _paginaActual * _itemsPorPagina;

    // Validación para evitar errores de rango
    if (inicio >= _productosFiltrados.length) {
      debugPrint(
          '⚠️ Inicio de paginación fuera de rango: $_paginaActual de $_totalPaginas (inicio=$inicio, total=${_productosFiltrados.length})');
      _paginaActual = 0;
      return _getProductosPaginaActual();
    }

    final int fin = (inicio + _itemsPorPagina < _productosFiltrados.length)
        ? inicio + _itemsPorPagina
        : _productosFiltrados.length;

    debugPrint(
        '📄 Obteniendo productos página $_paginaActual: $inicio-$fin de ${_productosFiltrados.length}');

    try {
      final List<Map<String, dynamic>> productosEnPagina =
          _productosFiltrados.sublist(inicio, fin);
      debugPrint('✅ Productos en página actual: ${productosEnPagina.length}');
      return productosEnPagina;
    } catch (e) {
      debugPrint('🚨 Error al obtener productos de la página: $e');
      // En caso de error, intentar mostrar la primera página
      _paginaActual = 0;
      if (_productosFiltrados.isNotEmpty) {
        // Intentar obtener algunos productos para mostrar
        final int elementosAMostrar =
            _productosFiltrados.length > 5 ? 5 : _productosFiltrados.length;
        return _productosFiltrados.sublist(0, elementosAMostrar);
      }
      return <Map<String, dynamic>>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Container(
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
            child: isMobile ? _buildMobileFilters() : _buildDesktopFilters(),
          ),

          // Resumen de resultados con indicador del filtro activo
          _buildFilterSummary(),

          // Resultados de la búsqueda usando el componente refactorizado
          Expanded(
            child: ListBusquedaProducto(
              productos: _getProductosPaginaActual(),
              onProductoSeleccionado: widget.onProductoSeleccionado,
              isLoading: widget.isLoading || _isLoadingLocal,
              filtroCategoria: _filtroCategoria,
              colores: _colores,
              darkBackground: darkBackground,
              darkSurface: darkSurface,
              mensajeVacio: _filtroCategoria != 'Todos'
                  ? 'No hay productos en la categoría "$_filtroCategoria"'
                  : 'Intenta con otro filtro',
              onRestablecerFiltro: () {
                _restablecerTodosFiltros();
                debugPrint(
                    '🔄 Filtros restablecidos desde ListBusquedaProducto');

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Se han restablecido todos los filtros'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              tieneAlgunFiltroActivo: _filtroCategoria != 'Todos' ||
                  _searchController.text.isNotEmpty ||
                  _tipoDescuentoSeleccionado != TipoDescuento.todos,
            ),
          ),

          // Paginador (solo en la parte inferior)
          if (_totalPaginas > 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildPaginador(),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileFilters() {
    // Verificar si hay algún filtro activo
    final bool hayFiltrosActivos = _filtroCategoria != 'Todos' ||
        _searchController.text.isNotEmpty ||
        _tipoDescuentoSeleccionado != TipoDescuento.todos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Fila de botones (siempre visible en la parte superior)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              // Botón de categoría
              Container(
                decoration: BoxDecoration(
                  color: _isCategoriaExpanded
                      ? Colors.blue.withOpacity(0.2)
                      : darkBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isCategoriaExpanded
                            ? Icons.category
                            : Icons.category_outlined,
                        color:
                            _isCategoriaExpanded || _filtroCategoria != 'Todos'
                                ? Colors.blue
                                : Colors.white70,
                        size: 20,
                      ),
                      if (!_isCategoriaExpanded &&
                          _filtroCategoria != 'Todos') ...[
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
                  onPressed: _toggleCategoria,
                  tooltip:
                      _isCategoriaExpanded ? 'Cerrar categorías' : 'Categorías',
                ),
              ),

              // Botón de promoción
              Container(
                decoration: BoxDecoration(
                  color: _isPromocionExpanded
                      ? Colors.purple.withOpacity(0.2)
                      : darkBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPromocionExpanded
                            ? Icons.local_offer
                            : Icons.local_offer_outlined,
                        color: _isPromocionExpanded ||
                                _tipoDescuentoSeleccionado !=
                                    TipoDescuento.todos
                            ? Colors.purple
                            : Colors.white70,
                        size: 20,
                      ),
                      if (!_isPromocionExpanded &&
                          _tipoDescuentoSeleccionado !=
                              TipoDescuento.todos) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.purple,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  onPressed: _togglePromocion,
                  tooltip: _isPromocionExpanded
                      ? 'Cerrar promociones'
                      : 'Promociones',
                ),
              ),

              // Botón de búsqueda
              Container(
                decoration: BoxDecoration(
                  color: _isSearchExpanded
                      ? Colors.orange.withOpacity(0.2)
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

              // Nuevo botón de limpiar filtros
              Container(
                decoration: BoxDecoration(
                  color: hayFiltrosActivos
                      ? Colors.red.withOpacity(0.2)
                      : darkBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.filter_list_off,
                    color: hayFiltrosActivos ? Colors.red : Colors.white38,
                    size: 20,
                  ),
                  onPressed: hayFiltrosActivos
                      ? () {
                          // Cerrar cualquier dropdown expandido
                          if (_isCategoriaExpanded) {
                            _toggleCategoria();
                          }
                          if (_isPromocionExpanded) {
                            _togglePromocion();
                          }
                          if (_isSearchExpanded) {
                            _toggleSearch();
                          }

                          // Limpiar todos los filtros
                          _restablecerTodosFiltros();

                          // Mostrar feedback visual
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Filtros restablecidos'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      : null, // Deshabilitar si no hay filtros activos
                  tooltip: 'Limpiar filtros',
                ),
              ),
            ],
          ),
        ),

        // Contenido expandido (aparece debajo de los botones)
        if (_isCategoriaExpanded) _buildCategoriaExpandida(),
        if (_isPromocionExpanded) _buildPromocionExpandida(),
        if (_isSearchExpanded) _buildSearchExpandido(),
      ],
    );
  }

  Widget _buildDesktopFilters() {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Categoría:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              _buildCategoriasDropdown(),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Promoción:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              _buildTipoPromocionDropdown(),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Buscar:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              _buildSearchField(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: darkBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: <Widget>[
          const Icon(Icons.search, color: Colors.white60, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o código',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (_) => _filtrarProductos(),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white60, size: 18),
              onPressed: () {
                _searchController.clear();
                _filtrarProductos();
              },
              tooltip: 'Limpiar',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 18,
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
          // Mostrar filtro activo si hay uno
          if (_filtroCategoria != 'Todos')
            _buildActiveFilter(
              icon: Icons.filter_list,
              label: 'Categoría: $_filtroCategoria',
              color: Colors.blue,
              onClear: () => _cambiarCategoria('Todos'),
            ),

          // Mostrar filtro de búsqueda si hay uno
          if (_searchController.text.isNotEmpty)
            _buildActiveFilter(
              icon: Icons.search,
              label: 'Búsqueda: "${_searchController.text}"',
              color: Colors.orange,
              onClear: () {
                _searchController.clear();
                _filtrarProductos();
              },
            ),

          // Mostrar filtro de promoción si hay uno activo
          if (_tipoDescuentoSeleccionado != TipoDescuento.todos)
            _buildActiveFilter(
              icon: _tipoDescuentoSeleccionado == TipoDescuento.promoGratis
                  ? Icons.card_giftcard
                  : Icons.percent,
              label:
                  'Promoción: ${_tipoDescuentoSeleccionado == TipoDescuento.promoGratis ? 'Lleva y Paga' : 'Descuento %'}',
              color: _tipoDescuentoSeleccionado == TipoDescuento.promoGratis
                  ? Colors.green
                  : Colors.purple,
              onClear: () {
                setState(() {
                  _tipoDescuentoSeleccionado = TipoDescuento.todos;
                });
                _filtrarProductos();
              },
            ),

          Text(
            'Mostrando ${_getProductosPaginaActual().length} de ${_productosFiltrados.length} productos',
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
        color: color.withOpacity(0.2),
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

  @override
  void dispose() {
    _searchController.dispose();
    _searchAnimationController.dispose();
    _categoriaAnimationController.dispose();
    _promocionAnimationController.dispose();
    super.dispose();
  }

  void _actualizarItemsPorPaginaSegunDispositivo() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final int nuevoItemsPorPagina = isMobile ? 100 : 10;

    if (_itemsPorPagina != nuevoItemsPorPagina) {
      debugPrint(
          '📱 Cambiando a modo ${isMobile ? "móvil" : "escritorio"}: $nuevoItemsPorPagina productos por página');
      setState(() {
        _itemsPorPagina = nuevoItemsPorPagina;
        _paginaActual = 0;
        _calcularTotalPaginas();
      });
    }
  }

  void _cambiarCategoria(String? nuevaCategoria) {
    if (nuevaCategoria == null) {
      debugPrint('⚠️ Se intentó cambiar a una categoría nula');
      return;
    }

    // Usar el método de normalización
    final String valorCategoriaFinal =
        BusquedaProductoUtils.normalizarCategoria(nuevaCategoria);
    final bool esCategoriaTodos =
        BusquedaProductoUtils.esCategoriaTodos(valorCategoriaFinal);

    // Usar 'Todos' como forma estándar cuando es la categoría general
    final String valorGuardar =
        esCategoriaTodos ? 'Todos' : valorCategoriaFinal;

    if (valorGuardar != _filtroCategoria) {
      debugPrint(
          '🔄 Cambiando categoría: "$_filtroCategoria" → "$valorGuardar"');

      // Verificar si la categoría existe en la lista (saltarse esta verificación para 'Todos')
      if (!esCategoriaTodos) {
        bool categoriaExiste = false;

        // Buscar de manera más flexible, ignorando mayúsculas/minúsculas
        for (final String cat in _categoriasList) {
          if (cat.trim().toLowerCase() == valorCategoriaFinal.toLowerCase()) {
            categoriaExiste = true;
            break;
          }
        }

        if (!categoriaExiste) {
          debugPrint(
              '⚠️ Advertencia: La categoría "$valorCategoriaFinal" no existe en la lista de categorías');
          // Mostrar las categorías disponibles para depuración
          final List<String> categoriasNormalizadas =
              _categoriasList.map((String c) => c.toLowerCase()).toList();
          debugPrint(
              '📋 Categorías disponibles (normalizadas): $categoriasNormalizadas');
        }
      }

      setState(() {
        _filtroCategoria = valorGuardar;
        _paginaActual = 0; // Reiniciar a primera página
      });

      _filtrarProductos(); // Volver a filtrar con la nueva categoría
    } else {
      debugPrint('ℹ️ La categoría seleccionada ya es: "$_filtroCategoria"');
    }
  }

  Widget _buildPaginador() {
    // Creamos un objeto Paginacion basado en nuestros datos actuales
    final Paginacion paginacion = Paginacion(
      currentPage: _paginaActual + 1, // Convertir a 1-indexed para el Paginador
      totalPages: _totalPaginas,
      totalItems: _productosFiltrados.length,
      hasNext: _paginaActual < _totalPaginas - 1,
      hasPrev: _paginaActual > 0,
    );

    // Determinar si estamos en una pantalla pequeña
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Paginador(
      paginacion: paginacion,
      onPageChanged: (int page) =>
          _irAPagina(page - 1), // Convertir de 1-indexed a 0-indexed
      backgroundColor: darkSurface,
      textColor: Colors.white,
      accentColor: Colors.blue,
      radius: 8.0,
      maxVisiblePages: isMobile ? 3 : 5,
      forceCompactMode: isMobile, // Forzar modo compacto en móviles
    );
  }

  Widget _buildCategoriasDropdown() {
    // Normalizar el valor actual para asegurar consistencia
    final String valorNormalizado =
        BusquedaProductoUtils.normalizarCategoria(_filtroCategoria);

    // Verificar que el valor esté en la lista de categorías
    final bool valorExisteEnLista = _categoriasList.any(
        (String cat) => cat.toLowerCase() == valorNormalizado.toLowerCase());

    // Si el valor no está en la lista y no es 'Todos', añadirlo temporalmente
    List<String> categoriasFinal = <String>[..._categoriasList];
    if (!valorExisteEnLista &&
        !BusquedaProductoUtils.esCategoriaTodos(valorNormalizado)) {
      debugPrint(
          '⚠️ Valor seleccionado "$valorNormalizado" no encontrado en la lista, añadiéndolo temporalmente');
      categoriasFinal.add(valorNormalizado);
    }

    // Asegurar que 'Todos' está en la lista y solo una vez
    categoriasFinal = categoriasFinal
        .where((String cat) =>
            !BusquedaProductoUtils.esCategoriaTodos(cat) || cat == 'Todos')
        .toList();
    if (!categoriasFinal.contains('Todos')) {
      categoriasFinal.insert(0, 'Todos');
    }

    debugPrint(
        '🔍 DropdownButton categorías: valor=$valorNormalizado, items=${categoriasFinal.length}');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: darkBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valorNormalizado,
          isExpanded: true,
          icon: _loadingCategorias
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.arrow_drop_down, color: Colors.white70),
          dropdownColor: darkSurface,
          items: categoriasFinal.map((String categoria) {
            // Si tenemos categorías de la API, podemos mostrar cuántos productos hay
            int totalProductos = 0;
            if (categoria != 'Todos' &&
                !BusquedaProductoUtils.esCategoriaTodos(categoria)) {
              final Categoria catObj = _categoriasFromApi.firstWhere(
                (Categoria c) =>
                    c.nombre.toLowerCase() == categoria.toLowerCase(),
                orElse: () => Categoria(id: 0, nombre: categoria),
              );
              totalProductos = catObj.totalProductos;
            }

            return DropdownMenuItem<String>(
              value: categoria,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      categoria,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: categoria.toLowerCase() ==
                                valorNormalizado.toLowerCase()
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Mostrar cantidad de productos si es categoría de API y no es 'Todos'
                  if (!BusquedaProductoUtils.esCategoriaTodos(categoria) &&
                      totalProductos > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$totalProductos',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: _cambiarCategoria,
        ),
      ),
    );
  }

  Widget _buildTipoPromocionDropdown() {
    // Mapeo de tipos de promoción a sus etiquetas e iconos (sin liquidación)
    final Map<TipoDescuento, Map<String, Object>> tiposPromocion =
        <TipoDescuento, Map<String, Object>>{
      TipoDescuento.todos: <String, Object>{
        'label': 'Todas',
        'icon': Icons.check_circle_outline,
        'color': Colors.blue,
      },
      TipoDescuento.promoGratis: <String, Object>{
        'label': 'Lleva y Paga',
        'icon': Icons.card_giftcard,
        'color': Colors.green,
      },
      TipoDescuento.descuentoPorcentual: <String, Object>{
        'label': 'Descuento %',
        'icon': Icons.percent,
        'color': Colors.purple,
      },
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TipoDescuento>(
          value: _tipoDescuentoSeleccionado == TipoDescuento.liquidacion
              ? TipoDescuento
                  .todos // Si está seleccionado liquidación, cambiar a todos
              : _tipoDescuentoSeleccionado,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          dropdownColor: darkSurface,
          items: tiposPromocion.entries
              .map((MapEntry<TipoDescuento, Map<String, Object>> entry) {
            final TipoDescuento tipo = entry.key;
            final Map<String, Object> datos = entry.value;
            final Color iconColor = _tipoDescuentoSeleccionado == tipo
                ? datos['color'] as Color
                : Colors.grey;

            return DropdownMenuItem<TipoDescuento>(
              value: tipo,
              child: Row(
                children: <Widget>[
                  Icon(
                    datos['icon'] as IconData,
                    size: 16,
                    color: iconColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      datos['label'] as String,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: _tipoDescuentoSeleccionado == tipo
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (TipoDescuento? value) {
            if (value != null) {
              setState(() {
                _tipoDescuentoSeleccionado = value;
              });
              _filtrarProductos();
            }
          },
        ),
      ),
    );
  }

  /// Método para navegar a una página específica
  void _irAPagina(int pagina) {
    if (_totalPaginas <= 0) {
      debugPrint('ℹ️ No hay páginas disponibles para navegar');
      return;
    }

    if (pagina < 0) {
      pagina = 0; // Evitar páginas negativas
      debugPrint('⚠️ Ajustando página negativa a 0');
    }

    if (pagina >= _totalPaginas) {
      pagina = _totalPaginas - 1; // Evitar páginas fuera de rango
      debugPrint('⚠️ Ajustando página > $_totalPaginas a ${_totalPaginas - 1}');
    }

    debugPrint('🔄 Cambiando a página ${pagina + 1} de $_totalPaginas');

    // Solo actualizar si realmente cambiamos de página
    if (pagina != _paginaActual) {
      setState(() {
        _paginaActual = pagina;
      });
    }
  }

  // Nuevo método para restablecer todos los filtros
  void _restablecerTodosFiltros() {
    debugPrint('🔄 Restableciendo todos los filtros');

    // Guardar valores anteriores para diagnóstico
    final String categoriaAnterior = _filtroCategoria;
    final TipoDescuento tipoDescuentoAnterior = _tipoDescuentoSeleccionado;
    final String busquedaAnterior = _searchController.text;

    // Primero actualizar los estados internos
    setState(() {
      // Restablecer categaría explícitamente a 'Todos'
      _filtroCategoria = 'Todos';

      // Restablecer tipo de descuento a 'todos'
      _tipoDescuentoSeleccionado = TipoDescuento.todos;

      // Limpiar campo de búsqueda
      _searchController.clear();

      // Restablecer página actual
      _paginaActual = 0;
    });

    // Logging detallado para diagnóstico
    debugPrint(
        '🔍 Filtros antes: Categoría="$categoriaAnterior", Búsqueda="$busquedaAnterior", Promoción=$tipoDescuentoAnterior');
    debugPrint(
        '🧹 Filtros limpiados. Aplicando: Categoría="Todos", Búsqueda="", Promoción=todos');

    // Ahora filtrar los productos con los nuevos valores
    _filtrarProductos();

    // Verificación post-restablecimiento
    debugPrint(
        '✅ Verificación: Categoría actual="$_filtroCategoria", Productos filtrados=${_productosFiltrados.length}');
    debugPrint('✅ Todos los filtros han sido restablecidos');
  }

  // Método para alternar la expansión del dropdown de categoría
  void _toggleCategoria() {
    // Cerrar otros dropdowns si este se está abriendo
    if (!_isCategoriaExpanded) {
      if (_isSearchExpanded) {
        _toggleSearch();
      }
      if (_isPromocionExpanded) {
        _togglePromocion();
      }
    }

    setState(() {
      _isCategoriaExpanded = !_isCategoriaExpanded;
      if (_isCategoriaExpanded) {
        _categoriaAnimationController.forward();
      } else {
        _categoriaAnimationController.reverse();
      }
    });
  }

  // Método para alternar la expansión del dropdown de promoción
  void _togglePromocion() {
    // Cerrar otros dropdowns si este se está abriendo
    if (!_isPromocionExpanded) {
      if (_isSearchExpanded) {
        _toggleSearch();
      }
      if (_isCategoriaExpanded) {
        _toggleCategoria();
      }
    }

    setState(() {
      _isPromocionExpanded = !_isPromocionExpanded;
      if (_isPromocionExpanded) {
        _promocionAnimationController.forward();
      } else {
        _promocionAnimationController.reverse();
      }
    });
  }

  // Método para alternar la expansión de la barra de búsqueda
  void _toggleSearch() {
    // Cerrar otros dropdowns si este se está abriendo
    if (!_isSearchExpanded) {
      if (_isCategoriaExpanded) {
        _toggleCategoria();
      }
      if (_isPromocionExpanded) {
        _togglePromocion();
      }
    }

    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (_isSearchExpanded) {
        _searchAnimationController.forward();
      } else {
        _searchAnimationController.reverse();
        // Si se está cerrando la búsqueda, limpiar el texto
        if (_searchController.text.isNotEmpty) {
          _searchController.clear();
          _filtrarProductos();
        }
      }
    });
  }

  // Nuevo método: Contenido expandido para categoría
  Widget _buildCategoriaExpandida() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra con título
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.category,
                  color: Colors.blue,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Categoría',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _toggleCategoria,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          // Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: _buildCategoriasDropdown(),
          ),
        ],
      ),
    );
  }

  // Nuevo método: Contenido expandido para promoción
  Widget _buildPromocionExpandida() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra con título
          Container(
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.local_offer,
                  color: Colors.purple,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Promoción',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _togglePromocion,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          // Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: _buildTipoPromocionDropdown(),
          ),
        ],
      ),
    );
  }

  // Nuevo método: Contenido expandido para búsqueda
  Widget _buildSearchExpandido() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra con título
          Container(
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
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
                hintText: 'Buscar...',
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
                          _filtrarProductos();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => _filtrarProductos(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('darkBackground', darkBackground))
      ..add(ColorProperty('darkSurface', darkSurface));
  }
}
