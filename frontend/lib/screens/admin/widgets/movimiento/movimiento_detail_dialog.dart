import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../main.dart' show api;
import '../../../../models/movimiento.model.dart';

/// Widget para mostrar el detalle de un movimiento de inventario
/// Este widget maneja internamente los estados de carga, error y visualización
class MovimientoDetailDialog extends StatefulWidget {
  final Movimiento movimiento;

  const MovimientoDetailDialog({
    super.key,
    required this.movimiento,
  });

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
    // Obtener tamaño de pantalla
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 1200;
    final isMediumScreen = screenSize.width > 800 && screenSize.width <= 1200;
    
    // Calcular ancho apropiado basado en el tamaño de pantalla
    double dialogWidth;
    if (isWideScreen) {
      dialogWidth = 1000; // Ancho fijo para pantallas grandes
    } else if (isMediumScreen) {
      dialogWidth = screenSize.width * 0.7;
    } else {
      dialogWidth = screenSize.width * 0.85;
    }
    
    // Asegurar que el diálogo nunca sea demasiado pequeño
    dialogWidth = dialogWidth.clamp(350.0, 1000.0);
    
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxWidth: 1000,
          maxHeight: screenSize.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        child: _buildContent(context, isWideScreen, isMediumScreen),
      ),
    );
  }
  
  Widget _buildContent(BuildContext context, bool isWideScreen, bool isMediumScreen) {
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
    return _buildDetailContent(context, isWideScreen, isMediumScreen);
  }
  
  // Widget para mostrar estado de carga
  Widget _buildLoadingContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          const CircularProgressIndicator(
            color: Color(0xFFE31E24),
            strokeWidth: 3,
          ),
          const SizedBox(height: 32),
          Text(
            'Cargando detalles de la transferencia #${widget.movimiento.id}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Esto puede tomar unos segundos',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  // Widget para mostrar estado de error
  Widget _buildErrorContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 24),
            Text(
              'Error al cargar los detalles',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Text(
                'No se pudieron cargar los detalles completos de la transferencia #${widget.movimiento.id}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            if (_errorMessage != null) 
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Text(
                    'Error: $_errorMessage',
                    style: TextStyle(color: Colors.red.shade200, fontSize: 14),
                  ),
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
        ),
      ),
    );
  }
  
  // Widget para mostrar los detalles del movimiento
  Widget _buildDetailContent(BuildContext context, bool isWideScreen, bool isMediumScreen) {
    // Movimiento a mostrar (ya sea el detallado o el original)
    final Movimiento movimiento = _detalleMovimiento ?? widget.movimiento;
    
    return SingleChildScrollView(
      child: Column(
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mostrando información parcial. Algunos detalles podrían no estar disponibles.',
                      style: TextStyle(color: Colors.orange.shade200, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          
          // Layout adaptativo para información general y sucursales
          if (isWideScreen)
            // En pantallas anchas, mostrar todo en una fila
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información general
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información General',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildGeneralInfoRow(movimiento),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Información de sucursales
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sucursales',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSucursalesInfoRow(movimiento),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            // En pantallas medianas y pequeñas, apilar en columnas
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información general
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información General',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildGeneralInfoRow(movimiento),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Información de sucursales
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sucursales',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSucursalesInfoRow(movimiento),
                    ],
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 24),
          
          // Productos y Observaciones
          if (isWideScreen)
            // En pantallas anchas, mostrar productos y observaciones en una fila
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Productos
                Expanded(
                  flex: 3,
                  child: _buildProductosSectionCard(movimiento),
                ),
                const SizedBox(width: 24),
                // Observaciones
                Expanded(
                  flex: 2,
                  child: _buildObservacionesSectionCard(movimiento),
                ),
              ],
            )
          else
            // En pantallas medianas y pequeñas, apilar en columnas
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductosSectionCard(movimiento),
                const SizedBox(height: 16),
                _buildObservacionesSectionCard(movimiento),
              ],
            ),
          
          const SizedBox(height: 24),
          
          // Botón para cerrar
          Center(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              label: const Text('Cerrar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE31E24),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Encabezado del diálogo
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE31E24).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.truck,
                color: Color(0xFFE31E24),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Detalle de Transferencia',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          iconSize: 24,
          splashRadius: 24,
        ),
      ],
    );
  }

  // Información general del movimiento
  Widget _buildGeneralInfoRow(Movimiento movimiento) {
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
  Widget _buildSucursalesInfoRow(Movimiento movimiento) {
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

  // Sección de productos en tarjeta
  Widget _buildProductosSectionCard(Movimiento movimiento) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.box,
                size: 16,
                color: Color(0xFFE31E24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Productos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              if (movimiento.productos != null && movimiento.productos!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE31E24).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${movimiento.productos!.length} productos',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (movimiento.productos != null && movimiento.productos!.isNotEmpty)
            _buildProductosList(movimiento)
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No hay productos disponibles para mostrar en esta transferencia',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Sección de observaciones en tarjeta
  Widget _buildObservacionesSectionCard(Movimiento movimiento) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.fileLines,
                size: 16,
                color: Color(0xFFE31E24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Observaciones',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              movimiento.observaciones ?? 'Sin observaciones',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          // Si hay solicitante, mostrarlo
          if (movimiento.solicitante != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.user,
                  size: 16,
                  color: Color(0xFFE31E24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Solicitante:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    movimiento.solicitante!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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
          maxHeight: 350, // Altura máxima ajustada
        ),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: movimiento.productos!.length,
          separatorBuilder: (context, index) => const Divider(
            color: Colors.white10,
            height: 1,
          ),
          itemBuilder: (context, index) {
            final producto = movimiento.productos![index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.boxOpen,
                  color: Color(0xFFE31E24),
                  size: 16,
                ),
              ),
              title: Text(
                producto.nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: producto.codigo != null 
                ? Text(
                    'Código: ${producto.codigo}',
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  )
                : null,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE31E24).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE31E24).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Cantidad: ${producto.cantidad}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
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
              size: 14,
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
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 22),
          child: Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
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