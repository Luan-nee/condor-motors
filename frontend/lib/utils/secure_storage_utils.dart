import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio utilitario para almacenamiento seguro de datos sensibles
class SecureStorageUtils {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Escribe un valor seguro
  static Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Lee un valor seguro
  static Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  /// Elimina un valor seguro
  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Elimina todos los valores seguros
  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
