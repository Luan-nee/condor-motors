import 'package:flutter/material.dart';
import '../../api/movimientos_stock.api.dart';
import '../../api/main.api.dart';

class MovimientosColabScreen extends StatefulWidget {
  const MovimientosColabScreen({super.key});

  @override
  State<MovimientosColabScreen> createState() => _MovimientosColabScreenState();
}

class _MovimientosColabScreenState extends State<MovimientosColabScreen> {
  final _movimientosApi = MovimientosStockApi(ApiService());
  bool _isLoading = false;
  String? _error;
  List<MovimientoStock> _movimientos = [];

  // Definir paleta de colores constante
  static const primaryRed = Color(0xFFD32F2F);
  static const secondaryRed = Color(0xFFFF5252);
  static const accentBlue = Color(0xFF1E88E5);
  static const accentGreen = Color(0xFF43A047);
  static const accentPurple = Color(0xFF6A1B9A);
  static const textDark = Color(0xFF424242);
  static const textMedium = Color(0xFF757575);
  static const backgroundLight = Color(0xFFFAFAFA);
  static const cardBackground = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _cargarMovimientos();
  }

  Future<void> _cargarMovimientos() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _movimientosApi.getMovimientos();
      
      if (!mounted) return;
      setState(() {
        _movimientos = response
            .where((m) => m.estado == MovimientosStockApi.estadosDetalle['PENDIENTE'] || 
                        m.estado == MovimientosStockApi.estadosDetalle['PREPARADO'])
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  int _getStepFromStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDIENTE':
        return 0;
      case 'PREPARADO':
        return 1;
      case 'RECIBIDO':
        return 2;
      case 'APROBADO':
        return 3;
      default:
        return 0;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDIENTE':
        return secondaryRed;
      case 'PREPARADO':
        return accentBlue;
      case 'RECIBIDO':
        return accentGreen;
      case 'APROBADO':
        return accentPurple;
      default:
        return textMedium;
    }
  }

  Widget _buildMovimientoCard(MovimientoStock movimiento) {
    final currentStep = _getStepFromStatus(movimiento.estado);
    final statusColor = _getStatusColor(movimiento.estado);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      color: cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Row(
                children: [
                  Text(
                    'Movimiento #${movimiento.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textDark,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      movimiento.estado.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      Icons.inventory,
                      '${movimiento.detalles.length} productos',
                      color: textDark,
                      bold: true,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.location_on,
                      'De: Local #${movimiento.localOrigenId}',
                      color: textMedium,
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      Icons.arrow_forward,
                      'A: Local #${movimiento.localDestinoId}',
                      color: textMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: backgroundLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressSteps(currentStep),
                const SizedBox(height: 16),
                if (movimiento.solicitanteId != null)
                  _buildInfoRow(
                    Icons.person,
                    'Solicitado por: ${movimiento.solicitanteId}',
                    color: textMedium,
                    bold: true,
                  ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Fecha: ${_formatDate(movimiento.fechaCreacion)}',
                  color: textMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {
    required Color color,
    bool bold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSteps(int currentStep) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildStepCircle(0, currentStep, 'Pendiente'),
          _buildStepLine(0, currentStep),
          _buildStepCircle(1, currentStep, 'Preparado'),
          _buildStepLine(1, currentStep),
          _buildStepCircle(2, currentStep, 'Recibido'),
          _buildStepLine(2, currentStep),
          _buildStepCircle(3, currentStep, 'Aprobado'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, int currentStep, String label) {
    final isCompleted = step <= currentStep;
    final isActive = step == currentStep;
    final color = isCompleted ? const Color(0xFFD32F2F) : Colors.grey[400]!;

    return Expanded(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? color : Colors.white,
                  border: Border.all(
                    color: color,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              if (isActive)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isCompleted ? color : Colors.grey[600],
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step, int currentStep) {
    final isCompleted = step < currentStep;
    return Container(
      height: 2,
      width: 40,
      color: isCompleted ? const Color(0xFFD32F2F) : Colors.grey[300],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: primaryRed,
        elevation: 0,
        title: const Text(
          'Movimientos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargarMovimientos,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: primaryRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: const TextStyle(color: primaryRed),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
              ),
              onPressed: _cargarMovimientos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_movimientos.isEmpty) {
      return const Center(
        child: Text(
          'No hay movimientos registrados',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: primaryRed,
      onRefresh: _cargarMovimientos,
      child: ListView.builder(
        itemCount: _movimientos.length,
        itemBuilder: (context, index) => _buildMovimientoCard(_movimientos[index]),
      ),
    );
  }
} 