import 'package:flutter/material.dart';
import '../../api/main.api.dart';
import '../../api/sucursales.api.dart';

class SucursalAdminScreen extends StatefulWidget {
  const SucursalAdminScreen({super.key});

  @override
  State<SucursalAdminScreen> createState() => _SucursalAdminScreenState();
}

class _SucursalAdminScreenState extends State<SucursalAdminScreen> {
  final _apiService = ApiService();
  late final SucursalesApi _sucursalesApi;
  bool _isLoading = false;
  List<Sucursal> _sucursales = [];
  final int _currentPage = 1;
  final int _pageSize = 10;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _sucursalesApi = SucursalesApi(_apiService);
    _cargarSucursales();
  }

  Future<void> _cargarSucursales() async {
    setState(() => _isLoading = true);
    try {
      final response = await _sucursalesApi.getSucursales(
        page: _currentPage,
        pageSize: _pageSize,
        search: _searchQuery,
      );
      if (!mounted) return;
      setState(() => _sucursales = response.items);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar sucursales')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _guardarSucursal(Map<String, dynamic> data) async {
    try {
      final request = SucursalRequest(
        nombre: data['nombre'],
        direccion: data['direccion'],
        sucursalCentral: data['sucursalCentral'] ?? false,
      );

      if (data['id'] != null) {
        await _sucursalesApi.updateSucursal(data['id'], request);
      } else {
        await _sucursalesApi.createSucursal(request);
      }
      
      if (!mounted) return;
      _cargarSucursales();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sucursal guardada exitosamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar sucursal: $e')),
      );
    }
  }

  void _showSucursalDialog([Sucursal? sucursal]) {
    showDialog(
      context: context,
      builder: (context) => SucursalFormDialog(
        sucursal: sucursal,
        onSave: _guardarSucursal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Sucursales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showSucursalDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar sucursal',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _cargarSucursales();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _sucursales.length,
                    itemBuilder: (context, index) {
                      final sucursal = _sucursales[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(sucursal.nombre),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sucursal.direccion),
                              if (sucursal.sucursalCentral)
                                const Text(
                                  'Sucursal Central',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showSucursalDialog(sucursal),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirmar eliminación'),
                                      content: const Text('¿Está seguro de eliminar esta sucursal?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await _sucursalesApi.deleteSucursal(sucursal.id);
                                    _cargarSucursales();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class SucursalFormDialog extends StatefulWidget {
  final Sucursal? sucursal;
  final Function(Map<String, dynamic>) onSave;

  const SucursalFormDialog({
    super.key,
    this.sucursal,
    required this.onSave,
  });

  @override
  State<SucursalFormDialog> createState() => _SucursalFormDialogState();
}

class _SucursalFormDialogState extends State<SucursalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  bool _sucursalCentral = false;

  @override
  void initState() {
    super.initState();
    if (widget.sucursal != null) {
      _nombreController.text = widget.sucursal!.nombre;
      _direccionController.text = widget.sucursal!.direccion;
      _sucursalCentral = widget.sucursal!.sucursalCentral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.sucursal == null ? 'Nueva Sucursal' : 'Editar Sucursal'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(labelText: 'Dirección'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La dirección es requerida';
                  }
                  return null;
                },
              ),
              SwitchListTile(
                title: const Text('Sucursal Central'),
                value: _sucursalCentral,
                onChanged: (value) => setState(() => _sucursalCentral = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final data = {
                if (widget.sucursal != null) 'id': widget.sucursal!.id,
                'nombre': _nombreController.text,
                'direccion': _direccionController.text,
                'sucursalCentral': _sucursalCentral,
              };
              widget.onSave(data);
              Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
