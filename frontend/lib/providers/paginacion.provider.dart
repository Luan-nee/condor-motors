import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/utils/logger.dart';
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

  /// Opciones de tamaño de página comunes
  static const List<int> opcionesTamanoPagina = [10, 50, 100, 200];

  /// Opciones de orden
  static const Map<String, String> opcionesOrden = {
    'asc': 'Ascendente',
    'desc': 'Descendente',
  };

  /// Opciones de tipos de filtro
  static const Map<String, String> opcionesTipoFiltro = {
    'eq': 'Igual a',
    'gt': 'Mayor que',
    'lt': 'Menor que',
    'after': 'Después de',
    'before': 'Antes de',
  };

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

  /// Obtiene opciones de ordenación desde los metadatos
  List<String> get opcionesSortBy {
    if (_metadata != null && _metadata!.containsKey('sortByOptions')) {
      final dynamic options = _metadata!['sortByOptions'];
      if (options is List) {
        logDebug(
            'PaginacionProvider: Opciones SortBy encontradas: ${options.length}');
        return options.map((e) => e.toString()).toList();
      }
    }
    return [];
  }

  /// Obtiene opciones de filtros desde los metadatos
  List<String> get opcionesFiltro {
    if (_metadata != null && _metadata!.containsKey('filterOptions')) {
      final dynamic options = _metadata!['filterOptions'];
      if (options is List) {
        logDebug(
            'PaginacionProvider: Opciones de filtro encontradas: ${options.length}');
        return options.map((e) => e.toString()).toList();
      }
    }
    return [];
  }

  /// Método para actualizar el objeto de paginación
  void actualizarPaginacion(Paginacion nuevaPaginacion) {
    _paginacion = nuevaPaginacion;
    logInfo(
        'PaginacionProvider: Paginación actualizada - Total: ${nuevaPaginacion.totalItems}, Página: ${nuevaPaginacion.currentPage}/${nuevaPaginacion.totalPages}');
    notifyListeners();
  }

  /// Método para actualizar los metadatos
  void actualizarMetadata(Map<String, dynamic>? nuevoMetadata) {
    _metadata = nuevoMetadata;
    if (nuevoMetadata != null) {
      logInfo(
          'PaginacionProvider: Metadatos actualizados - Keys: ${nuevoMetadata.keys.join(", ")}');

      if (nuevoMetadata.containsKey('sortByOptions')) {
        final sortByOptions = nuevoMetadata['sortByOptions'];
        logDebug('PaginacionProvider: sortByOptions: $sortByOptions');
      }

      if (nuevoMetadata.containsKey('filterOptions')) {
        final filterOptions = nuevoMetadata['filterOptions'];
        logDebug('PaginacionProvider: filterOptions: $filterOptions');
      }
    } else {
      logInfo('PaginacionProvider: Metadatos actualizados a null');
    }
    notifyListeners();
  }

  /// Método para actualizar la paginación desde un ResultadoPaginado
  void actualizarDesdePaginado<T>(ResultadoPaginado<T> resultado) {
    logInfo(
        'PaginacionProvider: Actualizando desde ResultadoPaginado - Items: ${resultado.items.length}, Total: ${resultado.total}');
    actualizarPaginacion(Paginacion(
      totalItems: resultado.total,
      totalPages: resultado.totalPages,
      currentPage: resultado.page,
      hasNext: resultado.hasNextPage,
      hasPrev: resultado.hasPrevPage,
    ));
    _itemsPerPage = resultado.pageSize;
    actualizarMetadata(resultado.metadata);
  }

  /// Método para actualizar la paginación desde un PaginatedResponse
  void actualizarDesdeResponse<T>(PaginatedResponse<T> response) {
    logInfo(
        'PaginacionProvider: Actualizando desde PaginatedResponse - Items: ${response.items.length}, TotalItems: ${response.paginacion.totalItems}');
    actualizarPaginacion(response.paginacion);
    actualizarMetadata(response.metadata);
  }

  /// Método para actualizar la paginación desde un JSON del servidor
  void actualizarDesdeJson(Map<String, dynamic> json) {
    logInfo(
        'PaginacionProvider: Actualizando desde JSON - Estructura: ${json.keys.join(", ")}');

    if (json.containsKey('pagination')) {
      final paginacionData = json['pagination'] as Map<String, dynamic>;
      logDebug(
          'PaginacionProvider: Datos de paginación recibidos: $paginacionData');

      final totalItems = paginacionData['totalItems'] as int? ?? 0;
      final totalPages = paginacionData['totalPages'] as int? ?? 1;
      final currentPage = paginacionData['currentPage'] as int? ?? 1;
      final hasNext = paginacionData['hasNext'] as bool? ?? false;
      final hasPrev = paginacionData['hasPrev'] as bool? ?? false;

      actualizarPaginacion(Paginacion(
        totalItems: totalItems,
        totalPages: totalPages,
        currentPage: currentPage,
        hasNext: hasNext,
        hasPrev: hasPrev,
      ));

      if (json.containsKey('metadata')) {
        logDebug('PaginacionProvider: Metadatos encontrados en la respuesta');
        actualizarMetadata(json['metadata'] as Map<String, dynamic>?);
      } else {
        logDebug(
            'PaginacionProvider: No se encontraron metadatos en la respuesta');
      }
    } else {
      logWarning(
          'PaginacionProvider: No se encontró información de paginación en el JSON');
    }
  }

  /// Método para cambiar de página
  void cambiarPagina(int nuevaPagina) {
    if (nuevaPagina < 1 || nuevaPagina > _paginacion.totalPages) {
      logWarning(
          'PaginacionProvider: Intento de cambiar a página fuera de rango - Página: $nuevaPagina, TotalPages: ${_paginacion.totalPages}');
      return;
    }

    logInfo(
        'PaginacionProvider: Cambiando de página ${_paginacion.currentPage} a $nuevaPagina');
    final nuevaPaginacion = Paginacion(
      totalItems: _paginacion.totalItems,
      totalPages: _paginacion.totalPages,
      currentPage: nuevaPagina,
      hasNext: nuevaPagina < _paginacion.totalPages,
      hasPrev: nuevaPagina > 1,
    );

    actualizarPaginacion(nuevaPaginacion);
  }

  /// Ir a la primera página
  void irAPrimeraPagina() {
    logDebug('PaginacionProvider: Ir a primera página');
    cambiarPagina(1);
  }

  /// Ir a la última página
  void irAUltimaPagina() {
    logDebug(
        'PaginacionProvider: Ir a última página: ${_paginacion.totalPages}');
    cambiarPagina(_paginacion.totalPages);
  }

  /// Ir a la página siguiente
  void irAPaginaSiguiente() {
    if (_paginacion.hasNext) {
      logDebug(
          'PaginacionProvider: Ir a página siguiente: ${_paginacion.currentPage + 1}');
      cambiarPagina(_paginacion.currentPage + 1);
    } else {
      logDebug('PaginacionProvider: No hay página siguiente disponible');
    }
  }

  /// Ir a la página anterior
  void irAPaginaAnterior() {
    if (_paginacion.hasPrev) {
      logDebug(
          'PaginacionProvider: Ir a página anterior: ${_paginacion.currentPage - 1}');
      cambiarPagina(_paginacion.currentPage - 1);
    } else {
      logDebug('PaginacionProvider: No hay página anterior disponible');
    }
  }

  /// Cambiar el número de elementos por página
  void cambiarItemsPorPagina(int nuevoItemsPerPage) {
    if (nuevoItemsPerPage < 1) {
      logWarning(
          'PaginacionProvider: Valor inválido para items por página: $nuevoItemsPerPage');
      return;
    }

    if (nuevoItemsPerPage > maximoPorPagina) {
      logWarning(
          'PaginacionProvider: Valor de items por página excede el máximo, ajustando a $maximoPorPagina');
      nuevoItemsPerPage = maximoPorPagina;
    }

    logInfo(
        'PaginacionProvider: Cambiando items por página de $_itemsPerPage a $nuevoItemsPerPage');
    _itemsPerPage = nuevoItemsPerPage;

    // Restaurar a la primera página al cambiar el tamaño
    if (_paginacion.currentPage > 1) {
      irAPrimeraPagina();
    } else {
      // Si ya estamos en la primera página, solo notificamos
      notifyListeners();
    }
  }

  /// Establecer el orden de los resultados
  void cambiarOrden(String nuevoOrden) {
    if (nuevoOrden != 'asc' && nuevoOrden != 'desc') {
      logWarning('PaginacionProvider: Valor de orden inválido: $nuevoOrden');
      return;
    }

    logInfo('PaginacionProvider: Cambiando orden de $_orden a $nuevoOrden');
    _orden = nuevoOrden;
    notifyListeners();
  }

  /// Establecer el campo por el cual ordenar
  void cambiarOrdenarPor(String? nuevoOrdenarPor) {
    logInfo(
        'PaginacionProvider: Cambiando ordenarPor de $_ordenarPor a $nuevoOrdenarPor');
    _ordenarPor = nuevoOrdenarPor;
    notifyListeners();
  }

  /// Establecer el término de búsqueda
  void cambiarBusqueda(String nuevaBusqueda) {
    logInfo('PaginacionProvider: Cambiando búsqueda a "$nuevaBusqueda"');
    _busqueda = nuevaBusqueda;
    irAPrimeraPagina(); // Reiniciar a primera página al cambiar búsqueda
  }

  /// Establecer filtro y su valor
  void aplicarFiltro({
    required String filtro,
    required dynamic valor,
    String tipoFiltro = 'eq',
  }) {
    logInfo(
        'PaginacionProvider: Aplicando filtro - Campo: $filtro, Valor: $valor, Tipo: $tipoFiltro');
    _filtro = filtro;
    _valorFiltro = valor;
    _tipoFiltro = tipoFiltro;
    irAPrimeraPagina(); // Reiniciar a primera página al aplicar filtro
  }

  /// Limpiar todos los filtros
  void limpiarFiltros() {
    logInfo('PaginacionProvider: Limpiando todos los filtros');
    _filtro = '';
    _valorFiltro = null;
    _tipoFiltro = 'eq';
    _busqueda = '';
    irAPrimeraPagina(); // Reiniciar a primera página al limpiar filtros
  }

  /// Calcular los parámetros de consulta para una petición HTTP según el formato del servidor
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

    // Agregar búsqueda si existe
    if (_busqueda.isNotEmpty) {
      parametros['search'] = _busqueda;
    }

    // Agregar filtro si existe
    if (_filtro.isNotEmpty) {
      parametros['filter'] = _filtro;
      parametros['filter_value'] = _valorFiltro;
      parametros['filter_type'] = _tipoFiltro;
    }

    // Agregar filtros adicionales si existen
    if (filtrosAdicionales != null && filtrosAdicionales.isNotEmpty) {
      parametros.addAll(filtrosAdicionales);
    }

    logDebug(
        'PaginacionProvider: Parámetros de consulta generados: $parametros');
    return parametros;
  }

  /// Reiniciar la paginación a valores por defecto
  void reiniciar() {
    logInfo('PaginacionProvider: Reiniciando a valores por defecto');
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
    notifyListeners();
  }

  /// Constructor que permite crear un provider a partir de una paginación existente
  static PaginacionProvider fromPaginacion(paginacion,
      {Map<String, dynamic>? metadata}) {
    logInfo('PaginacionProvider: Creando desde objeto paginación');
    final provider = PaginacionProvider();
    if (paginacion != null) {
      provider._paginacion = Paginacion(
        totalItems: paginacion.totalItems ?? 0,
        totalPages: paginacion.totalPages ?? 1,
        currentPage: paginacion.currentPage ?? 1,
        hasNext: (paginacion.currentPage ?? 1) < (paginacion.totalPages ?? 1),
        hasPrev: (paginacion.currentPage ?? 1) > 1,
      );
      provider._metadata = metadata;
      logDebug('PaginacionProvider: Inicializado con paginación y metadata');
    } else {
      logWarning('PaginacionProvider: Se recibió un objeto paginación nulo');
    }
    return provider;
  }

  /// Crea un provider desde un PaginatedResponse
  static PaginacionProvider fromResponse<T>(PaginatedResponse<T> response) {
    logInfo(
        'PaginacionProvider: Creando desde PaginatedResponse con ${response.items.length} items');
    final provider = PaginacionProvider();
    provider.actualizarPaginacion(response.paginacion);
    provider.actualizarMetadata(response.metadata);
    return provider;
  }

  /// Crea un provider desde una respuesta API completa
  static PaginacionProvider fromApiResponse(Map<String, dynamic> response) {
    logInfo(
        'PaginacionProvider: Creando desde respuesta API - Estructura: ${response.keys.join(", ")}');
    final provider = PaginacionProvider();

    if (response.containsKey('pagination')) {
      final paginacion =
          Paginacion.fromJson(response['pagination'] as Map<String, dynamic>);
      provider.actualizarPaginacion(paginacion);
    } else {
      logWarning(
          'PaginacionProvider: No se encontró información de paginación en la respuesta');
    }

    if (response.containsKey('metadata')) {
      provider
          .actualizarMetadata(response['metadata'] as Map<String, dynamic>?);
    } else {
      logDebug(
          'PaginacionProvider: No se encontraron metadatos en la respuesta');
    }

    return provider;
  }
}
