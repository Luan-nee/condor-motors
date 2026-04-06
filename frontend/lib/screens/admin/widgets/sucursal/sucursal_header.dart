import 'package:condorsmotors/utils/sucursal_utils.dart';
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
        AppBar(
          backgroundColor: const Color(0xFF212121),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Gestión de Sucursales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Administre las sucursales y locales de la empresa',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.filter, size: 16),
              tooltip: 'Filtros avanzados',
              onPressed: onToggleFiltros,
            ),
            ElevatedButton.icon(
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const FaIcon(
                      FontAwesomeIcons.arrowsRotate,
                      size: 16,
                      color: Colors.white,
                    ),
              label: Text(
                isLoading ? 'Recargando...' : 'Recargar',
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D2D2D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onPressed: isLoading ? null : onReload,
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.plus,
                  size: 16, color: Colors.white),
              label: const Text('Nueva Sucursal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE31E24),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
              onPressed: onAddNew,
            ),
            const SizedBox(width: 12)
          ],
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Row(
                    children: <Widget>[
                      FaIcon(
                        FontAwesomeIcons.buildingUser,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'GESTIÓN DE SUCURSALES',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Tooltip(
                    message: '$totalSucursales sucursales',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        totalSucursales.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Buscar sucursal',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  labelStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: onSearchChanged,
              ),
              if (mostrarFiltrosAvanzados) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filtros Avanzados',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Tipo de Local:',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D2D2D),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: filtroTipo,
                                  dropdownColor: const Color(0xFF2D2D2D),
                                  style: const TextStyle(color: Colors.white),
                                  items: SucursalUtils.tiposSucursal
                                      .map((String item) {
                                    return DropdownMenuItem<String>(
                                      value: item,
                                      child: Text(item),
                                    );
                                  }).toList(),
                                  onChanged: onFiltroTipoChanged,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Row(
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
                        'Agrupar por tipo',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Switch(
                    value: mostrarAgrupados,
                    onChanged: onToggleAgrupados,
                    activeThumbColor: const Color(0xFFE31E24),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
