import 'package:condorsmotors/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProductosFormPromociones extends StatefulWidget {
  final bool initialLiquidacionActiva;
  final String initialTipoPromocionSeleccionada;
  final TextEditingController precioVentaController;
  final TextEditingController precioOfertaController;
  final TextEditingController cantidadMinimaDescuentoController;
  final TextEditingController porcentajeDescuentoController;
  final TextEditingController cantidadGratisDescuentoController;
  
  final ValueChanged<bool> onLiquidacionActivaChanged;
  final ValueChanged<String> onTipoPromocionSeleccionadaChanged;

  const ProductosFormPromociones({
    super.key,
    required this.initialLiquidacionActiva,
    required this.initialTipoPromocionSeleccionada,
    required this.precioVentaController,
    required this.precioOfertaController,
    required this.cantidadMinimaDescuentoController,
    required this.porcentajeDescuentoController,
    required this.cantidadGratisDescuentoController,
    required this.onLiquidacionActivaChanged,
    required this.onTipoPromocionSeleccionadaChanged,
  });

  @override
  State<ProductosFormPromociones> createState() => _ProductosFormPromocionesState();
}

class _ProductosFormPromocionesState extends State<ProductosFormPromociones> {
  late bool _liquidacionActiva;
  late String _tipoPromocionSeleccionada;

  @override
  void initState() {
    super.initState();
    _liquidacionActiva = widget.initialLiquidacionActiva;
    _tipoPromocionSeleccionada = widget.initialTipoPromocionSeleccionada;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionTitle(
          'Promociones y Descuentos',
          FontAwesomeIcons.percent,
        ),
        const SizedBox(height: 16),

        // Sección de liquidación (siempre visible)
        _buildLiquidacionSection(),

        const SizedBox(height: 24),

        // Selector de tipo de promoción adicional
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  FaIcon(
                    FontAwesomeIcons.bullhorn,
                    size: 16,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Promoción adicional',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Opciones de tipo de promoción
              _buildPromoTypeOption(
                'ninguna',
                'Sin promoción adicional',
                'El producto no tendrá descuentos adicionales a la liquidación.',
                FontAwesomeIcons.ban,
                Colors.grey,
              ),
              const SizedBox(height: 8),
              _buildPromoTypeOption(
                'gratis',
                'Productos gratis',
                'Tipo: "Lleva X, Y gratis" - Ejemplo: Lleva 5, paga 4.',
                FontAwesomeIcons.gift,
                Colors.green,
              ),
              const SizedBox(height: 8),
              _buildPromoTypeOption(
                'descuentoPorcentual',
                'Descuento porcentual',
                'Aplica un porcentaje de descuento al comprar cierta cantidad.',
                FontAwesomeIcons.percent,
                Colors.blue,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Campos específicos según el tipo de promoción seleccionado
        if (_tipoPromocionSeleccionada == 'gratis')
          _buildProductosGratisFields(),
        if (_tipoPromocionSeleccionada == 'descuentoPorcentual')
          _buildDescuentoPorcentualFields(),
      ],
    );
  }

  // Sección de liquidación separada (siempre visible)
  Widget _buildLiquidacionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _liquidacionActiva
            ? Colors.amber.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(
          color: _liquidacionActiva
              ? Colors.amber.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  FaIcon(FontAwesomeIcons.tag, size: 16, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'Liquidación',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  SizedBox(width: 8),
                  Tooltip(
                    message:
                        'Active esta opción para establecer un precio especial de liquidación. El producto se mostrará como "En liquidación" en todas las vistas.',
                    child: Icon(
                      Icons.help_outline,
                      size: 16,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _liquidacionActiva,
                onChanged: (bool value) {
                  setState(() {
                    _liquidacionActiva = value;
                  });
                  widget.onLiquidacionActivaChanged(value);
                },
                activeThumbColor: Colors.amber,
              ),
            ],
          ),
          if (_liquidacionActiva) ...<Widget>[
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.precioOfertaController,
              decoration: _getInputDecoration(
                'Precio de liquidación',
                prefixText: 'S/ ',
                helperText: 'Precio especial para liquidar este producto',
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              validator: (String? value) {
                if (_liquidacionActiva) {
                  if (value == null || value.isEmpty) {
                    return 'El precio de liquidación es obligatorio';
                  }
                  try {
                    final double precio = double.parse(value);
                    if (precio <= 0) {
                      return 'El precio debe ser mayor a cero';
                    }
                    final double precioVenta =
                        double.tryParse(widget.precioVentaController.text) ?? 0;
                    if (precio >= precioVenta) {
                      return 'El precio de liquidación debe ser menor al precio de venta';
                    }
                  } catch (e) {
                    return 'Ingrese un número válido';
                  }
                }
                return null;
              },
            ),

            // Mostrar comparación de precios
            const SizedBox(height: 12),
            ValueListenableBuilder(
              valueListenable: widget.precioOfertaController,
              builder: (BuildContext context, TextEditingValue precioOfertaText, _) {
                return ValueListenableBuilder(
                  valueListenable: widget.precioVentaController,
                  builder: (BuildContext context, TextEditingValue precioVentaText, _) {
                    final double precioVenta =
                        double.tryParse(precioVentaText.text) ?? 0;
                    final double precioOferta =
                        double.tryParse(precioOfertaText.text) ?? 0;

                    if (precioOferta <= 0 || precioVenta <= 0) {
                      return Container();
                    }

                    final double ahorro = precioVenta - precioOferta;
                    final num porcentaje = precioVenta > 0
                        ? (ahorro / precioVenta) * 100
                        : 0;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppTheme.smallRadius,
                        ),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Precio original: S/ ${precioVenta.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Precio liquidación: S/ ${precioOferta.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${porcentaje.toStringAsFixed(0)}% descuento',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPromoTypeOption(
    String value,
    String title,
    String description,
    FaIconData icon,
    Color color,
  ) {
    final bool isSelected = _tipoPromocionSeleccionada == value;

    return InkWell(
      onTap: () {
        setState(() {
          _tipoPromocionSeleccionada = value;

          // Si seleccionamos una opción diferente, resetear los campos
          if (value != 'gratis') {
            widget.cantidadGratisDescuentoController.text = '';
          }

          if (value != 'descuentoPorcentual') {
            widget.porcentajeDescuentoController.text = '';
          }

          if (value == 'ninguna') {
            widget.cantidadMinimaDescuentoController.text = '';
          }
        });
        widget.onTipoPromocionSeleccionadaChanged(value);
      },
      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 24,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? color : Colors.white70,
                    width: 2,
                  ),
                  color: isSelected ? color : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: <Widget>[
                  FaIcon(
                    icon,
                    size: 16,
                    color: isSelected ? color : Colors.white70,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: description,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Icon(
                      Icons.help_outline,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductosGratisFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              FaIcon(FontAwesomeIcons.gift, size: 16, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Configuración de Productos Gratis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: widget.cantidadMinimaDescuentoController,
                  decoration: _getInputDecoration(
                    'Cantidad mínima a comprar',
                    helperText: 'Ejemplo: 5 unidades',
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  validator: (String? value) {
                    if (_tipoPromocionSeleccionada == 'gratis') {
                      if (value == null || value.isEmpty) {
                        return 'Campo requerido';
                      }
                      final int? cantidad = int.tryParse(value);
                      if (cantidad == null || cantidad <= 0) {
                        return 'Cantidad inválida';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: widget.cantidadGratisDescuentoController,
                  decoration: _getInputDecoration(
                    'Cantidad gratis',
                    helperText: 'Ejemplo: 1 unidad',
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  validator: (String? value) {
                    if (_tipoPromocionSeleccionada == 'gratis') {
                      if (value == null || value.isEmpty) {
                        return 'Campo requerido';
                      }
                      final int? cantidadGratis = int.tryParse(value);
                      if (cantidadGratis == null || cantidadGratis <= 0) {
                        return 'Cantidad inválida';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Vista previa de la promoción
          ValueListenableBuilder(
            valueListenable: widget.cantidadMinimaDescuentoController,
            builder: (BuildContext context, TextEditingValue cantidadMinimaText, _) {
              return ValueListenableBuilder(
                valueListenable: widget.cantidadGratisDescuentoController,
                builder:
                    (
                      BuildContext context,
                      TextEditingValue cantidadGratisText,
                      _,
                    ) {
                      final int cantidadMinima =
                          int.tryParse(cantidadMinimaText.text) ?? 0;
                      final int cantidadGratis =
                          int.tryParse(cantidadGratisText.text) ?? 0;

                      if (cantidadMinima > 0 && cantidadGratis > 0) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.smallRadius,
                            ),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              const FaIcon(
                                FontAwesomeIcons.circleInfo,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Promoción: Compra ${cantidadMinima + cantidadGratis} al precio de $cantidadMinima',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'El cliente obtendrá $cantidadGratis ${cantidadGratis == 1 ? 'unidad gratis' : 'unidades gratis'} por la compra de $cantidadMinima unidades.',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Container();
                    },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDescuentoPorcentualFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              FaIcon(FontAwesomeIcons.percent, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Configuración de Descuento Porcentual',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: widget.cantidadMinimaDescuentoController,
                  decoration: _getInputDecoration(
                    'Cantidad mínima a comprar',
                    helperText: 'Ejemplo: 3 unidades',
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  validator: (String? value) {
                    if (_tipoPromocionSeleccionada == 'descuentoPorcentual') {
                      if (value == null || value.isEmpty) {
                        return 'Campo requerido';
                      }
                      final int? cantidad = int.tryParse(value);
                      if (cantidad == null || cantidad <= 0) {
                        return 'Cantidad inválida';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: widget.porcentajeDescuentoController,
                  decoration: _getInputDecoration(
                    'Porcentaje de descuento',
                    helperText: 'Ejemplo: 10%',
                    suffixIcon: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('%', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  validator: (String? value) {
                    if (_tipoPromocionSeleccionada == 'descuentoPorcentual') {
                      if (value == null || value.isEmpty) {
                        return 'Campo requerido';
                      }
                      final int? porcentaje = int.tryParse(value);
                      if (porcentaje == null ||
                          porcentaje <= 0 ||
                          porcentaje >= 100) {
                        return 'Porcentaje inválido (1-99)';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Vista previa de la promoción
          ValueListenableBuilder(
            valueListenable: widget.cantidadMinimaDescuentoController,
            builder:
                (BuildContext context, TextEditingValue cantidadMinimaText, _) {
                  return ValueListenableBuilder(
                    valueListenable: widget.porcentajeDescuentoController,
                    builder:
                        (
                          BuildContext context,
                          TextEditingValue porcentajeText,
                          _,
                        ) {
                          final int cantidadMinima =
                              int.tryParse(cantidadMinimaText.text) ?? 0;
                          final int porcentaje =
                              int.tryParse(porcentajeText.text) ?? 0;

                          if (cantidadMinima > 0 &&
                              porcentaje > 0 &&
                              porcentaje < 100) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.smallRadius,
                                ),
                                border: Border.all(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  const FaIcon(
                                    FontAwesomeIcons.circleInfo,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Promoción: Al comprar $cantidadMinima tendras $porcentaje% de descuento',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return Container();
                        },
                  );
                },
          ),
        ],
      ),
    );
  }
}
