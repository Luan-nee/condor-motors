import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfiguracionesProvider extends ChangeNotifier {
  String? _directorioExcel;
  bool _isLoading = false;

  String? get directorioExcel => _directorioExcel;
  bool get isLoading => _isLoading;

  ConfiguracionesProvider() {
    _cargarConfiguraciones();
  }

  Future<void> _cargarConfiguraciones() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _directorioExcel = prefs.getString('directorioExcel');

      // Si no hay directorio configurado, usar el de documentos por defecto
      if (_directorioExcel == null && !kIsWeb && io.Platform.isWindows) {
        final directory = await getApplicationDocumentsDirectory();
        _directorioExcel = directory.path;
      }
    } catch (e) {
      debugPrint('Error al cargar configuraciones: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> actualizarDirectorioExcel(String directorio) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('directorioExcel', directorio);
      _directorioExcel = directorio;
    } catch (e) {
      debugPrint('Error al guardar directorio Excel: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> seleccionarDirectorioDocumentos() async {
    if (!kIsWeb && io.Platform.isWindows) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        await actualizarDirectorioExcel(directory.path);
      } catch (e) {
        debugPrint('Error al seleccionar directorio de documentos: $e');
      }
    }
  }

  Future<void> seleccionarDirectorioDescargas() async {
    if (!kIsWeb && io.Platform.isWindows) {
      try {
        final directory = await getDownloadsDirectory();
        if (directory != null) {
          await actualizarDirectorioExcel(directory.path);
        }
      } catch (e) {
        debugPrint('Error al seleccionar directorio de descargas: $e');
      }
    }
  }

  Future<bool> verificarDirectorio(String path) async {
    if (kIsWeb) {
      return true;
    }

    try {
      final directory = io.Directory(path);
      final exists = await directory.exists();
      return exists;
    } catch (e) {
      return false;
    }
  }
}

class SettingsAdminScreen extends StatefulWidget {
  const SettingsAdminScreen({super.key});

  @override
  State<SettingsAdminScreen> createState() => _SettingsAdminScreenState();
}

class _SettingsAdminScreenState extends State<SettingsAdminScreen> {
  final TextEditingController _directorioController = TextEditingController();
  bool _esDirectorioValido = true;
  String? _errorMessage;

  @override
  void dispose() {
    _directorioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConfiguracionesProvider(),
      child: Consumer<ConfiguracionesProvider>(
        builder: (context, configuracionesProvider, _) {
          if (configuracionesProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Actualizar el controlador con el valor actual solo si es diferente
          if (_directorioController.text.isEmpty &&
              configuracionesProvider.directorioExcel != null) {
            _directorioController.text =
                configuracionesProvider.directorioExcel!;
          }

          return Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado
                  const Text(
                    'Configuración',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Configuración para exportación de Excel
                  const Text(
                    'Configuración de Exportación de Excel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),

                  if (!kIsWeb && io.Platform.isWindows) ...[
                    // Campo para el directorio de Excel
                    TextField(
                      controller: _directorioController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Directorio para guardar archivos Excel',
                        labelStyle:
                            TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        hintText: 'Ej: C:\\Users\\Usuario\\Documents',
                        hintStyle:
                            TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFE31E24)),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2D2D2D),
                        errorText: !_esDirectorioValido ? _errorMessage : null,
                        prefixIcon:
                            const Icon(Icons.folder, color: Colors.white70),
                      ),
                      onChanged: (value) async {
                        final esValido = await configuracionesProvider
                            .verificarDirectorio(value);
                        setState(() {
                          _esDirectorioValido = esValido;
                          _errorMessage = esValido
                              ? null
                              : 'El directorio no existe o no es válido';
                        });
                      },
                    ),
                    const SizedBox(height: 10),

                    // Botones para opciones predefinidas y guardar
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.file_download, size: 16),
                          label: const Text('Carpeta de Descargas'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D2D2D),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          onPressed: () async {
                            await configuracionesProvider
                                .seleccionarDirectorioDescargas();
                            if (configuracionesProvider.directorioExcel !=
                                null) {
                              setState(() {
                                _directorioController.text =
                                    configuracionesProvider.directorioExcel!;
                                _esDirectorioValido = true;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.folder_special, size: 16),
                          label: const Text('Carpeta de Documentos'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D2D2D),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          onPressed: () async {
                            await configuracionesProvider
                                .seleccionarDirectorioDocumentos();
                            if (configuracionesProvider.directorioExcel !=
                                null) {
                              setState(() {
                                _directorioController.text =
                                    configuracionesProvider.directorioExcel!;
                                _esDirectorioValido = true;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.folder_open, size: 16),
                          label:
                              const Text('Seleccionar carpeta personalizada'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D2D2D),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          onPressed: () async {
                            String? selectedDirectory =
                                await FilePicker.platform.getDirectoryPath();
                            if (selectedDirectory != null) {
                              await configuracionesProvider
                                  .actualizarDirectorioExcel(selectedDirectory);
                              setState(() {
                                _directorioController.text = selectedDirectory;
                                _esDirectorioValido = true;
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Carpeta personalizada seleccionada correctamente'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          icon: const FaIcon(FontAwesomeIcons.floppyDisk,
                              size: 16),
                          label: const Text('Guardar Configuración'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE31E24),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          onPressed: _esDirectorioValido
                              ? () async {
                                  await configuracionesProvider
                                      .actualizarDirectorioExcel(
                                          _directorioController.text);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Configuración guardada correctamente'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              : null,
                        ),
                      ],
                    ),
                  ] else
                    // Mensaje para usuarios que no están en Windows
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'La configuración de directorio para Excel solo está disponible para Windows. '
                              'En modo web, los archivos se descargarán directamente.',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 30),

                  // Otras configuraciones podrían ir aquí
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
