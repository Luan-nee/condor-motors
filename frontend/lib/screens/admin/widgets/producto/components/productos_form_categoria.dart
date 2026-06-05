import 'package:condorsmotors/models/color.model.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductosFormCategoria extends StatelessWidget {
  final bool isLoadingCategorias;
  final bool isLoadingMarcas;
  final bool isLoadingColores;
  
  final List<String> categorias;
  final List<String> marcas;
  final List<ColorApp> colores;

  final String categoriaSeleccionada;
  final TextEditingController marcaController;
  final TextEditingController colorController;
  final ColorApp? colorSeleccionado;

  final Function(String) onCategoriaChanged;
  final Function(String) onMarcaChanged;
  final Function(ColorApp?) onColorChanged;
  final VoidCallback onRetryLoad;

  const ProductosFormCategoria({
    super.key,
    required this.isLoadingCategorias,
    required this.isLoadingMarcas,
    required this.isLoadingColores,
    required this.categorias,
    required this.marcas,
    required this.colores,
    required this.categoriaSeleccionada,
    required this.marcaController,
    required this.colorController,
    required this.colorSeleccionado,
    required this.onCategoriaChanged,
    required this.onMarcaChanged,
    required this.onColorChanged,
    required this.onRetryLoad,
  });

  Widget _buildSectionTitle(String title, FaIconData icon) {
    return Row(
      children: <Widget>[
        FaIcon(icon, color: AppTheme.primaryColor, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  InputDecoration _getInputDecoration(
    String label, {
    String? prefixText,
    String? helperText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
      prefixText: prefixText,
      prefixStyle: const TextStyle(color: Colors.white),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        borderSide: const BorderSide(color: AppTheme.primaryColor),
      ),
      filled: true,
      fillColor: AppTheme.surfaceColor,
      helperText: helperText,
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionTitle('Categorización', FontAwesomeIcons.tag),
        const SizedBox(height: 16),

        // Row de Marca y Categoría en la misma línea
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Dropdown de Marca
            Expanded(
              child: isLoadingMarcas
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      initialValue: marcas.contains(marcaController.text)
                          ? marcaController.text
                          : null,
                      decoration: _getInputDecoration('Marca'),
                      dropdownColor: AppTheme.surfaceColor,
                      style: const TextStyle(color: Colors.white),
                      items: marcas.map((String marca) {
                        return DropdownMenuItem<String>(
                          value: marca,
                          child: Text(marca),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          onMarcaChanged(value);
                        }
                      },
                      validator: (String? value) =>
                          value == null || value.isEmpty ? 'Requerido' : null,
                    ),
            ),
            const SizedBox(width: 16),
            // Dropdown de Categoría
            Expanded(
              child: isLoadingCategorias
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      initialValue: categorias.contains(categoriaSeleccionada)
                          ? categoriaSeleccionada
                          : null,
                      decoration: _getInputDecoration('Categoría'),
                      dropdownColor: AppTheme.surfaceColor,
                      style: const TextStyle(color: Colors.white),
                      items: categorias.map((String categoria) {
                        return DropdownMenuItem<String>(
                          value: categoria,
                          child: Text(categoria),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          onCategoriaChanged(value);
                        }
                      },
                      validator: (String? value) =>
                          value == null || value.isEmpty ? 'Requerido' : null,
                    ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Dropdown o entrada de Color (Ocupa todo el ancho)
        if (isLoadingColores)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('Cargando colores...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          )
        else if (colores.isNotEmpty)
          DropdownButtonFormField<ColorApp>(
            initialValue: colores.any((c) => c.nombre == colorSeleccionado?.nombre)
                ? colores.firstWhere((c) => c.nombre == colorSeleccionado?.nombre)
                : null,
            decoration: _getInputDecoration('Color'),
            dropdownColor: AppTheme.surfaceColor,
            style: const TextStyle(color: Colors.white),
            items: colores.map((ColorApp color) {
              return DropdownMenuItem<ColorApp>(
                value: color,
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color.toColor(),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(color.nombre),
                  ],
                ),
              );
            }).toList(),
            onChanged: onColorChanged,
            validator: (ColorApp? value) =>
                value == null ? 'Requerido' : null,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: colorController,
                decoration: _getInputDecoration('Color (ingreso manual)'),
                style: const TextStyle(color: Colors.white),
                validator: (String? value) =>
                    value?.isEmpty ?? true ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.warning_amber_outlined, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No se pudieron cargar los colores. Se usará el valor manual.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onRetryLoad,
                      child: const Text(
                        'Reintentar',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
