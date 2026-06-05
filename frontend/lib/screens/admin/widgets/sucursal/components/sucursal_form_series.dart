import 'package:condorsmotors/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SucursalFormSeries extends StatelessWidget {
  final TextEditingController serieFacturaController;
  final TextEditingController serieBoletaController;
  final TextEditingController numeroFacturaInicialController;
  final TextEditingController numeroBoletaInicialController;
  final bool seriesVinculadas;
  final VoidCallback onToggleVinculadas;
  final Animation<double> linkAnimation;
  final String? Function(String?) validateSerieFactura;
  final String? Function(String?) validateSerieBoleta;
  final void Function(String) onSerieFacturaChanged;
  final void Function(String) onSerieBoletaChanged;
  final String? Function(String?) validateNumeroInicial;

  const SucursalFormSeries({
    super.key,
    required this.serieFacturaController,
    required this.serieBoletaController,
    required this.numeroFacturaInicialController,
    required this.numeroBoletaInicialController,
    required this.seriesVinculadas,
    required this.onToggleVinculadas,
    required this.linkAnimation,
    required this.validateSerieFactura,
    required this.validateSerieBoleta,
    required this.onSerieFacturaChanged,
    required this.onSerieBoletaChanged,
    required this.validateNumeroInicial,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sección: Series y Numeración
        _buildSectionTitle('Series y Numeración', FontAwesomeIcons.fileInvoiceDollar),
        const SizedBox(height: 16),

        // Series de Facturación (Sin la etiqueta de texto interna redundante)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Serie de Factura
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.fileInvoice,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Serie Factura (Opcional)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Tooltip(
                        message: seriesVinculadas
                            ? 'Series vinculadas: Los cambios en la factura se reflejarán en la boleta'
                            : 'Vincular series de factura y boleta',
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: FaIcon(
                            seriesVinculadas
                                ? FontAwesomeIcons.link
                                : FontAwesomeIcons.linkSlash,
                            size: 16,
                            color: seriesVinculadas ? Colors.blue : Colors.white54,
                          ),
                          onPressed: onToggleVinculadas,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: serieFacturaController,
                    maxLength: 4,
                    // Hereda decoración del tema sin border override redundante
                    decoration: const InputDecoration(
                      helperText: 'F + 3 dígitos (F001) o dejar vacío',
                      counterText: '',
                      isDense: true,
                      hintText: 'Ej: F001',
                    ),
                    validator: validateSerieFactura,
                    onChanged: onSerieFacturaChanged,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Serie de Boleta
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.receipt,
                        size: 14,
                        color: Colors.white70,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Serie Boleta (Opcional)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: serieBoletaController,
                    maxLength: 4,
                    enabled: !seriesVinculadas,
                    // Hereda decoración del tema sin border override redundante
                    decoration: InputDecoration(
                      helperText: 'B + 3 dígitos (B001) o dejar vacío',
                      counterText: '',
                      isDense: true,
                      hintText: 'Ej: B001',
                      filled: seriesVinculadas,
                      fillColor: seriesVinculadas
                          ? Colors.blue.withValues(alpha: 0.1)
                          : null,
                    ),
                    validator: validateSerieBoleta,
                    onChanged: onSerieBoletaChanged,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Números Iniciales
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: numeroFacturaInicialController,
                // Hereda decoración del tema sin border override redundante y con prefixIcon perfecto
                decoration: const InputDecoration(
                  labelText: 'N° Factura Inicial',
                  isDense: true,
                  prefixIcon: Icon(Icons.tag, size: 18),
                ),
                keyboardType: TextInputType.number,
                validator: validateNumeroInicial,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: numeroBoletaInicialController,
                // Hereda decoración del tema sin border override redundante y con prefixIcon perfecto
                decoration: const InputDecoration(
                  labelText: 'N° Boleta Inicial',
                  isDense: true,
                  prefixIcon: Icon(Icons.tag, size: 18),
                ),
                keyboardType: TextInputType.number,
                validator: validateNumeroInicial,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, FaIconData icon) {
    return Row(
      children: [
        FaIcon(
          icon,
          size: 18,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
