import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TransferenciaInfoCard extends StatelessWidget {
  final List<TransferenciaInfoItem> items;

  const TransferenciaInfoCard({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: items.map((item) {
          return Expanded(
            child: Row(
              children: [
                FaIcon(
                  item.icon,
                  size: 14,
                  color: const Color(0xFFE31E24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.label != null)
                        Text(
                          item.label!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        item.value ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class TransferenciaInfoItem {
  final String? label;
  final String? value;
  final IconData icon;

  const TransferenciaInfoItem({
    this.label,
    this.value,
    required this.icon,
  });
}
