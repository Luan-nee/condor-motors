import 'package:condorsmotors/api/index.api.dart' as api_index;
import 'package:condorsmotors/api/protected/clientes.api.dart';
import 'package:condorsmotors/models/cliente.model.dart';

/// Repositorio para gestionar la información de los clientes.
class ClienteRepository {
  final ClientesApi _api;

  ClienteRepository(this._api);

  static final ClienteRepository instance =
      ClienteRepository(api_index.api.clientes);

  /// Busca datos de un cliente por su número de documento.
  Future<Map<String, dynamic>?> buscarClientePorDoc(String numeroDocumento) async {
    final datos = await _api.buscarClienteExternoPorDoc(numeroDocumento);
    if (datos == null) {
      return null;
    }
    return {
      'tipoDocumentoId': datos['tipoDocumentoId'] ?? 2, // Por defecto DNI
      'numeroDocumento': datos['numeroDocumento'],
      'denominacion': datos['denominacion'],
      'direccion': datos['direccion'] ?? '',
    };
  }

  /// Crea un nuevo cliente.
  Future<Cliente> crearCliente(Map<String, dynamic> clienteData) =>
      _api.createCliente(clienteData);

  /// Obtiene un cliente por su ID.
  Future<Cliente> obtenerCliente(String clienteId) =>
      _api.getCliente(clienteId);

  /// Obtiene un cliente por su número de documento.
  Future<Cliente?> obtenerClientePorDoc(String numeroDocumento) =>
      _api.getClienteByDoc(numeroDocumento);

  /// Obtiene la lista de clientes.
  Future<List<Cliente>> getClientes({int? pageSize, String? sortBy}) =>
      _api.getClientes(pageSize: pageSize, sortBy: sortBy);
}
