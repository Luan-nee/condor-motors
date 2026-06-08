import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/providers/admin/settings.admin.riverpod.dart';
import 'package:condorsmotors/theme/apptheme.dart';
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

  int? _currentSelectedIndex;
  int? _previousSelectedIndex;

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

    // Inicializar índices en base a la sucursal seleccionada en su orden visual
    final initialIndex = _getDisplayIndex(widget.sucursalSeleccionada);
    if (initialIndex != -1) {
      _currentSelectedIndex = initialIndex;
      _previousSelectedIndex = initialIndex;
    }
  }

  @override
  void didUpdateWidget(SlideSucursal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sucursalSeleccionada?.id != oldWidget.sucursalSeleccionada?.id) {
      final oldIndex = _getDisplayIndex(oldWidget.sucursalSeleccionada);
      final newIndex = _getDisplayIndex(widget.sucursalSeleccionada);

      setState(() {
        if (oldIndex != -1) {
          _previousSelectedIndex = oldIndex;
        }
        if (newIndex != -1) {
          _currentSelectedIndex = newIndex;
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int _getDisplayIndex(Sucursal? sucursal) {
    if (sucursal == null) {
      return -1;
    }
    final mostrarAgrupados =
        ref.read(settingsAdminProvider).mostrarSucursalesAgrupadas;
    if (!mostrarAgrupados) {
      return widget.sucursales.indexWhere((s) => s.id == sucursal.id);
    }
    
    // Agrupar y ordenar según el flujo visual de la pantalla
    final grupos = _agruparSucursales();
    final List<Sucursal> visualOrder = [
      ...grupos['Centrales']!,
      ...grupos['Sucursales']!,
    ];
    return visualOrder.indexWhere((s) => s.id == sucursal.id);
  }

  (Alignment, double) _getAlignmentAndHeight(int itemIndex, bool isSelected) {
    if (isSelected) {
      if (_previousSelectedIndex != null &&
          _currentSelectedIndex != null &&
          _currentSelectedIndex != _previousSelectedIndex) {
        if (_currentSelectedIndex! > _previousSelectedIndex!) {
          // El nuevo ítem está más abajo, el líquido entra desde arriba
          return (Alignment.topCenter, 120.0);
        } else {
          // El nuevo ítem está más arriba, el líquido entra desde abajo
          return (Alignment.bottomCenter, 120.0);
        }
      }
      return (Alignment.topCenter, 120.0);
    } else {
      // Si no está seleccionado, y fue el anteriormente seleccionado, se vacía
      // en la dirección hacia donde se mueve el nuevo foco
      if (_previousSelectedIndex != null &&
          _currentSelectedIndex != null &&
          itemIndex == _previousSelectedIndex &&
          _currentSelectedIndex != _previousSelectedIndex) {
        if (_currentSelectedIndex! > _previousSelectedIndex!) {
          // El nuevo foco está más abajo, se vacía drenando hacia abajo
          return (Alignment.bottomCenter, 0.0);
        } else {
          // El nuevo foco está más arriba, se vacía drenando hacia arriba
          return (Alignment.topCenter, 0.0);
        }
      }
      return (Alignment.topCenter, 0.0);
    }
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
              color: AppTheme.primaryColor,
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
                backgroundColor: AppTheme.primaryColor,
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
              color: AppTheme.primaryColor,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
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

    final int itemIndex = _getDisplayIndex(sucursal);
    final (Alignment alignment, double liquidHeight) = _getAlignmentAndHeight(itemIndex, isSelected);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onSucursalSelected(sucursal),
          borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          splashColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          highlightColor: AppTheme.primaryColor.withValues(alpha: 0.05),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
            child: Stack(
              children: <Widget>[
                // Fondo base inactivo
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.02),
                  ),
                ),
                // Relleno líquido animado (efecto de agua con oleaje)
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: isSelected ? 1.0 : 0.0),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    builder: (BuildContext context, double progress, Widget? child) {
                      if (progress == 0.0) {
                        return const SizedBox.shrink();
                      }
                      return ClipPath(
                        clipper: WaterWaveClipper(
                          progress: progress,
                          fromTop: alignment == Alignment.topCenter,
                        ),
                        child: Container(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        ),
                      );
                    },
                  ),
                ),
                // Contenido de la tarjeta y bordes
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      // Icono estático (sin animación de escala)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryColor : iconBgColor,
                          borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                        ),
                        child: Icon(
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
                                fontWeight: FontWeight.w600,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Clipper personalizado para generar una curva de onda de agua/líquido fluida
class WaterWaveClipper extends CustomClipper<Path> {
  final double progress;
  final bool fromTop;

  WaterWaveClipper({
    required this.progress,
    required this.fromTop,
  });

  @override
  Path getClip(Size size) {
    final Path path = Path();
    if (fromTop) {
      // Entra y se llena de arriba hacia abajo
      final double currentHeight = size.height * progress;
      if (progress == 0.0) {
        return path;
      }
      if (progress >= 1.0) {
        path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
        return path;
      }

      final double waveAmplitude = 10 * (1.0 - progress) * (progress > 0.5 ? (1.0 - progress) * 2 : progress * 2);
      final double controlY = currentHeight + waveAmplitude;

      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, currentHeight)
        ..quadraticBezierTo(size.width / 2, controlY, 0, currentHeight)
        ..close();
    } else {
      // Entra y se llena de abajo hacia arriba
      final double currentHeight = size.height * (1.0 - progress);
      if (progress == 0.0) {
        return path;
      }
      if (progress >= 1.0) {
        path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
        return path;
      }

      final double waveAmplitude = 10 * (1.0 - progress) * (progress > 0.5 ? (1.0 - progress) * 2 : progress * 2);
      final double controlY = currentHeight - waveAmplitude;

      path
        ..moveTo(0, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, currentHeight)
        ..quadraticBezierTo(size.width / 2, controlY, 0, currentHeight)
        ..close();
    }
    return path;
  }

  @override
  bool shouldReclip(WaterWaveClipper oldClipper) {
    return oldClipper.progress != progress || oldClipper.fromTop != fromTop;
  }
}
