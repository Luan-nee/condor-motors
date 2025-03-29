import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Paginador extends StatelessWidget {
  final Paginacion paginacion;
  final Function(int) onPageChanged;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? accentColor;
  final double radius;
  final int maxVisiblePages;
  final bool forceCompactMode;

  const Paginador({
    super.key,
    required this.paginacion,
    required this.onPageChanged,
    this.backgroundColor,
    this.textColor,
    this.accentColor,
    this.radius = 4.0,
    this.maxVisiblePages = 5,
    this.forceCompactMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isCompactScreen = screenWidth < 600 || forceCompactMode;
    
    final Color bgColor = backgroundColor ?? const Color(0xFF2D2D2D);
    final Color txtColor = textColor ?? Colors.white;
    final Color accent = accentColor ?? const Color(0xFFE31E24);
    
    // Si solo hay una página, no mostramos el paginador
    if (paginacion.totalPages <= 1) {
      return const SizedBox();
    }

    // Obtenemos las páginas visibles (menos en modo compacto)
    final List<int> visiblePages = paginacion.getVisiblePages(
      maxVisiblePages: isCompactScreen ? 3 : maxVisiblePages
    );

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 8, 
        horizontal: isCompactScreen ? 8 : 16
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: isCompactScreen 
        ? _buildCompactLayout(context, visiblePages, bgColor, txtColor, accent)
        : _buildFullLayout(context, visiblePages, bgColor, txtColor, accent),
    );
  }
  
  // Diseño compacto para pantallas pequeñas
  Widget _buildCompactLayout(
    BuildContext context, 
    List<int> visiblePages,
    Color bgColor,
    Color txtColor,
    Color accentColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Botón página anterior
        _buildPageButton(
          icon: Icons.chevron_left,
          onPressed: paginacion.hasPrevPage
              ? () => onPageChanged(paginacion.currentPage - 1)
              : null,
          bgColor: bgColor,
          txtColor: txtColor,
          accentColor: accentColor,
        ),
        
        const SizedBox(width: 4),
        
        // Indicador de página actual / total (pequeño)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${paginacion.currentPage}/${paginacion.totalPages}',
            style: TextStyle(
              color: txtColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        const SizedBox(width: 4),
        
        // Botón página siguiente
        _buildPageButton(
          icon: Icons.chevron_right,
          onPressed: paginacion.hasNextPage
              ? () => onPageChanged(paginacion.currentPage + 1)
              : null,
          bgColor: bgColor,
          txtColor: txtColor,
          accentColor: accentColor,
        ),
      ],
    );
  }
  
  // Diseño completo para pantallas más grandes
  Widget _buildFullLayout(
    BuildContext context, 
    List<int> visiblePages,
    Color bgColor,
    Color txtColor,
    Color accentColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Información de paginación
        Text(
          'Página ${paginacion.currentPage} de ${paginacion.totalPages}',
          style: TextStyle(
            color: txtColor.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        
        // Botón ir a primera página
        _buildPageButton(
          icon: Icons.first_page,
          onPressed: paginacion.hasPrevPage
              ? () => onPageChanged(1)
              : null,
          bgColor: bgColor,
          txtColor: txtColor,
          accentColor: accentColor,
        ),
        
        // Botón página anterior
        _buildPageButton(
          icon: Icons.chevron_left,
          onPressed: paginacion.hasPrevPage
              ? () => onPageChanged(paginacion.currentPage - 1)
              : null,
          bgColor: bgColor,
          txtColor: txtColor,
          accentColor: accentColor,
        ),
        
        // Números de página
        ...visiblePages.map(
          (int pageNum) => _buildNumberButton(
            pageNum: pageNum,
            isSelected: pageNum == paginacion.currentPage,
            onPressed: () => onPageChanged(pageNum),
            bgColor: bgColor,
            txtColor: txtColor,
            accentColor: accentColor,
          ),
        ),
        
        // Botón página siguiente
        _buildPageButton(
          icon: Icons.chevron_right,
          onPressed: paginacion.hasNextPage
              ? () => onPageChanged(paginacion.currentPage + 1)
              : null,
          bgColor: bgColor,
          txtColor: txtColor,
          accentColor: accentColor,
        ),
        
        // Botón ir a última página
        _buildPageButton(
          icon: Icons.last_page,
          onPressed: paginacion.hasNextPage
              ? () => onPageChanged(paginacion.totalPages)
              : null,
          bgColor: bgColor,
          txtColor: txtColor,
          accentColor: accentColor,
        ),
      ],
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color bgColor,
    required Color txtColor,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        icon: Icon(
          icon,
          size: 20,
          color: onPressed == null ? txtColor.withOpacity(0.3) : txtColor,
        ),
        onPressed: onPressed,
        splashRadius: 20,
        tooltip: onPressed == null ? null : 'Ir a la página',
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildNumberButton({
    required int pageNum,
    required bool isSelected,
    required VoidCallback onPressed,
    required Color bgColor,
    required Color txtColor,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: isSelected ? accentColor : bgColor,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: isSelected ? null : onPressed,
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: Text(
                pageNum.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : txtColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Paginacion>('paginacion', paginacion))
      ..add(ObjectFlagProperty<Function(int)>.has('onPageChanged', onPageChanged))
      ..add(ColorProperty('backgroundColor', backgroundColor))
      ..add(ColorProperty('textColor', textColor))
      ..add(ColorProperty('accentColor', accentColor))
      ..add(DoubleProperty('radius', radius))
      ..add(IntProperty('maxVisiblePages', maxVisiblePages))
      ..add(DiagnosticsProperty<bool>('forceCompactMode', forceCompactMode));
  }
} 