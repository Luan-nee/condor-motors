import 'package:condorsmotors/providers/admin/index.admin.provider.dart';
import 'package:condorsmotors/providers/auth.provider.dart';
import 'package:condorsmotors/screens/admin/categorias_admin.dart';
import 'package:condorsmotors/screens/admin/dashboard_admin.dart';
import 'package:condorsmotors/screens/admin/empleados_admin.dart';
import 'package:condorsmotors/screens/admin/marcas_admin.dart';
import 'package:condorsmotors/screens/admin/pedido_admin.dart';
import 'package:condorsmotors/screens/admin/productos_admin.dart';
import 'package:condorsmotors/screens/admin/settings_admin.dart';
import 'package:condorsmotors/screens/admin/stocks_admin.dart';
import 'package:condorsmotors/screens/admin/sucursal_admin.dart';
import 'package:condorsmotors/screens/admin/transferencias_admin.dart';
import 'package:condorsmotors/screens/admin/ventas_admin.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class SlidesAdminScreen extends StatefulWidget {
  const SlidesAdminScreen({super.key});

  @override
  State<SlidesAdminScreen> createState() => _SlidesAdminScreenState();
}

class _SlidesAdminScreenState extends State<SlidesAdminScreen> {
  // Índices para las secciones principales y subsecciones
  // 0: Dashboard, 1: Ventas, 2: Inventario, 3: Colaboradores, 4: Sucursales, 5: Configuración, 6: Pedidos Exclusivos
  int _selectedIndex = 0;

  int _selectedSubIndex = 0;

  DateTime? _transitionStart;

  @override
  void initState() {
    super.initState();
    _transitionStart = DateTime.now();
  }

  Widget _buildMainContent() {
    debugPrint(
        '[SlidesAdminScreen] _buildMainContent ejecutado, _selectedIndex:  $_selectedIndex, _selectedSubIndex:  $_selectedSubIndex');
    switch (_selectedIndex) {
      case 0:
        return const DashboardAdminScreen();
      case 1:
        return ChangeNotifierProvider(
          create: (_) => VentasProvider(),
          child: const VentasAdminScreen(),
        );
      case 2:
        return _buildInventarioSubContent();
      case 3:
        return const ColaboradoresAdminScreen();
      case 4:
        return const SucursalAdminScreen();
      case 5:
        return ChangeNotifierProvider(
          create: (_) => ConfiguracionesProvider(),
          child: const SettingsAdminScreen(),
        );
      case 6:
        return const PedidoAdminScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInventarioSubContent() {
    switch (_selectedSubIndex) {
      case 0:
        return const CategoriasAdminScreen();
      case 1:
        return const InventarioAdminScreen();
      case 2:
        return const MovimientosAdminScreen();
      case 3:
        return const MarcasAdminScreen();
      case 4:
        return const ProductosAdminScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
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
              ? const Color(0xFFE31E24).withValues(alpha: 0.1)
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
            Text(
              text,
              style: TextStyle(
                color: isSelected ? const Color(0xFFE31E24) : Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableMenuItem({
    required IconData icon,
    required String text,
    required bool isSelected,
    required bool isExpanded,
    required List<Widget> subItems,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildMenuItem(
          icon: icon,
          text: text,
          isSelected: isSelected,
          onTap: onTap,
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: subItems,
            ),
          ),
      ],
    );
  }

  Widget _buildSubMenuItem(
    String text, {
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFFE31E24)
                : Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Método para mostrar el diálogo de confirmación de cierre de sesión
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logoutAndRedirectToLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    if (_transitionStart != null) {
      final diff = now.difference(_transitionStart!).inMilliseconds;
      debugPrint(
          '[SlidesAdminScreen] Tiempo de transición hasta build: ${diff}ms');
      _transitionStart = null;
    }
    debugPrint('[SlidesAdminScreen] build ejecutado');
    return Scaffold(
      body: Row(
        children: <Widget>[
          // Menú lateral
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(
                right: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
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
                  child: Row(
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
                ),
                const SizedBox(height: 24),

                // Menú de opciones
                _buildMenuItem(
                  icon: FontAwesomeIcons.chartLine,
                  text: 'Análisis de ventas',
                  isSelected: _selectedIndex == 0,
                  onTap: () => setState(() {
                    _selectedIndex = 0;
                    _selectedSubIndex = 0;
                  }),
                ),
                _buildMenuItem(
                  icon: FontAwesomeIcons.fileInvoiceDollar,
                  text: 'Ventas y facturación',
                  isSelected: _selectedIndex == 1,
                  onTap: () => setState(() {
                    _selectedIndex = 1;
                    _selectedSubIndex = 0;
                  }),
                ),
                _buildExpandableMenuItem(
                  icon: FontAwesomeIcons.boxOpen,
                  text: 'Inventario',
                  isSelected: _selectedIndex == 2,
                  isExpanded: true,
                  subItems: <Widget>[
                    _buildSubMenuItem(
                      'Control de stock',
                      onTap: () => setState(() {
                        _selectedIndex = 2;
                        _selectedSubIndex = 1;
                      }),
                      isSelected: _selectedIndex == 2 && _selectedSubIndex == 1,
                    ),
                    _buildSubMenuItem(
                      'Productos',
                      onTap: () => setState(() {
                        _selectedIndex = 2;
                        _selectedSubIndex = 4;
                      }),
                      isSelected: _selectedIndex == 2 && _selectedSubIndex == 4,
                    ),
                    _buildSubMenuItem(
                      'Categorías',
                      onTap: () => setState(() {
                        _selectedIndex = 2;
                        _selectedSubIndex = 0;
                      }),
                      isSelected: _selectedIndex == 2 && _selectedSubIndex == 0,
                    ),
                    _buildSubMenuItem(
                      'Movimiento de inventario',
                      onTap: () => setState(() {
                        _selectedIndex = 2;
                        _selectedSubIndex = 2;
                      }),
                      isSelected: _selectedIndex == 2 && _selectedSubIndex == 2,
                    ),
                    _buildSubMenuItem(
                      'Marcas',
                      onTap: () => setState(() {
                        _selectedIndex = 2;
                        _selectedSubIndex = 3;
                      }),
                      isSelected: _selectedIndex == 2 && _selectedSubIndex == 3,
                    ),
                  ],
                  onTap: () => setState(() {
                    _selectedIndex = 2;
                    _selectedSubIndex = 1;
                  }),
                ),
                // Pedidos Exclusivos justo después de Inventario
                _buildMenuItem(
                  icon: FontAwesomeIcons.cartShopping,
                  text: 'Pedidos Exclusivos',
                  isSelected: _selectedIndex == 6,
                  onTap: () => setState(() {
                    _selectedIndex = 6;
                    _selectedSubIndex = 0;
                  }),
                ),
                _buildMenuItem(
                  icon: FontAwesomeIcons.users,
                  text: 'Colaboradores',
                  isSelected: _selectedIndex == 3,
                  onTap: () => setState(() {
                    _selectedIndex = 3;
                    _selectedSubIndex = 0;
                  }),
                ),
                // Sección de Sucursales
                _buildMenuItem(
                  icon: FontAwesomeIcons.building,
                  text: 'Sucursales',
                  isSelected: _selectedIndex == 4,
                  onTap: () => setState(() {
                    _selectedIndex = 4;
                    _selectedSubIndex = 0;
                  }),
                ),
                // Sección de Configuración
                _buildMenuItem(
                  icon: FontAwesomeIcons.gear,
                  text: 'Configuración',
                  isSelected: _selectedIndex == 5,
                  onTap: () => setState(() {
                    _selectedIndex = 5;
                    _selectedSubIndex = 0;
                  }),
                ),

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

          // Contenido principal (carga perezosa)
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }
}
