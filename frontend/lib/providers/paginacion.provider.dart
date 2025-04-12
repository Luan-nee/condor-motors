import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:flutter/foundation.dart';

/// Provider para manejar la lógica de paginación
class PaginacionProvider extends ChangeNotifier {
  /// Estado actual de la paginación
  Paginacion _paginacion = Paginacion(
    totalItems: 0,
    totalPages: 1,
    currentPage: 1,
    hasNext: false,
    hasPrev: false,
  );

  /// Límite de elementos por página (default del servidor: 50)
  int _itemsPerPage = 10;

  /// Orden de los resultados (asc o desc)
  String _orden = 'desc';

  /// Campo por el cual ordenar
  String? _ordenarPor;

  /// Término de búsqueda
  String _busqueda = '';

  /// Filtro aplicado
  String _filtro = '';

  /// Valor del filtro
  dynamic _valorFiltro;

  /// Tipo de filtro (eq, gt, lt, after, before)
  String _tipoFiltro = 'eq';

  /// Metadatos adicionales (opciones de ordenación, filtros, etc.)
  Map<String, dynamic>? _metadata;

  /// Valores máximos permitidos para tamaño de página
  static const int maximoPorPagina = 200;

  /// Opciones de tamaño de página comunes - memoizadas para mejor rendimiento
  static const List<int> opcionesTamanoPagina = [10, 50, 100, 200];

  /// Opciones de orden - memoizadas para mejor rendimiento
  static const Map<String, String> opcionesOrden = {
    'asc': 'Ascendente',
    'desc': 'Descendente',
  };

  /// Opciones de tipos de filtro - memoizadas para mejor rendimiento
  static const Map<String, String> opcionesTipoFiltro = {
    'eq': 'Igual a',
    'gt': 'Mayor que',
    'lt': 'Menor que',
    'after': 'Después de',
    'before': 'Antes de',
  };

  // Caché para opciones de sortBy, evitando procesamiento repetido
  List<String>? _opcSortByCache;

  // Caché para opciones de filtro, evitando procesamiento repetido
  List<String>? _opcFiltroCache;

  /// Acceso al objeto de paginación actual
  Paginacion get paginacion => _paginacion;

  /// Acceso al límite de elementos por página
  int get itemsPerPage => _itemsPerPage;

  /// Acceso al orden actual
  String get orden => _orden;

  /// Acceso al campo de ordenación
  String? get ordenarPor => _ordenarPor;

  /// Acceso al término de búsqueda
  String get busqueda => _busqueda;

  /// Acceso al filtro aplicado
  String get filtro => _filtro;

  /// Acceso al valor del filtro
  dynamic get valorFiltro => _valorFiltro;

  /// Acceso al tipo de filtro
  String get tipoFiltro => _tipoFiltro;

  /// Acceso a los metadatos
  Map<String, dynamic>? get metadata => _metadata;

  /// Obtiene opciones de ordenación desde los metadatos - optimizado con caché
  List<String> get opcionesSortBy {
    if (_opcSortByCache != null) {
      return _opcSortByCache!;
    }

    if (_metadata != null && _metadata!.containsKey('sortByOptions')) {
      final dynamic options = _metadata!['sortByOptions'];
      if (options is List) {
        _opcSortByCache = options.map((e) => e.toString()).toList();
        return _opcSortByCache!;
      }
    }
    _opcSortByCache = [];
    return _opcSortByCache!;
  }

  /// Obtiene opciones de filtros desde los metadatos - optimizado con caché
  List<String> get opcionesFiltro {
    if (_opcFiltroCache != null) {
      return _opcFiltroCache!;
    }

    if (_metadata != null && _metadata!.containsKey('filterOptions')) {
      final dynamic options = _metadata!['filterOptions'];
      if (options is List) {
        _opcFiltroCache = options.map((e) => e.toString()).toList();
        return _opcFiltroCache!;
      }
    }
    _opcFiltroCache = [];
    return _opcFiltroCache!;
  }

  /// Método para actualizar el objeto de paginación - optimizado
  void actualizarPaginacion(Paginacion nuevaPaginacion) {
    final bool cambio =
        _paginacion.currentPage != nuevaPaginacion.currentPage ||
            _paginacion.totalItems != nuevaPaginacion.totalItems ||
            _paginacion.totalPages != nuevaPaginacion.totalPages;

    _paginacion = nuevaPaginacion;

    if (cambio) {
      notifyListeners();
    }
  }

  /// Método para actualizar los metadatos - optimizado
  void actualizarMetadata(Map<String, dynamic>? nuevoMetadata) {
    // Si los nuevos metadatos son iguales a los actuales, no hacemos nada
    if (_metadata == nuevoMetadata) {
      return;
    }

    // Limpiar caché al cambiar metadatos
    _opcSortByCache = null;
    _opcFiltroCache = null;

    _metadata = nuevoMetadata;
    notifyListeners();
  }

  /// Método para actualizar la paginación desde un ResultadoPaginado - optimizado
  void actualizarDesdePaginado<T>(ResultadoPaginado<T> resultado) {
    final nuevaPaginacion = Paginacion(
      totalItems: resultado.total,
      totalPages: resultado.totalPages,
      currentPage: resultado.page,
      hasNext: resultado.hasNextPage,
      hasPrev: resultado.hasPrevPage,
    );

    // Detectar cambios en paginación
    final bool cambioPaginacion =
        _paginacion.currentPage != nuevaPaginacion.currentPage ||
            _paginacion.totalItems != nuevaPaginacion.totalItems ||
            _paginacion.totalPages != nuevaPaginacion.totalPages;

    // Detectar cambio en tamaño de página
    final bool cambioTamano = _itemsPerPage != resultado.pageSize;

    _paginacion = nuevaPaginacion;
    _itemsPerPage = resultado.pageSize;

    // Actualizar metadatos (la función ya verifica si hay cambios)
    actualizarMetadata(resultado.metadata);

    // Notificar solo si hay cambios en paginación o tamaño
    if (cambioPaginacion || cambioTamano) {
      notifyListeners();
    }
  }

  /// Método para actualizar la paginación desde un PaginatedResponse - optimizado
  void actualizarDesdeResponse<T>(PaginatedResponse<T> response) {
    final bool cambioPaginacion =
        _paginacion.currentPage != response.paginacion.currentPage ||
            _paginacion.totalItems != response.paginacion.totalItems ||
            _paginacion.totalPages != response.paginacion.totalPages;

    _paginacion = response.paginacion;

    // Limpiar caché al cambiar metadatos
    if (_metadata != response.metadata) {
      _opcSortByCache = null;
      _opcFiltroCache = null;
      _metadata = response.metadata;
    }

    if (cambioPaginacion || _metadata != response.metadata) {
      notifyListeners();
    }
  }

  /// Método para actualizar la paginación desde un JSON del servidor - optimizado
  void actualizarDesdeJson(Map<String, dynamic> json) {
    if (json.containsKey('pagination')) {
      final paginacionData = json['pagination'] as Map<String, dynamic>;

      final totalItems = paginacionData['totalItems'] as int? ?? 0;
      final totalPages = paginacionData['totalPages'] as int? ?? 1;
      final currentPage = paginacionData['currentPage'] as int? ?? 1;
      final hasNext = paginacionData['hasNext'] as bool? ?? false;
      final hasPrev = paginacionData['hasPrev'] as bool? ?? false;

      final nuevaPaginacion = Paginacion(
        totalItems: totalItems,
        totalPages: totalPages,
        currentPage: currentPage,
        hasNext: hasNext,
        hasPrev: hasPrev,
      );

      final bool cambioPaginacion =
          _paginacion.currentPage != nuevaPaginacion.currentPage ||
              _paginacion.totalItems != nuevaPaginacion.totalItems ||
              _paginacion.totalPages != nuevaPaginacion.totalPages;

      _paginacion = nuevaPaginacion;

      // Actualizar metadatos si existen
      if (json.containsKey('metadata')) {
        final nuevoMetadata = json['metadata'] as Map<String, dynamic>?;

        // Limpiar caché si cambian los metadatos
        if (_metadata != nuevoMetadata) {
          _opcSortByCache = null;
          _opcFiltroCache = null;
          _metadata = nuevoMetadata;
        }
      }

      if (cambioPaginacion || json.containsKey('metadata')) {
        notifyListeners();
      }
    }
  }

  /// Método para cambiar de página - optimizado
  void cambiarPagina(int nuevaPagina) {
    if (nuevaPagina < 1 ||
        nuevaPagina > _paginacion.totalPages ||
        nuevaPagina == _paginacion.currentPage) {
      return;
    }

    final nuevaPaginacion = Paginacion(
      totalItems: _paginacion.totalItems,
      totalPages: _paginacion.totalPages,
      currentPage: nuevaPagina,
      hasNext: nuevaPagina < _paginacion.totalPages,
      hasPrev: nuevaPagina > 1,
    );

    _paginacion = nuevaPaginacion;
    notifyListeners();
  }

  /// Ir a la primera página
  void irAPrimeraPagina() {
    if (_paginacion.currentPage == 1) {
      return;
    }
    cambiarPagina(1);
  }

  /// Ir a la última página
  void irAUltimaPagina() {
    if (_paginacion.currentPage == _paginacion.totalPages) {
      return;
    }
    cambiarPagina(_paginacion.totalPages);
  }

  /// Ir a la página siguiente
  void irAPaginaSiguiente() {
    if (_paginacion.hasNext) {
      cambiarPagina(_paginacion.currentPage + 1);
    }
  }

  /// Ir a la página anterior
  void irAPaginaAnterior() {
    if (_paginacion.hasPrev) {
      cambiarPagina(_paginacion.currentPage - 1);
    }
  }

  /// Cambiar el número de elementos por página - optimizado
  void cambiarItemsPorPagina(int nuevoItemsPerPage) {
    if (nuevoItemsPerPage < 1 || nuevoItemsPerPage == _itemsPerPage) {
      return;
    }

    nuevoItemsPerPage = nuevoItemsPerPage.clamp(1, maximoPorPagina);
    _itemsPerPage = nuevoItemsPerPage;

    // Restaurar a la primera página al cambiar el tamaño
    if (_paginacion.currentPage > 1) {
      irAPrimeraPagina();
    } else {
      // Si ya estamos en la primera página, solo notificamos
      notifyListeners();
    }
  }

  /// Establecer el orden de los resultados - optimizado
  void cambiarOrden(String nuevoOrden) {
    if (nuevoOrden != 'asc' && nuevoOrden != 'desc' || nuevoOrden == _orden) {
      return;
    }

    _orden = nuevoOrden;
    notifyListeners();
  }

  /// Establecer el campo por el cual ordenar - optimizado
  void cambiarOrdenarPor(String? nuevoOrdenarPor) {
    if (nuevoOrdenarPor == _ordenarPor) {
      return;
    }

    _ordenarPor = nuevoOrdenarPor;
    notifyListeners();
  }

  /// Establecer el término de búsqueda - optimizado
  void cambiarBusqueda(String nuevaBusqueda) {
    if (nuevaBusqueda == _busqueda) {
      return;
    }

    _busqueda = nuevaBusqueda;

    // Solo reiniciar página si realmente hay cambio
    if (_paginacion.currentPage != 1) {
      irAPrimeraPagina();
    } else {
      notifyListeners();
    }
  }

  /// Establecer filtro y su valor - optimizado
  void aplicarFiltro({
    required String filtro,
    required valor,
    String tipoFiltro = 'eq',
  }) {
    // Comparar todos los parámetros de filtro
    if (filtro == _filtro &&
        valor == _valorFiltro &&
        tipoFiltro == _tipoFiltro) {
      return;
    }

    _filtro = filtro;
    _valorFiltro = valor;
    _tipoFiltro = tipoFiltro;

    // Solo reiniciar página si realmente hay cambio
    if (_paginacion.currentPage != 1) {
      irAPrimeraPagina();
    } else {
      notifyListeners();
    }
  }

  /// Limpiar todos los filtros - optimizado
  void limpiarFiltros() {
    // Detectar si hay algún filtro activo
    if (_filtro.isEmpty &&
        _valorFiltro == null &&
        _tipoFiltro == 'eq' &&
        _busqueda.isEmpty &&
        _paginacion.currentPage == 1) {
      return;
    }

    _filtro = '';
    _valorFiltro = null;
    _tipoFiltro = 'eq';
    _busqueda = '';

    // Solo reiniciar página si no estamos en la primera
    if (_paginacion.currentPage != 1) {
      irAPrimeraPagina();
    } else {
      notifyListeners();
    }
  }

  /// Calcular los parámetros de consulta para una petición HTTP - optimizado
  Map<String, dynamic> obtenerParametrosConsulta({
    Map<String, dynamic>? filtrosAdicionales,
  }) {
    final Map<String, dynamic> parametros = {
      'page': _paginacion.currentPage,
      'page_size': _itemsPerPage,
    };

    // Agregar parámetros de ordenación si existen
    if (_ordenarPor != null && _ordenarPor!.isNotEmpty) {
      parametros['sort_by'] = _ordenarPor;
      parametros['order'] = _orden;
    }

    // Agregar búsqueda si existe - solo si no está vacía
    if (_busqueda.isNotEmpty) {
      parametros['search'] = _busqueda;
    }

    // Agregar filtro si existe - solo si no está vacío
    if (_filtro.isNotEmpty) {
      parametros['filter'] = _filtro;
      parametros['filter_value'] = _valorFiltro;
      parametros['filter_type'] = _tipoFiltro;
    }

    // Agregar filtros adicionales si existen - solo si no están vacíos
    if (filtrosAdicionales != null && filtrosAdicionales.isNotEmpty) {
      parametros.addAll(filtrosAdicionales);
    }

    return parametros;
  }

  /// Reiniciar la paginación a valores por defecto - optimizado
  void reiniciar() {
    // Guardar los valores originales para comparar
    final paginacionOriginal = _paginacion;
    final itemsPerPageOriginal = _itemsPerPage;
    final ordenOriginal = _orden;
    final ordenarPorOriginal = _ordenarPor;
    final busquedaOriginal = _busqueda;
    final filtroOriginal = _filtro;
    final valorFiltroOriginal = _valorFiltro;
    final tipoFiltroOriginal = _tipoFiltro;
    final metadataOriginal = _metadata;

    // Restaurar a valores por defecto
    _paginacion = Paginacion(
      totalItems: 0,
      totalPages: 1,
      currentPage: 1,
      hasNext: false,
      hasPrev: false,
    );
    _itemsPerPage = 50; // Valor por defecto del servidor
    _orden = 'desc';
    _ordenarPor = null;
    _busqueda = '';
    _filtro = '';
    _valorFiltro = null;
    _tipoFiltro = 'eq';
    _metadata = null;

    // Limpiar caché
    _opcSortByCache = null;
    _opcFiltroCache = null;

    // Solo notificar si hubo cambios
    if (_paginacion.currentPage != paginacionOriginal.currentPage ||
        _paginacion.totalItems != paginacionOriginal.totalItems ||
        _itemsPerPage != itemsPerPageOriginal ||
        _orden != ordenOriginal ||
        _ordenarPor != ordenarPorOriginal ||
        _busqueda != busquedaOriginal ||
        _filtro != filtroOriginal ||
        _valorFiltro != valorFiltroOriginal ||
        _tipoFiltro != tipoFiltroOriginal ||
        _metadata != metadataOriginal) {
      notifyListeners();
    }
  }

  /// Constructor que permite crear un provider a partir de una paginación existente
  static PaginacionProvider fromPaginacion(paginacion,
      {Map<String, dynamic>? metadata}) {
    final provider = PaginacionProvider();
    if (paginacion != null) {
      provider
        .._paginacion = Paginacion(
          totalItems: paginacion.totalItems ?? 0,
          totalPages: paginacion.totalPages ?? 1,
          currentPage: paginacion.currentPage ?? 1,
          hasNext: (paginacion.currentPage ?? 1) < (paginacion.totalPages ?? 1),
          hasPrev: (paginacion.currentPage ?? 1) > 1,
        )
        .._metadata = metadata;
    }
    return provider;
  }

  /// Crea un provider desde un PaginatedResponse
  static PaginacionProvider fromResponse<T>(PaginatedResponse<T> response) {
    final provider = PaginacionProvider();
    provider._paginacion = response.paginacion;
    provider._metadata = response.metadata;
    return provider;
  }

  /// Crea un provider desde una respuesta API completa
  static PaginacionProvider fromApiResponse(Map<String, dynamic> response) {
    final provider = PaginacionProvider();

    if (response.containsKey('pagination')) {
      final paginacion =
          Paginacion.fromJson(response['pagination'] as Map<String, dynamic>);
      provider._paginacion = paginacion;
    }

    if (response.containsKey('metadata')) {
      provider._metadata = response['metadata'] as Map<String, dynamic>?;
    }

    return provider;
  }
}
