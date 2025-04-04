import 'package:condorsmotors/api/main.api.dart' show ApiException;
import 'package:condorsmotors/providers/admin/index.admin.provider.dart';
import 'package:condorsmotors/widgets/dialogs/confirm_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('empleadoId', empleadoId))
      ..add(StringProperty('empleadoNombre', empleadoNombre))
      ..add(StringProperty('cuentaId', cuentaId))
      ..add(StringProperty('usuarioActual', usuarioActual))
      ..add(IntProperty('rolActualId', rolActualId))
      ..add(IterableProperty<Map<String, dynamic>>('roles', roles))
      ..add(DiagnosticsProperty<bool?>('esNuevaCuenta', esNuevaCuenta));
  }
}

class _EmpleadoCuentaDialogState extends State<EmpleadoCuentaDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _claveController = TextEditingController();
  final TextEditingController _confirmarClaveController =
      TextEditingController();

  bool _isLoading = false;
  bool _ocultarClave = true;
  bool _ocultarConfirmarClave = true;
  String? _errorMessage;
  int? _selectedRolId;
  String? _rolActualNombre;
  late EmpleadoProvider _empleadoProvider;

  // Usar esNuevaCuenta forzado si se proporciona, o determinar automáticamente
  bool get _esNuevaCuenta => widget.esNuevaCuenta ?? widget.cuentaId == null;

  // Colores y estilos comunes
  Color get _primaryColor => _esNuevaCuenta ? Colors.green : Colors.blue;

  // Estilos predefinidos para mejor reutilización
  late final TextStyle _labelStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 13,
    color: _esNuevaCuenta ? Colors.green.shade700 : Colors.blue.shade700,
  );

  late final TextStyle _helperStyle = TextStyle(
    fontStyle: FontStyle.italic,
    fontSize: 11,
    color: _esNuevaCuenta ? Colors.green.shade700 : Colors.blue.shade700,
  );

  late final InputDecoration _inputDecoration = InputDecoration(
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    isDense: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _empleadoProvider = Provider.of<EmpleadoProvider>(context, listen: false);
    });

    // Si es una cuenta existente, inicializar con el usuario actual
    if (widget.usuarioActual != null) {
      _usuarioController.text = widget.usuarioActual!;
    }

    _inicializarRol();
  }

  void _inicializarRol() {
    // Inicializar el rol seleccionado
    if (widget.rolActualId != null) {
      _selectedRolId = widget.rolActualId;
      // Buscar el nombre del rol actual eficientemente
      final Map<String, dynamic> rolActual = widget.roles.firstWhere(
        (Map<String, dynamic> rol) => rol['id'] == widget.rolActualId,
        orElse: () => <String, dynamic>{},
      );
      _rolActualNombre =
          rolActual['nombre'] ?? rolActual['codigo'] ?? 'Rol desconocido';
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
    if (!_validarFormulario()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool success = false;

      if (_esNuevaCuenta) {
        success = await _crearNuevaCuenta();
      } else {
        success = await _actualizarCuentaExistente();
      }

      if (!mounted) {
        return;
      }

      if (success) {
        Navigator.of(context).pop(true); // Cerrar diálogo con resultado exitoso
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No se pudo realizar la operación';
        });
      }
    } catch (e) {
      _manejarError(e);
    }
  }

  Future<bool> _crearNuevaCuenta() async {
    // Crear nueva cuenta usando el provider
    final bool success = await _empleadoProvider.crearCuentaEmpleado(
      empleadoId: widget.empleadoId,
      usuario: _usuarioController.text,
      clave: _claveController.text,
      rolCuentaEmpleadoId: _selectedRolId!,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    }

    return success;
  }

  Future<bool> _actualizarCuentaExistente() async {
    // Solo actualizar si hay datos para actualizar
    if (_usuarioController.text.isNotEmpty ||
        _claveController.text.isNotEmpty) {
      final int? cuentaId = int.tryParse(widget.cuentaId!);
      if (cuentaId == null) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de cuenta inválido',
        );
      }

      final bool success = await _empleadoProvider.actualizarCuentaEmpleado(
        id: cuentaId,
        usuario:
            _usuarioController.text.isNotEmpty ? _usuarioController.text : null,
        clave: _claveController.text.isNotEmpty ? _claveController.text : null,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return success;
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se realizaron cambios'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      return true; // No hay cambios, pero consideramos que fue exitoso
    }
  }

  void _manejarError(e) {
    String errorMsg = e.toString();

    // Mejorar mensajes de error comunes
    if (e is ApiException) {
      switch (e.statusCode) {
        case 401:
          errorMsg = 'Sesión expirada. Inicie sesión nuevamente.';
          break;
        case 400:
          if (e.message.contains('exists') || e.message.contains('ya existe')) {
            errorMsg =
                'El nombre de usuario ya está en uso. Por favor, elija otro.';
          } else {
            errorMsg = 'Error en los datos: ${e.message}';
          }
          break;
        case 403:
          errorMsg = 'No tiene permisos para realizar esta acción.';
          break;
        case 500:
          errorMsg = 'Error en el servidor. Intente nuevamente más tarde.';
          break;
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $errorMsg';
      });
    }
  }

  // Eliminar cuenta
  Future<void> _eliminarCuenta() async {
    if (_esNuevaCuenta) {
      return; // No se puede eliminar una cuenta que no existe
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => ConfirmDialog(
        title: 'Eliminar Cuenta',
        message:
            '¿Está seguro que desea eliminar la cuenta "${widget.usuarioActual}"? Esta acción no se puede deshacer.',
        confirmText: 'Eliminar',
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final int? cuentaId = int.tryParse(widget.cuentaId!);
      if (cuentaId == null) {
        throw ApiException(
          statusCode: 400,
          message: 'ID de cuenta inválido',
        );
      }

      // Usar el provider para eliminar la cuenta
      final bool success =
          await _empleadoProvider.eliminarCuentaEmpleado(cuentaId);

      if (!mounted) {
        return;
      }

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
      _manejarError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = _esNuevaCuenta
        ? 'Crear Cuenta de Usuario'
        : 'Gestionar Cuenta de Usuario';

    final String subtitle = widget.empleadoNombre != null
        ? 'Empleado: ${widget.empleadoNombre}'
        : 'ID Empleado: ${widget.empleadoId}';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(8),
        child:
            _isLoading ? _buildLoadingIndicator() : _buildForm(title, subtitle),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Procesando...'),
        ],
      ),
    );
  }

  Widget _buildForm(String title, String subtitle) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildHeader(title, subtitle),
          const Divider(height: 16),
          if (_errorMessage != null) _buildErrorMessage(),
          _buildInstructions(),
          const SizedBox(height: 10),
          _buildUserFields(),
          const SizedBox(height: 8),
          _buildPasswordFields(),
          const SizedBox(height: 12),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _esNuevaCuenta ? Icons.person_add : Icons.manage_accounts,
            color: _primaryColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _esNuevaCuenta
                          ? Colors.green.shade800
                          : Colors.blue.shade800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[300]!),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.error_outline, color: Colors.red[700], size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red[700], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _esNuevaCuenta ? Colors.green.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _esNuevaCuenta ? Colors.green.shade300 : Colors.blue.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (_esNuevaCuenta)
            _buildNewAccountInstructions()
          else if (_rolActualNombre != null)
            _buildExistingAccountInstructions(),
        ],
      ),
    );
  }

  Widget _buildNewAccountInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.info_outline, color: Colors.green[700], size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Creando cuenta para acceso al sistema',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'El colaborador "${widget.empleadoNombre}" podrá acceder al sistema con las credenciales que defina aquí.',
          style: TextStyle(color: Colors.green[700], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildExistingAccountInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Información actual: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              'Usuario: ${widget.usuarioActual} | Rol: $_rolActualNombre',
              style: TextStyle(color: Colors.blue[700], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Puede modificar el nombre de usuario y/o la contraseña.',
          style: TextStyle(color: Colors.blue[700], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildUserFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _buildUserField(),
        ),
        if (_esNuevaCuenta && widget.roles.isNotEmpty) ...<Widget>[
          const SizedBox(width: 10),
          Expanded(
            child: _buildRoleField(),
          ),
        ],
      ],
    );
  }

  Widget _buildUserField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            'Nombre de usuario',
            style: _labelStyle,
          ),
        ),
        TextFormField(
          controller: _usuarioController,
          decoration: _inputDecoration.copyWith(
            hintText: 'Ingrese un nombre de usuario',
            prefixIcon: const Icon(Icons.person, size: 18),
            helperText: _esNuevaCuenta
                ? 'Usuario para iniciar sesión'
                : 'Nuevo nombre de usuario',
            helperStyle: _helperStyle,
          ),
          validator: _validarUsuario,
        ),
      ],
    );
  }

  String? _validarUsuario(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese un nombre de usuario';
    }
    if (value.length < 4) {
      return 'Mínimo 4 caracteres';
    }
    if (value.length > 20) {
      return 'Máximo 20 caracteres';
    }
    if (!RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(value)) {
      return 'Solo letras, números, guiones y guiones bajos';
    }
    return null;
  }

  Widget _buildRoleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            'Rol del usuario',
            style: _labelStyle,
          ),
        ),
        DropdownButtonFormField<int>(
          value: _selectedRolId,
          decoration: _inputDecoration.copyWith(
            hintText: 'Seleccione un rol',
            prefixIcon: const Icon(Icons.badge, size: 18),
            helperText: 'Define permisos en el sistema',
            helperStyle: _helperStyle,
          ),
          items: widget.roles.map((Map<String, dynamic> rol) {
            return DropdownMenuItem<int>(
              value: rol['id'],
              child: Text(
                rol['nombre'] ?? rol['codigo'] ?? 'Rol sin nombre',
                style: const TextStyle(fontSize: 13),
              ),
            );
          }).toList(),
          onChanged: (int? value) {
            setState(() {
              _selectedRolId = value;
            });
          },
          validator: (int? value) {
            if (value == null) {
              return 'Seleccione un rol';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _buildPasswordField(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildConfirmPasswordField(),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            'Contraseña',
            style: _labelStyle,
          ),
        ),
        TextFormField(
          controller: _claveController,
          obscureText: _ocultarClave,
          decoration: _inputDecoration.copyWith(
            hintText: _esNuevaCuenta
                ? 'Ingrese contraseña segura'
                : 'Nueva contraseña (opcional)',
            prefixIcon: const Icon(Icons.lock, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                _ocultarClave ? Icons.visibility : Icons.visibility_off,
                size: 18,
              ),
              onPressed: () {
                setState(() {
                  _ocultarClave = !_ocultarClave;
                });
              },
            ),
            helperText: _esNuevaCuenta
                ? 'Mín. 6 caracteres con 1 número'
                : 'Vacío = no cambiar',
            helperStyle: _helperStyle,
          ),
          validator: _validarClave,
        ),
      ],
    );
  }

  String? _validarClave(String? value) {
    if (_esNuevaCuenta && (value == null || value.isEmpty)) {
      return 'Ingrese una contraseña';
    }
    if (value != null && value.isNotEmpty) {
      if (value.length < 6) {
        return 'Mínimo 6 caracteres';
      }
      if (value.length > 20) {
        return 'Máximo 20 caracteres';
      }
      if (!RegExp(r'\d').hasMatch(value)) {
        return 'Debe contener al menos un número';
      }
    }
    return null;
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            'Confirmar contraseña',
            style: _labelStyle,
          ),
        ),
        TextFormField(
          controller: _confirmarClaveController,
          obscureText: _ocultarConfirmarClave,
          decoration: _inputDecoration.copyWith(
            hintText: 'Confirme la contraseña',
            prefixIcon: const Icon(Icons.lock_outline, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                _ocultarConfirmarClave
                    ? Icons.visibility
                    : Icons.visibility_off,
                size: 18,
              ),
              onPressed: () {
                setState(() {
                  _ocultarConfirmarClave = !_ocultarConfirmarClave;
                });
              },
            ),
            helperText: 'Debe coincidir con la contraseña',
            helperStyle: _helperStyle,
          ),
          validator: (String? value) {
            if (_claveController.text.isNotEmpty &&
                value != _claveController.text) {
              return 'Las contraseñas no coinciden';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        // Botón para eliminar cuenta (solo para cuentas existentes)
        if (!_esNuevaCuenta)
          TextButton.icon(
            icon: const FaIcon(
              FontAwesomeIcons.trash,
              size: 14,
              color: Colors.red,
            ),
            label: const Text(
              'Eliminar cuenta',
              style: TextStyle(color: Colors.red, fontSize: 13),
            ),
            onPressed: _eliminarCuenta,
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
            ),
          )
        else
          const SizedBox.shrink(),

        Row(
          children: <Widget>[
            // Botón para cancelar
            TextButton.icon(
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Cancelar', style: TextStyle(fontSize: 13)),
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),

            // Botón para guardar
            ElevatedButton.icon(
              icon: FaIcon(
                _esNuevaCuenta
                    ? FontAwesomeIcons.userPlus
                    : FontAwesomeIcons.floppyDisk,
                size: 14,
              ),
              label: Text(
                _esNuevaCuenta ? 'Crear Cuenta' : 'Guardar Cambios',
                style: const TextStyle(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              onPressed: _guardarCuenta,
            ),
          ],
        ),
      ],
    );
  }
}
