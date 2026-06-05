import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/providers/admin/sucursal.admin.riverpod.dart';
import 'package:condorsmotors/screens/admin/widgets/sucursal/components/sucursal_form_series.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:condorsmotors/utils/sucursal_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SucursalForm extends ConsumerStatefulWidget {
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
  ConsumerState<SucursalForm> createState() => _SucursalFormState();

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

class _SucursalFormState extends ConsumerState<SucursalForm>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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
    final notifier = ref.read(sucursalAdminProvider.notifier);

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
      _serieFacturaController.text = widget.sucursal!.serieFactura ?? '';
      _serieBoletaController.text = widget.sucursal!.serieBoleta ?? '';
      _numeroFacturaInicialController.text =
          widget.sucursal!.numeroFacturaInicial?.toString() ?? '1';
      _numeroBoletaInicialController.text =
          widget.sucursal!.numeroBoletaInicial?.toString() ?? '1';
      _codigoEstablecimientoController.text =
          widget.sucursal!.codigoEstablecimiento ?? '';
    } else {
      // Valores predeterminados para nuevas sucursales
      // Los campos de serie se dejan vacíos para que sean opcionales
      _serieFacturaController.text = '';
      _serieBoletaController.text = '';
      _codigoEstablecimientoController.text = '';
      _numeroFacturaInicialController.text =
          notifier.getSiguienteNumeroFactura().toString();
      _numeroBoletaInicialController.text =
          notifier.getSiguienteNumeroBoleta().toString();
    }

    // Agregar listeners para detectar cambios e interactividad
    _nombreController.addListener(_onFieldChanged);
    _direccionController.addListener(_onFieldChanged);
    _serieFacturaController.addListener(_onFieldChanged);
    _serieBoletaController.addListener(_onFieldChanged);
    _numeroFacturaInicialController.addListener(_onFieldChanged);
    _numeroBoletaInicialController.addListener(_onFieldChanged);
    _codigoEstablecimientoController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nombreController.removeListener(_onFieldChanged);
    _direccionController.removeListener(_onFieldChanged);
    _serieFacturaController.removeListener(_onFieldChanged);
    _serieBoletaController.removeListener(_onFieldChanged);
    _numeroFacturaInicialController.removeListener(_onFieldChanged);
    _numeroBoletaInicialController.removeListener(_onFieldChanged);
    _codigoEstablecimientoController.removeListener(_onFieldChanged);

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

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool _hasChanges() {
    if (!_isEditing) {
      // Para nueva sucursal, se habilita "Guardar" si el nombre no está vacío
      return _nombreController.text.trim().isNotEmpty;
    }

    final sucursal = widget.sucursal!;
    final String initialNombre = sucursal.nombre;
    final String initialDireccion = sucursal.direccion ?? '';
    final bool initialCentral = sucursal.sucursalCentral;
    final String initialSerieFactura = sucursal.serieFactura ?? '';
    final String initialSerieBoleta = sucursal.serieBoleta ?? '';
    final String initialNumFactura = sucursal.numeroFacturaInicial?.toString() ?? '1';
    final String initialNumBoleta = sucursal.numeroBoletaInicial?.toString() ?? '1';
    final String initialCodigo = sucursal.codigoEstablecimiento ?? '';

    final bool nombreChanged = _nombreController.text.trim() != initialNombre.trim();
    final bool direccionChanged = _direccionController.text.trim() != initialDireccion.trim();
    final bool centralChanged = _sucursalCentral != initialCentral;
    final bool serieFacturaChanged = _serieFacturaController.text.trim() != initialSerieFactura.trim();
    final bool serieBoletaChanged = _serieBoletaController.text.trim() != initialSerieBoleta.trim();
    final bool numFacturaChanged = _numeroFacturaInicialController.text != initialNumFactura;
    final bool numBoletaChanged = _numeroBoletaInicialController.text != initialNumBoleta;
    final bool codigoChanged = _codigoEstablecimientoController.text.trim() != initialCodigo.trim();

    return nombreChanged ||
        direccionChanged ||
        centralChanged ||
        serieFacturaChanged ||
        serieBoletaChanged ||
        numFacturaChanged ||
        numBoletaChanged ||
        codigoChanged;
  }

  void _guardarSucursal() {
    if (_formKey.currentState!.validate()) {
      final Map<String, Object> data = <String, Object>{
        if (_isEditing) 'id': widget.sucursal!.id,
        'nombre': _nombreController.text,
        // Solo incluir dirección si no está vacía
        if (_direccionController.text.trim().isNotEmpty)
          'direccion': _direccionController.text.trim(),
        'sucursalCentral': _sucursalCentral,
      };

      // Agregar series y código siempre que tengan valores válidos (4 caracteres)
      final String serieFactura = _serieFacturaController.text.trim();
      if (serieFactura.length == 4 && serieFactura.startsWith('F')) {
        data['serieFactura'] = serieFactura;

        // Agregar número de factura inicial si se proporciona
        if (_numeroFacturaInicialController.text.isNotEmpty) {
          data['numeroFacturaInicial'] =
              int.parse(_numeroFacturaInicialController.text);
        }
      }

      final String serieBoleta = _serieBoletaController.text.trim();
      if (serieBoleta.length == 4 && serieBoleta.startsWith('B')) {
        data['serieBoleta'] = serieBoleta;

        // Agregar número de boleta inicial si se proporciona
        if (_numeroBoletaInicialController.text.isNotEmpty) {
          data['numeroBoletaInicial'] =
              int.parse(_numeroBoletaInicialController.text);
        }
      }

      final String codigoEstablecimiento =
          _codigoEstablecimientoController.text.trim();
      if (codigoEstablecimiento.length == 4 &&
          RegExp(r'^[0-9]{4}$').hasMatch(codigoEstablecimiento)) {
        data['codigoEstablecimiento'] = codigoEstablecimiento;
      }

      // Guardar los datos - el provider ya hará la recarga automáticamente
      widget.onSave(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el estado si es necesario, aunque aquí principalmente usamos acciones
    // final state = ref.watch(sucursalAdminProvider);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceColor,
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
                    color: SucursalUtils.colorCentral,
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
            Flexible(
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
                          _buildSectionTitle(
                              'Información General', FontAwesomeIcons.building),
                          const SizedBox(height: 16),

                          // Nombre de la sucursal
                          TextFormField(
                            controller: _nombreController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de la Sucursal *',
                              hintText: 'Ej: Sucursal Principal',
                              prefixIcon: Icon(Icons.store, size: 20),
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
                              labelText: 'Dirección',
                              hintText: 'Ej: Av. Principal 123',
                              prefixIcon: Icon(Icons.location_on, size: 20),
                            ),
                            validator: (String? value) {
                              return null;
                            },
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),

                          // Tipo de sucursal
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.buildingFlag,
                                      size: 16,
                                      color: Colors.white70,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Tipo de local',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue:
                                      _sucursalCentral ? 'Central' : 'Sucursal',
                                  items: SucursalUtils.tiposSucursal
                                      .where((tipo) => tipo != 'Todos')
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
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Sección: Código de Establecimiento
                          _buildSectionTitle('Código de Establecimiento',
                              FontAwesomeIcons.qrcode),
                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _codigoEstablecimientoController,
                                  maxLength: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'Código (Opcional)',
                                    hintText: 'Ej: 0001',
                                    counterText: '',
                                    isDense: true,
                                    prefixIcon: Icon(Icons.pin, size: 18),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: _validateCodigo,
                                  onChanged: _handleCodigoChange,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'El código de establecimiento es único para cada sucursal (opcional)',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Ingresar solo 4 dígitos numéricos (0-9)',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 11,
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
                      child: SucursalFormSeries(
                        serieFacturaController: _serieFacturaController,
                        serieBoletaController: _serieBoletaController,
                        numeroFacturaInicialController: _numeroFacturaInicialController,
                        numeroBoletaInicialController: _numeroBoletaInicialController,
                        seriesVinculadas: _seriesVinculadas,
                        onToggleVinculadas: () {
                          setState(() {
                            _seriesVinculadas = !_seriesVinculadas;
                            if (_seriesVinculadas) {
                              _linkAnimationController.forward();
                              final String serieFactura = _serieFacturaController.text;
                              if (serieFactura.startsWith('F') && serieFactura.length == 4) {
                                _serieBoletaController.text = 'B${serieFactura.substring(1)}';
                              }
                            } else {
                              _linkAnimationController.reverse();
                            }
                          });
                        },
                        linkAnimation: _linkAnimation,
                        validateSerieFactura: (value) => _validateSerie(value, 'F'),
                        validateSerieBoleta: (value) => _validateSerie(value, 'B'),
                        onSerieFacturaChanged: (value) => _handleSerieChange(value, _serieFacturaController, 'F'),
                        onSerieBoletaChanged: (value) => _handleSerieChange(value, _serieBoletaController, 'B'),
                        validateNumeroInicial: _validateNumeroInicial,
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
                  OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _hasChanges() ? _guardarSucursal : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SucursalUtils.colorCentral,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                      disabledForegroundColor: Colors.white30,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    icon: Icon(_isEditing ? Icons.save : Icons.add),
                    label: Text(_isEditing ? 'Guardar' : 'Crear'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Métodos auxiliares para validación
  String? _validateSerie(String? value, String prefix,
      {bool isRequired = false}) {
    if (value == null || value.isEmpty) {
      if (isRequired) {
        return 'Campo requerido';
      }
      return null; // Permitir campo vacío
    }

    if (prefix == 'E') {
      // Para código de establecimiento, verificar que tenga 4 dígitos si no está vacío
      if (value.isNotEmpty && value.length != 4) {
        return 'Debe tener 4 caracteres';
      }
      if (value.isNotEmpty && !RegExp(r'^[0-9]{4}$').hasMatch(value)) {
        return 'Solo se permiten dígitos';
      }
    } else {
      // Usar SucursalUtils para validar series
      final tipo = prefix == 'F' ? 'factura' : 'boleta';
      return SucursalUtils.validarSerie(value, tipo);
    }

    return null;
  }

  void _handleSerieChange(
      String value, TextEditingController controller, String prefix) {
    // No forzar el prefijo si el campo está vacío
    if (value.isEmpty) {
      return;
    }

    // Si es código de establecimiento, solo permitir dígitos
    if (prefix == 'E') {
      final digitsOnly = value.replaceAll(RegExp('[^0-9]'), '');
      if (digitsOnly != value) {
        controller
          ..text = digitsOnly
          ..selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
      }
      return;
    }

    // Si es el primer carácter que se escribe, asignar el prefijo correspondiente
    if (value.length == 1 && !value.startsWith(prefix)) {
      controller
        ..text = prefix
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );
      return;
    }

    if (prefix != 'E' && !value.startsWith(prefix) && value.isNotEmpty) {
      // Solo para series de factura y boleta forzamos el prefijo si hay contenido
      controller
        ..text = '$prefix${value.replaceAll(RegExp('[^0-9]'), '')}'
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
    return SucursalUtils.validarNumeroInicial(value);
  }

  String? _validateCodigo(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Ahora es opcional
    }
    if (value.length != 4 || !RegExp(r'^[0-9]{4}$').hasMatch(value)) {
      return 'Debe tener exactamente 4 dígitos numéricos';
    }
    return null;
  }

  void _handleCodigoChange(String value) {
    if (value.isEmpty) {
      return;
    }

    // Filtrar: permitir solo dígitos
    final digitsOnly = value.replaceAll(RegExp('[^0-9]'), '');

    // Si el usuario intentó ingresar algo que no son dígitos, corregirlo
    if (digitsOnly != value) {
      _codigoEstablecimientoController
        ..text = digitsOnly
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: digitsOnly.length),
        );
    }
  }

  Widget _buildSectionTitle(String title, FaIconData icon) {
    return Row(
      children: [
        FaIcon(
          icon,
          size: 18,
          color: AppTheme.primaryColor,
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
