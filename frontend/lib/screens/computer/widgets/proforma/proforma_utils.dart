import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/proforma.model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utilidades para manejar proformas y ventas pendientes
class VentasPendientesUtils {
  /// Obtiene el ID de sucursal del usuario autenticado
  ///
  /// Retorna el ID como entero, o null si no se encuentra
  static Future<int?> obtenerSucursalId() async {
    try {
      final Map<String, dynamic>? userData =
          await api.authService.getUserData();
      if (userData != null && userData.containsKey('sucursalId')) {
        try {
          return int.parse(userData['sucursalId'].toString());
        } catch (e) {
          debugPrint('Error al parsear sucursalId: $e');
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener datos del usuario: $e');
      return null;
    }
  }

  /// Convierte una lista de objetos Proforma a formato compatible con ventasPendientes
  ///
  /// [proformas] - Lista de objetos Proforma a convertir
  ///
  /// Retorna una lista de mapas con el formato necesario para PendingSalesWidget
  static List<Map<String, dynamic>> convertirProformasAVentasPendientes(
      List<Proforma> proformas) {
    return proformas.map((Proforma proforma) {
      return convertirProformaAVentaPendiente(proforma);
    }).toList();
  }

  /// Convierte un objeto Proforma individual a formato compatible con ventasPendientes
  ///
  /// [proforma] - Objeto Proforma a convertir
  ///
  /// Retorna un mapa con el formato necesario para PendingSalesWidget
  static Map<String, dynamic> convertirProformaAVentaPendiente(
      Proforma proforma) {
    // Obtener datos del cliente, o crear uno genérico si no existe
    final Map<String, dynamic> cliente = proforma.cliente ??
        <String, dynamic>{
          'id': 0,
          'nombre': 'Cliente sin nombre',
          'documento': proforma.clienteId != null
              ? 'ID: ${proforma.clienteId}'
              : 'Sin documento',
        };

    // Convertir detalles a formato de productos para UI
    final List<Map<String, dynamic>> productos =
        _procesarProductosProforma(proforma);

    // Incluir información sobre promociones en la proforma
    final List<DetalleProforma> detallesConPromociones = proforma.detalles
        .where((DetalleProforma d) => tienePromocion(d))
        .toList();

    // Generar un resumen de promociones para mostrar en la UI
    final Map<String, dynamic> promociones = <String, dynamic>{
      'tienePromociones': detallesConPromociones.isNotEmpty,
      'cantidadProductosConPromocion': detallesConPromociones.length,
      'detallePromociones': _generarResumenPromociones(detallesConPromociones),
    };

    return <String, dynamic>{
      'id': proforma.id,
      'nombre': proforma.nombre ?? 'Proforma #${proforma.id}',
      'total': proforma.total,
      'fecha': formatearFecha(proforma.fechaCreacion),
      'tipoDocumento': 'PROFORMA',
      'cliente': cliente,
      'sucursalId': proforma.sucursalId,
      'detalles': proforma.detalles,
      'productos': productos,
      'empleadoId': proforma.empleadoId,
      'tipoVenta': 'PROFORMA', // Tipo para diferenciar en la lista
      'estado': proforma.estado.toText(),
      'promociones': promociones,
      'fechaExpiracion': proforma.fechaExpiracion,
      'proformaObj': proforma, // Incluir el objeto original para acceso directo
    };
  }

  /// Procesa los detalles de proforma y los convierte a formato de productos para UI
  static List<Map<String, dynamic>> _procesarProductosProforma(
      Proforma proforma) {
    return proforma.detalles
        .map<Map<String, dynamic>>((DetalleProforma detalle) {
      // Verificar si tiene promociones
      final bool enPromocion = tienePromocion(detalle);

      // Determinar el tipo de promoción
      String? tipoPromocion;
      if (enPromocion && detalle.producto != null) {
        if (detalle.producto!.liquidacion) {
          tipoPromocion = 'liquidacion';
        } else if (detalle.producto!.cantidadGratisDescuento != null &&
            detalle.producto!.cantidadGratisDescuento! > 0) {
          tipoPromocion = 'unidades_gratis';
        } else if (detalle.producto!.porcentajeDescuento != null &&
            detalle.producto!.porcentajeDescuento! > 0) {
          tipoPromocion = 'descuento_porcentual';
        }
      }

      return <String, dynamic>{
        'id': detalle.productoId,
        'nombre': detalle.nombre,
        'precio': detalle.precioUnitario,
        'cantidad': detalle.cantidad,
        'subtotal': detalle.subtotal,
        'sku': detalle.sku,
        'marca': detalle.marca,
        'categoria': detalle.categoria,
        'enPromocion': enPromocion,
        'tipoPromocion': tipoPromocion,
        'detalleCompleto': detalle,
      };
    }).toList();
  }

  /// Genera un resumen de las promociones en una proforma
  static Map<String, dynamic> _generarResumenPromociones(
      List<DetalleProforma> detalles) {
    int cantidadLiquidacion = 0;
    int cantidadGratis = 0;
    int cantidadDescuento = 0;
    double ahorroEstimado = 0.0;

    for (final DetalleProforma detalle in detalles) {
      if (detalle.producto == null) {
        continue;
      }

      final Producto producto = detalle.producto!;

      // Verificar promociones y calcular ahorros
      if (producto.liquidacion && producto.precioOferta != null) {
        cantidadLiquidacion++;
        final double ahorroUnitario =
            producto.precioVenta - producto.precioOferta!;
        ahorroEstimado += ahorroUnitario * detalle.cantidad;
      } else if (producto.cantidadMinimaDescuento != null &&
          producto.cantidadMinimaDescuento! > 0 &&
          producto.cantidadGratisDescuento != null &&
          producto.cantidadGratisDescuento! > 0) {
        cantidadGratis++;

        // Calcular unidades gratis que recibiría
        final int promocionesCompletas =
            detalle.cantidad ~/ producto.cantidadMinimaDescuento!;
        if (promocionesCompletas > 0) {
          final int unidadesGratis =
              promocionesCompletas * producto.cantidadGratisDescuento!;
          ahorroEstimado += unidadesGratis * producto.precioVenta;
        }
      } else if (producto.cantidadMinimaDescuento != null &&
          producto.cantidadMinimaDescuento! > 0 &&
          producto.porcentajeDescuento != null &&
          producto.porcentajeDescuento! > 0) {
        cantidadDescuento++;

        // Verificar si aplica descuento porcentual
        if (detalle.cantidad >= producto.cantidadMinimaDescuento!) {
          final double descuento =
              producto.precioVenta * (producto.porcentajeDescuento! / 100);
          ahorroEstimado += descuento * detalle.cantidad;
        }
      }
    }

    return <String, dynamic>{
      'productosLiquidacion': cantidadLiquidacion,
      'productosUnidadesGratis': cantidadGratis,
      'productosDescuentoPorcentual': cantidadDescuento,
      'ahorroEstimado': ahorroEstimado,
    };
  }

  /// Verifica si un detalle de proforma tiene promociones
  static bool tienePromocion(DetalleProforma detalle) {
    if (detalle.producto == null) {
      return false;
    }

    final Producto producto = detalle.producto!;

    // Verificar si tiene liquidación
    if (producto.liquidacion && producto.precioOferta != null) {
      return true;
    }

    // Verificar promoción de unidades gratis
    if (producto.cantidadMinimaDescuento != null &&
        producto.cantidadMinimaDescuento! > 0 &&
        producto.cantidadGratisDescuento != null &&
        producto.cantidadGratisDescuento! > 0) {
      return true;
    }

    // Verificar descuento porcentual
    if (producto.cantidadMinimaDescuento != null &&
        producto.cantidadMinimaDescuento! > 0 &&
        producto.porcentajeDescuento != null &&
        producto.porcentajeDescuento! > 0) {
      return true;
    }

    return false;
  }

  /// Verifica si un ID de venta corresponde a una proforma
  ///
  /// [id] - ID de venta a verificar
  /// [tipoVenta] - Si se proporciona, se verifica este campo directamente
  ///
  /// Retorna true si es una proforma, false en caso contrario
  static bool esProforma(String id, {String? tipoVenta}) {
    // Si se proporciona el tipo de venta, usarlo directamente
    if (tipoVenta != null) {
      return tipoVenta == 'PROFORMA';
    }

    // Para compatibilidad con el formato antiguo
    if (id.startsWith('PRO-')) {
      return true;
    }

    return false;
  }

  /// Extrae el ID numérico de una proforma
  ///
  /// [id] - ID de proforma, ya sea en formato numérico directo o "PRO-X"
  ///
  /// Retorna el ID numérico, o null si el formato es inválido
  static int? extraerIdProforma(String id) {
    // Primero intentar parsear directamente (nuevo formato)
    try {
      return int.parse(id);
    } catch (_) {
      // Si falla, intentar el formato antiguo
      if (id.startsWith('PRO-')) {
        try {
          return int.parse(
              id.substring(4)); // Quitar "PRO-" y convertir a entero
        } catch (e) {
          debugPrint('Error al extraer ID de proforma: $e');
        }
      }
    }

    return null;
  }

  /// Formatea una fecha para mostrar
  ///
  /// [fecha] - Fecha a formatear
  ///
  /// Retorna un string con el formato: "dd/MM/yyyy HH:mm"
  static String formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }

  /// Valida si una proforma puede ser convertida a venta
  ///
  /// [proforma] - Proforma a validar
  ///
  /// Retorna un mapa con el resultado de la validación y mensajes
  static Map<String, dynamic> validarProformaParaVenta(Proforma proforma) {
    final bool esValida = proforma.estado == EstadoProforma.pendiente;
    final bool estaExpirada = proforma.haExpirado();
    final List<String> mensajes = <String>[];

    if (!esValida) {
      mensajes.add('La proforma no está en estado pendiente');
    }

    if (estaExpirada) {
      mensajes.add('La proforma ha expirado');
    }

    // Verificar stock disponible (esto requeriría consultas adicionales)

    return <String, dynamic>{
      'esValida': esValida && !estaExpirada,
      'mensajes': mensajes,
    };
  }

  /// Finaliza una proforma convirtiéndola a venta
  ///
  /// [proformaId] - ID de la proforma a finalizar
  /// [datosVenta] - Datos adicionales para la venta (clienteId, tipoDocumento, etc.)
  ///
  /// Retorna un mapa con {exito: bool, mensaje: String} indicando el resultado
  static Future<Map<String, dynamic>> finalizarProforma(
    int proformaId,
    Map<String, dynamic> datosVenta,
  ) async {
    try {
      // Obtener datos del usuario
      final Map<String, dynamic>? userData =
          await api.authService.getUserData();
      if (userData == null) {
        return <String, dynamic>{
          'exito': false,
          'mensaje': 'No se pudo obtener los datos del usuario',
        };
      }

      // Obtener sucursalId y empleadoId del usuario actual
      final int? sucursalId = userData['sucursalId'] != null
          ? int.tryParse(userData['sucursalId'].toString())
          : null;
      final int? empleadoId = userData['id'] != null
          ? int.tryParse(userData['id'].toString())
          : null;

      if (sucursalId == null) {
        return <String, dynamic>{
          'exito': false,
          'mensaje': 'No se pudo obtener el ID de la sucursal',
        };
      }

      if (empleadoId == null) {
        return <String, dynamic>{
          'exito': false,
          'mensaje': 'No se pudo obtener el ID del empleado',
        };
      }

      // Recargar los datos antes de intentar la conversión
      _recargarDatos(sucursalId.toString());

      try {
        debugPrint('Iniciando conversión de proforma #$proformaId a venta...');

        // Primero, verificar si la proforma existe sin usar caché para evitar problemas
        final Map<String, dynamic> proformaExistResponse =
            await api.proformas.getProformaVenta(
          sucursalId: sucursalId.toString(),
          proformaId: proformaId,
          useCache: false, // Evitar usar caché
          forceRefresh: true, // Forzar recarga desde el servidor
        );

        // Verificar explícitamente si hay un error o respuesta vacía
        if (proformaExistResponse.isEmpty ||
            proformaExistResponse['status'] == 'fail' ||
            !proformaExistResponse.containsKey('data') ||
            proformaExistResponse['data'] == null) {
          // Invalidar la caché para esta proforma específica
          api.proformas.invalidateCache(sucursalId.toString());

          String mensaje = 'La proforma #$proformaId no existe o fue eliminada';
          if (proformaExistResponse.containsKey('error')) {
            final errorMsg = proformaExistResponse['error'];
            if (errorMsg != null && errorMsg.toString().contains('Not found')) {
              mensaje = 'La proforma #$proformaId no existe o fue eliminada';
            } else {
              mensaje = 'Error: ${proformaExistResponse['error']}';
            }
          }

          debugPrint(
              'Error: Proforma $proformaId no existe. Respuesta: $proformaExistResponse');
          return <String, dynamic>{
            'exito': false,
            'mensaje': mensaje,
          };
        }

        // Si llegamos aquí, la proforma existe, obtener sus datos
        final Map<String, dynamic> proformaData = proformaExistResponse['data'];
        final List<dynamic> detalles = proformaData['detalles'] ?? [];

        // Verificar si hay detalles en la proforma
        if (detalles.isEmpty) {
          return <String, dynamic>{
            'exito': false,
            'mensaje':
                'La proforma no tiene productos, no se puede convertir a venta',
          };
        }

        // Verificar el cliente
        final dynamic clienteId =
            proformaData['clienteId'] ?? datosVenta['clienteId'];
        if (clienteId == null) {
          return <String, dynamic>{
            'exito': false,
            'mensaje': 'La venta requiere un cliente válido',
          };
        }

        // Preparar datos para la venta asegurando valores válidos
        final Map<String, dynamic> ventaData = {
          'observaciones': datosVenta['observaciones'] ??
              'Convertida desde Proforma #$proformaId',
          'tipoDocumentoId': datosVenta['tipoDocumentoId'] ??
              (datosVenta['tipoDocumento'] == 'BOLETA' ? 1 : 2),
          'monedaId': datosVenta['monedaId'] ?? 1,
          'metodoPagoId': datosVenta['metodoPagoId'] ?? 1,
          'clienteId': int.tryParse(clienteId.toString()) ?? 0,
          'empleadoId': empleadoId,
          'detalles': detalles,
        };

        debugPrint('Preparando datos para crear venta: $ventaData');

        // Crear la venta usando la API de ventas
        final Map<String, dynamic> ventaResponse = await api.ventas.createVenta(
          ventaData,
          sucursalId: sucursalId.toString(),
        );

        if (ventaResponse['status'] != 'success') {
          final errorMsg = ventaResponse['error'] ??
              ventaResponse['message'] ??
              'Error desconocido';
          debugPrint('Error al crear venta desde proforma: $errorMsg');
          return <String, dynamic>{
            'exito': false,
            'mensaje': 'Error al crear la venta: $errorMsg',
            'detalles': ventaResponse
          };
        }

        // Actualizar el estado de la proforma a "convertida"
        await api.proformas.updateProformaVenta(
          sucursalId: sucursalId.toString(),
          proformaId: proformaId,
          estado: 'convertida',
        );

        // Recargar datos después de la conversión
        _recargarDatos(sucursalId.toString());

        return <String, dynamic>{
          'exito': true,
          'mensaje': 'Proforma convertida exitosamente',
          'respuesta': ventaResponse,
        };
      } catch (apiError) {
        // Manejar específicamente el caso donde la proforma no existe (404)
        if (apiError.toString().contains('404') ||
            apiError.toString().contains('Not found')) {
          // Invalidar la caché para esta proforma
          api.proformas.invalidateCache(sucursalId.toString());

          debugPrint(
              'Error 404: Proforma $proformaId no existe. Error: $apiError');
          return <String, dynamic>{
            'exito': false,
            'mensaje': 'La proforma #$proformaId no existe o fue eliminada',
          };
        }
        // Otros errores de API
        debugPrint('Error en petición API: $apiError');
        return <String, dynamic>{
          'exito': false,
          'mensaje': 'Error al procesar la proforma: $apiError',
        };
      }
    } catch (e) {
      debugPrint('Error general al finalizar proforma: $e');
      return <String, dynamic>{
        'exito': false,
        'mensaje': 'Error al finalizar la proforma: $e',
      };
    }
  }

  /// Recarga los datos de proformas y sucursales para asegurar sincronización
  static Future<void> _recargarDatos(String sucursalId) async {
    try {
      // Invalidar caché de proformas para la sucursal específica
      api.proformas.invalidateCache(sucursalId);
      debugPrint('🔄 Caché de proformas invalidado para sucursal $sucursalId');

      // Recargar datos de la sucursal para mantener coherencia
      await api.sucursales.getSucursalData(sucursalId, forceRefresh: true);
      debugPrint('🔄 Datos de sucursal recargados: $sucursalId');

      // Recargar proformas específicas para esta sucursal
      await api.proformas.getProformasVenta(
        sucursalId: sucursalId,
        useCache: false,
        forceRefresh: true,
      );
      debugPrint('🔄 Lista de proformas recargada para sucursal $sucursalId');
    } catch (e) {
      debugPrint('❌ Error al recargar datos: $e');
      // No propagamos el error para no interrumpir el flujo principal
    }
  }

  /// Formatea solo la fecha sin la hora
  static String formatearSoloFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  /// Formatea solo la hora
  static String formatearSoloHora(DateTime fecha) {
    return DateFormat('HH:mm').format(fecha);
  }

  /// Verifica si una proforma está en estado pendiente
  static bool estaEnPendiente(Proforma proforma) {
    return proforma.estado == EstadoProforma.pendiente;
  }

  /// Verifica si una proforma ya ha sido convertida a venta
  static bool estaConvertida(Proforma proforma) {
    return proforma.estado == EstadoProforma.convertida;
  }

  /// Verifica si una proforma está cancelada
  static bool estaCancelada(Proforma proforma) {
    return proforma.estado == EstadoProforma.cancelada;
  }

  /// Verifica si una proforma ha expirado
  static bool haExpirado(Proforma proforma) {
    if (proforma.fechaExpiracion == null) {
      return false;
    }
    return proforma.fechaExpiracion!.isBefore(DateTime.now());
  }

  /// Calcula el tiempo restante hasta la expiración de la proforma
  static String tiempoRestante(Proforma proforma) {
    if (proforma.fechaExpiracion == null) {
      return 'Sin fecha de expiración';
    }

    final DateTime ahora = DateTime.now();
    if (proforma.fechaExpiracion!.isBefore(ahora)) {
      return 'Expirada';
    }

    final Duration diferencia = proforma.fechaExpiracion!.difference(ahora);
    if (diferencia.inDays > 0) {
      return '${diferencia.inDays} ${diferencia.inDays == 1 ? 'día' : 'días'}';
    } else if (diferencia.inHours > 0) {
      return '${diferencia.inHours} ${diferencia.inHours == 1 ? 'hora' : 'horas'}';
    } else {
      return '${diferencia.inMinutes} ${diferencia.inMinutes == 1 ? 'minuto' : 'minutos'}';
    }
  }

  /// Muestra un snackbar con mensaje de éxito
  static void mostrarExito(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Muestra un snackbar con mensaje de error
  static void mostrarError(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Muestra un diálogo de confirmación genérico
  static Future<bool> confirmar(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    String textoCancelar = 'Cancelar',
    String textoConfirmar = 'Confirmar',
    IconData? icono,
    Color? colorIcono,
  }) async {
    final bool? resultado = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Row(
          children: [
            if (icono != null) ...[
              Icon(icono, color: colorIcono ?? Colors.blue),
              const SizedBox(width: 10),
            ],
            Text(
              titulo,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          mensaje,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(textoCancelar),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: Text(textoConfirmar),
          ),
        ],
      ),
    );

    return resultado ?? false;
  }

  /// Genera un texto descriptivo del estado de la proforma
  static String textoEstado(Proforma proforma) {
    switch (proforma.estado) {
      case EstadoProforma.pendiente:
        return haExpirado(proforma) ? 'Expirada' : 'Pendiente';
      case EstadoProforma.convertida:
        return 'Convertida a venta';
      case EstadoProforma.cancelada:
        return 'Cancelada';
      default:
        return 'Desconocido';
    }
  }

  /// Obtiene un color asociado al estado de la proforma
  static Color colorEstado(Proforma proforma) {
    switch (proforma.estado) {
      case EstadoProforma.pendiente:
        return haExpirado(proforma) ? Colors.orange : Colors.blue;
      case EstadoProforma.convertida:
        return Colors.green;
      case EstadoProforma.cancelada:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// Extensión para agregar métodos útiles a las proformas
extension ProformaExtension on Proforma {
  /// Obtiene el nombre del cliente de la proforma
  String getNombreCliente() {
    if (cliente != null) {
      return cliente!['nombre'] ?? 'Cliente sin nombre';
    }
    return 'Cliente sin asignar';
  }

  /// Verifica si la proforma ha expirado
  bool haExpirado() {
    return VentasPendientesUtils.haExpirado(this);
  }

  /// Verifica si la proforma puede convertirse en venta
  bool puedeConvertirseEnVenta() {
    // Solo se pueden convertir proformas pendientes y no expiradas
    return estado == EstadoProforma.pendiente && !haExpirado();
  }
}
