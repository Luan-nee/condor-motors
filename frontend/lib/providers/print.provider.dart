import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Provider para gestionar configuración e impresión de documentos
class PrintProvider extends ChangeNotifier {
  // Singleton
  static final PrintProvider _instance = PrintProvider._internal();
  static PrintProvider get instance => _instance;
  PrintProvider._internal();

  // Claves para SharedPreferences
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

  // Valores por defecto
  static const double defaultMargenIzquierdo = 5.0;
  static const double defaultMargenDerecho = 5.0;
  static const double defaultMargenSuperior = 5.0;
  static const double defaultMargenInferior = 5.0;
  static const double defaultAnchoTicket =
      80.0; // mm (ancho estándar de ticket)
  static const double defaultEscalaTicket = 1.0;
  static const bool defaultRotacionAutomatica = true;
  static const bool defaultAjusteAutomatico = true;
  static const bool defaultImprimirFormatoA4 = true;
  static const bool defaultImprimirFormatoTicket = false;
  static const bool defaultAbrirPdfDespuesDeImprimir = false;
  static const bool defaultImpresionDirecta = false;

  // Estado para configuración
  double _margenIzquierdo = defaultMargenIzquierdo;
  double _margenDerecho = defaultMargenDerecho;
  double _margenSuperior = defaultMargenSuperior;
  double _margenInferior = defaultMargenInferior;
  double _anchoTicket = defaultAnchoTicket;
  double _escalaTicket = defaultEscalaTicket;
  bool _rotacionAutomatica = defaultRotacionAutomatica;
  bool _ajusteAutomatico = defaultAjusteAutomatico;
  bool _imprimirFormatoA4 = defaultImprimirFormatoA4;
  bool _imprimirFormatoTicket = defaultImprimirFormatoTicket;
  bool _abrirPdfDespuesDeImprimir = defaultAbrirPdfDespuesDeImprimir;
  bool _impresionDirecta = defaultImpresionDirecta;
  String? _impresoraSeleccionada;
  List<Printer> _impresorasDisponibles = [];

  // Referencia global al messenger para mostrar mensajes
  GlobalKey<ScaffoldMessengerState>? messengerKey;

  // Getters para configuración
  double get margenIzquierdo => _margenIzquierdo;
  double get margenDerecho => _margenDerecho;
  double get margenSuperior => _margenSuperior;
  double get margenInferior => _margenInferior;
  double get anchoTicket => _anchoTicket;
  double get escalaTicket => _escalaTicket;
  bool get rotacionAutomatica => _rotacionAutomatica;
  bool get ajusteAutomatico => _ajusteAutomatico;
  bool get imprimirFormatoA4 => _imprimirFormatoA4;
  bool get imprimirFormatoTicket => _imprimirFormatoTicket;
  bool get abrirPdfDespuesDeImprimir => _abrirPdfDespuesDeImprimir;
  bool get impresionDirecta => _impresionDirecta;
  String? get impresoraSeleccionada => _impresoraSeleccionada;
  List<Printer> get impresorasDisponibles => _impresorasDisponibles;

  /// Inicializa el provider cargando la configuración guardada
  Future<void> inicializar({GlobalKey<ScaffoldMessengerState>? key}) async {
    if (key != null) {
      messengerKey = key;
    }
    await cargarConfiguracion();
    await cargarImpresoras();
  }

  /// Muestra un mensaje usando el ScaffoldMessenger global
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

  /// Convierte milímetros a puntos (pts)
  double mmToPts(double mm) {
    return mm * 2.83465; // 1mm = 2.83465pts
  }

  /// Obtiene los márgenes en puntos para impresión
  Map<String, double> getMargenesPts() {
    return {
      'izquierdo': mmToPts(_margenIzquierdo),
      'derecho': mmToPts(_margenDerecho),
      'superior': mmToPts(_margenSuperior),
      'inferior': mmToPts(_margenInferior),
    };
  }

  /// Obtiene el ancho del ticket en puntos
  double getAnchoTicketPts() {
    return mmToPts(_anchoTicket);
  }

  /// Carga la configuración desde SharedPreferences
  Future<void> cargarConfiguracion() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Cargar configuración de márgenes y tamaño
      _margenIzquierdo =
          prefs.getDouble(keyMargenIzquierdo) ?? defaultMargenIzquierdo;
      _margenDerecho =
          prefs.getDouble(keyMargenDerecho) ?? defaultMargenDerecho;
      _margenSuperior =
          prefs.getDouble(keyMargenSuperior) ?? defaultMargenSuperior;
      _margenInferior =
          prefs.getDouble(keyMargenInferior) ?? defaultMargenInferior;
      _anchoTicket = prefs.getDouble(keyAnchoTicket) ?? defaultAnchoTicket;
      _escalaTicket = prefs.getDouble(keyEscalaTicket) ?? defaultEscalaTicket;
      _rotacionAutomatica =
          prefs.getBool(keyRotacionAutomatica) ?? defaultRotacionAutomatica;
      _ajusteAutomatico =
          prefs.getBool(keyAjusteAutomatico) ?? defaultAjusteAutomatico;

      // Cargar configuración de impresión
      _imprimirFormatoA4 =
          prefs.getBool(keyImprimirFormatoA4) ?? defaultImprimirFormatoA4;
      _imprimirFormatoTicket = prefs.getBool(keyImprimirFormatoTicket) ??
          defaultImprimirFormatoTicket;
      _abrirPdfDespuesDeImprimir =
          prefs.getBool(keyAbrirPdfDespuesDeImprimir) ??
              defaultAbrirPdfDespuesDeImprimir;
      _impresionDirecta =
          prefs.getBool(keyImpresionDirecta) ?? defaultImpresionDirecta;
      _impresoraSeleccionada = prefs.getString(keyImpresoraSeleccionada);

      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar configuración de impresión: $e');
    }
  }

  /// Guarda la configuración en SharedPreferences
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

      // Variable para controlar si hubo cambios reales
      bool cambiosRealizados = false;

      // Actualizar valores si se proporcionan y son diferentes
      if (margenIzquierdo != null && _margenIzquierdo != margenIzquierdo) {
        _margenIzquierdo = margenIzquierdo;
        await prefs.setDouble(keyMargenIzquierdo, margenIzquierdo);
        cambiosRealizados = true;
      }

      if (margenDerecho != null && _margenDerecho != margenDerecho) {
        _margenDerecho = margenDerecho;
        await prefs.setDouble(keyMargenDerecho, margenDerecho);
        cambiosRealizados = true;
      }

      if (margenSuperior != null && _margenSuperior != margenSuperior) {
        _margenSuperior = margenSuperior;
        await prefs.setDouble(keyMargenSuperior, margenSuperior);
        cambiosRealizados = true;
      }

      if (margenInferior != null && _margenInferior != margenInferior) {
        _margenInferior = margenInferior;
        await prefs.setDouble(keyMargenInferior, margenInferior);
        cambiosRealizados = true;
      }

      if (anchoTicket != null && _anchoTicket != anchoTicket) {
        _anchoTicket = anchoTicket;
        await prefs.setDouble(keyAnchoTicket, anchoTicket);
        cambiosRealizados = true;
      }

      if (escalaTicket != null && _escalaTicket != escalaTicket) {
        _escalaTicket = escalaTicket;
        await prefs.setDouble(keyEscalaTicket, escalaTicket);
        cambiosRealizados = true;
      }

      if (rotacionAutomatica != null &&
          _rotacionAutomatica != rotacionAutomatica) {
        _rotacionAutomatica = rotacionAutomatica;
        await prefs.setBool(keyRotacionAutomatica, rotacionAutomatica);
        cambiosRealizados = true;
      }

      if (ajusteAutomatico != null && _ajusteAutomatico != ajusteAutomatico) {
        _ajusteAutomatico = ajusteAutomatico;
        await prefs.setBool(keyAjusteAutomatico, ajusteAutomatico);
        cambiosRealizados = true;
      }

      if (imprimirFormatoA4 != null &&
          _imprimirFormatoA4 != imprimirFormatoA4) {
        _imprimirFormatoA4 = imprimirFormatoA4;
        await prefs.setBool(keyImprimirFormatoA4, imprimirFormatoA4);
        cambiosRealizados = true;
      }

      if (imprimirFormatoTicket != null &&
          _imprimirFormatoTicket != imprimirFormatoTicket) {
        _imprimirFormatoTicket = imprimirFormatoTicket;
        await prefs.setBool(keyImprimirFormatoTicket, imprimirFormatoTicket);
        cambiosRealizados = true;
      }

      if (abrirPdfDespuesDeImprimir != null &&
          _abrirPdfDespuesDeImprimir != abrirPdfDespuesDeImprimir) {
        _abrirPdfDespuesDeImprimir = abrirPdfDespuesDeImprimir;
        await prefs.setBool(
            keyAbrirPdfDespuesDeImprimir, abrirPdfDespuesDeImprimir);
        cambiosRealizados = true;
      }

      if (impresionDirecta != null && _impresionDirecta != impresionDirecta) {
        _impresionDirecta = impresionDirecta;
        await prefs.setBool(keyImpresionDirecta, impresionDirecta);
        cambiosRealizados = true;
      }

      if (impresoraSeleccionada != null &&
          _impresoraSeleccionada != impresoraSeleccionada) {
        _impresoraSeleccionada = impresoraSeleccionada;
        await prefs.setString(keyImpresoraSeleccionada, impresoraSeleccionada);
        cambiosRealizados = true;
      }

      // Solo notificar si hubo cambios reales
      if (cambiosRealizados) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al guardar configuración de impresión: $e');
    }
  }

  /// Restaura la configuración a valores por defecto
  Future<void> restaurarConfiguracionPorDefecto() async {
    try {
      _margenIzquierdo = defaultMargenIzquierdo;
      _margenDerecho = defaultMargenDerecho;
      _margenSuperior = defaultMargenSuperior;
      _margenInferior = defaultMargenInferior;
      _anchoTicket = defaultAnchoTicket;
      _escalaTicket = defaultEscalaTicket;
      _rotacionAutomatica = defaultRotacionAutomatica;
      _ajusteAutomatico = defaultAjusteAutomatico;
      _imprimirFormatoA4 = defaultImprimirFormatoA4;
      _imprimirFormatoTicket = defaultImprimirFormatoTicket;
      _abrirPdfDespuesDeImprimir = defaultAbrirPdfDespuesDeImprimir;
      _impresionDirecta = defaultImpresionDirecta;
      _impresoraSeleccionada = null;

      await guardarConfiguracion(
        margenIzquierdo: defaultMargenIzquierdo,
        margenDerecho: defaultMargenDerecho,
        margenSuperior: defaultMargenSuperior,
        margenInferior: defaultMargenInferior,
        anchoTicket: defaultAnchoTicket,
        escalaTicket: defaultEscalaTicket,
        rotacionAutomatica: defaultRotacionAutomatica,
        ajusteAutomatico: defaultAjusteAutomatico,
        imprimirFormatoA4: defaultImprimirFormatoA4,
        imprimirFormatoTicket: defaultImprimirFormatoTicket,
        abrirPdfDespuesDeImprimir: defaultAbrirPdfDespuesDeImprimir,
        impresionDirecta: defaultImpresionDirecta,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error al restaurar configuración por defecto: $e');
    }
  }

  /// Carga la lista de impresoras disponibles
  Future<void> cargarImpresoras() async {
    try {
      debugPrint('🔍 Buscando impresoras disponibles...');

      // Intentar obtener las impresoras disponibles
      _impresorasDisponibles = await Printing.listPrinters();
      debugPrint('📝 Impresoras encontradas: ${_impresorasDisponibles.length}');

      // Si no se encontraron impresoras, intentar de nuevo después de un breve retraso
      if (_impresorasDisponibles.isEmpty) {
        debugPrint('⚠️ No se encontraron impresoras, intentando de nuevo...');
        await Future.delayed(const Duration(milliseconds: 500));
        _impresorasDisponibles = await Printing.listPrinters();
        debugPrint(
            '📝 Segundo intento - Impresoras encontradas: ${_impresorasDisponibles.length}');
      }

      // Si aún no hay impresoras disponibles, no continuar
      if (_impresorasDisponibles.isEmpty) {
        debugPrint(
            '❌ No se encontraron impresoras disponibles después de varios intentos');
        mostrarMensaje(
          mensaje: 'No se encontraron impresoras disponibles',
          backgroundColor: Colors.orange,
        );
        return;
      }

      // Imprimir información sobre las impresoras encontradas para depuración
      for (var printer in _impresorasDisponibles) {
        debugPrint(
            '🖨️ Impresora: ${printer.name} | Predeterminada: ${printer.isDefault} | Disponible: ${printer.isAvailable}');
      }

      // Verificar si la impresora seleccionada actual sigue disponible
      bool impresoraSeleccionadaDisponible = _impresoraSeleccionada != null &&
          _impresorasDisponibles
              .any((p) => p.name == _impresoraSeleccionada && p.isAvailable);

      // Si la impresora seleccionada ya no está disponible o no se ha seleccionado ninguna
      if (!impresoraSeleccionadaDisponible) {
        debugPrint('⚠️ Seleccionando nueva impresora predeterminada...');

        // 1. Primero, intentar encontrar la impresora marcada como predeterminada del sistema
        Printer? defaultPrinter;
        try {
          defaultPrinter = _impresorasDisponibles.firstWhere(
            (p) => p.isDefault && p.isAvailable,
          );
          debugPrint(
              '✅ Impresora predeterminada encontrada: ${defaultPrinter.name}');
        } catch (e) {
          debugPrint(
              '⚠️ No se encontró impresora predeterminada, buscando cualquier disponible');

          // 2. Si no hay una impresora predeterminada, elegir cualquier impresora disponible
          try {
            defaultPrinter = _impresorasDisponibles.firstWhere(
              (p) => p.isAvailable,
            );
            debugPrint(
                '✅ Impresora disponible encontrada: ${defaultPrinter.name}');
          } catch (e) {
            // 3. Si no hay impresoras disponibles, simplemente tomar la primera de la lista
            if (_impresorasDisponibles.isNotEmpty) {
              defaultPrinter = _impresorasDisponibles.first;
              debugPrint(
                  '⚠️ Usando primera impresora de la lista: ${defaultPrinter.name}');
            }
          }
        }

        // Si encontramos una impresora, establecerla como seleccionada
        if (defaultPrinter != null) {
          _impresoraSeleccionada = defaultPrinter.name;
          await guardarConfiguracion(
              impresoraSeleccionada: defaultPrinter.name);
          debugPrint('✅ Nueva impresora seleccionada: ${defaultPrinter.name}');
        } else {
          debugPrint('❌ No se pudo seleccionar ninguna impresora');
          _impresoraSeleccionada = null;
        }
      } else {
        debugPrint(
            '✅ Impresora seleccionada (${_impresoraSeleccionada}) sigue disponible');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error al cargar impresoras: $e');
      _impresorasDisponibles = [];
      // No cambiar la impresora seleccionada en caso de error temporal
    }
  }

  /// Obtiene la impresora seleccionada actual
  Printer? obtenerImpresoraSeleccionada() {
    // Si no hay impresoras disponibles o no se ha seleccionado ninguna, no se puede continuar
    if (_impresorasDisponibles.isEmpty) {
      debugPrint('❌ No hay impresoras disponibles para seleccionar');
      return null;
    }

    try {
      // Caso 1: Tenemos una impresora seleccionada y aún está disponible
      if (_impresoraSeleccionada != null) {
        final printerExists = _impresorasDisponibles
            .any((p) => p.name == _impresoraSeleccionada && p.isAvailable);

        if (printerExists) {
          final printer = _impresorasDisponibles
              .firstWhere((p) => p.name == _impresoraSeleccionada);
          debugPrint('✅ Usando impresora seleccionada: ${printer.name}');
          return printer;
        } else {
          debugPrint(
              '⚠️ La impresora seleccionada ya no está disponible, buscando alternativa');
        }
      }

      // Caso 2: No tenemos una impresora seleccionada o ya no está disponible
      // Intentar obtener la impresora predeterminada del sistema
      try {
        final defaultPrinter = _impresorasDisponibles
            .firstWhere((p) => p.isDefault && p.isAvailable);
        debugPrint('✅ Usando impresora predeterminada: ${defaultPrinter.name}');
        // Actualizar la selección para futuros usos
        if (_impresoraSeleccionada != defaultPrinter.name) {
          _impresoraSeleccionada = defaultPrinter.name;
          guardarConfiguracion(impresoraSeleccionada: defaultPrinter.name);
        }
        return defaultPrinter;
      } catch (e) {
        debugPrint(
            '⚠️ No se encontró impresora predeterminada, buscando cualquier disponible');
      }

      // Caso 3: Buscar cualquier impresora disponible
      try {
        final availablePrinter =
            _impresorasDisponibles.firstWhere((p) => p.isAvailable);
        debugPrint(
            '✅ Usando primera impresora disponible: ${availablePrinter.name}');
        // Actualizar la selección para futuros usos
        if (_impresoraSeleccionada != availablePrinter.name) {
          _impresoraSeleccionada = availablePrinter.name;
          guardarConfiguracion(impresoraSeleccionada: availablePrinter.name);
        }
        return availablePrinter;
      } catch (e) {
        debugPrint(
            '⚠️ No se encontró ninguna impresora disponible, usando la primera de la lista');
      }

      // Caso 4: Último recurso, usar la primera impresora de la lista
      if (_impresorasDisponibles.isNotEmpty) {
        final anyPrinter = _impresorasDisponibles.first;
        debugPrint(
            '⚠️ Usando la primera impresora de la lista: ${anyPrinter.name}');
        // Actualizar la selección para futuros usos
        if (_impresoraSeleccionada != anyPrinter.name) {
          _impresoraSeleccionada = anyPrinter.name;
          guardarConfiguracion(impresoraSeleccionada: anyPrinter.name);
        }
        return anyPrinter;
      }

      // Si llegamos aquí, no se encontró ninguna impresora
      debugPrint('❌ No se pudo encontrar ninguna impresora');
      return null;
    } catch (e) {
      debugPrint('❌ Error al obtener impresora seleccionada: $e');
      return null;
    }
  }

  /// Abre un PDF en una aplicación externa
  ///
  /// [url] URL del documento PDF
  /// [context] Contexto para mostrar mensajes de error (opcional)
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
      debugPrint('Error al abrir el PDF: $e');

      final mensaje = 'Error al abrir el PDF: $e';
      if (context == null || !context.mounted) {
        mostrarMensaje(
          mensaje: mensaje,
          backgroundColor: Colors.red,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Imprime un documento PDF desde una URL con bypass de verificación SSL
  ///
  /// [url] URL del documento PDF
  /// [nombreDocumento] Nombre para el trabajo de impresión
  /// [context] Contexto para mostrar mensajes (opcional)
  Future<bool> imprimirDocumentoPdf(String url, String nombreDocumento,
      [BuildContext? context]) async {
    try {
      // Condensamos los logs en un solo mensaje de depuración
      debugPrint('''
🖨️ Procesando impresión:
- Documento: $nombreDocumento
- Formato: ${_imprimirFormatoTicket ? 'Ticket' : 'A4'} 
- Impresión directa: ${_impresionDirecta ? 'Sí' : 'No'}
- Impresora: ${_impresoraSeleccionada ?? 'No seleccionada'}
''');

      // Ajustar URL según el formato seleccionado
      String urlFinal = url;
      if (_imprimirFormatoTicket && url.contains('type=a4')) {
        urlFinal = url.replaceAll('type=a4', 'type=ticket');
      } else if (_imprimirFormatoA4 && url.contains('type=ticket')) {
        urlFinal = url.replaceAll('type=ticket', 'type=a4');
      }

      // Mostrar mensaje de preparación
      final mensaje = 'Preparando documento para impresión...';
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        mostrarMensaje(
          mensaje: mensaje,
          duration: const Duration(seconds: 1),
        );
      }

      // Crear un cliente HTTP que acepte todos los certificados
      final httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      // Realizar la solicitud HTTP
      final request = await httpClient.getUrl(Uri.parse(urlFinal));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Error al descargar el PDF: ${response.statusCode}');
      }

      // Leer los bytes de la respuesta
      final List<int> bytesBuilder = [];
      await for (var data in response) {
        bytesBuilder.addAll(data);
      }
      final Uint8List bytes = Uint8List.fromList(bytesBuilder);

      debugPrint('📥 PDF descargado: ${bytes.length} bytes');

      // Cerrar el cliente HTTP
      httpClient.close();

      // Configurar opciones de impresión
      final PdfPageFormat pageFormat;
      if (_imprimirFormatoTicket) {
        // Formato ticket personalizado
        final anchoTicketPts = getAnchoTicketPts();
        final margenes = getMargenesPts();

        pageFormat = PdfPageFormat(
          anchoTicketPts,
          double.infinity, // Alto automático
          marginLeft: margenes['izquierdo']!,
          marginRight: margenes['derecho']!,
          marginTop: margenes['superior']!,
          marginBottom: margenes['inferior']!,
        );
      } else {
        // Formato A4 con márgenes personalizados
        final margenes = getMargenesPts();
        pageFormat = PdfPageFormat.a4.copyWith(
          marginLeft: margenes['izquierdo']!,
          marginRight: margenes['derecho']!,
          marginTop: margenes['superior']!,
          marginBottom: margenes['inferior']!,
        );
      }

      // Imprimir documento
      bool result;
      if (_impresionDirecta) {
        // Obtener la impresora seleccionada o la predeterminada
        final printer = obtenerImpresoraSeleccionada();
        if (printer == null) {
          throw Exception('No hay impresora disponible');
        }

        debugPrint('🖨️ Imprimiendo en: ${printer.name}');

        // Imprimir directamente sin diálogo
        result = await Printing.directPrintPdf(
          printer: printer,
          onLayout: (_) => Future.value(bytes),
          name: nombreDocumento,
          format: pageFormat,
          usePrinterSettings:
              !_imprimirFormatoTicket, // Usar configuración de impresora solo para A4
        );
      } else {
        // Mostrar diálogo de impresión
        result = await Printing.layoutPdf(
          onLayout: (_) => Future.value(bytes),
          name: nombreDocumento,
          format: pageFormat,
          usePrinterSettings: !_imprimirFormatoTicket,
        );
      }

      debugPrint('🖨️ Resultado: ${result ? 'Exitoso' : 'Fallido'}');

      if (result) {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Documento enviado a la impresora'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          mostrarMensaje(
            mensaje: 'Documento enviado a la impresora',
            backgroundColor: Colors.green,
          );
        }

        // Si la impresión es exitosa y está configurado para abrir PDF
        if (result && _abrirPdfDespuesDeImprimir) {
          await abrirPdf(urlFinal);
        }

        return true;
      } else {
        // Si la impresión falló, abrir el PDF como fallback
        await abrirPdf(urlFinal);

        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo imprimir. PDF abierto en navegador'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          mostrarMensaje(
            mensaje: 'No se pudo imprimir. PDF abierto en navegador',
            backgroundColor: Colors.orange,
          );
        }
        return false;
      }
    } catch (e) {
      // Manejar errores
      debugPrint('❌ Error al imprimir documento: $e');

      // Intentar abrir el PDF en el navegador como alternativa
      await abrirPdf(url);

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al imprimir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        mostrarMensaje(
          mensaje: 'Error al imprimir: $e',
          backgroundColor: Colors.red,
        );
      }
      return false;
    }
  }
}
