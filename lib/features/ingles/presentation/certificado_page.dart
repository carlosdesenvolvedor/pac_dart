import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/mixart.dart';
import '../../../core/util/abrir_url.dart';
import '../../../core/util/salvar_texto.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../curso/domain/curriculo.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../../habito/presentation/habito_cubit.dart';
import '../data/aulas_repo.dart';
import '../data/certificado_pdf.dart';
import '../data/certificados_repository.dart';
import '../data/site_do_app.dart';
import '../domain/certificado.dart';
import '../domain/revisao.dart';
import '../domain/revisao_mista.dart';
import 'revisao_mista_page.dart';
import 'widgets/frase_view.dart';

/// 🎓 Onde o app guarda os certificados (Firestore; em memória sem Firebase). [paraTestes] troca.
abstract final class Certificados {
  static CertificadosRepository? paraTestes;
  static CertificadosRepository? _padrao;
  static CertificadosRepository get repo =>
      paraTestes ??
      (_padrao ??= Firebase.apps.isNotEmpty ? FirestoreCertificadosRepository() : MemoriaCertificadosRepository());

  /// O teste do EF SET (gratuito, padronizado): a sugestão de prova EXTERNA no fim do curso.
  static const efSet = 'https://www.efset.org/pt/';
}

/// O que fica no aparelho: o nome do aluno (para preencher da próxima vez), o código de cada nível emitido e a
/// hora da última reprovação de cada nível (a espera de [esperaDepoisDeReprovar]).
abstract final class PrefsCertificado {
  static const chaveNome = 'en_cert_nome';
  static String chaveCodigo(String nivel) => 'en_cert_codigo_$nivel';
  static String chaveReprovou(String nivel) => 'en_cert_reprovou_$nivel';

  static Future<SharedPreferences?> _p() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  static Future<String?> nome() async => (await _p())?.getString(chaveNome);
  static Future<String?> codigo(String nivel) async => (await _p())?.getString(chaveCodigo(nivel));

  static Future<void> guardar({required String nivel, required String codigo, required String nome}) async {
    final p = await _p();
    await p?.setString(chaveCodigo(nivel), codigo);
    await p?.setString(chaveNome, nome);
  }

  /// Até quando a prova do [nivel] está em espera (null = pode fazer).
  static Future<DateTime?> esperaAte(String nivel, {DateTime? agora}) async {
    final v = (await _p())?.getInt(chaveReprovou(nivel));
    if (v == null) return null;
    final ate = DateTime.fromMillisecondsSinceEpoch(v).add(esperaDepoisDeReprovar);
    return ate.isAfter(agora ?? DateTime.now()) ? ate : null;
  }

  static Future<void> reprovou(String nivel, {DateTime? agora}) async =>
      (await _p())?.setInt(chaveReprovou(nivel), (agora ?? DateTime.now()).millisecondsSinceEpoch);
}

/// O certificado já emitido do [nivel] para a conta [uid]: o código guardado no aparelho, senão o Firestore.
Future<Certificado?> certificadoEmitido(String uid, String nivel) async {
  try {
    final repo = Certificados.repo;
    final cod = await PrefsCertificado.codigo(nivel);
    if (cod != null) {
      final c = await repo.buscar(cod);
      if (c != null && c.uid == uid) return c;
    }
    for (final c in await repo.daConta(uid)) {
      if (c.nivel == nivel) return c;
    }
  } catch (_) {}
  return null;
}

/// O cartão "🎓 Certificado do nível" no fim de cada nível do mapa: o que falta, a prova ou o certificado.
class CartaoCertificado extends StatefulWidget {
  final CursoState st;
  final NivelCertificado nivel;
  const CartaoCertificado({super.key, required this.st, required this.nivel});

  @override
  State<CartaoCertificado> createState() => _CartaoCertificadoState();
}

class _CartaoCertificadoState extends State<CartaoCertificado> {
  Certificado? _emitido;
  bool _procurou = false;

  @override
  void initState() {
    super.initState();
    _procurar();
  }

  Future<void> _procurar() async {
    final uid = context.read<AuthCubit?>()?.state.user?.uid;
    final c = uid == null ? null : await certificadoEmitido(uid, widget.nivel.codigo);
    if (!mounted) return;
    setState(() {
      _emitido = c;
      _procurou = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.nivel;
    final sit = situacaoDoNivel(widget.st.trilhas, n, widget.st.licaoConcluida);
    final emitido = _emitido;
    final String texto;
    Widget? acao;
    if (emitido != null) {
      texto = 'Certificado do ${n.codigo} emitido em ${dataPorExtenso(emitido.emitidoEm)} · nota ${emitido.nota}%.';
      acao = FilledButton(
        key: Key('certificado-ver-${n.codigo}'),
        onPressed: () => abrirCertificado(context, emitido),
        child: const Text('Ver certificado'),
      );
    } else if (sit.liberaProva) {
      texto = 'Prova final do ${n.codigo}: $questoesDaProva exercícios de todas as lições do nível. '
          'Com $notaMinima% ou mais, você recebe o certificado de conclusão.';
      acao = FilledButton(
        key: Key('certificado-prova-${n.codigo}'),
        onPressed: _procurou ? () => _fazerProva(context) : null,
        child: const Text('Fazer a prova'),
      );
    } else {
      final falta = <String>[
        if (!sit.revisaoFeita) 'a trilha de revisão do nível',
        if (sit.feitas < sit.minimoDeLicoes) '${sit.minimoDeLicoes - sit.feitas} lições (${sit.feitas}/${sit.licoes} feitas)',
      ];
      texto = 'Para liberar a prova final e o certificado, falta: ${falta.join(' e ')}.';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Container(
        key: Key('certificado-${n.codigo}'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: emitido != null ? Mixart.brand : Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
        ),
        child: Row(children: [
          const Text('🎓', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Certificado do ${n.codigo} · ${n.titulo}', style: Mixart.display(size: 15)),
              const SizedBox(height: 4),
              Text(texto, style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.35)),
            ]),
          ),
          if (acao != null) ...[const SizedBox(width: 10), acao],
        ]),
      ),
    );
  }

  Future<void> _fazerProva(BuildContext context) async {
    final c = await abrirProvaFinal(context, widget.nivel);
    if (c != null && mounted) setState(() => _emitido = c);
  }
}

/// As lições do nível, na ordem do curso (as frases da prova saem delas).
List<Licao> licoesDoNivel(CursoState st, String nivel) => [
      for (final (_, t) in trilhasDoNivel(st.trilhas, nivel)) ...t.licoes,
    ];

/// 🎓 A prova final do [nivel]: confirmação → [questoesDaProva] exercícios (modo prova) → nota. Passou: pede o
/// nome, emite e abre o certificado (devolve ele). Não passou: espera de [esperaDepoisDeReprovar].
Future<Certificado?> abrirProvaFinal(BuildContext context, NivelCertificado nivel, {Random? rnd}) async {
  final nav = Navigator.of(context);
  final st = context.read<CursoBloc>().state;
  final uid = context.read<AuthCubit?>()?.state.user?.uid;
  final habito = HabitoCubit.de(context);
  if (uid == null) return null;

  final espera = await PrefsCertificado.esperaAte(nivel.codigo);
  if (!nav.mounted) return null;
  if (espera != null) {
    final min = espera.difference(DateTime.now()).inMinutes + 1;
    await _aviso(nav.context, 'Ainda não dá', 'Você poderá fazer a prova do ${nivel.codigo} de novo daqui a $min min. '
        'Aproveite para rever as lições em que tropeçou.');
    return null;
  }
  final ok = await showDialog<bool>(
    context: nav.context,
    builder: (c) => AlertDialog(
      title: Text('Prova final do ${nivel.codigo}'),
      content: Text('$questoesDaProva exercícios com frases de todas as lições do ${nivel.nome}: escrever, montar, '
          'escutar e falar. Só a primeira resposta vale e não há "foi erro de digitação".\n\n'
          'Com $notaMinima% ou mais, você recebe o certificado de conclusão. Se não passar, pode tentar de novo '
          'depois de ${esperaDepoisDeReprovar.inHours} hora, com outras frases.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Agora não')),
        FilledButton(key: const Key('prova-comecar'), onPressed: () => Navigator.pop(c, true), child: const Text('Começar')),
      ],
    ),
  );
  if (ok != true || !nav.mounted) return null;

  final licoes = licoesDoNivel(st, nivel.codigo);
  final pausa = await PrefsRevisaoMista.carregar();
  final exercicios = montarRevisaoMista(
    licoes,
    total: questoesDaProva,
    podeEscutar: pausa.semAudio == null,
    podeFalar: FraseView.fabricaReconhecedor().suportado && pausa.semFala == null,
    rnd: rnd,
  );
  if (exercicios.isEmpty || !nav.mounted) return null;
  List<ResultadoMisto>? resultados;
  await nav.push<SaidaRevisaoMista>(MaterialPageRoute<SaidaRevisaoMista>(
    builder: (_) => RevisaoMistaPage(
      exercicios: exercicios,
      prova: 'Prova final do ${nivel.codigo}',
      extraMontagem: [for (final l in licoes) for (final f in l.trechos) f.cod].take(40).toList(),
      onDesligar: PrefsRevisaoMista.desligar,
      onResultado: (_) => habito?.praticou(),
      onFim: (rs) => resultados = rs,
    ),
  ));
  final rs = resultados;
  if (rs == null || !nav.mounted) return null; // saiu no meio: não conta
  final validos = [for (final x in rs) if (!x.exercicio.repeticao) x];
  final nota = notaDaProva(
    dePrimeira: validos.where((x) => x.resultado == ResultadoRevisao.acertou).length,
    comTropeco: validos.where((x) => x.resultado == ResultadoRevisao.hesitou).length,
    total: validos.length,
  );
  if (nota < notaMinima) {
    await PrefsCertificado.reprovou(nivel.codigo);
    if (!nav.mounted) return null;
    await _aviso(nav.context, 'Quase lá: $nota%', 'Para o certificado do ${nivel.codigo} são $notaMinima%. '
        'Reveja as lições do nível (a 🔁 Revisão até aqui ajuda) e tente de novo daqui a '
        '${esperaDepoisDeReprovar.inHours} hora, com outras frases.');
    return null;
  }

  final nome = await _pedirNome(nav.context, nota, nivel);
  if (nome == null || !nav.mounted) return null;
  final segundos = <String, double>{};
  for (final l in licoes) {
    try {
      segundos[l.id] = (await AulasRepo.daLicao(l.id))?.segundos ?? 0;
    } catch (_) {
      segundos[l.id] = 0;
    }
  }
  final r = rnd ?? Random.secure();
  Certificado? emitido;
  for (var tentativa = 0; tentativa < 3 && emitido == null; tentativa++) {
    final c = Certificado(
      codigo: gerarCodigo(nivel.codigo, r),
      uid: uid,
      nome: nome,
      nivel: nivel.codigo,
      nomeDoNivel: nivel.nome,
      emitidoEm: DateTime.now(),
      nota: nota,
      horas: horasDoNivel(st.trilhas, nivel.codigo, (l) => segundos[l.id] ?? 0),
      licoes: licoes.length,
    );
    try {
      await Certificados.repo.emitir(c);
      emitido = c;
    } catch (_) {}
  }
  if (!nav.mounted) return emitido;
  if (emitido == null) {
    await _aviso(nav.context, 'Não deu para emitir agora', 'Você passou ($nota%), mas a conexão falhou ao gravar o '
        'certificado. Confira a internet e faça a prova de novo para emitir.');
    return null;
  }
  await PrefsCertificado.guardar(nivel: nivel.codigo, codigo: emitido.codigo, nome: nome);
  if (nav.mounted) await abrirCertificado(nav.context, emitido, recemEmitido: true);
  return emitido;
}

Future<void> _aviso(BuildContext context, String titulo, String texto) => showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Entendi'))],
      ),
    );

/// "Parabéns, você passou": o nome completo como deve sair no certificado (não muda depois).
Future<String?> _pedirNome(BuildContext context, int nota, NivelCertificado nivel) async {
  final ctrl = TextEditingController(text: await PrefsCertificado.nome() ?? '');
  if (!context.mounted) return null;
  String? erro;
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (c) => StatefulBuilder(
      builder: (c, set) {
        void confirmar() {
          final n = nomeParaCertificado(ctrl.text);
          if (n == null) {
            set(() => erro = 'Escreva o nome e o sobrenome (só letras).');
            return;
          }
          Navigator.pop(c, n);
        }

        return AlertDialog(
          title: Text('Parabéns! $nota% na prova do ${nivel.codigo} 🎉'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Qual nome deve sair no certificado? Escreva o nome completo: depois de emitido, ele não muda.'),
            const SizedBox(height: 12),
            TextField(
              key: const Key('certificado-nome'),
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: 'Nome completo', errorText: erro),
              onSubmitted: (_) => confirmar(),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
            FilledButton(key: const Key('certificado-emitir'), onPressed: confirmar, child: const Text('Emitir certificado')),
          ],
        );
      },
    ),
  );
}

/// Abre a página do certificado [c].
Future<void> abrirCertificado(BuildContext context, Certificado c, {bool recemEmitido = false}) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CertificadoPage(c, recemEmitido: recemEmitido)));

/// 🎓 O certificado na tela: o mesmo conteúdo do PDF, com "Baixar PDF", "Copiar link" e, no fim do curso, a dica
/// do teste externo gratuito (EF SET).
class CertificadoPage extends StatelessWidget {
  final Certificado c;
  final bool recemEmitido, publica;
  const CertificadoPage(this.c, {super.key, this.recemEmitido = false, this.publica = false});

  @override
  Widget build(BuildContext context) {
    final url = urlDeVerificacao(siteDoApp, c.codigo);
    return Scaffold(
      backgroundColor: Mixart.bg,
      appBar: publica ? null : AppBar(title: Text('Certificado do ${c.nivel}')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (publica) ...[
                  Text('✅ Certificado válido', key: const Key('certificado-valido'), textAlign: TextAlign.center,
                      style: Mixart.display(size: 22, color: Mixart.brand)),
                  const SizedBox(height: 4),
                  Text('Este certificado foi emitido pelo Paclingo e está registrado com o código abaixo.',
                      textAlign: TextAlign.center, style: Mixart.ui(size: 13, color: Mixart.textMuted)),
                  const SizedBox(height: 16),
                ] else if (recemEmitido) ...[
                  Text('🎉 Certificado emitido!', textAlign: TextAlign.center, style: Mixart.display(size: 22, color: Mixart.brand)),
                  const SizedBox(height: 16),
                ],
                _Folha(c),
                const SizedBox(height: 16),
                Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
                  FilledButton.icon(
                    key: const Key('certificado-pdf'),
                    icon: const Icon(Icons.download),
                    label: Text(podeSalvarArquivo ? 'Baixar PDF' : 'Abrir no site para baixar o PDF'),
                    onPressed: () => _baixar(context, url),
                  ),
                  OutlinedButton.icon(
                    key: const Key('certificado-copiar'),
                    icon: const Icon(Icons.link),
                    label: const Text('Copiar link de verificação'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: url));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copiado.')));
                      }
                    },
                  ),
                ]),
                if (!publica) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Quer comprovar o seu nível também com um teste externo? O EF SET é gratuito e padronizado: '
                    'dá para pôr o resultado no currículo junto com este certificado.',
                    textAlign: TextAlign.center,
                    style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.4),
                  ),
                  TextButton(onPressed: () => abrirUrl(Certificados.efSet), child: const Text('Fazer o EF SET (grátis)')),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _baixar(BuildContext context, String url) async {
    if (!podeSalvarArquivo) {
      abrirUrl(url);
      return;
    }
    final msg = ScaffoldMessenger.of(context);
    try {
      final bytes = await pdfDoCertificado(c, await FontesDoCertificado.carregar());
      if (!salvarBytes(nomeDoArquivo(c), bytes, 'application/pdf')) throw StateError('download');
    } catch (_) {
      msg.showSnackBar(const SnackBar(content: Text('Não deu para gerar o PDF agora. Tente de novo.')));
    }
  }
}

/// A "folha" do certificado na tela (o resumo do PDF).
class _Folha extends StatelessWidget {
  final Certificado c;
  const _Folha(this.c);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: Mixart.brand, width: 2),
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
        ),
        child: Column(children: [
          Text('PACLINGO', style: Mixart.ui(size: 12, weight: FontWeight.w800, color: Mixart.brand).copyWith(letterSpacing: 3)),
          const SizedBox(height: 10),
          Text('Certificado de conclusão', textAlign: TextAlign.center, style: Mixart.display(size: 24)),
          const SizedBox(height: 12),
          Text(c.nome, key: const Key('certificado-nome-aluno'), textAlign: TextAlign.center,
              style: Mixart.display(size: 22, color: Mixart.brand)),
          const SizedBox(height: 6),
          Text('concluiu o nível ${c.nomeDoNivel}', textAlign: TextAlign.center, style: Mixart.ui(size: 14, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('${c.licoes} lições · carga horária do conteúdo: ${c.horas} h · nota na prova final: ${c.nota}%',
              textAlign: TextAlign.center, style: Mixart.ui(size: 12.5, color: Mixart.textMuted)),
          const SizedBox(height: 4),
          Text('Emitido em ${dataPorExtenso(c.emitidoEm)} · código ${c.codigo}',
              textAlign: TextAlign.center, style: Mixart.ui(size: 12.5, color: Mixart.textMuted)),
          const SizedBox(height: 10),
          Text(textoDeConteudo, textAlign: TextAlign.center, style: Mixart.ui(size: 11, color: Mixart.textFaint)),
        ]),
      );
}

/// 🔎 A página PÚBLICA de verificação (`?certificado=<codigo>` no site, sem login): mostra o certificado se o
/// código existe; senão, avisa que não foi encontrado.
class VerificarCertificadoPage extends StatelessWidget {
  final String codigoBruto;
  final CertificadosRepository? repo;
  const VerificarCertificadoPage(this.codigoBruto, {super.key, this.repo});

  @override
  Widget build(BuildContext context) {
    final codigo = normalizarCodigo(codigoBruto);
    return FutureBuilder<Certificado?>(
      future: codigo == null ? Future.value(null) : (repo ?? Certificados.repo).buscar(codigo).catchError((_) => null),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Scaffold(backgroundColor: Mixart.bg, body: const Center(child: CircularProgressIndicator()));
        }
        final c = snap.data;
        if (c != null) return CertificadoPage(c, publica: true);
        return Scaffold(
          backgroundColor: Mixart.bg,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('❌ Certificado não encontrado', key: const Key('certificado-nao-encontrado'),
                      textAlign: TextAlign.center, style: Mixart.display(size: 22)),
                  const SizedBox(height: 10),
                  Text(
                    codigo == null
                        ? 'O código "$codigoBruto" não tem o formato dos certificados do Paclingo (ex.: PCL-B2-7KQ4-M9XZ).'
                        : 'Nenhum certificado do Paclingo tem o código $codigo. Confira se o código foi digitado certo.',
                    textAlign: TextAlign.center,
                    style: Mixart.ui(size: 13.5, color: Mixart.textMuted),
                  ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}
