import 'dart:math' as math;

import 'package:equatable/equatable.dart';

class Paginacion extends Equatable {
  final int totalItems;
  final int totalPages;
  final int currentPage;
  final bool hasNext;
  final bool hasPrev;
  final int? rangoInicio;
  final int? rangoFin;

  // Caché para cálculos costosos

  const Paginacion({
    required this.totalItems,
    required this.totalPages,
    required this.currentPage,
    required this.hasNext,
    required this.hasPrev,
    this.rangoInicio,
    this.rangoFin,
  });

  @override
  List<Object?> get props => [
        totalItems,
        totalPages,
        currentPage,
        hasNext,
        hasPrev,
        rangoInicio,
        rangoFin,
      ];

  factory Paginacion.fromJson(Map<String, dynamic> json) {
    return Paginacion(
      totalItems: json['totalItems'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 1,
      currentPage: json['currentPage'] as int? ?? 1,
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrev: json['hasPrev'] as bool? ?? false,
      rangoInicio: json['rangoInicio'] as int?,
      rangoFin: json['rangoFin'] as int?,
    );
  }

  /// Crea una Paginación desde la respuesta completa de la API
  factory Paginacion.fromApiResponse(Map<String, dynamic> response) {
    if (response.containsKey('pagination')) {
      return Paginacion.fromJson(
          response['pagination'] as Map<String, dynamic>);
    }

    return Paginacion.emptyPagination;
  }

  /// Crea una Paginación vacía para inicialización
  static const Paginacion emptyPagination = Paginacion(
    totalItems: 0,
    totalPages: 1,
    currentPage: 1,
    hasNext: false,
    hasPrev: false,
  );

  factory Paginacion.empty() => emptyPagination;

  /// Crea una paginación a partir de parámetros básicos, calculando automáticamente hasNext y hasPrev
  factory Paginacion.fromParams({
    required int totalItems,
    required int pageSize,
    required int currentPage,
  }) {
    if (pageSize <= 0) {
      throw ArgumentError.value(
          pageSize, 'pageSize', 'Debe ser mayor que cero');
    }

    final int totalPages = (totalItems / pageSize).ceil();
    final int safeTotalPages = totalPages > 0 ? totalPages : 1;
    final int safeCurrentPage =
        currentPage.clamp(1, math.max(1, safeTotalPages));

    return Paginacion(
      totalItems: totalItems,
      totalPages: safeTotalPages,
      currentPage: safeCurrentPage,
      hasNext: safeCurrentPage < safeTotalPages,
      hasPrev: safeCurrentPage > 1,
    );
  }

  // Getters directos para propiedades derivadas
  bool get hasNextPage => hasNext;
  bool get hasPrevPage => hasPrev;
  int? get nextPage => hasNext ? currentPage + 1 : null;
  int? get prevPage => hasPrev ? currentPage - 1 : null;
  bool get isFirstPage => currentPage == 1;
  bool get isLastPage => currentPage == totalPages;

  /// Calcula el índice del primer elemento de la página actual
  int getFirstItemIndex(int pageSize) =>
      math.max(0, (currentPage - 1) * pageSize);

  /// Calcula el índice del último elemento de la página actual
  int getLastItemIndex(int pageSize) {
    if (totalItems == 0) {
      return -1;
    }
    final int lastIndex = currentPage * pageSize - 1;
    return math.min(lastIndex, totalItems - 1);
  }

  /// Obtiene el número de elementos en la página actual
  int getItemCount(int pageSize) {
    if (totalItems == 0) {
      return 0;
    }
    if (isLastPage) {
      return totalItems - getFirstItemIndex(pageSize);
    }
    return pageSize;
  }

  /// Obtiene la información de resumen para mostrar en UI
  /// Ejemplo: "Mostrando 1-10 de 100 elementos"
  String getResumen(int pageSize) {
    if (totalItems == 0) {
      return "No hay elementos para mostrar";
    }

    final int inicio = getFirstItemIndex(pageSize) + 1;
    final int fin = math.min(getLastItemIndex(pageSize) + 1, totalItems);
    return "Mostrando $inicio-$fin de $totalItems elementos";
  }

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
      start = math.max(1, end - maxVisiblePages + 1);
    }

    return List.generate(end - start + 1, (int i) => start + i);
  }

  /// Convierte esta paginación a un mapa JSON
  Map<String, dynamic> toJson() => {
        'totalItems': totalItems,
        'totalPages': totalPages,
        'currentPage': currentPage,
        'hasNext': hasNext,
        'hasPrev': hasPrev,
        'rangoInicio': rangoInicio,
        'rangoFin': rangoFin,
      };

  /// Obtiene un resumen detallado de la paginación (útil para depuración)
  @override
  String toString() =>
      'Paginacion(page: $currentPage, total: $totalPages, items: $totalItems)';

  /// Crea una copia de esta paginación con modificaciones
  Paginacion copyWith({
    int? totalItems,
    int? totalPages,
    int? currentPage,
    bool? hasNext,
    bool? hasPrev,
    int? rangoInicio,
    int? rangoFin,
  }) {
    return Paginacion(
      totalItems: totalItems ?? this.totalItems,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      hasNext: hasNext ?? this.hasNext,
      hasPrev: hasPrev ?? this.hasPrev,
      rangoInicio: rangoInicio ?? this.rangoInicio,
      rangoFin: rangoFin ?? this.rangoFin,
    );
  }
}

/// Representa una colección de elementos con paginación y metadatos opcionales.
///
/// Proporciona funcionalidades para manejar fácilmente resultados paginados de la API,
/// incluyendo opciones de ordenación y filtrado a través de los metadatos.
class PaginatedResponse<T> extends Equatable {
  final List<T> items;
  final Paginacion paginacion;
  final Map<String, dynamic>? metadata;

  // Caché para opciones derivadas de metadatos

  const PaginatedResponse({
    required this.items,
    required this.paginacion,
    this.metadata,
  });

  @override
  List<Object?> get props => [items, paginacion, metadata];

  /// Crea una respuesta paginada desde la respuesta completa de la API
  /// Requiere un conversor para transformar los items JSON a objetos de tipo T
  static PaginatedResponse<T> fromApiResponse<T>(
    Map<String, dynamic> response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final List<dynamic> rawItems = response['data'] as List<dynamic>? ?? [];
    final List<T> items = rawItems
        .cast<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);

    final paginacion = Paginacion.fromApiResponse(response);
    final metadata = response['metadata'] as Map<String, dynamic>?;

    return PaginatedResponse<T>(
      items: items,
      paginacion: paginacion,
      metadata: metadata,
    );
  }

  /// Crea una respuesta paginada vacía
  static const PaginatedResponse<dynamic> emptyResponse = PaginatedResponse(
    items: [],
    paginacion: Paginacion.emptyPagination,
  );

  factory PaginatedResponse.empty() => PaginatedResponse<T>(
        items: const [],
        paginacion: Paginacion.emptyPagination,
      );

  /// Verifica si la respuesta está vacía (sin elementos)
  bool get isEmpty => items.isEmpty;

  /// Verifica si hay elementos en la respuesta
  bool get isNotEmpty => items.isNotEmpty;

  /// Obtiene el total de elementos en todas las páginas
  int get totalItems => paginacion.totalItems;

  /// Obtiene el número total de páginas
  int get totalPages => paginacion.totalPages;

  /// Obtiene la página actual
  int get currentPage => paginacion.currentPage;

  /// Verifica si hay una página siguiente
  bool get hasNextPage => paginacion.hasNext;

  /// Verifica si hay una página anterior
  bool get hasPrevPage => paginacion.hasPrev;

  /// Obtiene opciones de ordenación desde los metadatos si existen - con caché
  List<String> getSortByOptions() {
    if (metadata == null ||
        !metadata!.containsKey('sortByOptions') ||
        metadata!['sortByOptions'] is! List) {
      return <String>[];
    }
    return List<String>.from(metadata!['sortByOptions'] as List);
  }

  /// Obtiene opciones de filtros desde los metadatos si existen - con caché
  List<String> getFilterOptions() {
    if (metadata == null ||
        !metadata!.containsKey('filterOptions') ||
        metadata!['filterOptions'] is! List) {
      return <String>[];
    }
    return List<String>.from(metadata!['filterOptions'] as List);
  }

  /// Obtiene el valor de cualquier metadato por su clave
  dynamic getMetadata(String key) => metadata?[key];

  /// Crea una copia de esta respuesta con elementos modificados
  PaginatedResponse<T> copyWithItems(List<T> newItems) {
    return PaginatedResponse<T>(
      items: newItems,
      paginacion: paginacion,
      metadata: metadata,
    );
  }

  /// Crea una copia de esta respuesta con paginación modificada
  PaginatedResponse<T> copyWithPaginacion(Paginacion newPaginacion) {
    return PaginatedResponse<T>(
      items: items,
      paginacion: newPaginacion,
      metadata: metadata,
    );
  }

  /// Crea una copia de esta respuesta con metadatos modificados
  PaginatedResponse<T> copyWithMetadata(Map<String, dynamic> newMetadata) {
    return PaginatedResponse<T>(
      items: items,
      paginacion: paginacion,
      metadata: newMetadata,
    );
  }

  /// Aplica una función a cada elemento y devuelve una nueva respuesta con los resultados
  PaginatedResponse<R> map<R>(R Function(T) mapper) {
    return PaginatedResponse<R>(
      items: items.map(mapper).toList(growable: false),
      paginacion: paginacion,
      metadata: metadata,
    );
  }

  /// Aplica un filtro a los elementos y actualiza la paginación
  PaginatedResponse<T> where(bool Function(T) filtro, {int? pageSize}) {
    final filteredItems = items.where(filtro).toList();
    final newPageSize = pageSize ?? math.max(1, filteredItems.length);

    final newPaginacion = Paginacion.fromParams(
      totalItems: filteredItems.length,
      pageSize: newPageSize,
      currentPage: 1, // Reset a primera página al filtrar
    );

    return PaginatedResponse<T>(
      items: filteredItems,
      paginacion: newPaginacion,
      metadata: metadata,
    );
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

  const ResultadoPaginado({
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

  /// Crea una copia de este resultado con algunos campos modificados
  ResultadoPaginado<T> copyWith({
    List<T>? items,
    int? total,
    int? page,
    int? totalPages,
    int? pageSize,
    Map<String, dynamic>? metadata,
  }) {
    return ResultadoPaginado<T>(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      pageSize: pageSize ?? this.pageSize,
      metadata: metadata ?? this.metadata,
    );
  }
}
