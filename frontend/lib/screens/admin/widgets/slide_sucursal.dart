import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/providers/admin/settings.admin.riverpod.dart';
import 'package:condorsmotors/utils/sucursal_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SlideSucursal extends ConsumerStatefulWidget {
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
  ConsumerState<SlideSucursal> createState() => _SlideSucursalState();

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

class _SlideSucursalState extends ConsumerState<SlideSucursal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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

    grupos['Centrales']!
        .sort((Sucursal a, Sucursal b) => a.nombre.compareTo(b.nombre));
    grupos['Sucursales']!
        .sort((Sucursal a, Sucursal b) => a.nombre.compareTo(b.nombre));

    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    final mostrarAgrupados =
        ref.watch(settingsAdminProvider).mostrarSucursalesAgrupadas;
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

    final Map<String, List<Sucursal>>? sucursalesAgrupadas =
        mostrarAgrupados ? _agruparSucursales() : null;

    return FadeTransition(
      opacity: _animation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
              child: mostrarAgrupados
                  ? _buildAgrupadas(sucursalesAgrupadas!)
                  : _buildListaCompleta(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgrupadas(Map<String, List<Sucursal>> grupos) {
    final List<dynamic> flatList = <dynamic>[];
    
    if (grupos['Centrales']!.isNotEmpty) {
      flatList..add({'type': 'header', 'title': 'Centrales', 'count': grupos['Centrales']!.length})
      ..addAll(grupos['Centrales']!);
    }
    
    if (grupos['Centrales']!.isNotEmpty && grupos['Sucursales']!.isNotEmpty) {
      flatList.add({'type': 'spacer'});
    }
    
    if (grupos['Sucursales']!.isNotEmpty) {
      flatList..add({'type': 'header', 'title': 'Sucursales', 'count': grupos['Sucursales']!.length})
      ..addAll(grupos['Sucursales']!);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: flatList.length,
      itemBuilder: (BuildContext context, int index) {
        final dynamic item = flatList[index];
        
        if (item is Map) {
          if (item['type'] == 'header') {
            return _buildGrupoHeader(item['title'] as String, item['count'] as int);
          }
          if (item['type'] == 'spacer') {
            return const SizedBox(height: 16);
          }
        }
        
        if (item is Sucursal) {
          return _buildSucursalItem(item);
        }
        
        return const SizedBox.shrink();
      },
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
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
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
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.identity()
                    ..setEntry(0, 0, isSelected ? 1.1 : 1.0)
                    ..setEntry(1, 1, isSelected ? 1.1 : 1.0),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
