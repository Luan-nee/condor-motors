import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SucursalHeader extends StatelessWidget {
  final int totalSucursales;
  final bool isLoading;
  final String terminoBusqueda;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onReload;
  final VoidCallback onAddNew;
  final VoidCallback onToggleFiltros;
  final bool mostrarFiltrosAvanzados;
  final String filtroTipo;
  final ValueChanged<String?> onFiltroTipoChanged;
  final bool mostrarAgrupados;
  final ValueChanged<bool> onToggleAgrupados;

  const SucursalHeader({
    super.key,
    required this.totalSucursales,
    required this.isLoading,
    required this.terminoBusqueda,
    required this.onSearchChanged,
    required this.onReload,
    required this.onAddNew,
    required this.onToggleFiltros,
    required this.mostrarFiltrosAvanzados,
    required this.filtroTipo,
    required this.onFiltroTipoChanged,
    required this.mostrarAgrupados,
    required this.onToggleAgrupados,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: <Widget>[
                  const FaIcon(
                    FontAwesomeIcons.buildingUser,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'GESTIÓN DE SUCURSALES',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Contador de sucursales
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      totalSucursales.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Switch Agrupar
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      FaIcon(
                        mostrarAgrupados
                            ? FontAwesomeIcons.layerGroup
                            : FontAwesomeIcons.list,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Agrupar',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 24,
                        width: 44,
                        child: Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: mostrarAgrupados,
                            onChanged: onToggleAgrupados,
                            activeThumbColor: const Color(0xFFE31E24),
                            activeTrackColor:
                                const Color(0xFFE31E24).withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Botón Recargar
                  ElevatedButton.icon(
                    icon: isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const FaIcon(
                            FontAwesomeIcons.arrowsRotate,
                            size: 14,
                            color: Colors.white,
                          ),
                    label: Text(
                      isLoading ? 'Recargando...' : 'Recargar',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D2D2D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isLoading ? null : onReload,
                  ),
                  const SizedBox(width: 12),
                  // Botón Nueva Sucursal
                  ElevatedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.plus,
                        size: 14, color: Colors.white),
                    label: const Text(
                      'Nueva Sucursal',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: onAddNew,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Buscar sucursal',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  labelStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onChanged: onSearchChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
