import 'dart:developer' as developer;

import 'package:condorsmotors/models/proforma.model.dart';
import 'package:condorsmotors/providers/computer/proforma.computer.provider.dart';
import 'package:condorsmotors/screens/computer/widgets/proforma/proforma_utils.dart';
import 'package:condorsmotors/utils/documento_utils.dart';
import 'package:condorsmotors/utils/ventas_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class ProcessingDialog extends StatelessWidget {
  final String documentType;

  const ProcessingDialog({
    super.key,
    required this.documentType,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Procesando pago...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Imprimiendo ${documentType.toLowerCase()}...',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('documentType', documentType));
  }
}

class NumericKeypad extends StatefulWidget {
  final Function(String) onKeyPressed;
  final VoidCallback onClear;
  final VoidCallback onSubmit;
  final String currentAmount;
  final String paymentAmount;
  final String customerName;
  final String documentType;
  final Function(String) onCustomerNameChanged;
  final Function(String) onDocumentTypeChanged;
  final bool isProcessing;
  final double minAmount;
  final Function(double) onCharge;
  final bool puedeEmitirBoleta;
  final bool puedeEmitirFactura;

  const NumericKeypad({
    super.key,
    required this.onKeyPressed,
    required this.onClear,
    required this.onSubmit,
    required this.currentAmount,
    required this.paymentAmount,
    required this.customerName,
    required this.documentType,
    required this.onCustomerNameChanged,
    required this.onDocumentTypeChanged,
    required this.isProcessing,
    required this.minAmount,
    required this.onCharge,
    this.puedeEmitirBoleta = true,
    this.puedeEmitirFactura = true,
  });

  @override
  State<NumericKeypad> createState() => _NumericKeypadState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('customerName', customerName))
      ..add(ObjectFlagProperty<VoidCallback>.has('onSubmit', onSubmit))
      ..add(ObjectFlagProperty<Function(String)>.has(
          'onKeyPressed', onKeyPressed))
      ..add(ObjectFlagProperty<VoidCallback>.has('onClear', onClear))
      ..add(StringProperty('currentAmount', currentAmount))
      ..add(StringProperty('paymentAmount', paymentAmount))
      ..add(StringProperty('documentType', documentType))
      ..add(ObjectFlagProperty<Function(String)>.has(
          'onCustomerNameChanged', onCustomerNameChanged))
      ..add(ObjectFlagProperty<Function(String)>.has(
          'onDocumentTypeChanged', onDocumentTypeChanged))
      ..add(DiagnosticsProperty<bool>('isProcessing', isProcessing))
      ..add(DoubleProperty('minAmount', minAmount))
      ..add(ObjectFlagProperty<Function(double)>.has('onCharge', onCharge))
      ..add(DiagnosticsProperty<bool>('puedeEmitirBoleta', puedeEmitirBoleta))
      ..add(
          DiagnosticsProperty<bool>('puedeEmitirFactura', puedeEmitirFactura));
  }
}

class _NumericKeypadState extends State<NumericKeypad> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _changeController = TextEditingController();
  final bool _isManualChange = false;
  String _enteredAmount = '';

  @override
  void initState() {
    super.initState();
    developer.log('Inicializando NumericKeypad');
    _focusNode.requestFocus();
    _customerNameController.text = widget.customerName;
    // Establecer valores iniciales si es necesario
    if (widget.paymentAmount.isNotEmpty) {
      _enteredAmount = widget.paymentAmount;
    }
  }

  @override
  void didUpdateWidget(NumericKeypad oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Actualizar el monto si cambia desde el componente padre
    if (widget.paymentAmount != oldWidget.paymentAmount &&
        widget.paymentAmount != _enteredAmount) {
      setState(() {
        _enteredAmount = widget.paymentAmount;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _customerNameController.dispose();
    _changeController.dispose();
    super.dispose();
  }

  double get change {
    if (_isManualChange) {
      return double.tryParse(_changeController.text) ?? 0;
    }
    final double total = double.tryParse(widget.currentAmount) ?? 0;
    final double payment =
        double.tryParse(_enteredAmount.isEmpty ? '0' : _enteredAmount) ?? 0;
    return payment - total;
  }

  String get formattedChange {
    return VentasUtils.formatearMonto(change);
  }

  void _handleKeyEvent(String key) {
    developer.log('Tecla presionada: $key');

    if (key == 'Enter') {
      developer.log(
          'Intentando ejecutar onCharge - Monto ingresado: $_enteredAmount');
      final double montoIngresado =
          double.tryParse(_enteredAmount.isEmpty ? '0' : _enteredAmount) ?? 0;
      if (_enteredAmount.isNotEmpty && montoIngresado >= widget.minAmount) {
        developer.log('Ejecutando onCharge con monto: $montoIngresado');
        widget.onCharge(montoIngresado);
      } else {
        developer.log('Monto insuficiente para ejecutar onCharge');
      }
      return;
    }

    if (key == 'Backspace') {
      developer.log('Borrando último dígito');
      if (_enteredAmount.isNotEmpty) {
        setState(() {
          _enteredAmount =
              _enteredAmount.substring(0, _enteredAmount.length - 1);
          // Sincronizar con el componente padre
          widget.onKeyPressed(_enteredAmount);
        });
      }
      return;
    }

    // Si es un número y no sobrepasa el máximo de dígitos
    if (_enteredAmount.length < 10) {
      setState(() {
        // Si estamos empezando y el usuario presiona el punto, agregamos "0."
        if (_enteredAmount.isEmpty && key == '.') {
          _enteredAmount = '0.';
        }
        // Si ya existe un punto, no permitir agregar otro
        else if (key == '.' && _enteredAmount.contains('.')) {
          return;
        }
        // Agregar dígito normalmente
        else {
          _enteredAmount += key;
        }

        // Sincronizar con el componente padre
        widget.onKeyPressed(_enteredAmount);
      });
    }
  }

  void _handleClearClick() {
    developer.log('Limpiando campo de monto');
    setState(() {
      _enteredAmount = '';
      // Sincronizar con el componente padre
      widget.onKeyPressed('');
    });
  }

  @override
  Widget build(BuildContext context) {
    developer.log('Construyendo NumericKeypad');
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        if (event is! KeyDownEvent) {
          return;
        }

        final LogicalKeyboardKey key = event.logicalKey;
        developer.log('Tecla física presionada: ${key.keyLabel}');

        if (key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) {
          _handleKeyEvent('Enter');
        } else if (key == LogicalKeyboardKey.backspace) {
          _handleKeyEvent('Backspace');
        } else if (key == LogicalKeyboardKey.digit0 ||
            key == LogicalKeyboardKey.numpad0) {
          _handleKeyEvent('0');
        } else if (key == LogicalKeyboardKey.digit1 ||
            key == LogicalKeyboardKey.numpad1) {
          _handleKeyEvent('1');
        } else if (key == LogicalKeyboardKey.digit2 ||
            key == LogicalKeyboardKey.numpad2) {
          _handleKeyEvent('2');
        } else if (key == LogicalKeyboardKey.digit3 ||
            key == LogicalKeyboardKey.numpad3) {
          _handleKeyEvent('3');
        } else if (key == LogicalKeyboardKey.digit4 ||
            key == LogicalKeyboardKey.numpad4) {
          _handleKeyEvent('4');
        } else if (key == LogicalKeyboardKey.digit5 ||
            key == LogicalKeyboardKey.numpad5) {
          _handleKeyEvent('5');
        } else if (key == LogicalKeyboardKey.digit6 ||
            key == LogicalKeyboardKey.numpad6) {
          _handleKeyEvent('6');
        } else if (key == LogicalKeyboardKey.digit7 ||
            key == LogicalKeyboardKey.numpad7) {
          _handleKeyEvent('7');
        } else if (key == LogicalKeyboardKey.digit8 ||
            key == LogicalKeyboardKey.numpad8) {
          _handleKeyEvent('8');
        } else if (key == LogicalKeyboardKey.digit9 ||
            key == LogicalKeyboardKey.numpad9) {
          _handleKeyEvent('9');
        } else if (key == LogicalKeyboardKey.period ||
            key == LogicalKeyboardKey.numpadDecimal) {
          _handleKeyEvent('.');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Información del cliente
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Campo de nombre del cliente
                  Row(
                    children: <Widget>[
                      const FaIcon(FontAwesomeIcons.user,
                          color: Color(0xFFE31E24), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _customerNameController,
                          onChanged: widget.onCustomerNameChanged,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Nombre del Cliente',
                            labelStyle: TextStyle(color: Colors.white54),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFE31E24)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Selector de tipo de documento
                  Row(
                    children: <Widget>[
                      const Text(
                        'Tipo de documento:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: widget.documentType,
                        dropdownColor: const Color(0xFF2D2D2D),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        onChanged: widget.isProcessing
                            ? null
                            : (String? newValue) {
                                if (newValue != null) {
                                  // Verificar si el tipo de documento seleccionado está permitido
                                  if (newValue == 'Boleta' &&
                                      !widget.puedeEmitirBoleta) {
                                    return; // No permitir seleccionar boleta
                                  }
                                  if (newValue == 'Factura' &&
                                      !widget.puedeEmitirFactura) {
                                    return; // No permitir seleccionar factura
                                  }
                                  widget.onDocumentTypeChanged(newValue);
                                }
                              },
                        items: <DropdownMenuItem<String>>[
                          // Boleta - Deshabilitada si no se puede emitir
                          DropdownMenuItem<String>(
                            value: 'Boleta',
                            enabled: widget.puedeEmitirBoleta,
                            child: Text(
                              'Boleta',
                              style: TextStyle(
                                color: widget.puedeEmitirBoleta
                                    ? Colors.white
                                    : Colors.white38,
                              ),
                            ),
                          ),
                          // Factura - Deshabilitada si no se puede emitir
                          DropdownMenuItem<String>(
                            value: 'Factura',
                            enabled: widget.puedeEmitirFactura,
                            child: Text(
                              'Factura',
                              style: TextStyle(
                                color: widget.puedeEmitirFactura
                                    ? Colors.white
                                    : Colors.white38,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Total, monto a pagar y cambio en la misma fila
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  // Total a pagar
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        const Text(
                          'TOTAL A PAGAR',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          VentasUtils.formatearMontoTexto(
                              double.tryParse(widget.currentAmount) ?? 0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Monto recibido
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        const Text(
                          'MONTO RECIBIDO',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          VentasUtils.formatearMontoTexto(double.tryParse(
                                  _enteredAmount.isEmpty
                                      ? '0'
                                      : _enteredAmount) ??
                              0),
                          style: TextStyle(
                            color: _enteredAmount.isNotEmpty &&
                                    double.parse(_enteredAmount.isEmpty
                                            ? '0'
                                            : _enteredAmount) >=
                                        widget.minAmount
                                ? const Color(0xFF4CAF50)
                                : Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Cambio a devolver (visible solo si hay suficiente monto)
                  if (_esMontoSuficiente())
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          const Text(
                            'CAMBIO A DEVOLVER',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formattedChange,
                            style: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Teclado numérico
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Fila 1: 1, 2, 3
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        _buildNumberKeyButton('1'),
                        _buildNumberKeyButton('2'),
                        _buildNumberKeyButton('3'),
                      ],
                    ),
                  ),
                  // Fila 2: 4, 5, 6
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        _buildNumberKeyButton('4'),
                        _buildNumberKeyButton('5'),
                        _buildNumberKeyButton('6'),
                      ],
                    ),
                  ),
                  // Fila 3: 7, 8, 9
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        _buildNumberKeyButton('7'),
                        _buildNumberKeyButton('8'),
                        _buildNumberKeyButton('9'),
                      ],
                    ),
                  ),
                  // Fila 4: ., 0, Borrar
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        _buildNumberKeyButton('.'),
                        _buildNumberKeyButton('0'),
                        _buildActionButton(
                          icon: const Icon(Icons.backspace,
                              color: Colors.white70),
                          label: 'Borrar',
                          onPressed: _handleClearClick,
                        ),
                      ],
                    ),
                  ),
                  // Botón de Cobrar
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: _buildActionButton(
                        icon: const Icon(Icons.payment,
                            color: Color(0xFFE31E24), size: 20),
                        label: 'Cobrar',
                        onPressed: () => _handleKeyEvent('Enter'),
                        isEnabled: _esMontoSuficiente(),
                      ),
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

  Widget _buildNumberKeyButton(String number) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(2.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                developer.log('Botón numérico presionado: $number');
                _handleKeyEvent(number);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required Icon icon,
    required String label,
    required VoidCallback onPressed,
    bool isEnabled = true,
  }) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(2.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isEnabled
                  ? () {
                      developer.log('Botón de acción presionado: $label');
                      onPressed();
                    }
                  : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: isEnabled
                      ? (label == 'Cobrar'
                          ? const Color(0xFFE31E24).withOpacity(0.1)
                          : Colors.transparent)
                      : Colors.grey.withOpacity(0.1),
                  border: Border.all(
                    color: isEnabled
                        ? (label == 'Cobrar'
                            ? const Color(0xFFE31E24)
                            : Colors.white24)
                        : Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    icon,
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: isEnabled
                            ? (label == 'Cobrar'
                                ? const Color(0xFFE31E24)
                                : Colors.white)
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Verifica si el monto ingresado es suficiente para realizar el pago
  ///
  /// Compara _enteredAmount con widget.minAmount para determinar si
  /// se puede proceder con el cobro.
  ///
  /// Retorna true si el monto es suficiente, false en caso contrario.
  bool _esMontoSuficiente() {
    if (_enteredAmount.isEmpty) {
      return false;
    }
    final double montoIngresado = double.tryParse(_enteredAmount) ?? 0;
    return montoIngresado >= widget.minAmount;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('change', change));
    properties.add(StringProperty('formattedChange', formattedChange));
  }
}

class ProformaSaleDialog extends StatelessWidget {
  final Proforma proforma;
  final Function(Map<String, dynamic>) onConfirm;
  final VoidCallback onCancel;

  const ProformaSaleDialog({
    super.key,
    required this.proforma,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // Obtener el provider de proformas
    final proformaProvider = Provider.of<ProformaComputerProvider>(
      context,
      listen: false,
    );

    return Dialog(
      backgroundColor: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.fileInvoiceDollar,
                    size: 20,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Convertir Proforma a Venta',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: onCancel,
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),

            // Detalles de la proforma
            Text(
              'Proforma #${proforma.id} - ${VentasPendientesUtils.formatearFecha(proforma.fechaCreacion)}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cliente: ${proforma.cliente?['nombre'] ?? 'Sin nombre'}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            Text(
              'Fecha: ${VentasPendientesUtils.formatearFecha(proforma.fechaCreacion)}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),

            // Lista de productos
            const Text(
              'Productos:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: <Widget>[
                  for (DetalleProforma detalle in proforma.detalles)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            flex: 5,
                            child: Text(
                              detalle.nombre,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${detalle.cantidad}x',
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              VentasUtils.formatearMontoTexto(
                                  detalle.precioUnitario),
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              VentasUtils.formatearMontoTexto(detalle.subtotal),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(color: Colors.white24),
                  Row(
                    children: <Widget>[
                      const Spacer(),
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        VentasUtils.formatearMontoTexto(proforma.total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Preparar la venta desde la proforma
                    final Map<String, dynamic> ventaData =
                        VentasPendientesUtils.convertirProformaAVentaPendiente(
                            proforma);

                    // También podríamos usar una función de utilidad del provider:
                    // final ventaData = proformaProvider.prepararVentaDesdeProforma(proforma);

                    onConfirm(ventaData);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Convertir a Venta'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Proforma>('proforma', proforma))
      ..add(ObjectFlagProperty<Function(Map<String, dynamic>)>.has(
          'onConfirm', onConfirm))
      ..add(ObjectFlagProperty<VoidCallback>.has('onCancel', onCancel));
  }
}
