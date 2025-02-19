import 'package:flutter/material.dart';

class VentasColabScreen extends StatelessWidget {
  const VentasColabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Registro de Ventas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          Center(
            child: Text('Implementación pendiente'),
          ),
        ],
      ),
    );
  }
}
