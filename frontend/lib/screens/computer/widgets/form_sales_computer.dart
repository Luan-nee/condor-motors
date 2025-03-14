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
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE31E24)),
                strokeWidth: 4,
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
  });

  @override
  State<NumericKeypad> createState() => _NumericKeypadState();
}

class _NumericKeypadState extends State<NumericKeypad> {
  final _focusNode = FocusNode();
  final _customerNameController = TextEditingController();
  final _changeController = TextEditingController();
  bool _isManualChange = false;

  @override
  void initState() {
    super.initState();
    _customerNameController.text = widget.customerName;
    _focusNode.requestFocus();
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
    final total = double.tryParse(widget.currentAmount) ?? 0;
    final payment = double.tryParse(widget.paymentAmount) ?? 0;
    return payment - total;
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      widget.onSubmit();
    } else if (key == LogicalKeyboardKey.backspace) {
      widget.onClear();
    } else if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
      widget.onKeyPressed('0');
    } else if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      widget.onKeyPressed('1');
    } else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      widget.onKeyPressed('2');
    } else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      widget.onKeyPressed('3');
    } else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
      widget.onKeyPressed('4');
    } else if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
      widget.onKeyPressed('5');
    } else if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
      widget.onKeyPressed('6');
    } else if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
      widget.onKeyPressed('7');
    } else if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
      widget.onKeyPressed('8');
    } else if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
      widget.onKeyPressed('9');
    } else if (key == LogicalKeyboardKey.period || key == LogicalKeyboardKey.numpadDecimal) {
      widget.onKeyPressed('.');
    }
  }

  void _handleChangeClick() {
    setState(() {
      _isManualChange = true;
      _changeController.text = change.toStringAsFixed(2);
    });
  }

  void _handleChangeChanged(String value) {
    setState(() {
      _changeController.text = value;
    });
  }

  void _handleChangeFocusLost() {
    setState(() {
      _isManualChange = false;
      _changeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Información del cliente y tipo de documento
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Campo de nombre del cliente
                    TextField(
                      controller: _customerNameController,
                      onChanged: widget.onCustomerNameChanged,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Cliente',
                        labelStyle: TextStyle(color: Colors.white54),
                        prefixIcon: FaIcon(FontAwesomeIcons.user, color: Color(0xFFE31E24), size: 16),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE31E24)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Selector de tipo de documento
                    Row(
                      children: [
                        _buildDocumentTypeButton(
                          'Boleta',
                          FontAwesomeIcons.receipt,
                          widget.documentType == 'Boleta',
                          () => widget.onDocumentTypeChanged('Boleta'),
                        ),
                        const SizedBox(width: 8),
                        _buildDocumentTypeButton(
                          'Factura',
                          FontAwesomeIcons.fileInvoiceDollar,
                          widget.documentType == 'Factura',
                          () => widget.onDocumentTypeChanged('Factura'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Display de montos
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'TOTAL A COBRAR',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'S/ ${widget.currentAmount.isEmpty ? '0.00' : widget.currentAmount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(color: Colors.white24),
                    const Text(
                      'PAGO CON',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'S/ ${widget.paymentAmount.isEmpty ? '0.00' : widget.paymentAmount}',
                      style: TextStyle(
                        color: change >= 0 ? Colors.green : Colors.red,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (change != 0) ...[
                      const Divider(color: Colors.white24),
                      const Text(
                        'VUELTO',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: _handleChangeClick,
                        child: TextField(
                          controller: _changeController,
                          enabled: _isManualChange,
                          onChanged: _handleChangeChanged,
                          onEditingComplete: _handleChangeFocusLost,
                          onSubmitted: (_) => _handleChangeFocusLost(),
                          style: TextStyle(
                            color: change >= 0 ? Colors.green : Colors.red,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'S/ ${change.abs().toStringAsFixed(2)}',
                            hintStyle: TextStyle(
                              color: change >= 0 ? Colors.green : Colors.red,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Teclado numérico
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildNumberKey('7'),
                            _buildNumberKey('8'),
                            _buildNumberKey('9'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildNumberKey('4'),
                            _buildNumberKey('5'),
                            _buildNumberKey('6'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildNumberKey('1'),
                            _buildNumberKey('2'),
                            _buildNumberKey('3'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildNumberKey('00'),
                            _buildNumberKey('0'),
                            _buildNumberKey('.'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Columna de acciones
                  Column(
                    children: [
                      _buildActionButton(
                        onPressed: widget.onClear,
                        icon: FontAwesomeIcons.deleteLeft,
                        color: Colors.orange,
                        text: 'BORRAR',
                      ),
                      const SizedBox(height: 8),
                      _buildActionButton(
                        onPressed: change >= 0 && !widget.isProcessing ? widget.onSubmit : null,
                        icon: widget.isProcessing ? FontAwesomeIcons.spinner : FontAwesomeIcons.check,
                        color: const Color(0xFFE31E24),
                        text: widget.isProcessing ? 'PROCESANDO' : 'COBRAR',
                        height: 156,
                        isLoading: widget.isProcessing,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberKey(String number) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: TextButton(
          onPressed: () => widget.onKeyPressed(number),
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required Color color,
    required String text,
    double height = 72,
    bool isLoading = false,
  }) {
    return Container(
      width: 100,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: onPressed == null 
              ? Colors.grey.withOpacity(0.1) 
              : color.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: onPressed == null ? Colors.grey : color,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              FaIcon(icon, color: onPressed == null ? Colors.grey : color, size: 20),
            const SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                color: onPressed == null ? Colors.grey : color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTypeButton(
    String text,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE31E24).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFE31E24) : Colors.white24,
            ),
          ),
          child: Column(
            children: [
              FaIcon(
                icon,
                color: isSelected ? const Color(0xFFE31E24) : Colors.white54,
                size: 16,
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFE31E24) : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
