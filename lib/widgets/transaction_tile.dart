import 'package:flutter/material.dart';

class TransactionTile extends StatelessWidget {
  final String title;
  final String category;
  final String amount;
  final String date;
  final IconData icon;
  final Color color;
  final bool isExpense;

  const TransactionTile({
    super.key,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.icon,
    required this.color,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(category, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isExpense ? Colors.black87 : const Color(0xFF81C784),
                ),
              ),
              const SizedBox(height: 4),
              Text(date, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
