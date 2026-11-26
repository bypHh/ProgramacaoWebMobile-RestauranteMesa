/// Utilitários de formatação em pt-BR (moeda BRL, número de mesa, comanda, datas e iniciais).
class Formatters {
  static const List<String> _shortMonthsPt = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];

  static String formatCurrency(double value, {bool includeSymbol = true}) {
    final safe = value.isFinite ? value : 0.0;
    final negative = safe < 0;
    final absVal = safe.abs();
    final fixed = absVal.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final remaining = intPart.length - i;
      buffer.write(intPart[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    final formattedNumber = '${negative ? '-' : ''}$buffer,$decPart';
    return includeSymbol ? 'R\$ $formattedNumber' : formattedNumber;
  }

  static String formatTableNumber(int num) {
    return num.toString().padLeft(2, '0');
  }

  static String formatOrderDisplayNumber(int id) {
    return id >= 1000 ? '#$id' : '#${1039 + id}';
  }

  static String formatTimeHHMM(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '18:40';
    final parsed = DateTime.tryParse(isoString);
    if (parsed == null) return '18:40';
    final local = parsed.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static String formatShortDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '20 out';
    final parsed = DateTime.tryParse(isoString);
    if (parsed == null) return '20 out';
    final local = parsed.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final month = _shortMonthsPt[local.month - 1];
    return '$dd $month';
  }

  static String formatElapsedMinutes(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '1 min';
    final parsed = DateTime.tryParse(isoString);
    if (parsed == null) return '1 min';
    final diffMin = DateTime.now().difference(parsed).inMinutes;
    if (diffMin <= 0) return '1 min';
    if (diffMin > 240) return '${diffMin ~/ 60}h';
    return '$diffMin min';
  }

  static String getInitials(String? nameOrEmail) {
    if (nameOrEmail == null || nameOrEmail.trim().isEmpty) return 'AD';
    final clean = nameOrEmail.trim();
    if (clean.contains('@')) {
      return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
    }
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  static String categoryPluralLabel(String category) {
    switch (category) {
      case 'Bebida':
        return 'Bebidas';
      case 'Sobremesa':
        return 'Sobremesas';
      case 'Prato principal':
        return 'Pratos principais';
      case 'Entrada':
        return 'Entradas';
      default:
        return category;
    }
  }
}
