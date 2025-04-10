import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/providers/auth.provider.dart';
import 'package:condorsmotors/providers/computer/dash.computer.provider.dart';
import 'package:condorsmotors/screens/computer/dashboard_computer.dart';
import 'package:condorsmotors/screens/computer/proforma_computer.dart';
import 'package:condorsmotors/screens/computer/ventas_computer.dart';
import 'package:condorsmotors/utils/role_utils.dart' as role_utils;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class SlidesComputerScreen extends StatefulWidget {
  const SlidesComputerScreen({super.key});

  @override
  State<SlidesComputerScreen> createState() => _SlidesComputerScreenState();
}

class _SlidesComputerScreenState extends State<SlidesComputerScreen> {
  int _selectedIndex = 0;
  String _nombreSucursal = 'Sucursal';
  String _nombreUsuario = 'Usuario';
  int? _sucursalId;

  // Los widgets de pantalla se inicializarán después de obtener la información de la sucursal
  late List<Map<String, dynamic>> _menuItems;

  @override
  void initState() {
    super.initState();
    // Inicializar los elementos del menú con valores por defecto
    _menuItems = <Map<String, dynamic>>[
      <String, dynamic>{
        'title': 'Dashboard',
        'icon': FontAwesomeIcons.chartLine,
        'screen': const DashboardComputerScreen(),
        'description': 'Información general de la sucursal',
      },
      <String, dynamic>{
        'title': 'Aprobar Ventas',
        'icon': FontAwesomeIcons.cashRegister,
        'screen': const ProformaComputerScreen(),
        'description': 'Procesar ventas pendientes',
      },
      <String, dynamic>{
        'title': 'Historial de Ventas',
        'icon': FontAwesomeIcons.fileInvoiceDollar,
        'screen': const VentasComputerScreen(),
        'description': 'Ver y gestionar ventas realizadas',
      },
    ];

    // Obtener la información después de que el widget esté completamente inicializado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _obtenerInformacionSucursal();
    });
  }

  void _obtenerInformacionSucursal() {
    debugPrint('Obteniendo información de sucursal...');
    try {
      final Map<String, dynamic>? args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      debugPrint('Argumentos recibidos: ${args?.toString()}');

      if (args != null) {
        // Manejar el caso donde sucursal puede ser un String o un Map
        final dynamic sucursalData = args['sucursal'];
        Map<String, dynamic>? sucursalInfo;

        if (sucursalData is Map<String, dynamic>) {
          debugPrint('Sucursal es un Map');
          sucursalInfo = sucursalData;
        } else if (sucursalData is String) {
          debugPrint('Sucursal es un String: $sucursalData');
          // Si es un string, podemos crear un mapa con el nombre
          sucursalInfo = <String, dynamic>{'nombre': sucursalData};
        } else {
          debugPrint('Sucursal es de tipo: ${sucursalData?.runtimeType}');
          sucursalInfo = null;
        }

        // Obtener sucursalId de manera segura
        final dynamic sucursalIdData = args['sucursalId'];
        int? sucursalId;

        if (sucursalIdData is int) {
          sucursalId = sucursalIdData;
        } else if (sucursalIdData is String) {
          sucursalId = int.tryParse(sucursalIdData);
          debugPrint('Convertido sucursalId de String a int: $sucursalId');
        } else {
          sucursalId = sucursalInfo?['id'] as int?;
        }

        if (sucursalId == null) {
          debugPrint('ADVERTENCIA: No se pudo obtener un sucursalId válido');
        }

        setState(() {
          _nombreSucursal = sucursalInfo?['nombre'] ??
              args['sucursal']?.toString() ??
              'Sucursal sin nombre';
          _nombreUsuario = args['usuario'] ?? args['nombre'] ?? 'Usuario';
          _sucursalId = sucursalId;

          // Actualizar los widgets con la información de la sucursal
          _actualizarWidgets();
        });

        debugPrint(
            'Información de sucursal actualizada: nombre=$_nombreSucursal, id=$_sucursalId');
      } else {
        debugPrint('No se recibieron argumentos');
      }
    } catch (e) {
      debugPrint('ERROR al obtener información de sucursal: $e');
      // Establecer valores por defecto en caso de error
      setState(() {
        _nombreSucursal = 'Sucursal sin nombre';
        _nombreUsuario = 'Usuario';
        _sucursalId = null;
        _actualizarWidgets();
      });
    }
  }

  void _actualizarWidgets() {
    // Actualizar los widgets con la información de la sucursal
    setState(() {
      _menuItems = <Map<String, dynamic>>[
        <String, dynamic>{
          'title': 'Dashboard',
          'icon': FontAwesomeIcons.chartLine,
          'screen': DashboardComputerScreen(
              sucursalId: _sucursalId, nombreSucursal: _nombreSucursal),
          'description': 'Información general de la sucursal',
        },
        <String, dynamic>{
          'title': 'Aprobar Ventas',
          'icon': FontAwesomeIcons.cashRegister,
          'screen': ProformaComputerScreen(
              sucursalId: _sucursalId, nombreSucursal: _nombreSucursal),
          'description': 'Procesar ventas pendientes',
        },
        <String, dynamic>{
          'title': 'Historial de Ventas',
          'icon': FontAwesomeIcons.fileInvoiceDollar,
          'screen': VentasComputerScreen(
              sucursalId: _sucursalId, nombreSucursal: _nombreSucursal),
          'description': 'Ver y gestionar ventas realizadas',
          'badge':
              true, // Indicador para mostrar que es una nueva funcionalidad
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardComputerProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(api.auth)),
      ],
      child: Scaffold(
        body: Row(
          children: <Widget>[
            // Menú lateral
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                border: Border(
                  right: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Logo y título
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage(
                                      'assets/images/condor-motors-logo.webp'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Condor Motors',
                              style: TextStyle(
                                color: Color(0xFFE31E24),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Información de la sucursal
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE31E24).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: <Widget>[
                              const FaIcon(
                                FontAwesomeIcons.store,
                                color: Color(0xFFE31E24),
                                size: 12,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _nombreSucursal,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Información del usuario
                        Row(
                          children: <Widget>[
                            const FaIcon(
                              FontAwesomeIcons.user,
                              color: Colors.white54,
                              size: 12,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _nombreUsuario,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Menú de opciones
                  ..._menuItems
                      .asMap()
                      .entries
                      .map((MapEntry<int, Map<String, dynamic>> entry) {
                    final int index = entry.key;
                    final Map<String, dynamic> item = entry.value;
                    return _buildMenuItem(
                      icon: item['icon'] as IconData,
                      text: item['title'] as String,
                      description: item['description'] as String,
                      isSelected: _selectedIndex == index,
                      onTap: () => setState(() => _selectedIndex = index),
                    );
                  }),

                  const Spacer(),

                  // Botón de salir
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextButton.icon(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const FaIcon(
                        FontAwesomeIcons.rightFromBracket,
                        color: Colors.white54,
                        size: 18,
                      ),
                      label: const Text(
                        'Salir',
                        style: TextStyle(
                          color: Colors.white54,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido principal
            Expanded(
              child: _menuItems[_selectedIndex]['screen'] as Widget,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE31E24).withOpacity(0.1)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xFFE31E24) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: <Widget>[
            FaIcon(
              icon,
              color: isSelected ? const Color(0xFFE31E24) : Colors.white54,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    text,
                    style: TextStyle(
                      color:
                          isSelected ? const Color(0xFFE31E24) : Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white54.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para mostrar el diálogo de confirmación de cierre de sesión
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31E24),
              foregroundColor: Colors.white,
            ),
            onPressed: () => _handleLogout(context),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  // Método para manejar el cierre de sesión
  Future<void> _handleLogout(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (!context.mounted) {
        return;
      }

      // Navegar al login y limpiar el stack de navegación
      await Navigator.of(context).pushNamedAndRemoveUntil(
        role_utils.login,
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      // Mostrar error pero igual intentar navegar al login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hubo un error, pero la sesión ha sido cerrada'),
          backgroundColor: Colors.orange,
        ),
      );

      // Forzar navegación al login independientemente del error
      await Navigator.of(context).pushNamedAndRemoveUntil(
        role_utils.login,
        (Route<dynamic> route) => false,
      );
    }
  }
}
