import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/providers/admin/sucursal.admin.provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class SucursalForm extends StatefulWidget {
  final Sucursal? sucursal;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback onCancel;

  const SucursalForm({
    super.key,
    this.sucursal,
    required this.onSave,
    required this.onCancel,
  });

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
  late SucursalProvider _sucursalProvider;

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
    _sucursalProvider = Provider.of<SucursalProvider>(context, listen: false);

    // Inicializar valores
    if (_isEditing) {
      _nombreController.text = widget.sucursal!.nombre;
      _direccionController.text = widget.sucursal!.direccion ?? '';
      _sucursalCentral = widget.sucursal!.sucursalCentral;
      _serieFacturaController.text = widget.sucursal!.serieFactura ?? 'F';
      _serieBoletaController.text = widget.sucursal!.serieBoleta ?? 'B';
      _numeroFacturaInicialController.text =
          widget.sucursal!.numeroFacturaInicial?.toString() ?? '1';
      _numeroBoletaInicialController.text =
          widget.sucursal!.numeroBoletaInicial?.toString() ?? '1';
      _codigoEstablecimientoController.text =
          widget.sucursal!.codigoEstablecimiento ?? 'E';
    } else {
      // Valores predeterminados para nuevas sucursales
      _serieFacturaController.text = 'F';
      _serieBoletaController.text = 'B';
      _codigoEstablecimientoController.text = 'E';
      _numeroFacturaInicialController.text =
          _sucursalProvider.getSiguienteNumeroFactura().toString();
      _numeroBoletaInicialController.text =
          _sucursalProvider.getSiguienteNumeroBoleta().toString();
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
        'serieFactura': _serieFacturaController.text,
        'numeroFacturaInicial': int.parse(_numeroFacturaInicialController.text),
        'serieBoleta': _serieBoletaController.text,
        'numeroBoletaInicial': int.parse(_numeroBoletaInicialController.text),
        'codigoEstablecimiento': _codigoEstablecimientoController.text,
      };
      widget.onSave(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SucursalProvider>(
      builder: (context, provider, child) {
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
                      bottom: BorderSide(color: Color(0xFF3D3D3D)),
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
                                labelText: 'Nombre de la Sucursal *',
                                hintText: 'Ej: Sucursal Principal',
                                prefixIcon: Icon(Icons.business),
                                border: OutlineInputBorder(),
                              ),
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
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
                                labelText: 'Dirección *',
                                hintText: 'Ej: Av. Principal 123',
                                prefixIcon: Icon(Icons.location_on),
                                border: OutlineInputBorder(),
                              ),
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'La dirección es requerida';
                                }
                                return null;
                              },
                              maxLines: 2,
                            ),
                            const SizedBox(height: 20),

                            // Tipo de sucursal (central o no)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tipo de Sucursal',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value:
                                        _sucursalCentral ? 'Central' : 'Local',
                                    items: provider.tiposSucursal
                                        .map((tipo) => DropdownMenuItem(
                                              value: tipo,
                                              child: Text(tipo),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _sucursalCentral = value == 'Central';
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _sucursalCentral
                                        ? 'Las sucursales centrales tienen permisos especiales y acceso a todas las funcionalidades.'
                                        : 'Las sucursales locales tienen permisos limitados según su configuración.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Serie de Factura',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _serieFacturaController,
                                    maxLength: 4,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      helperText:
                                          'Formato: F + 3 dígitos (ej: F001)',
                                      counterText: '',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'La serie es requerida';
                                      }
                                      if (!value.startsWith('F')) {
                                        return 'Debe empezar con F';
                                      }
                                      if (value.length != 4) {
                                        return 'Debe tener 4 caracteres';
                                      }
                                      if (!RegExp(r'^F\d{3}$')
                                          .hasMatch(value)) {
                                        return 'Formato inválido. Use F + 3 dígitos';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      if (value.isEmpty) {
                                        _serieFacturaController
                                          ..text = 'F'
                                          ..selection =
                                              TextSelection.fromPosition(
                                            const TextPosition(offset: 1),
                                          );
                                      } else if (!value.startsWith('F')) {
                                        _serieFacturaController
                                          ..text =
                                              'F${value.replaceAll(RegExp(r'[^0-9]'), '')}'
                                          ..selection =
                                              TextSelection.fromPosition(
                                            TextPosition(
                                                offset: _serieFacturaController
                                                    .text.length),
                                          );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Número de Factura Inicial
                            TextFormField(
                              controller: _numeroFacturaInicialController,
                              decoration: const InputDecoration(
                                labelText: 'Número de Factura Inicial',
                                prefixIcon: Icon(Icons.format_list_numbered),
                                border: OutlineInputBorder(),
                                helperText:
                                    'Este número será el inicio de la numeración',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (String? value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingrese un número inicial';
                                }
                                if (int.tryParse(value) == null ||
                                    int.parse(value) < 1) {
                                  return 'Debe ser un número positivo';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Serie de Boleta
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Serie de Boleta',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _serieBoletaController,
                                    maxLength: 4,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      helperText:
                                          'Formato: B + 3 dígitos (ej: B001)',
                                      counterText: '',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'La serie es requerida';
                                      }
                                      if (!value.startsWith('B')) {
                                        return 'Debe empezar con B';
                                      }
                                      if (value.length != 4) {
                                        return 'Debe tener 4 caracteres';
                                      }
                                      if (!RegExp(r'^B\d{3}$')
                                          .hasMatch(value)) {
                                        return 'Formato inválido. Use B + 3 dígitos';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      if (value.isEmpty) {
                                        _serieBoletaController
                                          ..text = 'B'
                                          ..selection =
                                              TextSelection.fromPosition(
                                            const TextPosition(offset: 1),
                                          );
                                      } else if (!value.startsWith('B')) {
                                        _serieBoletaController
                                          ..text =
                                              'B${value.replaceAll(RegExp(r'[^0-9]'), '')}'
                                          ..selection =
                                              TextSelection.fromPosition(
                                            TextPosition(
                                                offset: _serieBoletaController
                                                    .text.length),
                                          );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Número de Boleta Inicial
                            TextFormField(
                              controller: _numeroBoletaInicialController,
                              decoration: const InputDecoration(
                                labelText: 'Número de Boleta Inicial',
                                prefixIcon: Icon(Icons.format_list_numbered),
                                border: OutlineInputBorder(),
                                helperText:
                                    'Este número será el inicio de la numeración',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (String? value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingrese un número inicial';
                                }
                                if (int.tryParse(value) == null ||
                                    int.parse(value) < 1) {
                                  return 'Debe ser un número positivo';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Código de Establecimiento
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Código de Establecimiento',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller:
                                        _codigoEstablecimientoController,
                                    maxLength: 4,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      helperText:
                                          'Formato: E + 3 dígitos (ej: E001)',
                                      counterText: '',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'El código es requerido';
                                      }
                                      if (!value.startsWith('E')) {
                                        return 'Debe empezar con E';
                                      }
                                      if (value.length != 4) {
                                        return 'Debe tener 4 caracteres';
                                      }
                                      if (!RegExp(r'^E\d{3}$')
                                          .hasMatch(value)) {
                                        return 'Formato inválido. Use E + 3 dígitos';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      if (value.isEmpty) {
                                        _codigoEstablecimientoController
                                          ..text = 'E'
                                          ..selection =
                                              TextSelection.fromPosition(
                                            const TextPosition(offset: 1),
                                          );
                                      } else if (!value.startsWith('E')) {
                                        _codigoEstablecimientoController
                                          ..text =
                                              'E${value.replaceAll(RegExp(r'[^0-9]'), '')}'
                                          ..selection =
                                              TextSelection.fromPosition(
                                            TextPosition(
                                                offset:
                                                    _codigoEstablecimientoController
                                                        .text.length),
                                          );
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'El código de establecimiento es único para cada sucursal',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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
                      OutlinedButton.icon(
                        onPressed: widget.onCancel,
                        icon: const Icon(Icons.close),
                        label: const Text('Cancelar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
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
                        label: Text(
                            _isEditing ? 'Guardar Cambios' : 'Crear Sucursal'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
