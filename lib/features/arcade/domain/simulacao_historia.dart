import '../../ingles/domain/expressao.dart';
import 'historia_turismo.dart';

/// 🎬 A simulação ÚNICA de uma cena da história: quem está onde, com que cara, segurando o quê, no carro,
/// sentado ou dormindo, que objetos estão no chão, clima, cenário e câmera. O [HistoriaTurismo.validar] usa
/// para checar as regras ao longo das falas; o player usa o estado antes/depois de cada passo para interpolar.

/// Um ator num instante da cena.
class EstadoAtor {
  final String quem;
  PosicaoPalco? pos;

  /// No palco (sempre false para o remoto, que fala pelo rádio/celular).
  bool visivel;
  final ViaRemota? remoto;
  Expressao emocao;
  PropHistoria? segura;
  bool noCarro, sentado, dormindo;

  /// O desenho olha para a esquerda (espelhado).
  bool olhaParaEsquerda;

  EstadoAtor({
    required this.quem,
    this.pos,
    this.visivel = true,
    this.remoto,
    this.emocao = Expressao.neutro,
    this.segura,
    this.noCarro = false,
    this.sentado = false,
    this.dormindo = false,
    this.olhaParaEsquerda = false,
  });

  bool get ehRemoto => remoto != null;

  /// Presente (não remoto) e visível.
  bool get noPalco => remoto == null && visivel;

  EstadoAtor copia() => EstadoAtor(
        quem: quem,
        pos: pos,
        visivel: visivel,
        remoto: remoto,
        emocao: emocao,
        segura: segura,
        noCarro: noCarro,
        sentado: sentado,
        dormindo: dormindo,
        olhaParaEsquerda: olhaParaEsquerda,
      );
}

/// Um objeto num instante da cena.
class EstadoObjeto {
  final PropHistoria prop;
  PosicaoPalco? pos;
  bool visivel;

  /// Id do ator que está dirigindo este carro (o objeto some enquanto ele dirige).
  String? absorvidoPor;

  EstadoObjeto({required this.prop, this.pos, this.visivel = true, this.absorvidoPor});

  EstadoObjeto copia() => EstadoObjeto(prop: prop, pos: pos, visivel: visivel, absorvidoPor: absorvidoPor);
}

/// O estado completo da cena num instante.
class EstadoCena {
  CenarioHistoria cenario;
  HoraHistoria hora;
  List<ClimaHistoria> clima;
  CameraHistoria camera;
  final Map<String, EstadoAtor> atores;
  final List<EstadoObjeto> objetos;

  EstadoCena({
    required this.cenario,
    required this.hora,
    required this.clima,
    this.camera = CameraHistoria.geral,
    required this.atores,
    required this.objetos,
  });

  /// O estado antes do 1º passo: o que a cena declara (câmera `geral`).
  factory EstadoCena.inicial(CenaHistoria c) => EstadoCena(
        cenario: c.cenario,
        hora: c.hora,
        clima: List.of(c.clima),
        atores: {
          for (final a in c.elenco)
            a.quem: EstadoAtor(
              quem: a.quem,
              pos: a.ehRemoto ? null : a.pos,
              visivel: !a.ehRemoto && a.visivel,
              remoto: a.remoto,
              emocao: a.emocao,
              segura: a.segura == PropHistoria.nada ? null : a.segura,
              noCarro: !a.ehRemoto && a.noCarro,
              olhaParaEsquerda: _olhaParaOCentro(a.pos),
            ),
        },
        objetos: [for (final o in c.objetos) EstadoObjeto(prop: o.prop, pos: o.pos, visivel: o.visivel)],
      );

  EstadoCena copia() => EstadoCena(
        cenario: cenario,
        hora: hora,
        clima: List.of(clima),
        camera: camera,
        atores: {for (final e in atores.entries) e.key: e.value.copia()},
        objetos: [for (final o in objetos) o.copia()],
      );

  /// Os atores no palco (presentes e visíveis).
  Iterable<EstadoAtor> get noPalco => atores.values.where((a) => a.noPalco);

  /// Os objetos visíveis com [prop].
  Iterable<EstadoObjeto> visiveis(PropHistoria prop) => objetos.where((o) => o.visivel && o.prop == prop);
}

/// Quem está à direita do centro olha para a esquerda (para o meio do palco).
bool _olhaParaOCentro(PosicaoPalco? p) => p != null && p.index > PosicaoPalco.centro.index;

/// O carro que o ator desenha quando dirige sem um objeto carro na posição dele (o Max é o rival).
PropHistoria _carroDe(String quem) => quem == 'max' ? PropHistoria.carroRival : PropHistoria.carro;

PropHistoria? _propDeNome(String nome) {
  for (final p in PropHistoria.values) {
    if (p.name == nome) return p;
  }
  return null;
}

abstract final class SimulacaoCena {
  /// Aplica o passo [f] a [antes] e devolve o estado no FIM do passo + os erros de regra do passo (sem prefixo).
  ///
  /// Ordem (seção 11.3 do plano): cenário/hora/clima → ação do falante → `segura` do falante → `emocao` do
  /// falante → `reacoes` (na ordem) → `objetos` (na ordem). Emoção, prop na mão, carro, sentado e dormindo
  /// persistem até mudar; a câmera também.
  static (EstadoCena depois, List<String> erros) aplicar(EstadoCena antes, FalaHistoria f) {
    final e = antes.copia();
    final erros = <String>[];
    final quem = f.quem;
    final narr = f.ehNarrador;
    final ator = narr ? null : e.atores[quem];

    // ── campos do passo
    if (f.mudo) {
      if (f.en != null || f.pt != null || f.ptF != null) erros.add('passo mudo não leva en/pt');
      if (narr || ator == null || ator.ehRemoto) erros.add('passo mudo exige um ator presente');
      if (f.acao == AcaoAtor.parado &&
          f.efeito == null &&
          f.emocao == null &&
          f.segura == null &&
          f.objetos.isEmpty &&
          f.reacoes.isEmpty) {
        erros.add('passo mudo sem nada acontecendo (acao, efeito, emocao, segura, objetos ou reacoes)');
      }
    } else {
      if ((f.en?.trim() ?? '').isEmpty) erros.add("'en' obrigatório (ou \"mudo\": true)");
      if ((f.pt?.trim() ?? '').isEmpty) erros.add("'pt' obrigatório (ou \"mudo\": true)");
    }
    if (f.ptF != null && f.pt == null) erros.add("'pt_f' só junto com 'pt'");
    if (!narr && ator == null) erros.add("'$quem' não está no elenco da cena");

    // ── 1. cenário / hora / clima
    if (f.cenario != null) e.cenario = f.cenario!;
    if (f.hora != null) e.hora = f.hora!;
    final novoClima = f.clima;
    if (novoClima != null) {
      if (novoClima.toSet().length != novoClima.length) erros.add('clima repetido');
      e.clima = List.of(novoClima);
    }
    if (f.cenario != null || f.hora != null || novoClima != null) {
      if (!horasPermitidas(e.cenario).contains(e.hora)) {
        erros.add("hora '${e.hora.name}' não combina com '${e.cenario.name}'");
      }
      for (final cl in e.clima) {
        if (!climaPermitido(cl, e.cenario, e.hora)) {
          erros.add("clima '${cl.name}' não combina com '${e.cenario.name}'/'${e.hora.name}'");
        }
      }
    }
    if (f.camera != null) e.camera = f.camera!;

    // ── quem fala pode falar?
    if (narr) {
      if (f.acao != AcaoAtor.parado) erros.add('o narrador não faz ação');
      if (f.segura != null) erros.add('o narrador não segura nada');
    } else if (ator != null) {
      if (ator.ehRemoto) {
        if (f.acao != AcaoAtor.parado) erros.add("'$quem' é remoto: só acao parado");
        if (f.segura != null) erros.add("'$quem' é remoto: não segura nada");
        final ancora = ator.remoto == ViaRemota.radio
            ? e.noPalco.any((a) => a.segura == PropHistoria.radio || a.noCarro)
            : e.noPalco.any((a) => a.segura == PropHistoria.celular);
        if (!ancora) {
          erros.add(ator.remoto == ViaRemota.radio
              ? "'$quem' fala pelo rádio, mas ninguém no palco segura radio nem está no carro"
              : "'$quem' fala pelo celular, mas ninguém no palco segura celular");
        }
      } else if (!ator.visivel && f.acao != AcaoAtor.entra) {
        erros.add("'$quem' não está visível (use acao entra)");
      }
    }

    // ── alvo e para
    final alvo = f.alvo;
    PosicaoPalco? posAlvo;
    var alvoEhAtor = false, alvoEhProp = false;
    if (alvo != null) {
      final a = e.atores[alvo];
      if (a != null) {
        alvoEhAtor = true;
        if (!a.noPalco || alvo == quem) erros.add("alvo '$alvo' tem de ser outro ator presente e visível");
        posAlvo = a.pos;
      } else {
        final prop = _propDeNome(alvo);
        final objs = prop == null ? const <EstadoObjeto>[] : e.visiveis(prop).toList();
        if (objs.isEmpty) {
          erros.add("alvo '$alvo' não é ator presente nem objeto visível");
        } else {
          alvoEhProp = true;
          posAlvo = objs.first.pos;
        }
      }
    }
    if ((f.acao == AcaoAtor.abraca || f.acao == AcaoAtor.arremessa || f.acao == AcaoAtor.olha) && alvo == null) {
      erros.add("acao '${f.acao.name}' exige alvo");
    }
    if (f.camera == CameraHistoria.dupla && !alvoEhAtor) erros.add('camera dupla exige alvo ator');
    final desloca = f.acao == AcaoAtor.anda || f.acao == AcaoAtor.corre;
    if (desloca && f.para == null) erros.add("acao '${f.acao.name}' exige para");
    if (f.para != null && !desloca && f.acao != AcaoAtor.entra) erros.add("'para' só em anda, corre ou entra");

    // ── 2. ação do falante
    if (ator != null && !ator.ehRemoto) {
      final seguraNoPasso = f.segura != null && f.segura != PropHistoria.nada;
      switch (f.acao) {
        case AcaoAtor.entra:
          if (ator.visivel) erros.add("'$quem' já está visível (entra)");
          ator.visivel = true;
          if (f.para != null) ator.pos = f.para;
          ator.olhaParaEsquerda = _olhaParaOCentro(ator.pos);
        case AcaoAtor.sai:
          if (!ator.visivel) erros.add("'$quem' já saiu (sai)");
          ator.visivel = false;
          ator.noCarro = false;
        case AcaoAtor.anda || AcaoAtor.corre:
          final para = f.para;
          if (para != null) {
            final de = ator.pos;
            if (de != null && para != de) ator.olhaParaEsquerda = para.index < de.index;
            ator.pos = para;
          }
        case AcaoAtor.dirige:
          if (ator.noCarro) {
            erros.add("'$quem' já está no carro (dirige)");
          } else {
            ator.noCarro = true;
            for (final o in e.objetos) {
              if (o.visivel &&
                  o.pos == ator.pos &&
                  (o.prop == PropHistoria.carro || o.prop == PropHistoria.carroRival)) {
                o.visivel = false;
                o.absorvidoPor = quem;
                break;
              }
            }
          }
        case AcaoAtor.desce:
          if (!ator.noCarro) {
            erros.add("'$quem' não está no carro (desce)");
          } else {
            ator.noCarro = false;
            final o = e.objetos.where((o) => o.absorvidoPor == quem).firstOrNull;
            if (o != null) {
              o
                ..absorvidoPor = null
                ..visivel = true
                ..pos = ator.pos;
            } else {
              e.objetos.add(EstadoObjeto(prop: _carroDe(quem), pos: ator.pos));
            }
          }
        case AcaoAtor.mostra:
          if (ator.segura == null && !seguraNoPasso) erros.add("'$quem' mostra sem nada na mão");
        case AcaoAtor.escreve:
          if (ator.segura == null && !seguraNoPasso && !alvoEhProp) {
            erros.add("'$quem' escreve sem prop na mão nem alvo objeto");
          }
        default:
          break;
      }
      _estadosDaAcao(ator, f.acao);
      final pa = posAlvo, pd = ator.pos;
      if (pa != null && pd != null && pa != pd && !desloca && f.acao != AcaoAtor.entra) {
        ator.olhaParaEsquerda = pa.index < pd.index;
      }
    }

    // ── 3. segura e 4. emoção do falante
    if (ator != null && !ator.ehRemoto && f.segura != null) {
      ator.segura = f.segura == PropHistoria.nada ? null : f.segura;
    }
    if (ator != null && f.emocao != null) ator.emocao = f.emocao!;

    // ── 5. reações
    if (f.reacoes.length > 4) erros.add('${f.reacoes.length} reações (máx. 4)');
    for (final r in f.reacoes) {
      final ra = e.atores[r.quem];
      if (ra == null) {
        erros.add("reação de '${r.quem}', que não está no elenco");
        continue;
      }
      if (r.quem == quem) erros.add("'${r.quem}' não reage à própria fala");
      if (r.emocao == null && r.acao == null && r.efeito == null && r.segura == null) {
        erros.add("reação de '${r.quem}' vazia");
      }
      if (ra.ehRemoto) {
        if (r.acao != null || r.efeito != null || r.segura != null) {
          erros.add("'${r.quem}' é remoto: a reação só leva emocao");
        }
        if (r.emocao != null) ra.emocao = r.emocao!;
        continue;
      }
      if (!ra.visivel) erros.add("reação de '${r.quem}', que não está visível");
      if (r.segura != null) ra.segura = r.segura == PropHistoria.nada ? null : r.segura;
      final acao = r.acao;
      if (acao != null) {
        if (!acoesDeReacao.contains(acao)) {
          erros.add("acao '${acao.name}' não vale numa reação");
        } else {
          if ((acao == AcaoAtor.mostra || acao == AcaoAtor.escreve) && ra.segura == null) {
            erros.add("reação '${acao.name}' de '${r.quem}' sem nada na mão");
          }
          _estadosDaAcao(ra, acao);
          final pf = ator?.pos, pr = ra.pos;
          if (acao == AcaoAtor.olha && pf != null && pr != null && pf != pr) {
            ra.olhaParaEsquerda = pf.index < pr.index;
          }
        }
      }
      if (r.emocao != null) ra.emocao = r.emocao!;
    }

    // ── 6. objetos
    if (f.objetos.length > 3) erros.add('${f.objetos.length} movimentos de objeto (máx. 3)');
    for (final m in f.objetos) {
      _movimento(e, m, erros);
    }

    // ── posições únicas depois do passo
    final ocupadas = <PosicaoPalco>{};
    for (final a in e.noPalco) {
      final p = a.pos;
      if (p != null && !ocupadas.add(p)) erros.add("dois atores em '${p.name}'");
    }
    final ocupadasObj = <PosicaoPalco>{};
    for (final o in e.objetos.where((o) => o.visivel)) {
      final p = o.pos;
      if (p != null && !ocupadasObj.add(p)) erros.add("dois objetos em '${p.name}'");
    }
    return (e, erros);
  }

  /// Estados antes de cada passo (length = falas.length + 1). O player interpola entre [i] e [i+1].
  static List<EstadoCena> linhaDoTempo(CenaHistoria c) {
    final r = [EstadoCena.inicial(c)];
    for (final f in c.falas) {
      r.add(aplicar(r.last, f).$1);
    }
    return r;
  }

  /// Duração base da ação (tabela 5.3), em segundos; null = dura a fala.
  static double? duracaoDe(AcaoAtor a) => switch (a) {
        AcaoAtor.acena => 1.2,
        AcaoAtor.pula => .6,
        AcaoAtor.comemora => 1.4,
        AcaoAtor.entra || AcaoAtor.sai || AcaoAtor.anda => .9,
        AcaoAtor.corre => .5,
        AcaoAtor.cai => 1.2,
        AcaoAtor.abraca => 1.0,
        AcaoAtor.palmas => 1.0,
        AcaoAtor.concorda || AcaoAtor.nega => .9,
        AcaoAtor.mostra => 1.0,
        AcaoAtor.dirige => .5,
        AcaoAtor.desce => .6,
        AcaoAtor.olha => .3,
        AcaoAtor.arremessa => .7,
        AcaoAtor.rodopia => .8,
        AcaoAtor.senta => .5,
        AcaoAtor.parado ||
        AcaoAtor.aponta ||
        AcaoAtor.danca ||
        AcaoAtor.treme ||
        AcaoAtor.pensa ||
        AcaoAtor.escreve ||
        AcaoAtor.dorme =>
          null,
      };

  /// Sentado e dormindo: `senta` senta até pular/comemorar/andar/correr/sair/entrar/dançar; `dorme` dorme até
  /// a próxima ação diferente de parado/dorme.
  static void _estadosDaAcao(EstadoAtor a, AcaoAtor acao) {
    if (acao == AcaoAtor.senta) a.sentado = true;
    if (acao == AcaoAtor.pula ||
        acao == AcaoAtor.comemora ||
        acao == AcaoAtor.anda ||
        acao == AcaoAtor.corre ||
        acao == AcaoAtor.sai ||
        acao == AcaoAtor.entra ||
        acao == AcaoAtor.danca) {
      a.sentado = false;
    }
    if (acao == AcaoAtor.dorme) {
      a.dormindo = true;
    } else if (acao != AcaoAtor.parado) {
      a.dormindo = false;
    }
  }

  static void _movimento(EstadoCena e, MovimentoObjeto m, List<String> erros) {
    final nome = "'${m.prop.name}' (${m.acao.name})";
    if (m.prop == PropHistoria.nada) erros.add("objeto 'nada' não se mexe");
    final precisaPos = m.acao == AcaoObjeto.aparece || m.acao == AcaoObjeto.entra;
    if (precisaPos && m.pos == null) erros.add('$nome exige pos');
    if (m.acao == AcaoObjeto.passa && m.pos != null) erros.add('$nome não leva pos');
    EstadoAtor? dono;
    final de = m.de;
    if (de != null) {
      final a = e.atores[de];
      if (a == null || !a.noPalco) {
        erros.add("$nome: de '$de' tem de ser um ator presente e visível");
      } else if (a.segura != m.prop) {
        erros.add("$nome: '$de' não segura '${m.prop.name}'");
      } else {
        dono = a;
        a.segura = null;
      }
    }
    switch (m.acao) {
      case AcaoObjeto.aparece || AcaoObjeto.entra:
        final pos = m.pos;
        if (pos == null) break;
        final guardado = de != null
            ? null
            : e.objetos.where((o) => !o.visivel && o.absorvidoPor == null && o.prop == m.prop).firstOrNull;
        if (guardado != null) {
          guardado
            ..visivel = true
            ..pos = pos;
        } else {
          e.objetos.add(EstadoObjeto(prop: m.prop, pos: pos));
        }
      case AcaoObjeto.passa:
        break; // cruza a tela e some: o estado não muda
      case AcaoObjeto.some || AcaoObjeto.sai || AcaoObjeto.voa:
        if (de != null) break; // sai da mão e vai embora
        final alvos = e.visiveis(m.prop).toList();
        if (alvos.length != 1) {
          erros.add('$nome: precisa de exatamente 1 objeto visível com esse prop (há ${alvos.length})');
        } else {
          alvos.first.visivel = false;
        }
      case AcaoObjeto.roda || AcaoObjeto.treme:
        if (de != null) {
          // sai da mão e fica no chão (na pos pedida ou aos pés de quem segurava)
          if (dono != null) e.objetos.add(EstadoObjeto(prop: m.prop, pos: m.pos ?? dono.pos));
          break;
        }
        final n = e.visiveis(m.prop).length;
        if (n != 1) erros.add('$nome: precisa de exatamente 1 objeto visível com esse prop (há $n)');
    }
  }
}
