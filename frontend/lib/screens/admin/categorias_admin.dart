import 'package:condorsmotors/models/categoria.model.dart';
import 'package:condorsmotors/providers/admin/categorias.admin.riverpod.dart';
import 'package:condorsmotors/theme/apptheme.dart';
import 'package:condorsmotors/widgets/common/empty_state.widget.dart';
import 'package:condorsmotors/widgets/common/error_banner.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CategoriasAdminScreen extends ConsumerStatefulWidget {
  const CategoriasAdminScreen({super.key});

  @override
  ConsumerState<CategoriasAdminScreen> createState() => _CategoriasAdminScreenState();
}

class _CategoriasAdminScreenState extends ConsumerState<CategoriasAdminScreen> {

  void _mostrarFormularioCategoria(CategoriasAdmin notifier, [Categoria? categoria]) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => _CategoriaFormDialog(
        categoria: categoria,
        onSave: (String nombre, String? descripcion) async {
          final messenger = ScaffoldMessenger.of(context);
          try {
            await notifier.guardarCategoria(
              categoria: categoria,
              nombre: nombre,
              descripcion: descripcion,
            );

            if (!dialogContext.mounted) {
              return;
            }
            Navigator.pop(dialogContext);

            messenger.showSnackBar(
              SnackBar(
                content: Text(categoria == null ? 'Categoría creada' : 'Categoría actualizada'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            // Error managed by StateNotifier
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoriasAdminProvider);
    final notifier = ref.read(categoriasAdminProvider.notifier);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    FaIcon(FontAwesomeIcons.folderTree, color: Colors.white, size: 24),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'CATEGORÍAS',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'gestión de categorías',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    SizedBox(
                      height: 46,
                      width: 46,
                      child: Tooltip(
                        message: state.isLoading
                            ? 'Recargando...'
                            : 'Recargar categorías',
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.surfaceColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                            ),
                            elevation: 0,
                          ),
                          onPressed: state.isLoading
                              ? null
                              : () =>
                                  notifier.cargarCategorias(forceRefresh: true),
                          child: state.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const FaIcon(FontAwesomeIcons.arrowsRotate,
                                  size: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        icon: const FaIcon(FontAwesomeIcons.plus,
                            size: 14, color: Colors.white),
                        label: const Text('Nuevo',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _mostrarFormularioCategoria(notifier),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (state.hasError && !state.isLoading)
              ErrorBanner(
                message: state.error.toString(),
                onClose: notifier.limpiarError,
              ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: _buildTableContent(state, notifier),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: const Row(
        children: <Widget>[
          Expanded(
              flex: 30,
              child: Text('Categoría',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(
              flex: 40,
              child: Text('Descripción',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(
              flex: 15,
              child: Text('Cant. de productos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(
              flex: 15,
              child: Text('Acciones',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildTableContent(AsyncValue<List<Categoria>> state, CategoriasAdmin notifier) {
    final categorias = state.value ?? const [];

    if (categorias.isEmpty && !state.isLoading) {
      return EmptyState(
        icon: FontAwesomeIcons.folderOpen,
        message: 'No hay categorías disponibles',
        buttonLabel: 'Crear categoría',
        onAction: () => _mostrarFormularioCategoria(notifier),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildTableHeader(),
        SizedBox(
          height: 2,
          child: (state.isLoading && categorias.isNotEmpty)
              ? const LinearProgressIndicator(
                  backgroundColor: Colors.white12,
                  color: AppTheme.primaryColor,
                  minHeight: 2,
                )
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: state.isLoading && categorias.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                )
              : AnimatedOpacity(
                  opacity: state.isLoading ? 0.5 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: ListView.builder(
                    itemCount: categorias.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      return _CategoriaAdminRow(
                        categoria: categorias[index],
                        onEdit: (cat) => _mostrarFormularioCategoria(notifier, cat),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _CategoriaAdminRow extends ConsumerWidget {
  final Categoria categoria;
  final Function(Categoria) onEdit;

  const _CategoriaAdminRow({
    required this.categoria,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaving =
        ref.watch(categoriasAdminProvider.select((s) => s.isLoading));

    return Container(
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 30,
            child: Row(
              children: <Widget>[
                const FaIcon(FontAwesomeIcons.folder,
                    color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    categoria.nombre,
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 40,
            child: Text(
              categoria.descripcion ?? '',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Expanded(
            flex: 15,
            child: Center(
              child: _ProductosCountWidget(
                totalProductos: categoria.totalProductos,
                tipo: 'categoría',
              ),
            ),
          ),
          Expanded(
            flex: 15,
            child: Center(
              child: IconButton(
                icon: const FaIcon(FontAwesomeIcons.penToSquare,
                    color: Colors.white54, size: 16),
                onPressed: isSaving ? null : () => onEdit(categoria),
                tooltip: 'Editar categoría',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductosCountWidget extends StatefulWidget {
  final int totalProductos;
  final String tipo;

  const _ProductosCountWidget({
    required this.totalProductos,
    required this.tipo,
  });

  @override
  State<_ProductosCountWidget> createState() => _ProductosCountWidgetState();
}

class _ProductosCountWidgetState extends State<_ProductosCountWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final String label = widget.totalProductos == 1 ? 'producto' : 'productos';
    final String tooltipMessage =
        '${widget.totalProductos} $label usando esta ${widget.tipo}';

    return Tooltip(
      message: tooltipMessage,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FaIcon(
              FontAwesomeIcons.box,
              size: 12,
              color: _isHovered ? AppTheme.primaryColor : Colors.white54,
            ),
            const SizedBox(width: 8),
            Text(
              widget.totalProductos.toString(),
              style: TextStyle(
                color: _isHovered ? Colors.white : Colors.white.withValues(alpha: 0.7),
                fontWeight: _isHovered ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriaFormDialog extends StatefulWidget {
  final Categoria? categoria;
  final Function(String nombre, String? descripcion) onSave;

  const _CategoriaFormDialog({
    this.categoria,
    required this.onSave,
  });

  @override
  State<_CategoriaFormDialog> createState() => _CategoriaFormDialogState();
}

class _CategoriaFormDialogState extends State<_CategoriaFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.categoria?.nombre ?? '');
    _descripcionController = TextEditingController(text: widget.categoria?.descripcion ?? '');
    _nombreController.addListener(_onFieldChanged);
    _descripcionController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nombreController.removeListener(_onFieldChanged);
    _descripcionController.removeListener(_onFieldChanged);
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool _hasChanges() {
    if (widget.categoria == null) {
      return _nombreController.text.trim().isNotEmpty;
    }
    final bool nombreChanged = _nombreController.text.trim() != widget.categoria!.nombre.trim();
    final bool descripcionChanged = _descripcionController.text.trim() != (widget.categoria!.descripcion ?? '').trim();
    return nombreChanged || descripcionChanged;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.mediumRadius)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const FaIcon(FontAwesomeIcons.folderPlus, color: Colors.red, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    widget.categoria == null ? 'Crear nueva categoría' : 'Editar categoría',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nombreController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nombre de la categoría',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor, width: 2)),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Por favor ingrese un nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor, width: 2)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                      disabledForegroundColor: Colors.white30,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: _hasChanges() ? () {
                      if (_formKey.currentState!.validate()) {
                        widget.onSave(
                          _nombreController.text.trim(),
                          _descripcionController.text.trim(),
                        );
                      }
                    } : null,
                    icon: Icon(widget.categoria != null ? Icons.save : Icons.add),
                    label: Text(widget.categoria != null ? 'Guardar' : 'Crear'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
