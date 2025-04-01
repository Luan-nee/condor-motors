import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SucursalForm extends StatefulWidget {
  final Sucursal? sucursal;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback onCancel;

  const SucursalForm({
    Key? key,
    this.sucursal,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<SucursalForm> createState() => _SucursalFormState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Sucursal?>('sucursal', sucursal))
      ..add(ObjectFlagProperty<Function(Map<String, dynamic>)>.has(
          'onSave', onSave))
      ..add(ObjectFlagProperty<VoidCallback>.has('onCancel', onCancel));
  }
}

class _SucursalFormState extends State<SucursalForm>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controladores para campos de texto
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _serieFacturaController = TextEditingController();
  final TextEditingController _numeroFacturaInicialController =
      TextEditingController();
  final TextEditingController _serieBoletaController = TextEditingController();
  final TextEditingController _numeroBoletaInicialController =
      TextEditingController();
  final TextEditingController _codigoEstablecimientoController =
      TextEditingController();

  // Variables para almacenar valores
  bool _sucursalCentral = false;
  bool _isEditing = false;

  // Animación
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.sucursal != null;
    _tabController = TabController(length: 2, vsync: this);

    // Inicializar valores
    if (_isEditing) {
      _nombreController.text = widget.sucursal!.nombre;
      _direccionController.text = widget.sucursal!.direccion ?? '';
      _sucursalCentral = widget.sucursal!.sucursalCentral;
      _serieFacturaController.text = widget.sucursal!.serieFactura ?? '';
      _numeroFacturaInicialController.text =
          widget.sucursal!.numeroFacturaInicial?.toString() ?? '1';
      _serieBoletaController.text = widget.sucursal!.serieBoleta ?? '';
      _numeroBoletaInicialController.text =
          widget.sucursal!.numeroBoletaInicial?.toString() ?? '1';
      _codigoEstablecimientoController.text =
          widget.sucursal!.codigoEstablecimiento ?? '';
    } else {
      // Valores predeterminados para nuevas sucursales
      _numeroFacturaInicialController.text = '1';
      _numeroBoletaInicialController.text = '1';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _serieFacturaController.dispose();
    _numeroFacturaInicialController.dispose();
    _serieBoletaController.dispose();
    _numeroBoletaInicialController.dispose();
    _codigoEstablecimientoController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _guardarSucursal() {
    if (_formKey.currentState!.validate()) {
      final Map<String, Object> data = <String, Object>{
        if (_isEditing) 'id': widget.sucursal!.id,
        'nombre': _nombreController.text,
        'direccion': _direccionController.text,
        'sucursalCentral': _sucursalCentral,
        if (_serieFacturaController.text.isNotEmpty)
          'serieFactura': _serieFacturaController.text,
        if (_numeroFacturaInicialController.text.isNotEmpty)
          'numeroFacturaInicial':
              int.parse(_numeroFacturaInicialController.text),
        if (_serieBoletaController.text.isNotEmpty)
          'serieBoleta': _serieBoletaController.text,
        if (_numeroBoletaInicialController.text.isNotEmpty)
          'numeroBoletaInicial': int.parse(_numeroBoletaInicialController.text),
        if (_codigoEstablecimientoController.text.isNotEmpty)
          'codigoEstablecimiento': _codigoEstablecimientoController.text,
      };
      widget.onSave(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado del formulario
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF2D2D2D),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  FaIcon(
                    _isEditing
                        ? FontAwesomeIcons.penToSquare
                        : FontAwesomeIcons.plus,
                    color: const Color(0xFFE31E24),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isEditing ? 'Editar Sucursal' : 'Nueva Sucursal',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // TabBar para organizar secciones del formulario
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF212121),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF3D3D3D), width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFE31E24),
                indicatorWeight: 3,
                labelColor: const Color(0xFFE31E24),
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.business),
                    text: 'Información General',
                  ),
                  Tab(
                    icon: Icon(Icons.receipt),
                    text: 'Facturación',
                  ),
                ],
              ),
            ),

            // Contenido de las pestañas
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Pestaña: Información General
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre de la sucursal
                        TextFormField(
                          controller: _nombreController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de la Sucursal',
                            hintText: 'Ej: Sucursal Principal',
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(),
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'El nombre es requerido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Dirección
                        TextFormField(
                          controller: _direccionController,
                          decoration: const InputDecoration(
                            labelText: 'Dirección',
                            hintText: 'Ej: Av. Principal 123',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(),
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'La dirección es requerida';
                            }
                            return null;
                          },
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),

                        // Tipo de sucursal (central o no)
                        SwitchListTile(
                          title: const Text(
                            'Sucursal Central',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: const Text(
                            'Las sucursales centrales tienen permisos especiales',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          value: _sucursalCentral,
                          activeColor: const Color(0xFFE31E24),
                          onChanged: (bool value) {
                            setState(() {
                              _sucursalCentral = value;
                            });
                          },
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _sucursalCentral
                                  ? const Color(0xFFE31E24).withOpacity(0.1)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: FaIcon(
                              FontAwesomeIcons.buildingUser,
                              color: _sucursalCentral
                                  ? const Color(0xFFE31E24)
                                  : Colors.white70,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Pestaña: Facturación
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Configuración de Series',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Serie de Factura
                        TextFormField(
                          controller: _serieFacturaController,
                          decoration: const InputDecoration(
                            labelText: 'Serie de Factura',
                            hintText: 'Ej: F001',
                            prefixIcon: Icon(Icons.receipt_long),
                            helperText:
                                'Debe empezar con F y tener 4 caracteres',
                            border: OutlineInputBorder(),
                          ),
                          validator: (String? value) {
                            if (value != null && value.isNotEmpty) {
                              if (!value.startsWith('F') || value.length != 4) {
                                return 'La serie debe empezar con F y tener 4 caracteres';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Número de Factura Inicial
                        TextFormField(
                          controller: _numeroFacturaInicialController,
                          decoration: const InputDecoration(
                            labelText: 'Número de Factura Inicial',
                            hintText: 'Ej: 1',
                            prefixIcon: Icon(Icons.format_list_numbered),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (String? value) {
                            if (value != null && value.isNotEmpty) {
                              if (int.tryParse(value) == null ||
                                  int.parse(value) < 1) {
                                return 'Debe ser un número positivo';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Configuración de Boletas',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Serie de Boleta
                        TextFormField(
                          controller: _serieBoletaController,
                          decoration: const InputDecoration(
                            labelText: 'Serie de Boleta',
                            hintText: 'Ej: B001',
                            prefixIcon: Icon(Icons.receipt),
                            helperText:
                                'Debe empezar con B y tener 4 caracteres',
                            border: OutlineInputBorder(),
                          ),
                          validator: (String? value) {
                            if (value != null && value.isNotEmpty) {
                              if (!value.startsWith('B') || value.length != 4) {
                                return 'La serie debe empezar con B y tener 4 caracteres';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Número de Boleta Inicial
                        TextFormField(
                          controller: _numeroBoletaInicialController,
                          decoration: const InputDecoration(
                            labelText: 'Número de Boleta Inicial',
                            hintText: 'Ej: 1',
                            prefixIcon: Icon(Icons.format_list_numbered),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (String? value) {
                            if (value != null && value.isNotEmpty) {
                              if (int.tryParse(value) == null ||
                                  int.parse(value) < 1) {
                                return 'Debe ser un número positivo';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Configuración Adicional',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Código de Establecimiento
                        TextFormField(
                          controller: _codigoEstablecimientoController,
                          decoration: const InputDecoration(
                            labelText: 'Código de Establecimiento',
                            hintText: 'Ej: EST001',
                            prefixIcon: Icon(Icons.store),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Botones de acción
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF212121),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _guardarSucursal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    icon: Icon(_isEditing ? Icons.save : Icons.add),
                    label:
                        Text(_isEditing ? 'Guardar Cambios' : 'Crear Sucursal'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
