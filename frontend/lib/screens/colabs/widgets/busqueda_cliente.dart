import 'package:condorsmotors/models/cliente.model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BusquedaClienteWidget extends StatefulWidget {
  final List<Cliente> clientes;
  final Function(Cliente) onClienteSeleccionado;
  final Function() onNuevoCliente;
  final bool isLoading;

  const BusquedaClienteWidget({
    super.key,
    required this.clientes,
    required this.onClienteSeleccionado,
    required this.onNuevoCliente,
    this.isLoading = false,
  });

  @override
  State<BusquedaClienteWidget> createState() => _BusquedaClienteWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Cliente>('clientes', clientes))
      ..add(ObjectFlagProperty<Function(Cliente)>.has('onClienteSeleccionado', onClienteSeleccionado))
      ..add(ObjectFlagProperty<Function()>.has('onNuevoCliente', onNuevoCliente))
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading));
  }
}

class _BusquedaClienteWidgetState extends State<BusquedaClienteWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Cliente> _clientesFiltrados = <Cliente>[];
  final bool _filtroFrecuentes = false;

  @override
  void initState() {
    super.initState();
    _filtrarClientes();
  }

  @override
  void didUpdateWidget(BusquedaClienteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clientes != widget.clientes) {
      _filtrarClientes();
    }
  }

  void _filtrarClientes() {
    final String filtroTexto = _searchController.text.toLowerCase();
    
    setState(() {
      _clientesFiltrados = widget.clientes.where((Cliente cliente) {
        // Filtrar por texto (nombre o documento)
        final bool coincideTexto = filtroTexto.isEmpty ||
            cliente.denominacion.toLowerCase().contains(filtroTexto) ||
            cliente.numeroDocumento.toLowerCase().contains(filtroTexto);
            
        // Aquí se aplicaría el filtro de clientes frecuentes si tuvieras esa información
        // Por ahora, lo dejamos como si todos fueran frecuentes cuando el filtro está activo
        final bool esFrecuente = !_filtroFrecuentes || true;
        
        return coincideTexto && esFrecuente;
      }).toList();
      
      // Ordenar por nombre
      _clientesFiltrados.sort((Cliente a, Cliente b) => a.denominacion.compareTo(b.denominacion));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // Barra de búsqueda con ícono
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar cliente por nombre o documento',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _filtrarClientes();
                    },
                  )
                : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (String value) => _filtrarClientes(),
            textInputAction: TextInputAction.search,
          ),
        ),
        
        // Filtros y botón de nuevo cliente
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: <Widget>[
              // Filtro de clientes frecuentes (comentado por ahora)
              /*
              Row(
                children: [
                  Checkbox(
                    value: _filtroFrecuentes,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _filtroFrecuentes = value;
                        });
                        _filtrarClientes();
                      }
                    },
                  ),
                  const Text('Frecuentes'),
                ],
              ),
              */
              const Spacer(),
              
              // Botón de nuevo cliente
              ElevatedButton.icon(
                onPressed: widget.onNuevoCliente,
                icon: const FaIcon(FontAwesomeIcons.userPlus, size: 14),
                label: const Text('Nuevo Cliente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Resultados de la búsqueda
        Expanded(
          child: widget.isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _clientesFiltrados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(
                            Icons.person_search,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No se encontraron clientes',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Intenta con otra búsqueda o crea un nuevo cliente',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: widget.onNuevoCliente,
                            icon: const FaIcon(FontAwesomeIcons.userPlus, size: 14),
                            label: const Text('Crear Cliente'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _clientesFiltrados.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Cliente cliente = _clientesFiltrados[index];
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          clipBehavior: Clip.antiAlias,
                          elevation: 2,
                          child: InkWell(
                            onTap: () => widget.onClienteSeleccionado(cliente),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: <Widget>[
                                  // Avatar del cliente
                                  CircleAvatar(
                                    backgroundColor: Colors.blue.withOpacity(0.1),
                                    child: Text(
                                      cliente.denominacion.isNotEmpty
                                          ? cliente.denominacion[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 12),
                                  
                                  // Información del cliente
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          cliente.denominacion,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: <Widget>[
                                            // Documento
                                            Row(
                                              children: <Widget>[
                                                const FaIcon(
                                                  FontAwesomeIcons.idCard,
                                                  size: 12,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  cliente.numeroDocumento,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 16),
                                            // Teléfono si existe
                                            if (cliente.telefono != null && cliente.telefono!.isNotEmpty)
                                              Row(
                                                children: <Widget>[
                                                  const FaIcon(
                                                    FontAwesomeIcons.phone,
                                                    size: 12,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    cliente.telefono!,
                                                    style: TextStyle(
                                                      color: Colors.grey.shade700,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Botón para seleccionar
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 28,
                                    ),
                                    onPressed: () => widget.onClienteSeleccionado(cliente),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
