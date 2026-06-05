import 'dart:io';

import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/repositories/producto.repository.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductosFormInformacion extends StatelessWidget {
  final Producto? producto;
  final TextEditingController nombreController;
  final TextEditingController descripcionController;
  final TextEditingController precioCompraController;
  final TextEditingController precioVentaController;
  final TextEditingController stockController;
  final TextEditingController stockMinimoController;
  final TextEditingController skuController;
  final File? selectedImageFile;
  final String? previewImageUrl;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  const ProductosFormInformacion({
    super.key,
    this.producto,
    required this.nombreController,
    required this.descripcionController,
    required this.precioCompraController,
    required this.precioVentaController,
    required this.stockController,
    required this.stockMinimoController,
    required this.skuController,
    required this.selectedImageFile,
    required this.previewImageUrl,
    required this.onPickImage,
    required this.onRemoveImage,
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

  Widget _buildBasicInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionTitle('Información Básica', FontAwesomeIcons.circleInfo),
        const SizedBox(height: 16),
        // Imagen de producto
        Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                child: selectedImageFile != null
                    ? Image.file(selectedImageFile!, fit: BoxFit.cover)
                    : (() {
                        final fotoUrl = producto != null
                            ? ProductoRepository.getProductoImageUrl(producto!)
                            : null;
                        if (fotoUrl != null && fotoUrl.isNotEmpty) {
                          return Image.network(fotoUrl, fit: BoxFit.cover);
                        } else {
                          return const FaIcon(
                            FontAwesomeIcons.boxOpen,
                            color: Colors.white24,
                            size: 40,
                          );
                        }
                      })(),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: onPickImage,
              icon: const Icon(Icons.upload, size: 18),
              label: const Text('Seleccionar imagen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            if (selectedImageFile != null || previewImageUrl != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white54),
                tooltip: 'Quitar imagen',
                onPressed: onRemoveImage,
              ),
            if (producto != null && skuController.text.isNotEmpty) ...[
              const Spacer(),
              Tooltip(
                message: 'Copiar SKU al portapapeles',
                child: InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: skuController.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Text('SKU ${skuController.text} copiado'),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppTheme.surfaceColor,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const FaIcon(
                          FontAwesomeIcons.barcode,
                          color: AppTheme.primaryColor,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          skuController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: nombreController,
          decoration: _getInputDecoration('Nombre'),
          style: const TextStyle(color: Colors.white),
          validator: (String? value) =>
              value?.isEmpty ?? true ? 'Campo requerido' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: descripcionController,
          decoration: _getInputDecoration('Descripción'),
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionTitle(
          'Precios y Ganancia',
          FontAwesomeIcons.moneyBillWave,
        ),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: precioCompraController,
                decoration: _getInputDecoration(
                  'Precio de Compra',
                  prefixText: 'S/ ',
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                validator: (String? value) =>
                    value?.isEmpty ?? true ? 'Campo requerido' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: precioVentaController,
                decoration: _getInputDecoration(
                  'Precio de Venta',
                  prefixText: 'S/ ',
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                validator: (String? value) {
                  if (value?.isEmpty ?? true) {
                    return 'Campo requerido';
                  }
                  final double venta = double.tryParse(value!) ?? 0;
                  final double compra =
                      double.tryParse(precioCompraController.text) ?? 0;
                  if (venta <= compra) {
                    return 'El precio de venta debe ser mayor al de compra';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: precioVentaController,
                builder: (BuildContext context, TextEditingValue precioVentaText, _) {
                  return ValueListenableBuilder(
                    valueListenable: precioCompraController,
                    builder: (BuildContext context, TextEditingValue precioCompraText, _) {
                      final double venta = double.tryParse(precioVentaText.text) ?? 0;
                      final double compra = double.tryParse(precioCompraText.text) ?? 0;

                      final bool tieneDatos = compra > 0 && venta > 0;
                      final double ganancia = tieneDatos ? (venta - compra) : 0;
                      final num porcentaje = (tieneDatos && compra > 0) ? (ganancia / compra) * 100 : 0;

                      String textoGanancia;
                      Color colorGanancia;
                      FontWeight pesoGanancia;

                      if (!tieneDatos) {
                        textoGanancia = 'S/ 0.00';
                        colorGanancia = Colors.white38;
                        pesoGanancia = FontWeight.normal;
                      } else {
                        textoGanancia = 'S/ ${ganancia.toStringAsFixed(2)} (${porcentaje.toStringAsFixed(1)}%)';
                        if (ganancia > 0) {
                          colorGanancia = Colors.green[400]!;
                          pesoGanancia = FontWeight.bold;
                        } else if (ganancia < 0) {
                          colorGanancia = Colors.red[400]!;
                          pesoGanancia = FontWeight.bold;
                        } else {
                          colorGanancia = Colors.white70;
                          pesoGanancia = FontWeight.normal;
                        }
                      }

                      return InputDecorator(
                        decoration: _getInputDecoration('Ganancia').copyWith(
                          filled: true,
                          fillColor: Colors.transparent,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            textoGanancia,
                            style: TextStyle(
                              color: colorGanancia,
                              fontWeight: pesoGanancia,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionTitle('Control de Stock', FontAwesomeIcons.cubes),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: stockController,
                builder: (BuildContext context, TextEditingValue stockText, _) {
                  return InputDecorator(
                    decoration: _getInputDecoration('Stock').copyWith(
                      filled: true,
                      fillColor: Colors.transparent,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        stockText.text.isEmpty ? '0' : stockText.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: stockMinimoController,
                decoration: _getInputDecoration('Stock Mínimo (opcional)'),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildSkuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionTitle('Identificador SKU', FontAwesomeIcons.barcode),
        const SizedBox(height: 16),
        TextFormField(
          controller: skuController,
          decoration: _getInputDecoration(
            'Código SKU',
            helperText: 'Código único para identificar este producto en inventario',
          ),
          style: const TextStyle(color: Colors.white),
          validator: (String? value) =>
              value?.isEmpty ?? true ? 'Campo requerido' : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildBasicInfoSection(context),
        const SizedBox(height: 32),
        _buildPricingSection(),
        const SizedBox(height: 32),
        _buildStockSection(),
        if (producto == null) ...[
          const SizedBox(height: 32),
          _buildSkuSection(),
        ],
      ],
    );
  }
}
