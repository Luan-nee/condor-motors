import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../models/empleado.model.dart';
import '../../../main.dart' show api;
import 'empleado_cuenta_dialog.dart';
import 'empleados_utils.dart';
import 'package:flutter/services.dart';

class EmpleadoForm extends StatefulWidget {
  final Empleado? empleado;
  final Map<String, String> sucursales;
  final List<String> roles;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback onCancel;

  const EmpleadoForm({
    Key? key,
    this.empleado,
    required this.sucursales,
    required this.roles,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<EmpleadoForm> createState() => _EmpleadoFormState();
}

class _EmpleadoFormState extends State<EmpleadoForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para los campos del formulario
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _dniController = TextEditingController();
  final _sueldoController = TextEditingController();
  final _celularController = TextEditingController();
  
  // Controladores para el horario
  final _horaInicioHoraController = TextEditingController();
  final _horaInicioMinutoController = TextEditingController();
  final _horaFinHoraController = TextEditingController();
  final _horaFinMinutoController = TextEditingController();
  
  String? _selectedSucursalId;
  String? _selectedRol;
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
    if (widget.empleado != null) {
      _cargarInformacionCuenta();
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
      _nombreController.text = widget.empleado!.nombre;
      _apellidosController.text = widget.empleado!.apellidos;
      _dniController.text = widget.empleado!.dni ?? '';
      _sueldoController.text = widget.empleado!.sueldo?.toString() ?? '';
      _celularController.text = widget.empleado!.celular ?? '';
      
      // Inicializar horarios utilizando la función de utilidad
      EmpleadosUtils.inicializarHorarios(
        horaInicioHoraController: _horaInicioHoraController,
        horaInicioMinutoController: _horaInicioMinutoController,
        horaFinHoraController: _horaFinHoraController,
        horaFinMinutoController: _horaFinMinutoController,
        horaInicio: widget.empleado!.horaInicioJornada,
        horaFin: widget.empleado!.horaFinJornada
      );
      
      _selectedSucursalId = widget.empleado!.sucursalId;
      _selectedRol = EmpleadosUtils.obtenerRolDeEmpleado(widget.empleado!);
      
      // Inicializar el estado del empleado
      _isEmpleadoActivo = widget.empleado!.activo;
    } else {
      _selectedRol = widget.roles.isNotEmpty ? widget.roles.first : null;
      
      // Valores por defecto para horario (8:00 - 17:00) usando la función de utilidad
      EmpleadosUtils.inicializarHorarios(
        horaInicioHoraController: _horaInicioHoraController,
        horaInicioMinutoController: _horaInicioMinutoController,
        horaFinHoraController: _horaFinHoraController,
        horaFinMinutoController: _horaFinMinutoController
      );
      
      // Por defecto, un nuevo empleado está activo
      _isEmpleadoActivo = true;
    }
    
    // Verificar si la sucursal seleccionada es central
    _actualizarEsSucursalCentral();
  }
  
  Future<void> _cargarInformacionCuenta() async {
    if (widget.empleado == null) return;
    
    setState(() {
      _isLoading = true;
      _cuentaNoEncontrada = false;
      _errorCargaInfo = null;
    });
    
    try {
      // Usar la función de utilidad para cargar la información de la cuenta
      final resultado = await EmpleadosUtils.cargarInformacionCuenta(widget.empleado!);
      
      if (mounted) {
        setState(() {
          _usuarioActual = resultado['usuarioActual'] as String?;
          _rolCuentaActual = resultado['rolCuentaActual'] as String?;
          _cuentaNoEncontrada = resultado['cuentaNoEncontrada'] as bool;
          _errorCargaInfo = resultado['errorCargaInfo'] as String?;
        });
      }
    } catch (e) {
      // Para errores en el flujo principal
      debugPrint('Error general al cargar información de cuenta: $e');
      if (mounted) {
        setState(() {
          _errorCargaInfo = 'Error al cargar información: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _actualizarEsSucursalCentral() {
    if (_selectedSucursalId != null) {
      final nombreSucursal = widget.sucursales[_selectedSucursalId] ?? '';
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
    final isSaving = _isLoading && (_errorCargaInfo == null);
    
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.userPlus,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.empleado == null ? 'Nuevo Colaborador' : 'Editar Colaborador',
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
                  children: [
                    // Columna izquierda
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nombreController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              labelStyle: TextStyle(color: Colors.white70),
                              prefixIcon: Icon(Icons.person, color: Colors.white54, size: 20),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'El nombre es requerido';
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
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'DNI',
                              labelStyle: TextStyle(color: Colors.white70),
                              prefixIcon: Icon(Icons.badge, color: Colors.white54, size: 20),
                              counterText: '',
                            ),
                            validator: (value) {
                              if (value != null && value.isNotEmpty && value.length != 8) {
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
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Celular',
                              labelStyle: TextStyle(color: Colors.white70),
                              prefixIcon: Icon(Icons.phone, color: Colors.white54, size: 20),
                              counterText: '',
                            ),
                            validator: (value) {
                              if (value != null && value.isNotEmpty && value.length != 9) {
                                return 'El celular debe tener 9 dígitos';
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
                        children: [
                          TextFormField(
                            controller: _apellidosController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Apellidos',
                              labelStyle: TextStyle(color: Colors.white70),
                              prefixIcon: Icon(Icons.person_outline, color: Colors.white54, size: 20),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Los apellidos son requeridos';
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Sueldo',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixText: 'S/ ',
                    prefixIcon: Icon(Icons.attach_money, color: Colors.white54, size: 20),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final sueldo = double.tryParse(value);
                      if (sueldo == null) {
                        return 'Ingrese un monto válido';
                      }
                      if (sueldo < 0) {
                        return 'El sueldo no puede ser negativo';
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
                  children: [
                    // Rol
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRol,
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: const Color(0xFF2D2D2D),
                        decoration: const InputDecoration(
                          labelText: 'Rol',
                          labelStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.work, color: Colors.white54, size: 20),
                        ),
                        items: widget.roles.map((rol) {
                          IconData iconData;
                          switch (rol.toLowerCase()) {
                            case 'administrador':
                              iconData = FontAwesomeIcons.userGear;
                              break;
                            case 'vendedor':
                              iconData = FontAwesomeIcons.cashRegister;
                              break;
                            case 'computadora':
                              iconData = FontAwesomeIcons.desktop;
                              break;
                            default:
                              iconData = FontAwesomeIcons.user;
                          }
                          
                          return DropdownMenuItem<String>(
                            value: rol,
                            child: Row(
                              children: [
                                FaIcon(iconData, size: 14, color: const Color(0xFFE31E24)),
                                const SizedBox(width: 8),
                                Text(rol),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRol = value;
                          });
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Sucursal
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedSucursalId,
                            style: const TextStyle(color: Colors.white),
                            dropdownColor: const Color(0xFF2D2D2D),
                            decoration: InputDecoration(
                              labelText: 'Sucursal',
                              labelStyle: const TextStyle(color: Colors.white70),
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
                            items: widget.sucursales.entries.map((entry) {
                              final bool esCentral = entry.value.contains('(Central)');
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Row(
                                  children: [
                                    FaIcon(
                                      esCentral ? FontAwesomeIcons.building : FontAwesomeIcons.store,
                                      size: 14,
                                      color: esCentral ? const Color(0xFF4CAF50) : Colors.white54,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      entry.value,
                                      style: TextStyle(
                                        color: esCentral ? const Color(0xFF4CAF50) : Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSucursalId = value;
                                _actualizarEsSucursalCentral();
                              });
                            },
                          ),
                          if (_esSucursalCentral)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
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
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
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
                          children: [
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
                        onChanged: (value) {
                          setState(() => _isEmpleadoActivo = value);
                        },
                        activeColor: const Color(0xFF4CAF50),
                        inactiveThumbColor: const Color(0xFFE31E24),
                        activeTrackColor: const Color(0xFF4CAF50).withOpacity(0.3),
                        inactiveTrackColor: const Color(0xFFE31E24).withOpacity(0.3),
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
                
                // Horario de inicio
                Row(
                  children: [
                    // Etiqueta
                    SizedBox(
                      width: 120,
                      child: Row(
                        children: [
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
                      child: Row(
                        children: [
                          // Horas
                          Expanded(
                            child: TextFormField(
                              controller: _horaInicioHoraController,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'HH',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requerido';
                                }
                                final hora = int.tryParse(value);
                                if (hora == null || hora < 0 || hora > 23) {
                                  return 'Inválido';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                // Formatear a 2 dígitos
                                if (value.length > 2) {
                                  _horaInicioHoraController.text = value.substring(0, 2);
                                  _horaInicioHoraController.selection = TextSelection.fromPosition(
                                    const TextPosition(offset: 2),
                                  );
                                }
                                
                                // Validar rango
                                final hora = int.tryParse(value);
                                if (hora != null && (hora < 0 || hora > 23)) {
                                  _horaInicioHoraController.text = '00';
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
                              controller: _horaInicioMinutoController,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'MM',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requerido';
                                }
                                final minuto = int.tryParse(value);
                                if (minuto == null || minuto < 0 || minuto > 59) {
                                  return 'Inválido';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                // Formatear a 2 dígitos
                                if (value.length > 2) {
                                  _horaInicioMinutoController.text = value.substring(0, 2);
                                  _horaInicioMinutoController.selection = TextSelection.fromPosition(
                                    const TextPosition(offset: 2),
                                  );
                                }
                                
                                // Validar rango
                                final minuto = int.tryParse(value);
                                if (minuto != null && (minuto < 0 || minuto > 59)) {
                                  _horaInicioMinutoController.text = '00';
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Horario de fin
                Row(
                  children: [
                    // Etiqueta
                    SizedBox(
                      width: 120,
                      child: Row(
                        children: [
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
                      child: Row(
                        children: [
                          // Horas
                          Expanded(
                            child: TextFormField(
                              controller: _horaFinHoraController,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'HH',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requerido';
                                }
                                final hora = int.tryParse(value);
                                if (hora == null || hora < 0 || hora > 23) {
                                  return 'Inválido';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                // Formatear a 2 dígitos
                                if (value.length > 2) {
                                  _horaFinHoraController.text = value.substring(0, 2);
                                  _horaFinHoraController.selection = TextSelection.fromPosition(
                                    const TextPosition(offset: 2),
                                  );
                                }
                                
                                // Validar rango
                                final hora = int.tryParse(value);
                                if (hora != null && (hora < 0 || hora > 23)) {
                                  _horaFinHoraController.text = '00';
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
                              controller: _horaFinMinutoController,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'MM',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requerido';
                                }
                                final minuto = int.tryParse(value);
                                if (minuto == null || minuto < 0 || minuto > 59) {
                                  return 'Inválido';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                // Formatear a 2 dígitos
                                if (value.length > 2) {
                                  _horaFinMinutoController.text = value.substring(0, 2);
                                  _horaFinMinutoController.selection = TextSelection.fromPosition(
                                    const TextPosition(offset: 2),
                                  );
                                }
                                
                                // Validar rango
                                final minuto = int.tryParse(value);
                                if (minuto != null && (minuto < 0 || minuto > 59)) {
                                  _horaFinMinutoController.text = '00';
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
                      onPressed: _guardar,
                      child: const Text('Guardar'),
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
      return EmpleadosUtils.buildInfoCuentaContainer(
        isLoading: true
      );
    }
    
    // Si hay un error al cargar la información
    if (_errorCargaInfo != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorCargaInfo!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
    
    // Si no se encontró una cuenta y hay un empleado existente
    if (_cuentaNoEncontrada && widget.empleado != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.triangleExclamation,
                  color: Colors.amber,
                  size: 18,
                ),
                const SizedBox(width: 12),
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
                icon: const FaIcon(
                  FontAwesomeIcons.userPlus,
                  size: 16,
                ),
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
  
  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    
    // Formatear horarios en formato hh:mm:ss
    final horaInicio = '${_horaInicioHoraController.text.padLeft(2, '0')}:${_horaInicioMinutoController.text.padLeft(2, '0')}:00';
    final horaFin = '${_horaFinHoraController.text.padLeft(2, '0')}:${_horaFinMinutoController.text.padLeft(2, '0')}:00';
    
    // Construir datos del empleado
    final empleadoData = {
      'nombre': _nombreController.text,
      'apellidos': _apellidosController.text,
      'dni': _dniController.text,
      'sueldo': _sueldoController.text.isNotEmpty ? double.parse(_sueldoController.text) : null,
      'sucursalId': _selectedSucursalId,
      'rol': _selectedRol,
      'horaInicioJornada': horaInicio,
      'horaFinJornada': horaFin,
      'celular': _celularController.text.isNotEmpty ? _celularController.text : null,
      'activo': _isEmpleadoActivo, // Añadir estado activo/inactivo
    };
    
    // Remover valores nulos
    empleadoData.removeWhere((key, value) => value == null || (value is String && value.isEmpty));
    
    widget.onSave(empleadoData);
  }
  
  Future<void> _gestionarCuenta(BuildContext context) async {
    if (widget.empleado == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Usar la función de utilidad para gestionar la cuenta
      final cuentaActualizada = await EmpleadosUtils.gestionarCuenta(context, widget.empleado!);
      
      if (cuentaActualizada) {
        if (mounted) {
          EmpleadosUtils.mostrarMensaje(
            context,
            mensaje: 'Cuenta actualizada correctamente'
          );
          
          // Recargar información de cuenta
          _cargarInformacionCuenta();
          
          // Resetear estado
          setState(() {
            _cuentaNoEncontrada = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Simplificado: mostrar siempre un mensaje de error genérico
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        EmpleadosUtils.mostrarMensaje(
          context,
          mensaje: 'Error al gestionar cuenta: $errorMsg',
          esError: true
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
