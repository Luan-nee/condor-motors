import 'package:flutter/foundation.dart';

/// Representa un movimiento de inventario entre sucursales
class Movimiento {
  final int id;
  final String estado;
  final String nombreSucursalOrigen;
  final String nombreSucursalDestino;
  final bool modificable;
  final DateTime? salidaOrigen;
  final DateTime? llegadaDestino;
  
  /// Detalles adicionales que pueden estar disponibles al cargar un movimiento específico
  final List<DetalleProducto>? productos;
  final String? observaciones;
  final String? solicitante;

  Movimiento({
    required this.id,
    required this.estado,
    required this.nombreSucursalOrigen,
    required this.nombreSucursalDestino,
    required this.modificable,
    this.salidaOrigen,
    this.llegadaDestino,
    this.productos,
    this.observaciones,
    this.solicitante,
  });

  /// Crea una instancia de Movimiento desde un mapa JSON
  factory Movimiento.fromJson(Map<String, dynamic> json) {
    debugPrint('🔄 [Movimiento.fromJson] Iniciando conversión de mapa a Movimiento');
    // Parsear fechas con manejo de nulos
    DateTime? parseFecha(fecha) {
      if (fecha == null) {
        return null;
      }
      try {
        return DateTime.parse(fecha.toString());
      } catch (e) {
        debugPrint('❌ [Movimiento.fromJson] Error al parsear fecha: $e');
        return null;
      }
    }

    // Parsear productos si existen
    List<DetalleProducto>? productos;
    
    // Primero revisamos si hay productos en el formato tradicional
    if (json['productos'] != null && json['productos'] is List) {
      try {
        final List productosLista = json['productos'] as List;
        debugPrint('📦 [Movimiento.fromJson] Procesando ${productosLista.length} productos...');
        
        productos = <DetalleProducto>[];
        for (int i = 0; i < productosLista.length; i++) {
          try {
            final Map<String, dynamic> item = productosLista[i] as Map<String, dynamic>;
            productos.add(DetalleProducto.fromJson(item));
          } catch (e) {
            debugPrint('❌ [Movimiento.fromJson] Error al parsear producto[$i]: $e');
          }
        }
        
        debugPrint('✅ [Movimiento.fromJson] ${productos.length} productos parseados correctamente');
      } catch (e) {
        debugPrint('❌ [Movimiento.fromJson] Error al parsear productos: $e');
        // Intentamos recuperarnos del error
        productos = <DetalleProducto>[];
      }
    } 
    // Si no, revisamos si hay itemsVenta (formato del detalle de movimiento)
    else if (json['itemsVenta'] != null && json['itemsVenta'] is List) {
      try {
        final List items = json['itemsVenta'] as List;
        debugPrint('🔍 [Movimiento.fromJson] Parseando ${items.length} itemsVenta...');
        
        productos = <DetalleProducto>[];
        for (int i = 0; i < items.length; i++) {
          try {
            final Map<String, dynamic> item = items[i] as Map<String, dynamic>;
            debugPrint('📦 [Movimiento.fromJson] Procesando item $i: ${item.keys.join(', ')}');
            productos.add(DetalleProducto.fromItemVenta(item));
          } catch (e) {
            debugPrint('❌ [Movimiento.fromJson] Error al parsear itemVenta[$i]: $e');
          }
        }
        
        debugPrint('✅ [Movimiento.fromJson] ${productos.length} productos parseados desde "itemsVenta"');
      } catch (e) {
        debugPrint('❌ [Movimiento.fromJson] Error al parsear itemsVenta: $e');
        productos = <DetalleProducto>[];
      }
    } else {
      debugPrint('⚠️ [Movimiento.fromJson] No se encontraron productos ni itemsVenta en el JSON');
      productos = <DetalleProducto>[];
    }

    // Manejo seguro de campos requeridos
    int id;
    try {
      // Si no hay ID (como en el caso del detalle que muestra), usamos 0
      if (json['id'] == null) {
        debugPrint('⚠️ [Movimiento.fromJson] ID no encontrado en los datos, usando 0');
        id = 0;
      } else {
        id = json['id'] is int ? json['id'] : int.parse(json['id'].toString());
      }
    } catch (e) {
      debugPrint('❌ [Movimiento.fromJson] Error al parsear id, usando valor por defecto: $e');
      id = 0; // Valor por defecto si hay error
    }

    final String estado = (json['estado'] ?? 'PENDIENTE').toString();
    final String origen = (json['nombreSucursalOrigen'] ?? json['sucursal_origen'] ?? 'N/A').toString();
    final String destino = (json['nombreSucursalDestino'] ?? json['sucursal_destino'] ?? 'N/A').toString();
    final bool modificable = json['modificable'] == true;

    debugPrint('✅ [Movimiento.fromJson] Conversión completada. ID: $id, Estado: $estado, '
        'Origen: $origen, Destino: $destino, Productos: ${productos.length}');

    return Movimiento(
      id: id,
      estado: estado,
      nombreSucursalOrigen: origen,
      nombreSucursalDestino: destino,
      modificable: modificable,
      salidaOrigen: parseFecha(json['salidaOrigen'] ?? json['fecha_creacion']),
      llegadaDestino: parseFecha(json['llegadaDestino']),
      productos: productos,
      observaciones: json['observaciones']?.toString(),
      solicitante: json['solicitante']?.toString(),
    );
  }

  /// Convierte la instancia a un mapa JSON
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'estado': estado,
      'nombreSucursalOrigen': nombreSucursalOrigen,
      'nombreSucursalDestino': nombreSucursalDestino,
      'modificable': modificable,
      'salidaOrigen': salidaOrigen?.toIso8601String(),
      'llegadaDestino': llegadaDestino?.toIso8601String(),
      if (productos != null)
        'productos': productos!.map((DetalleProducto producto) => producto.toJson()).toList(),
      if (observaciones != null) 'observaciones': observaciones,
      if (solicitante != null) 'solicitante': solicitante,
    };
  }

  /// Crea una copia del objeto con cambios específicos
  Movimiento copyWith({
    int? id,
    String? estado,
    String? nombreSucursalOrigen,
    String? nombreSucursalDestino,
    bool? modificable,
    DateTime? salidaOrigen,
    DateTime? llegadaDestino,
    List<DetalleProducto>? productos,
    String? observaciones,
    String? solicitante,
  }) {
    return Movimiento(
      id: id ?? this.id,
      estado: estado ?? this.estado,
      nombreSucursalOrigen: nombreSucursalOrigen ?? this.nombreSucursalOrigen,
      nombreSucursalDestino: nombreSucursalDestino ?? this.nombreSucursalDestino,
      modificable: modificable ?? this.modificable,
      salidaOrigen: salidaOrigen ?? this.salidaOrigen,
      llegadaDestino: llegadaDestino ?? this.llegadaDestino,
      productos: productos ?? this.productos,
      observaciones: observaciones ?? this.observaciones,
      solicitante: solicitante ?? this.solicitante,
    );
  }

  @override
  String toString() {
    return 'Movimiento{id: $id, estado: $estado, origen: $nombreSucursalOrigen, destino: $nombreSucursalDestino}';
  }
}

/// Representa un producto incluido en un movimiento de inventario
class DetalleProducto {
  final int id;
  final String nombre;
  final String? codigo;
  final int cantidad;

  DetalleProducto({
    required this.id,
    required this.nombre,
    this.codigo,
    required this.cantidad,
  });

  /// Crea una instancia de DetalleProducto desde un mapa JSON (formato tradicional)
  factory DetalleProducto.fromJson(Map<String, dynamic> json) {
    // Manejo seguro de campos requeridos
    int id;
    try {
      id = json['id'] is int ? json['id'] : int.parse(json['id'].toString());
    } catch (e) {
      debugPrint('Error al parsear id de producto, usando valor por defecto: $e');
      id = 0; // Valor por defecto si hay error
    }

    int cantidad;
    try {
      cantidad = json['cantidad'] is int ? json['cantidad'] : int.parse(json['cantidad'].toString());
    } catch (e) {
      debugPrint('Error al parsear cantidad, usando valor por defecto: $e');
      cantidad = 0; // Valor por defecto si hay error
    }

    return DetalleProducto(
      id: id,
      nombre: json['nombre']?.toString() ?? 'Sin nombre',
      codigo: json['codigo']?.toString(),
      cantidad: cantidad,
    );
  }

  /// Crea una instancia de DetalleProducto desde un mapa JSON del formato itemsVenta
  factory DetalleProducto.fromItemVenta(Map<String, dynamic> json) {
    debugPrint('🔄 Procesando itemVenta: ${json.keys.join(', ')}');
    
    // Extraer cantidad con manejo de errores
    int cantidad;
    try {
      if (json['cantidad'] == null) {
        debugPrint('⚠️ Cantidad es nula, usando 0');
        cantidad = 0;
      } else if (json['cantidad'] is int) {
        cantidad = json['cantidad'] as int;
      } else {
        cantidad = int.parse(json['cantidad'].toString());
      }
    } catch (e) {
      debugPrint('❌ Error al parsear cantidad de itemVenta, usando valor por defecto: $e');
      cantidad = 0; // Valor por defecto si hay error
    }
    
    // Extraer nombre con manejo de errores
    String nombre;
    if (json['nombreProducto'] != null) {
      nombre = json['nombreProducto'].toString();
    } else if (json['nombre'] != null) {
      nombre = json['nombre'].toString();
    } else if (json['producto_nombre'] != null) {
      nombre = json['producto_nombre'].toString();
    } else {
      nombre = 'Sin nombre';
      debugPrint('⚠️ No se encontró un nombre para el producto');
    }
    
    // Intentar extraer código si existe
    String? codigo;
    if (json['codigo'] != null) {
      codigo = json['codigo'].toString();
    } else if (json['codigoProducto'] != null) {
      codigo = json['codigoProducto'].toString();
    } else if (json['producto_codigo'] != null) {
      codigo = json['producto_codigo'].toString();
    }
    
    // Intentar extraer ID si existe
    int id = 0;
    if (json['productoId'] != null) {
      try {
        id = json['productoId'] is int ? json['productoId'] : int.parse(json['productoId'].toString());
      } catch (e) {
        debugPrint('⚠️ Error al parsear productoId: $e');
      }
    } else if (json['producto_id'] != null) {
      try {
        id = json['producto_id'] is int ? json['producto_id'] : int.parse(json['producto_id'].toString());
      } catch (e) {
        debugPrint('⚠️ Error al parsear producto_id: $e');
      }
    }

    debugPrint('✅ ItemVenta procesado: $nombre (Cantidad: $cantidad)');
    return DetalleProducto(
      id: id,
      nombre: nombre,
      codigo: codigo,
      cantidad: cantidad,
    );
  }

  /// Convierte la instancia a un mapa JSON
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nombre': nombre,
      if (codigo != null) 'codigo': codigo,
      'cantidad': cantidad,
    };
  }

  @override
  String toString() {
    return 'DetalleProducto{id: $id, nombre: $nombre, cantidad: $cantidad}';
  }
}
