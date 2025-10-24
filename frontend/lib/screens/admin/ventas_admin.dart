import 'package:condorsmotors/models/paginacion.model.dart';
import 'package:condorsmotors/models/sucursal.model.dart';
import 'package:condorsmotors/models/ventas.model.dart';
import 'package:condorsmotors/repositories/index.repository.dart';
import 'package:condorsmotors/screens/admin/widgets/slide_sucursal.dart';
import 'package:condorsmotors/screens/admin/widgets/venta/venta_detalle_dialog.dart';
import 'package:condorsmotors/widgets/paginador.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class VentasAdminScreen extends StatefulWidget {
  const VentasAdminScreen({super.key});

  @override
  State<VentasAdminScreen> createState() => _VentasAdminScreenState();
}

class _VentasAdminScreenState extends State<VentasAdminScreen> {
  final NumberFormat _formatoMoneda = NumberFormat.currency(
    symbol: 'S/ ',
    decimalDigits: 2,
  );
  final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');

  // Variables para controlar el estado de operaciones asíncronas
  bool _isInitialized = false;

  // Estado local para sucursales
  String _errorMessage = '';
  List<Sucursal> _sucursales = [];
  Sucursal? _sucursalSeleccionada;
  bool _isSucursalesLoading = false;

  // Estado local para ventas
  List<Venta> _ventas = [];
  bool _isVentasLoading = false;
  String _ventasErrorMessage = '';

  // Estado local para búsqueda
  String _searchQuery = '';

  // Estado local para detalles de venta
  Venta? _ventaSeleccionada;

  // Estado local para paginación
  Paginacion _paginacion = Paginacion.emptyPagination;
  int _itemsPerPage = 10;
  String _orden = 'desc';
  String? _ordenarPor = 'fechaCreacion';

  // Repositorios
  final VentaRepository _ventaRepository = VentaRepository.instance;
  final SucursalRepository _sucursalRepository = SucursalRepository.instance;

  @override
  void initState() {
    super.initState();
    // La inicialización se realizará en didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Solo realizar la inicialización una vez
    if (!_isInitialized) {
      // Programar la carga de datos para después del primer frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Verificar si el widget sigue montado cuando se ejecute el callback
        if (mounted) {
          _cargarDatos();
        }
      });
      _isInitialized = true;
    }
  }

  void _cargarDatos() {
    // Solo inicializamos si no hay sucursales cargadas
    if (_sucursales.isEmpty && !_isSucursalesLoading) {
      _inicializar();
    }
  }

  /// Inicializa el provider cargando los datos necesarios
  void _inicializar() {
    _cargarSucursales();
  }

  /// Carga las sucursales disponibles
  Future<void> _cargarSucursales() async {
    _isSucursalesLoading = true;
    _errorMessage = '';
    setState(() {});

    try {
      debugPrint('Cargando sucursales desde el repositorio...');
      final data = await _sucursalRepository.getSucursales();

      debugPrint('Datos recibidos tipo: ${data.runtimeType}');
      debugPrint('Longitud de la lista: ${data.length}');
      if (data.isNotEmpty) {
        debugPrint('Primer elemento tipo: ${data.first.runtimeType}');
      }

      List<Sucursal> sucursalesParsed = [];

      // Procesamiento seguro de los datos
      for (var item in data) {
        try {
          // Si ya es un objeto Sucursal, lo usamos directamente
          sucursalesParsed.add(item);
        } catch (e) {
          debugPrint('Error al procesar sucursal: $e');
        }
      }

      // Ordenar por nombre
      sucursalesParsed.sort((a, b) => a.nombre.compareTo(b.nombre));

      debugPrint(
          'Sucursales cargadas correctamente: ${sucursalesParsed.length}');

      setState(() {
        _sucursales = sucursalesParsed;
        _isSucursalesLoading = false;
      });

      // Seleccionar la primera sucursal como predeterminada si hay sucursales
      if (_sucursales.isNotEmpty && _sucursalSeleccionada == null) {
        _sucursalSeleccionada = _sucursales.first;
        // Cargar ventas de la sucursal seleccionada por defecto
        _cargarVentas();
      }
    } catch (e) {
      debugPrint('Error al cargar sucursales: $e');
      setState(() {
        _isSucursalesLoading = false;
        _errorMessage = 'Error al cargar sucursales: $e';
      });
    }
  }

  /// Cambia la sucursal seleccionada
  void _cambiarSucursal(Sucursal sucursal) {
    setState(() {
      _sucursalSeleccionada = sucursal;
    });
    _cargarVentas();
  }

  /// Actualiza el término de búsqueda y recarga las ventas
  void _actualizarBusqueda(String query) {
    setState(() {
      _searchQuery = query;
    });
    _cargarVentas();
  }

  /// Actualiza los parámetros de ordenamiento y recarga las ventas
  void _actualizarOrdenamiento(String sortBy, String order) {
    setState(() {
      _ordenarPor = sortBy;
      _orden = order;
    });
    _cargarVentas();
  }

  /// Actualiza la información de paginación basándose en los resultados
  void _actualizarPaginacion(int totalItems) {
    final int totalPages = (totalItems / _itemsPerPage).ceil();
    final int currentPage = _paginacion.currentPage > totalPages
        ? totalPages
        : _paginacion.currentPage;

    setState(() {
      _paginacion = Paginacion(
        totalItems: totalItems,
        totalPages: totalPages > 0 ? totalPages : 1,
        currentPage: currentPage > 0 ? currentPage : 1,
        hasNext: currentPage < totalPages,
        hasPrev: currentPage > 1,
      );
    });
  }

  /// Carga las ventas según los filtros actuales
  Future<void> _cargarVentas() async {
    if (_sucursalSeleccionada == null) {
      setState(() {
        _ventasErrorMessage = 'Debe seleccionar una sucursal';
        _ventas = [];
      });
      return;
    }

    setState(() {
      _isVentasLoading = true;
      _ventasErrorMessage = '';
    });

    try {
      // Llamar al repositorio para obtener las ventas
      final response = await _ventaRepository.getVentas(
        sucursalId: _sucursalSeleccionada!.id,
        page: _paginacion.currentPage,
        pageSize: _itemsPerPage,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        sortBy: _ordenarPor,
        order: _orden,
        forceRefresh: true,
      );

      debugPrint('Respuesta recibida: ${response.keys.join(', ')}');

      // Procesar la respuesta para obtener List<Venta>
      if (response.containsKey('data') && response['data'] is List) {
        final rawList = response['data'] as List<dynamic>;
        final ventas = rawList
            .map((item) {
              try {
                // Si ya es Venta, devolverlo. Si es Map, intentar convertir.
                if (item is Venta) {
                  return item;
                } else if (item is Map<String, dynamic>) {
                  // Asumiendo que Venta.fromJson existe y maneja la estructura
                  return Venta.fromJson(item);
                } else {
                  debugPrint(
                      'Item inesperado en la lista de ventas: ${item.runtimeType}');
                  return null; // Marcar para filtrar
                }
              } catch (e) {
                debugPrint(
                    'Error al convertir venta Map a Venta: $e - Item: $item');
                return null; // Marcar para filtrar
              }
            })
            .whereType<
                Venta>() // Filtrar los nulos (errores o tipos inesperados)
            .toList();
        debugPrint('Ventas convertidas a List<Venta>: ${ventas.length}');

        setState(() {
          _ventas = ventas;
        });
      } else {
        setState(() {
          _ventas =
              []; // Limpiar si no hay datos o la clave 'data' no existe/no es lista
        });
        debugPrint(
            'No se encontraron datos de ventas en la respuesta o el formato es incorrecto.');
      }

      // Actualizar información de paginación si está disponible en la respuesta
      if (response.containsKey('pagination') &&
          response['pagination'] is Map<String, dynamic>) {
        // Extraer el mapa para depuración
        final Map<String, dynamic> paginationMap =
            Map<String, dynamic>.from(response['pagination'] as Map);
        debugPrint('Datos de paginación recibidos: $paginationMap');

        try {
          // Crear una instancia de Paginacion con valores predeterminados
          // en caso de que falten campos en el mapa
          final int totalItems = paginationMap['totalItems'] as int? ?? 0;
          final int totalPages = paginationMap['totalPages'] as int? ?? 1;
          final int currentPage = paginationMap['currentPage'] as int? ?? 1;

          setState(() {
            _paginacion = Paginacion(
              totalItems: totalItems,
              totalPages: totalPages > 0 ? totalPages : 1,
              currentPage: currentPage > 0 ? currentPage : 1,
              hasNext: currentPage < totalPages,
              hasPrev: currentPage > 1,
            );
          });

          debugPrint('Paginación convertida correctamente: $_paginacion');
        } catch (e) {
          debugPrint('Error al procesar paginación: $e');
          // Si falla, usar el método de respaldo
          if (paginationMap.containsKey('totalItems')) {
            final dynamic totalItems = paginationMap['totalItems'];
            _actualizarPaginacion(totalItems is int
                ? totalItems
                : int.tryParse(totalItems.toString()) ?? _ventas.length);
          } else {
            _actualizarPaginacion(_ventas.length);
          }
        }
      } else if (response.containsKey('total')) {
        final dynamic total = response['total'];
        _actualizarPaginacion(total is int
            ? total
            : int.tryParse(total.toString()) ?? _ventas.length);
      } else {
        _actualizarPaginacion(_ventas.length);
      }

      setState(() {
        _isVentasLoading = false;
      });

      debugPrint(
          'Ventas cargadas: ${_ventas.length}, tipo: ${_ventas.isNotEmpty ? _ventas.first.runtimeType : "N/A"}');
      debugPrint('Paginación final: $_paginacion');
    } catch (e) {
      debugPrint('Error al cargar ventas: $e');
      setState(() {
        _isVentasLoading = false;
        _ventasErrorMessage = 'Error al cargar ventas: $e';
      });
    }
  }

  /// Carga los detalles de una venta específica
  Future<Venta?> _cargarDetalleVenta(String id) async {
    if (_sucursalSeleccionada == null) {
      setState(() {
        _ventaSeleccionada = null;
      });
      return null;
    }

    try {
      debugPrint(
          'Cargando detalle de venta: $id para sucursal: ${_sucursalSeleccionada!.id}');

      final Venta? venta = await _ventaRepository.getVenta(
        id,
        sucursalId: _sucursalSeleccionada!.id,
        forceRefresh: true, // Forzar recarga para obtener datos actualizados
      );

      if (venta == null) {
        return null;
      }

      setState(() {
        _ventaSeleccionada = venta;
      });

      debugPrint('Venta cargada: ${venta.id}');
      return venta;
    } catch (e) {
      debugPrint('Error al cargar detalle de venta: $e');
      return null;
    }
  }

  /// Cambia la página actual de resultados
  Future<void> _cambiarPagina(int nuevaPagina) async {
    if (nuevaPagina < 1 || nuevaPagina > _paginacion.totalPages) {
      return;
    }
    setState(() {
      _paginacion = Paginacion(
        totalItems: _paginacion.totalItems,
        totalPages: _paginacion.totalPages,
        currentPage: nuevaPagina,
        hasNext: nuevaPagina < _paginacion.totalPages,
        hasPrev: nuevaPagina > 1,
      );
    });
    await _cargarVentas();
  }

  /// Cambia el número de elementos por página
  Future<void> _cambiarItemsPorPagina(int nuevoTamano) async {
    if (nuevoTamano < 1 || nuevoTamano > 200) {
      return;
    }
    setState(() {
      _itemsPerPage = nuevoTamano;
      _paginacion = Paginacion(
        totalItems: _paginacion.totalItems,
        totalPages: (_paginacion.totalItems / nuevoTamano).ceil(),
        currentPage: 1,
        hasNext: _paginacion.totalItems > nuevoTamano,
        hasPrev: false,
      );
    });
    await _cargarVentas();
  }

  /// Obtiene el color según el estado de una venta
  Color _getEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'COMPLETADA':
      case 'ACEPTADO-SUNAT':
      case 'ACEPTADO ANTE LA SUNAT':
        return Colors.green;
      case 'ANULADA':
        return Colors.red;
      case 'CANCELADA':
        return Colors.orange.shade900;
      case 'DECLARADA':
        return Colors.blue;
      case 'PENDIENTE':
      default:
        return Colors.orange;
    }
  }

  /// Declara una venta a SUNAT
  Future<bool> _declararVenta(
    String ventaId, {
    bool enviarCliente = false,
    VoidCallback? onSuccess,
    Function(String)? onError,
  }) async {
    setState(() {
      _isVentasLoading = true;
    });

    try {
      // Necesitamos la sucursal ID actual
      if (_sucursalSeleccionada == null) {
        const errorMsg = 'No hay una sucursal seleccionada';
        if (onError != null) {
          onError(errorMsg);
        } else {
          // Error will be handled by callback
        }
        throw Exception(errorMsg);
      }

      // Llamar al repositorio para declarar la venta
      final result = await _ventaRepository.declararVenta(
        ventaId,
        sucursalId: _sucursalSeleccionada!.id,
        enviarCliente: enviarCliente,
      );

      // Verificar si la respuesta es exitosa
      if (result['status'] != 'success') {
        final errorMsg = result['message'] ?? 'Error al declarar la venta';
        if (onError != null) {
          onError(errorMsg);
        } else {
          // Error will be handled by callback
        }
        return false;
      }

      // Forzar recarga de los datos para obtener el estado actualizado
      await _cargarVentas();

      // Si teníamos detalles de esta venta seleccionados, actualizar
      if (_ventaSeleccionada != null &&
          _ventaSeleccionada!.id.toString() == ventaId) {
        await _cargarDetalleVenta(ventaId);
      }

      // Llamar al callback de éxito si existe
      if (onSuccess != null) {
        onSuccess();
      }
      // Success will be handled by callback

      return true;
    } catch (e) {
      final errorMsg = 'Error al declarar venta: $e';
      debugPrint(errorMsg);
      setState(() {
        _ventasErrorMessage = errorMsg;
      });

      // Llamar al callback de error si existe
      if (onError != null) {
        onError(errorMsg);
      }
      // Error will be handled by callback

      return false;
    } finally {
      setState(() {
        _isVentasLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Panel izquierdo: Contenido principal (70%)
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header optimizado
                _buildHeader(context),
                // Contenido de ventas optimizado
                Expanded(
                  child: _buildVentasContent(context),
                ),
              ],
            ),
          ),

          // Panel derecho: Selector de sucursales (30%) - Optimizado
          Container(
            width: 350,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(
                left: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mensaje de error para sucursales
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),

                // Selector de sucursales
                Expanded(
                  child: SlideSucursal(
                    sucursales: _sucursales,
                    sucursalSeleccionada: _sucursalSeleccionada,
                    onSucursalSelected: _cambiarSucursal,
                    onRecargarSucursales: _cargarSucursales,
                    isLoading: _isSucursalesLoading,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const FaIcon(
            FontAwesomeIcons.fileInvoiceDollar,
            color: Color(0xFFE31E24),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            _sucursalSeleccionada?.nombre ?? 'Todas las sucursales',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _buildSearchField(),
          ),
          const SizedBox(width: 16),
          // Selector de ordenamiento
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: '${_ordenarPor ?? 'fechaCreacion'}_$_orden',
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                isDense: true,
                items: const [
                  DropdownMenuItem(
                    value: 'fechaCreacion_desc',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(FontAwesomeIcons.clockRotateLeft,
                            size: 12, color: Colors.white70),
                        SizedBox(width: 8),
                        Text('Más recientes'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'fechaCreacion_asc',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(FontAwesomeIcons.clock,
                            size: 12, color: Colors.white70),
                        SizedBox(width: 8),
                        Text('Más antiguas'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'totalVenta_desc',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(FontAwesomeIcons.arrowDownWideShort,
                            size: 12, color: Colors.white70),
                        SizedBox(width: 8),
                        Text('Mayor valor'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'totalVenta_asc',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(FontAwesomeIcons.arrowUpWideShort,
                            size: 12, color: Colors.white70),
                        SizedBox(width: 8),
                        Text('Menor valor'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'declarada_desc',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(FontAwesomeIcons.circleCheck,
                            size: 12, color: Colors.white70),
                        SizedBox(width: 8),
                        Text('Declaradas primero'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'anulada_desc',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(FontAwesomeIcons.ban,
                            size: 12, color: Colors.white70),
                        SizedBox(width: 8),
                        Text('Anuladas primero'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'nombreEmpleado_asc',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(FontAwesomeIcons.user,
                            size: 12, color: Colors.white70),
                        SizedBox(width: 8),
                        Text('Por empleado'),
                      ],
                    ),
                  ),
                ],
                onChanged: (String? nuevoOrdenamiento) {
                  if (nuevoOrdenamiento != null) {
                    final partes = nuevoOrdenamiento.split('_');
                    final sortBy = partes[0];
                    final order = partes[1];
                    _actualizarOrdenamiento(sortBy, order);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Botón de recargar ventas
          ElevatedButton.icon(
            icon: _isVentasLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const FaIcon(
                    FontAwesomeIcons.arrowsRotate,
                    size: 16,
                    color: Colors.white,
                  ),
            label: Text(
              _isVentasLoading ? 'Recargando...' : 'Recargar',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D2D2D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onPressed: _isVentasLoading
                ? null
                : () async {
                    final currentContext = context;
                    final scaffoldMessenger =
                        ScaffoldMessenger.of(currentContext);
                    await _cargarVentas();
                    // Mostrar mensaje de éxito o error
                    if (!mounted) {
                      return;
                    }

                    if (_ventasErrorMessage.isNotEmpty) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(_ventasErrorMessage),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Ventas recargadas exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
            label: const Text('Nueva Venta'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFFE31E24),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onPressed: () {
              // Implementar creación de nueva venta
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función en desarrollo'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          hintText: 'Buscar por cliente, número de documento o serie...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon:
                      const Icon(Icons.close, color: Colors.white70, size: 18),
                  onPressed: () {
                    // Limpiar búsqueda
                    _actualizarBusqueda('');
                  },
                )
              : null,
        ),
        onChanged: (value) {
          // Actualizar búsqueda después de un pequeño retraso
          // Verificar que el widget esté montado antes de continuar
          if (mounted) {
            Future.delayed(const Duration(milliseconds: 500), () {
              // Verificar nuevamente que el widget está montado antes de actualizar
              if (mounted) {
                _actualizarBusqueda(value);
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildVentasContent(BuildContext context) {
    if (_isVentasLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_ventasErrorMessage.isNotEmpty) {
      return Center(
        child: _buildEmptyState(
          icon: FontAwesomeIcons.triangleExclamation,
          title: 'Error al cargar ventas',
          description: _ventasErrorMessage,
          actionText: 'Intentar de nuevo',
          onAction: _cargarVentas,
        ),
      );
    }

    if (_ventas.isEmpty) {
      String mensajeVacio = 'Aún no hay ventas registradas para esta sucursal';
      if (_searchQuery.isNotEmpty) {
        mensajeVacio =
            'No se encontraron ventas con el término "$_searchQuery"';
      }

      return Center(
        child: _buildEmptyState(
          icon: FontAwesomeIcons.fileInvoiceDollar,
          title: 'No hay ventas registradas',
          description: mensajeVacio,
          actionText: 'Actualizar',
          onAction: _cargarVentas,
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _ventas.length,
            itemBuilder: (context, index) {
              final venta = _ventas[index];
              return _buildVentaItem(context, venta);
            },
          ),
        ),
        // Paginador al final de la columna
        if (_paginacion.totalPages > 0)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RepaintBoundary(
                  key: ValueKey('ventas_paginador_${_paginacion.currentPage}'),
                  child: Paginador(
                    paginacion: _paginacion,
                    backgroundColor: const Color(0xFF2D2D2D),
                    textColor: Colors.white,
                    accentColor: const Color(0xFFE31E24),
                    radius: 8.0,
                    onPageChanged: _cambiarPagina,
                    onPageSizeChanged: _cambiarItemsPorPagina,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FaIcon(
          icon,
          size: 48,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE31E24),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
          child: Text(actionText),
        ),
      ],
    );
  }

  Widget _buildVentaItem(BuildContext context, Venta venta) {
    final String id = venta.id.toString();
    final String serie = venta.serieDocumento;
    final String numero = venta.numeroDocumento;
    final DateTime fecha = venta.fechaCreacion;
    final String horaEmision = venta.horaEmision;
    final double total = venta.calcularTotal();

    final String empleado = venta.empleadoDetalle != null
        ? venta.empleadoDetalle!.getNombreCompleto()
        : 'No especificado';

    final bool tienePdf = venta.documentoFacturacion?.linkPdf != null;
    final String? pdfLink = venta.documentoFacturacion?.linkPdf;

    final bool declarada = venta.declarada;
    final bool anulada = venta.anulada;

    final String estado = venta.estado.toText();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          if (mounted) {
            _mostrarDetalleVenta(context, id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getEstadoColor(estado).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: FaIcon(
                        tienePdf
                            ? FontAwesomeIcons.filePdf
                            : FontAwesomeIcons.fileInvoiceDollar,
                        color: _getEstadoColor(estado),
                      ),
                    ),
                  ),
                  if (declarada || anulada)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: anulada
                              ? Colors.red
                              : (declarada ? Colors.green : Colors.transparent),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serie.isNotEmpty && numero.isNotEmpty
                          ? '$serie-$numero'
                          : 'Venta #$id',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fecha: ${_formatoFecha.format(fecha)}${horaEmision.isNotEmpty ? ' $horaEmision' : ''}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Atendido por: $empleado',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatoMoneda.format(total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getEstadoColor(estado).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          estado,
                          style: TextStyle(
                            color: _getEstadoColor(estado),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (tienePdf)
                        IconButton(
                          icon: const FaIcon(
                            FontAwesomeIcons.fileArrowDown,
                            size: 14,
                            color: Colors.blue,
                          ),
                          tooltip: 'Descargar PDF',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          onPressed: () {
                            if (mounted && pdfLink != null) {
                              _abrirPdf(pdfLink);
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarDetalleVenta(BuildContext context, String id) async {
    final ValueNotifier<Venta?> ventaNotifier = ValueNotifier<Venta?>(null);
    final ValueNotifier<bool> isLoadingFullData = ValueNotifier<bool>(true);

    Venta? ventaBasica;
    try {
      ventaBasica = _ventas.firstWhere((v) => v.id.toString() == id);
      ventaNotifier.value = ventaBasica;
      isLoadingFullData.value = true;
    } catch (e) {
      debugPrint("Venta básica no encontrada en la lista: $id");
    }

    Future<void> declararVenta(String ventaId) async {
      if (!mounted) {
        return;
      }

      isLoadingFullData.value = true;

      await _declararVenta(
        ventaId,
        onSuccess: () async {
          if (!mounted) {
            return;
          }

          final ventaActualizada = await _cargarDetalleVenta(ventaId);

          if (!mounted) {
            return;
          }

          ventaNotifier.value = ventaActualizada;
          isLoadingFullData.value = false;
        },
        onError: (errorMsg) {
          if (!mounted) {
            return;
          }

          isLoadingFullData.value = false;
        },
      );
    }

    if (!mounted) {
      return;
    }
    showDialog(
      context: context,
      builder: (_) => ValueListenableBuilder<Venta?>(
        valueListenable: ventaNotifier,
        builder: (dialogContext, currentVenta, child) {
          return ValueListenableBuilder<bool>(
            valueListenable: isLoadingFullData,
            builder: (dialogContextLoading, isLoading, _) {
              return VentaDetalleDialog(
                venta: currentVenta,
                isLoadingFullData: isLoading,
                onDeclararPressed: declararVenta,
              );
            },
          );
        },
      ),
    );

    try {
      final ventaCompleta = await _cargarDetalleVenta(id);

      if (!mounted) {
        return;
      }

      ventaNotifier.value = ventaCompleta;

      isLoadingFullData.value = false;
    } catch (e) {
      if (!mounted) {
        return;
      }

      debugPrint('Error al cargar los detalles de la venta: ${e.toString()}');
      isLoadingFullData.value = false;
    }
  }

  Future<void> _abrirPdf(String url) async {
    if (!mounted) {
      return;
    }

    // Implementar apertura de PDF
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abriendo PDF: $url'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
