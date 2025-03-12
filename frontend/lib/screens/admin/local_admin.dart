import 'package:flutter/material.dart';
import '../../api/main.api.dart';
import '../../api/locales.api.dart';

class LocalAdminScreen extends StatefulWidget {
  const LocalAdminScreen({super.key});

  @override
  State<LocalAdminScreen> createState() => _LocalAdminScreenState();
}

class _LocalAdminScreenState extends State<LocalAdminScreen> {
  final _apiService = ApiService();
  late final LocalesApi _localesApi;
  bool _isLoading = false;
  List<Local> _locales = [];
  String _selectedView = 'todos'; // todos, tiendas, almacenes, oficinas

  @override
  void initState() {
    super.initState();
    _localesApi = LocalesApi(_apiService);
    _cargarLocales();
  }
  Future<void> _cargarLocales() async {
    setState(() => _isLoading = true);
    try {
      final locales = await _localesApi.getLocales();
      if (!mounted) return;
      setState(() => _locales = locales);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar locales')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _guardarLocal(Map<String, dynamic> data) async {
    try {
      if (data['id'] != null) {
        await _localesApi.updateLocal(data['id'], data);
      } else {
        await _localesApi.createLocal(data);
      }
      if (!mounted) return;
      _cargarLocales();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local guardado exitosamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar local: $e')),
      );
    }
  }

  void _showLocalDialog([Local? local]) {
    showDialog(
      context: context,
      builder: (context) => LocalFormDialog(
        local: local,
        onSave: _guardarLocal,
      ),
    );
  }

  List<Local> get _localesFiltrados {
    if (_selectedView == 'todos') return _locales;
    return _locales.where((l) => l.tipo == _selectedView.toUpperCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Locales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showLocalDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'todos',
                  label: Text('Todos'),
                ),
                ButtonSegment(
                  value: 'tienda',
                  label: Text('Tiendas'),
                ),
                ButtonSegment(
                  value: 'almacen',
                  label: Text('Almacenes'),
                ),
                ButtonSegment(
                  value: 'oficina',
                  label: Text('Oficinas'),
                ),
              ],
              selected: {_selectedView},
              onSelectionChanged: (values) {
                setState(() => _selectedView = values.first);
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _localesFiltrados.length,
                    itemBuilder: (context, index) {
                      final local = _localesFiltrados[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(local.nombre),
                          subtitle: Text(local.direccion),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showLocalDialog(local),
                              ),
                              Switch(
                                value: local.activo,
                                onChanged: (value) async {
                                  await _localesApi.updateLocal(
                                    local.id,
                                    {'activo': value},
                                  );
                                  _cargarLocales();
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

class LocalFormDialog extends StatefulWidget {
  final Local? local;
  final Function(Map<String, dynamic>) onSave;

  const LocalFormDialog({
    super.key,
    this.local,
    required this.onSave,
  });

  @override
  State<LocalFormDialog> createState() => _LocalFormDialogState();
}

class _LocalFormDialogState extends State<LocalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _encargadoController = TextEditingController();
  String _tipo = LocalesApi.tipos['TIENDA']!;

  @override
  void initState() {
    super.initState();
    if (widget.local != null) {
      _nombreController.text = widget.local!.nombre;
      _direccionController.text = widget.local!.direccion;
      _telefonoController.text = widget.local!.telefono;
      _encargadoController.text = widget.local!.encargado;
      _tipo = widget.local!.tipo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.local == null ? 'Nuevo Local' : 'Editar Local'),
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
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El teléfono es requerido';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _encargadoController,
                decoration: const InputDecoration(labelText: 'Encargado'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El encargado es requerido';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: LocalesApi.tipos.values.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _tipo = value!);
                },
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
                if (widget.local != null) 'id': widget.local!.id,
                'nombre': _nombreController.text,
                'direccion': _direccionController.text,
                'telefono': _telefonoController.text,
                'encargado': _encargadoController.text,
                'tipo': _tipo,
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
