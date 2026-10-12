String formatNumber(double value, [int decimals = 1]) =>
    value.toStringAsFixed(decimals).replaceAll('.', ',');

String formatRelativeDate(DateTime date, DateTime now) {
  final difference = now.difference(date);
  if (difference.inMinutes < 1) return 'ahora';
  if (difference.inHours < 1) return 'hace ${difference.inMinutes} min';
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final days = today.difference(day).inDays;
  if (days == 0) return 'hoy';
  if (days == 1) return 'ayer';
  if (days < 7) return const ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'][date.weekday - 1];
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}
