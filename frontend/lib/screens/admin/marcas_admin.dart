import 'package:condorsmotors/models/marca.model.dart';
import 'package:condorsmotors/providers/admin/marcas.admin.riverpod.dart';
import 'package:condorsmotors/widgets/common/empty_state.widget.dart';
import 'package:condorsmotors/widgets/common/error_banner.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MarcasAdminScreen extends ConsumerStatefulWidget {
  const MarcasAdminScreen({super.key});

  @override
  ConsumerState<MarcasAdminScreen> createState() => _MarcasAdminScreenState();
}

class _MarcasAdminScreenState extends ConsumerState<MarcasAdminScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _mostrarFormularioMarca(MarcasAdmin notifier, [Marca? marca]) {
    _nombreController.text = marca?.nombre ?? '';
    _descripcionController.text = marca?.descripcion ?? '';

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
                    const FaIcon(FontAwesomeIcons.trademark,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      marca == null ? 'Crear nueva marca' : 'Editar marca',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nombreController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la marca',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFFE31E24), width: 2)),
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Por favor ingrese un nombre'
                      : null,
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
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFFE31E24), width: 2)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancelar',
                          style: TextStyle(color: Colors.white54)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31E24),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await notifier.guardarMarca(
                              marca: marca,
                              nombre: _nombreController.text.trim(),
                              descripcion:
                                  _descripcionController.text.trim().isNotEmpty
                                      ? _descripcionController.text.trim()
                                      : null,
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }
                            Navigator.pop(dialogContext);

                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(marca == null
                                    ? 'Marca creada'
                                    : 'Marca actualizada'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            // Error handled in state
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
    final state = ref.watch(marcasAdminProvider);
    final notifier = ref.read(marcasAdminProvider.notifier);

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
                    const FaIcon(FontAwesomeIcons.tags,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'INVENTARIO',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        Text(
                          'marcas',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.7)),
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
                            : 'Recargar marcas',
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
                              : () => notifier.cargarMarcas(forceRefresh: true),
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
                            size: 16, color: Colors.white),
                        label: const Text('Nuevo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE31E24),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _mostrarFormularioMarca(notifier),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (state.errorMessage != null)
              ErrorBanner(
                message: state.errorMessage!,
                onClose: notifier.limpiarError,
              ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: const Row(
        children: <Widget>[
          Expanded(
              flex: 35,
              child: Text('Marca',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(
              flex: 45,
              child: Text('Descripción',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(
              flex: 10,
              child: Text('Productos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(
              flex: 10,
              child: Text('Acciones',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildTableContent(MarcasAdminState state, MarcasAdmin notifier) {
    if (state.marcas.isEmpty && !state.isLoading) {
      return EmptyState(
        icon: FontAwesomeIcons.tag,
        message: 'No hay marcas registradas',
        buttonLabel: 'Crear marca',
        onAction: () => _mostrarFormularioMarca(notifier),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildTableHeader(),
        SizedBox(
          height: 2,
          child: (state.isLoading && state.marcas.isNotEmpty)
              ? const LinearProgressIndicator(
                  backgroundColor: Colors.white12,
                  color: Color(0xFFE31E24),
                  minHeight: 2,
                )
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: state.isLoading && state.marcas.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFE31E24),
                  ),
                )
              : AnimatedOpacity(
                  opacity: state.isLoading ? 0.5 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: ListView.builder(
                    itemCount: state.marcas.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final marca = state.marcas[index];
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 20),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              flex: 35,
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF2D2D2D),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: const Center(
                                        child: FaIcon(FontAwesomeIcons.tag,
                                            color: Color(0xFFE31E24), size: 14)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      marca.nombre,
                                      style: const TextStyle(color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 45,
                              child: Text(
                                marca.descripcion ?? 'Sin descripción',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7)),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            Expanded(
                              flex: 10,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE31E24)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      const FaIcon(FontAwesomeIcons.box,
                                          size: 12, color: Color(0xFFE31E24)),
                                      const SizedBox(width: 6),
                                      Text(
                                        marca.totalProductos.toString(),
                                        style: const TextStyle(
                                            color: Color(0xFFE31E24),
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 10,
                              child: Center(
                                child: IconButton(
                                  icon: const FaIcon(FontAwesomeIcons.penToSquare,
                                      color: Colors.white54, size: 16),
                                  onPressed: () =>
                                      _mostrarFormularioMarca(notifier, marca),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
