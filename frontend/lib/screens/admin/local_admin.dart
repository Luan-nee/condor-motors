import 'package:flutter/material.dart';
import '../../models/branch.dart';
import '../../api/api.service.dart';

class LocalAdminScreen extends StatefulWidget {
  const LocalAdminScreen({super.key});

  @override
  State<LocalAdminScreen> createState() => _LocalAdminScreenState();
}

class _LocalAdminScreenState extends State<LocalAdminScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<Branch> _branches = [];
  String _selectedType = 'central';

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Implementar carga desde API
      setState(() {
        _branches = [
          Branch(
            id: 1,
            name: 'Central Lima',
            address: 'Av. La Marina 123',
            type: 'central',
            phone: '(01) 123-4567',
            manager: 'Juan Pérez',
          ),
          Branch(
            id: 2,
            name: 'Sucursal Miraflores',
            address: 'Av. Larco 456',
            type: 'sucursal',
            phone: '(01) 987-6543',
            manager: 'Ana García',
          ),
        ];
      });
    } catch (e) {
      // Manejar error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddEditBranchDialog([Branch? branch]) {
    showDialog(
      context: context,
      builder: (context) => _BranchFormDialog(
        branch: branch,
        onSave: (editedBranch) async {
          // TODO: Implementar guardado
          await _loadBranches();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra superior
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Gestión de Locales',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Local'),
                onPressed: () => _showAddEditBranchDialog(),
              ),
            ],
          ),
        ),

        // Tabs de Centrales/Sucursales
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'central',
                      label: Text('Centrales'),
                      icon: Icon(Icons.store),
                    ),
                    ButtonSegment(
                      value: 'sucursal',
                      label: Text('Sucursales'),
                      icon: Icon(Icons.store_mall_directory),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedType = newSelection.first;
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        // Lista de locales
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _branches
                      .where((b) => b.type == _selectedType)
                      .length,
                  itemBuilder: (context, index) {
                    final branch = _branches
                        .where((b) => b.type == _selectedType)
                        .toList()[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          branch.type == 'central'
                              ? Icons.store
                              : Icons.store_mall_directory,
                        ),
                        title: Text(branch.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(branch.address),
                            if (branch.phone != null)
                              Text('Tel: ${branch.phone}'),
                            if (branch.manager != null)
                              Text('Encargado: ${branch.manager}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showAddEditBranchDialog(branch),
                            ),
                            IconButton(
                              icon: Icon(
                                branch.isActive
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                // TODO: Implementar toggle de estado
                              },
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _BranchFormDialog extends StatefulWidget {
  final Branch? branch;
  final Function(Branch) onSave;

  const _BranchFormDialog({
    this.branch,
    required this.onSave,
  });

  @override
  State<_BranchFormDialog> createState() => _BranchFormDialogState();
}

class _BranchFormDialogState extends State<_BranchFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _managerController;
  late String _type;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final branch = widget.branch;
    _nameController = TextEditingController(text: branch?.name);
    _addressController = TextEditingController(text: branch?.address);
    _phoneController = TextEditingController(text: branch?.phone);
    _managerController = TextEditingController(text: branch?.manager);
    _type = branch?.type ?? 'central';
    _isActive = branch?.isActive ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.branch == null ? 'Nuevo Local' : 'Editar Local'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'central',
                    label: Text('Central'),
                    icon: Icon(Icons.store),
                  ),
                  ButtonSegment(
                    value: 'sucursal',
                    label: Text('Sucursal'),
                    icon: Icon(Icons.store_mall_directory),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _type = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _managerController,
                decoration: const InputDecoration(
                  labelText: 'Encargado',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Local Activo'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
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
            if (_formKey.currentState?.validate() ?? false) {
              final branch = Branch(
                id: widget.branch?.id ?? 0,
                name: _nameController.text,
                address: _addressController.text,
                type: _type,
                phone: _phoneController.text,
                manager: _managerController.text,
                isActive: _isActive,
              );
              widget.onSave(branch);
              Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _managerController.dispose();
    super.dispose();
  }
}
