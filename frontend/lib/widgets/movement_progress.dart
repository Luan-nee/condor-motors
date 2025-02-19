import 'package:flutter/material.dart';

enum MovementStatus {
  solicitando,
  preparado,
  recibido,
  aprobado,
}

class MovementProgress extends StatelessWidget {
  final MovementStatus currentStatus;
  final VoidCallback? onInfoTap;

  const MovementProgress({
    super.key,
    required this.currentStatus,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStepper(context),
            ),
            if (onInfoTap != null)
              IconButton(
                icon: const Icon(Icons.info_outline, size: 20),
                onPressed: () {
                  _showInfoDialog(context);
                },
                tooltip: 'Ver información de estados',
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepper(BuildContext context) {
    const steps = MovementStatus.values;
    final currentIndex = steps.indexOf(currentStatus);

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Línea conectora
          return Expanded(
            child: Container(
              height: 2,
              color: index <= currentIndex * 2
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).disabledColor,
            ),
          );
        }

        final stepIndex = index ~/ 2;
        final step = steps[stepIndex];
        final isCompleted = stepIndex <= currentIndex;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForStatus(step),
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getStatusText(step),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                color: isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
              ),
            ),
          ],
        );
      }),
    );
  }

  IconData _getIconForStatus(MovementStatus status) {
    switch (status) {
      case MovementStatus.solicitando:
        return Icons.send;
      case MovementStatus.preparado:
        return Icons.inventory;
      case MovementStatus.recibido:
        return Icons.local_shipping;
      case MovementStatus.aprobado:
        return Icons.check_circle;
    }
  }

  String _getStatusText(MovementStatus status) {
    switch (status) {
      case MovementStatus.solicitando:
        return 'Solicitando';
      case MovementStatus.preparado:
        return 'Preparado';
      case MovementStatus.recibido:
        return 'Recibido';
      case MovementStatus.aprobado:
        return 'Aprobado';
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estados del Movimiento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem(
              Icons.send,
              'Solicitando',
              'El colaborador ha iniciado una solicitud de movimiento',
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              Icons.inventory,
              'Preparado',
              'Los productos están listos para ser enviados',
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              Icons.local_shipping,
              'Recibido',
              'El destino ha confirmado la recepción de productos',
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              Icons.check_circle,
              'Aprobado',
              'El administrador ha aprobado el movimiento',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 