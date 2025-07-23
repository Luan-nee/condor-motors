import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/utils/sucursal_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Sucursal>('sucursales', sucursales))
      ..add(DiagnosticsProperty<Sucursal?>(
          'sucursalSeleccionada', sucursalSeleccionada))
      ..add(ObjectFlagProperty<Function(Sucursal)>.has(
          'onSucursalSelected', onSucursalSelected))
      ..add(ObjectFlagProperty<VoidCallback>.has(
          'onRecargarSucursales', onRecargarSucursales))
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading));
  }
}

class _SlideSucursalState extends State<SlideSucursal>
    with SingleTickerProviderStateMixin {
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
    final Map<String, List<Sucursal>> grupos = <String, List<Sucursal>>{
      'Centrales': <Sucursal>[],
      'Sucursales': <Sucursal>[],
    };

    for (final Sucursal sucursal in widget.sucursales) {
      if (sucursal.sucursalCentral) {
        grupos['Centrales']!.add(sucursal);
      } else {
        grupos['Sucursales']!.add(sucursal);
      }
    }

    // Ordenamos por nombre dentro de cada grupo
    grupos['Centrales']!
        .sort((Sucursal a, Sucursal b) => a.nombre.compareTo(b.nombre));
    grupos['Sucursales']!
        .sort((Sucursal a, Sucursal b) => a.nombre.compareTo(b.nombre));

    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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
          children: <Widget>[
            const FaIcon(
              FontAwesomeIcons.buildingCircleXmark,
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
              icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 16),
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
    final Map<String, List<Sucursal>>? sucursalesAgrupadas =
        _mostrarAgrupados ? _agruparSucursales() : null;

    return FadeTransition(
      opacity: _animation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Cabecera del panel
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF222222),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
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
                          'SUCURSALES',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Tooltip(
                          message: '${widget.sucursales.length} sucursales',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
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
                          icon: const FaIcon(
                            FontAwesomeIcons.arrowsRotate,
                            color: Colors.white,
                            size: 16,
                          ),
                          onPressed: widget.onRecargarSucursales,
                          tooltip: 'Recargar sucursales',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Switch para agrupar/desagrupar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        FaIcon(
                          _mostrarAgrupados
                              ? FontAwesomeIcons.layerGroup
                              : FontAwesomeIcons.list,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Agrupar sucursales',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _mostrarAgrupados,
                      onChanged: (bool value) {
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
      children: <Widget>[
        // Construimos los grupos que tienen elementos
        if (grupos['Centrales']!.isNotEmpty) ...<Widget>[
          _buildGrupoHeader('Centrales', grupos['Centrales']!.length),
          ...grupos['Centrales']!
              .map(_buildSucursalItem),
        ],
        if (grupos['Sucursales']!.isNotEmpty) ...<Widget>[
          if (grupos['Centrales']!.isNotEmpty) const SizedBox(height: 16),
          _buildGrupoHeader('Sucursales', grupos['Sucursales']!.length),
          ...grupos['Sucursales']!
              .map(_buildSucursalItem),
        ],
      ],
    );
  }

  Widget _buildGrupoHeader(String titulo, int cantidad) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
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
      itemBuilder: (BuildContext context, int index) {
        final Sucursal sucursal = widget.sucursales[index];
        return _buildSucursalItem(sucursal);
      },
    );
  }

  Widget _buildSucursalItem(Sucursal sucursal) {
    final bool isSelected = widget.sucursalSeleccionada?.id == sucursal.id;
    final IconData icon = SucursalUtils.getIconForSucursal(sucursal);
    final Color iconColor = SucursalUtils.getColorForSucursal(sucursal);
    final Color iconBgColor = SucursalUtils.getIconBackgroundColor(sucursal);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  ? const Color(0xFFE31E24).withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFE31E24)
                    : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                AnimatedScale(
                  scale: isSelected ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE31E24) : iconBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FaIcon(
                      icon,
                      color: isSelected ? Colors.white : iconColor,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        sucursal.nombre,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (sucursal.codigoEstablecimiento != null)
                            SucursalUtils.buildCodigoEstablecimiento(
                              sucursal.codigoEstablecimiento,
                            ),
                          if (sucursal.sucursalCentral) ...[
                            const SizedBox(width: 8),
                            SucursalUtils.buildTipoSucursalBadge(sucursal),
                          ],
                        ],
                      ),
                      if (sucursal.direccion != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          sucursal.direccion!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  const FaIcon(
                    FontAwesomeIcons.circleCheck,
                    color: Color(0xFFE31E24),
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
