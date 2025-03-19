import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../main.dart' show api;
import '../../../widgets/dialogs/confirm_dialog.dart';
import '../../../api/main.api.dart' show ApiException;

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
  final bool? esNuevaCuenta; // Permite forzar el modo de creación
  
  const EmpleadoCuentaDialog({
    super.key,
    required this.empleadoId,
    this.empleadoNombre,
    this.cuentaId,
    this.usuarioActual,
    this.rolActualId,
    required this.roles,
    this.esNuevaCuenta,
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
  
  // Usar esNuevaCuenta forzado si se proporciona, o determinar automáticamente
  bool get _esNuevaCuenta => widget.esNuevaCuenta ?? widget.cuentaId == null;
  
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
        // Crear nueva cuenta - usar la nueva API
        await api.cuentasEmpleados.registerEmpleadoAccount(
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
        // Actualizar cuenta existente - usar la nueva API
        final Map<String, dynamic> updateData = {};
        
        // Incluir usuario siempre que se haya proporcionado uno
        if (_usuarioController.text.isNotEmpty) {
          updateData['usuario'] = _usuarioController.text;
        }
        
        // Solo actualizar si hay datos para actualizar
        if (updateData.isNotEmpty || _claveController.text.isNotEmpty) {
          final cuentaId = int.tryParse(widget.cuentaId!);
          if (cuentaId == null) {
            throw ApiException(
              statusCode: 400,
              message: 'ID de cuenta inválido',
            );
          }
          
          await api.cuentasEmpleados.updateCuentaEmpleado(
            id: cuentaId,
            usuario: updateData['usuario'],
            // Si hay una clave nueva, se enviará para actualización
            clave: _claveController.text.isNotEmpty ? _claveController.text : null,
            rolCuentaEmpleadoId: null, // No modificamos el rol en la actualización
          );
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cuenta actualizada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se realizaron cambios'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
      
      if (!mounted) return;
      Navigator.of(context).pop(true); // Cerrar diálogo con resultado exitoso
    } catch (e) {
      String errorMsg = e.toString();
      
      // Mejorar mensajes de error comunes
      if (e is ApiException) {
        if (e.statusCode == 401) {
          errorMsg = 'Sesión expirada. Inicie sesión nuevamente.';
        } else if (e.statusCode == 400) {
          if (e.message.contains('exists') || e.message.contains('ya existe')) {
            errorMsg = 'El nombre de usuario ya está en uso. Por favor, elija otro.';
          } else {
            errorMsg = 'Error en los datos: ${e.message}';
          }
        } else if (e.statusCode == 403) {
          errorMsg = 'No tiene permisos para realizar esta acción.';
        } else if (e.statusCode == 500) {
          errorMsg = 'Error en el servidor. Intente nuevamente más tarde.';
        }
      }
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $errorMsg';
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
      final cuentaId = int.tryParse(widget.cuentaId!);
      if (cuentaId == null) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de cuenta inválido',
        );
      }
      
      // Usar la nueva API para eliminar la cuenta
      final success = await api.cuentasEmpleados.deleteCuentaEmpleado(cuentaId);
      
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
      String errorMsg = e.toString();
      
      // Mejorar mensajes de error comunes
      if (e is ApiException) {
        if (e.statusCode == 401) {
          errorMsg = 'Sesión expirada. Inicie sesión nuevamente.';
        } else if (e.statusCode == 403) {
          errorMsg = 'No tiene permisos para eliminar esta cuenta.';
        } else if (e.statusCode == 500) {
          errorMsg = 'Error en el servidor. Intente nuevamente más tarde.';
        }
      }
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $errorMsg';
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
        width: 500, // Aumentado ligeramente para mejor visualización
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
                    // Cabecera - título y subtítulo con iconos
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _esNuevaCuenta ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _esNuevaCuenta ? Icons.person_add : Icons.manage_accounts,
                            color: _esNuevaCuenta ? Colors.green : Colors.blue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _esNuevaCuenta ? Colors.green[800] : Colors.blue[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    
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
                    
                    // Instrucciones para el usuario
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _esNuevaCuenta ? Colors.green[50] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _esNuevaCuenta ? Colors.green[300]! : Colors.blue[300]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_esNuevaCuenta) ...[
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.green[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Creando cuenta para acceso al sistema',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'El colaborador "${widget.empleadoNombre}" podrá acceder al sistema con las credenciales que defina aquí. Seleccione un rol apropiado según sus funciones.',
                              style: TextStyle(color: Colors.green[700]),
                            ),
                          ] else ...[
                            if (_rolActualNombre != null) ...[
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue[700]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Información de cuenta actual',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(color: Colors.blue[700]),
                                        children: [
                                          const TextSpan(
                                            text: 'Usuario: ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(text: widget.usuarioActual),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_rolActualNombre != null)
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(color: Colors.blue[700]),
                                          children: [
                                            const TextSpan(
                                              text: 'Rol: ',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            TextSpan(text: _rolActualNombre),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Puede modificar el nombre de usuario y/o la contraseña. Si no desea cambiar la contraseña, deje esos campos vacíos.',
                                style: TextStyle(color: Colors.blue[700]),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Campos del formulario
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Campo de usuario
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 8),
                              child: Text(
                                'Nombre de usuario',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _esNuevaCuenta ? Colors.green[700] : Colors.blue[700],
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: _usuarioController,
                              decoration: InputDecoration(
                                hintText: 'Ingrese un nombre de usuario',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                helperText: _esNuevaCuenta 
                                  ? 'Este será el nombre para iniciar sesión'
                                  : 'Nuevo nombre de usuario',
                                helperStyle: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: _esNuevaCuenta ? Colors.green[700] : Colors.blue[700],
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: _esNuevaCuenta ? Colors.green : Colors.blue,
                                    width: 2,
                                  ),
                                ),
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
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Selector de rol (solo para nuevas cuentas)
                        if (_esNuevaCuenta && widget.roles.isNotEmpty) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 8),
                                child: Text(
                                  'Rol del usuario',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                              DropdownButtonFormField<int>(
                                value: _selectedRolId,
                                decoration: InputDecoration(
                                  hintText: 'Seleccione un rol',
                                  prefixIcon: const Icon(Icons.badge),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  helperText: 'Determina qué acciones podrá realizar en el sistema',
                                  helperStyle: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.green[700],
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.green,
                                      width: 2,
                                    ),
                                  ),
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
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Sección de Contraseña
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 8),
                              child: Text(
                                'Contraseña',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _esNuevaCuenta ? Colors.green[700] : Colors.blue[700],
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: _claveController,
                              obscureText: _ocultarClave,
                              decoration: InputDecoration(
                                hintText: _esNuevaCuenta 
                                    ? 'Ingrese una contraseña segura' 
                                    : 'Nueva contraseña (opcional)',
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
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                helperText: _esNuevaCuenta 
                                  ? 'Mínimo 6 caracteres con al menos un número'
                                  : 'Dejar vacío si no desea cambiarla',
                                helperStyle: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: _esNuevaCuenta ? Colors.green[700] : Colors.blue[700],
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: _esNuevaCuenta ? Colors.green : Colors.blue,
                                    width: 2,
                                  ),
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
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Campo para confirmar contraseña
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 8),
                              child: Text(
                                'Confirmación de contraseña',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _esNuevaCuenta ? Colors.green[700] : Colors.blue[700],
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: _confirmarClaveController,
                              obscureText: _ocultarConfirmarClave,
                              decoration: InputDecoration(
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
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                helperText: 'Debe coincidir con la contraseña ingresada',
                                helperStyle: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: _esNuevaCuenta ? Colors.green[700] : Colors.blue[700],
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: _esNuevaCuenta ? Colors.green : Colors.blue,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (_claveController.text.isNotEmpty && value != _claveController.text) {
                                  return 'Las contraseñas no coinciden';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
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
                              'Eliminar cuenta',
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed: _eliminarCuenta,
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                          
                        Row(
                          children: [
                            // Botón para cancelar
                            TextButton.icon(
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Cancelar'),
                              onPressed: () => Navigator.of(context).pop(false),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Botón para guardar
                            ElevatedButton.icon(
                              icon: FaIcon(
                                _esNuevaCuenta ? FontAwesomeIcons.userPlus : FontAwesomeIcons.floppyDisk,
                                size: 16,
                              ),
                              label: Text(_esNuevaCuenta ? 'Crear Cuenta' : 'Guardar Cambios'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _esNuevaCuenta ? Colors.green : Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: _guardarCuenta,
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