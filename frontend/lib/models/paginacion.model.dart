class Paginacion {
  final int totalItems;
  final int totalPages;
  final int currentPage;
  final bool hasNext;
  final bool hasPrev;

  Paginacion({
    required this.totalItems,
    required this.totalPages,
    required this.currentPage,
    required this.hasNext,
    required this.hasPrev,
  });

  factory Paginacion.fromJson(Map<String, dynamic> json) {
    return Paginacion(
      totalItems: json['totalItems'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 1,
      currentPage: json['currentPage'] as int? ?? 1,
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrev: json['hasPrev'] as bool? ?? false,
    );
  }

  /// Crea una Paginación desde la respuesta completa de la API
  factory Paginacion.fromApiResponse(Map<String, dynamic> response) {
    if (response.containsKey('pagination')) {
      return Paginacion.fromJson(
          response['pagination'] as Map<String, dynamic>);
    }

    return Paginacion(
      totalItems: 0,
      totalPages: 1,
      currentPage: 1,
      hasNext: false,
      hasPrev: false,
    );
  }

  // Método para verificar si hay más páginas
  bool get hasNextPage => hasNext;

  // Método para verificar si hay páginas anteriores
  bool get hasPrevPage => hasPrev;

  // Método para obtener el número de la siguiente página
  int? get nextPage => hasNext ? currentPage + 1 : null;

  // Método para obtener el número de la página anterior
  int? get prevPage => hasPrev ? currentPage - 1 : null;

  // Método para generar un rango de páginas visible (útil para UI)
  List<int> getVisiblePages({int maxVisiblePages = 5}) {
    if (totalPages <= maxVisiblePages) {
      return List.generate(totalPages, (int i) => i + 1);
    }

    // Calcular el rango de páginas visibles
    int start = currentPage - (maxVisiblePages ~/ 2);
    if (start < 1) {
      start = 1;
    }
    int end = start + maxVisiblePages - 1;
    if (end > totalPages) {
      end = totalPages;
      start = end - maxVisiblePages + 1;
      if (start < 1) {
        start = 1;
      }
    }

    return List.generate(end - start + 1, (int i) => start + i);
  }

  /// Convierte esta paginación a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'totalItems': totalItems,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'hasNext': hasNext,
      'hasPrev': hasPrev,
    };
  }

  /// Crea una copia de esta paginación con modificaciones
  Paginacion copyWith({
    int? totalItems,
    int? totalPages,
    int? currentPage,
    bool? hasNext,
    bool? hasPrev,
  }) {
    return Paginacion(
      totalItems: totalItems ?? this.totalItems,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      hasNext: hasNext ?? this.hasNext,
      hasPrev: hasPrev ?? this.hasPrev,
    );
  }
}

class PaginatedResponse<T> {
  final List<T> items;
  final Paginacion paginacion;
  final Map<String, dynamic>? metadata;

  PaginatedResponse({
    required this.items,
    required this.paginacion,
    this.metadata,
  });

  /// Crea una respuesta paginada desde la respuesta completa de la API
  /// Requiere un conversor para transformar los items JSON a objetos de tipo T
  static PaginatedResponse<T> fromApiResponse<T>(
    Map<String, dynamic> response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final List<dynamic> rawItems = response['data'] as List<dynamic>? ?? [];
    final List<T> items =
        rawItems.map((item) => fromJson(item as Map<String, dynamic>)).toList();

    final paginacion = Paginacion.fromApiResponse(response);
    final metadata = response['metadata'] as Map<String, dynamic>?;

    return PaginatedResponse<T>(
      items: items,
      paginacion: paginacion,
      metadata: metadata,
    );
  }

  /// Obtiene opciones de ordenación desde los metadatos si existen
  List<String> get sortByOptions {
    if (metadata != null && metadata!.containsKey('sortByOptions')) {
      final options = metadata!['sortByOptions'] as List<dynamic>?;
      if (options != null) {
        return options.map((e) => e.toString()).toList();
      }
    }
    return [];
  }

  /// Obtiene opciones de filtros desde los metadatos si existen
  List<String> get filterOptions {
    if (metadata != null && metadata!.containsKey('filterOptions')) {
      final options = metadata!['filterOptions'] as List<dynamic>?;
      if (options != null) {
        return options.map((e) => e.toString()).toList();
      }
    }
    return [];
  }
}

/// Clase que representa un resultado paginado de la API
class ResultadoPaginado<T> {
  final List<T> items;
  final int total;
  final int page;
  final int totalPages;
  final int pageSize;
  final Map<String, dynamic>? metadata;

  ResultadoPaginado({
    required this.items,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.pageSize,
    this.metadata,
  });

  /// Verifica si hay página siguiente
  bool get hasNextPage => page < totalPages;

  /// Verifica si hay página anterior
  bool get hasPrevPage => page > 1;

  /// Obtiene el número de la siguiente página, o null si no hay
  int? get nextPage => hasNextPage ? page + 1 : null;

  /// Obtiene el número de la página anterior, o null si no hay
  int? get prevPage => hasPrevPage ? page - 1 : null;

  /// Convierte este resultado paginado a un objeto PaginatedResponse
  PaginatedResponse<T> toPaginatedResponse() {
    return PaginatedResponse<T>(
      items: items,
      paginacion: Paginacion(
        totalItems: total,
        totalPages: totalPages,
        currentPage: page,
        hasNext: hasNextPage,
        hasPrev: hasPrevPage,
      ),
      metadata: metadata,
    );
  }
}
