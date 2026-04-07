import 'dart:io' as io;

import 'package:condorsmotors/providers/admin/settings.admin.riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SettingsAdminScreen extends ConsumerStatefulWidget {
  const SettingsAdminScreen({super.key});

  @override
  ConsumerState<SettingsAdminScreen> createState() => _SettingsAdminScreenState();
}

class _SettingsAdminScreenState extends ConsumerState<SettingsAdminScreen> {
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
    final settingsState = ref.watch(settingsAdminProvider);
    final settingsNotifier = ref.read(settingsAdminProvider.notifier);

    if (settingsState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Actualizar el controlador con el valor actual solo si es diferente
    if (_directorioController.text.isEmpty &&
        settingsState.directorioExcel != null) {
      _directorioController.text = settingsState.directorioExcel!;
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
                  labelStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7)),
                  hintText: 'Ej: C:\\Users\\Usuario\\Documents',
                  hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3)),
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
                  final esValido = await settingsNotifier
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
                      await settingsNotifier
                          .seleccionarDirectorioDescargas();
                      if (ref.read(settingsAdminProvider).directorioExcel !=
                          null) {
                        setState(() {
                          _directorioController.text =
                              ref.read(settingsAdminProvider).directorioExcel!;
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
                      await settingsNotifier
                          .seleccionarDirectorioDocumentos();
                      if (ref.read(settingsAdminProvider).directorioExcel !=
                          null) {
                        setState(() {
                          _directorioController.text =
                              ref.read(settingsAdminProvider).directorioExcel!;
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
                        await settingsNotifier
                            .actualizarDirectorioExcel(selectedDirectory);
                        setState(() {
                          _directorioController.text = selectedDirectory;
                          _esDirectorioValido = true;
                        });
                        if (context.mounted) {
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
                            await settingsNotifier
                                .actualizarDirectorioExcel(
                                    _directorioController.text);
                            if (context.mounted) {
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

            // Configuración de interfaz
            const Text(
              'Configuración de Interfaz',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),

            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Agrupar sucursales por tipo',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Muestra las sucursales divididas en "Centrales" y "Sucursales" en el panel lateral.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                secondary: const Icon(
                  FontAwesomeIcons.layerGroup,
                  color: Color(0xFFE31E24),
                  size: 20,
                ),
                activeThumbColor: const Color(0xFFE31E24),
                value: settingsState.mostrarSucursalesAgrupadas,
                onChanged: (value) => settingsNotifier.actualizarMostrarAgrupados(valor: value),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
