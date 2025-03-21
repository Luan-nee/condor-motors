import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../models/sucursal.model.dart';

class SlideSucursal extends StatefulWidget {
  final List<Sucursal> sucursales;
  final Sucursal? sucursalSeleccionada;
  final Function(Sucursal) onSucursalSelected;
  final VoidCallback onRecargarSucursales;
  final bool isLoading;

  const SlideSucursal({
    super.key,
    required this.sucursales,
    required this.sucursalSeleccionada,
    required this.onSucursalSelected,
    required this.onRecargarSucursales,
    required this.isLoading,
  });

  @override
  State<SlideSucursal> createState() => _SlideSucursalState();
}

class _SlideSucursalState extends State<SlideSucursal> with SingleTickerProviderStateMixin {
  bool _mostrarAgrupados = true;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Método para agrupar las sucursales
  Map<String, List<Sucursal>> _agruparSucursales() {
    final Map<String, List<Sucursal>> grupos = {
      'Centrales': [],
      'Sucursales': [],
    };

    for (final sucursal in widget.sucursales) {
      if (sucursal.nombre.toLowerCase().contains('central') || 
          sucursal.nombre.toLowerCase().contains('principal') ||
          sucursal.sucursalCentral) {
        grupos['Centrales']!.add(sucursal);
      } else {
        grupos['Sucursales']!.add(sucursal);
      }
    }

    // Ordenamos por nombre dentro de cada grupo
    grupos['Centrales']!.sort((a, b) => a.nombre.compareTo(b.nombre));
    grupos['Sucursales']!.sort((a, b) => a.nombre.compareTo(b.nombre));

    return grupos;
  }

  // Método para obtener icono según la sucursal
  IconData _getIconForSucursal(Sucursal sucursal) {
    // Primero revisamos si es sucursal central
    if (sucursal.sucursalCentral) {
      return FontAwesomeIcons.building;
    }
    
    // Luego revisamos el nombre
    final nombre = sucursal.nombre.toLowerCase();
    if (nombre.contains('central') || nombre.contains('principal')) {
      return FontAwesomeIcons.building;
    } else if (nombre.contains('taller')) {
      return FontAwesomeIcons.screwdriverWrench;
    } else if (nombre.contains('almacén') || nombre.contains('almacen') || nombre.contains('bodega')) {
      return FontAwesomeIcons.warehouse;
    } else if (nombre.contains('tienda') || nombre.contains('venta')) {
      return FontAwesomeIcons.store;
    }
    return FontAwesomeIcons.locationDot;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFFE31E24),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando sucursales...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (widget.sucursales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.store_mall_directory_outlined,
              color: Colors.white54,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay sucursales disponibles',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Recargar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE31E24),
                foregroundColor: Colors.white,
              ),
              onPressed: widget.onRecargarSucursales,
            ),
          ],
        ),
      );
    }

    // Agrupar las sucursales si es necesario
    final sucursalesAgrupadas = _mostrarAgrupados ? _agruparSucursales() : null;

    return FadeTransition(
      opacity: _animation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera del panel
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF222222),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SUCURSALES',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        Tooltip(
                          message: '${widget.sucursales.length} sucursales',
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2D2D),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.sucursales.length.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: widget.onRecargarSucursales,
                          tooltip: 'Recargar sucursales',
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Switch para agrupar/desagrupar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Agrupar sucursales',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Switch(
                      value: _mostrarAgrupados,
                      onChanged: (value) {
                        setState(() {
                          _mostrarAgrupados = value;
                        });
                      },
                      activeColor: const Color(0xFFE31E24),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Lista de sucursales
          Expanded(
            child: _mostrarAgrupados
                ? _buildAgrupadas(sucursalesAgrupadas!)
                : _buildListaCompleta(),
          ),
        ],
      ),
    );
  }

  Widget _buildAgrupadas(Map<String, List<Sucursal>> grupos) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Construimos los grupos que tienen elementos
        if (grupos['Centrales']!.isNotEmpty) ...[
          _buildGrupoHeader('Centrales', grupos['Centrales']!.length),
          ...grupos['Centrales']!.map((sucursal) => _buildSucursalItem(sucursal)),
        ],
        if (grupos['Sucursales']!.isNotEmpty) ...[
          if (grupos['Centrales']!.isNotEmpty) const SizedBox(height: 16),
          _buildGrupoHeader('Sucursales', grupos['Sucursales']!.length),
          ...grupos['Sucursales']!.map((sucursal) => _buildSucursalItem(sucursal)),
        ],
      ],
    );
  }

  Widget _buildGrupoHeader(String titulo, int cantidad) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titulo.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE31E24),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              cantidad.toString(),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaCompleta() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.sucursales.length,
      itemBuilder: (context, index) {
        final sucursal = widget.sucursales[index];
        return _buildSucursalItem(sucursal);
      },
    );
  }

  Widget _buildSucursalItem(Sucursal sucursal) {
    final isSelected = widget.sucursalSeleccionada?.id == sucursal.id;
    final icon = _getIconForSucursal(sucursal);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Hero(
        tag: 'sucursal_${sucursal.id}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onSucursalSelected(sucursal),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFFE31E24).withOpacity(0.2) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFFE31E24) 
                      : Colors.white.withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFFE31E24) 
                            : const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FaIcon(
                        icon,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sucursal.nombre,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                            color: isSelected 
                                ? Colors.white 
                                : Colors.white.withOpacity(0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sucursal.direccion ?? 'Sin dirección',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFFE31E24),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
