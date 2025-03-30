import 'dart:async';

import 'package:condorsmotors/main.dart' show api, proformaNotification;
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('sucursalId', sucursalId));
    properties.add(StringProperty('nombreSucursal', nombreSucursal));
  }
}

class ProformaComputerScreenState extends State<ProformaComputerScreen> {
  List<Proforma> _proformas = [];
  Set<int> _proformasIds = {}; // Para seguimiento de nuevas proformas
  Proforma? _selectedProforma;
  bool _isLoading = false;
  String? _errorMessage;
  Paginacion? _paginacion;
  int _currentPage = 1;
  
  // Para actualización automática
  Timer? _actualizacionTimer;
  final int _intervaloActualizacion = 10; // Segundos
  bool _hayNuevasProformas = false;
  
  @override
  void initState() {
    super.initState();
    _loadProformas();
    
    // Iniciar timer para actualización automática
    _iniciarActualizacionPeriodica();
  }
  
  /// Inicia un timer para actualizar las proformas periódicamente
  void _iniciarActualizacionPeriodica() {
    // Cancelar timer existente si hay uno
    _actualizacionTimer?.cancel();
    
    // Crear nuevo timer para actualizar cada _intervaloActualizacion segundos
    _actualizacionTimer = Timer.periodic(
      Duration(seconds: _intervaloActualizacion), 
      (_) => _verificarNuevasProformas()
    );
    
    Logger.info('🔄 Timer de actualización de proformas iniciado (cada $_intervaloActualizacion segundos)');
  }
  
  /// Verifica si hay nuevas proformas sin interferir con la UI
  Future<void> _verificarNuevasProformas() async {
    Logger.debug('🔍 Verificando nuevas proformas...');
    try {
      // Obtener el ID de sucursal
      String? sucursalId = await _getSucursalId();
      if (sucursalId == null) {
        return;
      }
      
      // Obtener proformas sin modificar el estado de carga
      final response = await api.proformas.getProformasVenta(
        sucursalId: sucursalId,
        page: 1, // Siempre la primera página para ver las más recientes
        pageSize: 20, // Aumentar tamaño para tener más visibilidad
        forceRefresh: true, // Forzar actualización desde el servidor
        useCache: false, // No usar caché
      );
      
      if (response.isNotEmpty) {
        final nuevasProformas = api.proformas.parseProformasVenta(response);
        
        // Verificar si hay nuevas proformas comparando con los IDs conocidos
        Set<int> nuevosIds = nuevasProformas.map((p) => p.id).toSet();
        Set<int> proformasNuevas = nuevosIds.difference(_proformasIds);
        
        if (proformasNuevas.isNotEmpty) {
          Logger.info('🔔 Se encontraron ${proformasNuevas.length} nuevas proformas!');
          
          // Notificar por cada nueva proforma encontrada
          for (var id in proformasNuevas) {
            final nuevaProforma = nuevasProformas.firstWhere((p) => p.id == id);
            
            // Mostrar notificación en Windows
            await proformaNotification.notifyNewProformaPending(
              nuevaProforma, 
              nuevaProforma.getNombreCliente(),
            );
            
            // Actualizar interfaz para mostrar indicador de nuevas proformas
            if (mounted) {
              setState(() {
                _hayNuevasProformas = true;
              });
            }
          }
          
          // Actualizar lista completa de proformas silenciosamente
          await _loadProformas(silencioso: true);
        } else {
          Logger.debug('✓ No se encontraron nuevas proformas');
        }
      }
    } catch (e) {
      Logger.error('❌ Error al verificar nuevas proformas: $e');
    }
  }
  
  /// Obtiene el ID de la sucursal (del widget o del usuario)
  Future<String?> _getSucursalId() async {
    if (widget.sucursalId != null) {
      // Usar el sucursalId pasado como parámetro
      return widget.sucursalId.toString();
    } else {
      // Obtener el ID de sucursal del usuario
      final userData = await api.authService.getUserData();
      if (userData == null || !userData.containsKey('sucursalId')) {
        Logger.error('No se pudo determinar la sucursal del usuario');
        return null;
      }
      return userData['sucursalId'].toString();
    }
  }
  
  @override
  void dispose() {
    // Cancelar el timer al destruir el widget
    _actualizacionTimer?.cancel();
    super.dispose();
  }
  
  /// Carga las proformas desde la API
  Future<void> _loadProformas({bool silencioso = false}) async {
    if (_isLoading && !silencioso) {
      return;
    }
    
    if (!silencioso) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    
    try {
      // Obtener el ID de sucursal
      String? sucursalId = await _getSucursalId();
      if (sucursalId == null) {
        if (!silencioso) {
          setState(() {
            _errorMessage = 'No se pudo determinar la sucursal del usuario';
            _isLoading = false;
          });
        }
        return;
      }
      
      final response = await api.proformas.getProformasVenta(
        sucursalId: sucursalId,
        page: _currentPage,
        forceRefresh: true, // Forzar actualización desde el servidor
        useCache: false, // No usar caché
      );
      
      if (response.isNotEmpty) {
        final proformas = api.proformas.parseProformasVenta(response);
        
        // Extraer información de paginación
        final Map<String, dynamic>? paginacionJson = response['pagination'];
        Paginacion? paginacionObj;
        
        // Crear un objeto Paginacion compatible con ProformaListWidget
        if (paginacionJson != null) {
          final total = paginacionJson['total'] as int? ?? 0;
          final page = paginacionJson['page'] as int? ?? 1;
          final pageSize = paginacionJson['pageSize'] as int? ?? 10;
          
          // Crear objeto de paginación específico para ProformaListWidget
          paginacionObj = Paginacion(
            total: total,
            page: page,
            pageSize: pageSize,
          );
        }
        
        if (mounted) {
          setState(() {
            _proformas = proformas;
            
            // Almacenar IDs para seguimiento de nuevas proformas
            _proformasIds = proformas.map((p) => p.id).toSet();
            
            _paginacion = paginacionObj;
            _isLoading = false;
            _hayNuevasProformas = false; // Resetear indicador al cargar manualmente
            
            // Si la proforma seleccionada ya no está en la lista, deseleccionarla
            if (_selectedProforma != null && 
                !_proformas.any((p) => p.id == _selectedProforma!.id)) {
              _selectedProforma = null;
            }
          });
        }
      } else {
        if (mounted && !silencioso) {
          setState(() {
            _errorMessage = 'No se pudo cargar las proformas';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      Logger.error('Error al cargar proformas: $e');
      if (mounted && !silencioso) {
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
        title: Row(
          children: [
            Text('Gestión de Proformas - ${widget.nombreSucursal}'),
            if (_hayNuevasProformas)
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_active, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'NUEVAS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        elevation: 0,
        actions: [
          // Información del temporizador
          Center(
            child: Text(
              'Actualización: ${_intervaloActualizacion}s',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Botón de recarga
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadProformas,
                tooltip: 'Recargar proformas',
              ),
              if (_hayNuevasProformas)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
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
                  child: Column(
                    children: [
                      // Badge de actualización en tiempo real
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: _hayNuevasProformas 
                              ? Colors.red.withOpacity(0.2) 
                              : const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _hayNuevasProformas 
                                  ? Icons.notifications_active 
                                  : Icons.sync,
                              color: _hayNuevasProformas 
                                  ? Colors.red 
                                  : const Color(0xFF4CAF50),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _hayNuevasProformas 
                                  ? '¡Nuevas proformas detectadas!' 
                                  : 'Actualizando en tiempo real',
                              style: TextStyle(
                                color: _hayNuevasProformas 
                                    ? Colors.red 
                                    : const Color(0xFF4CAF50),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Lista de proformas
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ProformaListWidget(
                            proformas: _proformas,
                            onProformaSelected: _handleProformaSelected,
                            onConvertToSale: _handleConvertToSale,
                            onDeleteProforma: _handleDeleteProforma,
                            onRefresh: _loadProformas,
                            isLoading: _isLoading,
                            paginacion: _paginacion,
                            onPageChanged: _handlePageChange,
                          ),
                        ),
                      ),
                    ],
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
      ..add(DiagnosticsProperty<Set<int>>('_proformasIds', _proformasIds))
      ..add(DiagnosticsProperty<Proforma?>('_selectedProforma', _selectedProforma))
      ..add(DiagnosticsProperty<bool>('_isLoading', _isLoading))
      ..add(StringProperty('_errorMessage', _errorMessage))
      ..add(DiagnosticsProperty<Paginacion?>('_paginacion', _paginacion))
      ..add(IntProperty('_currentPage', _currentPage))
      ..add(DiagnosticsProperty<bool>('_hayNuevasProformas', _hayNuevasProformas))
      ..add(IntProperty('_intervaloActualizacion', _intervaloActualizacion))
      ..add(IntProperty('sucursalId', widget.sucursalId))
      ..add(StringProperty('nombreSucursal', widget.nombreSucursal));
  }
}
