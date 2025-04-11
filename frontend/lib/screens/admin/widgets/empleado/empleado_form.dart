import 'package:condorsmotors/models/empleado.model.dart';
import 'package:condorsmotors/providers/admin/empleado.admin.provider.dart';
import 'package:condorsmotors/screens/admin/widgets/empleado/empleado_cuenta_dialog.dart';
import 'package:condorsmotors/screens/admin/widgets/empleado/empleado_horario_dialog.dart';
import 'package:condorsmotors/utils/empleados_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class EmpleadoForm extends StatefulWidget {
  final Empleado? empleado;
  final Map<String, String> sucursales;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback onCancel;

  const EmpleadoForm({
    super.key,
    this.empleado,
    required this.sucursales,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<EmpleadoForm> createState() => _EmpleadoFormState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Empleado?>('empleado', empleado))
      ..add(DiagnosticsProperty<Map<String, String>>('sucursales', sucursales))
      ..add(ObjectFlagProperty<Function(Map<String, dynamic> p1)>.has(
          'onSave', onSave))
      ..add(ObjectFlagProperty<VoidCallback>.has('onCancel', onCancel));
  }
}

class _EmpleadoFormState extends State<EmpleadoForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controladores para los campos del formulario
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _sueldoController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();

  // Controladores para el horario
  final TextEditingController _horaInicioHoraController =
      TextEditingController();
  final TextEditingController _horaInicioMinutoController =
      TextEditingController();
  final TextEditingController _horaFinHoraController = TextEditingController();
  final TextEditingController _horaFinMinutoController =
      TextEditingController();

  String? _selectedSucursalId;
  bool _esSucursalCentral = false;
  bool _isLoading = false;
  String? _usuarioActual;
  String? _rolCuentaActual;
  bool _cuentaNoEncontrada = false;
  String? _errorCargaInfo;

  // Variable para controlar el estado activo/inactivo del empleado
  bool _isEmpleadoActivo = true;

  @override
  void initState() {
    super.initState();
    _inicializarFormulario();

    // Si hay un empleado existente, obtener su información de cuenta
    // usando addPostFrameCallback para evitar setState durante el build
    if (widget.empleado != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cargarInformacionCuenta();
      });
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _dniController.dispose();
    _sueldoController.dispose();
    _celularController.dispose();
    _horaInicioHoraController.dispose();
    _horaInicioMinutoController.dispose();
    _horaFinHoraController.dispose();
    _horaFinMinutoController.dispose();
    super.dispose();
  }

  void _inicializarFormulario() {
    if (widget.empleado != null) {
      _inicializarFormularioEmpleadoExistente();
    } else {
      _inicializarFormularioNuevoEmpleado();
    }

    // Verificar si la sucursal seleccionada es central
    _actualizarEsSucursalCentral();
  }

  void _inicializarFormularioEmpleadoExistente() {
    final Empleado empleado = widget.empleado!;

    // Datos personales
    _nombreController.text = empleado.nombre;
    _apellidosController.text = empleado.apellidos;
    _dniController.text = empleado.dni ?? '';
    _sueldoController.text = empleado.sueldo?.toString() ?? '';
    _celularController.text = empleado.celular ?? '';

    // Inicializar horarios utilizando la función de utilidad
    EmpleadosUtils.inicializarHorarios(
        horaInicioHoraController: _horaInicioHoraController,
        horaInicioMinutoController: _horaInicioMinutoController,
        horaFinHoraController: _horaFinHoraController,
        horaFinMinutoController: _horaFinMinutoController,
        horaInicio: empleado.horaInicioJornada,
        horaFin: empleado.horaFinJornada);

    // Datos laborales
    _selectedSucursalId = empleado.sucursalId;

    // Estado del empleado
    _isEmpleadoActivo = empleado.activo;
  }

  void _inicializarFormularioNuevoEmpleado() {
    // Valores por defecto para horario (8:00 - 17:00)
    EmpleadosUtils.inicializarHorarios(
        horaInicioHoraController: _horaInicioHoraController,
        horaInicioMinutoController: _horaInicioMinutoController,
        horaFinHoraController: _horaFinHoraController,
        horaFinMinutoController: _horaFinMinutoController);

    // Por defecto, un nuevo empleado está activo
    _isEmpleadoActivo = true;
  }

  Future<void> _cargarInformacionCuenta() async {
    if (widget.empleado == null || !mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _cuentaNoEncontrada = false;
      _errorCargaInfo = null;
    });

    try {
      // Usar el provider para cargar la información de la cuenta
      final empleadoProvider =
          Provider.of<EmpleadoProvider>(context, listen: false);
      final Map<String, dynamic> resultado =
          await empleadoProvider.obtenerInfoCuentaEmpleado(widget.empleado!);

      if (!mounted) {
        return;
      }

      setState(() {
        _usuarioActual = resultado['usuarioActual'] as String?;
        _rolCuentaActual = resultado['rolCuentaActual'] as String?;
        _cuentaNoEncontrada = resultado['cuentaNoEncontrada'] as bool;
        _errorCargaInfo = resultado['errorCargaInfo'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorCargaInfo =
            'Error al cargar información: ${e.toString().replaceAll('Exception: ', '')}';
        _isLoading = false;
      });
      debugPrint('Error general al cargar información de cuenta: $e');
    }
  }

  void _actualizarEsSucursalCentral() {
    if (_selectedSucursalId != null) {
      final String nombreSucursal =
          widget.sucursales[_selectedSucursalId] ?? '';
      setState(() {
        _esSucursalCentral = nombreSucursal.contains('(Central)');
      });
    } else {
      setState(() {
        _esSucursalCentral = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 900,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const FaIcon(
                      FontAwesomeIcons.userPlus,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.empleado == null
                          ? 'Nuevo Colaborador'
                          : 'Editar Colaborador',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Información de cuenta (si existe)
                _buildInfoCuentaBlock(),

                // Información personal
                const Text(
                  'INFORMACIÓN PERSONAL',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE31E24),
                  ),
                ),
                const SizedBox(height: 16),

                // Formulario organizado en 2 columnas
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Columna izquierda
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            controller: _nombreController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              labelStyle: TextStyle(color: Colors.white70),
                              prefixIcon: Icon(Icons.person,
                                  color: Colors.white54, size: 20),
                            ),
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'El nombre es requerido';
                              }
                              // Validar que solo contenga letras, tildes y espacios
                              if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$")
                                  .hasMatch(value)) {
                                return 'El nombre solo puede contener letras y espacios';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _dniController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            maxLength: 8,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'DNI',
                              labelStyle: TextStyle(color: Colors.white70),
                              prefixIcon: Icon(Icons.badge,
                                  color: Colors.white54, size: 20),
                              counterText: '',
                            ),
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'El DNI es requerido';
                              }
                              if (value.length != 8) {
                                return 'El DNI debe tener 8 dígitos';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _celularController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.phone,
                            maxLength: 9,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Celular',
                              labelStyle: TextStyle(color: Colors.white70),
                              prefixIcon: Icon(Icons.phone,
                                  color: Colors.white54, size: 20),
                              counterText: '',
                            ),
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'El numero de celular es requerido';
                              }
                              if (value.length != 9) {
                                return 'El celular debe tener 9 dígitos';
                              }
                              if (!RegExp(r'^9\d{8}$').hasMatch(value)) {
                                return 'El celular debe comenzar con el número 9';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Columna derecha
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            controller: _apellidosController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Apellidos',
                              labelStyle: TextStyle(color: Colors.white70),
                              prefixIcon: Icon(Icons.person_outline,
                                  color: Colors.white54, size: 20),
                            ),
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'El nombre es requerido';
                              }
                              // Validar que solo contenga letras, tildes y espacios
                              if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$")
                                  .hasMatch(value)) {
                                return 'El nombre solo puede contener letras y espacios';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Sueldo
                TextFormField(
                  controller: _sueldoController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Sueldo',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixText: 'S/ ',
                    prefixIcon: Icon(Icons.attach_money,
                        color: Colors.white54, size: 20),
                  ),
                  validator: (String? value) {
                    if (value != null && value.isNotEmpty) {
                      final double? sueldo = double.tryParse(value);
                      if (sueldo == null) {
                        return 'Ingrese un monto válido';
                      }
                      if (sueldo < 0) {
                        return 'El sueldo no puede ser negativo';
                      }
                      if (sueldo > 9999.99) {
                        return 'El sueldo no puede exceder S/ 9999.99';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Información laboral
                const Text(
                  'INFORMACIÓN LABORAL',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE31E24),
                  ),
                ),
                const SizedBox(height: 16),

                // Rol y Sucursal
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Sucursal
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          DropdownButtonFormField<String>(
                            value: _selectedSucursalId,
                            style: const TextStyle(color: Colors.white),
                            dropdownColor: const Color(0xFF2D2D2D),
                            decoration: InputDecoration(
                              labelText: 'Sucursal',
                              labelStyle:
                                  const TextStyle(color: Colors.white70),
                              prefixIcon: Icon(
                                _esSucursalCentral
                                    ? FontAwesomeIcons.building
                                    : FontAwesomeIcons.store,
                                color: _esSucursalCentral
                                    ? const Color(0xFF4CAF50)
                                    : Colors.white54,
                                size: 20,
                              ),
                            ),
                            items: widget.sucursales.entries
                                .map((MapEntry<String, String> entry) {
                              final bool esCentral =
                                  entry.value.contains('(Central)');
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Row(
                                  children: <Widget>[
                                    const SizedBox(width: 8),
                                    Text(
                                      entry.value,
                                      style: TextStyle(
                                        color: esCentral
                                            ? const Color(0xFF4CAF50)
                                            : Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (String? value) {
                              setState(() {
                                _selectedSucursalId = value;
                                _actualizarEsSucursalCentral();
                              });
                            },
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'Seleccione en donde va trabajar';
                              }
                              return null;
                            },
                          ),
                          if (_esSucursalCentral)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.info_outline,
                                    color: Color(0xFF4CAF50),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Esta es una sucursal central',
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

                const SizedBox(height: 24),

                // Estado del empleado
                const Text(
                  'ESTADO DEL COLABORADOR',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE31E24),
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isEmpleadoActivo
                          ? const Color(0xFF4CAF50).withOpacity(0.5)
                          : const Color(0xFFE31E24).withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: FaIcon(
                            _isEmpleadoActivo
                                ? FontAwesomeIcons.userCheck
                                : FontAwesomeIcons.userXmark,
                            color: _isEmpleadoActivo
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFE31E24),
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _isEmpleadoActivo
                                  ? 'Colaborador Activo'
                                  : 'Colaborador Inactivo',
                              style: TextStyle(
                                color: _isEmpleadoActivo
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFE31E24),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isEmpleadoActivo
                                  ? 'El colaborador está trabajando actualmente en la empresa'
                                  : 'El colaborador no está trabajando actualmente en la empresa',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Switch(
                        value: _isEmpleadoActivo,
                        onChanged: (bool value) {
                          setState(() => _isEmpleadoActivo = value);
                        },
                        activeColor: const Color(0xFF4CAF50),
                        inactiveThumbColor: const Color(0xFFE31E24),
                        activeTrackColor:
                            const Color(0xFF4CAF50).withOpacity(0.3),
                        inactiveTrackColor:
                            const Color(0xFFE31E24).withOpacity(0.3),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Horario de trabajo
                const Text(
                  'HORARIO DE TRABAJO',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE31E24),
                  ),
                ),
                const SizedBox(height: 16),

                // Si es un empleado existente, mostrar el widget de horario
                // Si es un nuevo empleado, mostrar campos de entrada de tiempo
                if (widget.empleado != null)
                  // Usar EmpleadoHorarioViewer para un empleado existente
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      EmpleadoHorarioViewer(
                        empleado: widget.empleado!,
                        showTitle: false,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const FaIcon(
                            FontAwesomeIcons.penToSquare,
                            size: 14,
                            color: Colors.white70,
                          ),
                          label: const Text(
                            'Editar horario',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          onPressed: _editarHorario,
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF3D3D3D),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  // Campos de entrada de tiempo para un nuevo empleado
                  Column(
                    children: <Widget>[
                      // Horario de inicio
                      Row(
                        children: <Widget>[
                          // Etiqueta
                          SizedBox(
                            width: 120,
                            child: Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Hora inicio:',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Campo de hora
                          Expanded(
                            child: _buildTimeInputRow(
                              horaController: _horaInicioHoraController,
                              minutoController: _horaInicioMinutoController,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Horario de fin
                      Row(
                        children: <Widget>[
                          // Etiqueta
                          SizedBox(
                            width: 120,
                            child: Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.access_time_filled,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Hora fin:',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Campo de hora
                          Expanded(
                            child: _buildTimeInputRow(
                              horaController: _horaFinHoraController,
                              minutoController: _horaFinMinutoController,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed: widget.onCancel,
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31E24),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _isLoading
                          ? null
                          : _guardar, // Deshabilitar botón si está cargando
                      child: _isLoading
                          ? const SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCuentaBlock() {
    // Si estamos cargando información
    if (_isLoading) {
      return EmpleadosUtils.buildInfoCuentaContainer(isLoading: true);
    }

    // Si hay un error al cargar la información
    if (_errorCargaInfo != null) {
      return _buildErrorContainer(_errorCargaInfo!);
    }

    // Si no se encontró una cuenta y hay un empleado existente
    if (_cuentaNoEncontrada && widget.empleado != null) {
      return _buildCrearCuentaContainer();
    }

    // Si hay una cuenta existente
    if (_usuarioActual != null) {
      return EmpleadosUtils.buildInfoCuentaContainer(
        isLoading: false,
        usuarioActual: _usuarioActual,
        rolCuentaActual: _rolCuentaActual,
        onGestionarCuenta: () => _gestionarCuenta(context),
      );
    }

    // Si no hay ninguna condición anterior, no mostrar nada
    return const SizedBox();
  }

  Widget _buildErrorContainer(String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.error_outline,
            color: Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrearCuentaContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: const <Widget>[
              FaIcon(
                FontAwesomeIcons.triangleExclamation,
                color: Colors.amber,
                size: 18,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Este colaborador no tiene una cuenta para acceder al sistema',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Para permitir que este colaborador inicie sesión en el sistema, necesita crear una cuenta de usuario con un rol asignado.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _gestionarCuenta(context),
              label: const Text('Crear Cuenta de Usuario'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Formatear horarios en formato hh:mm:ss
      final String horaInicio =
          '${_horaInicioHoraController.text.padLeft(2, '0')}:${_horaInicioMinutoController.text.padLeft(2, '0')}:00';
      final String horaFin =
          '${_horaFinHoraController.text.padLeft(2, '0')}:${_horaFinMinutoController.text.padLeft(2, '0')}:00';

      // Construir datos del empleado
      final Map<String, Object?> empleadoData = <String, Object?>{
        'nombre': _nombreController.text,
        'apellidos': _apellidosController.text,
        'dni': _dniController.text,
        'sueldo': _sueldoController.text.isNotEmpty
            ? double.parse(_sueldoController.text)
            : null,
        'sucursalId': _selectedSucursalId,
        'horaInicioJornada': horaInicio,
        'horaFinJornada': horaFin,
        'celular':
            _celularController.text.isNotEmpty ? _celularController.text : null,
        'activo': _isEmpleadoActivo,
      };

      // Remover valores nulos
      empleadoData.removeWhere((String key, Object? value) =>
          value == null || (value is String && value.isEmpty));

      // Guardar empleado
      await widget.onSave(empleadoData);

      // Recargar datos usando el provider
      if (mounted) {
        final empleadoProvider =
            Provider.of<EmpleadoProvider>(context, listen: false);
        await empleadoProvider.recargarDatos();

        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.empleado == null
                    ? 'Colaborador creado correctamente'
                    : 'Colaborador actualizado correctamente',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _gestionarCuenta(BuildContext context) async {
    if (widget.empleado == null || !mounted) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Obtener el provider
      final empleadoProvider =
          Provider.of<EmpleadoProvider>(context, listen: false);

      // Obtener datos para gestionar la cuenta
      final Map<String, dynamic> datosCuenta =
          await empleadoProvider.prepararDatosGestionCuenta(widget.empleado!);

      // Si el widget ya no está montado, salir temprano
      if (!mounted || !context.mounted) {
        return;
      }

      // Mostrar diálogo de gestión de cuenta
      final bool cuentaActualizada = await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) => Dialog(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: EmpleadoCuentaDialog(
                  empleado: widget.empleado!,
                  roles: datosCuenta['roles'],
                  esNuevaCuenta: datosCuenta['esNuevaCuenta'],
                ),
              ),
            ),
          ) ??
          false;

      // Si el widget ya no está montado, salir temprano
      if (!mounted) {
        return;
      }

      if (cuentaActualizada && context.mounted) {
        EmpleadosUtils.mostrarMensaje(
          context,
          mensaje: 'Cuenta actualizada correctamente',
          esError: false,
        );

        // Recargar información de cuenta
        await _cargarInformacionCuenta();

        if (mounted) {
          setState(() => _cuentaNoEncontrada = false);
        }
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      // Actualizar estado de carga
      setState(() => _isLoading = false);

      if (!context.mounted) {
        return;
      }

      // Mostrar mensaje de error
      final String errorMsg = e.toString().replaceAll('Exception: ', '');
      EmpleadosUtils.mostrarMensaje(
        context,
        mensaje: 'Error al gestionar cuenta: $errorMsg',
        esError: true,
      );
    } finally {
      // Asegurarse de actualizar el estado solo si el widget sigue montado
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Método para construir campos de entrada de hora/minuto
  Widget _buildTimeInputRow({
    required TextEditingController horaController,
    required TextEditingController minutoController,
  }) {
    return Row(
      children: <Widget>[
        // Horas
        Expanded(
          child: TextFormField(
            controller: horaController,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'HH',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return 'Requerido';
              }
              final int? hora = int.tryParse(value);
              if (hora == null || hora < 0 || hora > 23) {
                return 'Inválido';
              }
              return null;
            },
            onChanged: (String value) {
              // Formatear a 2 dígitos
              if (value.length > 2) {
                horaController
                  ..text = value.substring(0, 2)
                  ..selection = TextSelection.fromPosition(
                    const TextPosition(offset: 2),
                  );
              }

              // Validar rango
              final int? hora = int.tryParse(value);
              if (hora != null && (hora < 0 || hora > 23)) {
                horaController.text = '00';
              }

              // Avanzar al siguiente campo si se ingresaron 2 dígitos
              if (value.length == 2) {
                FocusScope.of(context).nextFocus();
              }
            },
          ),
        ),

        // Separador
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            ':',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Minutos
        Expanded(
          child: TextFormField(
            controller: minutoController,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'MM',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return 'Requerido';
              }
              final int? minuto = int.tryParse(value);
              if (minuto == null || minuto < 0 || minuto > 59) {
                return 'Inválido';
              }
              return null;
            },
            onChanged: (String value) {
              // Formatear a 2 dígitos
              if (value.length > 2) {
                minutoController
                  ..text = value.substring(0, 2)
                  ..selection = TextSelection.fromPosition(
                    const TextPosition(offset: 2),
                  );
              }

              // Validar rango
              final int? minuto = int.tryParse(value);
              if (minuto != null && (minuto < 0 || minuto > 59)) {
                minutoController.text = '00';
              }
            },
          ),
        ),
      ],
    );
  }

  void _editarHorario() {
    // Guardar los valores actuales por si el usuario cancela
    final String horaInicioHoraOriginal = _horaInicioHoraController.text;
    final String horaInicioMinutoOriginal = _horaInicioMinutoController.text;
    final String horaFinHoraOriginal = _horaFinHoraController.text;
    final String horaFinMinutoOriginal = _horaFinMinutoController.text;

    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: const <Widget>[
                  FaIcon(
                    FontAwesomeIcons.clock,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Editar Horario',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Horario de inicio
              Row(
                children: <Widget>[
                  // Etiqueta
                  SizedBox(
                    width: 120,
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.access_time,
                          color: Colors.white54,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Hora inicio:',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Campo de hora
                  Expanded(
                    child: _buildTimeInputRow(
                      horaController: _horaInicioHoraController,
                      minutoController: _horaInicioMinutoController,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Horario de fin
              Row(
                children: <Widget>[
                  // Etiqueta
                  SizedBox(
                    width: 120,
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.access_time_filled,
                          color: Colors.white54,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Hora fin:',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Campo de hora
                  Expanded(
                    child: _buildTimeInputRow(
                      horaController: _horaFinHoraController,
                      minutoController: _horaFinMinutoController,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () {
                      // Restaurar valores originales si cancela
                      _horaInicioHoraController.text = horaInicioHoraOriginal;
                      _horaInicioMinutoController.text =
                          horaInicioMinutoOriginal;
                      _horaFinHoraController.text = horaFinHoraOriginal;
                      _horaFinMinutoController.text = horaFinMinutoOriginal;
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      // Validar campos de hora
                      final int? horaInicio =
                          int.tryParse(_horaInicioHoraController.text);
                      final int? minutoInicio =
                          int.tryParse(_horaInicioMinutoController.text);
                      final int? horaFin =
                          int.tryParse(_horaFinHoraController.text);
                      final int? minutoFin =
                          int.tryParse(_horaFinMinutoController.text);

                      if (horaInicio == null ||
                          horaInicio < 0 ||
                          horaInicio > 23 ||
                          minutoInicio == null ||
                          minutoInicio < 0 ||
                          minutoInicio > 59 ||
                          horaFin == null ||
                          horaFin < 0 ||
                          horaFin > 23 ||
                          minutoFin == null ||
                          minutoFin < 0 ||
                          minutoFin > 59) {
                        // Mostrar mensaje de error
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Por favor, ingrese horas válidas'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Todo válido, actualizar localmente
                      setState(() {
                        // Se guardará al confirmar el formulario
                      });

                      Navigator.pop(context);

                      // Mostrar mensaje de confirmación
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Horario actualizado'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
