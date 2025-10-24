import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/models/cliente.model.dart';
import 'package:flutter/foundation.dart';

class ClienteRepository {
  final ClientesApi _api;

  ClienteRepository(this._api);

  static final ClienteRepository instance = ClienteRepository(api.clientes);

  /// Busca datos de un cliente por su número de documento
  Future<Map<String, dynamic>?> buscarClientePorDoc(
      String numeroDocumento) async {
    try {
      debugPrint('Buscando cliente con documento: $numeroDocumento');
      final datos = await _api.buscarClienteExternoPorDoc(numeroDocumento);

      if (datos != null) {
        debugPrint('Datos encontrados para documento $numeroDocumento');
        return {
          'tipoDocumentoId':
              datos['tipoDocumentoId'] ?? 2, // Por defecto DNI si no viene
          'numeroDocumento': datos['numeroDocumento'],
          'denominacion': datos['denominacion'],
          'direccion': datos['direccion'] ?? '',
        };
      }

      return null;
    } catch (e) {
      debugPrint('Error al buscar cliente por documento: $e');
      rethrow;
    }
  }

  /// Crea un nuevo cliente
  Future<Cliente> crearCliente(Map<String, dynamic> clienteData) async {
    try {
      debugPrint('➕ Creando nuevo cliente: ${clienteData['denominacion']}');
      return await _api.createCliente(clienteData);
    } catch (e) {
      debugPrint('Error al crear cliente: $e');
      rethrow;
    }
  }

  /// Obtiene un cliente por su ID
  Future<Cliente> obtenerCliente(String clienteId) async {
    try {
      debugPrint('Obteniendo cliente con ID: $clienteId');
      return await _api.getCliente(clienteId);
    } catch (e) {
      debugPrint('Error al obtener cliente: $e');
      rethrow;
    }
  }

  /// Obtiene un cliente por su número de documento
  Future<Cliente?> obtenerClientePorDoc(String numeroDocumento) async {
    try {
      debugPrint('Obteniendo cliente con documento: $numeroDocumento');
      return await _api.getClienteByDoc(numeroDocumento);
    } catch (e) {
      debugPrint('Error al obtener cliente por documento: $e');
      rethrow;
    }
  }

  /// Obtiene la lista de clientes
  Future<List<Cliente>> getClientes({int? pageSize, String? sortBy}) {
    return _api.getClientes(pageSize: pageSize, sortBy: sortBy);
  }
}
