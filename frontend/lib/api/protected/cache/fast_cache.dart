import 'package:condorsmotors/utils/logger.dart';

/// Implementación de un sistema de caché en memoria con:
/// - Control de tamaño máximo
/// - Expiración basada en tiempo
/// - Invalidación por patrones
/// - Política LRU (Least Recently Used) para liberar espacio
class FastCache {
  final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};
  final int maxSize;
  final Duration stalePeriod;
  final Duration expirePeriod;

  /// Constructor de FastCache
  /// [maxSize] Tamaño máximo del caché (por defecto 100 entradas)
  /// [stalePeriod] Período después del cual los datos se consideran obsoletos (por defecto 5 minutos)
  /// [expirePeriod] Período después del cual los datos expiran y son eliminados (por defecto 30 minutos)
  FastCache({
    this.maxSize = 100,
    this.stalePeriod = const Duration(minutes: 5),
    this.expirePeriod = const Duration(minutes: 30),
  });

  /// Obtiene un valor del caché
  /// Retorna null si no existe o ha expirado
  T? get<T>(String key) {
    final _CacheEntry? entry = _cache[key];
    if (entry == null) {
      return null;
    }

    // Si ha expirado, eliminarlo y retornar null
    if (DateTime.now().difference(entry.timestamp) > expirePeriod) {
      _cache.remove(key);
      logCache('Entrada expirada eliminada: $key');
      return null;
    }

    // Actualizar la última vez que se accedió
    entry.lastAccessed = DateTime.now();
    return entry.data as T;
  }

  /// Verifica si una entrada del caché está obsoleta
  bool isStale(String key) {
    final _CacheEntry? entry = _cache[key];
    if (entry == null) {
      return true;
    }
    return DateTime.now().difference(entry.timestamp) > stalePeriod;
  }

  /// Guarda un valor en el caché
  void set<T>(String key, T data) {
    // Si alcanzamos el tamaño máximo, eliminar la entrada menos usada
    if (_cache.length >= maxSize && !_cache.containsKey(key)) {
      _removeOldest();
    }

    _cache[key] = _CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      lastAccessed: DateTime.now(),
    );
    
    logCache('Dato guardado en caché: $key');
  }

  /// Invalida una entrada específica del caché
  void invalidate(String key) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
      logCache('Entrada invalidada: $key');
    }
  }

  /// Invalida todas las entradas que coincidan con un patrón
  void invalidateByPattern(String pattern) {
    final int initialSize = _cache.length;
    _cache.removeWhere((String key, _) => key.startsWith(pattern));
    final int removed = initialSize - _cache.length;
    
    if (removed > 0) {
      logCache('$removed entradas invalidadas por patrón: $pattern');
    }
  }

  /// Limpia completamente el caché
  void clear() {
    final int initialSize = _cache.length;
    _cache.clear();
    logCache('Caché completamente limpiado. Entradas eliminadas: $initialSize');
  }

  /// Elimina la entrada menos usada recientemente (LRU)
  void _removeOldest() {
    if (_cache.isEmpty) {
      return;
    }

    String? oldestKey;
    DateTime? oldestAccess;

    for (MapEntry<String, _CacheEntry> entry in _cache.entries) {
      if (oldestAccess == null || entry.value.lastAccessed.isBefore(oldestAccess)) {
        oldestAccess = entry.value.lastAccessed;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _cache.remove(oldestKey);
      logCache('Eliminada entrada más antigua del caché: $oldestKey');
    }
  }
  
  /// Devuelve el número de entradas en el caché
  int get size => _cache.length;
  
  /// Devuelve todas las claves en el caché
  List<String> get keys => _cache.keys.toList();
}

/// Clase interna para almacenar entradas en el caché
class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  DateTime lastAccessed;

  _CacheEntry({
    required this.data,
    required this.timestamp,
    required this.lastAccessed,
  });
} 