import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/providers/admin/productos.admin.riverpod.dart';
import 'package:condorsmotors/providers/admin/stocks.admin.riverpod.dart';
import 'package:condorsmotors/providers/admin/ventas.admin.riverpod.dart';
import 'package:condorsmotors/screens/admin/widgets/slide_sucursal.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SidebarMenuItem extends StatefulWidget {
  final FaIconData icon;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const SidebarMenuItem({
    super.key,
    required this.icon,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<SidebarMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color targetColor;
    if (widget.isSelected) {
      targetColor = AppTheme.primaryColor;
    } else if (_isHovered) {
      targetColor = Colors.white.withValues(alpha: 0.8);
    } else {
      targetColor = Colors.white54;
    }

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: targetColor, end: targetColor),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: (context, color, child) {
        return SizedBox(
          height: 48,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (hovered) {
              setState(() {
                _isHovered = hovered;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              color: Colors.transparent,
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 24,
                    child: Center(
                      child: FaIcon(
                        widget.icon,
                        color: color,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.text,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SidebarSubMenuItem extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool isSelected;

  const SidebarSubMenuItem({
    super.key,
    required this.text,
    required this.onTap,
    required this.isSelected,
  });

  @override
  State<SidebarSubMenuItem> createState() => _SidebarSubMenuItemState();
}

class _SidebarSubMenuItemState extends State<SidebarSubMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color targetColor;
    if (widget.isSelected) {
      targetColor = AppTheme.primaryColor;
    } else if (_isHovered) {
      targetColor = Colors.white.withValues(alpha: 0.9);
    } else {
      targetColor = Colors.white.withValues(alpha: 0.7);
    }

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: targetColor, end: targetColor),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: (context, color, child) {
        return SizedBox(
          height: 36,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (hovered) {
              setState(() {
                _isHovered = hovered;
              });
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.text,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SharedAdminSidebar extends ConsumerWidget {
  final int selectedIndex;
  final int subIndex;

  const SharedAdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.subIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedIndex == 1) {
      final sucursales = ref.watch(ventasAdminProvider.select((s) => s.sucursales));
      final selected = ref.watch(ventasAdminProvider.select((s) => s.selectedSucursal));
      final isLoading = ref.watch(ventasAdminProvider.select((s) => s.isLoadingSucursales));
      final notifier = ref.read(ventasAdminProvider.notifier);

      return _buildSidebarContainer(
        sucursales: sucursales,
        selected: selected,
        onSelected: notifier.seleccionarSucursal,
        onRecargar: notifier.cargarSucursales,
        isLoading: isLoading,
      );
    } else if (selectedIndex == 2) {
      if (subIndex == 1) {
        final sucursales = ref.watch(stocksAdminProvider.select((s) => s.sucursales));
        final selected = ref.watch(stocksAdminProvider.select((s) => s.selectedSucursal));
        final isLoading = ref.watch(stocksAdminProvider.select((s) => s.isLoadingSucursales));
        final notifier = ref.read(stocksAdminProvider.notifier);

        return _buildSidebarContainer(
          sucursales: sucursales,
          selected: selected,
          onSelected: notifier.seleccionarSucursal,
          onRecargar: notifier.cargarSucursales,
          isLoading: isLoading,
        );
      } else {
        final sucursales = ref.watch(productosAdminProvider.select((s) => s.sucursales));
        final selected = ref.watch(productosAdminProvider.select((s) => s.selectedSucursal));
        final isLoading = ref.watch(productosAdminProvider.select((s) => s.isLoadingSucursales));
        final notifier = ref.read(productosAdminProvider.notifier);

        return _buildSidebarContainer(
          sucursales: sucursales,
          selected: selected,
          onSelected: notifier.seleccionarSucursal,
          onRecargar: notifier.cargarSucursales,
          isLoading: isLoading,
        );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildSidebarContainer({
    required List<Sucursal> sucursales,
    required Sucursal? selected,
    required Function(Sucursal) onSelected,
    required Function() onRecargar,
    required bool isLoading,
  }) {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border(left: BorderSide(color: Colors.white.withAlpha(25))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: SlideSucursal(
        sucursales: sucursales,
        sucursalSeleccionada: selected,
        onSucursalSelected: onSelected,
        onRecargarSucursales: onRecargar,
        isLoading: isLoading,
      ),
    );
  }
}
