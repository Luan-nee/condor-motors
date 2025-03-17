import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../api/protected/empleados.api.dart';

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
  final _edadController = TextEditingController();
  final _sueldoController = TextEditingController();
  
  // Controladores para el horario
  final _horaInicioHoraController = TextEditingController();
  final _horaInicioMinutoController = TextEditingController();
  final _horaFinHoraController = TextEditingController();
  final _horaFinMinutoController = TextEditingController();
  
  String? _selectedSucursalId;
  String? _selectedRol;
  bool _esSucursalCentral = false;
  
  @override
  void initState() {
    super.initState();
    _inicializarFormulario();
  }
  
  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _dniController.dispose();
    _edadController.dispose();
    _sueldoController.dispose();
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
      _edadController.text = widget.empleado!.edad?.toString() ?? '';
      _sueldoController.text = widget.empleado!.sueldo?.toString() ?? '';
      
      // Inicializar horarios
      _inicializarHorarios(
        widget.empleado!.horaInicioJornada, 
        widget.empleado!.horaFinJornada
      );
      
      _selectedSucursalId = widget.empleado!.sucursalId;
      _selectedRol = _obtenerRolDeEmpleado(widget.empleado!);
    } else {
      _selectedRol = widget.roles.isNotEmpty ? widget.roles.first : null;
      
      // Valores por defecto para horario (8:00 - 17:00)
      _horaInicioHoraController.text = '08';
      _horaInicioMinutoController.text = '00';
      _horaFinHoraController.text = '17';
      _horaFinMinutoController.text = '00';
    }
    
    // Verificar si la sucursal seleccionada es central
    _actualizarEsSucursalCentral();
  }
  
  void _inicializarHorarios(String? horaInicio, String? horaFin) {
    // Inicializar hora de inicio
    if (horaInicio != null && horaInicio.isNotEmpty) {
      final partes = horaInicio.split(':');
      if (partes.length >= 2) {
        _horaInicioHoraController.text = partes[0].padLeft(2, '0');
        _horaInicioMinutoController.text = partes[1].padLeft(2, '0');
      } else {
        _horaInicioHoraController.text = '08';
        _horaInicioMinutoController.text = '00';
      }
    } else {
      _horaInicioHoraController.text = '08';
      _horaInicioMinutoController.text = '00';
    }
    
    // Inicializar hora de fin
    if (horaFin != null && horaFin.isNotEmpty) {
      final partes = horaFin.split(':');
      if (partes.length >= 2) {
        _horaFinHoraController.text = partes[0].padLeft(2, '0');
        _horaFinMinutoController.text = partes[1].padLeft(2, '0');
      } else {
        _horaFinHoraController.text = '17';
        _horaFinMinutoController.text = '00';
      }
    } else {
      _horaFinHoraController.text = '17';
      _horaFinMinutoController.text = '00';
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
  
  String _obtenerRolDeEmpleado(Empleado empleado) {
    // Lógica para determinar el rol del empleado
    // Esta es una implementación simplificada
    if (empleado.id == "13") {
      return "Administrador";
    }
    
    if (empleado.sucursalId == "7") {
      return "Administrador";
    }
    
    final idNum = int.tryParse(empleado.id) ?? 0;
    if (idNum % 2 == 0) {
      return "Vendedor";
    } else {
      return "Computadora";
    }
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
      'edad': _edadController.text.isNotEmpty ? int.parse(_edadController.text) : null,
      'sueldo': _sueldoController.text.isNotEmpty ? double.parse(_sueldoController.text) : null,
      'sucursalId': _selectedSucursalId,
      'rol': _selectedRol,
      'horaInicioJornada': horaInicio,
      'horaFinJornada': horaFin,
    };
    
    // Remover valores nulos
    empleadoData.removeWhere((key, value) => value == null || (value is String && value.isEmpty));
    
    widget.onSave(empleadoData);
  }
  
  @override
  Widget build(BuildContext context) {
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
                            decoration: const InputDecoration(
                              labelText: 'DNI',
                              labelStyle: TextStyle(color: Colors.white70),
                              prefixIcon: Icon(Icons.badge, color: Colors.white54, size: 20),
                            ),
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
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _edadController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Edad',
                              labelStyle: TextStyle(color: Colors.white70),
                              prefixIcon: Icon(Icons.cake, color: Colors.white54, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                
                const SizedBox(height: 16),
                
                // Sueldo
                TextFormField(
                  controller: _sueldoController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sueldo',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixText: 'S/ ',
                    prefixIcon: Icon(Icons.attach_money, color: Colors.white54, size: 20),
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
                
                const SizedBox(height: 24),
                
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
}
