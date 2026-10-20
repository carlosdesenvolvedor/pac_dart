// O passo da CPU no Rali: no Dart e no C# continua o de sempre (8% por fase, piso de 1,8 s, sem folga por
// letra); a folga (piso de 2,4 s, +140 ms por letra acima de 5, +25%/+40%) é só do inglês.
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/presentation/rali_page.dart';

void main() {
  int ms(Duration d) => d.inMilliseconds;

  test('Dart/C#: a fórmula de sempre, sem folga pela palavra', () {
    expect(ms(intervaloCpuRali(baseMs: 3000, fase: 1, palavra: 'StatelessWidget')), 3000);
    expect(ms(intervaloCpuRali(baseMs: 3000, fase: 6, palavra: 'var')), 1977);
    expect(ms(intervaloCpuRali(baseMs: 3000, fase: 6, palavra: 'StatelessWidget')), 1977);
    expect(ms(intervaloCpuRali(baseMs: 3000, fase: 12, palavra: 'x')), 1800, reason: 'piso de 1,8 s');
    expect(ms(intervaloCpuRali(baseMs: 6000, fase: 1, palavra: 'StatefulWidget')), 6000);
  });

  test('inglês: piso de 2,4 s, folga por letra e +25% (ou +40% de memória)', () {
    expect(ms(intervaloCpuRali(baseMs: 3000, fase: 1, palavra: 'tea', ingles: true)), 3750);
    expect(ms(intervaloCpuRali(baseMs: 3000, fase: 12, palavra: 'tea', ingles: true)), 3000);
    expect(ms(intervaloCpuRali(baseMs: 3000, fase: 1, palavra: 'breakfast', ingles: true)), ((3000 + 560) * 1.25).round());
    expect(ms(intervaloCpuRali(baseMs: 3000, fase: 1, palavra: 'tea', ingles: true, memoria: true)), 4200);
  });
}
