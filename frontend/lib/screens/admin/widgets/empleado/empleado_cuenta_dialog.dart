import 'package:condorsmotors/api/main.api.dart' show ApiException;
import 'package:condorsmotors/models/empleado.model.dart';
import 'package:condorsmotors/repositories/empleado.repository.dart';
import 'package:condorsmotors/utils/empleados_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Diálogo para gestionar la cuenta de un empleado
///
/// Permite crear una nueva cuenta o actualizar una existente (cambiar usuario y/o clave)
class EmpleadoCuentaDialog extends StatefulWidget {
  final Empleado empleado;
  final List<Map<String, dynamic>> roles;
  final bool? esNuevaCuenta; // Permite forzar el modo de creación
  final VoidCallback? onRefresh; // Callback para refrescar la lista

  const EmpleadoCuentaDialog({
    super.key,
    required this.empleado,
    required this.roles,
    this.esNuevaCuenta,
    this.onRefresh,
  });

  @override
  State<EmpleadoCuentaDialog> createState() => _EmpleadoCuentaDialogState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Empleado>('empleado', empleado))
      ..add(IterableProperty<Map<String, dynamic>>('roles', roles))
      ..add(DiagnosticsProperty<bool?>('esNuevaCuenta', esNuevaCuenta))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onRefresh', onRefresh));
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
  late final EmpleadoRepository _empleadoRepository;

  // Constantes de colores para tema oscuro con rojo
  static const Color colorPrimario = Color(0xFFE31E24); // Rojo TiendaPeru

  // Determinar si es una nueva cuenta o actualización
  bool get _esNuevaCuenta =>
      widget.esNuevaCuenta ?? !widget.empleado.tieneCuenta;

  @override
  void initState() {
    super.initState();
    _empleadoRepository = EmpleadoRepository.instance;

    // Para cuentas existentes, obtener el ID del rol actual
    if (!_esNuevaCuenta) {
      _cargarDatosRolActual();
    }

    // Inicializar formulario con datos existentes si aplica
    _inicializarFormulario();
  }

  void _inicializarFormulario() {
    // Inicializar nombre de usuario si existe
    if (widget.empleado.cuentaEmpleadoUsuario != null) {
      _usuarioController.text = widget.empleado.cuentaEmpleadoUsuario!;
    }

    // Inicializar información de rol
    _inicializarRol();
  }

  void _inicializarRol() {
    // Primero intentar usar el rol del modelo Empleado
    if (widget.empleado.rol != null) {
      // Buscar ese rol en la lista de roles disponibles
      final Map<String, dynamic> rolMatch = widget.roles.firstWhere(
        (Map<String, dynamic> rol) =>
            rol['codigo'] == widget.empleado.rol!.codigo ||
            rol['nombre'] == widget.empleado.rol!.nombre ||
            rol['nombreRol'] == widget.empleado.rol!.nombre,
        orElse: () =>
            widget.roles.isNotEmpty ? widget.roles.first : <String, dynamic>{},
      );

      if (rolMatch.isNotEmpty) {
        _selectedRolId = rolMatch['id'];
        _rolActualNombre = widget.empleado.rol!.nombre;
      }
    }
    // Si no tiene rol asignado y hay roles disponibles, usar el primero por defecto
    else if (widget.roles.isNotEmpty) {
      _selectedRolId = widget.roles.first['id'];
      _rolActualNombre =
          widget.roles.first['nombreRol'] ?? widget.roles.first['nombre'];
    }
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _claveController.dispose();
    _confirmarClaveController.dispose();
    super.dispose();
  }

  // Validar todos los campos del formulario
  bool _validarFormulario() {
    // Limpiar mensaje de error previo
    setState(() => _errorMessage = null);

    // Validar campos usando el FormState
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    // Validar rol seleccionado (solo para nuevas cuentas)
    if (_esNuevaCuenta && _selectedRolId == null) {
      setState(() => _errorMessage = 'Debe seleccionar un rol para la cuenta');
      return false;
    }

    // Validar coincidencia de contraseñas
    final String? errorConfirmacion = _validarConfirmacionClave(
        _confirmarClaveController.text, _claveController.text);

    if (errorConfirmacion != null) {
      setState(() => _errorMessage = errorConfirmacion);
      return false;
    }

    return true;
  }

  // Validar confirmación de clave
  String? _validarConfirmacionClave(String? confirmacion, String clave) {
    if (confirmacion == null || confirmacion.isEmpty) {
      return 'Debe confirmar la contraseña';
    }
    if (confirmacion != clave) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  // Validar usuario
  String? _validarUsuario(String? usuario) {
    if (usuario == null || usuario.isEmpty) {
      return 'El nombre de usuario es obligatorio';
    }
    if (usuario.length < 3) {
      return 'El nombre de usuario debe tener al menos 3 caracteres';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(usuario)) {
      return 'El nombre de usuario solo puede contener letras, números y guiones bajos';
    }
    return null;
  }

  // Validar clave
  String? _validarClave(String? clave, {bool esRequerida = true}) {
    if (esRequerida && (clave == null || clave.isEmpty)) {
      return 'La contraseña es obligatoria';
    }
    if (clave != null && clave.isNotEmpty && clave.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (clave != null &&
        clave.isNotEmpty &&
        !RegExp(r'.*\d.*').hasMatch(clave)) {
      return 'La contraseña debe contener al menos un número';
    }
    return null;
  }

  // Método principal para guardar la cuenta
  Future<void> _guardarCuenta() async {
    // Validar formulario antes de continuar
    if (!_validarFormulario()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool success = false;

      // Determinar si es crear o actualizar
      if (_esNuevaCuenta) {
        success = await _crearNuevaCuenta();
      } else {
        success = await _actualizarCuentaExistente();
      }

      if (!mounted) {
        return;
      }

      if (success) {
        // Mostrar confirmación y cerrar diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_esNuevaCuenta
                ? 'Cuenta creada exitosamente'
                : 'Cuenta actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Refrescar la lista de empleados antes de cerrar
        widget.onRefresh?.call();

        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'No se pudo ${_esNuevaCuenta ? "crear" : "actualizar"} la cuenta';
        });
      }
    } catch (e) {
      _manejarError(e);
    }
  }

  // Crear una nueva cuenta
  Future<bool> _crearNuevaCuenta() async {
    if (_selectedRolId == null) {
      setState(() {
        _errorMessage = 'Debe seleccionar un rol para la cuenta';
      });
      return false;
    }

    try {
      // Usar el repository para crear la cuenta
      final Map<String, dynamic> resultado =
          await _empleadoRepository.registerEmpleadoAccount(
        empleadoId: widget.empleado.id,
        usuario: _usuarioController.text,
        clave: _claveController.text,
        rolCuentaEmpleadoId: _selectedRolId!,
      );

      // La API devuelve los datos de la cuenta creada directamente
      // Si llegamos aquí sin excepción, la cuenta se creó exitosamente
      return resultado.isNotEmpty;
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      return false;
    }
  }

  // Actualizar una cuenta existente
  Future<bool> _actualizarCuentaExistente() async {
    try {
      // Obtener la cuenta actual del empleado
      final Map<String, dynamic>? cuentaActual =
          await _empleadoRepository.getCuentaByEmpleadoId(widget.empleado.id);

      if (cuentaActual == null) {
        setState(() {
          _errorMessage =
              'No se encontró la cuenta del empleado. Es posible que el empleado no tenga cuenta asociada.';
        });
        return false;
      }

      final int cuentaId = cuentaActual['id'];
      final String? nuevoUsuario =
          _usuarioController.text.isNotEmpty ? _usuarioController.text : null;
      final String? nuevaClave =
          _claveController.text.isNotEmpty ? _claveController.text : null;

      // Usar el repository para actualizar la cuenta
      final Map<String, dynamic> resultado =
          await _empleadoRepository.updateCuentaEmpleado(
        id: cuentaId,
        usuario: nuevoUsuario,
        clave: nuevaClave,
        rolCuentaEmpleadoId: _selectedRolId,
      );

      // La API devuelve los datos actualizados directamente
      // Si llegamos aquí sin excepción, la cuenta se actualizó exitosamente
      return resultado.isNotEmpty;
    } catch (e) {
      // Manejar específicamente el caso de empleado sin cuenta
      if (e.toString().contains('404') ||
          e.toString().contains('Not found') ||
          e.toString().contains('no tiene cuenta asociada')) {
        setState(() {
          _errorMessage =
              'El empleado no tiene cuenta asociada. Use "Crear Cuenta" en su lugar.';
        });
      } else {
        setState(() {
          _errorMessage = e.toString();
        });
      }
      return false;
    }
  }

  // Manejar errores de forma amigable
  void _manejarError(e) {
    String errorMsg = e.toString();

    // Mejorar mensajes de error comunes
    if (e is ApiException) {
      switch (e.statusCode) {
        case 401:
          errorMsg = 'Sesión expirada. Inicie sesión nuevamente.';
        case 400:
          if (e.message.contains('exists') || e.message.contains('ya existe')) {
            errorMsg =
                'El nombre de usuario ya está en uso. Por favor, elija otro.';
          } else {
            errorMsg = 'Error en los datos: ${e.message}';
          }
        case 403:
          errorMsg = 'No tiene permisos para realizar esta acción.';
        case 404:
          errorMsg = 'No se encontró la cuenta o empleado especificado.';
        case 500:
          errorMsg = 'Error en el servidor. Intente nuevamente más tarde.';
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $errorMsg';
      });
    }
  }

  // Eliminar cuenta existente
  Future<void> _eliminarCuenta() async {
    // Solicitar confirmación antes de eliminar
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Icono de advertencia
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const FaIcon(
                  FontAwesomeIcons.triangleExclamation,
                  color: Colors.red,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              // Título con advertencia
              const Text(
                '¿Eliminar cuenta de usuario?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Mensaje de confirmación
              Text(
                'La cuenta del colaborador "${EmpleadosUtils.getNombreCompleto(widget.empleado)}" será eliminada permanentemente y no podrá iniciar sesión en el sistema.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Botón cancelar
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 16),
                  // Botón confirmar
                  ElevatedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.trash, size: 14),
                    label: const Text('Eliminar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Si no confirma, salir temprano
    if (confirmar != true) {
      return;
    }

    // Mostrar indicador de carga
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Obtener la cuenta actual del empleado
      final Map<String, dynamic>? cuentaActual =
          await _empleadoRepository.getCuentaByEmpleadoId(widget.empleado.id);

      if (cuentaActual == null) {
        setState(() {
          _errorMessage =
              'No se encontró la cuenta del empleado. Es posible que el empleado no tenga cuenta asociada.';
          _isLoading = false;
        });
        return;
      }

      final int cuentaId = cuentaActual['id'];

      // Usar el repository para eliminar la cuenta
      final bool success =
          await _empleadoRepository.deleteCuentaEmpleado(cuentaId);

      if (!mounted) {
        return;
      }

      if (success) {
        // Notificar éxito y cerrar diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta eliminada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = 'No se pudo eliminar la cuenta';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      // Manejar específicamente el caso de empleado sin cuenta
      if (e.toString().contains('404') ||
          e.toString().contains('Not found') ||
          e.toString().contains('no tiene cuenta asociada')) {
        setState(() {
          _errorMessage = 'El empleado no tiene cuenta asociada para eliminar.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Error al eliminar cuenta: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  // Método para cargar el ID del rol actual usando el repository
  Future<void> _cargarDatosRolActual() async {
    try {
      final Map<String, dynamic>? cuentaInfo =
          await _empleadoRepository.getCuentaByEmpleadoId(widget.empleado.id);

      if (cuentaInfo != null &&
          cuentaInfo['rolCuentaEmpleadoId'] != null &&
          mounted) {
        setState(() {
          _selectedRolId = cuentaInfo['rolCuentaEmpleadoId'] as int;
        });
      }
    } catch (e) {
      // El empleado no tiene cuenta (404) - esto es normal para empleados sin cuenta
      if (e.toString().contains('404') ||
          e.toString().contains('Not found') ||
          e.toString().contains('no tiene cuenta asociada')) {
        debugPrint(
            'Empleado ${widget.empleado.id} no tiene cuenta asociada (normal)');
        // No es un error, es el comportamiento esperado
        return;
      } else {
        // Solo loggear errores reales
        debugPrint('Error al cargar datos del rol: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = _esNuevaCuenta
        ? 'Crear Cuenta de Usuario'
        : 'Gestionar Cuenta de Usuario';

    final String subtitle =
        'Empleado: ${EmpleadosUtils.getNombreCompleto(widget.empleado)}';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 15,
              spreadRadius: 5,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _isLoading
              ? _buildLoadingIndicator()
              : _buildForm(title, subtitle),
        ),
      ),
    );
  }

  // Indicador de carga con animación
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      color: const Color(0xFF1A1A1A),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            height: 80,
            width: 80,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(colorPrimario),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Procesando solicitud...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _esNuevaCuenta
                ? 'Creando cuenta de usuario'
                : 'Actualizando información de cuenta',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // Construir formulario completo con tema oscuro
  Widget _buildForm(String title, String subtitle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildHeader(title, subtitle),
        if (_errorMessage != null) _buildErrorMessage(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInstructions(),
                  const SizedBox(height: 24),
                  _buildUserFields(),
                  const SizedBox(height: 24),
                  _buildPasswordFields(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Encabezado con tema estilo empleado_form
  Widget _buildHeader(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFE31E24),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(
              _esNuevaCuenta
                  ? FontAwesomeIcons.userPlus
                  : FontAwesomeIcons.userGear,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mensaje de error con tema oscuro
  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade700),
      ),
      child: Row(
        children: <Widget>[
          const FaIcon(FontAwesomeIcons.circleExclamation,
              color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.xmark,
                color: Colors.red, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _errorMessage = null),
          )
        ],
      ),
    );
  }

  // Instrucciones con tema oscuro
  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _esNuevaCuenta
              ? colorPrimario.withValues(alpha: 0.5)
              : Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (_esNuevaCuenta)
            _buildNewAccountInstructions()
          else
            _buildExistingAccountInstructions(),
        ],
      ),
    );
  }

  // Instrucciones para nueva cuenta con tema oscuro
  Widget _buildNewAccountInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.circleInfo,
                color: colorPrimario,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Creando nueva cuenta de acceso',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorPrimario,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'El colaborador "${EmpleadosUtils.getNombreCompleto(widget.empleado)}" podrá iniciar sesión en el sistema con las credenciales que defina a continuación.',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // Instrucciones para cuenta existente con tema oscuro
  Widget _buildExistingAccountInstructions() {
    final String rolName =
        widget.empleado.rol?.nombre ?? _rolActualNombre ?? "No definido";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.userCheck,
                color: Colors.blue,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Cuenta de usuario actual',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                icon: FontAwesomeIcons.userTag,
                label: 'Usuario',
                value: '@${widget.empleado.cuentaEmpleadoUsuario}',
              ),
              const SizedBox(height: 10),
              _buildInfoRow(
                icon: FontAwesomeIcons.userShield,
                label: 'Rol',
                value: rolName,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Fila de información para datos de cuenta (misma estructura que empleado_form)
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        FaIcon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Campos de usuario con tema oscuro
  Widget _buildUserFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Row(
          children: <Widget>[
            FaIcon(
              FontAwesomeIcons.userPen,
              size: 14,
              color: colorPrimario,
            ),
            SizedBox(width: 8),
            Text(
              'DATOS DE ACCESO',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: colorPrimario,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _usuarioController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nombre de usuario',
                  labelStyle: TextStyle(color: Colors.white70),
                  prefixIcon:
                      Icon(Icons.person, color: Colors.white54, size: 20),
                  helperText: 'Usuario para iniciar sesión',
                  helperStyle: TextStyle(color: Colors.white54),
                ),
                validator: _validarUsuario,
              ),
            ),
            if (widget.roles.isNotEmpty) ...<Widget>[
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedRolId,
                  dropdownColor: const Color(0xFF2D2D2D),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Rol del usuario',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: FaIcon(FontAwesomeIcons.userShield,
                        size: 16, color: Colors.white54),
                    helperText: 'Define permisos en el sistema',
                    helperStyle: TextStyle(color: Colors.white54),
                  ),
                  items: widget.roles.map((Map<String, dynamic> rol) {
                    IconData iconData = FontAwesomeIcons.userTag;
                    final String codigo =
                        (rol['codigo'] ?? '').toString().toLowerCase();

                    switch (codigo) {
                      case 'administrador':
                        iconData = FontAwesomeIcons.userGear;
                      case 'vendedor':
                        iconData = FontAwesomeIcons.cashRegister;
                      case 'computadora':
                        iconData = FontAwesomeIcons.desktop;
                    }

                    return DropdownMenuItem<int>(
                      value: rol['id'],
                      child: Row(
                        children: [
                          FaIcon(iconData, size: 14, color: colorPrimario),
                          const SizedBox(width: 10),
                          Text(
                            rol['nombreRol'] ??
                                rol['nombre'] ??
                                rol['codigo'] ??
                                'Rol sin nombre',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (int? value) {
                    setState(() {
                      _selectedRolId = value;
                    });
                  },
                  validator: (int? value) {
                    if (value == null && _esNuevaCuenta) {
                      return 'Seleccione un rol';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // Campos de contraseña con tema oscuro
  Widget _buildPasswordFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Row(
          children: <Widget>[
            FaIcon(
              FontAwesomeIcons.lock,
              size: 14,
              color: colorPrimario,
            ),
            SizedBox(width: 8),
            SizedBox(width: 8),
            Text(
              'CONTRASEÑA',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: colorPrimario,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _claveController,
                style: const TextStyle(color: Colors.white),
                obscureText: _ocultarClave,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon:
                      const Icon(Icons.lock, color: Colors.white54, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarClave ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white54,
                      size: 20,
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
                  helperStyle: const TextStyle(color: Colors.white54),
                ),
                validator: (value) =>
                    _validarClave(value, esRequerida: _esNuevaCuenta),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _confirmarClaveController,
                style: const TextStyle(color: Colors.white),
                obscureText: _ocultarConfirmarClave,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: Colors.white54, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarConfirmarClave
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _ocultarConfirmarClave = !_ocultarConfirmarClave;
                      });
                    },
                  ),
                  helperText: 'Debe coincidir con la contraseña',
                  helperStyle: const TextStyle(color: Colors.white54),
                ),
                validator: (String? value) =>
                    _validarConfirmacionClave(value, _claveController.text),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Botones de acción con tema oscuro
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
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
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: _eliminarCuenta,
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
        else
          const SizedBox.shrink(),

        Row(
          children: <Widget>[
            // Botón para cancelar
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(width: 16),

            // Botón para guardar
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE31E24),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: _guardarCuenta,
              child: Text(
                _esNuevaCuenta ? 'Crear Cuenta' : 'Guardar Cambios',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
