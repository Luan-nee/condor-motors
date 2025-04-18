import 'package:condorsmotors/models/producto.model.dart';
import 'package:condorsmotors/models/proforma.model.dart' as model_proforma;
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utilidades para manejar proformas y ventas pendientes
class VentasPendientesUtils {
  /// Instancias de repositorios
  static final ProformaRepository _proformaRepository =
      ProformaRepository.instance;
  static final SucursalRepository _sucursalRepository =
      SucursalRepository.instance;
  static final VentaRepository _ventaRepository = VentaRepository.instance;

  /// Obtiene el ID de sucursal del usuario autenticado
  ///
  /// Retorna el ID como entero, o null si no se encuentra
  static Future<int?> obtenerSucursalId() async {
    try {
      final Map<String, dynamic>? userData =
          await _proformaRepository.getUserData();
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
      List<model_proforma.Proforma> proformas) {
    return proformas.map((model_proforma.Proforma proforma) {
      return convertirProformaAVentaPendiente(proforma);
    }).toList();
  }

  /// Convierte un objeto Proforma individual a formato compatible con ventasPendientes
  ///
  /// [proforma] - Objeto Proforma a convertir
  ///
  /// Retorna un mapa con el formato necesario para PendingSalesWidget
  static Map<String, dynamic> convertirProformaAVentaPendiente(
      model_proforma.Proforma proforma) {
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
    final List<model_proforma.DetalleProforma> detallesConPromociones = proforma
        .detalles
        .where((model_proforma.DetalleProforma d) => tienePromocion(d))
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
      model_proforma.Proforma proforma) {
    return proforma.detalles
        .map<Map<String, dynamic>>((model_proforma.DetalleProforma detalle) {
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
      List<model_proforma.DetalleProforma> detalles) {
    int cantidadLiquidacion = 0;
    int cantidadGratis = 0;
    int cantidadDescuento = 0;
    double ahorroEstimado = 0.0;

    for (final model_proforma.DetalleProforma detalle in detalles) {
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
  static bool tienePromocion(model_proforma.DetalleProforma detalle) {
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
  static Map<String, dynamic> validarProformaParaVenta(
      model_proforma.Proforma proforma) {
    final bool esValida =
        proforma.estado == model_proforma.EstadoProforma.pendiente;
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
          await _proformaRepository.getUserData();
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
            await _proformaRepository.getProforma(
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
          _proformaRepository.invalidateCache(sucursalId.toString());

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
        final Map<String, dynamic> ventaResponse =
            await _ventaRepository.createVenta(
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

        // Intentar declarar la venta recién creada ante SUNAT
        try {
          int? ventaId;

          if (ventaResponse.containsKey('data') &&
              ventaResponse['data'] is Map<String, dynamic> &&
              ventaResponse['data'].containsKey('id')) {
            ventaId = int.tryParse(ventaResponse['data']['id'].toString());
          }

          if (ventaId != null) {
            debugPrint('Declarando venta #$ventaId ante SUNAT');

            final Map<String, dynamic> declaracionResponse =
                await _ventaRepository.declararVenta(
              ventaId.toString(),
              sucursalId: sucursalId.toString(),
            );

            if (declaracionResponse['status'] == 'success') {
              debugPrint('Venta #$ventaId declarada correctamente ante SUNAT');
            } else {
              final errorMsg = declaracionResponse['error'] ??
                  declaracionResponse['message'] ??
                  'Error desconocido';
              debugPrint('Error al declarar venta #$ventaId: $errorMsg');
              // No detenemos el proceso si la declaración falla
            }
          } else {
            debugPrint('No se pudo obtener el ID de la venta para declararla');
          }
        } catch (e) {
          debugPrint('Error al declarar venta ante SUNAT: $e');
          // Continuamos con el proceso aunque la declaración falle
        }

        // Eliminar la proforma después de convertirla a venta
        try {
          await _proformaRepository.deleteProforma(
            sucursalId: sucursalId.toString(),
            proformaId: proformaId,
          );
          debugPrint(
              'Proforma #$proformaId eliminada después de convertirse a venta');
        } catch (deleteError) {
          // Si hay error al eliminar, registrarlo pero no fallar el proceso completo
          debugPrint(
              'Advertencia: No se pudo eliminar la proforma #$proformaId: $deleteError');
        }

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
          _proformaRepository.invalidateCache(sucursalId.toString());

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
      _proformaRepository
        ..invalidateCache(sucursalId)
        // Invalidar caché global de proformas
        ..invalidateCache();
      debugPrint('Caché de proformas invalidado para sucursal $sucursalId');

      // Invalidar caché de ventas para la sucursal específica
      _ventaRepository
        ..invalidateCache(sucursalId)
        // Invalidar caché global de ventas
        ..invalidateCache();
      debugPrint('Caché de ventas invalidado para sucursal $sucursalId');

      // Invalidar caché de sucursales
      _sucursalRepository.invalidateCache();
      debugPrint('Caché de sucursales invalidado');

      // Recargar datos de la sucursal para mantener coherencia
      await _sucursalRepository.getSucursalData(sucursalId, forceRefresh: true);
      debugPrint('Datos de sucursal recargados: $sucursalId');

      // Recargar proformas específicas para esta sucursal
      await _proformaRepository.getProformas(
        sucursalId: sucursalId,
        useCache: false,
        forceRefresh: true,
      );
      debugPrint('Lista de proformas recargada para sucursal $sucursalId');

      // Recargar lista de ventas para mantener coherencia
      await _ventaRepository.getVentas(
        sucursalId: sucursalId,
        useCache: false,
        forceRefresh: true,
      );
      debugPrint('Lista de ventas recargada para sucursal $sucursalId');
    } catch (e) {
      debugPrint('Error al recargar datos: $e');
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
  static bool estaEnPendiente(model_proforma.Proforma proforma) {
    return proforma.estado == model_proforma.EstadoProforma.pendiente;
  }

  /// Verifica si una proforma ya ha sido convertida a venta
  static bool estaConvertida(model_proforma.Proforma proforma) {
    return proforma.estado == model_proforma.EstadoProforma.convertida;
  }

  /// Verifica si una proforma está cancelada
  static bool estaCancelada(model_proforma.Proforma proforma) {
    return proforma.estado == model_proforma.EstadoProforma.cancelada;
  }

  /// Verifica si una proforma ha expirado
  static bool haExpirado(model_proforma.Proforma proforma) {
    if (proforma.fechaExpiracion == null) {
      return false;
    }
    return proforma.fechaExpiracion!.isBefore(DateTime.now());
  }

  /// Calcula el tiempo restante hasta la expiración de la proforma
  static String tiempoRestante(model_proforma.Proforma proforma) {
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
  static String textoEstado(model_proforma.Proforma proforma) {
    switch (proforma.estado) {
      case model_proforma.EstadoProforma.pendiente:
        if (proforma.haExpirado()) {
          return 'Expirada';
        }
        return 'Pendiente';
      case model_proforma.EstadoProforma.convertida:
        return 'Convertida a venta';
      case model_proforma.EstadoProforma.cancelada:
        return 'Cancelada';
      default:
        return 'Desconocido';
    }
  }

  /// Obtiene un color asociado al estado de la proforma
  static Color colorEstado(model_proforma.Proforma proforma) {
    switch (proforma.estado) {
      case model_proforma.EstadoProforma.pendiente:
        if (proforma.haExpirado()) {
          return Colors.red;
        }
        return Colors.blue;
      case model_proforma.EstadoProforma.convertida:
        return Colors.green;
      case model_proforma.EstadoProforma.cancelada:
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}

/// Extensión para agregar métodos útiles a las proformas
extension ProformaExtension on model_proforma.Proforma {
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
    return estado == model_proforma.EstadoProforma.pendiente && !haExpirado();
  }
}

/// Utilidades para trabajar con proformas
/// Centraliza operaciones comunes relacionadas con proformas
/// para evitar duplicación de código
class ProformaUtils {
  // Métodos para manejo de descuentos

  /// Verificar si un detalle de proforma tiene descuento aplicado
  static bool tieneDescuento(model_proforma.DetalleProforma detalle) {
    try {
      final dynamic descuento = (detalle as dynamic).descuento;
      return descuento != null && descuento > 0;
    } catch (e) {
      return false;
    }
  }

  /// Obtener el valor del descuento formateado como String
  static String getDescuento(model_proforma.DetalleProforma detalle) {
    try {
      final dynamic descuento = (detalle as dynamic).descuento;
      if (descuento != null && descuento is num) {
        return '${descuento.toInt()}';
      }
      return '0';
    } catch (e) {
      return '0';
    }
  }

  /// Obtener el precio original antes del descuento
  static double? getPrecioOriginal(model_proforma.DetalleProforma detalle) {
    try {
      final dynamic precioOriginal = (detalle as dynamic).precioOriginal;
      if (precioOriginal != null && precioOriginal is num) {
        return precioOriginal.toDouble();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Métodos para manejo de unidades gratis

  /// Verificar si un detalle tiene unidades gratis
  static bool tieneUnidadesGratis(model_proforma.DetalleProforma detalle) {
    try {
      final dynamic cantidadGratis = (detalle as dynamic).cantidadGratis;
      return cantidadGratis != null && cantidadGratis > 0;
    } catch (e) {
      return false;
    }
  }

  /// Obtener cantidad de unidades gratis
  static int getCantidadGratis(model_proforma.DetalleProforma detalle) {
    try {
      final dynamic cantidadGratis = (detalle as dynamic).cantidadGratis;
      if (cantidadGratis != null && cantidadGratis is num) {
        return cantidadGratis.toInt();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Obtener cantidad de unidades pagadas
  static int getCantidadPagada(model_proforma.DetalleProforma detalle) {
    try {
      final dynamic cantidadPagada = (detalle as dynamic).cantidadPagada;
      if (cantidadPagada != null && cantidadPagada is num) {
        return cantidadPagada.toInt();
      }
      // Si no hay campo específico, calcular restando gratis del total
      final int cantidadGratis = getCantidadGratis(detalle);
      return detalle.cantidad - cantidadGratis;
    } catch (e) {
      return detalle.cantidad;
    }
  }

  /// Extraer y obtener el número de documento de un cliente de proforma
  static String? extraerNumeroDocumentoCliente(dynamic cliente) {
    if (cliente == null) {
      return null;
    }

    String? numeroDocumento;
    if (cliente is Map<String, dynamic>) {
      numeroDocumento = cliente['numeroDocumento']?.toString();
    } else {
      try {
        numeroDocumento = (cliente.numeroDocumento as String?);
      } catch (_) {
        numeroDocumento = null;
      }
    }

    return numeroDocumento;
  }
}
