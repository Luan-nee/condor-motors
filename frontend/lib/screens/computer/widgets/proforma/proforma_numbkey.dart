import 'dart:async';
import 'dart:developer' as developer;

import 'package:condorsmotors/utils/proforma_utils.dart';
import 'package:condorsmotors/utils/ventas_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  Timer? _processingTimeout;
  BuildContext? processingDialogContext;

  @override
  void initState() {
    super.initState();
    developer.log('Inicializando NumericKeypad');
    _focusNode.requestFocus();
    _customerNameController.text = widget.customerName;
    if (widget.paymentAmount.isNotEmpty) {
      _enteredAmount = widget.paymentAmount;
    }
  }

  @override
  void didUpdateWidget(NumericKeypad oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    _processingTimeout?.cancel();
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

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        processingDialogContext = dialogContext;

        _processingTimeout = Timer(const Duration(seconds: 30), () {
          _closeProcessingDialog();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'El proceso ha tardado demasiado. Por favor intente nuevamente.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });

        return ProformaUtils.buildProcessingDialog(widget.documentType);
      },
    );
  }

  void _closeProcessingDialog() {
    if (processingDialogContext != null) {
      Navigator.of(processingDialogContext!).pop();
      processingDialogContext = null;
    }
    _processingTimeout?.cancel();
  }

  Future<void> _handleKeyEvent(String key) async {
    if (widget.isProcessing) {
      return;
    }

    try {
      if (key == 'Enter') {
        if (!_esMontoSuficiente()) {
          return;
        }

        _showProcessingDialog();

        try {
          final double montoIngresado = double.tryParse(_enteredAmount) ?? 0;
          await widget.onCharge(montoIngresado);
          widget.onSubmit();
          _closeProcessingDialog();
        } catch (e) {
          _closeProcessingDialog();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al procesar el pago: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else if (key == 'Backspace') {
        developer.log('Borrando último dígito');
        if (_enteredAmount.isNotEmpty) {
          setState(() {
            _enteredAmount =
                _enteredAmount.substring(0, _enteredAmount.length - 1);
            widget.onKeyPressed(_enteredAmount);
          });
        }
      } else if (_enteredAmount.length < 10) {
        setState(() {
          if (_enteredAmount.isEmpty && key == '.') {
            _enteredAmount = '0.';
          } else if (key == '.' && _enteredAmount.contains('.')) {
            return;
          } else {
            _enteredAmount += key;
          }
          widget.onKeyPressed(_enteredAmount);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la tecla: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleClearClick() {
    developer.log('Limpiando campo de monto');
    setState(() {
      _enteredAmount = '';
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
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
                                  if (newValue == 'Boleta' &&
                                      !widget.puedeEmitirBoleta) {
                                    return;
                                  }
                                  if (newValue == 'Factura' &&
                                      !widget.puedeEmitirFactura) {
                                    return;
                                  }
                                  widget.onDocumentTypeChanged(newValue);
                                }
                              },
                        items: <DropdownMenuItem<String>>[
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
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
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Expanded(child: _buildNumberKeyButton('1')),
                        Expanded(child: _buildNumberKeyButton('2')),
                        Expanded(child: _buildNumberKeyButton('3')),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Expanded(child: _buildNumberKeyButton('4')),
                        Expanded(child: _buildNumberKeyButton('5')),
                        Expanded(child: _buildNumberKeyButton('6')),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Expanded(child: _buildNumberKeyButton('7')),
                        Expanded(child: _buildNumberKeyButton('8')),
                        Expanded(child: _buildNumberKeyButton('9')),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Expanded(child: _buildNumberKeyButton('.')),
                        Expanded(child: _buildNumberKeyButton('0')),
                        Expanded(
                          child: _buildActionButton(
                            icon: const Icon(Icons.backspace,
                                color: Colors.white70),
                            label: 'Borrar',
                            onPressed: _handleClearClick,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              icon: const Icon(Icons.payment,
                                  color: Color(0xFFE31E24), size: 20),
                              label: 'Cobrar',
                              onPressed: () => _handleKeyEvent('Enter'),
                              isEnabled: _esMontoSuficiente(),
                            ),
                          ),
                        ],
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
    return Container(
      padding: const EdgeInsets.all(2.0),
      child: AspectRatio(
        aspectRatio: 1,
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
    );
  }

  Widget _buildActionButton({
    required Icon icon,
    required String label,
    required VoidCallback onPressed,
    bool isEnabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(2.0),
      child: AspectRatio(
        aspectRatio: 1,
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
    );
  }

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
    properties
      ..add(DoubleProperty('change', change))
      ..add(StringProperty('formattedChange', formattedChange))
      ..add(DiagnosticsProperty<BuildContext?>(
          'processingDialogContext', processingDialogContext));
  }
}
