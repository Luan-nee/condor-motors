import 'package:condorsmotors/models/categoria.model.dart';
import 'package:condorsmotors/providers/admin/index.admin.provider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class CategoriasAdminScreen extends StatefulWidget {
  const CategoriasAdminScreen({super.key});

  @override
  State<CategoriasAdminScreen> createState() => _CategoriasAdminScreenState();
}

class _CategoriasAdminScreenState extends State<CategoriasAdminScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  late CategoriasProvider _categoriasProvider;

  @override
  void initState() {
    super.initState();
    // Inicialización y primera carga de datos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _categoriasProvider =
          Provider.of<CategoriasProvider>(context, listen: false);
      _categoriasProvider.cargarCategorias();
    });
  }

  // Método para mostrar el formulario de creación/edición de categoría
  void _mostrarFormularioCategoria([Categoria? categoria]) {
    _nombreController.text = categoria?.nombre ?? '';
    _descripcionController.text = categoria?.descripcion ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
                    const FaIcon(
                      FontAwesomeIcons.folderPlus,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      categoria == null
                          ? 'Crear nueva categoría'
                          : 'Editar categoría',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFFE31E24), width: 2),
                    ),
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese un nombre';
                    }
                    return null;
                  },
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
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFFE31E24), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton(
                      onPressed: _categoriasProvider.isCreating
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31E24),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _categoriasProvider.isCreating
                          ? null
                          : () => _guardarCategoria(categoria),
                      child: _categoriasProvider.isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Guardar'),
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

  // Método para guardar la categoría usando el provider
  Future<void> _guardarCategoria([Categoria? categoria]) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String nombre = _nombreController.text.trim();
    final String descripcion = _descripcionController.text.trim();

    // Definir una función para mostrar el SnackBar
    void showSuccessSnackBar() {
      final String message = categoria == null
          ? 'Categoría creada correctamente'
          : 'Categoría actualizada correctamente';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }

    final bool exito = await _categoriasProvider.guardarCategoria(
      id: categoria?.id,
      nombre: nombre,
      descripcion: descripcion,
    );

    // Verificar si el widget aún está montado
    if (!mounted) {
      return;
    }

    if (exito) {
      showSuccessSnackBar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoriasProvider>(
      builder: (context, categoriasProvider, _) {
        _categoriasProvider = categoriasProvider;
        final List<Categoria> categorias = categoriasProvider.categorias;
        final bool isLoading = categoriasProvider.isLoading;
        final String errorMessage = categoriasProvider.errorMessage;

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const FaIcon(
                          FontAwesomeIcons.folderTree,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'INVENTARIO',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'categorías',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        ElevatedButton.icon(
                          icon: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const FaIcon(
                                  FontAwesomeIcons.arrowsRotate,
                                  size: 16,
                                  color: Colors.white,
                                ),
                          label: Text(
                            isLoading ? 'Recargando...' : 'Recargar',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D2D2D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  // Definir funciones para mostrar SnackBars
                                  void showErrorSnackBar() {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            categoriasProvider.errorMessage),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }

                                  void showSuccessSnackBar() {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Datos recargados exitosamente'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }

                                  await categoriasProvider.recargarDatos();

                                  // Verificar si el widget aún está montado
                                  if (!mounted) {
                                    return;
                                  }

                                  if (categoriasProvider
                                      .errorMessage.isNotEmpty) {
                                    showErrorSnackBar();
                                  } else {
                                    showSuccessSnackBar();
                                  }
                                },
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const FaIcon(FontAwesomeIcons.plus,
                              size: 16, color: Colors.white),
                          label: const Text('Nueva Categoría'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE31E24),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                          onPressed: _mostrarFormularioCategoria,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Mensaje de error si existe
                if (errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            categoriasProvider.clearError();
                          },
                        ),
                      ],
                    ),
                  ),

                // Tabla de categorías
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : categorias.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const FaIcon(
                                      FontAwesomeIcons.folderOpen,
                                      color: Colors.grey,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No hay categorías disponibles',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      icon: const FaIcon(
                                        FontAwesomeIcons.plus,
                                        size: 14,
                                      ),
                                      label: const Text('Crear categoría'),
                                      onPressed: _mostrarFormularioCategoria,
                                    ),
                                  ],
                                ),
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    // Encabezado de la tabla
                                    Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2D2D2D),
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(12)),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 20),
                                      child: const Row(
                                        children: <Widget>[
                                          // Categorías (30% del ancho)
                                          Expanded(
                                            flex: 30,
                                            child: Text(
                                              'Categorías',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          // Descripción (40% del ancho)
                                          Expanded(
                                            flex: 40,
                                            child: Text(
                                              'Descripción',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          // Cant. de productos (15% del ancho)
                                          Expanded(
                                            flex: 15,
                                            child: Text(
                                              'Cant. de productos',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          // Acciones (15% del ancho)
                                          Expanded(
                                            flex: 15,
                                            child: Text(
                                              'Acciones',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Filas de categorías
                                    ...categorias.map((Categoria categoria) =>
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.white
                                                    .withValues(alpha: 0.1),
                                              ),
                                            ),
                                            borderRadius: BorderRadius.zero,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 20),
                                          child: Row(
                                            children: <Widget>[
                                              // Categoría
                                              Expanded(
                                                flex: 30,
                                                child: Row(
                                                  children: <Widget>[
                                                    const FaIcon(
                                                      FontAwesomeIcons.folder,
                                                      color: Color(0xFFE31E24),
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      categoria.nombre,
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Descripción
                                              Expanded(
                                                flex: 40,
                                                child: Text(
                                                  categoria.descripcion ?? '',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.7),
                                                  ),
                                                ),
                                              ),
                                              // Cant. de productos
                                              Expanded(
                                                flex: 15,
                                                child: Center(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                              0xFFE31E24)
                                                          .withValues(
                                                              alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 12,
                                                      vertical: 4,
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: <Widget>[
                                                        const FaIcon(
                                                          FontAwesomeIcons.box,
                                                          size: 12,
                                                          color:
                                                              Color(0xFFE31E24),
                                                        ),
                                                        const SizedBox(
                                                            width: 6),
                                                        Text(
                                                          categoria
                                                              .totalProductos
                                                              .toString(),
                                                          style:
                                                              const TextStyle(
                                                            color: Color(
                                                                0xFFE31E24),
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Acciones
                                              Expanded(
                                                flex: 15,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: <Widget>[
                                                    IconButton(
                                                      icon: const FaIcon(
                                                        FontAwesomeIcons
                                                            .penToSquare,
                                                        color: Colors.white54,
                                                        size: 16,
                                                      ),
                                                      onPressed: () =>
                                                          _mostrarFormularioCategoria(
                                                              categoria),
                                                      constraints:
                                                          const BoxConstraints(
                                                        minWidth: 30,
                                                        minHeight: 30,
                                                      ),
                                                      padding: EdgeInsets.zero,
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }
}
