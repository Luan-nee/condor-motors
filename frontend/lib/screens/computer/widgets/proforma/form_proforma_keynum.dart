import 'package:condorsmotors/utils/ventas_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  String _enteredAmount = '';
  bool _isClearingAll = false;

  @override
  void initState() {
    super.initState();
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
    if (widget.customerName != oldWidget.customerName) {
      _customerNameController.text = widget.customerName;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  double get change {
    final double total = double.tryParse(widget.currentAmount) ?? 0;
    final double payment =
        double.tryParse(_enteredAmount.isEmpty ? '0' : _enteredAmount) ?? 0;
    return payment - total;
  }

  bool get isSufficient =>
      _enteredAmount.isNotEmpty &&
      (double.tryParse(_enteredAmount) ?? 0) >= widget.minAmount;

  void _handleKeyEvent(String key) {
    if (widget.isProcessing) {
      return;
    }
    if (key == 'Enter') {
      final double montoIngresado =
          double.tryParse(_enteredAmount.isEmpty ? '0' : _enteredAmount) ?? 0;
      if (_enteredAmount.isNotEmpty && montoIngresado >= widget.minAmount) {
        widget.onCharge(montoIngresado);
      }
      return;
    }
    if (key == 'Backspace') {
      if (_enteredAmount.isNotEmpty) {
        setState(() {
          _enteredAmount =
              _enteredAmount.substring(0, _enteredAmount.length - 1);
          widget.onKeyPressed(_enteredAmount);
        });
      }
      return;
    }
    if (_enteredAmount.length < 10) {
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
  }

  void _handleClearClick() {
    setState(() {
      _enteredAmount = '';
      widget.onKeyPressed('');
    });
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const FaIcon(FontAwesomeIcons.user, color: Color(0xFFE31E24), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _customerNameController,
            onChanged: widget.onCustomerNameChanged,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            decoration: const InputDecoration(
              labelText: 'Cliente',
              labelStyle: TextStyle(color: Colors.white54),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: widget.documentType,
            dropdownColor: const Color(0xFF232323),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            onChanged: widget.isProcessing
                ? null
                : (String? newValue) {
                    if (newValue != null) {
                      if (newValue == 'Boleta' && !widget.puedeEmitirBoleta) {
                        return;
                      }
                      if (newValue == 'Factura' && !widget.puedeEmitirFactura) {
                        return;
                      }
                      widget.onDocumentTypeChanged(newValue);
                    }
                  },
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: 'Boleta',
                enabled: widget.puedeEmitirBoleta,
                child: Row(
                  children: [
                    Icon(Icons.receipt_long,
                        color: widget.puedeEmitirBoleta
                            ? Colors.white
                            : Colors.white38,
                        size: 18),
                    const SizedBox(width: 4),
                    Text('Boleta',
                        style: TextStyle(
                            color: widget.puedeEmitirBoleta
                                ? Colors.white
                                : Colors.white38)),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'Factura',
                enabled: widget.puedeEmitirFactura,
                child: Row(
                  children: [
                    Icon(Icons.description,
                        color: widget.puedeEmitirFactura
                            ? Colors.white
                            : Colors.white38,
                        size: 18),
                    const SizedBox(width: 4),
                    Text('Factura',
                        style: TextStyle(
                            color: widget.puedeEmitirFactura
                                ? Colors.white
                                : Colors.white38)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountCard({
    required String label,
    required String value,
    Color? color,
    IconData? icon,
  }) {
    return Card(
      color: color?.withOpacity(0.13) ?? const Color(0xFF232323),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color ?? Colors.white54, size: 22),
              const SizedBox(height: 2),
            ],
            Text(label,
                style: TextStyle(
                    color: color ?? Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    color: color ?? Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
          ],
        ),
      ),
    );
  }

  String _formatearMoneda(double monto) {
    // Siempre anteponer 'S/' al número
    return 'S/ ${VentasUtils.formatearMonto(monto)}';
  }

  Widget _buildSummaryRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: _buildAmountCard(
            label: 'Total',
            value: _formatearMoneda(double.tryParse(widget.currentAmount) ?? 0),
            color: Colors.blue,
            icon: Icons.attach_money,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildAmountCard(
            label: 'Recibido',
            value: _formatearMoneda(double.tryParse(
                    _enteredAmount.isEmpty ? '0' : _enteredAmount) ??
                0),
            color: Colors.orange,
            icon: Icons.payments,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildAmountCard(
            label: 'Vuelto',
            value: isSufficient ? _formatearMoneda(change) : '--',
            color: isSufficient ? Colors.green : Colors.white38,
            icon: Icons.change_circle,
          ),
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String label,
      {Color? color,
      VoidCallback? onTap,
      bool filled = false,
      bool enabled = true,
      IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: filled
              ? (enabled
                  ? (color ?? Colors.blue).withOpacity(0.15)
                  : Colors.grey.withOpacity(0.08))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled
                ? (color ?? Colors.white24)
                : Colors.grey.withOpacity(0.2),
            width: 1.2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? onTap : null,
            child: SizedBox(
              height: 56,
              child: Center(
                child: icon != null
                    ? Icon(icon,
                        color: enabled ? (color ?? Colors.white) : Colors.grey,
                        size: 26)
                    : Text(
                        label,
                        style: TextStyle(
                          fontSize: 24,
                          color:
                              enabled ? (color ?? Colors.white) : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          children: [
            Flexible(
                child:
                    _buildKeypadButton('1', onTap: () => _handleKeyEvent('1'))),
            Flexible(
                child:
                    _buildKeypadButton('2', onTap: () => _handleKeyEvent('2'))),
            Flexible(
                child:
                    _buildKeypadButton('3', onTap: () => _handleKeyEvent('3'))),
          ],
        ),
        Row(
          children: [
            Flexible(
                child:
                    _buildKeypadButton('4', onTap: () => _handleKeyEvent('4'))),
            Flexible(
                child:
                    _buildKeypadButton('5', onTap: () => _handleKeyEvent('5'))),
            Flexible(
                child:
                    _buildKeypadButton('6', onTap: () => _handleKeyEvent('6'))),
          ],
        ),
        Row(
          children: [
            Flexible(
                child:
                    _buildKeypadButton('7', onTap: () => _handleKeyEvent('7'))),
            Flexible(
                child:
                    _buildKeypadButton('8', onTap: () => _handleKeyEvent('8'))),
            Flexible(
                child:
                    _buildKeypadButton('9', onTap: () => _handleKeyEvent('9'))),
          ],
        ),
        Row(
          children: [
            Flexible(
                child:
                    _buildKeypadButton('.', onTap: () => _handleKeyEvent('.'))),
            Flexible(
                child:
                    _buildKeypadButton('0', onTap: () => _handleKeyEvent('0'))),
            Flexible(
                child: _buildKeypadButton(
              '',
              icon: Icons.backspace,
              color: Colors.orange,
              onTap: _handleClearClick,
              filled: true,
              enabled: _enteredAmount.isNotEmpty,
            )),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        final LogicalKeyboardKey key = event.logicalKey;
        // Si es repetición de Backspace o Space, borrar todo y animar
        if (event is KeyRepeatEvent &&
            (key == LogicalKeyboardKey.backspace ||
                key == LogicalKeyboardKey.space)) {
          if (_enteredAmount.isNotEmpty) {
            setState(() {
              _enteredAmount = '';
              widget.onKeyPressed('');
              _isClearingAll = true;
            });
          } else {
            setState(() {
              _isClearingAll = true;
            });
          }
          return;
        }
        // Al soltar la tecla, quitar animación
        if (event is KeyUpEvent &&
            (key == LogicalKeyboardKey.backspace ||
                key == LogicalKeyboardKey.space)) {
          if (_isClearingAll) {
            setState(() {
              _isClearingAll = false;
            });
          }
          return;
        }
        // KeyDown: comportamiento normal
        if (event is! KeyDownEvent) {
          return;
        }
        // Números (fila superior y numpad)
        if (key == LogicalKeyboardKey.digit0 ||
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
        }
        // Punto o coma decimal
        else if (key == LogicalKeyboardKey.period ||
            key == LogicalKeyboardKey.numpadDecimal ||
            key == LogicalKeyboardKey.comma) {
          _handleKeyEvent('.');
        }
        // Enter
        else if (key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) {
          _handleKeyEvent('Enter');
        }
        // Backspace y Delete
        else if (key == LogicalKeyboardKey.backspace ||
            key == LogicalKeyboardKey.delete) {
          _handleKeyEvent('Backspace');
        }
        // Ignorar otras teclas
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF232323),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSummaryRow(),
            const SizedBox(height: 16),
            Spacer(),
            _buildKeypad(),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('change', change))
      ..add(DiagnosticsProperty<bool>('isSufficient', isSufficient));
  }
}
