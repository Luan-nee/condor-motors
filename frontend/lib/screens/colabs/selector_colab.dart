import 'package:condorsmotors/providers/auth.provider.dart';
import 'package:condorsmotors/providers/colabs/ventas.colab.provider.dart';
import 'package:condorsmotors/screens/colabs/productos_colab.dart';
import 'package:condorsmotors/screens/colabs/transferencias_colab.dart';
import 'package:condorsmotors/screens/colabs/ventas_colab.dart';
import 'package:condorsmotors/utils/role_utils.dart' as role_utils;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class SelectorColabScreen extends StatelessWidget {
  final Map<String, dynamic>? empleadoData;

  const SelectorColabScreen({
    super.key,
    this.empleadoData,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final double cardWidth = isMobile ? screenWidth * 0.45 : 300.0;

    // Obtener el nombre del empleado de los datos pasados
    final nombre = empleadoData?['nombre'] ?? 'Colaborador';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
            vertical: isMobile ? 12 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header con información del usuario
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE31E24).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.userGear,
                        size: 24,
                        color: Color(0xFFE31E24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            nombre.toUpperCase(),
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Bienvenido al panel de control',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Botón de cierre de sesión
                    InkWell(
                      onTap: () => _showLogoutDialog(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 8 : 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const FaIcon(
                              FontAwesomeIcons.rightFromBracket,
                              size: 16,
                              color: Colors.red,
                            ),
                            SizedBox(width: isMobile ? 4 : 8),
                            Text(
                              isMobile ? 'Salir' : 'Cerrar Sesión',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Título de sección
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 4 : 8,
                  vertical: isMobile ? 8 : 12,
                ),
                child: Text(
                  'MÓDULOS DISPONIBLES',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[400],
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Grid de opciones
              Expanded(
                child: GridView(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: cardWidth,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: isMobile ? 0.75 : 0.85,
                  ),
                  children: <Widget>[
                    _buildOptionCard(
                      context,
                      'Nueva Venta',
                      'Registrar ventas',
                      FontAwesomeIcons.cashRegister,
                      const VentasColabScreen(),
                      const Color(0xFF4CAF50),
                      'Crear nuevas ventas y gestionar productos',
                    ),
                    _buildOptionCard(
                      context,
                      'Productos',
                      'Gestión de inventario',
                      FontAwesomeIcons.box,
                      const ProductosColabScreen(),
                      const Color(0xFF2196F3),
                      'Consultar stock y precios',
                    ),
                    _buildOptionCard(
                      context,
                      'Movimientos',
                      'Solicitar productos',
                      FontAwesomeIcons.truck,
                      const TransferenciasColabScreen(),
                      const Color(0xFFE31E24),
                      'Gestionar traslados entre sucursales',
                    ),
                  ],
                ),
              ),
            ],
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
            onPressed: () => _logout(context),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  // Método para realizar el cierre de sesión
  Future<void> _logout(BuildContext context) async {
    try {
      debugPrint('Iniciando proceso de logout en selector_colab.dart');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      debugPrint('AuthProvider obtenido correctamente');

      // Cerrar el diálogo antes de proceder con el logout
      Navigator.of(context).pop();

      debugPrint('Llamando a authProvider.logout()');
      await authProvider.logout();
      debugPrint('Logout completado exitosamente');

      if (!context.mounted) return;

      // Navegar al login y limpiar el stack de navegación
      debugPrint('Navegando a la pantalla de login');
      await Navigator.of(context).pushNamedAndRemoveUntil(
        role_utils.login,
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('Error durante el logout: $e');

      if (!context.mounted) return;

      // Mostrar error pero igual intentar navegar al login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hubo un error, pero la sesión ha sido cerrada'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );

      // Forzar navegación al login independientemente del error
      debugPrint('Forzando navegación a login después del error');
      await Navigator.of(context).pushNamedAndRemoveUntil(
        role_utils.login,
        (Route<dynamic> route) => false,
      );
    }
  }

  Widget _buildOptionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Widget screen,
    Color color,
    String description,
  ) {
    // Obtener el tamaño de la pantalla para hacer el diseño responsivo
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    // Envolver la pantalla con su Provider si es necesario
    Widget wrappedScreen = screen;
    if (screen is VentasColabScreen) {
      wrappedScreen = ChangeNotifierProvider(
        create: (_) => VentasColabProvider(),
        child: screen,
      );
    }

    return Card(
      elevation: 0,
      color: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (BuildContext context) => wrappedScreen),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Icono en la parte superior
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),

              // Espacio flexible para ajustar el diseño
              const SizedBox(height: 12),

              // Título con tamaño adaptativo
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Subtítulo
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey[400],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Espacio flexible que se expande para llenar el espacio disponible
              const Spacer(),

              // Botón de acceso en la parte inferior
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'ACCEDER',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FaIcon(
                      FontAwesomeIcons.angleRight,
                      size: 12,
                      color: color,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Map<String, dynamic>?>(
        'empleadoData', empleadoData));
  }
}
