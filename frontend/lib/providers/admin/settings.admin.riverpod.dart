import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings.admin.riverpod.g.dart';

class SettingsAdminState {
  final String? directorioExcel;
  final bool mostrarSucursalesAgrupadas;
  final bool isLoading;

  const SettingsAdminState({
    this.directorioExcel,
    this.mostrarSucursalesAgrupadas = true,
    this.isLoading = false,
  });

  SettingsAdminState copyWith({
    String? directorioExcel,
    bool? mostrarSucursalesAgrupadas,
    bool? isLoading,
  }) {
    return SettingsAdminState(
      directorioExcel: directorioExcel ?? this.directorioExcel,
      mostrarSucursalesAgrupadas:
          mostrarSucursalesAgrupadas ?? this.mostrarSucursalesAgrupadas,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@Riverpod(keepAlive: true)
class SettingsAdmin extends _$SettingsAdmin {
  @override
  SettingsAdminState build() {
    // Escuchar cambios de SharedPreferences si fuera necesario, pero aquí solo inicializamos.
    // Riverpod build() no debería llamar a async directamente sin manejarlo.
    // Pero lo mantendremos como origninalmente estaba con _cargarConfiguraciones.
    Future.microtask(_cargarConfiguraciones);
    return const SettingsAdminState();
  }

  Future<void> _cargarConfiguraciones() async {
    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? directorioExcel = prefs.getString('directorioExcel');
      final bool mostrarAgrupadas =
          prefs.getBool('mostrarSucursalesAgrupadas') ?? true;

      String? finalDir = directorioExcel;
      // Si no hay directorio configurado, usar el de documentos por defecto
      if (finalDir == null && !kIsWeb && io.Platform.isWindows) {
        final directory = await getApplicationDocumentsDirectory();
        finalDir = directory.path;
      }

      state = state.copyWith(
          directorioExcel: finalDir,
          mostrarSucursalesAgrupadas: mostrarAgrupadas,
          isLoading: false);
    } catch (e) {
      debugPrint('Error al cargar configuraciones: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> actualizarDirectorioExcel(String directorio) async {
    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('directorioExcel', directorio);
      state = state.copyWith(directorioExcel: directorio, isLoading: false);
    } catch (e) {
      debugPrint('Error al guardar directorio Excel: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> actualizarMostrarAgrupados({required bool valor}) async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('mostrarSucursalesAgrupadas', valor);
      state = state.copyWith(
          mostrarSucursalesAgrupadas: valor, isLoading: false);
    } catch (e) {
      debugPrint('Error al guardar configuración de agrupación: $e');
      state = state.copyWith(isLoading: false);
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
