import 'package:condorsmotors/models/categoria.model.dart';
import 'package:condorsmotors/providers/admin/categorias.admin.riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CategoriasAdminScreen extends ConsumerStatefulWidget {
  const CategoriasAdminScreen({super.key});

  @override
  ConsumerState<CategoriasAdminScreen> createState() => _CategoriasAdminScreenState();
}

class _CategoriasAdminScreenState extends ConsumerState<CategoriasAdminScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _mostrarFormularioCategoria(CategoriasAdmin notifier, [Categoria? categoria]) {
    _nombreController.text = categoria?.nombre ?? '';
    _descripcionController.text = categoria?.descripcion ?? '';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      categoria == null ? 'Crear nueva categoría' : 'Editar categoría',
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
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE31E24), width: 2)),
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
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE31E24), width: 2)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31E24),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          try {
                            await notifier.guardarCategoria(
                              categoria: categoria,
                              nombre: _nombreController.text.trim(),
                              descripcion: _descripcionController.text.trim().isNotEmpty ? _descripcionController.text.trim() : null,
                            );
                            if (context.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(categoria == null ? 'Categoría creada' : 'Categoría actualizada'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            // Error handled in state but we show it here too if needed
                          }
                        }
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
                Row(
                  children: <Widget>[
                    const FaIcon(FontAwesomeIcons.folderTree, color: Colors.white, size: 24),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'INVENTARIO',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'categorías',
                          style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.7)),
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
                            backgroundColor: const Color(0xFF2D2D2D),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
                          backgroundColor: const Color(0xFFE31E24),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
            if (state.errorMessage != null)
              _buildErrorBanner(state.errorMessage!, notifier),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.categorias.isEmpty
                        ? _buildEmptyState(notifier)
                        : _buildTable(state.categorias, notifier),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message, CategoriasAdmin notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 16),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.red))),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: notifier.limpiarError,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(CategoriasAdmin notifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const FaIcon(FontAwesomeIcons.folderOpen, color: Colors.grey, size: 48),
          const SizedBox(height: 16),
          Text('No hay categorías disponibles', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
            label: const Text('Crear categoría'),
            onPressed: () => _mostrarFormularioCategoria(notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<Categoria> categorias, CategoriasAdmin notifier) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: const Row(
              children: <Widget>[
                Expanded(flex: 30, child: Text('Categoría', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 40, child: Text('Descripción', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 15, child: Text('Cant. de productos', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(flex: 15, child: Text('Acciones', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          ...categorias.map((categoria) => Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 30,
                      child: Row(
                        children: <Widget>[
                          const FaIcon(FontAwesomeIcons.folder, color: Color(0xFFE31E24), size: 20),
                          const SizedBox(width: 12),
                          Text(categoria.nombre, style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 40,
                      child: Text(categoria.descripcion ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                    ),
                    Expanded(
                      flex: 15,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE31E24).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const FaIcon(FontAwesomeIcons.box, size: 12, color: Color(0xFFE31E24)),
                              const SizedBox(width: 6),
                              Text(categoria.totalProductos.toString(), style: const TextStyle(color: Color(0xFFE31E24), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 15,
                      child: IconButton(
                        icon: const FaIcon(FontAwesomeIcons.penToSquare, color: Colors.white54, size: 16),
                        onPressed: () => _mostrarFormularioCategoria(notifier, categoria),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
