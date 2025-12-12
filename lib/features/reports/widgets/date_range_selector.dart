import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRangeSelector extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime, DateTime) onDateRangeChanged;

  const DateRangeSelector({
    super.key,
    this.startDate,
    this.endDate,
    required this.onDateRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Rango de Fechas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    context,
                    'Fecha Inicio',
                    startDate != null ? dateFormat.format(startDate!) : 'Seleccionar',
                    () => _selectStartDate(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateButton(
                    context,
                    'Fecha Fin',
                    endDate != null ? dateFormat.format(endDate!) : 'Seleccionar',
                    () => _selectEndDate(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildQuickSelectChip(context, 'Esta semana', () {
                  final now = DateTime.now();
                  final start = now.subtract(Duration(days: now.weekday - 1));
                  final end = now.add(Duration(days: 7 - now.weekday));
                  onDateRangeChanged(start, end);
                }),
                const SizedBox(width: 8),
                _buildQuickSelectChip(context, 'Este mes', () {
                  final now = DateTime.now();
                  final start = DateTime(now.year, now.month, 1);
                  final end = DateTime(now.year, now.month + 1, 0);
                  onDateRangeChanged(start, end);
                }),
                const SizedBox(width: 8),
                _buildQuickSelectChip(context, 'Último mes', () {
                  final now = DateTime.now();
                  final start = DateTime(now.year, now.month - 1, 1);
                  final end = DateTime(now.year, now.month, 0);
                  onDateRangeChanged(start, end);
                }),
              ],
            ),
          ],
           ),
  ),
);
}
Widget _buildDateButton(
BuildContext context,
String label,
String value,
VoidCallback onTap,
) {
return InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(8),
child: Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
border: Border.all(color: Colors.grey.shade300),
borderRadius: BorderRadius.circular(8),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
label,
style: TextStyle(
fontSize: 12,
color: Colors.grey.shade600,
),
),
const SizedBox(height: 4),
Text(
value,
style: const TextStyle(
fontSize: 14,
fontWeight: FontWeight.bold,
),
),
],
),
),
);
}
Widget _buildQuickSelectChip(
BuildContext context,
String label,
VoidCallback onTap,
) {
return InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(16),
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
decoration: BoxDecoration(
color: Colors.blue.shade50,
borderRadius: BorderRadius.circular(16),
border: Border.all(color: Colors.blue.shade200),
),
child: Text(
label,
style: TextStyle(
fontSize: 12,
color: Colors.blue.shade700,
fontWeight: FontWeight.w500,
),
),
),
);
}
Future<void> _selectStartDate(BuildContext context) async {
final DateTime? picked = await showDatePicker(
context: context,
initialDate: startDate ?? DateTime.now(),
firstDate: DateTime(2020),
lastDate: DateTime.now(),
);
if (picked != null && endDate != null) {
  onDateRangeChanged(picked, endDate!);
}
}
Future<void> _selectEndDate(BuildContext context) async {
final DateTime? picked = await showDatePicker(
context: context,
initialDate: endDate ?? DateTime.now(),
firstDate: startDate ?? DateTime(2020),
lastDate: DateTime.now(),
);
if (picked != null && startDate != null) {
  onDateRangeChanged(startDate!, picked);
}
}
}