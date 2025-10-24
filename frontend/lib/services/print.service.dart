import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

/// Servicio para manejo de apertura e impresión de PDFs
class PrintService {
  PrintService._();
  static final PrintService instance = PrintService._();

  /// Intenta abrir un PDF en una aplicación externa
  Future<bool> openPdfUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('PrintService.openPdfUrl error: $e');
      return false;
    }
  }

  /// Descarga e imprime un PDF desde una URL
  Future<bool> printPdfFromUrl(String url,
      {String jobName = 'Documento'}) async {
    try {
      // Crear un cliente HTTP que acepte todos los certificados
      final HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
      final HttpClientResponse response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final List<int> bytesBuilder = <int>[];
      await for (final List<int> data in response) {
        bytesBuilder.addAll(data);
      }
      final Uint8List bytes = Uint8List.fromList(bytesBuilder);
      httpClient.close();

      final bool result = await Printing.layoutPdf(
        onLayout: (_) => bytes,
        name: jobName,
      );

      return result;
    } catch (e) {
      debugPrint('PrintService.printPdfFromUrl error: $e');
      return false;
    }
  }
}
