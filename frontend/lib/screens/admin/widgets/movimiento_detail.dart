import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../../main.dart' show api;
import '../../../models/movimiento.model.dart';

/// Widget para mostrar el detalle de un movimiento de inventario
/// Este widget maneja internamente los estados de carga, error y visualización
class MovimientoDetailDialog extends StatefulWidget {
  final Movimiento movimiento;

  const MovimientoDetailDialog({
    Key? key,
    required this.movimiento,
  }) : super(key: key);

  @override
  State<MovimientoDetailDialog> createState() => _MovimientoDetailDialogState();
}

class _MovimientoDetailDialogState extends State<MovimientoDetailDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  Movimiento? _detalleMovimiento;
  int _retryCount = 0;
  
  @override
  void initState() {
    super.initState();
    // Cargar detalles al inicializar el widget
    _cargarDetalles();
  }
  
  Future<void> _cargarDetalles() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      debugPrint('⏳ [MovimientoDetailDialog] Cargando detalles del movimiento #${widget.movimiento.id}');
      
      // Cargar detalles desde la API
      final id = widget.movimiento.id.toString();
      
      // Usar useCache: false para forzar una nueva solicitud
      final detalleMovimiento = await api.movimientos.getMovimiento(
        id, 
        useCache: false,
      );
      
      if (!mounted) return;
      
      setState(() {
        _detalleMovimiento = detalleMovimiento;
        _isLoading = false;
      });
      
      debugPrint('✅ [MovimientoDetailDialog] Detalles cargados correctamente');
      debugPrint('📦 [MovimientoDetailDialog] Productos: ${_detalleMovimiento?.productos?.length ?? 0}');
      
    } catch (e, stackTrace) {
      debugPrint('❌ [MovimientoDetailDialog] Error al cargar detalles: $e');
      debugPrint('📋 [MovimientoDetailDialog] StackTrace: $stackTrace');
      
      if (!mounted) return;
      
      // Si hay un error, usamos los datos que ya tenemos
      setState(() {
        _detalleMovimiento = widget.movimiento;
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        padding: const EdgeInsets.all(24),
        child: _buildContent(),
      ),
    );
  }
  
  Widget _buildContent() {
    // Estado de carga
    if (_isLoading) {
      return _buildLoadingContent();
    }
    
    // Estado de error
    if (_errorMessage != null && _retryCount < 2) {
      return _buildErrorContent();
    }
    
    // Estado normal - muestra los detalles usando el movimiento actual
    // (ya sea el cargado exitosamente o el original como fallback)
    return _buildDetailContent();
  }
  
  // Widget para mostrar estado de carga
  Widget _buildLoadingContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(
          color: Color(0xFFE31E24),
          strokeWidth: 3,
        ),
        const SizedBox(height: 24),
        Text(
          'Cargando detalles de la transferencia #${widget.movimiento.id}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Esto puede tomar unos segundos',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  // Widget para mostrar estado de error
  Widget _buildErrorContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        Text(
          'Error al cargar los detalles',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'No se pudieron cargar los detalles completos de la transferencia #${widget.movimiento.id}.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
        if (_errorMessage != null) 
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Error: $_errorMessage',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
            ),
          ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFFE31E24))),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _retryCount++;
                });
                _cargarDetalles();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE31E24),
              ),
              child: const Text('Reintentar'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                // Usar los datos básicos del movimiento sin productos detallados
                setState(() {
                  _detalleMovimiento = widget.movimiento;
                  _errorMessage = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D2D2D),
              ),
              child: const Text('Ver datos básicos'),
            ),
          ],
        ),
      ],
    );
  }
  
  // Widget para mostrar los detalles del movimiento
  Widget _buildDetailContent() {
    // Movimiento a mostrar (ya sea el detallado o el original)
    final Movimiento movimiento = _detalleMovimiento ?? widget.movimiento;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const Divider(color: Colors.white24),
        const SizedBox(height: 16),
        
        // Mensaje de error si hubo problemas cargando detalles pero seguimos adelante
        if (_errorMessage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mostrando información parcial. Algunos detalles podrían no estar disponibles.',
                    style: TextStyle(color: Colors.orange.shade200, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        
        // Información general
        _buildGeneralInfo(movimiento),
        const SizedBox(height: 16),
        
        _buildSucursalesInfo(movimiento),
        const SizedBox(height: 24),
        
        // Productos
        _buildProductosSection(movimiento),
        const SizedBox(height: 24),
        
        // Observaciones
        _buildObservacionesSection(movimiento),
        
        const SizedBox(height: 24),
        
        // Botón para cerrar
        Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE31E24),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Cerrar'),
          ),
        ),
      ],
    );
  }

  // Encabezado del diálogo
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Detalle de Transferencia',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  // Información general del movimiento
  Widget _buildGeneralInfo(Movimiento movimiento) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoItem(
            'ID', 
            movimiento.id.toString(),
            FontAwesomeIcons.hashtag,
          ),
        ),
        Expanded(
          child: _buildInfoItem(
            'Fecha Creación', 
            _formatFecha(movimiento.salidaOrigen),
            FontAwesomeIcons.calendar,
          ),
        ),
        Expanded(
          child: _buildInfoItem(
            'Estado', 
            movimiento.estado,
            FontAwesomeIcons.circleInfo,
          ),
        ),
      ],
    );
  }

  // Información de sucursales
  Widget _buildSucursalesInfo(Movimiento movimiento) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoItem(
            'Sucursal Origen', 
            movimiento.nombreSucursalOrigen,
            FontAwesomeIcons.building,
          ),
        ),
        Expanded(
          child: _buildInfoItem(
            'Sucursal Destino', 
            movimiento.nombreSucursalDestino,
            FontAwesomeIcons.building,
          ),
        ),
      ],
    );
  }

  // Sección de productos
  Widget _buildProductosSection(Movimiento movimiento) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Productos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        if (movimiento.productos != null && movimiento.productos!.isNotEmpty)
          _buildProductosList(movimiento)
        else
          const Text(
            'No hay productos disponibles para mostrar en esta transferencia',
            style: TextStyle(color: Colors.white70),
          ),
      ],
    );
  }

  // Lista de productos
  Widget _buildProductosList(Movimiento movimiento) {
    // Debug para verificar qué contiene productos
    debugPrint('📦 Productos en el movimiento: ${movimiento.productos?.length ?? 0}');
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
      ),
      // Usamos ConstrainedBox para evitar problemas de altura con ListView
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 300, // Altura máxima para evitar desbordamientos
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: movimiento.productos!.length,
          itemBuilder: (context, index) {
            final producto = movimiento.productos![index];
            return ListTile(
              title: Text(
                producto.nombre,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: producto.codigo != null 
                ? Text(
                    'Código: ${producto.codigo}',
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  )
                : null,
              trailing: Text(
                'Cantidad: ${producto.cantidad}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Sección de observaciones
  Widget _buildObservacionesSection(Movimiento movimiento) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Observaciones',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            movimiento.observaciones ?? 'Sin observaciones',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  // Widget para mostrar un elemento de información
  Widget _buildInfoItem(String titulo, String valor, IconData icono) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FaIcon(
              icono,
              size: 12,
              color: const Color(0xFFE31E24),
            ),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Formato de fecha
  String _formatFecha(DateTime? fecha) {
    if (fecha == null) return 'N/A';
    try {
      return DateFormat('dd/MM/yyyy').format(fecha);
    } catch (e) {
      return 'Fecha inválida';
    }
  }
}
