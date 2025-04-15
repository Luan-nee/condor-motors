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
  late AnimationController _linkAnimationController;
  late Animation<double> _linkAnimation;

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
  bool _seriesVinculadas = true;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.sucursal != null;
    _sucursalProvider = Provider.of<SucursalProvider>(context, listen: false);

    // Inicializar el controlador de animación
    _linkAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _linkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _linkAnimationController,
      curve: Curves.easeInOut,
    ));

    // Iniciar la animación si está vinculado por defecto
    if (_seriesVinculadas) {
      _linkAnimationController.forward();
    }

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
    _linkAnimationController.dispose();
    _nombreController.dispose();
    _direccionController.dispose();
    _serieFacturaController.dispose();
    _numeroFacturaInicialController.dispose();
    _serieBoletaController.dispose();
    _numeroBoletaInicialController.dispose();
    _codigoEstablecimientoController.dispose();
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
                // Encabezado
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

                // Contenido del formulario
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Columna Izquierda
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sección: Información General
                              _buildSectionTitle('Información General',
                                  FontAwesomeIcons.building),
                              const SizedBox(height: 16),

                              // Nombre de la sucursal
                              TextFormField(
                                controller: _nombreController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre de la Sucursal *',
                                  hintText: 'Ej: Sucursal Principal',
                                  prefixIcon:
                                      FaIcon(FontAwesomeIcons.store, size: 18),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (String? value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'El nombre es requerido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Dirección
                              TextFormField(
                                controller: _direccionController,
                                decoration: const InputDecoration(
                                  labelText: 'Dirección *',
                                  hintText: 'Ej: Av. Principal 123',
                                  prefixIcon: FaIcon(
                                      FontAwesomeIcons.locationDot,
                                      size: 18),
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
                              const SizedBox(height: 16),

                              // Tipo de sucursal
                              Container(
                                padding: const EdgeInsets.all(12),
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
                                    Row(
                                      children: [
                                        const FaIcon(
                                          FontAwesomeIcons.buildingFlag,
                                          size: 16,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Tipo de Sucursal',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      value: _sucursalCentral
                                          ? 'Central'
                                          : 'Local',
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
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Columna Derecha
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sección: Series y Numeración
                              _buildSectionTitle('Series y Numeración',
                                  FontAwesomeIcons.fileInvoiceDollar),
                              const SizedBox(height: 16),

                              // Series de Facturación (Ya existente)
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
                                    Row(
                                      children: [
                                        const FaIcon(
                                          FontAwesomeIcons.fileInvoice,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Series de Facturación',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const Spacer(),
                                        Tooltip(
                                          message: _seriesVinculadas
                                              ? 'Series vinculadas: Los cambios en la factura se reflejarán en la boleta'
                                              : 'Vincular series de factura y boleta',
                                          child: AnimatedBuilder(
                                            animation: _linkAnimation,
                                            builder: (context, child) {
                                              return IconButton(
                                                icon: Transform.rotate(
                                                  angle: _linkAnimation.value *
                                                      2.0 *
                                                      3.14159,
                                                  child: FaIcon(
                                                    _seriesVinculadas
                                                        ? FontAwesomeIcons.link
                                                        : FontAwesomeIcons
                                                            .linkSlash,
                                                    size: 16,
                                                    color: Color.lerp(
                                                      Colors.white54,
                                                      Colors.blue,
                                                      _linkAnimation.value,
                                                    ),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _seriesVinculadas =
                                                        !_seriesVinculadas;
                                                    if (_seriesVinculadas) {
                                                      _linkAnimationController
                                                          .forward();
                                                      final String
                                                          serieFactura =
                                                          _serieFacturaController
                                                              .text;
                                                      if (serieFactura
                                                              .startsWith(
                                                                  'F') &&
                                                          serieFactura.length ==
                                                              4) {
                                                        _serieBoletaController
                                                                .text =
                                                            'B${serieFactura.substring(1)}';
                                                      }
                                                    } else {
                                                      _linkAnimationController
                                                          .reverse();
                                                    }
                                                  });
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Serie de Factura
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const FaIcon(
                                              FontAwesomeIcons.receipt,
                                              size: 14,
                                              color: Colors.white70,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Serie Factura',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _serieFacturaController,
                                          maxLength: 4,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            helperText: 'F + 3 dígitos (F001)',
                                            counterText: '',
                                            isDense: true,
                                          ),
                                          validator: (value) =>
                                              _validateSerie(value, 'F'),
                                          onChanged: (value) =>
                                              _handleSerieChange(value,
                                                  _serieFacturaController, 'F'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Serie de Boleta
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const FaIcon(
                                              FontAwesomeIcons.receipt,
                                              size: 14,
                                              color: Colors.white70,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Serie Boleta',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (_seriesVinculadas)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    left: 8),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  'Vinculada',
                                                  style: TextStyle(
                                                    color: Colors.blue,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _serieBoletaController,
                                          maxLength: 4,
                                          enabled: !_seriesVinculadas,
                                          decoration: InputDecoration(
                                            border: const OutlineInputBorder(),
                                            helperText: 'B + 3 dígitos (B001)',
                                            counterText: '',
                                            isDense: true,
                                            filled: _seriesVinculadas,
                                            fillColor: _seriesVinculadas
                                                ? Colors.blue.withOpacity(0.1)
                                                : null,
                                          ),
                                          validator: (value) =>
                                              _validateSerie(value, 'B'),
                                          onChanged: (value) =>
                                              _handleSerieChange(value,
                                                  _serieBoletaController, 'B'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Números Iniciales
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller:
                                          _numeroFacturaInicialController,
                                      decoration: const InputDecoration(
                                        labelText: 'N° Factura Inicial',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        prefixIcon: FaIcon(
                                            FontAwesomeIcons.hashtag,
                                            size: 16),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: _validateNumeroInicial,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller:
                                          _numeroBoletaInicialController,
                                      decoration: const InputDecoration(
                                        labelText: 'N° Boleta Inicial',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        prefixIcon: FaIcon(
                                            FontAwesomeIcons.hashtag,
                                            size: 16),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: _validateNumeroInicial,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Sección: Código de Establecimiento
                              _buildSectionTitle('Código de Establecimiento',
                                  FontAwesomeIcons.qrcode),
                              const SizedBox(height: 16),

                              Container(
                                padding: const EdgeInsets.all(12),
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
                                    TextFormField(
                                      controller:
                                          _codigoEstablecimientoController,
                                      maxLength: 4,
                                      decoration: const InputDecoration(
                                        labelText: 'Código',
                                        helperText: 'E + 3 dígitos (E001)',
                                        counterText: '',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        prefixIcon: FaIcon(
                                            FontAwesomeIcons.buildingUser,
                                            size: 16),
                                      ),
                                      validator: (value) =>
                                          _validateSerie(value, 'E'),
                                      onChanged: (value) => _handleSerieChange(
                                          value,
                                          _codigoEstablecimientoController,
                                          'E'),
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

  // Métodos auxiliares para validación
  String? _validateSerie(String? value, String prefix) {
    if (value == null || value.isEmpty) {
      return 'Requerido';
    }
    if (!value.startsWith(prefix)) {
      return 'Inicia con $prefix';
    }
    if (value.length != 4) {
      return '4 caracteres';
    }
    if (!RegExp('^$prefix\\d{3}\$').hasMatch(value)) {
      return 'Formato: ${prefix}001';
    }
    return null;
  }

  void _handleSerieChange(
      String value, TextEditingController controller, String prefix) {
    if (value.isEmpty) {
      controller
        ..text = prefix
        ..selection = TextSelection.fromPosition(
          const TextPosition(offset: 1),
        );
    } else if (!value.startsWith(prefix)) {
      controller
        ..text = '$prefix${value.replaceAll(RegExp(r'[^0-9]'), '')}'
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );
    }

    if (prefix == 'F' &&
        _seriesVinculadas &&
        value.length == 4 &&
        value.startsWith('F')) {
      _serieBoletaController.text = 'B${value.substring(1)}';
    }
  }

  String? _validateNumeroInicial(String? value) {
    if (value == null || value.isEmpty) {
      return 'Requerido';
    }
    if (int.tryParse(value) == null || int.parse(value) < 1) {
      return 'Número inválido';
    }
    return null;
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        FaIcon(
          icon,
          size: 18,
          color: const Color(0xFFE31E24),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
