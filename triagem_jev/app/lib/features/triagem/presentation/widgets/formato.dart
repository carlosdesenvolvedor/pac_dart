/// Formatação usada na tela (percentual, dólar, duração).
String pct(double? v) => v == null ? '—' : '${(v * 100).toStringAsFixed(1)}%';

/// Custos de triagem são frações de centavo: mostra dígitos suficientes para não virar "0,00".
String usd(double v) {
  if (v == 0) return r'US$ 0';
  if (v >= 1) return 'US\$ ${v.toStringAsFixed(2)}';
  if (v >= 0.01) return 'US\$ ${v.toStringAsFixed(4)}';
  return 'US\$ ${v.toStringAsPrecision(2)}';
}

String duracao(int ms) => ms < 1000 ? '$ms ms' : '${(ms / 1000).toStringAsFixed(1)} s';
