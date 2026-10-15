import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/mixart.dart';
import '../../curso/domain/curriculo.dart';
import '../../ia/domain/explicacao.dart';
import '../../ia/presentation/widgets/botao_por_que.dart';
import '../data/reconhecedor_fala.dart';
import '../data/voz_ingles.dart';
import '../domain/alternativas.dart';
import '../domain/avaliacao_fala.dart';
import '../domain/comparar_resposta.dart';
import '../domain/nivel_resposta.dart';
import '../domain/shadowing.dart';
import '../domain/srs.dart';
import '../domain/subida_nivel.dart';
import 'widgets/cena_visual.dart';
import 'widgets/painel_shadowing.dart';
import 'widgets/pastilha.dart';

/// A nota que a pessoa deu a uma frase (a 1ª vez que ela apareceu na sessão).
class ResultadoCartao {
  final Trecho frase;
  final Rating nota;
  const ResultadoCartao(this.frase, this.nota);
}

/// O cartão do Anki: uma língua na FRENTE, a outra no VERSO. O sentido varia — inglês →
/// português, português → inglês ou misturado (cada cartão sorteia o seu) — e a pessoa
/// responde no nível que escolheu: montando a frase com BLOCOS de palavras (Fácil, com
/// palavras de enfeite para confundir, como no Duolingo), completando LACUNAS (Médio, com
/// algumas palavras à vista), ESCREVENDO a frase inteira (Avançado) ou só lembrando e
/// virando. A resposta é conferida palavra por palavra e sugere uma nota. Avalia com 4
/// botões — Errei, Difícil, Bom, Fácil — cada um com o tempo até o cartão voltar.
/// Só a 1ª nota de cada frase vale para o agendador; a que sai "Errei" volta
/// ainda nesta sessão (sem contar de novo) até ser lembrada.
/// Celular (Android/iOS): muda só as dicas de uso (sem tecla de atalho).
bool get _ehCelular => defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

class SessaoCartoesPage extends StatefulWidget {
  final String titulo, subtitulo, emoji;

  /// As frases (a ordem é a da sessão).
  final List<Trecho> itens;

  /// Chaves (a da frase) dos cartões que a pessoa vê pela PRIMEIRA vez: ganham a
  /// etiqueta "NOVO" e a previsão dos botões parte de um cartão novo.
  final Set<String> novas;

  /// Chave da frase → chave do cartão (para saber se é nova). O `RevisaoCubit` dá.
  final String Function(Trecho frase) chaveDe;

  /// Em quantos dias a frase volta com cada nota (os textos dos botões).
  final Map<Rating, int> Function(Trecho frase) previsao;

  /// A 1ª nota de cada frase.
  final FutureOr<void> Function(Trecho frase, Rating nota) onNota;
  final void Function(List<ResultadoCartao> resultados)? onFim;

  /// Veio emendada em outra sequência: sair devolve false, terminar true.
  final bool emSequencia;

  /// A lição de onde veio cada frase (a cena ajuda a lembrar).
  final Licao? Function(Trecho frase)? cenaDe;

  /// Botão a mais ao lado do 🔊 (o áudio do aluno).
  final Widget Function(BuildContext context, Trecho frase)? acaoExtra;

  final VozIngles? voz;

  /// O reconhecedor de voz do shadowing (testes injetam o deles; null = o de [fabricaReconhecedor]).
  final ReconhecedorFala? reconhecedor;

  /// Quem cria o reconhecedor quando [reconhecedor] é null (o probe e os testes de app trocam por um falso).
  static ReconhecedorFala Function() fabricaReconhecedor = ReconhecedorFala.navegador;

  /// Diz se a frase é um cartão de lacuna da leitura (guardado em "Meus cartões" com a palavra-alvo).
  /// ATENÇÃO: as frases do CURSO também têm `alvo` (é o destaque da lição); por isso quem abre a revisão
  /// é quem sabe de onde a frase veio. Sem isto, nenhuma frase vira lacuna de leitura.
  final bool Function(Trecho frase)? lacunaDaLeitura;

  /// Outras frases do curso para os blocos de enfeite do nível Fácil (além das da própria sessão).
  final List<Trecho> apoio;

  /// Sorteio (testes põem uma semente): lado de cada cartão, palavras das lacunas e dos blocos.
  final Random? aleatorio;

  /// Pref: o nível de resposta (`NivelResposta.id`; padrão Avançado).
  static const prefNivel = 'en_cartao_nivel';

  /// Pref: o sentido (`SentidoCartao.id`; padrão misturado).
  static const prefSentido = 'en_cartao_sentido';

  /// Pref: as últimas respostas por nível (a série que decide quando SUGERIR subir ou descer de nível).
  static const prefSerie = 'en_cartao_serie_v1';

  /// Pref de antes dos níveis (responder escrevendo sim/não): sem `prefNivel`, "não" vira Só virar.
  static const prefEscrita = 'en_cartao_escrita';

  const SessaoCartoesPage({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.emoji = '🔄',
    required this.itens,
    required this.chaveDe,
    required this.previsao,
    required this.onNota,
    this.novas = const {},
    this.onFim,
    this.emSequencia = false,
    this.cenaDe,
    this.acaoExtra,
    this.voz,
    this.reconhecedor,
    this.lacunaDaLeitura,
    this.apoio = const [],
    this.aleatorio,
  });

  @override
  State<SessaoCartoesPage> createState() => _SessaoCartoesPageState();
}

class _Item {
  final Trecho frase;

  /// Voltou na sessão depois de "Errei": não conta de novo para o agendador.
  final bool repeticao;

  /// No sentido "misturado": este cartão pergunta o português (true) ou o inglês (false).
  final bool sorteado;
  const _Item(this.frase, {this.repeticao = false, this.sorteado = false});
}

class _SessaoCartoesPageState extends State<SessaoCartoesPage> {
  /// Quantas voltas uma frase errada pode ter na sessão.
  static const _maxVoltas = 2;

  /// Pref do palco: tocar o áudio sozinho.
  static const _prefAudio = 'en_audio_auto';

  late final VozIngles _voz = widget.voz ?? VozIngles();
  late final Random _alea = widget.aleatorio ?? Random();
  final _foco = FocusNode(debugLabel: 'cartões');
  late final List<_Item> _fila = [for (final f in widget.itens) _Item(f, sorteado: _alea.nextBool())];
  final List<ResultadoCartao> _resultados = [];
  final Map<String, int> _voltas = {};
  int _i = 0;
  bool _virado = false;
  bool _fim = false;
  bool _audioAuto = true;

  /// As preferências leram? (antes disso o cartão não aparece: nada de piscar no lado errado)
  bool _pronto = false;

  /// O que a pessoa escolheu (vale para os próximos cartões; muda o atual se ainda não virou).
  NivelResposta _nivel = NivelResposta.avancado;
  SentidoCartao _sentido = SentidoCartao.misto;

  /// A série de acertos/erros por nível e o degrau sugerido agora (null = nada a sugerir).
  SerieDeNivel _serie = const SerieDeNivel();
  NivelResposta? _sugerido;

  /// Como o cartão ATUAL foi montado (fica fixo até ele acabar, mesmo se a escolha mudar depois de virar).
  bool _ptEnAtual = false;

  /// Ditado: o cartão atual não mostra texto, só o áudio (a resposta é o inglês, como no PT → EN).
  bool _audioAtual = false;

  /// Shadowing: o cartão atual é ouvir e REPETIR FALANDO (a frase só aparece ao virar). Sem reconhecedor (ou
  /// depois que a voz falhou) o cartão vira ditado e a revisão segue.
  bool _shadowAtual = false;
  bool _shadowSemVoz = false;
  SessaoShadowing _shadow = const SessaoShadowing();
  final _painel = GlobalKey<PainelShadowingState>();
  late final ReconhecedorFala _rec = widget.reconhecedor ?? SessaoCartoesPage.fabricaReconhecedor();

  /// O cartão atual é uma lacuna da leitura (nível forçado a "lacuna única": não conta na série de níveis).
  bool _lacunaDeLeitura = false;
  NivelResposta _nivelCartao = NivelResposta.avancado;

  /// Avançado: o campo, o que foi conferido e a nota que combina.
  final _resposta = TextEditingController();
  final _focoCampo = FocusNode(debugLabel: 'resposta escrita');
  ComparacaoResposta? _comparacao;
  Rating? _sugerida;

  /// Médio: a frase com as lacunas e um campo por lacuna.
  List<ParteFrase> _partes = const [];
  List<TextEditingController> _lacunas = [];
  List<FocusNode> _focosLacunas = [];

  /// Fácil: os blocos do cartão e os que a pessoa já pôs na frase (ids, na ordem).
  List<Bloco> _blocos = const [];
  final List<int> _escolhidos = [];

  _Item get _item => _fila[_i];

  @override
  void initState() {
    super.initState();
    if (_fila.isEmpty) {
      _fim = true;
      _pronto = true;
    } else {
      _comecar();
    }
  }

  Future<void> _comecar() async {
    try {
      final p = await SharedPreferences.getInstance();
      _audioAuto = p.getBool(_prefAudio) ?? true;
      _serie = SerieDeNivel.decodificar(p.getString(SessaoCartoesPage.prefSerie));
      _sentido = SentidoCartao.porId(p.getString(SessaoCartoesPage.prefSentido)) ?? SentidoCartao.misto;
      _nivel = NivelResposta.porId(p.getString(SessaoCartoesPage.prefNivel)) ??
          (p.getBool(SessaoCartoesPage.prefEscrita) == false ? NivelResposta.livre : NivelResposta.avancado);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _prepararCartao();
      _pronto = true;
    });
    _falarAoComecar();
    _focarCampo();
  }

  @override
  void dispose() {
    _voz.parar();
    _foco.dispose();
    _focoCampo.dispose();
    _resposta.dispose();
    for (final c in _lacunas) {
      c.dispose();
    }
    for (final f in _focosLacunas) {
      f.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------- o cartão atual

  bool _calcularPtEn(_Item it) {
    // ditado: responde-se o inglês, não importa se há tradução cadastrada
    if (_sentido == SentidoCartao.audio || _sentido == SentidoCartao.shadowing) return true;
    // sem tradução cadastrada não dá para perguntar o português
    if (it.frase.dicaPlana.trim().isEmpty) return false;
    // cartão de lacuna da leitura: a tradução na frente e a palavra guardada em branco no inglês
    if (_ehLacunaDeLeitura(it.frase) && _nivel != NivelResposta.livre) return true;
    return switch (_sentido) {
      SentidoCartao.enPt => false,
      SentidoCartao.ptEn => true,
      SentidoCartao.misto => it.sorteado,
      SentidoCartao.audio || SentidoCartao.shadowing => true,
    };
  }

  /// O cartão veio da leitura (tem a palavra-alvo guardada): é sempre PT → EN com SÓ essa palavra em lacuna
  /// (menos no "Só virar", que é autoavaliação).
  bool _ehLacunaDeLeitura(Trecho f) =>
      f.alvo.trim().isNotEmpty && f.dicaPlana.trim().isNotEmpty && (widget.lacunaDaLeitura?.call(f) ?? false);

  /// O que aparece na frente e o que a pessoa tem de responder, no sentido do cartão atual.
  String get _pergunta => _ptEnAtual ? _item.frase.dicaPlana : _item.frase.cod;
  String get _esperada => _ptEnAtual ? _item.frase.cod : _item.frase.dicaPlana;

  /// Monta o que o nível atual precisa para o cartão que está na tela (lacunas ou blocos) e limpa a resposta.
  void _prepararCartao() {
    _descartarCampos();
    _resposta.clear();
    _escolhidos.clear();
    _blocos = const [];
    _partes = const [];
    _ptEnAtual = _calcularPtEn(_item);
    _shadowAtual = _sentido == SentidoCartao.shadowing && _rec.suportado && !_shadowSemVoz;
    // shadowing sem voz neste aparelho: vira ditado (com o nível escolhido)
    _audioAtual = _sentido == SentidoCartao.audio || (_sentido == SentidoCartao.shadowing && !_shadowAtual);
    _shadow = const SessaoShadowing();
    // shadowing não tem nível: a resposta é falada (e a frase inteira, não só a palavra da leitura)
    var nivel = _shadowAtual ? NivelResposta.livre : _nivel;
    _lacunaDeLeitura = false;
    // lacuna da leitura: só a palavra guardada some, qualquer que seja o nível escolhido (a escada de níveis não conta)
    final soAlvo = _ehLacunaDeLeitura(_item.frase) && _ptEnAtual && nivel != NivelResposta.livre
        ? lacunaUnica(partirFrase(_esperada), _item.frase.alvo)
        : null;
    if (soAlvo != null) {
      nivel = NivelResposta.medio;
      _lacunaDeLeitura = true;
      _partes = soAlvo;
      final n = contarLacunas(_partes);
      _lacunas = [for (var j = 0; j < n; j++) TextEditingController()];
      _focosLacunas = [for (var j = 0; j < n; j++) FocusNode(debugLabel: 'lacuna $j')];
    } else if (nivel == NivelResposta.medio) {
      _partes = esconderPalavras(partirFrase(_esperada), _alea);
      final n = contarLacunas(_partes);
      if (n == 0) {
        nivel = NivelResposta.livre; // frase sem palavras: não há o que preencher
      } else {
        _lacunas = [for (var j = 0; j < n; j++) TextEditingController()];
        _focosLacunas = [for (var j = 0; j < n; j++) FocusNode(debugLabel: 'lacuna $j')];
      }
    } else if (nivel == NivelResposta.facil) {
      _blocos = montarBlocos(
        _esperada,
        apoio: _textosDe(widget.itens),
        extra: _textosDe(([...widget.apoio]..shuffle(_alea)).take(60)),
        reserva: _ptEnAtual ? palavrasDeReservaEn : palavrasDeReservaPt,
        aleatorio: _alea,
      );
      if (_blocos.isEmpty) nivel = NivelResposta.livre;
    }
    _nivelCartao = nivel;
  }

  /// Os textos de outras frases (a atual fica de fora) no idioma da RESPOSTA do cartão atual:
  /// inglês quando a pessoa responde em inglês, português quando responde em português.
  List<String> _textosDe(Iterable<Trecho> frases) => [
        for (final x in frases)
          if (x.cod != _item.frase.cod) _ptEnAtual ? x.cod : x.dicaPlana,
      ];

  /// Os campos do cartão anterior saem depois do quadro (os campos da tela ainda os usam até lá).
  void _descartarCampos() {
    final velhos = <ChangeNotifier>[..._lacunas, ..._focosLacunas];
    _lacunas = [];
    _focosLacunas = [];
    if (velhos.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final v in velhos) {
        v.dispose();
      }
    });
  }

  /// O cursor vai para onde a pessoa responde (campo, primeira lacuna ou a tela, para as teclas dos blocos).
  void _focarCampo() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _virado || _fim) return;
        switch (_nivelCartao) {
          case NivelResposta.avancado:
            _focoCampo.requestFocus();
          case NivelResposta.medio:
            if (_focosLacunas.isNotEmpty) _focosLacunas.first.requestFocus();
          case NivelResposta.facil || NivelResposta.livre:
            _foco.requestFocus();
        }
      });

  Future<void> _mudarNivel(NivelResposta n) async {
    if (n == _nivel) return;
    setState(() {
      // trocou de degrau (à mão ou pela sugestão): a contagem do degrau antigo recomeça
      _serie = _serie.limpar(_nivel);
      _sugerido = null;
      _nivel = n;
      if (!_virado && !_fim) _prepararCartao();
    });
    _guardarSerie();
    _focarCampo();
    try {
      (await SharedPreferences.getInstance()).setString(SessaoCartoesPage.prefNivel, n.id);
    } catch (_) {}
  }

  Future<void> _mudarSentido(SentidoCartao s) async {
    if (s == _sentido) return;
    final antes = _ptEnAtual;
    setState(() {
      _sentido = s;
      if (!_virado && !_fim) _prepararCartao();
    });
    if (!_virado && !_fim && (antes != _ptEnAtual || _audioAtual || _shadowAtual)) {
      _voz.parar();
      _falarAoComecar();
    }
    _focarCampo();
    try {
      (await SharedPreferences.getInstance()).setString(SessaoCartoesPage.prefSentido, s.id);
    } catch (_) {}
  }

  void _falarSeAuto() {
    if (_audioAuto && !_fim && _voz.somLiberado) unawaited(_voz.falar(_item.frase.cod));
  }

  /// Ao abrir o cartão: o áudio só toca sozinho se o inglês está na frente (senão entregaria a resposta).
  void _falarAoComecar() {
    // no ditado o áudio É a pergunta: toca ao abrir o cartão
    if (!_ptEnAtual || _audioAtual || _shadowAtual) _falarSeAuto();
  }

  // ---------------------------------------------------------------- responder

  void _revelar({ComparacaoResposta? comparacao, Rating? sugerida}) {
    setState(() {
      _virado = true;
      _comparacao = comparacao;
      _sugerida = sugerida;
    });
    _foco.requestFocus();
    // português na frente: o inglês só toca quando a resposta aparece
    if (_ptEnAtual) _falarSeAuto();
  }

  /// Vira sem resposta: "Mostrar resposta" (Só virar) ou "Não sei" (nos outros níveis, que já sugere "Errei").
  void _virar() {
    if (_virado || _fim) return;
    _revelar(sugerida: _nivelCartao == NivelResposta.livre ? null : Rating.again);
  }

  /// Shadowing: uma fala conferida. Perfeita ou na última tentativa, o cartão vira com a nota que combina.
  void _aoTentativa(AvaliacaoFala av) {
    if (_virado || _fim || !_shadowAtual) return;
    final s = _shadow.registrar(av);
    setState(() => _shadow = s);
    if (s.encerrou) _virarShadow();
  }

  /// "Mostrar a frase": desistiu de repetir (nota Errei).
  void _aoMostrarFrase() {
    if (_virado || _fim || !_shadowAtual) return;
    _virarShadow(desistiu: true);
  }

  void _virarShadow({bool desistiu = false}) {
    final nota = _shadow.notaSugerida(desistiu: desistiu);
    _revelar(comparacao: comparacaoDoShadowing(_item.frase.cod, _shadow, sugerida: nota), sugerida: nota);
  }

  /// A voz não funciona aqui (sem permissão, sem microfone, sem suporte): o cartão vira ditado e a revisão segue.
  void _aoSemVoz() {
    if (_virado || _fim) return;
    setState(() {
      _shadowSemVoz = true;
      _prepararCartao();
    });
    _falarAoComecar();
    _focarCampo();
  }

  /// Confere o que a pessoa respondeu (escrito, nas lacunas ou com os blocos) e sugere a nota.
  void _conferir() {
    if (_virado || _fim) return;
    // montando com blocos e nada montado: não há o que conferir (para virar, é o "Não sei")
    if (_nivelCartao == NivelResposta.facil && _escolhidos.isEmpty) return;
    final esperada = _esperada;
    final ComparacaoResposta? c = switch (_nivelCartao) {
      NivelResposta.avancado => _resposta.text.trim().isEmpty ? null : compararResposta(esperada, _resposta.text.trim()),
      NivelResposta.medio => _lacunas.every((l) => l.text.trim().isEmpty)
          ? null
          : conferirLacunas(_partes, [for (final l in _lacunas) l.text]),
      NivelResposta.facil => _escolhidos.isEmpty ? null : conferirBlocos(esperada, [for (final id in _escolhidos) _blocos[id]]),
      NivelResposta.livre => null,
    };
    if (c == null) return _virar();
    _revelar(comparacao: c, sugerida: c.sugerida);
  }

  void _pegarBloco(int id) {
    if (_virado || _fim || _escolhidos.contains(id)) return;
    setState(() => _escolhidos.add(id));
  }

  void _soltarBloco(int id) {
    if (_virado || _fim) return;
    setState(() => _escolhidos.remove(id));
  }

  void _soltarUltimoBloco() {
    if (_virado || _fim || _escolhidos.isEmpty) return;
    setState(() => _escolhidos.removeLast());
  }

  Future<void> _nota(Rating nota) async {
    if (!_virado || _fim) return;
    final item = _item;
    final k = widget.chaveDe(item.frase);
    if (!item.repeticao) {
      _resultados.add(ResultadoCartao(item.frase, nota));
      _acompanharNivel(nota);
      try {
        await widget.onNota(item.frase, nota);
      } catch (_) {}
      if (!mounted) return;
    }
    if (nota == Rating.again) {
      final voltas = _voltas[k] ?? 0;
      if (voltas < _maxVoltas) {
        _voltas[k] = voltas + 1;
        // volta daqui a umas frases (ou no fim, se a sessão for curta), do mesmo lado
        _fila.insert((_i + 1 + 4).clamp(_i + 1, _fila.length), _Item(item.frase, repeticao: true, sorteado: item.sorteado));
      }
    }
    _proximo();
  }

  /// A 1ª nota do cartão entra na série do degrau; se a série pede, o banner SUGERE (nunca troca sozinho).
  void _acompanharNivel(Rating nota) {
    // a lacuna da leitura não diz nada sobre o nível escolhido: fora da série
    if (_lacunaDeLeitura || _shadowAtual) return;
    _serie = _serie.registrar(_nivelCartao, nota);
    final alvo = _nivelCartao == _nivel ? _serie.sugestao(_nivelCartao) : null;
    if (alvo != null && alvo != _sugerido) setState(() => _sugerido = alvo);
    _guardarSerie();
  }

  void _guardarSerie() => unawaited(SharedPreferences.getInstance().then(
        (p) => p.setString(SessaoCartoesPage.prefSerie, _serie.codificar()),
        onError: (_) => false,
      ));

  void _aceitarSugestao() {
    final alvo = _sugerido;
    if (alvo != null) _mudarNivel(alvo);
  }

  /// "Agora não": a contagem do degrau recomeça (só volta a sugerir depois de outra série inteira).
  void _dispensarSugestao() {
    setState(() {
      _serie = _serie.limpar(_nivel);
      _sugerido = null;
    });
    _guardarSerie();
  }

  /// O convite para trocar de degrau: subir quando vai bem, descer (sem culpa) quando está pesado.
  Widget _bannerNivel(NivelResposta alvo) {
    final sobe = SerieDeNivel.escada.indexOf(alvo) > SerieDeNivel.escada.indexOf(_nivel);
    final texto = sobe
        ? '🚀 ${SerieDeNivel.acertosParaSubir} acertos seguidos no ${_nivel.rotulo}! Que tal tentar o ${alvo.rotulo}?'
        : '🫶 Está pesado? Foram ${SerieDeNivel.errosParaDescer} erros nas últimas ${SerieDeNivel.janelaParaDescer} no ${_nivel.rotulo}. '
            'Que tal voltar ao ${alvo.rotulo} por um tempo?';
    return Container(
      key: const Key('sugestao-nivel'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Mixart.brandSub,
        border: Border.all(color: Mixart.brandDim),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(texto, style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.text).copyWith(height: 1.4)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: [
          FilledButton(
            key: const Key('aceitar-sugestao-nivel'),
            onPressed: _aceitarSugestao,
            style: FilledButton.styleFrom(
              backgroundColor: Mixart.brand,
              foregroundColor: Mixart.onBrand,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: Text(sobe ? 'Subir para ${alvo.rotulo}' : 'Voltar para ${alvo.rotulo}',
                style: Mixart.ui(size: 12.5, weight: FontWeight.w800, color: Mixart.onBrand)),
          ),
          TextButton(
            key: const Key('dispensar-sugestao-nivel'),
            onPressed: _dispensarSugestao,
            child: Text('Agora não', style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.textMuted)),
          ),
        ]),
      ]),
    );
  }

  void _proximo() {
    if (_i < _fila.length - 1) {
      setState(() {
        _i++;
        _virado = false;
        _comparacao = null;
        _sugerida = null;
        _prepararCartao();
      });
      _falarAoComecar();
      _focarCampo();
      return;
    }
    _voz.parar();
    setState(() => _fim = true);
    widget.onFim?.call(List.unmodifiable(_resultados));
  }

  void _sair({required bool seguir}) => Navigator.of(context).pop(seguir);

  KeyEventResult _tecla(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    final enter = k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter;
    if (_fim) {
      if (enter || k == LogicalKeyboardKey.space) {
        _sair(seguir: true);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (_shadowAtual && !_virado) {
      // Espaço fala/para o microfone; Enter não vira o cartão (a frase só aparece depois de falar ou de "Mostrar a frase")
      if (k == LogicalKeyboardKey.space) {
        _painel.currentState?.alternar();
        return KeyEventResult.handled;
      }
      if (enter) return KeyEventResult.handled;
    }
    if (!_virado) {
      // escrevendo (campo ou lacunas): as teclas são do campo (Enter confere pelo próprio campo)
      if (_nivelCartao.escreve) return KeyEventResult.ignored;
      // montando com blocos: Enter confere e Backspace tira o último bloco
      if (_nivelCartao == NivelResposta.facil) {
        if (enter) {
          _conferir();
          return KeyEventResult.handled;
        }
        if (k == LogicalKeyboardKey.backspace) {
          _soltarUltimoBloco();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      }
    }
    if (k == LogicalKeyboardKey.space || enter) {
      _virado ? _nota(_sugerida ?? Rating.good) : _virar();
      return KeyEventResult.handled;
    }
    if (_virado) {
      final nota = switch (k) {
        LogicalKeyboardKey.digit1 || LogicalKeyboardKey.numpad1 => Rating.again,
        LogicalKeyboardKey.digit2 || LogicalKeyboardKey.numpad2 => _item.repeticao ? null : Rating.hard,
        LogicalKeyboardKey.digit3 || LogicalKeyboardKey.numpad3 => Rating.good,
        LogicalKeyboardKey.digit4 || LogicalKeyboardKey.numpad4 => _item.repeticao ? null : Rating.easy,
        _ => null,
      };
      if (nota != null) {
        _nota(nota);
        return KeyEventResult.handled;
      }
    }
    // ouvir: com o português na frente, o inglês só depois de virar
    if (k == LogicalKeyboardKey.keyR && (!_ptEnAtual || _virado || _audioAtual || _shadowAtual)) {
      unawaited(_voz.falar(_item.frase.cod));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ---------------------------------------------------------------- telas

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: SafeArea(
        child: Focus(
          focusNode: _foco,
          autofocus: true,
          onKeyEvent: _tecla,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 40), children: [
                _topo(),
                const SizedBox(height: 16),
                if (_fim) _resumo() else if (_pronto) _cartao(),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topo() => Row(children: [
        IconButton(
          tooltip: widget.emSequencia ? 'Sair da sequência' : 'Voltar',
          onPressed: () => _sair(seguir: false),
          icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
          style: IconButton.styleFrom(backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
        ),
        const SizedBox(width: 12),
        Text(widget.emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.titulo, style: Mixart.display(size: 20), overflow: TextOverflow.ellipsis),
            Text(widget.subtitulo, style: Mixart.ui(size: 12, color: Mixart.textMuted), overflow: TextOverflow.ellipsis),
          ]),
        ),
        if (!_fim)
          Text('${_i + 1} / ${_fila.length}', style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.textMuted)),
      ]);

  Widget _etiqueta(String t, Color cor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: .12),
          border: Border.all(color: cor.withValues(alpha: .55)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(t, style: Mixart.ui(size: 10.5, weight: FontWeight.w800, color: cor).copyWith(letterSpacing: 1)),
      );

  Widget _ouvir(Trecho f) => Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          key: const Key('ouvir-cartao'),
          tooltip: 'Ouvir (R)',
          onPressed: () => unawaited(_voz.falar(f.cod, lenta: false)),
          icon: Icon(Icons.volume_up_rounded, color: Mixart.brand, size: 22),
        ),
        IconButton(
          tooltip: 'Ouvir devagar',
          onPressed: () => unawaited(_voz.falar(f.cod, lenta: true)),
          icon: Icon(Icons.slow_motion_video_rounded, color: Mixart.textMuted, size: 21),
        ),
        if (widget.acaoExtra != null) widget.acaoExtra!(context, f),
      ]);

  /// Nível e sentido do cartão: duas fileiras de opções.
  Widget _seletores() {
    const dicas = {
      NivelResposta.facil: 'Monte a frase tocando em blocos de palavras (tem blocos que não fazem parte dela)',
      NivelResposta.medio: 'Algumas palavras já aparecem; escreva as que faltam',
      NivelResposta.avancado: 'Escreva a frase inteira',
      NivelResposta.livre: 'Só lembre, vire o cartão e avalie',
    };
    Widget rotulo(String t) => Text(t, style: Mixart.ui(size: 11.5, weight: FontWeight.w700, color: Mixart.textFaint));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (!_shadowAtual) ...[
      Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        rotulo('Nível'),
        for (final n in NivelResposta.values)
          _Opcao(
            key: Key('nivel-${n.id}'),
            texto: '${n.emoji} ${n.rotulo}',
            dica: dicas[n]!,
            ativo: n == _nivel,
            onTap: () => _mudarNivel(n),
          ),
      ]),
      const SizedBox(height: 6),
      ],
      Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        rotulo('Sentido'),
        for (final s in SentidoCartao.values)
          _Opcao(
            key: Key('sentido-${s.id}'),
            texto: s.rotulo,
            dica: switch (s) {
              SentidoCartao.enPt => 'Você vê o inglês e responde em português',
              SentidoCartao.ptEn => 'Você vê o português e responde em inglês',
              SentidoCartao.misto => 'Cada cartão sorteia o lado',
              SentidoCartao.audio => 'Ditado: só o áudio na frente; escreva em inglês o que ouviu',
              SentidoCartao.shadowing => 'Shadowing: ouça e repita falando; a frase só aparece depois',
            },
            ativo: s == _sentido,
            onTap: () => _mudarSentido(s),
          ),
      ]),
    ]);
  }

  /// A instrução em cima do cartão, conforme o lado e o nível.
  String _instrucao(bool repeticao) {
    final de = _ptEnAtual ? 'português' : 'inglês', para = _ptEnAtual ? 'inglês' : 'português';
    final texto = _shadowAtual
        ? 'Ouça e repita a frase falando; ela só aparece depois'
        : _lacunaDeLeitura && !_audioAtual
        ? 'Leia o português e escreva a palavra que falta no inglês (a que você guardou na leitura)'
        : _audioAtual
        ? switch (_nivelCartao) {
            NivelResposta.facil => 'Ouça e monte em inglês o que você ouviu, com os blocos',
            NivelResposta.medio => 'Ouça e complete a frase em inglês',
            NivelResposta.avancado => 'Ouça e escreva em inglês o que você ouviu',
            NivelResposta.livre => 'Ouça e tente lembrar o que foi dito',
          }
        : switch (_nivelCartao) {
      NivelResposta.facil => 'Monte a frase em $para com os blocos',
      NivelResposta.medio => 'Complete a frase em $para',
      NivelResposta.avancado => 'Leia o $de e escreva em $para',
      NivelResposta.livre => 'Leia o $de e tente lembrar o $para',
    };
    final semVoz = _sentido == SentidoCartao.shadowing && !_shadowAtual ? 'Sem voz neste aparelho, hoje é ditado. ' : '';
    return semVoz + (repeticao ? 'Você errou: ${texto[0].toLowerCase()}${texto.substring(1)}' : texto);
  }

  Widget _cartao() {
    final item = _item;
    final f = item.frase;
    final k = widget.chaveDe(f);
    final nova = widget.novas.contains(k) && !item.repeticao;
    final prev = widget.previsao(f);
    final licao = widget.cenaDe?.call(f);
    final ptEn = _ptEnAtual;
    // ditado antes de virar: a frente é só o áudio (sem texto, senão não seria ditado)
    final soAudio = (_audioAtual || _shadowAtual) && !_virado;
    final rotuloFrente = soAudio ? 'ÁUDIO' : (ptEn ? 'PORTUGUÊS' : 'INGLÊS'), rotuloVerso = ptEn ? 'INGLÊS' : 'PORTUGUÊS';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: _i / _fila.length,
          minHeight: 6,
          backgroundColor: Mixart.surfaceHi,
          color: Mixart.brand,
        ),
      ),
      const SizedBox(height: 14),
      Row(children: [
        _etiqueta(item.repeticao ? 'DE NOVO' : (nova ? 'NOVO' : 'REVISÃO'),
            item.repeticao ? Mixart.danger : (nova ? Mixart.brand : Mixart.textMuted)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(_instrucao(item.repeticao), key: const Key('instrucao-cartao'), style: Mixart.ui(size: 12, color: Mixart.textMuted)),
        ),
      ]),
      const SizedBox(height: 10),
      if (_sugerido != null && _sugerido != _nivel) _bannerNivel(_sugerido!),
      _seletores(),
      const SizedBox(height: 12),
      if (licao != null && CenaVisual(licao: licao).temAlgo) ...[
        CenaVisual(licao: licao, compacta: true),
        const SizedBox(height: 10),
      ],
      Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: _virado ? Mixart.brandDim : Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(rotuloFrente, style: Mixart.ui(size: 10.5, weight: FontWeight.w800, color: Mixart.textFaint).copyWith(letterSpacing: 1.4)),
          const SizedBox(height: 6),
          if (soAudio && _shadowAtual)
            Text('🗣 Ouça e repita',
                key: const Key('frente-shadowing'),
                style: Mixart.display(size: 27, weight: FontWeight.w700).copyWith(height: 1.3))
          else if (soAudio)
            Text('🎧 Ouça e escreva',
                key: const Key('frente-audio'),
                style: Mixart.display(size: 27, weight: FontWeight.w700).copyWith(height: 1.3))
          else
            Text(_pergunta,
                key: const Key('frente-cartao'),
                style: Mixart.display(size: 27, weight: FontWeight.w700).copyWith(height: 1.3)),
          // o áudio é em inglês: com o inglês na frente fica aqui; com o português, só junto da resposta
          // (no ditado, o áudio fica na frente até virar)
          if (!ptEn || soAudio) Align(alignment: Alignment.centerRight, child: _ouvir(f)),
          if (_virado) ...[
            Divider(color: Mixart.border, height: 22),
            if (_comparacao case final c?) ...[
              Text(_shadowAtual ? 'O QUE EU OUVI' : 'SUA RESPOSTA', style: Mixart.ui(size: 10.5, weight: FontWeight.w800, color: Mixart.textFaint).copyWith(letterSpacing: 1.4)),
              const SizedBox(height: 6),
              _comMarcas(c.digitada, key: const Key('sua-resposta'), tamanho: 19, cor: Mixart.text, certa: _verde, errada: Mixart.danger, sublinhaErro: false),
              const SizedBox(height: 14),
            ],
            Text(rotuloVerso, style: Mixart.ui(size: 10.5, weight: FontWeight.w800, color: Mixart.textFaint).copyWith(letterSpacing: 1.4)),
            const SizedBox(height: 6),
            if (_comparacao case final c?)
              _comMarcas(c.esperada, key: const Key('verso-cartao'), tamanho: 24, cor: Mixart.brand, certa: Mixart.brand, errada: Mixart.danger, sublinhaErro: true)
            else
              Text(_esperada,
                  key: const Key('verso-cartao'),
                  style: Mixart.display(size: 24, weight: FontWeight.w600, color: Mixart.brand).copyWith(height: 1.3)),
            if (ptEn) Align(alignment: Alignment.centerRight, child: _ouvir(f)),
            if (_comparacao case final c?) ...[
              const SizedBox(height: 10),
              Text(_resumoDe(c), key: const Key('resumo-comparacao'), style: Mixart.ui(size: 12.5, weight: FontWeight.w800, color: Mixart.textMuted)),
              // respondeu e não foi idêntico: o Prof. Dash explica o porquê
              if (!c.exata && !_shadowAtual) ...[
                const SizedBox(height: 8),
                BotaoPorQue(key: ValueKey('por-que-$_i-${_fila.length}'), pedido: _pedidoPorQue(c)),
              ],
            ],
            if (f.literal.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('ao pé da letra: ${f.literal}', style: Mixart.ui(size: 13, color: Mixart.textMuted).copyWith(height: 1.45)),
            ],
            if (f.conceito.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('💡 ${f.conceito}', style: Mixart.ui(size: 13, color: Mixart.textMuted).copyWith(height: 1.45)),
            ],
          ],
        ]),
      ),
      const SizedBox(height: 16),
      if (_virado)
        _notas(prev, repeticao: item.repeticao)
      else if (_shadowAtual)
        PainelShadowing(
          key: _painel,
          reconhecedor: _rec,
          frase: f.cod,
          alternativas: alternativasDe(f.cod, declaradas: f.alternativas),
          sessao: _shadow,
          onTentativa: _aoTentativa,
          onMicrofone: (ouvindo) {
            // o app se cala enquanto a pessoa fala (senão o reconhecedor ouve o próprio áudio)
            if (ouvindo) _voz.parar();
          },
          onMostrarFrase: _aoMostrarFrase,
          onSemVoz: _aoSemVoz,
        )
      else
        switch (_nivelCartao) {
          NivelResposta.avancado => _campoDeEscrita(),
          NivelResposta.medio => _lacunasParaEscrever(),
          NivelResposta.facil => _montagemComBlocos(),
          NivelResposta.livre => _mostrarResposta(),
        },
      const SizedBox(height: 14),
      Text(_dica(), textAlign: TextAlign.center, style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
    ]);
  }

  /// O que a pessoa escreveu no cartão atual e o que era esperado, em dados.
  PedidoExplicacao _pedidoPorQue(ComparacaoResposta c) {
    final erradas = [
      for (final s in c.esperada)
        if (s.acerto == false) s.texto,
    ];
    final ouvindo = _audioAtual;
    return PedidoExplicacao(
      frase: _item.frase.cod,
      traducao: _item.frase.dicaPlana,
      // a resposta é na língua do lado de trás: no PT → EN e no ditado é o inglês da frase; no EN → PT, a tradução
      resposta: c.digitada.map((s) => s.texto).join(),
      palavrasErradas: _ptEnAtual ? erradas : const [],
      exercicio: ouvindo
          ? 'ditado: ouvir a frase e escrever em inglês (${_nivelCartao.rotulo})'
          : _ptEnAtual
              ? 'cartão PT → EN: escrever em inglês (${_nivelCartao.rotulo})'
              : 'cartão EN → PT: escrever a tradução (${_nivelCartao.rotulo})',
    );
  }

  /// A linha de ajuda no pé do cartão.
  String _dica() {
    if (_virado && _sugerida != null) {
      return _ehCelular
          ? 'Toque na nota que combina (a sugerida vem marcada)'
          : 'Espaço aceita a sugestão · 1 Errei · 2 Difícil · 3 Bom · 4 Fácil';
    }
    if (!_virado && _shadowAtual) {
      return _ehCelular ? 'Toque em Falar, repita a frase e confira' : 'Espaço fala e para o microfone · R ouve de novo';
    }
    if (!_virado) {
      switch (_nivelCartao) {
        case NivelResposta.avancado:
          return _ehCelular ? 'Escreva a resposta e toque em Conferir' : 'Enter confere · "Não sei" mostra a resposta';
        case NivelResposta.medio:
          return _ehCelular
              ? 'Preencha as lacunas e toque em Conferir'
              : 'Espaço ou Enter passa para a próxima lacuna · no fim, Enter confere';
        case NivelResposta.facil:
          return _ehCelular
              ? 'Toque nos blocos na ordem da frase · toque num bloco da frase para tirar'
              : 'Clique nos blocos na ordem da frase · Backspace tira o último · Enter confere';
        case NivelResposta.livre:
          break;
      }
    }
    return _ehCelular
        ? 'Toque em "Mostrar resposta" e avalie o quanto você lembrou'
        : 'Espaço vira · 1 Errei · 2 Difícil · 3 Bom (ou Espaço) · 4 Fácil · R ouve';
  }

  static const _verde = Color(0xFF4CD08A);

  static String _nomeDaNota(Rating n) => switch (n) {
        Rating.again => 'Errei',
        Rating.hard => 'Difícil',
        Rating.good => 'Bom',
        Rating.easy => 'Fácil',
      };

  /// O resultado da conferência em uma linha.
  String _resumoDe(ComparacaoResposta c) {
    if (_shadowAtual) {
      return c.exata
          ? 'Você falou a frase inteira! ✅ ${c.acertadas} de ${c.totalEsperadas} palavras.'
          : 'Você falou ${c.acertadas} de ${c.totalEsperadas} palavras · sugestão: ${_nomeDaNota(c.sugerida)}';
    }
    if (c.exata) {
      return switch (_nivelCartao) {
        NivelResposta.medio => 'Todas as lacunas certas! ✅',
        NivelResposta.facil => 'Frase montada certinha! ✅',
        _ => 'Idêntica! ✅ ${c.acertadas} de ${c.totalEsperadas} palavras.',
      };
    }
    final sugestao = 'sugestão: ${_nomeDaNota(c.sugerida)}';
    if (c.cobertura >= 1 && c.precisao >= 1) return 'Todas as palavras, mas em outra ordem · $sugestao';
    final unidade = _nivelCartao == NivelResposta.medio ? 'lacunas' : 'palavras';
    return 'Você acertou ${c.acertadas} de ${c.totalEsperadas} $unidade · $sugestao';
  }

  /// O texto com as palavras coloridas: acertou ([certa]) ou não ([errada], sublinhada
  /// quando [sublinhaErro]); o espaço e a pontuação ficam na [cor] do texto.
  Widget _comMarcas(List<Segmento> segmentos,
      {required Key key, required double tamanho, required Color cor, required Color certa, required Color errada, required bool sublinhaErro}) {
    final base = Mixart.display(size: tamanho, weight: FontWeight.w600, color: cor).copyWith(height: 1.35);
    return Text.rich(
      key: key,
      TextSpan(children: [
        for (final s in segmentos)
          TextSpan(
            text: s.texto,
            style: s.acerto == null
                ? base
                : base.copyWith(
                    color: s.acerto! ? certa : errada,
                    decoration: !s.acerto! && sublinhaErro ? TextDecoration.underline : null,
                    decorationColor: errada,
                  ),
          ),
      ]),
    );
  }

  Widget _botaoConferir({required VoidCallback? onPressed}) => FilledButton(
        key: const Key('conferir-resposta'),
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Mixart.brand,
          foregroundColor: Mixart.onBrand,
          disabledBackgroundColor: Mixart.surfaceHi,
          minimumSize: const Size(160, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        child: Text('Conferir', style: Mixart.ui(size: 15, weight: FontWeight.w800, color: onPressed == null ? Mixart.textFaint : Mixart.onBrand)),
      );

  Widget _botaoNaoSei() => TextButton(
        key: const Key('nao-sei-cartao'),
        onPressed: _virar,
        child: Text('Não sei', style: Mixart.ui(size: 13.5, weight: FontWeight.w700, color: Mixart.textMuted)),
      );

  Widget _mostrarResposta() => Center(
        child: InkWell(
          key: const Key('mostrar-resposta'),
          canRequestFocus: false,
          onTap: _virar,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            constraints: const BoxConstraints(minWidth: 240, minHeight: 52),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
            decoration: BoxDecoration(color: Mixart.brand, borderRadius: BorderRadius.circular(999)),
            child: Text('Mostrar resposta', style: Mixart.ui(size: 15, weight: FontWeight.w800, color: Mixart.onBrand)),
          ),
        ),
      );

  InputDecoration _decoracaoDoCampo(String dica) => InputDecoration(
        hintText: dica,
        hintStyle: Mixart.ui(size: 14, color: Mixart.textFaint),
        filled: true,
        fillColor: Mixart.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd), borderSide: BorderSide(color: Mixart.brand, width: 1.4)),
      );

  /// Avançado: o campo para escrever a frase inteira e os botões Conferir / Não sei.
  Widget _campoDeEscrita() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          key: const Key('resposta-escrita'),
          controller: _resposta,
          focusNode: _focoCampo,
          textInputAction: TextInputAction.done,
          autocorrect: !_ptEnAtual,
          enableSuggestions: !_ptEnAtual,
          onSubmitted: (_) => _conferir(),
          style: Mixart.ui(size: 16, color: Mixart.text),
          decoration: _decoracaoDoCampo(_ptEnAtual ? 'Escreva aqui a frase em inglês…' : 'Escreva aqui a tradução em português…'),
        ),
        const SizedBox(height: 12),
        Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          _botaoConferir(onPressed: _conferir),
          _botaoNaoSei(),
        ]),
      ]);

  /// Médio: a frase na língua da resposta com as palavras que faltam como campos para escrever.
  Widget _lacunasParaEscrever() {
    final estilo = Mixart.display(size: 22, weight: FontWeight.w600, color: Mixart.text).copyWith(height: 1.3);
    // fichas: palavra à vista ou campo; "colada" = sem espaço antes da próxima (pontuação)
    final fichas = <({String? texto, int? lacuna, bool espacoDepois})>[];
    var lacuna = 0;
    final visivel = StringBuffer();

    void despejar() {
      final run = visivel.toString();
      visivel.clear();
      if (run.isEmpty) return;
      if (fichas.isNotEmpty && RegExp(r'^\s').hasMatch(run)) {
        final ultima = fichas.removeLast();
        fichas.add((texto: ultima.texto, lacuna: ultima.lacuna, espacoDepois: true));
      }
      for (final m in RegExp(r'\S+\s*').allMatches(run)) {
        final t = m[0]!;
        fichas.add((texto: t.trimRight(), lacuna: null, espacoDepois: t.length != t.trimRight().length));
      }
    }

    for (final p in _partes) {
      if (p.palavra && p.escondida) {
        despejar();
        fichas.add((texto: null, lacuna: lacuna++, espacoDepois: false));
      } else {
        visivel.write(p.texto);
      }
    }
    despejar();

    Widget campo(int n) {
      final palavra = _partes.where((p) => p.palavra && p.escondida).elementAt(n).texto;
      final ultimo = n == _lacunas.length - 1;
      return SizedBox(
        width: (palavra.length * 12.0 + 38).clamp(76.0, 230.0).toDouble(),
        child: TextField(
          key: Key('lacuna-$n'),
          controller: _lacunas[n],
          focusNode: _focosLacunas[n],
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: ultimo ? TextInputAction.done : TextInputAction.next,
          onChanged: (v) {
            // espaço = terminei esta palavra: vai para a próxima lacuna
            if (v.endsWith(' ')) {
              _lacunas[n].text = v.trim();
              if (!ultimo) _focosLacunas[n + 1].requestFocus();
            }
          },
          onSubmitted: (_) => ultimo ? _conferir() : _focosLacunas[n + 1].requestFocus(),
          style: Mixart.ui(size: 18, weight: FontWeight.w700, color: Mixart.brand),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Mixart.textFaint, width: 1.6)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Mixart.brand, width: 2.2)),
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        key: const Key('lacunas'),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
        ),
        child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 10, children: [
          for (final f in fichas)
            Padding(
              padding: EdgeInsets.only(right: f.espacoDepois ? 7 : 0),
              child: f.lacuna != null ? campo(f.lacuna!) : Text(f.texto!, style: estilo),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        _botaoConferir(onPressed: _conferir),
        _botaoNaoSei(),
      ]),
    ]);
  }

  /// Fácil: a frase sendo montada em cima e, embaixo, os blocos (os da resposta e os de enfeite).
  Widget _montagemComBlocos() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          key: const Key('montagem'),
          constraints: const BoxConstraints(minHeight: 86),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Mixart.surface,
            border: Border.all(color: _escolhidos.isEmpty ? Mixart.border : Mixart.brandDim, width: 1.4),
            borderRadius: BorderRadius.circular(Mixart.radiusLg),
          ),
          child: _escolhidos.isEmpty
              ? Text('Toque nos blocos abaixo para montar a frase', style: Mixart.ui(size: 13.5, color: Mixart.textFaint))
              : Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final id in _escolhidos)
                    Pastilha(key: Key('escolhido-$id'), texto: _blocos[id].texto, onTap: () => _soltarBloco(id)),
                ]),
        ),
        const SizedBox(height: 16),
        Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
          for (final b in _blocos)
            Pastilha(
              key: Key('bloco-${b.id}'),
              texto: b.texto,
              vazia: _escolhidos.contains(b.id),
              onTap: _escolhidos.contains(b.id) ? null : () => _pegarBloco(b.id),
            ),
        ]),
        const SizedBox(height: 16),
        Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          _botaoConferir(onPressed: _escolhidos.isEmpty ? null : _conferir),
          _botaoNaoSei(),
        ]),
      ]);

  Widget _notas(Map<Rating, int> prev, {required bool repeticao}) {
    String intervalo(Rating n) => repeticao ? 'nesta sessão' : rotuloIntervalo(prev[n] ?? 1);
    final s = _sugerida;
    final botoes = repeticao
        ? [
            _BotaoNota(const Key('nota-errei'), '1 · Ainda não', 'volta de novo', Mixart.danger, () => _nota(Rating.again),
                sugerido: s == Rating.again),
            _BotaoNota(const Key('nota-bom'), '3 · Lembrei', 'segue', Mixart.brand, () => _nota(Rating.good),
                sugerido: s != null && s != Rating.again),
          ]
        : [
            _BotaoNota(const Key('nota-errei'), '1 · Errei', intervalo(Rating.again), Mixart.danger, () => _nota(Rating.again),
                sugerido: s == Rating.again),
            _BotaoNota(const Key('nota-dificil'), '2 · Difícil', intervalo(Rating.hard), const Color(0xFFE0A030), () => _nota(Rating.hard),
                sugerido: s == Rating.hard),
            _BotaoNota(const Key('nota-bom'), '3 · Bom', intervalo(Rating.good), Mixart.brand, () => _nota(Rating.good),
                sugerido: s == Rating.good),
            _BotaoNota(const Key('nota-facil'), '4 · Fácil', intervalo(Rating.easy), const Color(0xFF4FC3F7), () => _nota(Rating.easy),
                sugerido: s == Rating.easy),
          ];
    return LayoutBuilder(builder: (context, caixa) {
      final colunas = caixa.maxWidth < 420 && botoes.length > 2 ? 2 : botoes.length;
      final largura = (caixa.maxWidth - 10 * (colunas - 1)) / colunas;
      return Wrap(spacing: 10, runSpacing: 10, children: [for (final b in botoes) SizedBox(width: largura, child: b)]);
    });
  }

  Widget _resumo() {
    int n(Rating r) => _resultados.where((x) => x.nota == r).length;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
      ),
      child: Column(children: [
        Text(_resultados.isEmpty ? 'Nada para revisar agora 🎉' : 'Pronto!', style: Mixart.display(size: 26, color: Mixart.brand)),
        const SizedBox(height: 14),
        if (_resultados.isNotEmpty)
          Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
            _Placar('🔁 ERREI', '${n(Rating.again)}'),
            _Placar('🟡 DIFÍCIL', '${n(Rating.hard)}'),
            _Placar('✅ BOM', '${n(Rating.good)}'),
            _Placar('⚡ FÁCIL', '${n(Rating.easy)}'),
          ]),
        const SizedBox(height: 18),
        FilledButton(
          key: const Key('continuar-cartoes'),
          style: FilledButton.styleFrom(
            backgroundColor: Mixart.brand,
            foregroundColor: Mixart.onBrand,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
          onPressed: () => _sair(seguir: true),
          child: Text('Continuar →', style: Mixart.ui(size: 13, weight: FontWeight.w800, color: Mixart.onBrand)),
        ),
      ]),
    );
  }
}

class _BotaoNota extends StatelessWidget {
  final String rotulo, intervalo;
  final Color cor;
  final VoidCallback onTap;

  /// A nota que a conferência da resposta escrita sugere: borda grossa e fundo mais forte.
  final bool sugerido;
  const _BotaoNota(Key key, this.rotulo, this.intervalo, this.cor, this.onTap, {this.sugerido = false}) : super(key: key);

  @override
  Widget build(BuildContext context) => InkWell(
        canRequestFocus: false,
        onTap: onTap,
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            color: cor.withValues(alpha: sugerido ? .24 : .10),
            border: Border.all(color: cor.withValues(alpha: sugerido ? 1 : .7), width: sugerido ? 2.4 : 1),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(rotulo, style: Mixart.ui(size: 13.5, weight: FontWeight.w800, color: cor)),
            const SizedBox(height: 2),
            Text(sugerido ? '$intervalo · sugerida' : intervalo, style: Mixart.ui(size: 11.5, color: Mixart.textMuted)),
          ]),
        ),
      );
}

class _Placar extends StatelessWidget {
  final String rotulo, valor;
  const _Placar(this.rotulo, this.valor);

  @override
  Widget build(BuildContext context) => Container(
        width: 118,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Mixart.surfaceHi,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Column(children: [
          Text(valor, style: Mixart.display(size: 24)),
          const SizedBox(height: 2),
          Text(rotulo, style: Mixart.ui(size: 10, weight: FontWeight.w800, color: Mixart.textMuted).copyWith(letterSpacing: .8)),
        ]),
      );
}

/// Uma opção de nível/sentido: pílula que acende quando é a escolhida.
class _Opcao extends StatelessWidget {
  final String texto, dica;
  final bool ativo;
  final VoidCallback onTap;
  const _Opcao({super.key, required this.texto, required this.dica, required this.ativo, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: dica,
        child: InkWell(
          canRequestFocus: false,
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: ativo ? Mixart.brand.withValues(alpha: .18) : Colors.transparent,
              border: Border.all(color: ativo ? Mixart.brand : Mixart.border, width: ativo ? 1.6 : 1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(texto, style: Mixart.ui(size: 12, weight: FontWeight.w800, color: ativo ? Mixart.brand : Mixart.textMuted)),
          ),
        ),
      );
}
