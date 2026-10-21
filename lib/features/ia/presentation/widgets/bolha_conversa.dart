import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import '../../../ingles/presentation/widgets/elenco_ingles.dart';
import '../../domain/cenario.dart';
import '../../domain/conversa_resposta.dart';
import '../../domain/sessao_cenario.dart';
import '../feedback_cenario.dart';
import 'botao_por_que.dart' show comNegrito;

/// O fundo do rosto dos personagens (o mesmo creme do palco).
const corFundoRosto = Color(0xFFFFF1DC);

/// A fala do personagem (key 'bolha-dash'): avatar com o nome, o inglês, a tradução (ou "Ver tradução")
/// e 🔊/🐢.
class BolhaPersonagem extends StatelessWidget {
  final int indice;
  final Turno turno;
  final Cenario cenario;
  final bool mostrarTraducao;
  final VoidCallback onOuvir;
  final VoidCallback onOuvirDevagar;

  /// "Ver tradução" só desta bolha (a tela guarda quais estão abertas); null = sem o botão.
  final VoidCallback? onVerTraducao;

  const BolhaPersonagem({
    super.key,
    required this.indice,
    required this.turno,
    required this.cenario,
    required this.mostrarTraducao,
    required this.onOuvir,
    required this.onOuvirDevagar,
    this.onVerTraducao,
  });

  /// A abertura leva a tradução do cenário quando o turno veio sem ela.
  String get _traducao => turno.traducao.isNotEmpty ? turno.traducao : (indice == 0 ? cenario.aberturaPt : '');

  @override
  Widget build(BuildContext context) {
    final pt = _traducao;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AvatarPersonagem(quem: cenario.quem, tamanho: 32, frase: turno.texto),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              key: const Key('bolha-dash'),
              constraints: const BoxConstraints(maxWidth: 540),
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 4),
              decoration: BoxDecoration(
                color: Mixart.surface,
                border: Border.all(color: Mixart.border),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(Mixart.radiusMd),
                  bottomLeft: Radius.circular(Mixart.radiusMd),
                  bottomRight: Radius.circular(Mixart.radiusMd),
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(cenario.nomePersonagem,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: Mixart.ui(size: 10.5, weight: FontWeight.w800, color: Mixart.brand)),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: SelectableText(turno.texto, style: Mixart.ui(size: 14.5, color: Mixart.text).copyWith(height: 1.45)),
                ),
                if (pt.isNotEmpty && mostrarTraducao)
                  Padding(
                    padding: const EdgeInsets.only(top: 3, right: 6),
                    child: Text(pt, key: Key('traducao-$indice'), style: Mixart.ui(size: 12, color: Mixart.textFaint).copyWith(height: 1.4)),
                  ),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  if (pt.isNotEmpty && !mostrarTraducao && onVerTraducao != null)
                    TextButton(
                      key: Key('ver-traducao-$indice'),
                      onPressed: onVerTraducao,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('Ver tradução', style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.brand)),
                    ),
                  _BotaoPequeno(
                    chave: Key('ouvir-fala-$indice'),
                    dica: 'Ouvir de novo',
                    onTap: onOuvir,
                    child: Icon(Icons.volume_up_rounded, size: 18, color: Mixart.brand),
                  ),
                  _BotaoPequeno(
                    chave: Key('ouvir-devagar-$indice'),
                    dica: 'Ouvir devagar',
                    onTap: onOuvirDevagar,
                    child: const Text('🐢', style: TextStyle(fontSize: 15)),
                  ),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// A fala do aluno (key 'bolha-aluno') com o [CartaoCorrecao] embaixo.
class BolhaAluno extends StatelessWidget {
  final int indice;
  final Turno turno;
  final VoidCallback? onOuvirCorrecao;

  const BolhaAluno({super.key, required this.indice, required this.turno, this.onOuvirCorrecao});

  @override
  Widget build(BuildContext context) {
    final c = turno.correcao;
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          key: const Key('bolha-aluno'),
          constraints: const BoxConstraints(maxWidth: 540),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Mixart.brandSub,
            border: Border.all(color: Mixart.brandDim),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(Mixart.radiusMd),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(Mixart.radiusMd),
              bottomRight: Radius.circular(Mixart.radiusMd),
            ),
          ),
          child: SelectableText(turno.texto, style: Mixart.ui(size: 14.5, color: Mixart.text).copyWith(height: 1.45)),
        ),
        if (c != null) CartaoCorrecao(indice: indice, sua: turno.texto, correcao: c, onOuvir: onOuvirCorrecao),
      ]),
    );
  }
}

/// A correção do Prof. Dash (key 'correcao-<i>'): "✅ Certinho!" ou ✏️ o jeito mais natural, com 🔊 e
/// "Salvar como cartão" (salvarCartaoDoCenario).
class CartaoCorrecao extends StatefulWidget {
  final int indice;
  final String sua;
  final CorrecaoTurno correcao;
  final VoidCallback? onOuvir;

  const CartaoCorrecao({super.key, required this.indice, required this.sua, required this.correcao, this.onOuvir});

  @override
  State<CartaoCorrecao> createState() => _CartaoCorrecaoState();
}

class _CartaoCorrecaoState extends State<CartaoCorrecao> {
  bool _salvando = false, _salvo = false;

  Future<void> _salvar() async {
    final cartao = widget.correcao.cartao;
    if (cartao == null || _salvando || _salvo) return;
    setState(() => _salvando = true);
    await salvarCartaoDoCenario(context, cartao);
    if (!mounted) return;
    setState(() {
      _salvando = false;
      _salvo = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.correcao;
    final i = widget.indice;
    if (!c.precisa) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Container(
          key: Key('fala-certa-$i'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Mixart.surfaceHi,
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text('✅ Certinho!', style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.textMuted)),
        ),
      );
    }
    final cartao = c.cartao;
    final salvar = cartao != null && podeSalvarCartao(context);
    return Container(
      key: Key('correcao-$i'),
      margin: const EdgeInsets.only(top: 6),
      constraints: const BoxConstraints(maxWidth: 540),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
      decoration: BoxDecoration(
        color: Mixart.surfaceHi,
        border: Border.all(color: Mixart.brandDim),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('✏️ Prof. Dash · jeito mais natural',
            style: Mixart.ui(size: 10.5, weight: FontWeight.w800, color: Mixart.textFaint).copyWith(letterSpacing: .3)),
        const SizedBox(height: 4),
        SelectableText(c.melhor, style: Mixart.ui(size: 14.5, weight: FontWeight.w700, color: Mixart.brand).copyWith(height: 1.4)),
        if (c.pt.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(c.pt, style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.4)),
        ],
        if (c.porque.isNotEmpty) ...[
          const SizedBox(height: 6),
          SelectableText.rich(comNegrito(c.porque, Mixart.ui(size: 12.5, color: Mixart.text).copyWith(height: 1.45))),
        ],
        if (c.dica.isNotEmpty) ...[
          const SizedBox(height: 4),
          SelectableText.rich(comNegrito('💡 ${c.dica}', Mixart.ui(size: 12, color: Mixart.textMuted).copyWith(height: 1.45))),
        ],
        const SizedBox(height: 4),
        Wrap(spacing: 4, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
          if (widget.onOuvir != null)
            _BotaoPequeno(
              chave: Key('ouvir-correcao-$i'),
              dica: 'Ouvir a versão certa',
              onTap: widget.onOuvir!,
              child: Icon(Icons.volume_up_rounded, size: 18, color: Mixart.brand),
            ),
          if (salvar)
            OutlinedButton(
              key: Key('salvar-correcao-$i'),
              onPressed: _salvo || _salvando ? null : _salvar,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _salvo ? Mixart.brand : Mixart.brandDim),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              child: Text(_salvo ? '✓ Salvo' : (_salvando ? 'Salvando…' : 'Salvar como cartão'),
                  style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.brand)),
            ),
        ]),
      ]),
    );
  }
}

/// O rosto do personagem: ClipOval(ColoredBox(0xFFFFF1DC, PersonagemFalante)), ou 🐦 quando [quem] é vazio.
class AvatarPersonagem extends StatelessWidget {
  final String quem;
  final double tamanho;

  /// Mexe a boca só com esta frase (a tela passa sempre uma: nunca anima com a voz das correções).
  final String? frase;

  const AvatarPersonagem({super.key, required this.quem, required this.tamanho, this.frase});

  @override
  Widget build(BuildContext context) {
    if (quem.isEmpty) {
      return Container(
        width: tamanho,
        height: tamanho,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Mixart.brandSub, shape: BoxShape.circle, border: Border.all(color: Mixart.brandDim)),
        child: Text('🐦', style: TextStyle(fontSize: tamanho * .5)),
      );
    }
    return ClipOval(
      child: ColoredBox(
        color: corFundoRosto,
        child: PersonagemFalante(quem: quem, tamanho: tamanho, frase: frase),
      ),
    );
  }
}

/// 🔊/🐢: um alvo de 36 px com dica.
class _BotaoPequeno extends StatelessWidget {
  final Key chave;
  final String dica;
  final VoidCallback onTap;
  final Widget child;
  const _BotaoPequeno({required this.chave, required this.dica, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) => IconButton(
        key: chave,
        tooltip: dica,
        onPressed: onTap,
        icon: child,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      );
}
