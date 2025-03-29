import 'package:condorsmotors/main.dart' show api;
import 'package:condorsmotors/models/proforma.model.dart';
import 'package:condorsmotors/screens/computer/proforma_list.dart';
import 'package:condorsmotors/screens/computer/widgets/proforma_widget.dart';
import 'package:condorsmotors/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Pantalla principal para gestionar proformas en la versión de computadora
class ProformaComputerScreen extends StatefulWidget {
  final int? sucursalId;
  final String nombreSucursal;

  const ProformaComputerScreen({
    super.key, 
    this.sucursalId,
    this.nombreSucursal = 'Sucursal',
  });

  @override
  ProformaComputerScreenState createState() => ProformaComputerScreenState();
}

class ProformaComputerScreenState extends State<ProformaComputerScreen> {
  List<Proforma> _proformas = [];
  Proforma? _selectedProforma;
  bool _isLoading = false;
  String? _errorMessage;
  Paginacion? _paginacion;
  int _currentPage = 1;
  
  @override
  void initState() {
    super.initState();
    _loadProformas();
  }
  
  /// Carga las proformas desde la API
  Future<void> _loadProformas() async {
    if (_isLoading) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Obtener el ID de sucursal, primero del widget y si no está disponible, del usuario
      String? sucursalId;
      
      if (widget.sucursalId != null) {
        // Usar el sucursalId pasado como parámetro
        sucursalId = widget.sucursalId.toString();
      } else {
        // Obtener el ID de sucursal del usuario
        final userData = await api.authService.getUserData();
        if (userData == null || !userData.containsKey('sucursalId')) {
          setState(() {
            _errorMessage = 'No se pudo determinar la sucursal del usuario';
            _isLoading = false;
          });
          return;
        }
        sucursalId = userData['sucursalId'].toString();
      }
      
      final response = await api.proformas.getProformasVenta(
        sucursalId: sucursalId,
        page: _currentPage,
        pageSize: 10,
      );
      
      if (response.isNotEmpty) {
        final proformas = api.proformas.parseProformasVenta(response);
        
        // Extraer información de paginación
        final Map<String, dynamic>? paginacionJson = response['pagination'];
        Paginacion? paginacionLocal;
        
        // Crear un objeto Paginacion compatible con ProformaListWidget
        if (paginacionJson != null) {
          final totalItems = paginacionJson['total'] as int? ?? 0;
          final currentPage = paginacionJson['page'] as int? ?? 1;
          final totalPages = paginacionJson['totalPages'] as int? ?? 1;
          final itemsPerPage = paginacionJson['pageSize'] as int? ?? 10;
          
          paginacionLocal = Paginacion(
            totalItems: totalItems,
            currentPage: currentPage,
            totalPages: totalPages,
            itemsPerPage: itemsPerPage,
          );
        }
        
        if (mounted) {
          setState(() {
            _proformas = proformas;
            _paginacion = paginacionLocal;
            _isLoading = false;
            
            // Si la proforma seleccionada ya no está en la lista, deseleccionarla
            if (_selectedProforma != null && 
                !_proformas.any((p) => p.id == _selectedProforma!.id)) {
              _selectedProforma = null;
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'No se pudo cargar las proformas';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      Logger.error('Error al cargar proformas: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  /// Cambia la página actual y recarga las proformas
  void _handlePageChange(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadProformas();
  }
  
  /// Maneja la selección de una proforma
  void _handleProformaSelected(Proforma proforma) {
    setState(() {
      _selectedProforma = proforma;
    });
  }
  
  /// Maneja la conversión de una proforma a venta
  void _handleConvertToSale(Proforma proforma) {
    // Esta función se pasa al widget de lista y se ejecuta cuando
    // una proforma se convierte exitosamente a venta
    _loadProformas(); // Recargar la lista
    
    // Si la proforma convertida es la seleccionada, deseleccionarla
    if (_selectedProforma != null && _selectedProforma!.id == proforma.id) {
      setState(() {
        _selectedProforma = null;
      });
    }
  }
  
  /// Maneja la eliminación de una proforma
  Future<void> _handleDeleteProforma(Proforma proforma) async {
    // Mostrar diálogo de confirmación
    final bool confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 10),
            Text(
              'Eliminar proforma',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          '¿Está seguro que desea eliminar la proforma #${proforma.id}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirmado) {
      try {
        // Obtener el ID de sucursal, primero del widget y si no está disponible, del usuario
        String? sucursalId;
        
        if (widget.sucursalId != null) {
          // Usar el sucursalId pasado como parámetro
          sucursalId = widget.sucursalId.toString();
        } else {
          // Obtener el ID de sucursal del usuario
          final userData = await api.authService.getUserData();
          if (userData == null || !userData.containsKey('sucursalId')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No se pudo determinar la sucursal del usuario'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
          sucursalId = userData['sucursalId'].toString();
        }
        
        final response = await api.proformas.deleteProformaVenta(
          sucursalId: sucursalId,
          proformaId: proforma.id,
        );
        
        if (mounted) {
          if (response.containsKey('status') && response['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Proforma eliminada correctamente'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Recargar proformas
            _loadProformas();
            
            // Si la proforma eliminada es la seleccionada, deseleccionarla
            if (_selectedProforma != null && _selectedProforma!.id == proforma.id) {
              setState(() {
                _selectedProforma = null;
              });
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al eliminar proforma: ${response['message'] ?? 'Error desconocido'}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        Logger.error('Error al eliminar proforma: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar proforma: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: Text('Gestión de Proformas - ${widget.nombreSucursal}'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProformas,
            tooltip: 'Recargar',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implementar creación de nueva proforma
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Crear nueva proforma (pendiente)'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            tooltip: 'Nueva proforma',
          ),
        ],
      ),
      body: _errorMessage != null
          ? _buildErrorWidget()
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lista de proformas (1/3 del ancho)
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.35,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ProformaListWidget(
                      proformas: _proformas,
                      onProformaSelected: _handleProformaSelected,
                      onConvertToSale: _handleConvertToSale,
                      onDeleteProforma: _handleDeleteProforma,
                      onRefresh: _loadProformas,
                      isLoading: _isLoading,
                      emptyMessage: 'No hay proformas disponibles',
                      paginacion: _paginacion,
                      onPageChanged: _handlePageChange,
                    ),
                  ),
                ),
                
                // Línea vertical divisoria
                Container(
                  width: 1,
                  height: double.infinity,
                  color: const Color(0xFF2D2D2D),
                ),
                
                // Detalle de proforma seleccionada (2/3 del ancho)
                Expanded(
                  child: _selectedProforma != null
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ProformaWidget(
                            proforma: _selectedProforma!,
                            onConvert: _handleConvertToSale,
                            onUpdate: (_) => _loadProformas(),
                            onDelete: () {
                              _handleDeleteProforma(_selectedProforma!);
                            },
                          ),
                        )
                      : const Center(
                          child: Text(
                            'Seleccione una proforma para ver detalles',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Error desconocido',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadProformas,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Proforma>('_proformas', _proformas))
      ..add(DiagnosticsProperty<Proforma?>('_selectedProforma', _selectedProforma))
      ..add(DiagnosticsProperty<bool>('_isLoading', _isLoading))
      ..add(StringProperty('_errorMessage', _errorMessage))
      ..add(DiagnosticsProperty<Paginacion?>('_paginacion', _paginacion))
      ..add(IntProperty('_currentPage', _currentPage))
      ..add(IntProperty('sucursalId', widget.sucursalId))
      ..add(StringProperty('nombreSucursal', widget.nombreSucursal));
  }
}
