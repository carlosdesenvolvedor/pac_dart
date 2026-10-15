import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import '../../domain/montagem.dart';
import '../../domain/nivel_resposta.dart';
import 'pastilha.dart';

/// 🧩 Montar: a frase em inglês montada com blocos de palavras (o estilo do Duolingo, o mesmo "Fácil" dos
/// cartões de revisão). Os blocos são as palavras da frase misturadas com 2 a 5 de enfeite; a pessoa toca na ordem
/// e confere. Errar não trava: as pastilhas ficam verdes (no lugar) ou vermelhas e dá para ajustar e conferir de novo.
class MontagemFrase extends StatefulWidget {
  /// A frase em inglês a montar.
  final String frase;

  /// Frases (em inglês) de onde saem os blocos de enfeite: as outras da lição e, se faltar, do curso.
  final List<String> apoio, extra;

  /// Mesma semente, mesmos blocos na mesma ordem (a tela pode se reconstruir sem embaralhar de novo).
  final int semente;

  /// Mostra o "não sei" (os degraus de memória; na cópia a frase já está à vista).
  final bool podeNaoSei;

  /// Conferiu e errou: um erro (1) por palavra da frase fora do lugar, na chave de `errosPorPosicao`.
  final void Function(Map<int, int> erros) onErrou;

  /// Conferiu e a frase está certa.
  final VoidCallback onCerta;

  /// "Não sei": a frase foi revelada; os blocos recomeçam para ela ser copiada.
  final VoidCallback onNaoSei;

  const MontagemFrase({
    super.key,
    required this.frase,
    required this.onErrou,
    required this.onCerta,
    required this.onNaoSei,
    this.apoio = const [],
    this.extra = const [],
    this.semente = 0,
    this.podeNaoSei = true,
  });

  @override
  State<MontagemFrase> createState() => MontagemFraseState();
}

class MontagemFraseState extends State<MontagemFrase> {
  late List<Bloco> _blocos;

  /// Os ids dos blocos na frase montada, na ordem em que foram postos.
  final List<int> _escolhidos = [];

  /// A última conferência errada (as pastilhas ficam marcadas até a pessoa mexer na frase).
  ConferenciaMontagem? _marcas;
  bool _concluida = false;

  @override
  void initState() {
    super.initState();
    _blocos = _montar();
  }

  List<Bloco> _montar() => montarBlocos(
        widget.frase,
        apoio: widget.apoio,
        extra: widget.extra,
        reserva: palavrasDeReservaEn,
        aleatorio: Random(widget.semente),
      );

  @override
  void didUpdateWidget(covariant MontagemFrase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frase != widget.frase || oldWidget.semente != widget.semente) {
      _blocos = _montar();
      limpar(notificar: false);
      _concluida = false;
    }
  }

  /// Os blocos que estão à mostra agora (para os testes e para quem quiser inspecionar).
  List<Bloco> get blocos => List.unmodifiable(_blocos);

  /// Recomeça a montagem (o "não sei" revelou a frase: ela vai ser copiada).
  void limpar({bool notificar = true}) {
    void zera() {
      _escolhidos.clear();
      _marcas = null;
    }

    notificar ? setState(zera) : zera();
  }

  void _pegar(int id) {
    if (_concluida || _escolhidos.contains(id)) return;
    setState(() {
      _escolhidos.add(id);
      _marcas = null;
    });
  }

  void _soltar(int id) {
    if (_concluida) return;
    setState(() {
      _escolhidos.remove(id);
      _marcas = null;
    });
  }

  /// Confere a frase montada. Sem nenhum bloco não há o que conferir.
  void conferir() {
    if (_concluida || _escolhidos.isEmpty) return;
    final c = conferirMontagem(widget.frase, [for (final id in _escolhidos) _blocos[id]]);
    if (c.certa) {
      setState(() {
        _concluida = true;
        _marcas = c;
      });
      widget.onCerta();
    } else {
      setState(() => _marcas = c);
      widget.onErrou(c.erros);
    }
  }

  MarcaPastilha _marca(int posicao) {
    final m = _marcas;
    if (m == null || posicao >= m.escolhidasCertas.length) return MarcaPastilha.nenhuma;
    return m.escolhidasCertas[posicao] ? MarcaPastilha.certa : MarcaPastilha.errada;
  }

  @override
  Widget build(BuildContext context) {
    if (_blocos.isEmpty) {
      // frase sem nenhuma palavra: não há o que montar
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('Esta frase não tem palavras para montar.', style: Mixart.ui(size: 12.5, color: Mixart.textMuted)),
          _Botao(chave: const Key('montagem-continuar'), rotulo: 'Continuar', onTap: widget.onCerta),
        ]),
      );
    }
    final m = _marcas;
    final errou = m != null && !m.certa;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          key: const Key('montagem-frase'),
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Mixart.surface,
            border: Border.all(color: _escolhidos.isEmpty ? Mixart.border : Mixart.brandDim, width: 1.4),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: _escolhidos.isEmpty
              ? Text('Toque nos blocos abaixo para montar a frase em inglês',
                  style: Mixart.ui(size: 13, color: Mixart.textFaint))
              : Wrap(spacing: 8, runSpacing: 8, children: [
                  for (var k = 0; k < _escolhidos.length; k++)
                    Pastilha(
                      key: Key('escolhido-${_escolhidos[k]}'),
                      texto: _blocos[_escolhidos[k]].texto,
                      marca: _marca(k),
                      onTap: _concluida ? null : () => _soltar(_escolhidos[k]),
                    ),
                ]),
        ),
        const SizedBox(height: 14),
        Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
          for (final b in _blocos)
            Pastilha(
              key: Key('bloco-${b.id}'),
              texto: b.texto,
              vazia: _escolhidos.contains(b.id),
              onTap: _concluida || _escolhidos.contains(b.id) ? null : () => _pegar(b.id),
            ),
        ]),
        if (errou) ...[
          const SizedBox(height: 10),
          Text(
            key: const Key('montagem-erro'),
            'Ainda não: as palavras em vermelho estão fora do lugar. Toque nelas para tirar e tente de novo.',
            textAlign: TextAlign.center,
            style: Mixart.ui(size: 12.5, weight: FontWeight.w600, color: Mixart.danger).copyWith(height: 1.4),
          ),
        ],
        const SizedBox(height: 12),
        if (!_concluida)
          Wrap(alignment: WrapAlignment.center, spacing: 14, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            _Botao(
              chave: const Key('montagem-conferir'),
              rotulo: 'Conferir',
              onTap: _escolhidos.isEmpty ? null : conferir,
            ),
            if (widget.podeNaoSei)
              InkWell(
                key: const Key('montagem-nao-sei'),
                onTap: widget.onNaoSei,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                  child: Text('não sei',
                      style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.textMuted)
                          .copyWith(decoration: TextDecoration.underline)),
                ),
              ),
          ]),
      ]),
    );
  }
}

class _Botao extends StatelessWidget {
  final Key chave;
  final String rotulo;
  final VoidCallback? onTap;
  const _Botao({required this.chave, required this.rotulo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ativo = onTap != null;
    return Material(
      key: chave,
      color: ativo ? Mixart.brand : Mixart.surfaceHi,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 120),
          child: Center(
            widthFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text(rotulo,
                  style: Mixart.ui(size: 14, weight: FontWeight.w800, color: ativo ? Mixart.onBrand : Mixart.textHint)),
            ),
          ),
        ),
      ),
    );
  }
}
