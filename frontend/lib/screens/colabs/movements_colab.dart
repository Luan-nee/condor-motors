import 'package:flutter/material.dart';
import '../../models/movement.dart';
import '../../api/movimientos.api.dart';
import '../../api/api.service.dart';

class MovementsColabScreen extends StatefulWidget {
  const MovementsColabScreen({super.key});

  @override
  State<MovementsColabScreen> createState() => _MovementsColabScreenState();
}

class _MovementsColabScreenState extends State<MovementsColabScreen> {
  final _movimientosApi = MovimientosApi(ApiService());
  bool _isLoading = false;
  String? _error;
  List<Movement> _movements = [];

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
    _loadMovements();
  }

  Future<void> _loadMovements() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _movimientosApi.getMovements();
      
      if (!mounted) return;
      setState(() {
        _movements = response
            .map((m) => Movement.fromJson(m))
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
      case 'SOLICITANDO':
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
      case 'SOLICITANDO':
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

  Widget _buildMovementCard(Movement movement) {
    final currentStep = _getStepFromStatus(movement.estado);
    final statusColor = _getStatusColor(movement.estado);

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
                    'Movimiento #${movement.id}',
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
                      movement.estado.toUpperCase(),
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
                      '${movement.cantidad} ${movement.producto?.name ?? 'productos'}',
                      color: textDark,
                      bold: true,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.location_on,
                      'De: ${movement.sucursalOrigen}',
                      color: textMedium,
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      Icons.arrow_forward,
                      'A: ${movement.sucursalDestino}',
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
                if (movement.usuario != null)
                  _buildInfoRow(
                    Icons.person,
                    'Solicitado por: ${movement.usuario!['nombre_completo']}',
                    color: textMedium,
                    bold: true,
                  ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Fecha: ${_formatDate(movement.fechaMovimiento)}',
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
          _buildStepCircle(0, currentStep, 'Solicitado'),
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
            onPressed: _loadMovements,
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
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD32F2F)),
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
              color: Color(0xFFD32F2F),
            ),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: const TextStyle(color: Color(0xFFD32F2F)),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
              ),
              onPressed: _loadMovements,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_movements.isEmpty) {
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
      color: const Color(0xFFD32F2F),
      onRefresh: _loadMovements,
      child: ListView.builder(
        itemCount: _movements.length,
        itemBuilder: (context, index) => _buildMovementCard(_movements[index]),
      ),
    );
  }
} 