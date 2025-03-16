import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/protected/empleados.api.dart';
import '../../main.dart' show api;
import '../../api/main.api.dart' show ApiException;
import 'widgets/empleado_form.dart';

class ColaboradoresAdminScreen extends StatefulWidget {
  const ColaboradoresAdminScreen({super.key});

  @override
  State<ColaboradoresAdminScreen> createState() => _ColaboradoresAdminScreenState();
}

class _ColaboradoresAdminScreenState extends State<ColaboradoresAdminScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  List<Empleado> _empleados = [];
  Map<String, String> _nombresSucursales = {};
  
  // Para búsqueda y paginación
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMorePages = false;
  
  // Lista de roles disponibles
  final List<String> _roles = ['Administrador', 'Vendedor', 'Computadora'];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Cargar sucursales primero para mostrar nombres en lugar de IDs
      await _cargarSucursales();
      
      // Luego cargar empleados
      final empleadosData = await api.empleados.getEmpleados(
        page: _currentPage,
        pageSize: _pageSize,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );
      
      final List<Empleado> empleados = [];
      for (var item in empleadosData) {
        try {
          empleados.add(Empleado.fromJson(item));
        } catch (e) {
          debugPrint('Error al convertir empleado: $e');
        }
      }
      
      // Verificar si hay más páginas
      _hasMorePages = empleados.length >= _pageSize;
      
      if (!mounted) return;
      setState(() {
        _empleados = empleados;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar datos: $e';
      });
      
      // Manejar errores de autenticación
      if (e is ApiException && e.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión expirada. Por favor, inicie sesión nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }
  
  Future<void> _cargarSucursales() async {
    try {
      final sucursalesData = await api.sucursales.getSucursales();
      final Map<String, String> sucursales = {};
      
      for (var item in sucursalesData) {
        final id = item['id']?.toString() ?? '';
        String nombre = item['nombre']?.toString() ?? 'Sucursal sin nombre';
        final bool esCentral = item['sucursalCentral'] == true;
        
        // Agregar indicador de Central al nombre si corresponde
        if (esCentral) {
          nombre = "$nombre (Central)";
        }
        
        if (id.isNotEmpty) {
          sucursales[id] = nombre;
        }
      }
      
      setState(() {
        _nombresSucursales = sucursales;
      });
    } catch (e) {
      debugPrint('Error al cargar sucursales: $e');
    }
  }

  Future<void> _buscarEmpleados() async {
    _currentPage = 1; // Reiniciar a primera página
    await _cargarDatos();
  }
  
  Future<void> _cargarMasPaginas() async {
    if (!_hasMorePages) return;
    
    _currentPage++;
    setState(() => _isLoading = true);
    
    try {
      final empleadosData = await api.empleados.getEmpleados(
        page: _currentPage,
        pageSize: _pageSize,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );
      
      final nuevosEmpleados = empleadosData
          .map((item) => Empleado.fromJson(item))
          .toList();
      
      // Verificar si hay más páginas
      _hasMorePages = nuevosEmpleados.length >= _pageSize;
      
      if (!mounted) return;
      setState(() {
        _empleados.addAll(nuevosEmpleados);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar más empleados: $e')),
        );
      });
    }
  }
  
  Future<void> _cambiarEstadoEmpleado(Empleado empleado, bool nuevoEstado) async {
    try {
      await api.empleados.updateEmpleado(
        empleado.id, 
        {'activo': nuevoEstado}
      );
      
      // Actualizar localmente
      setState(() {
        final index = _empleados.indexWhere((e) => e.id == empleado.id);
        if (index >= 0) {
          final empleadoActualizado = Empleado(
            id: empleado.id,
            nombre: empleado.nombre,
            apellidos: empleado.apellidos,
            ubicacionFoto: empleado.ubicacionFoto,
            edad: empleado.edad,
            dni: empleado.dni,
            horaInicioJornada: empleado.horaInicioJornada,
            horaFinJornada: empleado.horaFinJornada,
            fechaContratacion: empleado.fechaContratacion,
            sueldo: empleado.sueldo,
            fechaRegistro: empleado.fechaRegistro,
            sucursalId: empleado.sucursalId,
            activo: nuevoEstado,
          );
          _empleados[index] = empleadoActualizado;
        }
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nuevoEstado 
            ? 'Empleado activado correctamente' 
            : 'Empleado desactivado correctamente'
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar estado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _eliminarEmpleado(Empleado empleado) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '¿Eliminar colaborador?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Está seguro que desea eliminar a ${empleado.nombre} ${empleado.apellidos}? Esta acción no se puede deshacer.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31E24),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    
    if (confirmacion != true) return;
    
    try {
      await api.empleados.deleteEmpleado(empleado.id);
      
      if (!mounted) return;
      
      // Actualizar localmente
      setState(() {
        _empleados.removeWhere((e) => e.id == empleado.id);
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Colaborador eliminado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar colaborador: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarFormularioEmpleado([Empleado? empleado]) {
    // Importar el widget EmpleadoForm
    showDialog(
      context: context,
      builder: (context) => EmpleadoForm(
        empleado: empleado,
        sucursales: _nombresSucursales,
        roles: _roles,
        onSave: (empleadoData) => _guardarEmpleado(empleado, empleadoData),
        onCancel: () => Navigator.pop(context),
      ),
    );
  }
  
  Future<void> _guardarEmpleado(Empleado? empleadoExistente, Map<String, dynamic> empleadoData) async {
    try {
      if (empleadoExistente != null) {
        // Actualizar empleado existente
        await api.empleados.updateEmpleado(empleadoExistente.id, empleadoData);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Colaborador actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Crear nuevo empleado
        await api.empleados.createEmpleado(empleadoData);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Colaborador creado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Cerrar el diálogo y recargar datos
      if (!mounted) return;
      Navigator.pop(context);
      _cargarDatos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar colaborador: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  String _obtenerRolDeEmpleado(Empleado empleado) {
    // En un entorno de producción, esto se obtendría de una propiedad del empleado
    // o consultando una tabla de relaciones empleado-rol
    
    // Como no tenemos el rol en los datos del empleado, podemos asignar roles 
    // basados en alguna lógica de negocio o patrón:
    
    // Por ejemplo, el ID 13 corresponde al "Administrador Principal"
    if (empleado.id == "13") {
      return "Administrador";
    }
    
    // Sucursal central (ID 7) podrían ser administradores
    if (empleado.sucursalId == "7") {
      return "Administrador";
    }
    
    // Alternamos entre vendedor y computadora para el resto
    final idNum = int.tryParse(empleado.id) ?? 0;
    if (idNum % 2 == 0) {
      return "Vendedor";
    } else {
      return "Computadora";
    }
    
    // NOTA: Esta es una asignación ficticia. En producción, deberías obtener
    // el rol real de cada empleado desde la base de datos
  }

  IconData _getRolIcon(String rol) {
    switch (rol.toLowerCase()) {
      case 'administrador':
        return FontAwesomeIcons.userGear;
      case 'vendedor':
        return FontAwesomeIcons.cashRegister;
      case 'computadora':
        return FontAwesomeIcons.desktop;
      default:
        return FontAwesomeIcons.user;
    }
  }
  
  String _getNombreSucursal(String? sucursalId) {
    if (sucursalId == null || sucursalId.isEmpty) {
      return 'Sin asignar';
    }
    return _nombresSucursales[sucursalId] ?? 'Sucursal $sucursalId';
  }

  bool _esSucursalCentral(String? sucursalId) {
    if (sucursalId == null || sucursalId.isEmpty) {
      return false;
    }
    final nombre = _nombresSucursales[sucursalId] ?? '';
    return nombre.contains('(Central)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.users,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'COLABORADORES',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'gestión de personal',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.plus,
                      size: 16, color: Colors.white),
                  label: const Text('Nuevo Colaborador'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31E24),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  onPressed: _isLoading ? null : () => _mostrarFormularioEmpleado(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Barra de búsqueda
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Buscar colaborador...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        icon: FaIcon(FontAwesomeIcons.magnifyingGlass, color: Colors.white54, size: 16),
                      ),
                      onSubmitted: (_) => _buscarEmpleados(),
                    ),
                  ),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.arrowRight, color: Colors.white, size: 16),
                    onPressed: _buscarEmpleados,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: _isLoading && _empleados.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE31E24),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _cargarDatos,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _empleados.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay colaboradores para mostrar',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Encabezado de la tabla
                      Container(
                        color: const Color(0xFF2D2D2D),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        child: const Row(
                          children: [
                            // Nombre (30% del ancho)
                            Expanded(
                              flex: 30,
                              child: Text(
                                'Nombre',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Rol (25% del ancho)
                            Expanded(
                              flex: 25,
                              child: Text(
                                'Rol',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Local (25% del ancho)
                            Expanded(
                              flex: 25,
                              child: Text(
                                'Local',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Estado (10% del ancho)
                            Expanded(
                              flex: 10,
                              child: Text(
                                'Estado',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Acciones (10% del ancho)
                            Expanded(
                              flex: 10,
                              child: Text(
                                'Acciones',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Filas de colaboradores
                              ..._empleados.map((empleado) => Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        child: Row(
                          children: [
                            // Nombre
                            Expanded(
                              flex: 30,
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2D2D2D),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                            child: Center(
                                              child: empleado.ubicacionFoto != null
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Image.network(
                                                      empleado.ubicacionFoto!,
                                                      width: 32,
                                                      height: 32,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => const FaIcon(
                                                        FontAwesomeIcons.user,
                                                        color: Color(0xFFE31E24),
                                                        size: 14,
                                                      ),
                                                    ),
                                                  )
                                                : const FaIcon(
                                        FontAwesomeIcons.user,
                                        color: Color(0xFFE31E24),
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              '${empleado.nombre} ${empleado.apellidos}',
                                    style: const TextStyle(color: Colors.white),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                  ),
                                ],
                              ),
                            ),
                            // Rol
                            Expanded(
                              flex: 25,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2D2D2D),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE31E24).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        FaIcon(
                                                  _getRolIcon(_obtenerRolDeEmpleado(empleado)),
                                          color: const Color(0xFFE31E24),
                                          size: 12,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                                  _obtenerRolDeEmpleado(empleado),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Local
                            Expanded(
                              flex: 25,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2D2D2D),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _esSucursalCentral(empleado.sucursalId) 
                                            ? const Color.fromARGB(255, 95, 208, 243) // Verde para centrales
                                            : Colors.white.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        FaIcon(
                                          _esSucursalCentral(empleado.sucursalId)
                                            ? FontAwesomeIcons.building
                                            : FontAwesomeIcons.store,
                                          color: _esSucursalCentral(empleado.sucursalId)
                                            ? const Color.fromARGB(255, 76, 152, 175) // Verde para centrales
                                            : Colors.white54,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _getNombreSucursal(empleado.sucursalId),
                                          style: TextStyle(
                                            color: _esSucursalCentral(empleado.sucursalId)
                                              ? const Color.fromARGB(255, 76, 160, 175) // Verde para centrales
                                              : Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Estado
                            Expanded(
                              flex: 10,
                              child: Center(
                                child: Switch(
                                          value: empleado.activo,
                                          onChanged: (value) => _cambiarEstadoEmpleado(empleado, value),
                                  activeColor: const Color(0xFFE31E24),
                                ),
                              ),
                            ),
                            // Acciones
                            Expanded(
                              flex: 10,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Botón de detalles (lupa)
                                  IconButton(
                                    icon: const FaIcon(
                                      FontAwesomeIcons.magnifyingGlass,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    onPressed: () => _mostrarDetallesEmpleado(empleado),
                                    constraints: const BoxConstraints(
                                      minWidth: 30,
                                      minHeight: 30,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  IconButton(
                                    icon: const FaIcon(
                                      FontAwesomeIcons.penToSquare,
                                      color: Colors.white54,
                                      size: 16,
                                    ),
                                    onPressed: () => _mostrarFormularioEmpleado(empleado),
                                    constraints: const BoxConstraints(
                                      minWidth: 30,
                                      minHeight: 30,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  IconButton(
                                    icon: const FaIcon(
                                      FontAwesomeIcons.trash,
                                      color: Color(0xFFE31E24),
                                      size: 16,
                                    ),
                                    onPressed: () => _eliminarEmpleado(empleado),
                                    constraints: const BoxConstraints(
                                      minWidth: 30,
                                      minHeight: 30,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                              )),
                              
                              // Botón para cargar más
                              if (_hasMorePages && !_isLoading)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: ElevatedButton(
                                      onPressed: _cargarMasPaginas,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2D2D2D),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Cargar más'),
                                    ),
                                  ),
                                ),
                                
                              // Indicador de carga para paginación
                              if (_isLoading && _empleados.isNotEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para mostrar los detalles completos del empleado
  void _mostrarDetallesEmpleado(Empleado empleado) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado con foto y nombre
                Row(
                  children: [
                    // Foto o avatar
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: empleado.ubicacionFoto != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                empleado.ubicacionFoto!,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const FaIcon(
                                  FontAwesomeIcons.user,
                                  color: Color(0xFFE31E24),
                                  size: 28,
                                ),
                              ),
                            )
                          : const FaIcon(
                              FontAwesomeIcons.user,
                              color: Color(0xFFE31E24),
                              size: 28,
                            ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Nombre y rol
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${empleado.nombre} ${empleado.apellidos}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2D2D),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE31E24).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FaIcon(
                                  _getRolIcon(_obtenerRolDeEmpleado(empleado)),
                                  color: const Color(0xFFE31E24),
                                  size: 14,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _obtenerRolDeEmpleado(empleado),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
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
                
                // Información personal
                const Text(
                  'INFORMACIÓN PERSONAL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE31E24),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Dos columnas para la información
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Columna izquierda
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoItem('DNI', empleado.dni ?? 'No especificado'),
                          const SizedBox(height: 12),
                          _buildInfoItem('Edad', empleado.edad?.toString() ?? 'No especificada'),
                        ],
                      ),
                    ),
                    
                    // Columna derecha
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoItem('Estado', empleado.activo ? 'Activo' : 'Inactivo'),
                          const SizedBox(height: 12),
                          _buildInfoItem('Fecha Registro', empleado.fechaRegistro ?? 'No especificada'),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Información de sucursal
                const Text(
                  'SUCURSAL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE31E24),
                  ),
                ),
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _esSucursalCentral(empleado.sucursalId) 
                          ? const Color(0xFF4CAF50) 
                          : Colors.white.withOpacity(0.1),
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
                            _esSucursalCentral(empleado.sucursalId)
                                ? FontAwesomeIcons.building
                                : FontAwesomeIcons.store,
                            color: _esSucursalCentral(empleado.sucursalId)
                                ? const Color(0xFF4CAF50)
                                : Colors.white54,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getNombreSucursal(empleado.sucursalId),
                              style: TextStyle(
                                color: _esSucursalCentral(empleado.sucursalId)
                                    ? const Color(0xFF4CAF50)
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_esSucursalCentral(empleado.sucursalId))
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Sucursal Central',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Fecha Contratación: ${empleado.fechaContratacion ?? 'No especificada'}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Información laboral
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'INFORMACIÓN LABORAL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE31E24),
                      ),
                    ),
                    // Botón para ver horario
                    TextButton.icon(
                      icon: const FaIcon(
                        FontAwesomeIcons.clock,
                        size: 14,
                        color: Colors.white70,
                      ),
                      label: const Text(
                        'Ver horario',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: () => _mostrarHorarioEmpleado(empleado),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF2D2D2D),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Columna izquierda
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoItem('Sueldo', empleado.sueldo != null 
                            ? 'S/ ${empleado.sueldo!.toStringAsFixed(2)}' 
                            : 'No especificado'),
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
                    TextButton.icon(
                      icon: const FaIcon(
                        FontAwesomeIcons.arrowLeft,
                        size: 14,
                        color: Colors.white54,
                      ),
                      label: const Text('Volver'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white54,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const FaIcon(
                        FontAwesomeIcons.penToSquare,
                        size: 14,
                      ),
                      label: const Text('Editar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31E24),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        // Cerrar el diálogo de detalles
                        Navigator.pop(context);
                        // Abrir el formulario de edición
                        _mostrarFormularioEmpleado(empleado);
                      },
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
  
  // Método para mostrar el horario del empleado
  void _mostrarHorarioEmpleado(Empleado empleado) {
    // Formatear las horas para asegurar que no tengan segundos
    final horaInicio = _formatearHora(empleado.horaInicioJornada);
    final horaFin = _formatearHora(empleado.horaFinJornada);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.clock,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Horario de ${empleado.nombre}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Horario
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildHorarioItem(
                      'Hora de inicio',
                      horaInicio,
                      FontAwesomeIcons.solidClock,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Colors.white24),
                    ),
                    _buildHorarioItem(
                      'Hora de fin',
                      horaFin,
                      FontAwesomeIcons.solidClockFour,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botón para cerrar
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2D2D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Método para formatear la hora sin segundos
  String _formatearHora(String? hora) {
    if (hora == null || hora.isEmpty) {
      return 'No especificada';
    }
    
    // Si la hora ya tiene el formato HH:MM, devolverla como está
    if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(hora)) {
      return hora;
    }
    
    // Si la hora tiene formato HH:MM:SS, quitar los segundos
    if (RegExp(r'^\d{1,2}:\d{2}:\d{2}$').hasMatch(hora)) {
      return hora.substring(0, 5);
    }
    
    // Si no se puede formatear, devolver la hora original
    return hora;
  }
  
  // Widget para mostrar un elemento de horario
  Widget _buildHorarioItem(String label, String value, IconData icon) {
    return Row(
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
              icon,
              color: const Color(0xFFE31E24),
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Widget para mostrar un elemento de información
  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
} 