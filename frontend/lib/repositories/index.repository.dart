// Exportación de los repositorios
// Este archivo facilita la importación desde módulos externos

export 'auth.repository.dart';
export 'categoria.repository.dart';
export 'color.repository.dart';
export 'empleado.repository.dart';
export 'estadistica.repository.dart';
export 'facturacion.repository.dart';
export 'marcas.repository.dart';
export 'producto.repository.dart';
export 'proforma.repository.dart';
export 'stock.repository.dart';
export 'sucursal.repository.dart';
export 'transferencia.repository.dart';
export 'venta.repository.dart';

/// Clase base para todos los repositorios
///
/// Define métodos comunes que todos los repositorios deben implementar
abstract class BaseRepository {
  /// Obtiene datos del usuario desde la API centralizada
  Future<Map<String, dynamic>?> getUserData();

  /// Obtiene el ID de la sucursal del usuario actual
  Future<String?> getCurrentSucursalId();
}

// export 'cliente.repository.dart';

// export 'documento.repository.dart';
