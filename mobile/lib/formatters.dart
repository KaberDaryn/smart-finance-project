String money(int minor) =>
    '${minor < 0 ? '-' : ''}${minor.abs() ~/ 100}.${(minor.abs() % 100).toString().padLeft(2, '0')} KZT';

int? parseAmount(String input) {
  final value = input.trim();
  if (!RegExp(r'^\d{1,11}(\.\d{1,2})?$').hasMatch(value)) return null;
  final parts = value.split('.');
  final amount =
      int.parse(parts[0]) * 100 +
      int.parse(parts.length == 2 ? parts[1].padRight(2, '0') : '0');
  return amount > 0 && amount <= 1000000000000 ? amount : null;
}

String dateText(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
