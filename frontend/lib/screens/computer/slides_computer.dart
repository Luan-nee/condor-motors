import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../routes/routes.dart';
import 'ventas_computer.dart';
import 'dashboard_computer.dart';

class SlidesComputerScreen extends StatefulWidget {
  const SlidesComputerScreen({super.key});

  @override
  State<SlidesComputerScreen> createState() => _SlidesComputerScreenState();
}

class _SlidesComputerScreenState extends State<SlidesComputerScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Dashboard',
      'icon': FontAwesomeIcons.chartLine,
      'screen': const DashboardComputerScreen(),
      'description': 'Información general de la sucursal',
    },
    {
      'title': 'Aprobar Ventas',
      'icon': FontAwesomeIcons.cashRegister,
      'screen': const SalesComputerScreen(),
      'description': 'Procesar ventas pendientes',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Menú lateral
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(
                right: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo y título
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage('assets/images/condor-motors-logo.webp'),
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
                ..._menuItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
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
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, Routes.login);
                    },
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
          color: isSelected ? const Color(0xFFE31E24).withOpacity(0.1) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xFFE31E24) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            FaIcon(
              icon,
              color: isSelected ? const Color(0xFFE31E24) : Colors.white54,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFE31E24) : Colors.white54,
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
}
