import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

part 'print.riverpod.g.dart';

class PrintState {
  final double margenIzquierdo;
  final double margenDerecho;
  final double margenSuperior;
  final double margenInferior;
  final double anchoTicket;
  final double escalaTicket;
  final bool rotacionAutomatica;
  final bool ajusteAutomatico;
  final bool imprimirFormatoA4;
  final bool imprimirFormatoTicket;
  final bool abrirPdfDespuesDeImprimir;
  final bool impresionDirecta;
  final String? impresoraSeleccionada;
  final List<Printer> impresorasDisponibles;

  const PrintState({
    this.margenIzquierdo = 5.0,
    this.margenDerecho = 5.0,
    this.margenSuperior = 5.0,
    this.margenInferior = 5.0,
    this.anchoTicket = 80.0,
    this.escalaTicket = 1.0,
    this.rotacionAutomatica = true,
    this.ajusteAutomatico = true,
    this.imprimirFormatoA4 = true,
    this.imprimirFormatoTicket = false,
    this.abrirPdfDespuesDeImprimir = false,
    this.impresionDirecta = false,
    this.impresoraSeleccionada,
    this.impresorasDisponibles = const [],
  });

  PrintState copyWith({
    double? margenIzquierdo,
    double? margenDerecho,
    double? margenSuperior,
    double? margenInferior,
    double? anchoTicket,
    double? escalaTicket,
    bool? rotacionAutomatica,
    bool? ajusteAutomatico,
    bool? imprimirFormatoA4,
    bool? imprimirFormatoTicket,
    bool? abrirPdfDespuesDeImprimir,
    bool? impresionDirecta,
    String? impresoraSeleccionada,
    List<Printer>? impresorasDisponibles,
  }) {
    return PrintState(
      margenIzquierdo: margenIzquierdo ?? this.margenIzquierdo,
      margenDerecho: margenDerecho ?? this.margenDerecho,
      margenSuperior: margenSuperior ?? this.margenSuperior,
      margenInferior: margenInferior ?? this.margenInferior,
      anchoTicket: anchoTicket ?? this.anchoTicket,
      escalaTicket: escalaTicket ?? this.escalaTicket,
      rotacionAutomatica: rotacionAutomatica ?? this.rotacionAutomatica,
      ajusteAutomatico: ajusteAutomatico ?? this.ajusteAutomatico,
      imprimirFormatoA4: imprimirFormatoA4 ?? this.imprimirFormatoA4,
      imprimirFormatoTicket:
          imprimirFormatoTicket ?? this.imprimirFormatoTicket,
      abrirPdfDespuesDeImprimir:
          abrirPdfDespuesDeImprimir ?? this.abrirPdfDespuesDeImprimir,
      impresionDirecta: impresionDirecta ?? this.impresionDirecta,
      impresoraSeleccionada:
          impresoraSeleccionada ?? this.impresoraSeleccionada,
      impresorasDisponibles:
          impresorasDisponibles ?? this.impresorasDisponibles,
    );
  }
}

@Riverpod(keepAlive: true)
class PrintConfig extends _$PrintConfig {
  static const String keyMargenIzquierdo = 'margen_izquierdo';
  static const String keyMargenDerecho = 'margen_derecho';
  static const String keyMargenSuperior = 'margen_superior';
  static const String keyMargenInferior = 'margen_inferior';
  static const String keyAnchoTicket = 'ancho_ticket';
  static const String keyEscalaTicket = 'escala_ticket';
  static const String keyRotacionAutomatica = 'rotacion_automatica';
  static const String keyAjusteAutomatico = 'ajuste_automatico';
  static const String keyImprimirFormatoA4 = 'imprimir_formato_a4';
  static const String keyImprimirFormatoTicket = 'imprimir_formato_ticket';
  static const String keyAbrirPdfDespuesDeImprimir =
      'abrir_pdf_despues_imprimir';
  static const String keyImpresionDirecta = 'impresion_directa';
  static const String keyImpresoraSeleccionada = 'impresora_seleccionada';

  GlobalKey<ScaffoldMessengerState>? messengerKey;

  double get margenIzquierdo => state.margenIzquierdo;
  double get margenDerecho => state.margenDerecho;
  double get margenSuperior => state.margenSuperior;
  double get margenInferior => state.margenInferior;
  double get anchoTicket => state.anchoTicket;
  double get escalaTicket => state.escalaTicket;
  bool get rotacionAutomatica => state.rotacionAutomatica;
  bool get ajusteAutomatico => state.ajusteAutomatico;
  bool get imprimirFormatoA4 => state.imprimirFormatoA4;
  bool get imprimirFormatoTicket => state.imprimirFormatoTicket;
  bool get abrirPdfDespuesDeImprimir => state.abrirPdfDespuesDeImprimir;
  bool get impresionDirecta => state.impresionDirecta;
  String? get impresoraSeleccionada => state.impresoraSeleccionada;
  List<Printer> get impresorasDisponibles => state.impresorasDisponibles;

  @override
  PrintState build() {
    Future.microtask(() async {
      await cargarConfiguracion();
      await cargarImpresoras();
    });
    return const PrintState();
  }

  Future<void> inicializar({GlobalKey<ScaffoldMessengerState>? key}) async {
    if (key != null) {
      messengerKey = key;
    }
  }

  void mostrarMensaje({
    required String mensaje,
    Color backgroundColor = Colors.black,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = messengerKey?.currentState;
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: backgroundColor,
          duration: duration,
        ),
      );
    }
  }

  double mmToPts(double mm) {
    return mm * 2.83465;
  }

  Map<String, double> getMargenesPts() {
    return {
      'izquierdo': mmToPts(state.margenIzquierdo),
      'derecho': mmToPts(state.margenDerecho),
      'superior': mmToPts(state.margenSuperior),
      'inferior': mmToPts(state.margenInferior),
    };
  }

  double getAnchoTicketPts() {
    return mmToPts(state.anchoTicket);
  }

  Future<void> cargarConfiguracion() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      state = state.copyWith(
        margenIzquierdo:
            prefs.getDouble(keyMargenIzquierdo) ?? state.margenIzquierdo,
        margenDerecho: prefs.getDouble(keyMargenDerecho) ?? state.margenDerecho,
        margenSuperior:
            prefs.getDouble(keyMargenSuperior) ?? state.margenSuperior,
        margenInferior:
            prefs.getDouble(keyMargenInferior) ?? state.margenInferior,
        anchoTicket: prefs.getDouble(keyAnchoTicket) ?? state.anchoTicket,
        escalaTicket: prefs.getDouble(keyEscalaTicket) ?? state.escalaTicket,
        rotacionAutomatica:
            prefs.getBool(keyRotacionAutomatica) ?? state.rotacionAutomatica,
        ajusteAutomatico:
            prefs.getBool(keyAjusteAutomatico) ?? state.ajusteAutomatico,
        imprimirFormatoA4:
            prefs.getBool(keyImprimirFormatoA4) ?? state.imprimirFormatoA4,
        imprimirFormatoTicket: prefs.getBool(keyImprimirFormatoTicket) ??
            state.imprimirFormatoTicket,
        abrirPdfDespuesDeImprimir:
            prefs.getBool(keyAbrirPdfDespuesDeImprimir) ??
                state.abrirPdfDespuesDeImprimir,
        impresionDirecta:
            prefs.getBool(keyImpresionDirecta) ?? state.impresionDirecta,
        impresoraSeleccionada: prefs.getString(keyImpresoraSeleccionada),
      );
    } catch (e) {
      debugPrint('Error al cargar configuración de impresión: $e');
    }
  }

  Future<void> guardarConfiguracion({
    double? margenIzquierdo,
    double? margenDerecho,
    double? margenSuperior,
    double? margenInferior,
    double? anchoTicket,
    double? escalaTicket,
    bool? rotacionAutomatica,
    bool? ajusteAutomatico,
    bool? imprimirFormatoA4,
    bool? imprimirFormatoTicket,
    bool? abrirPdfDespuesDeImprimir,
    bool? impresionDirecta,
    String? impresoraSeleccionada,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      bool flagChanged = false;
      PrintState newState = state;

      if (margenIzquierdo != null) {
        newState = newState.copyWith(margenIzquierdo: margenIzquierdo);
        await prefs.setDouble(keyMargenIzquierdo, margenIzquierdo);
        flagChanged = true;
      }
      if (margenDerecho != null) {
        newState = newState.copyWith(margenDerecho: margenDerecho);
        await prefs.setDouble(keyMargenDerecho, margenDerecho);
        flagChanged = true;
      }
      if (margenSuperior != null) {
        newState = newState.copyWith(margenSuperior: margenSuperior);
        await prefs.setDouble(keyMargenSuperior, margenSuperior);
        flagChanged = true;
      }
      if (margenInferior != null) {
        newState = newState.copyWith(margenInferior: margenInferior);
        await prefs.setDouble(keyMargenInferior, margenInferior);
        flagChanged = true;
      }
      if (anchoTicket != null) {
        newState = newState.copyWith(anchoTicket: anchoTicket);
        await prefs.setDouble(keyAnchoTicket, anchoTicket);
        flagChanged = true;
      }
      if (escalaTicket != null) {
        newState = newState.copyWith(escalaTicket: escalaTicket);
        await prefs.setDouble(keyEscalaTicket, escalaTicket);
        flagChanged = true;
      }
      if (rotacionAutomatica != null) {
        newState = newState.copyWith(rotacionAutomatica: rotacionAutomatica);
        await prefs.setBool(keyRotacionAutomatica, rotacionAutomatica);
        flagChanged = true;
      }
      if (ajusteAutomatico != null) {
        newState = newState.copyWith(ajusteAutomatico: ajusteAutomatico);
        await prefs.setBool(keyAjusteAutomatico, ajusteAutomatico);
        flagChanged = true;
      }
      if (imprimirFormatoA4 != null) {
        newState = newState.copyWith(imprimirFormatoA4: imprimirFormatoA4);
        await prefs.setBool(keyImprimirFormatoA4, imprimirFormatoA4);
        flagChanged = true;
      }
      if (imprimirFormatoTicket != null) {
        newState =
            newState.copyWith(imprimirFormatoTicket: imprimirFormatoTicket);
        await prefs.setBool(keyImprimirFormatoTicket, imprimirFormatoTicket);
        flagChanged = true;
      }
      if (abrirPdfDespuesDeImprimir != null) {
        newState = newState.copyWith(
            abrirPdfDespuesDeImprimir: abrirPdfDespuesDeImprimir);
        await prefs.setBool(
            keyAbrirPdfDespuesDeImprimir, abrirPdfDespuesDeImprimir);
        flagChanged = true;
      }
      if (impresionDirecta != null) {
        newState = newState.copyWith(impresionDirecta: impresionDirecta);
        await prefs.setBool(keyImpresionDirecta, impresionDirecta);
        flagChanged = true;
      }
      if (impresoraSeleccionada != null) {
        newState =
            newState.copyWith(impresoraSeleccionada: impresoraSeleccionada);
        await prefs.setString(keyImpresoraSeleccionada, impresoraSeleccionada);
        flagChanged = true;
      }

      if (flagChanged) {
        state = newState;
      }
    } catch (e) {
      debugPrint('Error al guardar configuración de impresión: $e');
    }
  }

  Future<void> restaurarConfiguracionPorDefecto() async {
    try {
      await guardarConfiguracion(
        margenIzquierdo: 5.0,
        margenDerecho: 5.0,
        margenSuperior: 5.0,
        margenInferior: 5.0,
        anchoTicket: 80.0,
        escalaTicket: 1.0,
        rotacionAutomatica: true,
        ajusteAutomatico: true,
        imprimirFormatoA4: true,
        imprimirFormatoTicket: false,
        abrirPdfDespuesDeImprimir: false,
        impresionDirecta: false,
      );
    } catch (e) {
      debugPrint('Error al restaurar configuración por defecto: $e');
    }
  }

  Future<void> cargarImpresoras() async {
    try {
      debugPrint('Buscando impresoras disponibles...');
      List<Printer> impresoras = await Printing.listPrinters();

      if (impresoras.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        impresoras = await Printing.listPrinters();
      }

      if (impresoras.isEmpty) {
        mostrarMensaje(
          mensaje: 'No se encontraron impresoras disponibles',
          backgroundColor: Colors.orange,
        );
        state = state.copyWith(impresorasDisponibles: impresoras);
        return;
      }

      state = state.copyWith(impresorasDisponibles: impresoras);

      bool impresoraSeleccionadaDisponible = state.impresoraSeleccionada !=
              null &&
          impresoras.any(
              (p) => p.name == state.impresoraSeleccionada && p.isAvailable);

      if (!impresoraSeleccionadaDisponible) {
        Printer? defaultPrinter;
        try {
          defaultPrinter =
              impresoras.firstWhere((p) => p.isDefault && p.isAvailable);
        } catch (_) {
          try {
            defaultPrinter = impresoras.firstWhere((p) => p.isAvailable);
          } catch (_) {
            if (impresoras.isNotEmpty) {
              defaultPrinter = impresoras.first;
            }
          }
        }

        if (defaultPrinter != null) {
          await guardarConfiguracion(
              impresoraSeleccionada: defaultPrinter.name);
        }
      }
    } catch (e) {
      debugPrint('Error al cargar impresoras: $e');
    }
  }

  Printer? obtenerImpresoraSeleccionada() {
    if (state.impresorasDisponibles.isEmpty) {
      return null;
    }

    try {
      if (state.impresoraSeleccionada != null) {
        final printerExists = state.impresorasDisponibles
            .any((p) => p.name == state.impresoraSeleccionada && p.isAvailable);
        if (printerExists) {
          return state.impresorasDisponibles
              .firstWhere((p) => p.name == state.impresoraSeleccionada);
        }
      }

      try {
        final defaultPrinter = state.impresorasDisponibles
            .firstWhere((p) => p.isDefault && p.isAvailable);
        if (state.impresoraSeleccionada != defaultPrinter.name) {
          guardarConfiguracion(impresoraSeleccionada: defaultPrinter.name);
        }
        return defaultPrinter;
      } catch (_) {}

      try {
        final availablePrinter =
            state.impresorasDisponibles.firstWhere((p) => p.isAvailable);
        if (state.impresoraSeleccionada != availablePrinter.name) {
          guardarConfiguracion(impresoraSeleccionada: availablePrinter.name);
        }
        return availablePrinter;
      } catch (_) {}

      if (state.impresorasDisponibles.isNotEmpty) {
        final anyPrinter = state.impresorasDisponibles.first;
        if (state.impresoraSeleccionada != anyPrinter.name) {
          guardarConfiguracion(impresoraSeleccionada: anyPrinter.name);
        }
        return anyPrinter;
      }

      return null;
    } catch (e) {
      debugPrint('Error al obtener impresora seleccionada: $e');
      return null;
    }
  }

  Future<bool> abrirPdf(String url, [BuildContext? context]) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        throw 'No se pudo abrir el enlace: $url';
      }
    } catch (e) {
      final mensaje = 'Error al abrir el PDF: $e';
      if (context == null || !context.mounted) {
        mostrarMensaje(mensaje: mensaje, backgroundColor: Colors.red);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }

  Future<bool> imprimirDocumentoPdf(String url, String nombreDocumento,
      [BuildContext? context]) async {
    try {
      String urlFinal = url;
      if (state.imprimirFormatoTicket && url.contains('type=a4')) {
        urlFinal = url.replaceAll('type=a4', 'type=ticket');
      } else if (state.imprimirFormatoA4 && url.contains('type=ticket')) {
        urlFinal = url.replaceAll('type=ticket', 'type=a4');
      }

      const mensaje = 'Preparando documento para impresión...';
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(mensaje), duration: Duration(seconds: 1)),
        );
      } else {
        mostrarMensaje(mensaje: mensaje, duration: const Duration(seconds: 1));
      }

      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final request = await httpClient.getUrl(Uri.parse(urlFinal));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Error al descargar el PDF: ${response.statusCode}');
      }

      final List<int> bytesBuilder = [];
      await for (var data in response) {
        bytesBuilder.addAll(data);
      }
      final Uint8List bytes = Uint8List.fromList(bytesBuilder);
      httpClient.close();

      final PdfPageFormat pageFormat;
      if (state.imprimirFormatoTicket) {
        final anchoTicketPts = getAnchoTicketPts();
        final margenes = getMargenesPts();

        pageFormat = PdfPageFormat(
          anchoTicketPts,
          double.infinity,
          marginLeft: margenes['izquierdo']!,
          marginRight: margenes['derecho']!,
          marginTop: margenes['superior']!,
          marginBottom: margenes['inferior']!,
        );
      } else {
        final margenes = getMargenesPts();
        pageFormat = PdfPageFormat.a4.copyWith(
          marginLeft: margenes['izquierdo']!,
          marginRight: margenes['derecho']!,
          marginTop: margenes['superior']!,
          marginBottom: margenes['inferior']!,
        );
      }

      bool result;
      if (state.impresionDirecta) {
        final printer = obtenerImpresoraSeleccionada();
        if (printer == null) {
          throw Exception('No hay impresora disponible');
        }

        result = await Printing.directPrintPdf(
          printer: printer,
          onLayout: (_) => Future.value(bytes),
          name: nombreDocumento,
          format: pageFormat,
          usePrinterSettings: !state.imprimirFormatoTicket,
        );
      } else {
        result = await Printing.layoutPdf(
          onLayout: (_) => Future.value(bytes),
          name: nombreDocumento,
          format: pageFormat,
          usePrinterSettings: !state.imprimirFormatoTicket,
        );
      }

      if (result) {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Documento enviado a la impresora'),
                backgroundColor: Colors.green),
          );
        } else {
          mostrarMensaje(
              mensaje: 'Documento enviado a la impresora',
              backgroundColor: Colors.green);
        }

        if (state.abrirPdfDespuesDeImprimir) {
          await abrirPdf(urlFinal);
        }
        return true;
      } else {
        await abrirPdf(urlFinal);
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No se pudo imprimir. PDF abierto en navegador'),
                backgroundColor: Colors.orange),
          );
        } else {
          mostrarMensaje(
              mensaje: 'No se pudo imprimir. PDF abierto en navegador',
              backgroundColor: Colors.orange);
        }
        return false;
      }
    } catch (e) {
      await abrirPdf(url);
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al imprimir: $e'),
              backgroundColor: Colors.red),
        );
      } else {
        mostrarMensaje(
            mensaje: 'Error al imprimir: $e', backgroundColor: Colors.red);
      }
      return false;
    }
  }
}
