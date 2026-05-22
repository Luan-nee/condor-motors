import 'package:condorsmotors/theme/apptheme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Un campo de entrada de búsqueda premium estilo HUD táctico para el panel de administración.
///
/// Encapsula la reactividad al foco visual con sombreado de brillo sutil en
/// el color primario y animación geométrica fluida.
class SearchBarAdmin extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final FocusNode? focusNode;

  const SearchBarAdmin({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<SearchBarAdmin> createState() => _SearchBarAdminState();
}

class _SearchBarAdminState extends State<SearchBarAdmin> {
  FocusNode? _internalFocusNode;
  bool _isFocused = false;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    _internalFocusNode?.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _effectiveFocusNode.hasFocus;
      });
    }
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      height: 40,
      decoration: BoxDecoration(
        color: _isFocused ? const Color(0xFF242424) : const Color(0xFF1D1D1D),
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(
          color: _isFocused
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 14),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: FaIcon(
              FontAwesomeIcons.magnifyingGlass,
              color: _isFocused
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.35),
              size: 14,
            ),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _effectiveFocusNode,
              enabled: widget.enabled,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: kFontFamily,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 14,
                ),
                // ANULACIÓN TOTAL DEL TEMA DE DECORACIÓN GLOBAL
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                suffixIcon: widget.controller.text.isNotEmpty
                    ? IconButton(
                        hoverColor: Colors.white.withValues(alpha: 0.05),
                        splashColor: Colors.white.withValues(alpha: 0.1),
                        icon: const Icon(
                          Icons.clear,
                          size: 16,
                          color: Colors.white54,
                        ),
                        onPressed: () {
                          widget.controller.clear();
                          widget.onChanged?.call('');
                        },
                      )
                    : null,
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
