import 'package:flutter/material.dart';

class IntegratedCategoryBadge extends StatelessWidget {
  final String label;

  const IntegratedCategoryBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amberAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.amberAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
