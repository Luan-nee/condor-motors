import 'dart:async';
import 'dart:math' show min;

import 'package:condorsmotors/main.dart' show api; // Importar la API global
import 'package:condorsmotors/utils/logger.dart';
import 'package:flutter/material.dart';

/// Clase para gestionar la conversión de proformas a ventas
class ProformaConversionManager {
  /// Convierte una proforma a venta con manejo de errores
  ///
  /// [context] Contexto para mostrar mensajes
  /// [sucursalId] ID de la sucursal
  /// [proformaId] ID de la proforma a convertir
  /// [tipoDocumento] Tipo de documento (BOLETA/FACTURA)
  /// [onSuccess] Callback ejecutado al completar la conversión exitosamente
  ///
  /// Retorna true si la conversión fue exitosa, false en caso contrario
  static Future<bool> convertirProformaAVenta({
    required BuildContext context,
    required String sucursalId,
    required int proformaId,
    required String tipoDocumento,
    required VoidCallback onSuccess,
  }) async {
    try {
      Logger.debug('INICIO: Convirtiendo proforma #$proformaId a venta tipo $tipoDocumento en sucursal $sucursalId');
      
      // Invalidar cache al inicio para asegurar que tenemos datos actualizados
      _recargarDatos(sucursalId);
      
      // Mostrar diálogo de procesamiento
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => _buildProcessingDialog(tipoDocumento.toLowerCase()),
        );
      }
      
      // Primero, verificar si la proforma existe sin usar caché para evitar problemas
      try {
        Logger.debug('Verificando existencia de proforma #$proformaId...');
        final proformaExistResponse = await api.proformas.getProformaVenta(
          sucursalId: sucursalId,
          proformaId: proformaId,
          useCache: false,
          forceRefresh: true,
        );
        
        Logger.debug('Respuesta de verificación: ${proformaExistResponse.toString().substring(0, min(100, proformaExistResponse.toString().length))}...');
        
        // Verificar explícitamente si hay un error 404
        if (proformaExistResponse.isEmpty || 
            proformaExistResponse['status'] == 'fail' || 
            !proformaExistResponse.containsKey('data') || 
            proformaExistResponse['data'] == null) {
          
          Logger.debug('ERROR: Proforma #$proformaId no encontrada o datos inválidos');
          Logger.debug('Respuesta completa: $proformaExistResponse');
          
          // Cerrar diálogo de procesamiento
          if (context.mounted) {
            _cerrarDialogoProcesamiento(context);
            
            // Mensaje personalizado si es error 404
            if (proformaExistResponse.containsKey('error') && 
                proformaExistResponse['error'].toString().contains('Not found')) {
              _mostrarError(context, 'La proforma #$proformaId no existe o fue eliminada');
            } else {
              _mostrarError(context, 'No se pudo obtener información de la proforma');
            }
          }
          
          // Invalidar la caché completamente
          api.proformas.invalidateCache(sucursalId);
          // Forzar recarga de lista de proformas 
          _recargarProformasSucursal(sucursalId);
          
          return false;
        }
        
        Logger.debug('ÉXITO: Proforma #$proformaId verificada, obteniendo datos completos...');
        
        // Si llegamos aquí, la proforma existe, obtenerla de nuevo para procesar sus datos
        final proformaResponse = await api.proformas.getProformaVenta(
          sucursalId: sucursalId,
          proformaId: proformaId,
        );
        
        Logger.debug('Datos de proforma recibidos, validando formato...');
        
        // Verificar si el formato de datos es correcto
        if (!proformaResponse.containsKey('data') || proformaResponse['data'] == null) {
          Logger.debug('ERROR: Formato inválido en datos de proforma');
          if (context.mounted) {
            _cerrarDialogoProcesamiento(context);
            _mostrarError(context, 'Formato de datos de proforma inválido');
          }
          return false;
        }
        
        final proformaData = proformaResponse['data'];
        final List<dynamic> detalles = proformaData['detalles'] ?? [];
        
        Logger.debug('Detalles de proforma: ${detalles.length} productos');
        
        // Verificar si hay detalles en la proforma
        if (detalles.isEmpty) {
          Logger.debug('ERROR: Proforma sin productos');
          if (context.mounted) {
            _cerrarDialogoProcesamiento(context);
            _mostrarError(context, 'La proforma no tiene productos, no se puede convertir a venta');
          }
          return false;
        }
        
        // Verificar si hay cliente - Ahora lo hacemos opcional
        final dynamic clienteId = proformaData['clienteId'];
        final dynamic clienteInfo = proformaData['cliente'];
        
        Logger.debug('Información de cliente: ${clienteInfo != null ? "Presente" : "No presente"}, ID: $clienteId');
        
        // Transformar los detalles al formato esperado por el endpoint de ventas
        final List<Map<String, dynamic>> detallesTransformados = [];
        for (final dynamic detalle in detalles) {
          try {
            // Validar que el detalle tenga la estructura mínima esperada
            if (detalle == null || !detalle.containsKey('productoId')) {
              Logger.debug('Detalle inválido encontrado, omitiendo: $detalle');
              continue;
            }
            
            // Crear detalle en formato esperado por el API de ventas
            detallesTransformados.add({
              'productoId': detalle['productoId'],
              'cantidad': detalle['cantidadPagada'] ?? detalle['cantidadTotal'] ?? 1,
              'tipoTaxId': 7, // IGV estándar (18%), valor por defecto
              'aplicarOferta': detalle['descuento'] != null && detalle['descuento'] > 0
            });
            
            Logger.debug('Detalle transformado: ${detallesTransformados.last}');
          } catch (e) {
            Logger.error('Error al transformar detalle: $e');
            // Continuar con el siguiente detalle en lugar de fallar toda la conversión
          }
        }
        
        // Verificar si quedaron detalles válidos después de la transformación
        if (detallesTransformados.isEmpty) {
          Logger.debug('ERROR: No hay productos válidos después de la transformación');
          if (context.mounted) {
            _cerrarDialogoProcesamiento(context);
            _mostrarError(context, 'Error en el formato de productos. No se puede convertir la proforma.');
          }
          return false;
        }
        
        // Crear venta a partir de los datos de la proforma
        final Map<String, dynamic> ventaData = {
          'observaciones': 'Convertida desde Proforma #$proformaId',
          'tipoDocumentoId': tipoDocumento == 'BOLETA' ? 1 : 2,
          'monedaId': 1, // PEN por defecto
          'metodoPagoId': 1, // Efectivo por defecto
          'detalles': detallesTransformados,
          'clienteId': 1, // Cliente genérico por defecto (se puede sobrescribir si hay uno válido)
        };
        
        // Extraer clienteId del objeto cliente si está disponible
        int? clienteIdNumerico;
        // Primero revisar si tenemos clienteId directo
        if (clienteId != null) {
          clienteIdNumerico = int.tryParse(clienteId.toString());
        }
        // Si no tenemos clienteId directo, intentar extraerlo del objeto cliente
        else if (clienteInfo != null && clienteInfo is Map && clienteInfo.containsKey('id')) {
          clienteIdNumerico = int.tryParse(clienteInfo['id'].toString());
        }
        
        // Solo sobrescribir clienteId si tenemos un valor numérico válido
        if (clienteIdNumerico != null && clienteIdNumerico > 0) {
          // Reemplazar el clienteId genérico con el específico
          ventaData['clienteId'] = clienteIdNumerico;
          Logger.debug('Cliente específico asignado a la venta: $clienteIdNumerico');
        } else {
          Logger.debug('Usando cliente genérico (ID: 1) para la venta');
        }
        
        // Obtener el ID del empleado actual
        final userData = await api.authService.getUserData();
        if (userData != null && userData.containsKey('id')) {
          final int? empleadoId = int.tryParse(userData['id'].toString());
          if (empleadoId != null && empleadoId > 0) {
            ventaData['empleadoId'] = empleadoId;
          }
        }
        
        Logger.debug('PREPARANDO VENTA: $ventaData');
        
        // ALTERNATIVA MANUAL: Si después de varios intentos la conversión automática sigue fallando,
        // se puede recomendar al usuario hacer la conversión manual:
        // 1. Copiar los datos de los productos de la proforma
        // 2. Crear una nueva venta manualmente con esos productos
        // 3. Marcar la proforma como convertida
        
        // Crear la venta usando la API estándar de ventas
        Logger.debug('Enviando petición para crear venta...');
        final Map<String, dynamic> ventaResponse = await api.ventas.createVenta(
          ventaData,
          sucursalId: sucursalId,
        );
        
        Logger.debug('RESPUESTA CREACIÓN VENTA COMPLETA: $ventaResponse');
        
        // Cerrar diálogo de procesamiento
        if (context.mounted) {
          _cerrarDialogoProcesamiento(context);
        }
        
        // Validar el resultado de la creación de venta
        if (ventaResponse['status'] != 'success') {
          final String errorMsg = ventaResponse.containsKey('error') 
              ? ventaResponse['error'].toString() 
              : ventaResponse['message'] ?? 'Error desconocido';
          
          Logger.error('ERROR CREACIÓN VENTA: $errorMsg');
          
          String mensajeError = 'No se pudo crear la venta: $errorMsg';
          
          // Añadir sugerencia de creación manual si es un error persistente
          if (errorMsg.contains('clienteId') || errorMsg.contains('tipoTaxId')) {
            mensajeError += '\n\nIntente crear la venta manualmente usando los datos de la proforma.';
          }
          
          if (context.mounted) {
            _mostrarError(context, mensajeError);
          }
          return false;
        }
        
        // Verificación adicional para asegurar que realmente se creó la venta
        if (!ventaResponse.containsKey('data') || ventaResponse['data'] == null) {
          Logger.error('ERROR: Respuesta de creación de venta sin datos');
          if (context.mounted) {
            _cerrarDialogoProcesamiento(context);
            _mostrarError(context, 'Error en formato de respuesta al crear venta');
          }
          return false;
        }
        
        // Verificar si el objeto data contiene un error anidado
        final dynamic responseData = ventaResponse['data'];
        if (responseData is Map && responseData.containsKey('status') && responseData['status'] == 'fail') {
          final String nestedErrorMsg = responseData.containsKey('error')
              ? responseData['error'].toString()
              : 'Error desconocido en respuesta';
          
          Logger.error('ERROR ANIDADO EN RESPUESTA: $nestedErrorMsg');
          if (context.mounted) {
            _cerrarDialogoProcesamiento(context);
            _mostrarError(context, 'No se pudo crear la venta: $nestedErrorMsg');
          }
          return false;
        }
        
        final String numeroDoc = ventaResponse['data']?['numeroDocumento'] ?? '';
        Logger.debug('ÉXITO: Venta creada correctamente con documento: $numeroDoc');
        Logger.debug('Datos de venta creada: ${ventaResponse['data']}');
        
        if (context.mounted) {
          _mostrarExito(context, 'Venta creada correctamente: $numeroDoc');
        }
        
        // Marcar la proforma como convertida (actualizar estado)
        Logger.debug('Actualizando estado de proforma a "convertida"...');
        final updateResponse = await api.proformas.updateProformaVenta(
          sucursalId: sucursalId,
          proformaId: proformaId,
          estado: 'convertida',
        );
        
        Logger.debug('Respuesta de actualización proforma: $updateResponse');
        
        // Ejecutar callback de éxito
        Logger.debug('Ejecutando callback de éxito...');
        onSuccess();
        
        // Forzar recarga de proformas para actualizar UI
        Logger.debug('Recargando lista de proformas...');
        _recargarProformasSucursal(sucursalId);
        
        Logger.debug('PROCESO COMPLETADO: Proforma #$proformaId convertida exitosamente a venta');
        return true;
        
      } catch (apiError) {
        // Manejar específicamente el caso donde la proforma no existe (404)
        Logger.error('ERROR EN API: $apiError');
        
        if (apiError.toString().contains('404') || 
            apiError.toString().contains('Not found')) {
          
          Logger.debug('ERROR 404: Proforma #$proformaId no encontrada');
          
          // Invalidar caché
          api.proformas.invalidateCache(sucursalId);
          _recargarProformasSucursal(sucursalId);
          
          if (context.mounted) {
            _cerrarDialogoProcesamiento(context);
            _mostrarError(context, 'La proforma #$proformaId no existe o fue eliminada');
          }
          return false;
        }
        
        // Otros errores de API
        Logger.error('Error en petición API: $apiError');
        if (context.mounted) {
          _cerrarDialogoProcesamiento(context);
          _mostrarError(context, 'Error en la conversión: ${apiError.toString()}');
        }
        return false;
      }
    } catch (e) {
      Logger.error('ERROR GENERAL: $e');
      Logger.debug('Traza de error: ${e.toString()}');
      if (context.mounted) {
        _cerrarDialogoProcesamiento(context);
        _mostrarError(context, 'Error en la conversión: ${e.toString()}');
      }
      return false;
    }
  }
  
  /// Recarga los datos de proformas y sucursales para asegurar sincronización
  static Future<void> _recargarDatos(String sucursalId) async {
    try {
      // Invalidar caché de proformas para la sucursal específica
      api.proformas.invalidateCache(sucursalId);
      Logger.debug('Caché de proformas invalidado para sucursal $sucursalId');
      
      // Recargar datos de la sucursal para mantener coherencia
      await api.sucursales.getSucursalData(sucursalId, forceRefresh: true);
      Logger.debug('Datos de sucursal recargados: $sucursalId');
      
      // Recargar proformas específicas para esta sucursal
      await api.proformas.getProformasVenta(
        sucursalId: sucursalId,
        useCache: false,
        forceRefresh: true,
      );
      Logger.debug('Lista de proformas recargada para sucursal $sucursalId');
    } catch (e) {
      Logger.error('Error al recargar datos: $e');
      // No propagamos el error para no interrumpir el flujo principal
    }
  }
  
  /// Verifica si la proforma ya fue convertida (útil para casos donde el API falla pero la conversión fue exitosa)
  static Future<bool> _verificarConversion(int proformaId) async {
    try {
      // Obtener el ID de sucursal del usuario
      final userData = await api.authService.getUserData();
      if (userData == null || !userData.containsKey('sucursalId')) {
        return false;
      }
      
      final String sucursalId = userData['sucursalId'].toString();
      
      // Verificar estado de la proforma
      final response = await api.proformas.getProformaVenta(
        sucursalId: sucursalId,
        proformaId: proformaId,
        forceRefresh: true,
      );
      
      if (response.isNotEmpty && response['data'] != null) {
        final String estado = response['data']['estado'] ?? '';
        return estado.toLowerCase() == 'convertida';
      }
      return false;
    } catch (e) {
      Logger.error('Error al verificar conversión: $e');
      return false;
    }
  }
  
  
  /// Cierra el diálogo de procesamiento
  static void _cerrarDialogoProcesamiento(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
  
  /// Muestra un mensaje de éxito
  static void _mostrarExito(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// Muestra un mensaje de error
  static void _mostrarError(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  
  /// Construye el diálogo de procesamiento
  static Widget _buildProcessingDialog(String tipoDocumento) {
    return Dialog(
      backgroundColor: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Procesando ${tipoDocumento.toLowerCase()}...',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Por favor espere',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Recarga la lista de proformas de una sucursal para mantener datos actualizados
  static Future<void> _recargarProformasSucursal(String sucursalId) async {
    try {
      // Invalidar caché de proformas
      api.proformas.invalidateCache(sucursalId);
      // Invalidar caché de la sucursal
      api.sucursales.invalidateCache(sucursalId);
      
      // Forzar recarga de la lista de proformas
      await api.proformas.getProformasVenta(
        sucursalId: sucursalId,
        useCache: false,
        forceRefresh: true,
      );
      
      // También recargar desde la API de sucursales para mantener sincronización
      await api.sucursales.getProformasVenta(
        sucursalId,
        useCache: false,
        forceRefresh: true,
      );
      
      Logger.debug('Lista de proformas recargada para sucursal $sucursalId');
    } catch (e) {
      Logger.error('Error al recargar lista de proformas: $e');
    }
  }
} 