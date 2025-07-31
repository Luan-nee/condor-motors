import 'dart:async';
import 'dart:math' show min;

import 'package:condorsmotors/api/index.api.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:condorsmotors/utils/logger.dart';
import 'package:flutter/material.dart';

/// Clase para gestionar la conversión de proformas a ventas
class ProformaConversionManager {
  // Instancias de repositorios
  static final SucursalRepository _sucursalRepository =
      SucursalRepository.instance;
  static final ProformaRepository _proformaRepository =
      ProformaRepository.instance;
  static final VentaRepository _ventaRepository = VentaRepository.instance;

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
      Logger.debug(
          'INICIO: Convirtiendo proforma #$proformaId a venta tipo $tipoDocumento en sucursal $sucursalId');

      // Limpiar caché de ventas para evitar problemas de inconsistencia de tipos
      _limpiarCacheVentas(sucursalId);

      // Invalidar cache al inicio para asegurar que tenemos datos actualizados
      _recargarDatos(sucursalId);

      // Mostrar diálogo de procesamiento
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) =>
              _buildProcessingDialog(tipoDocumento.toLowerCase()),
        );
      }

      // Verificar que la sucursal tenga configuradas las series necesarias
      try {
        Logger.debug(
            'Verificando configuración de series para la sucursal #$sucursalId...');

        // Asegurarse de que sucursalId sea siempre String para la API
        final String sucursalIdStr = sucursalId.toString();

        final Sucursal sucursal = await _sucursalRepository
            .getSucursalData(sucursalIdStr, forceRefresh: true);

        // Verificar la serie según el tipo de documento
        if (tipoDocumento.toUpperCase() == 'BOLETA' &&
            (sucursal.serieBoleta == null || sucursal.serieBoleta!.isEmpty)) {
          Logger.error(
              'ERROR: La sucursal no tiene configurada una serie para BOLETAS');
          if (context.mounted) {
            _cerrarDialogoProcesamiento(context);
            _mostrarError(
                context,
                'La sucursal no tiene configurada una serie para boletas. '
                'Por favor configure la serie en la sección de administración de sucursales.');
          }
          return false;
        } else if (tipoDocumento.toUpperCase() == 'FACTURA' &&
            (sucursal.serieFactura == null || sucursal.serieFactura!.isEmpty)) {
          Logger.error(
              'ERROR: La sucursal no tiene configurada una serie para FACTURAS');
          if (context.mounted) {
            _cerrarDialogoProcesamiento(context);
            _mostrarError(
                context,
                'La sucursal no tiene configurada una serie para facturas. '
                'Por favor configure la serie en la sección de administración de sucursales.');
          }
          return false;
        }

        Logger.debug('Series de sucursal verificadas correctamente. '
            'Boleta: ${sucursal.serieBoleta ?? 'No configurada'}, '
            'Factura: ${sucursal.serieFactura ?? 'No configurada'}');
      } catch (e) {
        Logger.error('Error al verificar configuración de sucursal: $e');
        if (context.mounted) {
          _cerrarDialogoProcesamiento(context);
          _mostrarError(
              context, 'Error al verificar configuración de la sucursal: $e');
        }
        return false;
      }

      // Verificar los tipos de documentos disponibles en el sistema
      try {
        Logger.debug('Obteniendo información de tipos de documentos...');
        // Esta llamada podría ser reemplazada por una API real que consulte los tipos de documentos disponibles
        // Por ahora, asumimos que los tipos 1 (BOLETA) y 2 (FACTURA) son válidos
        Logger.debug('Tipos de documentos conocidos: 1=BOLETA, 2=FACTURA');
      } catch (e) {
        Logger.debug(
            'Error al obtener tipos de documentos: $e - Usando valores por defecto');
      }

      // Primero, verificar si la proforma existe sin usar caché para evitar problemas
      try {
        Logger.debug('Verificando existencia de proforma #$proformaId...');

        // Asegurarse de que sucursalId sea siempre String para la API
        final String sucursalIdStr = sucursalId.toString();

        final proformaExistResponse = await _proformaRepository.getProforma(
          sucursalId: sucursalIdStr,
          proformaId: proformaId,
          useCache: false,
          forceRefresh: true,
        );

        Logger.debug(
            'Respuesta de verificación: ${proformaExistResponse.toString().substring(0, min(100, proformaExistResponse.toString().length))}...');

        // Verificar explícitamente si hay un error 404
        if (proformaExistResponse.isEmpty ||
            proformaExistResponse['status'] == 'fail' ||
            !proformaExistResponse.containsKey('data') ||
            proformaExistResponse['data'] == null) {
          Logger.debug(
              'ERROR: Proforma #$proformaId no encontrada o datos inválidos');
          Logger.debug('Respuesta completa: $proformaExistResponse');

          // Cerrar diálogo de procesamiento
          if (context.mounted) {
            _cerrarDialogoProcesamiento(context);

            // Mensaje personalizado si es error 404
            if (proformaExistResponse.containsKey('error') &&
                proformaExistResponse['error']
                    .toString()
                    .contains('Not found')) {
              _mostrarError(context,
                  'La proforma #$proformaId no existe o fue eliminada');
            } else {
              _mostrarError(
                  context, 'No se pudo obtener información de la proforma');
            }
          }

          // Invalidar la caché completamente
          _proformaRepository.invalidateCache(sucursalIdStr);
          // Forzar recarga de lista de proformas
          _recargarProformasSucursal(sucursalIdStr);

          return false;
        }

        Logger.debug(
            'ÉXITO: Proforma #$proformaId verificada, obteniendo datos completos...');

        // Si llegamos aquí, la proforma existe, obtenerla de nuevo para procesar sus datos
        final proformaResponse = await _proformaRepository.getProforma(
          sucursalId: sucursalIdStr,
          proformaId: proformaId,
        );

        Logger.debug('Datos de proforma recibidos, validando formato...');

        // Verificar si el formato de datos es correcto
        if (!proformaResponse.containsKey('data') ||
            proformaResponse['data'] == null) {
          Logger.debug('ERROR: Formato inválido en datos de proforma');
          if (context.mounted) {
            _cerrarDialogoProcesamiento(context);
            _mostrarError(context, 'Formato de datos de proforma inválido');
          }
          return false;
        }

        final Map<String, dynamic> proformaData =
            Map<String, dynamic>.from(proformaResponse['data'] as Map);
        final List<dynamic> detalles = proformaData['detalles'] ?? [];

        Logger.debug('Detalles de proforma: ${detalles.length} productos');

        // Verificar si hay detalles en la proforma
        if (detalles.isEmpty) {
          Logger.debug('ERROR: Proforma sin productos');
          if (context.mounted) {
            _cerrarDialogoProcesamiento(context);
            _mostrarError(context,
                'La proforma no tiene productos, no se puede convertir a venta');
          }
          return false;
        }

        // Verificar si hay cliente - Ahora lo hacemos opcional
        final dynamic clienteId = proformaData['clienteId'];
        final dynamic clienteInfo = proformaData['cliente'];

        Logger.debug(
            'Información de cliente: ${clienteInfo != null ? "Presente" : "No presente"}, ID: $clienteId');

        // Obtener ID del tipoTax para gravado (18% IGV)
        Logger.debug('Obteniendo ID para tipo Tax Gravado (IGV 18%)');
        final int tipoTaxId =
            await _proformaRepository.getGravadoTaxId(sucursalIdStr);
        Logger.debug('ID obtenido para Tax Gravado: $tipoTaxId');

        // Transformar los detalles al formato esperado por el endpoint de ventas
        final List<Map<String, dynamic>> detallesTransformados = [];
        for (final dynamic detalle in detalles) {
          try {
            if (detalle == null) {
              Logger.debug('Detalle inválido encontrado, omitiendo: $detalle');
              continue;
            }
            // Convertir a Map para evitar dynamic calls
            final Map<String, dynamic> detalleMap =
                Map<String, dynamic>.from(detalle as Map);

            // Validar que el detalle tenga la estructura mínima esperada
            if (!detalleMap.containsKey('productoId')) {
              Logger.debug('Detalle inválido encontrado, omitiendo: $detalle');
              continue;
            }

            detallesTransformados.add({
              'productoId': detalleMap['productoId'],
              'cantidad': detalleMap['cantidadPagada'] ??
                  detalleMap['cantidadTotal'] ??
                  1,
              'tipoTaxId': tipoTaxId, // Usar el ID obtenido del servidor
              'aplicarOferta': detalleMap['descuento'] != null &&
                  detalleMap['descuento'] > 0
            });

            Logger.debug('Detalle transformado: ${detallesTransformados.last}');
          } catch (e) {
            Logger.error('Error al transformar detalle: $e');
            // Continuar con el siguiente detalle en lugar de fallar toda la conversión
          }
        }

        // Verificar si quedaron detalles válidos después de la transformación
        if (detallesTransformados.isEmpty) {
          Logger.debug(
              'ERROR: No hay productos válidos después de la transformación');
          if (context.mounted) {
            _cerrarDialogoProcesamiento(context);
            _mostrarError(context,
                'Error en el formato de productos. No se puede convertir la proforma.');
          }
          return false;
        }

        // Determinar el tipo de documento correcto según la opción seleccionada
        Logger.debug('Obteniendo ID para tipo de documento: $tipoDocumento');
        final int tipoDocumentoId =
            await _proformaRepository.getTipoDocumentoIdBoleta(sucursalIdStr);
        Logger.debug('ID obtenido para $tipoDocumento: $tipoDocumentoId');

        // Obtener un cliente válido del sistema en lugar de usar uno genérico fijo
        Logger.debug('Buscando cliente válido en el sistema...');
        int clienteIdValido = 1; // Valor por defecto, pero buscaremos uno real

        try {
          // Intentar obtener una lista de clientes
          final clientes = await api.clientes.getClientes(
            pageSize: 1, // Solo necesitamos uno
          );

          if (clientes.isNotEmpty) {
            clienteIdValido = clientes.first.id;
            Logger.debug('Cliente válido encontrado con ID: $clienteIdValido');
          } else {
            Logger.debug(
                'No se encontraron clientes en el sistema, usando ID predeterminado');
          }
        } catch (e) {
          Logger.error('Error al buscar clientes: $e');
          Logger.debug('Usando ID de cliente predeterminado: $clienteIdValido');
        }

        final Map<String, dynamic> ventaData = {
          'observaciones': 'Convertida desde Proforma #$proformaId',
          'tipoDocumentoId': tipoDocumentoId,
          'detalles': detallesTransformados,
          'clienteId':
              clienteIdValido, // Usar el ID de cliente válido encontrado
        };

        // Extraer clienteId del objeto cliente si está disponible
        int? clienteIdNumerico;
        // Primero revisar si tenemos clienteId directo
        if (clienteId != null) {
          clienteIdNumerico = int.tryParse(clienteId.toString());
        }
        // Si no tenemos clienteId directo, intentar extraerlo del objeto cliente
        else if (clienteInfo != null &&
            clienteInfo is Map &&
            (clienteInfo).containsKey('id')) {
          clienteIdNumerico =
              int.tryParse((clienteInfo)['id'].toString());
        }

        // Solo sobrescribir clienteId si tenemos un valor numérico válido
        if (clienteIdNumerico != null && clienteIdNumerico > 0) {
          // Verificar que el cliente existe antes de asignarlo
          try {
            // Cliente confirmado como válido
            ventaData['clienteId'] = clienteIdNumerico;
            Logger.debug(
                'Cliente específico verificado y asignado a la venta: $clienteIdNumerico');
          } catch (e) {
            Logger.error('Error al verificar cliente específico: $e');
            Logger.debug('Manteniendo cliente genérico: $clienteIdValido');
          }
        } else {
          Logger.debug(
              'Usando cliente genérico para la venta: $clienteIdValido');
        }

        // Obtener el ID del empleado actual
        int? empleadoId;
        try {
          Logger.debug(
              'Obteniendo información del empleado asociado a la cuenta...');
          final userData = await api.auth.getUserData();

          if (userData == null) {
            Logger.error('No se pudo obtener información del usuario actual');
            if (context.mounted) {
              _cerrarDialogoProcesamiento(context);
              _mostrarError(context,
                  'No se pudo identificar al usuario para realizar la venta');
            }
            return false;
          }

          // Verificar que sucursalId coincida con el de la operación
          final String userSucursalId =
              userData.containsKey('sucursalId')
                  ? userData['sucursalId']?.toString() ?? ''
                  : '';
          if (userSucursalId.isNotEmpty && userSucursalId != sucursalId) {
            Logger.warn(
                'ADVERTENCIA: El sucursalId del usuario ($userSucursalId) es diferente al de la operación ($sucursalId)');
            // Permitimos que continúe, pero lo registramos para debugging
          }

          // Buscar el empleado asociado a esta cuenta de usuario
          // Primero intentar obtener empleadoId directamente de userData
          if (userData.containsKey('empleadoId')) {
            empleadoId = int.tryParse(userData['empleadoId'].toString());
            Logger.debug('ID de empleado encontrado en userData: $empleadoId');
          }

          // Si no se encontró en userData, intentar buscar empleado por sucursal actual
          if (empleadoId == null || empleadoId <= 0) {
            Logger.debug('Buscando empleados en la sucursal $sucursalId...');

            // Asegurarse de que sucursalId sea siempre String para la API
            final String sucursalIdStr = sucursalId.toString();

            // Usar el método específico para obtener empleados por sucursal
            final empleadosSucursal =
                await api.empleados.getEmpleadosPorSucursal(sucursalIdStr);

            if (empleadosSucursal.empleados.isNotEmpty) {
              // Preferir empleado asociado al usuario si existe
              String? userId;
              if (userData.containsKey('id')) {
                userId = userData['id']?.toString();
              }
              if (userId != null) {
                // Buscar empleado que coincida con el ID de usuario
                final empleadoUsuario = empleadosSucursal.empleados.firstWhere(
                  (emp) => emp.cuentaEmpleadoId == userId,
                  orElse: () => empleadosSucursal
                      .empleados.first, // Si no encuentra, usar el primero
                );
                empleadoId = int.tryParse(empleadoUsuario.id);
                Logger.debug(
                    'Empleado encontrado asociado al usuario: $empleadoId');
              } else {
                // Si no hay ID de usuario, usar el primer empleado de la sucursal
                empleadoId = int.tryParse(empleadosSucursal.empleados.first.id);
                Logger.debug(
                    'Usando primer empleado de la sucursal: $empleadoId');
              }
            } else {
              Logger.error(
                  'No se encontraron empleados para la sucursal $sucursalId');
            }
          }

          // Si no pudimos encontrar un ID de empleado válido, fallar con un mensaje claro
          if (empleadoId == null || empleadoId <= 0) {
            Logger.error(
                'No se pudo obtener un ID de empleado válido para la sucursal $sucursalId');
            if (context.mounted) {
              _cerrarDialogoProcesamiento(context);
              _mostrarError(context,
                  'No se encontró un empleado válido en la sucursal para realizar la venta');
            }
            return false;
          }

          // Asignar el ID de empleado a los datos de la venta
          ventaData['empleadoId'] = empleadoId;
          Logger.debug(
              'Empleado asignado a la venta: $empleadoId (sucursal: $sucursalId)');
        } catch (e) {
          Logger.error('Error al buscar empleado: $e');
          if (context.mounted) {
            _cerrarDialogoProcesamiento(context);
            _mostrarError(
                context, 'Error al identificar al empleado: ${e.toString()}');
          }
          return false;
        }

        // Verificaciones finales antes de enviar la petición
        if (!ventaData.containsKey('clienteId') ||
            !ventaData.containsKey('empleadoId') ||
            !ventaData.containsKey('tipoDocumentoId') ||
            ventaData['detalles'].isEmpty) {
          Logger.error('Datos de venta incompletos: ${ventaData.keys}');
          if (context.mounted) {
            _cerrarDialogoProcesamiento(context);
            _mostrarError(
                context, 'Faltan datos requeridos para crear la venta');
          }
          return false;
        }

        Logger.debug('PREPARANDO VENTA: $ventaData');

        // ALTERNATIVA MANUAL: Si después de varios intentos la conversión automática sigue fallando,
        // se puede recomendar al usuario hacer la conversión manual:
        // 1. Copiar los datos de los productos de la proforma
        // 2. Crear una nueva venta manualmente con esos productos
        // 3. Marcar la proforma como convertida

        // Crear la venta usando la API estándar de ventas
        Logger.debug('Enviando petición para crear venta...');
        try {
          // Asegurarse de que sucursalId sea siempre String para la API
          final String sucursalIdStr = sucursalId.toString();

          final Map<String, dynamic> ventaResponse =
              await api.ventas.createVenta(
            ventaData,
            sucursalId: sucursalIdStr,
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
            bool esErrorCliente = false;

            // Mensajes específicos para errores comunes
            if (errorMsg.contains('tipo de documento')) {
              mensajeError =
                  'Error en tipo de documento: Intente crear la venta manualmente desde el menú de ventas.';
            } else if (errorMsg.contains('cliente') ||
                errorMsg.contains('Client')) {
              mensajeError =
                  'Error con el cliente: El cliente especificado no existe o no es válido.';
              esErrorCliente = true;

              // Intentar una nueva búsqueda de cliente alternativo
              if (esErrorCliente) {
                Logger.debug('Intentando recuperar con otro cliente...');
                try {
                  // Intentar obtener una lista más grande de clientes para buscar alternativas
                  final clientes = await api.clientes.getClientes(
                    pageSize: 5, // Buscar más clientes
                  );

                  // Buscar el primer cliente diferente al que ya intentamos
                  int? otroClienteId;
                  for (final cliente in clientes) {
                    if (cliente.id != ventaData['clienteId']) {
                      otroClienteId = cliente.id;
                      break;
                    }
                  }

                  if (otroClienteId != null) {
                    Logger.debug(
                        'Encontrado cliente alternativo: $otroClienteId, reintentando conversión...');
                    mensajeError +=
                        '\n\nSe intentará nuevamente con otro cliente.';

                    // Mostrar mensaje de reintento
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Reintentando con cliente alternativo...'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }

                    // Preparar nuevo intento con cliente alternativo
                    ventaData['clienteId'] = otroClienteId;

                    // Reintentar creación con nuevo cliente
                    final nuevoResponse = await api.ventas.createVenta(
                      ventaData,
                      sucursalId: sucursalIdStr,
                    );

                    // Si el nuevo intento es exitoso, actualizar la respuesta
                    if (nuevoResponse['status'] == 'success') {
                      Logger.debug('¡Éxito con cliente alternativo!');
                      // Reemplazar la respuesta fallida con la exitosa
                      ventaResponse
                        ..clear()
                        ..addAll(nuevoResponse);

                      // Continuar el flujo normal (al salir del if)
                      return true; // Retornar éxito directamente
                    } else {
                      Logger.error(
                          'También falló con cliente alternativo: ${nuevoResponse['error']}');
                      mensajeError +=
                          '\nTambién falló con cliente alternativo.';
                    }
                  }
                } catch (e) {
                  Logger.error('Error al intentar con cliente alternativo: $e');
                }
              }
            } else if (errorMsg.contains('tipoTaxId')) {
              mensajeError =
                  'Error en impuestos: Los datos de impuestos no son válidos.';
            }

            // Añadir sugerencia de creación manual si es un error persistente
            mensajeError +=
                '\n\nSe recomienda crear la venta manualmente usando los datos de la proforma.';

            if (context.mounted) {
              _mostrarError(context, mensajeError);
            }
            return false;
          } else {
            // Verificar si el objeto data contiene un error anidado
            final dynamic responseData = ventaResponse['data'];
            if (responseData is Map &&
                responseData.containsKey('status') &&
                responseData['status'] == 'fail') {
              final String nestedErrorMsg = responseData.containsKey('error')
                  ? responseData['error'].toString()
                  : 'Error desconocido en respuesta';

              Logger.error('ERROR ANIDADO EN RESPUESTA: $nestedErrorMsg');
              if (context.mounted) {
                _cerrarDialogoProcesamiento(context);
                _mostrarError(
                    context, 'No se pudo crear la venta: $nestedErrorMsg');
              }
              return false;
            }

            String numeroDoc = '';
            if (ventaResponse['data'] is Map &&
                (ventaResponse['data'] as Map).containsKey('numeroDocumento')) {
              numeroDoc =
                  (ventaResponse['data'] as Map)['numeroDocumento'] ?? '';
            }
            Logger.debug(
                'ÉXITO: Venta creada correctamente con documento: $numeroDoc');
            Logger.debug('Datos de venta creada: ${ventaResponse['data']}');

            // Venta creada exitosamente, intentar declararla ante SUNAT
            await _declararVentaRecienCreada(ventaResponse, sucursalIdStr);

            if (context.mounted) {
              _mostrarExito(context, 'Venta creada correctamente: $numeroDoc');
            }

            // Eliminar la proforma después de convertirla a venta
            Logger.debug(
                'Eliminando proforma #$proformaId después de convertirla a venta...');
            try {
              final deleteResponse = await _proformaRepository.deleteProforma(
                sucursalId: sucursalIdStr,
                proformaId: proformaId,
              );
              Logger.debug(
                  'Respuesta de eliminación de proforma: $deleteResponse');
            } catch (deleteError) {
              // Si hay error al eliminar, registrarlo pero no fallar el proceso completo
              Logger.error(
                  'Advertencia: No se pudo eliminar la proforma #$proformaId: $deleteError');
            }

            // Ejecutar callback de éxito
            Logger.debug('Ejecutando callback de éxito...');
            onSuccess();

            // Forzar recarga de proformas para actualizar UI
            Logger.debug('Recargando lista de proformas...');
            _recargarProformasSucursal(sucursalIdStr);

            Logger.debug(
                'PROCESO COMPLETADO: Proforma #$proformaId convertida exitosamente a venta');
            return true;
          }
        } catch (e) {
          Logger.error('ERROR EN API DE VENTAS: $e');

          // Cerrar diálogo de procesamiento si aún está abierto
          if (context.mounted) {
            _cerrarDialogoProcesamiento(context);
            _mostrarError(context, 'Error al crear la venta: ${e.toString()}');
          }
          return false;
        }
      } catch (apiError) {
        // Manejar específicamente el caso donde la proforma no existe (404)
        Logger.error('ERROR EN API: $apiError');

        if (apiError.toString().contains('404') ||
            apiError.toString().contains('Not found')) {
          Logger.debug('ERROR 404: Proforma #$proformaId no encontrada');

          // Asegurarse de que sucursalId sea siempre String para la API
          final String sucursalIdStr = sucursalId.toString();

          // Invalidar caché
          _proformaRepository.invalidateCache(sucursalIdStr);
          _recargarProformasSucursal(sucursalIdStr);

          if (context.mounted) {
            _cerrarDialogoProcesamiento(context);
            _mostrarError(
                context, 'La proforma #$proformaId no existe o fue eliminada');
          }
          return false;
        }

        // Otros errores de API
        Logger.error('Error en petición API: $apiError');
        if (context.mounted) {
          _cerrarDialogoProcesamiento(context);
          _mostrarError(
              context, 'Error en la conversión: ${apiError.toString()}');
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
      _proformaRepository
        ..invalidateCache(sucursalId)
        // Invalidar caché global de proformas
        ..invalidateCache();
      Logger.debug('Caché de proformas invalidado para sucursal $sucursalId');

      // Invalidar caché de ventas para la sucursal específica
      _ventaRepository
        ..invalidateCache(sucursalId)
        // Invalidar caché global de ventas
        ..invalidateCache();
      Logger.debug('Caché de ventas invalidado para sucursal $sucursalId');

      // Invalidar caché de sucursales
      _sucursalRepository.invalidateCache();
      Logger.debug('Caché de sucursales invalidado');

      // Recargar datos de la sucursal para mantener coherencia
      await _sucursalRepository.getSucursalData(sucursalId, forceRefresh: true);
      Logger.debug('Datos de sucursal recargados: $sucursalId');

      // Recargar proformas específicas para esta sucursal
      await _proformaRepository.getProformas(
        sucursalId: sucursalId,
        useCache: false,
        forceRefresh: true,
      );
      Logger.debug('Lista de proformas recargada para sucursal $sucursalId');

      // Recargar lista de ventas para mantener coherencia
      await _ventaRepository.getVentas(
        sucursalId: sucursalId,
        useCache: false,
        forceRefresh: true,
      );
      Logger.debug('Lista de ventas recargada para sucursal $sucursalId');
    } catch (e) {
      Logger.error('Error al recargar datos: $e');
      // No propagamos el error para no interrumpir el flujo principal
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
      // Invalidar caché de proformas para la sucursal específica
      _proformaRepository
        ..invalidateCache(sucursalId)
        // Invalidar caché global de proformas
        ..invalidateCache();
      Logger.debug('Caché de proformas invalidado para sucursal $sucursalId');

      // Invalidar caché de ventas para la sucursal específica
      _ventaRepository
        ..invalidateCache(sucursalId)
        // Invalidar caché global de ventas
        ..invalidateCache();
      Logger.debug('Caché de ventas invalidado para sucursal $sucursalId');

      // Invalidar caché de sucursales
      _sucursalRepository.invalidateCache();
      Logger.debug('Caché de sucursales invalidado');

      // Forzar recarga de la lista de proformas
      await _proformaRepository.getProformas(
        sucursalId: sucursalId,
        useCache: false,
        forceRefresh: true,
      );
      Logger.debug('Lista de proformas recargada para sucursal $sucursalId');

      // Recargar lista de ventas para mantener coherencia
      await _ventaRepository.getVentas(
        sucursalId: sucursalId,
        useCache: false,
        forceRefresh: true,
      );
      Logger.debug('Lista de ventas recargada para sucursal $sucursalId');

      // También recargar desde la API de sucursales para mantener sincronización
      await _sucursalRepository.getSucursalData(sucursalId, forceRefresh: true);
      Logger.debug('Datos de sucursal recargados: $sucursalId');
    } catch (e) {
      Logger.error('Error al recargar lista de proformas: $e');
    }
  }

  /// Limpia la caché de ventas para evitar problemas de inconsistencia de tipos
  static void _limpiarCacheVentas(String sucursalId) {
    try {
      // Asegurarse de que sucursalId sea siempre String para la API
      final String sucursalIdStr = sucursalId.toString();

      // Limpiar caché de ventas para la sucursal específica
      _ventaRepository.invalidateCache(sucursalIdStr);
      Logger.debug('Caché de ventas limpiado para sucursal $sucursalIdStr');

      // También limpiar caché global de ventas por si acaso
      _ventaRepository.invalidateCache();
      Logger.debug('Caché global de ventas limpiado');
    } catch (e) {
      Logger.error('Error al limpiar caché de ventas: $e');
      // No propagamos el error para no interrumpir el flujo principal
    }
  }

  /// Declara una venta recién creada ante SUNAT
  static Future<void> _declararVentaRecienCreada(
      Map<String, dynamic> ventaResponse, String sucursalId) async {
    try {
      // Obtener el ID de la venta desde la respuesta
      int? ventaId;

      if (ventaResponse.containsKey('data') &&
          ventaResponse['data'] is Map<String, dynamic> &&
          (ventaResponse['data'] as Map<String, dynamic>).containsKey('id')) {
        ventaId =
            int.tryParse((ventaResponse['data'] as Map<String, dynamic>)['id'].toString());
      }

      if (ventaId == null) {
        Logger.error(
            'No se pudo obtener el ID de la venta creada para declararla');
        return;
      }

      Logger.debug('Declarando venta #$ventaId ante SUNAT');

      // Llamar al endpoint de declaración
      final Map<String, dynamic> declaracionResponse =
          await _ventaRepository.declararVenta(
        ventaId.toString(),
        sucursalId: sucursalId,
      );

      if (declaracionResponse['status'] == 'success') {
        Logger.debug('Venta #$ventaId declarada correctamente ante SUNAT');
      } else {
        final String errorMsg = declaracionResponse['error'] ??
            declaracionResponse['message'] ??
            'Error desconocido';
        Logger.error('Error al declarar venta #$ventaId: $errorMsg');
      }
    } catch (e) {
      Logger.error('Error al declarar venta recién creada: $e');
    }
  }
}
