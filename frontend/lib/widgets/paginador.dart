import 'package:flutter/material.dart';
import '../models/paginacion.model.dart';

class Paginador extends StatelessWidget {
  final Paginacion paginacion;
  final Function(int) onPageChanged;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? accentColor;
  final double radius;
  final int maxVisiblePages;

  const Paginador({
    super.key,
    required this.paginacion,
    required this.onPageChanged,
    this.backgroundColor,
    this.textColor,
    this.accentColor,
    this.radius = 4.0,
    this.maxVisiblePages = 5,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final bgColor = backgroundColor ?? const Color(0xFF2D2D2D);
    final txtColor = textColor ?? Colors.white;
    final accent = accentColor ?? const Color(0xFFE31E24);
    
    // Si solo hay una página, no mostramos el paginador
    if (paginacion.totalPages <= 1) {
      return const SizedBox();
    }

    // Obtenemos las páginas visibles
    final visiblePages = paginacion.getVisiblePages(maxVisiblePages: maxVisiblePages);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            accentColor: accent,
          ),
          
          // Botón página anterior
          _buildPageButton(
            icon: Icons.chevron_left,
            onPressed: paginacion.hasPrevPage
                ? () => onPageChanged(paginacion.currentPage - 1)
                : null,
            bgColor: bgColor,
            txtColor: txtColor,
            accentColor: accent,
          ),
          
          // Números de página
          ...visiblePages.map(
            (pageNum) => _buildNumberButton(
              pageNum: pageNum,
              isSelected: pageNum == paginacion.currentPage,
              onPressed: () => onPageChanged(pageNum),
              bgColor: bgColor,
              txtColor: txtColor,
              accentColor: accent,
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
            accentColor: accent,
          ),
          
          // Botón ir a última página
          _buildPageButton(
            icon: Icons.last_page,
            onPressed: paginacion.hasNextPage
                ? () => onPageChanged(paginacion.totalPages)
                : null,
            bgColor: bgColor,
            txtColor: txtColor,
            accentColor: accent,
          ),
        ],
      ),
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
} 