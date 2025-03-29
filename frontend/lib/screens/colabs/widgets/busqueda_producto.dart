import 'package:flutter/material.dart';

import '../../../main.dart' show api;
import '../../../models/categoria.model.dart'; // Importar modelo de categoría
import '../../../models/color.model.dart'; // Importar modelo de color
import '../../../models/paginacion.model.dart';
import '../../../models/producto.model.dart'; // Importar modelo de producto
import '../../../utils/productos_utils.dart'; // Importar utilidades de productos
import '../../../widgets/paginador.dart';
import './list_busqueda_producto.dart'; // Importar nuestro nuevo componente

enum TipoDescuento {
  todos,
  liquidacion,
  promoGratis,
  descuentoPorcentual,
}

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
    this.categorias = const ['Todas'],
    this.isLoading = false,
    this.sucursalId,
  });

  @override
  State<BusquedaProductoWidget> createState() => _BusquedaProductoWidgetState();
}

class _BusquedaProductoWidgetState extends State<BusquedaProductoWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroCategoria = 'Todos'; // Cambiado a 'Todos' por estándar
  List<Map<String, dynamic>> _productosFiltrados = [];
  
  // Lista de categorías cargadas desde la API
  List<Categoria> _categoriasFromApi = [];
  List<String> _categoriasList = ['Todos']; // Nombres de categorías para el dropdown
  bool _loadingCategorias = false;
  
  // Lista de colores disponibles
  List<ColorApp> _colores = [];
  
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
    
    // Configuramos los ítems por página después de que el widget esté renderizado
    // para poder acceder al MediaQuery
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _actualizarItemsPorPaginaSegunDispositivo();
      _cargarCategorias(); // Primero cargar las categorías
      _cargarColores(); // Cargar colores
      _filtrarProductos(); // Finalmente filtrar productos
    });
  }

  @override
  void didUpdateWidget(BusquedaProductoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambia la lista de productos o las categorías, actualizar
    if (oldWidget.productos != widget.productos || 
        oldWidget.categorias != widget.categorias) {
      _filtrarProductos();
    }
  }
  
  /// Carga las categorías desde la API o usa las proporcionadas como fallback
  Future<void> _cargarCategorias() async {
    setState(() {
      _loadingCategorias = true;
    });
    
    try {
      // Extraer categorías únicas de los productos actuales
      final categoriasEnProductos = widget.productos
          .map((p) => p['categoria']?.toString().trim() ?? '')
          .where((cat) => cat.isNotEmpty)
          .toSet()
          .toList();
      
      debugPrint('🔍 Categorías extraídas de productos: $categoriasEnProductos');
      
      // Si tenemos categorías en los productos, usarlas
      if (categoriasEnProductos.isNotEmpty) {
        categoriasEnProductos.sort(); // Ordenar alfabéticamente
        setState(() {
          _categoriasList = ['Todos', ...categoriasEnProductos];
          _loadingCategorias = false;
        });
        return;
      }
      
      // Si no hay categorías en productos, intentar usar las de fallback
      if (widget.categorias.isNotEmpty) {
        setState(() {
          _categoriasList = ['Todos', ...widget.categorias.where((cat) => cat != 'Todos' && cat != 'Todas')];
          _loadingCategorias = false;
        });
        return;
      }
      
      // Solo como último recurso, intentar cargar desde API
      try {
        // Cargar categorías desde la API
        final categorias = await api.categorias.getCategoriasObjetos();
        
        // Ordenar por nombre
        categorias.sort((a, b) => a.nombre.compareTo(b.nombre));
        
        setState(() {
          _categoriasFromApi = categorias;
          _categoriasList = ['Todos', ...categorias.map((c) => c.nombre)];
          _loadingCategorias = false;
        });
        
        debugPrint('🔍 Categorías cargadas desde API: ${categorias.length}');
      } catch (e) {
        debugPrint('🚨 Error al cargar categorías desde API: $e');
        // En caso de error, usar categorías predefinidas básicas
        setState(() {
          _loadingCategorias = false;
          _categoriasList = ['Todos', 'Repuestos', 'Accesorios', 'Lubricantes'];
        });
      }
    } catch (e) {
      debugPrint('🚨 Error general en carga de categorías: $e');
      setState(() {
        _loadingCategorias = false;
        _categoriasList = ['Todos']; // Al menos tener "Todos" como opción
      });
    }
  }
  
  /// Carga los colores desde la API
  Future<void> _cargarColores() async {
    try {
      final colores = await api.colores.getColores();
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
    
    // Usar el filtrado local mejorado
    _filtrarProductosLocalmente();
    
    setState(() {
      _isLoadingLocal = false;
    });
  }
  
  /// Método para filtrado local (sin llamadas a API)
  void _filtrarProductosLocalmente() {
    // Filtrado local (comportamiento original)
    final filtroTexto = _searchController.text.toLowerCase();
    
    // Verificar que la categoría sea válida, usar "Todos" como fallback
    if (_filtroCategoria.isEmpty) {
      debugPrint('⚠️ Categoría vacía detectada, restableciendo a "Todos"');
      _filtroCategoria = 'Todos';
    }
    
    debugPrint('🔍 Filtrando localmente. Categoría: "$_filtroCategoria", Texto: "$filtroTexto"');
    
    // NUEVO: Normalizar la categoría para unificar 'Todos'/'Todas'
    final filtroCategoriaNormalizado = _normalizarCategoria(_filtroCategoria);
    
    // Verificación explícita de "Todos"
    final bool filtraTodos = _esCategoriaTodos(filtroCategoriaNormalizado);
    debugPrint('🔍 Filtro de categoría "$filtroCategoriaNormalizado" ${filtraTodos ? "INCLUYE TODOS" : "NO INCLUYE TODOS"}');
    
    // NUEVO: Utilizar ProductosUtils cuando sea posible
    if (_esFormatoCompatible(widget.productos)) {
      try {
        // Convertir los datos al formato esperado por ProductosUtils
        final List<Producto> productosFormateados = _convertirAProductos(widget.productos);
        
        // Usar la función centralizada de filtrado
        final productosFiltrados = ProductosUtils.filtrarProductos(
          productos: productosFormateados, 
          searchQuery: filtroTexto,
          selectedCategory: filtroCategoriaNormalizado,
          debugMode: true, // Habilitar depuración detallada
        );
        
        debugPrint('✅ Filtrado usando ProductosUtils: ${productosFiltrados.length} resultados');
        
        // Convertir de nuevo al formato de mapa esperado por la UI
        final resultadosFiltrados = _convertirAMapas(productosFiltrados);
        
        // Aplicar filtrado adicional por tipo de descuento (no incluido en ProductosUtils)
        final resultadosConDescuentoFiltrado = _filtrarPorTipoDescuento(resultadosFiltrados);
        
        setState(() {
          _productosFiltrados = resultadosConDescuentoFiltrado;
          _paginaActual = 0; // Reiniciar a la primera página al cambiar filtros
          _calcularTotalPaginas();
        });
        
        return; // Terminar aquí si pudimos usar ProductosUtils
      } catch (e) {
        // Si hay algún error, caer al método de filtrado original
        debugPrint('⚠️ Error al usar ProductosUtils, usando filtrado alternativo: $e');
      }
    }
    
    // Si no podemos usar ProductosUtils, usamos el filtrado mejorado:
    final List<Map<String, dynamic>> resultadosFiltrados = widget.productos.where((producto) {
      // Filtrar por texto (nombre o código)
      final coincideTexto = filtroTexto.isEmpty ||
          producto['nombre'].toString().toLowerCase().contains(filtroTexto) ||
          producto['codigo'].toString().toLowerCase().contains(filtroTexto);
      
      // Filtrar por categoría (verificación exhaustiva)
      bool coincideCategoria = _esCategoriaTodos(filtroCategoriaNormalizado);
      
      if (!coincideCategoria && producto['categoria'] != null) {
        final categoriaProducto = producto['categoria'].toString().trim();
        final categoriaProductoNormalizada = categoriaProducto.toLowerCase();
        final filtroCategoriaNormalizadoLC = filtroCategoriaNormalizado.toLowerCase();
        
        // Intentar varias formas de comparación
        coincideCategoria = 
            categoriaProductoNormalizada == filtroCategoriaNormalizadoLC ||
            _normalizarCategoria(categoriaProducto).toLowerCase() == filtroCategoriaNormalizadoLC;
        
        // Depuración mejorada
        if (!coincideCategoria) {
          debugPrint('❌ No coincide: "$categoriaProducto" ($categoriaProductoNormalizada) vs "$filtroCategoriaNormalizado" ($filtroCategoriaNormalizadoLC)');
        } else {
          debugPrint('✅ Coincidencia: "$categoriaProducto" con "$filtroCategoriaNormalizado"');
        }
      }
      
      // Filtrar por tipo de descuento
      bool coincideDescuento = true;
      switch (_tipoDescuentoSeleccionado) {
        case TipoDescuento.liquidacion:
          coincideDescuento = producto['enLiquidacion'] == true;
          break;
        case TipoDescuento.promoGratis:
          coincideDescuento = producto['tienePromocionGratis'] == true;
          break;
        case TipoDescuento.descuentoPorcentual:
          coincideDescuento = producto['tieneDescuentoPorcentual'] == true;
          break;
        case TipoDescuento.todos:
          // No aplicar filtro adicional
          break;
      }
      
      return coincideTexto && coincideCategoria && coincideDescuento;
    }).toList();
    
    // Si no hay resultados con categoría específica, hacer diagnóstico detallado
    if (resultadosFiltrados.isEmpty && !_esCategoriaTodos(filtroCategoriaNormalizado)) {
      debugPrint('⚠️ No se encontraron productos con la categoría "$filtroCategoriaNormalizado"');
      
      // Listar todas las categorías disponibles con formato detallado
      final categoriasDiagnostico = widget.productos
          .map((p) => '${p['categoria']?.toString().trim() ?? 'null'} (minúsculas: ${p['categoria']?.toString().toLowerCase() ?? 'null'})')
          .toSet()
          .toList();
      
      debugPrint('📋 Categorías disponibles (detalladas): $categoriasDiagnostico');
      debugPrint('🔍 Buscando coincidencias parciales...');
      
      // Buscar coincidencias parciales para sugerir posibles soluciones
      for (var producto in widget.productos) {
        if (producto['categoria'] != null) {
          final catProd = producto['categoria'].toString().toLowerCase();
          final catFiltro = filtroCategoriaNormalizado.toLowerCase();
          
          if (catProd.contains(catFiltro) || catFiltro.contains(catProd)) {
            debugPrint('💡 Posible coincidencia: "$catProd" contiene o está contenido en "$catFiltro"');
          }
        }
      }
    }
    
    // Ordenar: primero los que tienen promociones, luego por nombre
    resultadosFiltrados.sort((a, b) {
      // Primero ordenar por si tiene alguna promoción
      final aPromo = (a['enLiquidacion'] == true) || 
                     (a['tienePromocionGratis'] == true) || 
                     (a['tieneDescuentoPorcentual'] == true);
      
      final bPromo = (b['enLiquidacion'] == true) || 
                     (b['tienePromocionGratis'] == true) || 
                     (b['tieneDescuentoPorcentual'] == true);
      
      if (aPromo && !bPromo) return -1;
      if (!aPromo && bPromo) return 1;
      
      // Si ambos tienen o no tienen promoción, ordenar por nombre
      return a['nombre'].toString().compareTo(b['nombre'].toString());
    });
    
    setState(() {
      _productosFiltrados = resultadosFiltrados;
      _paginaActual = 0; // Reiniciar a la primera página al cambiar filtros
      _calcularTotalPaginas();
    });
  }
  
  /// NUEVO: Método para normalizar la categoría (unifica 'Todos'/'Todas')
  String _normalizarCategoria(String categoria) {
    if (categoria.isEmpty) {
      return 'Todos'; // Categoría vacía se considera como "Todos"
    }
    
    final categoriaLC = categoria.trim().toLowerCase();
    if (categoriaLC == 'todas' || categoriaLC == 'todos' || categoriaLC == 'all') {
      return 'Todos'; // Normalizar a 'Todos' como estándar
    }
    return categoria.trim(); // Mantener mayúsculas/minúsculas originales, pero quitar espacios
  }
  
  /// NUEVO: Verificar si una categoría es la opción "todos/todas"
  bool _esCategoriaTodos(String categoria) {
    if (categoria.isEmpty) {
      return true; // Categoría vacía se considera como "Todos"
    }
    
    final categoriaLC = categoria.trim().toLowerCase();
    final esTodos = categoriaLC == 'todas' || categoriaLC == 'todos' || categoriaLC == 'all';
    if (esTodos) {
      debugPrint('✅ Categoría identificada como "Todos": "$categoria"');
    }
    return esTodos;
  }
  
  /// NUEVO: Verificar si los datos son compatibles con ProductosUtils
  bool _esFormatoCompatible(List<Map<String, dynamic>> productos) {
    if (productos.isEmpty) return false;
    
    // Verificar campos mínimos necesarios
    return productos.first.containsKey('nombre') && 
           productos.first.containsKey('categoria') &&
           productos.first.containsKey('codigo');
  }
  
  /// NUEVO: Convertir de Map<String, dynamic> a Producto para usar ProductosUtils
  List<Producto> _convertirAProductos(List<Map<String, dynamic>> productos) {
    return productos.map((p) => Producto(
      id: p['id'] is int ? p['id'] : int.tryParse(p['id']?.toString() ?? '0') ?? 0,
      sku: p['codigo']?.toString() ?? '',
      nombre: p['nombre']?.toString() ?? '',
      categoria: p['categoria']?.toString() ?? '',
      marca: p['marca']?.toString() ?? '',
      fechaCreacion: DateTime.now(),
      precioCompra: 0, // No es relevante para filtrado
      precioVenta: (p['precio'] is num) ? (p['precio'] as num).toDouble() : 0,
      stock: p['stock'] is int ? p['stock'] : int.tryParse(p['stock']?.toString() ?? '0') ?? 0,
      stockMinimo: p['stockMinimo'] is int ? p['stockMinimo'] : null,
      // Campos opcionales
      stockBajo: p['stock'] != null && p['stockMinimo'] != null ? 
          p['stock'] < p['stockMinimo'] : false,
      descripcion: p['descripcion']?.toString(),
    )).toList();
  }
  
  /// NUEVO: Convertir de Producto a Map<String, dynamic> para la UI
  List<Map<String, dynamic>> _convertirAMapas(List<Producto> productos) {
    return productos.map((p) => {
      'id': p.id,
      'codigo': p.sku,
      'nombre': p.nombre,
      'categoria': p.categoria,
      'marca': p.marca,
      'precio': p.precioVenta,
      'stock': p.stock,
      'stockMinimo': p.stockMinimo,
      // Preservar otros campos si existen en el objeto original
      'enLiquidacion': false, // Valores por defecto
      'tienePromocionGratis': false,
      'tieneDescuentoPorcentual': false,
    }).toList();
  }
  
  /// NUEVO: Filtrar por tipo de descuento (complemento a ProductosUtils)
  List<Map<String, dynamic>> _filtrarPorTipoDescuento(List<Map<String, dynamic>> productos) {
    if (_tipoDescuentoSeleccionado == TipoDescuento.todos) {
      return productos; // No aplicar filtro
    }
    
    return productos.where((producto) {
      switch (_tipoDescuentoSeleccionado) {
        case TipoDescuento.liquidacion:
          return producto['enLiquidacion'] == true;
        case TipoDescuento.promoGratis:
          return producto['tienePromocionGratis'] == true;
        case TipoDescuento.descuentoPorcentual:
          return producto['tieneDescuentoPorcentual'] == true;
        default:
          return true;
      }
    }).toList();
  }

  void _calcularTotalPaginas() {
    _totalPaginas = (_productosFiltrados.length / _itemsPorPagina).ceil();
    if (_totalPaginas == 0) _totalPaginas = 1; // Mínimo 1 página aunque esté vacía
  }
  
  List<Map<String, dynamic>> _getProductosPaginaActual() {
    if (_productosFiltrados.isEmpty) return [];
    
    final inicio = _paginaActual * _itemsPorPagina;
    
    // Validación para evitar errores de rango
    if (inicio >= _productosFiltrados.length) {
      // Si el inicio está fuera de rango, resetear a la primera página
      debugPrint('⚠️ Inicio de paginación fuera de rango: $_paginaActual de $_totalPaginas (inicio=$inicio, total=${_productosFiltrados.length})');
      _paginaActual = 0;
      return _getProductosPaginaActual();
    }
    
    final fin = (inicio + _itemsPorPagina < _productosFiltrados.length) 
        ? inicio + _itemsPorPagina 
        : _productosFiltrados.length;
    
    // Validación adicional para asegurar que el rango sea válido
    if (inicio < 0 || fin > _productosFiltrados.length || inicio >= fin) {
      debugPrint('⚠️ Advertencia: Rango inválido para paginación: inicio=$inicio, fin=$fin, total=${_productosFiltrados.length}');
      if (_productosFiltrados.isNotEmpty) {
        return [_productosFiltrados.first]; // Devolver al menos un elemento para mostrar algo
      }
      return [];
    }
    
    try {
      return _productosFiltrados.sublist(inicio, fin);
    } catch (e) {
      debugPrint('🚨 Error al obtener productos de la página: $e');
      // En caso de error, intentar mostrar la primera página
      _paginaActual = 0;
      if (_productosFiltrados.isNotEmpty) {
        // Intentar obtener algunos productos para mostrar
        final elementosAMostrar = _productosFiltrados.length > 5 ? 5 : _productosFiltrados.length;
        return _productosFiltrados.sublist(0, elementosAMostrar);
      }
      return [];
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Verificar tamaño de pantalla en cada build
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    // Actualizar ítems por página si cambia el tamaño (por ejemplo, rotación del dispositivo)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _actualizarItemsPorPaginaSegunDispositivo();
    });
    
    // Debug de la paginación actual
    debugPrint('📊 Paginación: página=${_paginaActual+1}/$_totalPaginas, items=$_itemsPorPagina, total=${_productosFiltrados.length}');
    
    final productosPaginados = _getProductosPaginaActual();
    final isLoading = widget.isLoading || _isLoadingLocal;
    
    return Container(
      color: darkBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Contenedor para filtros (adaptativo: columna en móviles, fila en más grandes)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: darkSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filtro de categoría
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Categoría:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: _buildCategoriasDropdown(),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Filtro por tipo de promoción (ahora como dropdown)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Promoción:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: _buildTipoPromocionDropdown(),
                          ),
                        ],
                      ),
                      
                      // Nuevo: campo de búsqueda
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Container(
                            decoration: BoxDecoration(
                              color: darkBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: [
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
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // Filtro de categoría
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                      
                      // Filtro por tipo de promoción
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                      
                      // Campo de búsqueda
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Container(
                              decoration: BoxDecoration(
                                color: darkBackground,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                children: [
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
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          
          // Resumen de resultados con indicador del filtro activo
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mostrar filtro activo si hay uno
                if (_filtroCategoria != 'Todos')
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.filter_list,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Categoría: $_filtroCategoria',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _cambiarCategoria('Todos'),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Mostrar filtro de búsqueda si hay uno
                if (_searchController.text.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Búsqueda: "${_searchController.text}"',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            _searchController.clear();
                            _filtrarProductos();
                          },
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Nuevo: Mostrar filtro de promoción si hay uno activo
                if (_tipoDescuentoSeleccionado != TipoDescuento.todos)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (_tipoDescuentoSeleccionado == TipoDescuento.promoGratis 
                          ? Colors.green 
                          : Colors.purple).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _tipoDescuentoSeleccionado == TipoDescuento.promoGratis 
                              ? Icons.card_giftcard 
                              : Icons.percent,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Promoción: ${_tipoDescuentoSeleccionado == TipoDescuento.promoGratis 
                              ? 'Lleva y Paga' 
                              : 'Descuento %'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _tipoDescuentoSeleccionado = TipoDescuento.todos;
                            });
                            _filtrarProductos();
                          },
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                Text(
                  'Mostrando ${productosPaginados.length} de ${_productosFiltrados.length} productos',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Resultados de la búsqueda usando el componente refactorizado
          Expanded(
            child: ListBusquedaProducto(
              productos: productosPaginados,
              onProductoSeleccionado: widget.onProductoSeleccionado,
              isLoading: isLoading,
              filtroCategoria: _filtroCategoria,
              colores: _colores,
              darkBackground: darkBackground,
              darkSurface: darkSurface,
              mensajeVacio: _filtroCategoria != 'Todos'
                ? 'No hay productos en la categoría "$_filtroCategoria"'
                : 'Intenta con otro filtro',
              onRestablecerFiltro: () {
                // Usar el método completo que restablece todos los filtros
                _restablecerTodosFiltros();
                debugPrint('🔄 Filtros restablecidos desde ListBusquedaProducto');
                
                // Mostrar un SnackBar para confirmar la acción
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
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Método para actualizar los ítems por página según el dispositivo
  void _actualizarItemsPorPaginaSegunDispositivo() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    if (isMobile && _itemsPorPagina != 100) {
      setState(() {
        debugPrint('📱 Cambiando a modo móvil: 100 productos por página');
        _itemsPorPagina = 100;
        _paginaActual = 0; // Volver a la primera página para evitar problemas
        _calcularTotalPaginas();
      });
    } else if (!isMobile && _itemsPorPagina != 10) {
      setState(() {
        debugPrint('🖥️ Cambiando a modo escritorio: 10 productos por página');
        _itemsPorPagina = 10;
        _paginaActual = 0; // Volver a la primera página para evitar problemas
        _calcularTotalPaginas();
      });
    }
  }

  // Método para cambiar la categoría seleccionada
  void _cambiarCategoria(String? nuevaCategoria) {
    if (nuevaCategoria == null) {
      debugPrint('⚠️ Se intentó cambiar a una categoría nula');
      return;
    }
    
    // MODIFICADO: Usar el método de normalización
    final valorCategoriaFinal = _normalizarCategoria(nuevaCategoria);
    final esCategoriaTodos = _esCategoriaTodos(valorCategoriaFinal);
    
    // Usar 'Todos' como forma estándar cuando es la categoría general
    final valorGuardar = esCategoriaTodos ? 'Todos' : valorCategoriaFinal;
    
    if (valorGuardar != _filtroCategoria) {
      debugPrint('🔄 Cambiando categoría: "$_filtroCategoria" → "$valorGuardar"');
      
      // Verificar si la categoría existe en la lista (saltarse esta verificación para 'Todos')
      if (!esCategoriaTodos) {
        bool categoriaExiste = false;
        
        // Buscar de manera más flexible, ignorando mayúsculas/minúsculas
        for (final cat in _categoriasList) {
          if (cat.trim().toLowerCase() == valorCategoriaFinal.toLowerCase()) {
            categoriaExiste = true;
            break;
          }
        }
        
        if (!categoriaExiste) {
          debugPrint('⚠️ Advertencia: La categoría "$valorCategoriaFinal" no existe en la lista de categorías');
          // Mostrar las categorías disponibles para depuración
          final categoriasNormalizadas = _categoriasList.map((c) => c.toLowerCase()).toList();
          debugPrint('📋 Categorías disponibles (normalizadas): $categoriasNormalizadas');
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
    final paginacion = Paginacion(
      currentPage: _paginaActual + 1, // Convertir a 1-indexed para el Paginador
      totalPages: _totalPaginas,
      totalItems: _productosFiltrados.length,
      hasNext: _paginaActual < _totalPaginas - 1,
      hasPrev: _paginaActual > 0,
    );
    
    // Determinar si estamos en una pantalla pequeña
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Paginador(
      paginacion: paginacion,
      onPageChanged: (page) => _irAPagina(page - 1), // Convertir de 1-indexed a 0-indexed
      backgroundColor: darkSurface,
      textColor: Colors.white,
      accentColor: Colors.blue,
      radius: 8.0,
      maxVisiblePages: isMobile ? 3 : 5,
      forceCompactMode: isMobile, // Forzar modo compacto en móviles
    );
  }
  
  // Método para construir el dropdown de categorías
  Widget _buildCategoriasDropdown() {
    // NUEVO: Normalizar el valor actual para asegurar consistencia
    final String valorNormalizado = _esCategoriaTodos(_filtroCategoria) 
        ? 'Todos' // Usar el estándar
        : _filtroCategoria;
    
    // NUEVO: Verificar que el valor esté en la lista de categorías
    final bool valorExisteEnLista = _categoriasList.any((cat) => 
        cat.toLowerCase() == valorNormalizado.toLowerCase());
    
    // NUEVO: Si el valor no está en la lista y no es 'Todos', añadirlo temporalmente
    List<String> categoriasFinal = [..._categoriasList];
    if (!valorExisteEnLista && !_esCategoriaTodos(valorNormalizado)) {
      debugPrint('⚠️ Valor seleccionado "$valorNormalizado" no encontrado en la lista, añadiéndolo temporalmente');
      categoriasFinal.add(valorNormalizado);
    }
    
    // NUEVO: Asegurar que 'Todos' está en la lista y solo una vez
    categoriasFinal = categoriasFinal.where((cat) => !_esCategoriaTodos(cat) || cat == 'Todos').toList();
    if (!categoriasFinal.contains('Todos')) {
      categoriasFinal.insert(0, 'Todos');
    }
    
    debugPrint('🔍 DropdownButton categorías: valor=$valorNormalizado, items=${categoriasFinal.length}');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: darkBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valorNormalizado, // MODIFICADO: Usar el valor normalizado
          isExpanded: true,
          icon: _loadingCategorias 
              ? const SizedBox(
                  width: 16, 
                  height: 16, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                )
              : const Icon(Icons.arrow_drop_down, color: Colors.white70),
          dropdownColor: darkSurface,
          items: categoriasFinal.map((categoria) { // MODIFICADO: Usar la lista filtrada
            // Si tenemos categorías de la API, podemos mostrar cuántos productos hay
            int totalProductos = 0;
            if (categoria != 'Todos' && !_esCategoriaTodos(categoria)) {
              final catObj = _categoriasFromApi.firstWhere(
                (c) => c.nombre.toLowerCase() == categoria.toLowerCase(),
                orElse: () => Categoria(id: 0, nombre: categoria),
              );
              totalProductos = catObj.totalProductos;
            }
            
            return DropdownMenuItem<String>(
              value: categoria,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      categoria,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: categoria.toLowerCase() == valorNormalizado.toLowerCase() 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  // Mostrar cantidad de productos si es categoría de API y no es 'Todos'
                  if (!_esCategoriaTodos(categoria) && totalProductos > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
  
  // Método para construir el dropdown del tipo de promoción
  Widget _buildTipoPromocionDropdown() {
    // Mapeo de tipos de promoción a sus etiquetas e iconos (sin liquidación)
    final Map<TipoDescuento, Map<String, dynamic>> tiposPromocion = {
      TipoDescuento.todos: {
        'label': 'Todas',
        'icon': Icons.check_circle_outline,
        'color': Colors.blue,
      },
      TipoDescuento.promoGratis: {
        'label': 'Lleva y Paga',
        'icon': Icons.card_giftcard,
        'color': Colors.green,
      },
      TipoDescuento.descuentoPorcentual: {
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
              ? TipoDescuento.todos  // Si está seleccionado liquidación, cambiar a todos
              : _tipoDescuentoSeleccionado,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          dropdownColor: darkSurface,
          items: tiposPromocion.entries.map((entry) {
            final tipo = entry.key;
            final datos = entry.value;
            final iconColor = _tipoDescuentoSeleccionado == tipo 
                ? datos['color'] as Color 
                : Colors.grey;
            
            return DropdownMenuItem<TipoDescuento>(
              value: tipo,
              child: Row(
                children: [
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
    final categoriaAnterior = _filtroCategoria;
    final tipoDescuentoAnterior = _tipoDescuentoSeleccionado;
    final busquedaAnterior = _searchController.text;
    
    // Primero actualizar los estados internos
    setState(() {
      // Restablecer categaría explícitamente a 'Todos' (sin usar _cambiarCategoria aún)
      _filtroCategoria = 'Todos';
      
      // Restablecer tipo de descuento a 'todos'
      _tipoDescuentoSeleccionado = TipoDescuento.todos;
      
      // Limpiar campo de búsqueda
      _searchController.clear();
      
      // Restablecer página actual
      _paginaActual = 0;
    });
    
    // Logging detallado para diagnóstico
    debugPrint('🔍 Filtros antes: Categoría="$categoriaAnterior", Búsqueda="$busquedaAnterior", Promoción=$tipoDescuentoAnterior');
    debugPrint('🧹 Filtros limpiados. Aplicando: Categoría="Todos", Búsqueda="", Promoción=todos');
    
    // Ahora filtrar los productos con los nuevos valores
    _filtrarProductos();
    
    // Verificación post-restablecimiento
    debugPrint('✅ Verificación: Categoría actual="$_filtroCategoria", Productos filtrados=${_productosFiltrados.length}');
    debugPrint('✅ Todos los filtros han sido restablecidos');
  }
}
