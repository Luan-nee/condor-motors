import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../main.dart' show api;
import '../../../widgets/dialogs/confirm_dialog.dart';

/// Diálogo para gestionar la cuenta de un empleado
/// 
/// Permite crear una nueva cuenta o actualizar una existente (cambiar usuario y/o clave)
class EmpleadoCuentaDialog extends StatefulWidget {
  final String empleadoId;
  final String? empleadoNombre;
  final String? cuentaId;
  final String? usuarioActual;
  final int? rolActualId;
  final List<Map<String, dynamic>> roles;
  
  const EmpleadoCuentaDialog({
    super.key,
    required this.empleadoId,
    this.empleadoNombre,
    this.cuentaId,
    this.usuarioActual,
    this.rolActualId,
    required this.roles,
  });

  @override
  State<EmpleadoCuentaDialog> createState() => _EmpleadoCuentaDialogState();
}

class _EmpleadoCuentaDialogState extends State<EmpleadoCuentaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _claveController = TextEditingController();
  final _confirmarClaveController = TextEditingController();
  
  bool _isLoading = false;
  bool _ocultarClave = true;
  bool _ocultarConfirmarClave = true;
  String? _errorMessage;
  int? _selectedRolId;
  String? _rolActualNombre;
  
  bool get _esNuevaCuenta => widget.cuentaId == null;
  
  @override
  void initState() {
    super.initState();
    
    // Si es una cuenta existente, inicializar con el usuario actual
    if (widget.usuarioActual != null) {
      _usuarioController.text = widget.usuarioActual!;
    }
    
    // Inicializar el rol seleccionado
    if (widget.rolActualId != null) {
      _selectedRolId = widget.rolActualId;
      // Buscar el nombre del rol actual
      final rolActual = widget.roles.firstWhere(
        (rol) => rol['id'] == widget.rolActualId,
        orElse: () => <String, dynamic>{},
      );
      _rolActualNombre = rolActual['nombre'] ?? rolActual['codigo'] ?? 'Rol desconocido';
    } else if (widget.roles.isNotEmpty) {
      // Si no hay rol actual pero hay roles disponibles, seleccionar el primero por defecto
      _selectedRolId = widget.roles.first['id'];
    }
  }
  
  @override
  void dispose() {
    _usuarioController.dispose();
    _claveController.dispose();
    _confirmarClaveController.dispose();
    super.dispose();
  }
  
  // Validar el formulario
  bool _validarFormulario() {
    // Limpiar mensaje de error previo
    setState(() => _errorMessage = null);
    
    // Validar campos del formulario
    if (!_formKey.currentState!.validate()) {
      return false;
    }
    
    // Validar que se haya seleccionado un rol (solo para nuevas cuentas)
    if (_esNuevaCuenta && _selectedRolId == null) {
      setState(() => _errorMessage = 'Debe seleccionar un rol para la cuenta');
      return false;
    }
    
    // Validar que las contraseñas coincidan
    if (_claveController.text.isNotEmpty && 
        _claveController.text != _confirmarClaveController.text) {
      setState(() => _errorMessage = 'Las contraseñas no coinciden');
      return false;
    }
    
    return true;
  }
  
  // Guardar la cuenta (crear nueva o actualizar existente)
  Future<void> _guardarCuenta() async {
    if (!_validarFormulario()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      if (_esNuevaCuenta) {
        // Crear nueva cuenta
        await api.empleados.registerEmpleadoAccount(
          empleadoId: widget.empleadoId,
          usuario: _usuarioController.text,
          clave: _claveController.text,
          rolCuentaEmpleadoId: _selectedRolId!,
        );
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Actualizar cuenta existente
        final Map<String, dynamic> updateData = {};
        
        // Solo incluir usuario si ha cambiado
        if (_usuarioController.text != widget.usuarioActual) {
          updateData['usuario'] = _usuarioController.text;
        }
        
        // Solo incluir clave si se ha ingresado una nueva
        if (_claveController.text.isNotEmpty) {
          updateData['clave'] = _claveController.text;
        }
        
        // Solo actualizar si hay datos para actualizar
        if (updateData.isNotEmpty) {
          await api.empleados.updateCuentaEmpleado(
            cuentaId: widget.cuentaId!,
            usuario: updateData['usuario'],
            clave: updateData['clave'],
          );
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cuenta actualizada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
      if (!mounted) return;
      Navigator.of(context).pop(true); // Cerrar diálogo con resultado exitoso
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }
  
  // Eliminar cuenta
  Future<void> _eliminarCuenta() async {
    if (_esNuevaCuenta) return; // No se puede eliminar una cuenta que no existe
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Eliminar Cuenta',
        message: '¿Está seguro que desea eliminar la cuenta "${widget.usuarioActual}"? Esta acción no se puede deshacer.',
        confirmText: 'Eliminar',
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final success = await api.empleados.deleteCuentaEmpleado(widget.cuentaId!);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta eliminada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Cerrar diálogo con resultado exitoso
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No se pudo eliminar la cuenta';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _esNuevaCuenta 
        ? 'Crear Cuenta de Usuario' 
        : 'Gestionar Cuenta de Usuario';
    
    final subtitle = widget.empleadoNombre != null 
        ? 'Empleado: ${widget.empleadoNombre}'
        : 'ID Empleado: ${widget.empleadoId}';
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Procesando...'),
                  ],
                ),
              )
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título y subtítulo
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Mensaje de error (si existe)
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Información de cuenta actual (si existe)
                    if (!_esNuevaCuenta) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Información de cuenta actual',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Usuario: ${widget.usuarioActual}',
                                    style: TextStyle(color: Colors.blue[700]),
                                  ),
                                ),
                                if (_rolActualNombre != null)
                                  Expanded(
                                    child: Text(
                                      'Rol: $_rolActualNombre',
                                      style: TextStyle(color: Colors.blue[700]),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Campo de usuario (deshabilitado si es una cuenta existente)
                    TextFormField(
                      controller: _usuarioController,
                      enabled: _esNuevaCuenta, // Solo permitir edición si es nueva cuenta
                      decoration: InputDecoration(
                        labelText: 'Nombre de usuario',
                        hintText: _esNuevaCuenta 
                            ? 'Ingrese un nombre de usuario' 
                            : 'No se puede modificar el usuario',
                        prefixIcon: const Icon(Icons.person),
                        helperText: !_esNuevaCuenta 
                            ? 'El nombre de usuario no se puede modificar' 
                            : null,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un nombre de usuario';
                        }
                        if (value.length < 4) {
                          return 'El usuario debe tener al menos 4 caracteres';
                        }
                        if (value.length > 20) {
                          return 'El usuario debe tener máximo 20 caracteres';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(value)) {
                          return 'El usuario solo puede contener letras, números, guiones y guiones bajos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo de contraseña (requerido para nuevas cuentas, opcional para actualizar)
                    TextFormField(
                      controller: _claveController,
                      obscureText: _ocultarClave,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        hintText: _esNuevaCuenta 
                            ? 'Ingrese una contraseña' 
                            : 'Ingrese nueva contraseña para cambiarla',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _ocultarClave ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _ocultarClave = !_ocultarClave;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (_esNuevaCuenta && (value == null || value.isEmpty)) {
                          return 'Por favor ingrese una contraseña';
                        }
                        if (value != null && value.isNotEmpty) {
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          if (value.length > 20) {
                            return 'La contraseña debe tener máximo 20 caracteres';
                          }
                          if (!RegExp(r'\d').hasMatch(value)) {
                            return 'La contraseña debe contener al menos un número';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo para confirmar contraseña
                    TextFormField(
                      controller: _confirmarClaveController,
                      obscureText: _ocultarConfirmarClave,
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        hintText: _esNuevaCuenta 
                            ? 'Confirme la contraseña' 
                            : 'Confirme la nueva contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _ocultarConfirmarClave ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _ocultarConfirmarClave = !_ocultarConfirmarClave;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (_claveController.text.isNotEmpty && value != _claveController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Selector de rol (solo para nuevas cuentas)
                    if (_esNuevaCuenta && widget.roles.isNotEmpty) ...[
                      DropdownButtonFormField<int>(
                        value: _selectedRolId,
                        decoration: const InputDecoration(
                          labelText: 'Rol',
                          hintText: 'Seleccione un rol',
                          prefixIcon: Icon(Icons.badge),
                        ),
                        items: widget.roles.map((rol) {
                          return DropdownMenuItem<int>(
                            value: rol['id'],
                            child: Text(rol['nombre'] ?? rol['codigo'] ?? 'Rol sin nombre'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRolId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Por favor seleccione un rol';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Botones de acción
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Botón para eliminar cuenta (solo para cuentas existentes)
                        if (!_esNuevaCuenta)
                          TextButton.icon(
                            icon: const FaIcon(
                              FontAwesomeIcons.trash,
                              size: 16,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed: _eliminarCuenta,
                          )
                        else
                          const SizedBox.shrink(),
                          
                        Row(
                          children: [
                            // Botón para cancelar
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 16),
                            
                            // Botón para guardar
                            ElevatedButton(
                              onPressed: _guardarCuenta,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(_esNuevaCuenta ? 'Crear Cuenta' : 'Guardar Cambios'),
                            ),
                          ],
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