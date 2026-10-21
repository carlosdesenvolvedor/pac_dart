import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../ingles/data/reconhecedor_fala.dart';
import '../../ingles/presentation/widgets/painel_shadowing.dart' show PainelShadowingState;

/// Onde o modo mãos-livres da Conversa está:
/// desligado → ocioso → ouvindo → enviando → personagemFalando → ouvindo → …
enum EstadoMaosLivres {
  /// O modo está desligado (o 🎤 escreve no campo, como sempre).
  desligado,

  /// Ligado, microfone fechado, esperando o aluno (toque/segure o 🎤) ou a vez dele.
  ocioso,

  /// Microfone aberto: segurando o 🎤, ou aberto sozinho na vez do aluno.
  ouvindo,

  /// O que o aluno disse foi enviado; esperando a resposta do personagem.
  enviando,

  /// A voz do personagem está soando (o microfone NUNCA abre aqui: eco).
  personagemFalando,
}

/// A máquina de estados do mãos-livres, sem widget (testável com fakes). A `ConversaPage` liga os
/// eventos (segurar/soltar o 🎤, resposta chegou, fala terminou, sair/pausar/resumo/descanso/fim) e
/// redesenha com o [ChangeNotifier].
///
/// - Segurar o 🎤 abre o microfone; soltar envia o que foi reconhecido (vazio → [recadoNaoOuvi]). O
///   reconhecedor do navegador fecha sozinho a cada frase: com o dedo ainda no 🎤 ele reabre e o que vier soma.
/// - Um TOQUE (soltar antes de [toqueCurto]) abre a vez: ouve até um resultado final seguido de
///   [silencioParaEnviar] e envia sozinho; nada dito em [esperaSemFala] → fecha ([recadoToque]).
/// - Depois da fala do personagem ([personagemFala], que espera o fim REAL da voz), a vez abre sozinha.
class ControladorMaosLivres extends ChangeNotifier {
  final ReconhecedorFala reconhecedor;

  /// Envia o texto reconhecido (não vazio) como fala do aluno.
  final void Function(String texto) enviar;

  /// Cala o app antes de abrir o microfone (`voz.calarTudo`).
  final Future<void> Function()? antesDeOuvir;

  /// A vez pode abrir sozinha agora? (a conversa está livre, a página à vista, nenhuma voz soando…)
  /// null = sempre. Só vale para a abertura automática: segurar o 🎤 é escolha do aluno.
  final bool Function()? podeAbrirSozinho;

  /// O 🎤 pode abrir agora (a conversa pode receber uma fala: nem esperando a resposta, nem na janela de
  /// descanso)? null = sempre. Sem poder, segurar não grava nada (a fala se perderia).
  final bool Function()? podeSegurar;

  /// Silêncio depois de um resultado final para enviar sozinho (na vez aberta sozinha).
  final Duration silencioParaEnviar;

  /// Sem nada dito nesse tempo, a vez fecha o microfone ("Toque no 🎤 para falar").
  final Duration esperaSemFala;

  /// Soltar o 🎤 antes disso é um toque (abre a vez), não um "segurar e falar".
  final Duration toqueCurto;

  /// Depois de soltar, quanto esperar o navegador entregar o fim antes de fechar à força (com o que já ouviu).
  final Duration esperaParar;

  /// Cria os timers (injetável nos testes; padrão: [Timer.new]).
  final Timer Function(Duration, void Function()) criarTimer;

  static const recadoSuaVez = 'Sua vez… fale em inglês';
  static const recadoNaoOuvi = 'Não ouvi nada — tente de novo';
  static const recadoToque = 'Toque no 🎤 para falar';
  static const recadoNoCampo = 'Sua fala ficou no campo — envie quando der';

  /// Quantas vezes o microfone reabre com o dedo no 🎤 (rede contra um navegador que fecha na hora).
  static const maxReaberturas = 6;

  ControladorMaosLivres({
    required this.reconhecedor,
    required this.enviar,
    this.antesDeOuvir,
    this.podeAbrirSozinho,
    this.podeSegurar,
    this.silencioParaEnviar = const Duration(milliseconds: 1500),
    this.esperaSemFala = const Duration(seconds: 8),
    this.toqueCurto = const Duration(milliseconds: 400),
    this.esperaParar = const Duration(seconds: 2),
    Timer Function(Duration, void Function())? criarTimer,
  }) : criarTimer = criarTimer ?? Timer.new;

  EstadoMaosLivres _estado = EstadoMaosLivres.desligado;
  EstadoMaosLivres get estado => _estado;

  /// O recado da vez ('' = nenhum).
  String _recado = '';
  String get recado => _recado;

  /// O que está sendo ouvido agora ('' fora da escuta).
  String _parcial = '';
  String get parcial => _parcial;

  /// O motivo de o microfone não servir (sem permissão/microfone), descoberto numa escuta; null = serve.
  String? _bloqueio;

  /// Há reconhecimento de voz neste aparelho (senão o item do menu fica desabilitado).
  bool get disponivel => reconhecedor.suportado && _bloqueio == null;

  /// Por que o mãos-livres não liga ('' quando liga).
  String get motivoIndisponivel {
    if (!reconhecedor.suportado) return 'Sem reconhecimento de voz neste navegador (no computador, use o Chrome ou o Edge).';
    return _bloqueio ?? '';
  }

  bool get ligado => _estado != EstadoMaosLivres.desligado;

  /// O dedo está no 🎤 (soltar envia); false na vez aberta sozinha.
  bool get segurando => _segurando;

  /// Muda estado/recado/parcial e avisa a tela (só se algo mudou).
  @protected
  void mudar(EstadoMaosLivres estado, {String? recado, String? parcial}) {
    if (_descartado) return;
    final r = recado ?? _recado, p = parcial ?? _parcial;
    if (estado == _estado && r == _recado && p == _parcial) return;
    _estado = estado;
    _recado = r;
    _parcial = p;
    notifyListeners();
  }

  // ── a escuta ─────────────────────────────────────────────────────────────

  SessaoFala? _escuta;

  /// Cada escuta tem uma "vez": o que chega de uma escuta velha é ignorado.
  int _vez = 0;

  /// Cada fala do personagem esperada: segurar/pausar/desligar invalidam a abertura depois dela.
  int _vezFala = 0;

  bool _segurando = false;

  /// Soltou o 🎤 e o navegador ainda não entregou o fim (o [_tForca] fecha à força).
  bool _soltou = false;

  /// Os resultados finais desta vez (as frases que o navegador fechou somam).
  String _ouvido = '';

  /// O erro da escuta atual (o aoFim decide com ele).
  ErroFala? _erro;
  int _reaberturas = 0;
  bool _descartado = false;

  /// [_tFala]: o limite da espera pela voz do personagem ([personagemFala]).
  Timer? _tSilencio, _tSemFala, _tToque, _tForca, _tFala;

  void _cancelarTimers() {
    _tSilencio?.cancel();
    _tSemFala?.cancel();
    _tToque?.cancel();
    _tForca?.cancel();
    _tFala?.cancel();
    _tSilencio = _tSemFala = _tToque = _tForca = _tFala = null;
  }

  /// Desiste da escuta em curso (nada mais dela vale).
  void _cancelarEscuta() {
    _vez++;
    final e = _escuta;
    _escuta = null;
    _segurando = false;
    _soltou = false;
    try {
      e?.cancelar();
    } catch (_) {}
  }

  void _fecharTudo() {
    _vezFala++;
    _cancelarTimers();
    _cancelarEscuta();
    _ouvido = '';
  }

  static String _juntar(String a, String b) => a.isEmpty ? b : (b.isEmpty ? a : '$a $b');

  /// Abre o microfone para uma vez nova (segurando ou aberta sozinha).
  void _abrir({required bool segurando}) {
    _cancelarTimers();
    _cancelarEscuta();
    _segurando = segurando;
    _ouvido = '';
    _reaberturas = 0;
    mudar(EstadoMaosLivres.ouvindo, recado: segurando ? '' : recadoSuaVez, parcial: '');
    // cala o app ANTES de abrir (senão o microfone ouve o personagem). Sem await: o microfone abre no mesmo
    // toque (regra do navegador); a parte que cala é síncrona.
    try {
      final f = antesDeOuvir?.call();
      if (f != null) unawaited(f.catchError((Object _) {}));
    } catch (_) {}
    _ouvir();
    if (!segurando) _armarSemFala();
  }

  /// Uma escuta do reconhecedor (os finais somam em [_ouvido]).
  void _ouvir() {
    final vez = ++_vez;
    _erro = null;
    var acabou = false;
    SessaoFala? s;
    try {
      s = reconhecedor.ouvir(
        idioma: 'en-US',
        aoParcial: (t) {
          if (vez != _vez || _descartado) return;
          // a escuta ouviu algo: o limite de reaberturas é contra o navegador que fecha na hora, não contra a fala longa
          _reaberturas = 0;
          _tSemFala?.cancel();
          _tSemFala = null;
          _tSilencio?.cancel();
          _tSilencio = null;
          mudar(EstadoMaosLivres.ouvindo, parcial: _juntar(_ouvido, t.trim()));
        },
        aoFinal: (hipoteses) {
          if (vez != _vez || _descartado) return;
          final t = hipoteses.isEmpty ? '' : hipoteses.first.trim();
          if (t.isEmpty) return;
          _reaberturas = 0;
          _ouvido = _juntar(_ouvido, t);
          _tSemFala?.cancel();
          _tSemFala = null;
          mudar(EstadoMaosLivres.ouvindo, parcial: _ouvido);
          if (!_segurando && !_soltou) _armarSilencio();
        },
        aoErro: (e) {
          if (vez == _vez) _erro = e;
        },
        aoFim: () {
          acabou = true;
          if (vez != _vez || _descartado) return;
          _escuta = null;
          _aoFimDaEscuta();
        },
      );
    } catch (_) {
      if (vez != _vez) return;
      _erro = ErroFala.outro;
      acabou = true;
      _aoFimDaEscuta();
      return;
    }
    // o reconhecedor pode ter acabado dentro do próprio ouvir (sem suporte): aí não há escuta a guardar
    if (!acabou && vez == _vez) _escuta = s;
  }

  void _aoFimDaEscuta() {
    _tForca?.cancel();
    _tForca = null;
    final erro = _erro;
    if (erro != null && PainelShadowingState.semSaida(erro)) {
      // sem permissão/microfone/suporte: insistir não adianta — o modo desliga e o menu mostra o motivo
      final texto = PainelShadowingState.textoDoErro(erro);
      _bloqueio = texto;
      _fecharTudo();
      mudar(EstadoMaosLivres.desligado, recado: texto, parcial: '');
      return;
    }
    if (_soltou) {
      _soltou = false;
      _concluir();
      return;
    }
    // o reconhecedor fecha a cada pausa (continuous=false): dá para reabrir se nada deu errado e o navegador
    // não está fechando na hora, vez após vez, sem ouvir nada
    final reabre = (erro == null || erro == ErroFala.naoOuviu) && _reaberturas < maxReaberturas;
    if (_segurando) {
      // o navegador fechou a frase com o dedo ainda no 🎤: continua ouvindo (o que vier soma)
      if (reabre) {
        _reaberturas++;
        _ouvir();
        return;
      }
      // sem reabrir (sem rede, ou o navegador fecha na hora): a tela não finge que ouve — fecha com o que ouviu
      _concluir();
      return;
    }
    if (_estado != EstadoMaosLivres.ouvindo) return;
    // a vez aberta sozinha: com algo ouvido, o silêncio envia — e o microfone segue aberto nesse tempo (o
    // resto da frase, depois de uma pausa, soma e adia o envio)
    if (_ouvido.isNotEmpty) {
      _tSilencio ??= criarTimer(silencioParaEnviar, _silencioAcabou);
      if (reabre) {
        _reaberturas++;
        _ouvir();
      }
      return;
    }
    _cancelarTimers();
    mudar(EstadoMaosLivres.ocioso,
        recado: erro == ErroFala.semRede ? PainelShadowingState.textoDoErro(erro!) : recadoToque, parcial: '');
  }

  void _armarSilencio() {
    _tSilencio?.cancel();
    _tSilencio = criarTimer(silencioParaEnviar, _silencioAcabou);
  }

  void _silencioAcabou() {
    _tSilencio = null;
    if (_estado != EstadoMaosLivres.ouvindo || _segurando || _soltou) return;
    final ouvido = _ouvido;
    _cancelarEscuta();
    _ouvido = ouvido;
    _concluir();
  }

  void _armarSemFala() {
    _tSemFala?.cancel();
    _tSemFala = criarTimer(esperaSemFala, () {
      _tSemFala = null;
      if (_estado != EstadoMaosLivres.ouvindo || _segurando || _ouvido.isNotEmpty) return;
      _cancelarTimers();
      _cancelarEscuta();
      mudar(EstadoMaosLivres.ocioso, recado: recadoToque, parcial: '');
    });
  }

  /// Fecha a vez: envia o que ouviu, ou avisa que não ouviu nada.
  void _concluir() {
    _cancelarTimers();
    final t = _ouvido.trim();
    _ouvido = '';
    _segurando = false;
    _soltou = false;
    if (t.isEmpty) {
      final erro = _erro;
      mudar(EstadoMaosLivres.ocioso,
          recado: erro == ErroFala.semRede ? PainelShadowingState.textoDoErro(erro!) : recadoNaoOuvi, parcial: '');
      return;
    }
    mudar(EstadoMaosLivres.enviando, recado: '', parcial: '');
    enviar(t);
  }

  // ── os eventos da tela ───────────────────────────────────────────────────

  /// Liga o modo (vai a [EstadoMaosLivres.ocioso]). Sem reconhecimento de voz, nada muda.
  void ligar() {
    if (ligado || !disponivel) return;
    mudar(EstadoMaosLivres.ocioso, recado: '', parcial: '');
  }

  /// Desliga e fecha o microfone (nada é enviado).
  void desligar() {
    _fecharTudo();
    mudar(EstadoMaosLivres.desligado, recado: '', parcial: '');
  }

  /// Some com o recado (a tela já mostrou ou a pessoa mexeu no campo).
  void limparRecado() => mudar(_estado, recado: '');

  /// Apertou e segurou o 🎤: abre o microfone.
  void segurar() {
    if (!ligado || _estado == EstadoMaosLivres.enviando) return;
    // a conversa não recebe fala agora (esperando a resposta, janela de descanso): não grava o que se perderia
    try {
      if (podeSegurar?.call() == false) return;
    } catch (_) {
      return;
    }
    if (_estado == EstadoMaosLivres.ouvindo) {
      // a vez já estava aberta (sozinha): vira "segurar" — soltar envia o que ouviu
      if (_segurando) return;
      _tSilencio?.cancel();
      _tSemFala?.cancel();
      _tSilencio = _tSemFala = null;
      _segurando = true;
      _soltou = false;
      if (_escuta == null) _ouvir();
      mudar(EstadoMaosLivres.ouvindo, recado: '');
      // um toque (ou o leitor de tela/teclado) não fecha a vez: sem nada ouvido, ela segue aberta
      _tToque?.cancel();
      _tToque = criarTimer(toqueCurto, () => _tToque = null);
      return;
    }
    // a fala que ainda soava não abre a vez depois (o 🎤 cala o app)
    _vezFala++;
    _abrir(segurando: true);
    _tToque = criarTimer(toqueCurto, () => _tToque = null);
  }

  /// Soltou o 🎤: para de ouvir e envia o que foi reconhecido (vazio → [recadoNaoOuvi]). Soltar logo
  /// (um toque) sem nada ouvido abre a vez (ou a mantém aberta): ela envia sozinha depois do silêncio.
  void soltar() {
    if (_estado != EstadoMaosLivres.ouvindo || !_segurando) return;
    final toque = _tToque;
    if (toque != null && toque.isActive && _ouvido.isEmpty) {
      toque.cancel();
      _tToque = null;
      _segurando = false;
      mudar(EstadoMaosLivres.ouvindo, recado: recadoSuaVez);
      if (_escuta == null) _ouvir();
      _armarSemFala();
      return;
    }
    _tToque?.cancel();
    _tToque = null;
    _segurando = false;
    final e = _escuta;
    if (e == null) {
      _concluir();
      return;
    }
    // pede o fim ao navegador (ele entrega o que ouviu e fecha); sem resposta, fecha à força
    _soltou = true;
    try {
      e.parar();
    } catch (_) {}
    _tForca?.cancel();
    _tForca = criarTimer(esperaParar, () {
      _tForca = null;
      if (!_soltou) return;
      final ouvido = _ouvido;
      _cancelarEscuta();
      _ouvido = ouvido;
      _concluir();
    });
  }

  /// O ⏹: fecha o microfone da vez aberta sozinha sem enviar.
  void parar() {
    if (_estado != EstadoMaosLivres.ouvindo) return;
    _cancelarTimers();
    _cancelarEscuta();
    _ouvido = '';
    mudar(EstadoMaosLivres.ocioso, recado: recadoToque, parcial: '');
  }

  /// A resposta do personagem chegou e [fala] é a voz dela (completa quando a voz ACABA, ex.:
  /// `VozIngles.falar`); null = sem voz (voz automática desligada). No fim, abre a vez do aluno.
  /// Com o aluno já falando (segurando o 🎤) nada muda.
  ///
  /// [limite]: o máximo a esperar a voz (o Chrome às vezes nunca avisa o fim de uma fala longa). Passou dele,
  /// o app é calado ([antesDeOuvir]) e a vez abre como se a voz tivesse acabado. null = espera o fim sempre.
  Future<void> personagemFala(Future<void>? fala, {Duration? limite}) async {
    if (!ligado || _estado == EstadoMaosLivres.ouvindo) return;
    final g = ++_vezFala;
    _cancelarTimers();
    _cancelarEscuta();
    mudar(EstadoMaosLivres.personagemFalando, recado: '', parcial: '');
    if (fala != null) {
      final fim = Completer<void>();
      var passou = false;
      Timer? t;
      if (limite != null) {
        t = _tFala = criarTimer(limite, () {
          passou = true;
          if (!fim.isCompleted) fim.complete();
        });
      }
      unawaited(fala.then((_) {}, onError: (Object _) {}).whenComplete(() {
        if (!fim.isCompleted) fim.complete();
      }));
      await fim.future;
      t?.cancel();
      if (identical(_tFala, t)) _tFala = null;
      if (passou && !_descartado && g == _vezFala && _estado == EstadoMaosLivres.personagemFalando) {
        // a voz não avisou o fim: cala o que restar (o microfone não pode ouvir o personagem)
        try {
          await antesDeOuvir?.call();
        } catch (_) {}
      }
    }
    if (_descartado || g != _vezFala || _estado != EstadoMaosLivres.personagemFalando) return;
    var pode = true;
    try {
      pode = podeAbrirSozinho?.call() ?? true;
    } catch (_) {
      pode = false;
    }
    if (!pode) {
      mudar(EstadoMaosLivres.ocioso, recado: recadoToque, parcial: '');
      return;
    }
    _abrir(segurando: false);
  }

  /// O turno falhou (o texto volta ao campo): sai de [EstadoMaosLivres.enviando] para o ocioso, com [recado].
  void turnoFalhou({String recado = ''}) {
    if (_estado != EstadoMaosLivres.enviando) return;
    mudar(EstadoMaosLivres.ocioso, recado: recado, parcial: '');
  }

  /// Sair da página, pausar, abrir o resumo, janela de descanso ou conversa acabou: fecha tudo e fica
  /// ocioso (ligado, sem abrir o microfone sozinho até a próxima fala do personagem).
  void pausar() {
    if (!ligado) return;
    _fecharTudo();
    mudar(EstadoMaosLivres.ocioso, recado: '', parcial: '');
  }

  @override
  void dispose() {
    _fecharTudo();
    _descartado = true;
    super.dispose();
  }
}
