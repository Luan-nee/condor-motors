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
}

/// Clase que representa un resultado paginado de la API
class ResultadoPaginado<T> {
  final List<T> items;
  final int total;
  final int page;
  final int totalPages;
  final int pageSize;
  
  ResultadoPaginado({
    required this.items,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.pageSize,
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
    );
  }
} 