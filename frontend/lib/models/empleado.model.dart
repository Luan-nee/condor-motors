class Empleado {
  final String id;
  final String nombre;
  final String apellidos;
  final String? ubicacionFoto;
  final String? dni;
  final String? horaInicioJornada;
  final String? horaFinJornada;
  final String? fechaContratacion;
  final double? sueldo;
  final String? fechaRegistro;
  final String? sucursalId;
  final String? sucursalNombre;
  final bool sucursalCentral;
  final bool activo;
  final String? celular;
  final String? cuentaEmpleadoId;

  Empleado({
    required this.id,
    required this.nombre,
    required this.apellidos,
    this.ubicacionFoto,
    this.dni,
    this.horaInicioJornada,
    this.horaFinJornada,
    this.fechaContratacion,
    this.sueldo,
    this.fechaRegistro,
    this.sucursalId,
    this.sucursalNombre,
    this.sucursalCentral = false,
    this.activo = true,
    this.celular,
    this.cuentaEmpleadoId,
  });

  /// Crea una instancia de Empleado a partir de un mapa JSON
  factory Empleado.fromJson(Map<String, dynamic> json) {
    // Extraer información de sucursal si está disponible
    String? sucursalId;
    String? sucursalNombre;
    bool sucursalCentral = false;
    
    if (json['sucursal'] is Map<String, dynamic>) {
      final Map<String, dynamic> sucursal = json['sucursal'] as Map<String, dynamic>;
      sucursalId = sucursal['id']?.toString();
      sucursalNombre = sucursal['nombre']?.toString();
      sucursalCentral = sucursal['sucursalCentral'] == true;
    } else {
      // Mantener compatibilidad con el formato anterior
      sucursalId = json['sucursalId']?.toString();
    }
    
    // Extraer ID de cuenta de empleado si está disponible
    String? cuentaEmpleadoId;
    if (json['cuentaEmpleado'] is Map<String, dynamic>) {
      final Map<String, dynamic> cuenta = json['cuentaEmpleado'] as Map<String, dynamic>;
      cuentaEmpleadoId = cuenta['id']?.toString();
    }

    return Empleado(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      apellidos: json['apellidos'] ?? '',
      ubicacionFoto: json['ubicacionFoto'] ?? json['pathFoto'],
      dni: json['dni'],
      horaInicioJornada: json['horaInicioJornada'],
      horaFinJornada: json['horaFinJornada'],
      fechaContratacion: json['fechaContratacion'],
      sueldo: json['sueldo'] != null ? double.parse(json['sueldo'].toString()) : null,
      fechaRegistro: json['fechaRegistro'],
      sucursalId: sucursalId,
      sucursalNombre: sucursalNombre,
      sucursalCentral: sucursalCentral,
      activo: json['activo'] ?? true,
      celular: json['celular'],
      cuentaEmpleadoId: cuentaEmpleadoId,
    );
  }

  /// Convierte el modelo a un mapa JSON
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nombre': nombre,
      'apellidos': apellidos,
      'ubicacionFoto': ubicacionFoto,
      'dni': dni,
      'horaInicioJornada': horaInicioJornada,
      'horaFinJornada': horaFinJornada,
      'fechaContratacion': fechaContratacion,
      'sueldo': sueldo,
      'sucursalId': sucursalId,
      'activo': activo,
      'celular': celular,
    };
  }
  
  /// Retorna una copia del empleado con propiedades modificadas
  Empleado copyWith({
    String? id,
    String? nombre,
    String? apellidos,
    String? ubicacionFoto,
    String? dni,
    String? horaInicioJornada,
    String? horaFinJornada,
    String? fechaContratacion,
    double? sueldo,
    String? fechaRegistro,
    String? sucursalId,
    String? sucursalNombre,
    bool? sucursalCentral,
    bool? activo,
    String? celular,
    String? cuentaEmpleadoId,
  }) {
    return Empleado(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
      ubicacionFoto: ubicacionFoto ?? this.ubicacionFoto,
      dni: dni ?? this.dni,
      horaInicioJornada: horaInicioJornada ?? this.horaInicioJornada,
      horaFinJornada: horaFinJornada ?? this.horaFinJornada,
      fechaContratacion: fechaContratacion ?? this.fechaContratacion,
      sueldo: sueldo ?? this.sueldo,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      sucursalId: sucursalId ?? this.sucursalId,
      sucursalNombre: sucursalNombre ?? this.sucursalNombre,
      sucursalCentral: sucursalCentral ?? this.sucursalCentral,
      activo: activo ?? this.activo,
      celular: celular ?? this.celular,
      cuentaEmpleadoId: cuentaEmpleadoId ?? this.cuentaEmpleadoId,
    );
  }
  
  /// Retorna el nombre completo del empleado
  String get nombreCompleto => '$nombre $apellidos';

  @override
  String toString() {
    return 'Empleado{id: $id, nombre: $nombre $apellidos, activo: $activo}';
  }
}

/// Modelo para la respuesta paginada de empleados
class EmpleadosPaginados {
  final List<Empleado> empleados;
  final Map<String, dynamic> paginacion;

  EmpleadosPaginados({
    required this.empleados,
    required this.paginacion,
  });

  /// Crea una instancia de EmpleadosPaginados a partir de una respuesta JSON
  factory EmpleadosPaginados.fromJson(Map<String, dynamic> json) {
    List<dynamic> items = <dynamic>[];
    
    if (json['data'] is List) {
      items = json['data'];
    } else if (json['data'] is Map && json['data']['data'] is List) {
      items = json['data']['data'];
    }
    
    final List<Empleado> empleados = items
        .map((item) => Empleado.fromJson(item as Map<String, dynamic>))
        .toList();
    
    Map<String, dynamic> paginacion = <String, dynamic>{};
    if (json['pagination'] is Map) {
      paginacion = json['pagination'] as Map<String, dynamic>;
    } else if (json['data'] is Map && json['data']['pagination'] is Map) {
      paginacion = json['data']['pagination'] as Map<String, dynamic>;
    }
    
    return EmpleadosPaginados(
      empleados: empleados,
      paginacion: paginacion,
    );
  }
}

/// Extensión con métodos útiles para listas de empleados
extension EmpleadoListExtension on List<Empleado> {
  /// Filtra los empleados activos
  List<Empleado> get activos => where((Empleado e) => e.activo).toList();
  
  /// Filtra por sucursal
  List<Empleado> porSucursal(String sucursalId) => 
      where((Empleado e) => e.sucursalId == sucursalId).toList();
      
  /// Busca empleados por término en nombre o apellidos
  List<Empleado> buscar(String termino) {
    final String terminoLower = termino.toLowerCase();
    return where((Empleado e) => 
      e.nombre.toLowerCase().contains(terminoLower) || 
      e.apellidos.toLowerCase().contains(terminoLower) ||
      e.dni?.toLowerCase() == terminoLower
    ).toList();
  }
}
