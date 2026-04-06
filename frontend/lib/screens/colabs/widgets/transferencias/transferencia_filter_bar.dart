import 'package:flutter/material.dart';

class TransferenciaFilterBar extends StatelessWidget {
  final bool isSearchExpanded;
  final bool isCategoriaExpanded;
  final bool isOrdenamientoExpanded;
  final TextEditingController searchController;
  final String filtroCategoria;
  final String ordenarPor;
  final String orden;
  final VoidCallback onToggleSearch;
  final VoidCallback onToggleCategoria;
  final VoidCallback onToggleOrdenamiento;
  final Function(String) onCategoriaChanged;
  final Function(String) onOrdenarPorChanged;
  final Function(String) onOrdenChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onSearch;
  final bool hasActiveFilters;

  const TransferenciaFilterBar({
    super.key,
    required this.isSearchExpanded,
    required this.isCategoriaExpanded,
    required this.isOrdenamientoExpanded,
    required this.searchController,
    required this.filtroCategoria,
    required this.ordenarPor,
    required this.orden,
    required this.onToggleSearch,
    required this.onToggleCategoria,
    required this.onToggleOrdenamiento,
    required this.onCategoriaChanged,
    required this.onOrdenarPorChanged,
    required this.onOrdenChanged,
    required this.onClearFilters,
    required this.onSearch,
    required this.hasActiveFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildFilterButton(
                isExpanded: isSearchExpanded,
                icon: Icons.search,
                activeIcon: Icons.search,
                label: 'Buscar',
                color: Colors.orange,
                hasValue: searchController.text.isNotEmpty,
                onPressed: onToggleSearch,
              ),
              const SizedBox(width: 8),
              _buildFilterButton(
                isExpanded: isCategoriaExpanded,
                icon: Icons.category_outlined,
                activeIcon: Icons.category,
                label: 'Categoría',
                color: Colors.blue,
                hasValue: filtroCategoria != 'Todos',
                onPressed: onToggleCategoria,
              ),
              const SizedBox(width: 8),
              _buildFilterButton(
                isExpanded: isOrdenamientoExpanded,
                icon: Icons.sort,
                activeIcon: Icons.sort,
                label: 'Ordenar',
                color: Colors.purple,
                hasValue: ordenarPor != 'nombre' || orden != 'asc',
                onPressed: onToggleOrdenamiento,
              ),
              const Spacer(),
              if (hasActiveFilters)
                _buildFilterButton(
                  isExpanded: false,
                  icon: Icons.filter_list_off,
                  activeIcon: Icons.filter_list_off,
                  label: 'Limpiar',
                  color: Colors.red,
                  hasValue: false,
                  onPressed: onClearFilters,
                ),
            ],
          ),
          if (isSearchExpanded) _buildSearchExpandido(),
          if (isCategoriaExpanded) _buildCategoriaExpandida(),
          if (isOrdenamientoExpanded) _buildOrdenamientoExpandido(),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required bool isExpanded,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color color,
    required bool hasValue,
    required VoidCallback onPressed,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isExpanded ? color.withValues(alpha: 0.2) : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isExpanded ? activeIcon : icon,
              color: isExpanded || hasValue ? color : Colors.white70,
              size: 20,
            ),
            if (!isExpanded && hasValue) ...[
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        onPressed: onPressed,
        tooltip: label,
      ),
    );
  }

  Widget _buildSearchExpandido() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Buscar',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                InkWell(
                  onTap: onToggleSearch,
                  child: const Icon(Icons.close, color: Colors.white70, size: 16),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o código...',
                hintStyle: const TextStyle(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        color: Colors.white60,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          searchController.clear();
                          onSearch();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => onSearch(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaExpandida() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.category, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Categoría',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                InkWell(
                  onTap: onToggleCategoria,
                  child: const Icon(Icons.close, color: Colors.white70, size: 16),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: filtroCategoria,
                isExpanded: true,
                dropdownColor: const Color(0xFF2D2D2D),
                style: const TextStyle(color: Colors.white),
                items: ['Todos', 'Repuestos', 'Accesorios', 'Lubricantes']
                    .map((String categoria) {
                  return DropdownMenuItem<String>(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    onCategoriaChanged(newValue);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdenamientoExpandido() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.sort, color: Colors.purple, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Ordenar por',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                InkWell(
                  onTap: onToggleOrdenamiento,
                  child: const Icon(Icons.close, color: Colors.white70, size: 16),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: ordenarPor,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2D2D2D),
                    style: const TextStyle(color: Colors.white),
                    items: [
                      {'value': 'nombre', 'label': 'Nombre'},
                      {'value': 'stock', 'label': 'Stock'},
                      {'value': 'sku', 'label': 'Código'},
                    ].map((Map<String, String> item) {
                      return DropdownMenuItem<String>(
                        value: item['value'],
                        child: Text(item['label']!),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        onOrdenarPorChanged(newValue);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: orden,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2D2D2D),
                    style: const TextStyle(color: Colors.white),
                    items: [
                      {'value': 'asc', 'label': 'Ascendente'},
                      {'value': 'desc', 'label': 'Descendente'},
                    ].map((Map<String, String> item) {
                      return DropdownMenuItem<String>(
                        value: item['value'],
                        child: Text(item['label']!),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        onOrdenChanged(newValue);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
