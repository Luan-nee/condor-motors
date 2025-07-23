import 'package:condorsmotors/models/marca.model.dart';
import 'package:condorsmotors/providers/admin/index.admin.provider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class MarcasAdminScreen extends StatefulWidget {
  const MarcasAdminScreen({super.key});

  @override
  State<MarcasAdminScreen> createState() => _MarcasAdminScreenState();
}

class _MarcasAdminScreenState extends State<MarcasAdminScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  late MarcasProvider _marcasProvider;

  @override
  void initState() {
    super.initState();
    // Inicialización y primera carga de datos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _marcasProvider = Provider.of<MarcasProvider>(context, listen: false);
      _marcasProvider.cargarMarcas();
    });
  }

  Future<void> _guardarMarca([Marca? marca]) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String nombre = _nombreController.text.trim();
    final String descripcion = _descripcionController.text.trim();

    // Definir una función para mostrar el SnackBar
    void showSuccessSnackBar() {
      final String message = marca == null
          ? 'Marca creada correctamente'
          : 'Marca actualizada correctamente';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }

    final bool exito = await _marcasProvider.guardarMarca(
      id: marca?.id,
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

  void _mostrarFormularioMarca([Marca? marca]) {
    _nombreController.text = marca?.nombre ?? '';
    _descripcionController.text = marca?.descripcion ?? '';

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
                      FontAwesomeIcons.trademark,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      marca == null ? 'Crear nueva marca' : 'Editar marca',
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
                    labelText: 'Nombre de la marca',
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
                      onPressed: _marcasProvider.isCreating
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
                      onPressed: _marcasProvider.isCreating
                          ? null
                          : () => _guardarMarca(marca),
                      child: _marcasProvider.isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Consumer<MarcasProvider>(
      builder: (context, marcasProvider, _) {
        _marcasProvider = marcasProvider;
        final List<Marca> marcas = marcasProvider.marcas;
        final bool isLoading = marcasProvider.isLoading;
        final String errorMessage = marcasProvider.errorMessage;
        final Map<int, int> productosPorMarca =
            marcasProvider.productosPorMarca;

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
                          FontAwesomeIcons.tags,
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
                              'marcas',
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
                                        content:
                                            Text(marcasProvider.errorMessage),
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

                                  await marcasProvider.recargarDatos();

                                  // Verificar si el widget aún está montado
                                  if (!mounted) {
                                    return;
                                  }

                                  if (marcasProvider.errorMessage.isNotEmpty) {
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
                          label: const Text('Nueva Marca'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE31E24),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                          onPressed: isLoading ? null : _mostrarFormularioMarca,
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
                            marcasProvider.clearError();
                          },
                        ),
                      ],
                    ),
                  ),

                // Tabla de marcas
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
                        ? const Center(child: CircularProgressIndicator())
                        : marcas.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const FaIcon(
                                      FontAwesomeIcons.tag,
                                      color: Colors.grey,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No hay marcas registradas',
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
                                      label: const Text('Crear marca'),
                                      onPressed: _mostrarFormularioMarca,
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
                                          // Marca (35% del ancho)
                                          Expanded(
                                            flex: 35,
                                            child: Text(
                                              'Marca',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          // Descripción (45% del ancho)
                                          Expanded(
                                            flex: 45,
                                            child: Text(
                                              'Descripción',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          // Cant. de productos (10% del ancho)
                                          Expanded(
                                            flex: 10,
                                            child: Text(
                                              'Productos',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          // Acciones (10% del ancho)
                                          Expanded(
                                            flex: 10,
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

                                    // Filas de marcas
                                    ...marcas.map((Marca marca) => Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.white
                                                    .withValues(alpha: 0.1),
                                              ),
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 20),
                                          child: Row(
                                            children: <Widget>[
                                              // Marca
                                              Expanded(
                                                flex: 35,
                                                child: Row(
                                                  children: <Widget>[
                                                    Container(
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xFF2D2D2D),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: const Center(
                                                        child: FaIcon(
                                                          FontAwesomeIcons.tag,
                                                          color:
                                                              Color(0xFFE31E24),
                                                          size: 14,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      marca.nombre,
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Descripción
                                              Expanded(
                                                flex: 45,
                                                child: Text(
                                                  marca.descripcion ??
                                                      'Sin descripción',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.7),
                                                  ),
                                                ),
                                              ),
                                              // Cant. de productos
                                              Expanded(
                                                flex: 10,
                                                child: Center(
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 12,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                              0xFFE31E24)
                                                          .withValues(
                                                              alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
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
                                                          productosPorMarca[
                                                                      marca.id]
                                                                  ?.toString() ??
                                                              '0',
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
                                                flex: 10,
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
                                                          _mostrarFormularioMarca(
                                                              marca),
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
