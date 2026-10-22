#!/usr/bin/env python3
"""Validador oficial (espelho em Python) das historinhas do 📺 Escutar assistindo (no 🎧 Ouvir, não na lição).

O DART MANDA (plano D11): `HistoriasDaTrilha.fromJson(estrito: true)` + `validarHistoriasDaTrilha` em
lib/features/ingles/domain/assistir/historia_licao.dart. Este script reproduz os dois MENSAGEM POR MENSAGEM
(inclusive o "parse estrito para no 1º erro"), e a paridade é provada pelos fixtures compartilhados em
fixtures/ (--auto-teste aqui; test/historias_licoes_paridade_test.dart no Dart). Por cima do espelho, roda as
regras da RECEITA (marcadas com "[receita]"), que o Dart não cobra: cenários vetados, efeitos e câmeras
evitados, fecho com sorriso etc.

Uso:
    python3 -I validar_historias_licoes.py --auto-teste
    python3 -I validar_historias_licoes.py <slug>.json [<slug>.json ...] [--so-dart]
    python3 -I validar_historias_licoes.py --tabela encenacao_auto.json
    python3 -I validar_historias_licoes.py --pasta <pasta com indice.json, encenacao_auto.json e <slug>.json>
Opções: --curriculo CAMINHO (padrão: assets/ingles/curriculo.json do repo) · --dart CAMINHO (historia_turismo.dart)
        · --so-dart (só o espelho do Dart, sem as regras da receita)

Arquivo de trilha = o esquema do plano §16 (o nome do arquivo tem de ser o campo `trilha`). Também aceita o
pacote do lote piloto {"versao", "lote", "descricao", "arquivos": {"<slug>": <arquivo de trilha>}}.
Código de saída: 0 sem erros, 1 com erros, 2 uso/arquivo inválido.

O motor da cena (SimulacaoCena + enums lidos por regex do historia_turismo.dart) é importado por caminho de
validar_historia.py, nesta mesma pasta (`-I` não põe a pasta do script no sys.path). As constantes das lições
(elencoDasLicoes, figurantesConhecidos, cenariosSoDoTurismo…) são lidas por regex de historia_licao.dart.
"""
import importlib.util
import json
import os
import re
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
_REPO = os.path.normpath(os.path.join(AQUI, '..', '..', '..'))
if not os.path.isfile(os.path.join(_REPO, 'lib', 'features', 'arcade', 'domain', 'historia_turismo.dart')):
    _REPO = '/Users/fazplay/pac_dart'
CURRICULO = os.path.join(_REPO, 'assets', 'ingles', 'curriculo.json')
DART = os.path.join(_REPO, 'lib', 'features', 'arcade', 'domain', 'historia_turismo.dart')
DART_LICAO = os.path.join(_REPO, 'lib', 'features', 'ingles', 'domain', 'assistir', 'historia_licao.dart')
FIXTURES = os.path.join(AQUI, 'fixtures')

# ───────────────────────────── motor e constantes ─────────────────────────────

_MOTOR = None


def motor(dart=None):
    """(m, D, R): o módulo validar_historia.py, os enums lidos do Dart e as Regras. Carregado uma vez."""
    global _MOTOR
    if _MOTOR is None:
        spec = importlib.util.spec_from_file_location('validar_historia_turismo', os.path.join(AQUI, 'validar_historia.py'))
        m = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(m)
        D = m.ler_dart(dart or DART)
        m.POS_IDX = {p: i for i, p in enumerate(D['PosicaoPalco'])}
        _MOTOR = (m, D, m.Regras(D))
    return _MOTOR


# Espelho de historia_licao.dart (usado só se o arquivo Dart não estiver acessível).
_PADRAO_LICAO = {
    'elencoDasLicoes': {'voce', 'mike', 'sarah', 'ana', 'ben', 'emma', 'lucas', 'julia', 'dra-lee'},
    'figurantesConhecidos': {
        'amigo-do-ben', 'atendente', 'caixa', 'cfo', 'cliente', 'colega', 'convidada', 'convidado', 'corretora',
        'desenvolvedora', 'dev-junior', 'dev-nova', 'dev-novo', 'dev-pleno', 'diretora', 'engenheira', 'engenheiro',
        'entrevistador', 'estagiaria', 'farmaceutica', 'gestora', 'guia', 'marido', 'moradora', 'motorista',
        'participante', 'passageira', 'passageiro', 'proprietario', 'recepcionista', 'recrutadora', 'seguranca',
        'stakeholder', 'supervisora', 'vendedor', 'vizinha', 'oficial', 'garcom', 'vendedora'},
    'maxFigurantesMudos': 2,
    'maxMudosPorHistoria': 4,
    'maxArco': 300,
    'cenariosSoDoTurismo': {'boxes', 'podio', 'autodromo', 'plataforma', 'espaco', 'lua', 'marte', 'estacao', 'garagem'},
    'propsSoDoTurismo': {'carro', 'carroRival', 'rodaDeOuro', 'foguete', 'capacete', 'pneu', 'trofeu', 'medalha', 'bandeira'},
    'acoesQueDeslocam': {'entra', 'anda', 'corre', 'dirige', 'desce', 'sai'},
}
_LICAO = None


def consts_licao():
    """As constantes das lições lidas de historia_licao.dart (o Dart manda); sem o arquivo, o espelho acima."""
    global _LICAO
    if _LICAO is not None:
        return _LICAO
    c = {k: (set(v) if isinstance(v, set) else v) for k, v in _PADRAO_LICAO.items()}
    try:
        src = re.sub(r'//[^\n]*', '', open(DART_LICAO, encoding='utf-8').read())
    except OSError:
        _LICAO = c
        return c

    def bloco(nome):
        mm = re.search(r'const\s+' + nome + r'\s*=\s*\{(.*?)\}\s*;', src, re.S)
        return mm.group(1) if mm else None

    for nome in ('elencoDasLicoes', 'figurantesConhecidos'):
        b = bloco(nome)
        if b:
            c[nome] = set(re.findall(r"'([^']+)'", b))
    for nome, tipo in (('cenariosSoDoTurismo', 'CenarioHistoria'), ('propsSoDoTurismo', 'PropHistoria'),
                       ('acoesQueDeslocam', 'AcaoAtor')):
        b = bloco(nome)
        if b:
            c[nome] = set(re.findall(tipo + r'\.(\w+)', b))
    for nome in ('maxFigurantesMudos', 'maxMudosPorHistoria', 'maxArco'):
        mm = re.search(r'const\s+' + nome + r'\s*=\s*(\d+)\s*;', src)
        if mm:
            c[nome] = int(mm.group(1))
    _LICAO = c
    return c


NARRADOR = 'narrador'
PROIBIDOS_NA_ANCORA = ('en', 'pt', 'pt_f', 'mudo')
ARQ_KEYS = {'versao', 'trilha', 'arco', 'licoes'}
LIC_KEYS = {'titulo', 'cenas'}
CENA_KEYS = {'cenario', 'hora', 'clima', 'elenco', 'objetos', 'passos'}
ATOR_KEYS = {'quem', 'pos', 'visivel', 'remoto', 'segura', 'emocao', 'noCarro'}
OBJ_KEYS = {'prop', 'pos', 'visivel'}
FALA_KEYS = {'quem', 'en', 'pt', 'pt_f', 'mudo', 'emocao', 'acao', 'alvo', 'para', 'camera', 'efeito', 'clima',
             'segura', 'cenario', 'hora', 'reacoes', 'objetos'}
REAC_KEYS = {'quem', 'emocao', 'acao', 'efeito', 'segura'}
MOV_KEYS = {'prop', 'acao', 'pos', 'de'}
FEMININOS = {'emocao', 'acao', 'hora', 'camera', 'pos', 'para'}


def quem_no_palco(q):
    return NARRADOR if q in ('', 'placa') else q


def nivel_da_etapa(etapa):
    e = etapa.strip().upper()
    for n in ('A1', 'A2', 'B1'):
        if e.startswith(n):
            return n.lower()
    return 'b2'


def slug_da_licao(lid):
    i = lid.find('.')
    return lid[:i] if i > 0 else lid


def dica_plana(s):
    return re.sub(r'</?code>', '', re.sub(r'</?b>', '', s))


def chave_da_frase(t):
    return t['id']  # os 5.308 trechos têm id (Revisao.chaveDe só cai no hash do texto sem id)


def dart_len(s):
    """String.length do Dart (unidades UTF-16)."""
    return len(s.encode('utf-16-le')) // 2


def dart_str(v):
    """'$v' do Dart para valores vindos do jsonDecode."""
    if v is None:
        return 'null'
    if isinstance(v, bool):
        return 'true' if v else 'false'
    if isinstance(v, str):
        return v
    if isinstance(v, list):
        return '[' + ', '.join(dart_str(x) for x in v) + ']'
    if isinstance(v, dict):
        return '{' + ', '.join(f'{k}: {dart_str(x)}' for k, x in v.items()) + '}'
    return str(v)


def trilhas_por_slug(curriculo):
    r = {}
    for t in json.load(open(curriculo, encoding='utf-8')):
        if t.get('licoes'):
            r[slug_da_licao(t['licoes'][0]['id'])] = t
    return r


# ───────────────────────────── parse estrito (espelho do Dart) ─────────────────────────────

class ErroParse(Exception):
    def __init__(self, msg):
        super().__init__(msg)
        self.msg = msg


def _erro(ctx, msg):
    raise ErroParse(msg if not ctx else f'{ctx}: {msg}')


def _e_int(v):
    return isinstance(v, int) and not isinstance(v, bool)


def _mapa(v, ctx):
    if isinstance(v, dict):
        return v
    _erro(ctx, 'esperava um objeto JSON')


def _chaves(j, validas, ctx):
    for k in j:
        if k not in validas:
            _erro(ctx, f"chave '{k}' desconhecida")


def _invalido(campo, v):
    return f"{campo} '{dart_str(v)}' {'inválida' if campo in FEMININOS else 'inválido'}"


class _Leitor:
    """Os _lerAtor/_lerFala/... de historia_turismo.dart no modo estrito (mesma ordem de checagem)."""

    def __init__(self, D):
        self.D = D

    def texto(self, j, campo, ctx):
        v = j.get(campo)
        if not isinstance(v, str):
            _erro(ctx, f"'{campo}' ausente ou não é texto")
        return v

    def texto_opc(self, j, campo, ctx):
        v = j.get(campo)
        if v is None:
            return None
        if isinstance(v, str):
            return v
        _erro(ctx, f"'{campo}' não é texto")

    def booleano(self, j, campo, padrao, ctx):
        v = j.get(campo)
        if v is None:
            return padrao
        if isinstance(v, bool):
            return v
        _erro(ctx, f"'{campo}' não é true/false")

    def _achar(self, nome_enum, v):
        return v if isinstance(v, str) and v in self.D[nome_enum] else None

    def enum(self, nome_enum, j, campo, ctx, padrao=None):
        v = j.get(campo)
        e = self._achar(nome_enum, v)
        if e is not None:
            return e
        if v is None and padrao is not None:
            return padrao
        _erro(ctx, f"'{campo}' ausente" if v is None else _invalido(campo, v))

    def enum_opc(self, nome_enum, j, campo, ctx):
        v = j.get(campo)
        if v is None:
            return None
        e = self._achar(nome_enum, v)
        if e is not None:
            return e
        _erro(ctx, _invalido(campo, v))

    enum_estrutural = enum_opc  # no estrito, os dois só aceitam ausente ou válido

    def lista(self, j, campo, ctx, obrigatorio=False):
        v = j.get(campo)
        if v is None:
            if obrigatorio:
                _erro(ctx, f"'{campo}' ausente")
            return []
        if isinstance(v, list):
            return v
        _erro(ctx, f"'{campo}' não é uma lista")

    def climas(self, lista, ctx):
        r = []
        for v in lista:
            if self._achar('ClimaHistoria', v) is None:
                _erro(ctx, f"clima '{dart_str(v)}' inválido")
            r.append(v)
        return r

    def ator(self, j, ctx=''):
        _chaves(j, ATOR_KEYS, ctx)
        return {
            'quem': self.texto(j, 'quem', ctx),
            'pos': self.enum_estrutural('PosicaoPalco', j, 'pos', ctx),
            'visivel': self.booleano(j, 'visivel', True, ctx),
            'remoto': self.enum_estrutural('ViaRemota', j, 'remoto', ctx),
            'segura': self.enum_opc('PropHistoria', j, 'segura', ctx),
            'emocao': self.enum('Expressao', j, 'emocao', ctx, padrao='neutro'),
            'noCarro': self.booleano(j, 'noCarro', False, ctx),
        }

    def objeto(self, j, ctx=''):
        _chaves(j, OBJ_KEYS, ctx)
        return {
            'prop': self.enum('PropHistoria', j, 'prop', ctx),
            'pos': self.enum('PosicaoPalco', j, 'pos', ctx),
            'visivel': self.booleano(j, 'visivel', True, ctx),
        }

    def reacao(self, j, ctx):
        _chaves(j, REAC_KEYS, ctx)
        return {
            'quem': self.texto(j, 'quem', ctx),
            'emocao': self.enum_opc('Expressao', j, 'emocao', ctx),
            'acao': self.enum_opc('AcaoAtor', j, 'acao', ctx),
            'efeito': self.enum_opc('EfeitoHistoria', j, 'efeito', ctx),
            'segura': self.enum_opc('PropHistoria', j, 'segura', ctx),
        }

    def movimento(self, j, ctx):
        _chaves(j, MOV_KEYS, ctx)
        return {
            'prop': self.enum('PropHistoria', j, 'prop', ctx),
            'acao': self.enum('AcaoObjeto', j, 'acao', ctx),
            'pos': self.enum_estrutural('PosicaoPalco', j, 'pos', ctx),
            'de': self.texto_opc(j, 'de', ctx),
        }

    def fala(self, j, ctx=''):
        _chaves(j, FALA_KEYS, ctx)
        clima = j.get('clima')
        reacoes = self.lista(j, 'reacoes', ctx)
        objetos = self.lista(j, 'objetos', ctx)
        f = {'quem': self.texto(j, 'quem', ctx)}
        f['en'] = self.texto_opc(j, 'en', ctx)
        f['pt'] = self.texto_opc(j, 'pt', ctx)
        f['ptF'] = self.texto_opc(j, 'pt_f', ctx)
        f['mudo'] = self.booleano(j, 'mudo', False, ctx)
        f['emocao'] = self.enum_opc('Expressao', j, 'emocao', ctx)
        f['acao'] = self.enum('AcaoAtor', j, 'acao', ctx, padrao='parado')
        f['alvo'] = self.texto_opc(j, 'alvo', ctx)
        f['para'] = self.enum_estrutural('PosicaoPalco', j, 'para', ctx)
        f['camera'] = self.enum_opc('CameraHistoria', j, 'camera', ctx)
        f['efeito'] = self.enum_opc('EfeitoHistoria', j, 'efeito', ctx)
        f['clima'] = None if clima is None else self.climas(self.lista(j, 'clima', ctx), ctx)
        f['segura'] = self.enum_opc('PropHistoria', j, 'segura', ctx)
        f['cenario'] = self.enum_estrutural('CenarioHistoria', j, 'cenario', ctx)
        f['hora'] = self.enum_estrutural('HoraHistoria', j, 'hora', ctx)
        f['reacoes'] = [self.reacao(_mapa(r, f'{ctx} reacoes[{i}]'), f'{ctx} reacoes[{i}]') for i, r in enumerate(reacoes)]
        f['objetos'] = [self.movimento(_mapa(o, f'{ctx} objetos[{i}]'), f'{ctx} objetos[{i}]') for i, o in enumerate(objetos)]
        return f


def _com_ctx(ctx, ler):
    try:
        return ler()
    except ErroParse as e:
        _erro(ctx, e.msg)


def _lista_de(v, ctx, campo):
    if isinstance(v, list):
        return v
    _erro(ctx, f"'{campo}' ausente" if v is None else f"'{campo}' não é uma lista")


def ler_licao(lid, j, licao, nivel, D):
    """Espelho de _lerLicao (estrito). Devolve a HistoriaLicao como dict."""
    lt = _Leitor(D)
    _chaves(j, LIC_KEYS, lid)
    titulo = None
    tj = j.get('titulo')
    if tj is not None:
        t = _mapa(tj, f'{lid} titulo')
        _chaves(t, {'en', 'pt'}, f'{lid} titulo')
        en, pt = t.get('en'), t.get('pt')
        if not isinstance(en, str) or not isinstance(pt, str):
            _erro(f'{lid} titulo', "'en' e 'pt' têm de ser texto")
        titulo = (en, pt)
    cenas_j = _lista_de(j.get('cenas'), lid, 'cenas')
    trechos = {chave_da_frase(t): t for t in licao['trechos']}
    cenas, ancoras = [], {}
    for ci, c in enumerate(cenas_j):
        ctx = f'{lid} cena[{ci}]'
        cj = _mapa(c, ctx)
        if 'falas' in cj:
            _erro(ctx, "chave 'falas' desconhecida (use 'passos', não 'falas')")
        _chaves(cj, CENA_KEYS, ctx)
        cen = cj.get('cenario')
        if lt._achar('CenarioHistoria', cen) is None:
            _erro(ctx, "'cenario' ausente" if cen is None else f"cenario '{dart_str(cen)}' inválido")
        hora = cj.get('hora')
        if lt._achar('HoraHistoria', hora) is None:
            _erro(ctx, "'hora' ausente" if hora is None else f"hora '{dart_str(hora)}' inválida")
        clima = []
        for v in ([] if cj.get('clima') is None else _lista_de(cj.get('clima'), ctx, 'clima')):
            if lt._achar('ClimaHistoria', v) is None:
                _erro(ctx, f"clima '{dart_str(v)}' inválido")
            clima.append(v)
        elenco_j = [] if cj.get('elenco') is None else _lista_de(cj.get('elenco'), ctx, 'elenco')
        objetos_j = [] if cj.get('objetos') is None else _lista_de(cj.get('objetos'), ctx, 'objetos')
        passos_j = _lista_de(cj.get('passos'), ctx, 'passos')
        elenco = [_com_ctx(f'{ctx} elenco[{i}]', lambda a=a, i=i: lt.ator(_mapa(a, f'{ctx} elenco[{i}]')))
                  for i, a in enumerate(elenco_j)]
        objetos = [_com_ctx(f'{ctx} objetos[{i}]', lambda o=o, i=i: lt.objeto(_mapa(o, f'{ctx} objetos[{i}]')))
                   for i, o in enumerate(objetos_j)]
        passos = []
        for pi, p in enumerate(passos_j):
            pc = f'{ctx} passo {pi + 1}'
            pj = dict(_mapa(p, pc))
            if 'frase' in pj:
                for k in PROIBIDOS_NA_ANCORA:
                    if k in pj:
                        _erro(pc, f"âncora não leva '{k}' (o texto vem do currículo)")
                fid = pj.pop('frase')
                tr = trechos.get(fid) if isinstance(fid, str) else None
                if tr is None:
                    _erro(pc, f"frase '{dart_str(fid)}' desconhecida")
                q = quem_no_palco(tr['quem'])
                quem_j = pj.get('quem')
                if quem_j is not None and quem_j != q:
                    _erro(pc, f"quem '{dart_str(quem_j)}' não bate com o da frase ('{q}')")
                pj['quem'] = q
                pj['en'] = tr['cod']
                pj['pt'] = dica_plana(tr['dica'])
                passos.append(_com_ctx(pc, lambda pj=pj: lt.fala(pj)))
                ancoras.setdefault(fid, (ci, len(passos) - 1))
            elif pj.get('mudo') is True:
                passos.append(_com_ctx(pc, lambda pj=pj: lt.fala(pj)))
            else:
                _erro(pc, "fala sem 'frase': falas de ligação são só atuadas (mudo)")
        cenas.append({'cenario': cen, 'hora': hora, 'clima': clima, 'elenco': elenco, 'objetos': objetos,
                      'falas': passos})
    return {'licaoId': lid, 'nivel': nivel, 'titulo': titulo, 'cenas': cenas, 'ancoras': ancoras, 'autoral': True}


def ler_trilha(j, trilha, D):
    """Espelho de HistoriasDaTrilha.fromJson(estrito: true). Lança ErroParse no 1º erro."""
    if not isinstance(j, dict):
        _erro('', 'esperava um objeto JSON')
    _chaves(j, ARQ_KEYS, 'arquivo')
    versao = j.get('versao')
    if not _e_int(versao):
        _erro('arquivo', "'versao' ausente ou não é inteiro")
    if versao != 1:
        _erro('arquivo', f'versao {versao} (esperava 1)')
    slug = j.get('trilha')
    if not isinstance(slug, str):
        _erro('arquivo', "'trilha' ausente ou não é texto")
    arco = j.get('arco')
    if arco is not None and not isinstance(arco, str):
        _erro('arquivo', "'arco' não é texto")
    brutas = _mapa(j.get('licoes'), "arquivo 'licoes'")
    por_id = {l['id']: l for l in trilha['licoes']}
    nivel = nivel_da_etapa(trilha['etapa'])
    slug_t = slug_da_licao(trilha['licoes'][0]['id']) if trilha['licoes'] else ''
    licoes = {}
    for lid, v in brutas.items():
        licao = por_id.get(lid)
        if licao is None:
            _erro(lid, f"não é lição da trilha '{slug_t}'")
        licoes[lid] = ler_licao(lid, _mapa(v, lid), licao, nivel, D)
    return {'versao': versao, 'trilha': slug, 'arco': arco, 'licoes': licoes}


# ───────────────────────────── validação (espelho do Dart) ─────────────────────────────

def validar_cena_base(ctx, cena, erros, personagens):
    """validarCenaBase(validarTextos: false, rotuloPasso: 'passo'). Devolve a linha do tempo."""
    m, D, R = motor()
    if cena['hora'] not in R.horas(cena['cenario']):
        erros.append(f"{ctx}: hora '{cena['hora']}' não combina com '{cena['cenario']}'")
    if len(set(cena['clima'])) != len(cena['clima']):
        erros.append(f'{ctx}: clima repetido')
    for cl in cena['clima']:
        if not R.clima_ok(cl, cena['cenario'], cena['hora']):
            erros.append(f"{ctx}: clima '{cl}' não combina com '{cena['cenario']}'/'{cena['hora']}'")
    ids, posicoes = set(), set()
    presentes = remotos = 0
    for a in cena['elenco']:
        if a['quem'] == NARRADOR:
            erros.append(f'{ctx}: o narrador não entra no elenco')
        elif a['quem'] not in personagens:
            erros.append(f"{ctx}: personagem '{a['quem']}' desconhecido")
        if a['quem'] in ids:
            erros.append(f"{ctx}: '{a['quem']}' repetido no elenco")
        ids.add(a['quem'])
        if a['segura'] == 'nada':
            erros.append(f"{ctx}: '{a['quem']}' com segura 'nada' no elenco")
        if a['remoto'] is not None:
            remotos += 1
            if a['pos'] is not None:
                erros.append(f"{ctx}: '{a['quem']}' é remoto e não tem pos")
        else:
            presentes += 1
            if a['pos'] is None:
                erros.append(f"{ctx}: '{a['quem']}' sem pos")
            elif a['pos'] in posicoes:
                erros.append(f"{ctx}: posição inicial '{a['pos']}' repetida")
            else:
                posicoes.add(a['pos'])
    if presentes > 5:
        erros.append(f'{ctx}: {presentes} atores presentes (máx. 5)')
    if remotos > 2:
        erros.append(f'{ctx}: {remotos} remotos (máx. 2)')
    if len(cena['objetos']) > 4:
        erros.append(f"{ctx}: {len(cena['objetos'])} objetos (máx. 4)")
    pos_obj = set()
    for o in cena['objetos']:
        if o['prop'] == 'nada':
            erros.append(f"{ctx}: objeto 'nada'")
        if o['pos'] in pos_obj:
            erros.append(f"{ctx}: dois objetos em '{o['pos']}'")
        pos_obj.add(o['pos'])
    if not cena['falas']:
        erros.append(f'{ctx}: cena sem falas')
        return [m.estado_inicial(cena)]
    mudas = seguidas = 0
    linha = [m.estado_inicial(cena)]
    for i, f in enumerate(cena['falas']):
        fc = f'{ctx} passo {i + 1}'
        if f['mudo']:
            mudas += 1
            seguidas += 1
            if seguidas == 3:
                erros.append(f'{fc}: mais de 2 passos mudos seguidos')
        else:
            seguidas = 0
        depois, errs = m.aplicar(R, linha[-1], f)
        erros.extend(f'{fc}: {e}' for e in errs)
        linha.append(depois)
    if mudas > 3:
        erros.append(f'{ctx}: {mudas} passos mudos (máx. 3)')
    return linha


def validar_historia_licao(h, licao):
    """Espelho de validarHistoriaLicao: [] = ok."""
    _, _, R = motor()
    C = consts_licao()
    erros = []
    lid = h['licaoId']
    tit = h['titulo']
    if tit is None:
        if h['autoral']:
            erros.append(f'{lid}: titulo ausente (obrigatório na história autoral)')
    else:
        en = tit[0].strip()
        if not en or len(re.split(r'\s+', en)) > 6 or any(ord(c) > 127 for c in en):
            erros.append(f'{lid}: titulo.en tem de ter de 1 a 6 palavras, só ASCII')
        for termo, rx in R.re_termos:
            if rx.search(tit[0]) or rx.search(tit[1]):
                erros.append(f"{lid}: termo proibido '{termo}' no título")
        if not tit[1].strip():
            erros.append(f'{lid}: titulo.pt vazio')
    if not h['cenas'] or len(h['cenas']) > 2:
        erros.append(f'{lid}: de 1 a 2 cenas')

    ordem = [chave_da_frase(t) for t in licao['trechos']]
    trecho_de = {chave_da_frase(t): t for t in licao['trechos']}
    falantes = {quem_no_palco(t['quem']) for t in licao['trechos']}
    tem_narrador = NARRADOR in falantes
    permitidos = (C['elencoDasLicoes'] | falantes | C['figurantesConhecidos']) - {NARRADOR}
    por_passo = {v: k for k, v in h['ancoras'].items()}
    vistas, fig_mudos = [], set()
    mudos = 0

    def prop_ok(p, onde):
        if p is not None and p in C['propsSoDoTurismo']:
            erros.append(f"{onde}: prop '{p}' é só do Turismo")

    for ci, cena in enumerate(h['cenas']):
        ctx = f'{lid} cena[{ci}]'
        ancoras_na_cena = 0
        if cena['cenario'] in C['cenariosSoDoTurismo']:
            erros.append(f"{ctx}: cenário '{cena['cenario']}' é só do Turismo")
        for a in cena['elenco']:
            if a['quem'] == NARRADOR:
                continue
            if a['quem'] in ('max', 'kim'):
                erros.append(f"{ctx}: '{a['quem']}' é só do Turismo")
            elif a['quem'] not in permitidos:
                erros.append(f"{ctx}: '{a['quem']}' não é do elenco das lições nem figurante conhecido")
            elif a['quem'] in C['figurantesConhecidos'] and a['quem'] not in falantes:
                fig_mudos.add(a['quem'])
            if a['noCarro']:
                erros.append(f'{ctx}: noCarro é só do Turismo')
            prop_ok(a['segura'], ctx)
        for o in cena['objetos']:
            prop_ok(o['prop'], ctx)
        for pi, f in enumerate(cena['falas']):
            pc = f'{ctx} passo {pi + 1}'
            if f['cenario'] is not None and f['cenario'] in C['cenariosSoDoTurismo']:
                erros.append(f"{pc}: cenário '{f['cenario']}' é só do Turismo")
            prop_ok(f['segura'], pc)
            for r in f['reacoes']:
                prop_ok(r['segura'], pc)
            for mv in f['objetos']:
                prop_ok(mv['prop'], pc)
            if f['mudo']:
                mudos += 1
                continue
            ancoras_na_cena += 1
            if f['quem'] == NARRADOR and not tem_narrador:
                erros.append(f'{pc}: narrador só onde a frase é de placa')
            if f['acao'] in C['acoesQueDeslocam']:
                erros.append(f"{pc}: acao '{f['acao']}' desloca: vai num passo mudo antes ou depois")
            chave = por_passo.get((ci, pi))
            tr = None if chave is None else trecho_de.get(chave)
            if chave is None or tr is None:
                igual = next((t for t in licao['trechos'] if t['cod'] == f['en'] and quem_no_palco(t['quem']) == f['quem']),
                             None)
                if igual is not None:
                    vistas.append(chave_da_frase(igual))
                else:
                    erros.append(f"{pc}: fala sem 'frase': falas de ligação são só atuadas (mudo)")
                continue
            vistas.append(chave)
            q = quem_no_palco(tr['quem'])
            if f['quem'] != q:
                erros.append(f"{pc}: quem '{f['quem']}' não bate com o da frase ('{q}')")
            if f['en'] != tr['cod'] or f['pt'] != dica_plana(tr['dica']):
                erros.append(f"{pc}: o texto não é o da frase '{chave}' (a âncora puxa en/pt do currículo)")
        if ancoras_na_cena == 0:
            erros.append(f'{ctx}: cena sem nenhuma âncora (frase)')
        validar_cena_base(ctx, cena, erros, {a['quem'] for a in cena['elenco']} - {NARRADOR})
    if mudos > C['maxMudosPorHistoria']:
        erros.append(f"{lid}: {mudos} passos mudos (máx. {C['maxMudosPorHistoria']} na história)")
    if len(fig_mudos) > C['maxFigurantesMudos']:
        erros.append(f"{lid}: {len(fig_mudos)} figurantes mudos (máx. {C['maxFigurantesMudos']}): "
                     f"{', '.join(sorted(fig_mudos))}")
    if vistas != ordem:
        faltam = [k for k in ordem if k not in vistas]
        contagem = {}
        for k in vistas:
            contagem[k] = contagem.get(k, 0) + 1
        repetidas = sorted(k for k, n in contagem.items() if n > 1)
        if faltam:
            erros.append(f"{lid}: frases faltando: {', '.join(faltam)}")
        if repetidas:
            erros.append(f"{lid}: frases repetidas: {', '.join(repetidas)}")
        if not faltam and not repetidas:
            erros.append(f'{lid}: frases fora da ordem da lição')
    return erros


def validar_historias_da_trilha(h, trilha, avisos=None):
    """Espelho de validarHistoriasDaTrilha."""
    C = consts_licao()
    erros = []
    slug = slug_da_licao(trilha['licoes'][0]['id']) if trilha['licoes'] else ''
    if h['versao'] != 1:
        erros.append('arquivo: versao tem de ser 1')
    if h['trilha'] != slug:
        erros.append(f"arquivo: trilha '{h['trilha']}' diferente da trilha '{slug}'")
    arco = h['arco']
    if arco is not None and dart_len(arco) > C['maxArco']:
        erros.append(f"arquivo: arco com {dart_len(arco)} caracteres (máx. {C['maxArco']})")
    por_id = {l['id']: l for l in trilha['licoes']}
    for l in trilha['licoes']:
        if l['id'] not in h['licoes'] and avisos is not None:
            avisos.append(f"{l['id']}: sem história (trilha incompleta)")
    for lid, hl in h['licoes'].items():
        licao = por_id.get(lid)
        if licao is None:
            erros.append(f"{lid}: não é lição da trilha '{slug}'")
            continue
        erros.extend(validar_historia_licao(hl, licao))
    return erros


def erros_do_dart(j, trilha, avisos=None):
    """O que o Dart diria: a mensagem do parse estrito (se falhar) ou a lista do validarHistoriasDaTrilha.
    Devolve (erros, historia_ou_None)."""
    _, D, _ = motor()
    try:
        h = ler_trilha(j, trilha, D)
    except ErroParse as e:
        return [e.msg], None
    return validar_historias_da_trilha(h, trilha, avisos), h


def trilha_de_referencia(j, ts):
    """A trilha contra a qual um JSON é validado: a do 1º Licao.id em `licoes` (senão o campo `trilha`)."""
    lic = j.get('licoes') if isinstance(j, dict) else None
    slug = slug_da_licao(next(iter(lic))) if isinstance(lic, dict) and lic else None
    if slug is None and isinstance(j, dict) and isinstance(j.get('trilha'), str):
        slug = j['trilha']
    return ts.get(slug)


# ───────────────────────────── regras da RECEITA (o Dart não cobra) ─────────────────────────────

CENARIOS_VETADOS = {'cafe', 'campina', 'deserto', 'neve', 'vulcao', 'canion', 'floresta', 'vale', 'oasis'}
EFEITOS_EVITADOS = {'fogos', 'relampago', 'fumaca', 'estrelaCadente'}
CAMERAS_EVITADAS = {'panoramica'}
PROPS_EVITADAS = {'radio'}
ACOES_NUNCA = {'dirige', 'desce'}
ACOES_PROIBIDAS_VIDEOCHAMADA = {'anda', 'corre', 'senta'}
ACOES_PARCIMONIA = {'cai', 'treme', 'rodopia', 'dorme', 'arremessa', 'danca'}
EMOCOES_FECHO_RUINS = {'bravo', 'triste'}
EMOCOES_SORRISO = {'feliz', 'radiante'}
MAX_CLOSE_POR_LICAO = 2
MAX_TREMIDA_POR_TRILHA = 1
RX = '[receita] '


def checar_receita(slug, j, h, trilha, erros, avisos, stats):
    """Sobre o JSON cru `j` e a história já lida `h` (só roda quando o espelho do Dart leu o arquivo)."""
    m, _, R = motor()
    C = consts_licao()
    arco = j.get('arco') or ''
    for termo, rx in R.re_termos:
        if rx.search(arco):
            erros.append(f"{RX}{slug}: termo proibido '{termo}' no arco")
    por_id = {l['id']: l for l in trilha['licoes']}
    tremidas = 0
    for lid, hl in h['licoes'].items():
        lic = por_id[lid]
        if hl['titulo']:
            en = hl['titulo'][0].strip()
            if en and (en.endswith('.') or not en[0].isupper()):
                erros.append(f'{RX}{lid}: titulo.en com capitalização de frase e sem ponto final')
        falantes = {quem_no_palco(x['quem']) for x in lic['trechos']}
        closes = mudos = 0
        figs = set()
        for ci, cena in enumerate(hl['cenas']):
            ctx = f'{lid} cena[{ci}]'
            vc = cena['cenario'] == 'videochamada'
            if cena['cenario'] in CENARIOS_VETADOS:
                erros.append(f"{RX}{ctx}: cenário '{cena['cenario']}' não serve para as lições (pista ou exótico)")
            for a in cena['elenco']:
                if a['remoto'] is not None and a['remoto'] != 'celular':
                    erros.append(f"{RX}{ctx}: remoto '{a['remoto']}': nas lições só 'celular'")
                if vc and a['remoto'] is not None:
                    erros.append(f'{RX}{ctx}: videochamada não tem remoto (todos ficam presentes nas molduras)')
                if a['segura'] in PROPS_EVITADAS:
                    erros.append(f"{RX}{ctx}: prop '{a['segura']}' evitada nas lições")
                if a['quem'] in C['figurantesConhecidos'] and a['quem'] not in falantes:
                    figs.add(a['quem'])
            for o in cena['objetos']:
                if o['prop'] in PROPS_EVITADAS:
                    erros.append(f"{RX}{ctx}: prop '{o['prop']}' evitada nas lições")
            for n, f in enumerate(cena['falas'], 1):
                pc = f'{ctx} passo {n}'
                for x in [f] + f['reacoes']:
                    ac = x.get('acao')
                    if ac in ACOES_NUNCA:
                        erros.append(f"{RX}{pc}: acao '{ac}' é do carro (nunca nas lições)")
                    if vc and ac in ACOES_PROIBIDAS_VIDEOCHAMADA:
                        erros.append(f"{RX}{pc}: acao '{ac}' na videochamada (as molduras não andam)")
                    if x.get('efeito') in EFEITOS_EVITADOS:
                        erros.append(f"{RX}{pc}: efeito '{x.get('efeito')}' evitado nas lições")
                    if x.get('segura') in PROPS_EVITADAS:
                        erros.append(f"{RX}{pc}: prop '{x.get('segura')}' evitada nas lições")
                    if ac in ACOES_PARCIMONIA:
                        stats['parcimonia'].append(f'{pc}: {ac}')
                for mv in f['objetos']:
                    if mv['prop'] in PROPS_EVITADAS:
                        erros.append(f"{RX}{pc}: prop '{mv['prop']}' evitada nas lições")
                cam = f['camera']
                if cam in CAMERAS_EVITADAS:
                    erros.append(f"{RX}{pc}: camera '{cam}' evitada nas lições")
                if cam == 'close':
                    closes += 1
                    if f['quem'] == NARRADOR:
                        erros.append(f'{RX}{pc}: narrador não leva câmera close')
                if cam == 'tremida':
                    tremidas += 1
                if f['mudo']:
                    mudos += 1
        if closes > MAX_CLOSE_POR_LICAO:
            erros.append(f'{RX}{lid}: {closes} câmeras close (máx. {MAX_CLOSE_POR_LICAO} por lição)')
        if hl['cenas']:
            e = m.estado_inicial(hl['cenas'][-1])
            for f in hl['cenas'][-1]['falas']:
                e, _ = m.aplicar(R, e, f)
            emocoes = {q: a['emocao'] for q, a in e['atores'].items()}
            ruins = sorted(q for q, x in emocoes.items() if x in EMOCOES_FECHO_RUINS)
            if ruins:
                erros.append(f"{RX}{lid}: fecho com {', '.join(ruins)} bravo/triste (toda historinha termina num sorriso)")
            if not any(x in EMOCOES_SORRISO for x in emocoes.values()):
                erros.append(f'{RX}{lid}: fecho sem ninguém feliz/radiante (toda historinha termina num sorriso)')
            if 'voce' in emocoes and emocoes['voce'] not in EMOCOES_SORRISO | {'determinado', 'timido'}:
                avisos.append(f"{lid}: o voce termina '{emocoes['voce']}'")
        stats['licoes'] += 1
        stats['frases'] += len(lic['trechos'])
        stats['mudos'] += mudos
        stats['cenas'] += len(hl['cenas'])
        stats['figurantes'] += len(figs)
        stats['por_licao'].append((lid, len(lic['trechos']), len(hl['cenas']), mudos, sorted(figs)))
    if tremidas > MAX_TREMIDA_POR_TRILHA:
        erros.append(f'{RX}{slug}: {tremidas} câmeras tremida (máx. {MAX_TREMIDA_POR_TRILHA} por trilha)')


def novo_stats():
    return {'licoes': 0, 'frases': 0, 'mudos': 0, 'cenas': 0, 'figurantes': 0, 'por_licao': [], 'parcimonia': []}


def validar_trilha_obj(slug_arq, j, ts, stats, so_dart=False):
    """Um arquivo de trilha: nome do arquivo = campo trilha; depois o espelho do Dart e a receita."""
    erros, avisos = [], []
    if not isinstance(j, dict):
        return [f'{slug_arq}: o arquivo tem de ser um objeto JSON'], avisos
    trilha = ts.get(slug_arq)
    if trilha is None:
        # exemplo_licao.json, fixtures etc.: o nome não é um slug; vale a trilha do próprio conteúdo
        trilha = trilha_de_referencia(j, ts)
        if trilha is None:
            erros.append(f"arquivo: '{slug_arq}' não é slug de trilha e o conteúdo não aponta uma trilha do currículo")
            return erros, avisos
        avisos.append(f"o nome '{slug_arq}' não é um slug: validado contra a trilha "
                      f"'{slug_da_licao(trilha['licoes'][0]['id'])}' (num lote, o arquivo se chama <slug>.json)")
        slug_arq = slug_da_licao(trilha['licoes'][0]['id'])
    elif j.get('trilha') != slug_arq:
        erros.append(f"arquivo: trilha '{dart_str(j.get('trilha'))}' diferente do nome do arquivo '{slug_arq}'")
    e, h = erros_do_dart(j, trilha, avisos)
    erros += e
    if h is not None and not so_dart:
        checar_receita(slug_arq, j, h, trilha, erros, avisos, stats)
    return erros, avisos


def validar_arquivo(caminho, ts, so_dart=False):
    stats = novo_stats()
    try:
        j = json.load(open(caminho, encoding='utf-8'))
    except (OSError, ValueError) as e:
        return None, [f'JSON inválido: {e}'], stats
    if isinstance(j, dict) and 'arquivos' in j:  # pacote do lote
        erros, avisos = [], []
        for k in j:
            if k not in {'versao', 'lote', 'descricao', 'arquivos'}:
                erros.append(f"pacote: chave '{k}' desconhecida")
        arqs = j.get('arquivos')
        if not isinstance(arqs, dict) or not arqs:
            return erros + ['pacote: arquivos vazio'], avisos, stats
        for slug, arq in arqs.items():
            e, a = validar_trilha_obj(slug, arq, ts, stats, so_dart)
            erros += [f'[{slug}] {x}' for x in e]
            avisos += [f'[{slug}] {x}' for x in a]
        return erros, avisos, stats
    slug = os.path.splitext(os.path.basename(caminho))[0]
    e, a = validar_trilha_obj(slug, j, ts, stats, so_dart)
    return e, a, stats


def imprimir(erros, avisos, stats):
    for lid, nf, nc, nm, figs in stats['por_licao']:
        extra = f" · figurantes mudos: {', '.join(figs)}" if figs else ''
        print(f'  {lid}: {nf} frases · {nc} cena(s) · {nm} mudo(s){extra}')
    if stats['licoes']:
        print(f"Total: {stats['licoes']} lições · {stats['frases']} âncoras · {stats['cenas']} cenas · "
              f"{stats['mudos']} mudos · {stats['figurantes']} figurante(s) mudo(s)")
    if stats['parcimonia']:
        print('Ações de parcimônia (conferir humor leve): ' + '; '.join(stats['parcimonia']))
    for a in avisos:
        print(f'AVISO  {a}')
    for e in erros:
        print(f'ERRO   {e}')
    print(f'{len(erros)} erro(s), {len(avisos)} aviso(s).')


# ───────────────────────────── tabela encenacao_auto.json ─────────────────────────────

TAB_KEYS = {'cenario', 'hora', 'remotos', 'entram', 'mudos'}


def validar_tabela(j, ts):
    """encenacao_auto.json: uma entrada para CADA lição (plano §4.5/§10.3, I13), enums válidos e coerentes com
    o elenco da lição. Devolve (erros, avisos, contagem por cenário)."""
    _, D, R = motor()
    C = consts_licao()
    erros, avisos, por_cenario = [], [], {}
    if not isinstance(j, dict):
        return ['tabela: esperava um objeto JSON'], avisos, por_cenario
    for k in j:
        if k not in {'versao', 'licoes'}:
            erros.append(f"tabela: chave '{k}' desconhecida")
    if j.get('versao') != 1 or isinstance(j.get('versao'), bool):
        erros.append('tabela: versao tem de ser 1')
    lic = j.get('licoes')
    if not isinstance(lic, dict):
        return erros + ["tabela: 'licoes' tem de ser um objeto"], avisos, por_cenario
    licoes = {l['id']: l for t in ts.values() for l in t['licoes']}
    for lid in licoes:
        if lid not in lic:
            erros.append(f'{lid}: sem entrada na tabela (ela grava as {len(licoes)} lições)')
    for lid, e in lic.items():
        l = licoes.get(lid)
        if l is None:
            erros.append(f'{lid}: não é lição do currículo')
            continue
        if not isinstance(e, dict):
            erros.append(f'{lid}: esperava um objeto')
            continue
        for k in e:
            if k not in TAB_KEYS:
                erros.append(f"{lid}: chave '{k}' desconhecida")
        cen, hora = e.get('cenario'), e.get('hora')
        if cen not in D['CenarioHistoria']:
            erros.append(f"{lid}: cenario '{dart_str(cen)}' inválido" if cen is not None else f"{lid}: 'cenario' ausente")
        elif cen in C['cenariosSoDoTurismo']:
            erros.append(f"{lid}: cenário '{cen}' é só do Turismo")
        elif cen in CENARIOS_VETADOS:
            erros.append(f"{RX}{lid}: cenário '{cen}' não serve para as lições (pista ou exótico)")
        if hora not in D['HoraHistoria']:
            erros.append(f"{lid}: hora '{dart_str(hora)}' inválida" if hora is not None else f"{lid}: 'hora' ausente")
        elif cen in D['CenarioHistoria'] and hora not in R.horas(cen):
            erros.append(f"{lid}: hora '{hora}' não combina com '{cen}'")
        por_cenario[cen] = por_cenario.get(cen, 0) + 1
        ordem = []
        for t in l['trechos']:
            q = quem_no_palco(t['quem'])
            if q not in ordem:
                ordem.append(q)
        falantes = set(ordem)
        corpos = [q for q in ordem if q != NARRADOR]
        remotos = e.get('remotos', {})
        if not isinstance(remotos, dict):
            erros.append(f"{lid}: 'remotos' tem de ser um objeto {{quem: celular}}")
            remotos = {}
        for q, via in remotos.items():
            if via != 'celular':
                erros.append(f"{lid}: remoto '{q}' por '{dart_str(via)}' (nas lições só 'celular')")
            if q == 'voce':
                erros.append(f"{lid}: o voce nunca é remoto (é ele quem segura o celular)")
            elif q not in corpos:
                erros.append(f"{lid}: remoto '{q}' não fala nesta lição")
        if len(remotos) > 2:
            erros.append(f'{lid}: {len(remotos)} remotos (máx. 2)')
        if remotos and cen == 'videochamada':
            erros.append(f'{lid}: videochamada não tem remoto (todos ficam presentes nas molduras)')
        entram = e.get('entram', [])
        if not isinstance(entram, list):
            erros.append(f"{lid}: 'entram' tem de ser uma lista")
            entram = []
        primeira = {}
        for i, t in enumerate(l['trechos']):
            primeira.setdefault(quem_no_palco(t['quem']), i)
        for q in entram:
            if q == 'voce':
                erros.append(f'{lid}: o voce já começa no palco (não entra tarde)')
            elif q not in corpos:
                erros.append(f"{lid}: '{q}' entra tarde, mas não fala nesta lição")
            elif q in remotos:
                erros.append(f"{lid}: '{q}' é remoto e não entra no palco")
            elif primeira[q] == 0:
                erros.append(f"{lid}: '{q}' entra tarde, mas diz a 1ª frase da lição")
            elif primeira[q] == 1:
                avisos.append(f"{lid}: '{q}' entra tarde já antes da 2ª frase (o plano sugere da 3ª em diante)")
        if len(set(entram)) != len(entram):
            erros.append(f"{lid}: 'entram' repetido")
        if len(entram) > 2:
            erros.append(f'{lid}: {len(entram)} entradas tardias (máx. 2: cada uma vira um passo mudo)')
        mudos = e.get('mudos', [])
        if not isinstance(mudos, list):
            erros.append(f"{lid}: 'mudos' tem de ser uma lista")
            mudos = []
        figs = 0
        for q in mudos:
            if q in falantes:
                erros.append(f"{lid}: '{q}' fala nesta lição (mudos = presentes sem falar)")
            elif q in ('max', 'kim'):
                erros.append(f"{lid}: '{q}' é só do Turismo")
            elif q == 'voce':
                erros.append(f'{lid}: o voce entra sempre (não precisa estar em mudos)')
            elif q in C['figurantesConhecidos']:
                figs += 1
            elif q not in C['elencoDasLicoes']:
                erros.append(f"{lid}: '{q}' não é do elenco das lições nem figurante conhecido")
        if figs > C['maxFigurantesMudos']:
            erros.append(f"{lid}: {figs} figurantes mudos (máx. {C['maxFigurantesMudos']})")
        presentes = len([q for q in corpos if q not in remotos]) + (0 if 'voce' in corpos else 1) + len(set(mudos))
        if presentes > 5:
            erros.append(f'{lid}: {presentes} atores presentes (máx. 5)')
    return erros, avisos, por_cenario


# ───────────────────────────── pasta inteira (o que o lead copia) ─────────────────────────────

def validar_pasta(pasta, ts, so_dart=False):
    erros, avisos = [], []
    try:
        ind = json.load(open(os.path.join(pasta, 'indice.json'), encoding='utf-8'))
    except (OSError, ValueError) as e:
        return [f'indice.json: {e}'], avisos
    trilhas = ind.get('trilhas') if isinstance(ind, dict) else None
    if not isinstance(ind, dict) or ind.get('versao') != 1 or not isinstance(trilhas, dict):
        erros.append('indice.json: esperava {"versao": 1, "trilhas": {"<slug>": <versão>}}')
        trilhas = {}
    presentes = sorted(os.path.splitext(f)[0] for f in os.listdir(pasta)
                       if f.endswith('.json') and f not in ('indice.json', 'encenacao_auto.json'))
    for s in presentes:
        if s not in trilhas:
            erros.append(f'indice.json: falta a trilha {s} (o arquivo {s}.json existe)')
    for s, v in trilhas.items():
        if s not in presentes:
            erros.append(f'indice.json: lista {s}, mas {s}.json não existe')
        if not _e_int(v) or v < 1:
            erros.append(f'indice.json: versão de {s} tem de ser um inteiro ≥ 1')
    for s in presentes:
        e, a, st = validar_arquivo(os.path.join(pasta, f'{s}.json'), ts, so_dart)
        erros += [f'[{s}] {x}' for x in e]
        avisos += [f'[{s}] {x}' for x in a]
        print(f"  {s}: {st['licoes']} lições, {len(e)} erro(s)")
    tab = os.path.join(pasta, 'encenacao_auto.json')
    try:
        tj = json.load(open(tab, encoding='utf-8'))
    except (OSError, ValueError) as e:
        return erros + [f'encenacao_auto.json: {e}'], avisos
    e, a, _ = validar_tabela(tj, ts)
    erros += [f'[tabela] {x}' for x in e]
    avisos += [f'[tabela] {x}' for x in a]
    return erros, avisos


# ───────────────────────────── auto-teste ─────────────────────────────

def _ler_esperado(caminho):
    txt = open(caminho, encoding='utf-8').read()
    return [l for l in txt.split('\n') if l != '']


def auto_teste(ts):
    falhas = total = 0
    # 1. Paridade com o Dart: cada fixtures/<caso>.json tem de dar EXATAMENTE as linhas de <caso>.esperado.txt
    #    (geradas pelo Dart; a mesma lista que o test/historias_licoes_paridade_test.dart confere).
    casos = sorted(f[:-5] for f in os.listdir(FIXTURES) if f.endswith('.json')) if os.path.isdir(FIXTURES) else []
    if not casos:
        print(f'FALHOU  nenhum fixture em {FIXTURES}')
        return 1
    print(f'── paridade com o Dart ({len(casos)} fixtures) ──')
    for c in casos:
        total += 1
        j = json.load(open(os.path.join(FIXTURES, c + '.json'), encoding='utf-8'))
        esp_arq = os.path.join(FIXTURES, c + '.esperado.txt')
        if not os.path.isfile(esp_arq):
            falhas += 1
            print(f'FALHOU  {c}: falta {c}.esperado.txt')
            continue
        esperado = _ler_esperado(esp_arq)
        trilha = trilha_de_referencia(j, ts)
        if trilha is None:
            falhas += 1
            print(f'FALHOU  {c}: trilha de referência não encontrada no currículo')
            continue
        veio, _ = erros_do_dart(j, trilha)
        if veio == esperado:
            print(f"ok      {c}" + (f' ({len(veio)} msg)' if veio else ' (0 erros)'))
        else:
            falhas += 1
            print(f'FALHOU  {c}:\n   esperado {esperado}\n   veio     {veio}')
    # 2. Regras da receita (só Python): cada caso tem de produzir um erro com o trecho esperado.
    print('── regras da receita ──')
    base = json.load(open(os.path.join(AQUI, 'exemplo_licao.json'), encoding='utf-8'))
    lid = next(iter(base['licoes']))

    def caso(mut):
        j = json.loads(json.dumps(base))
        mut(j['licoes'][lid], j['licoes'][lid]['cenas'][0])
        return j

    receita = [
        ('exemplo limpo', lambda l, c: None, None),
        ('cenário vetado', lambda l, c: c.update(cenario='cafe'), 'não serve para as lições'),
        ('título com ponto', lambda l, c: l['titulo'].update(en='The first call.'), 'sem ponto final'),
        ('efeito evitado', lambda l, c: c['passos'][0].update(efeito='fogos'), 'evitado nas lições'),
        ('câmera evitada', lambda l, c: c['passos'][0].update(camera='panoramica'), "camera 'panoramica' evitada"),
        ('3 closes', lambda l, c: [c['passos'][i].update(camera='close') for i in (0, 1, 2)], 'câmeras close'),
        ('senta na videochamada', lambda l, c: c['passos'][1].update(acao='senta'), 'na videochamada'),
        ('fecho bravo', lambda l, c: c['passos'][-1]['reacoes'].append({'quem': 'voce', 'emocao': 'bravo'}),
         'bravo/triste'),
        ('remoto na videochamada', lambda l, c: (c['elenco'][1].pop('pos'), c['elenco'][1].update(remoto='celular'),
                                                 c['elenco'][0].update(segura='celular'),
                                                 c['passos'][1].pop('acao'), c['passos'][-1].pop('alvo'),
                                                 c['passos'][-1]['reacoes'][0].pop('acao'),
                                                 c['passos'][-1]['reacoes'][0].update(emocao='feliz')),
         'videochamada não tem remoto'),
    ]
    for nome, mut, esperado in receita:
        total += 1
        j = caso(mut)
        erros, avisos = validar_trilha_obj(slug_da_licao(lid), j, ts, novo_stats())
        ok = (not erros) if esperado is None else any(esperado in e and e.startswith(RX) for e in erros)
        print(('ok      ' if ok else 'FALHOU  ') + nome + ('' if ok else f': esperado {esperado!r}, veio {erros}'))
        falhas += 0 if ok else 1
    # 3. Tabela: os casos negativos têm de acusar; a tabela vazia acusa as lições que faltam.
    print('── tabela encenacao_auto.json ──')
    um = 'primeiro-contato.oi-tudo-bem'
    tab_casos = [
        ('cenário do Turismo', {'cenario': 'garagem', 'hora': 'dia'}, 'é só do Turismo'),
        ('hora inválida', {'cenario': 'casa', 'hora': 'meiodia'}, "hora 'meiodia' inválida"),
        ('remoto na videochamada', {'cenario': 'videochamada', 'hora': 'dia', 'remotos': {'mike': 'celular'}},
         'videochamada não tem remoto'),
        ('voce remoto', {'cenario': 'casa', 'hora': 'dia', 'remotos': {'voce': 'celular'}}, 'o voce nunca é remoto'),
        ('entra quem abre', {'cenario': 'casa', 'hora': 'dia', 'entram': ['voce']}, 'não entra tarde'),
        ('mudo que fala', {'cenario': 'casa', 'hora': 'dia', 'mudos': ['mike']}, 'fala nesta lição'),
        ('2 figurantes valem', {'cenario': 'casa', 'hora': 'dia', 'mudos': ['caixa', 'garcom']}, None),
        ('3 figurantes', {'cenario': 'casa', 'hora': 'dia', 'mudos': ['caixa', 'garcom', 'oficial']},
         '3 figurantes mudos (máx. 2)'),
        ('Max mudo', {'cenario': 'casa', 'hora': 'dia', 'mudos': ['max']}, 'só do Turismo'),
        ('chave estranha', {'cenario': 'casa', 'hora': 'dia', 'clima': []}, "chave 'clima' desconhecida"),
    ]
    for nome, entrada, esperado in tab_casos:
        total += 1
        erros, _, _ = validar_tabela({'versao': 1, 'licoes': {um: entrada}}, {'primeiro-contato': ts['primeiro-contato']})
        erros = [e for e in erros if 'sem entrada na tabela' not in e]
        ok = (not erros) if esperado is None else any(esperado in e for e in erros)
        print(('ok      ' if ok else 'FALHOU  ') + nome + ('' if ok else f': esperado {esperado!r}, veio {erros}'))
        falhas += 0 if ok else 1
    total += 1
    erros, _, _ = validar_tabela({'versao': 1, 'licoes': {}}, {'primeiro-contato': ts['primeiro-contato']})
    ok = len([e for e in erros if 'sem entrada na tabela' in e]) == len(ts['primeiro-contato']['licoes'])
    print(('ok      ' if ok else 'FALHOU  ') + 'tabela vazia acusa todas as lições')
    falhas += 0 if ok else 1
    print(f'\nauto-teste: {total - falhas}/{total} casos ok.')
    return 1 if falhas else 0


# ───────────────────────────── main ─────────────────────────────

def main(argv):
    global DART
    args = argv[1:]

    def opc(nome, padrao):
        if nome in args:
            i = args.index(nome)
            v = args[i + 1]
            del args[i:i + 2]
            return v
        return padrao

    curriculo = opc('--curriculo', CURRICULO)
    DART = opc('--dart', DART)
    tabela = opc('--tabela', None)
    pasta = opc('--pasta', None)
    so_dart = '--so-dart' in args
    args = [a for a in args if a != '--so-dart']
    try:
        ts = trilhas_por_slug(curriculo)
    except (OSError, ValueError) as e:
        print(f'currículo ilegível ({curriculo}): {e}', file=sys.stderr)
        return 2
    if '--auto-teste' in args:
        return auto_teste(ts)
    if tabela:
        try:
            j = json.load(open(tabela, encoding='utf-8'))
        except (OSError, ValueError) as e:
            print(f'JSON inválido: {e}', file=sys.stderr)
            return 2
        erros, avisos, por_cenario = validar_tabela(j, ts)
        n = len(j.get('licoes') or {}) if isinstance(j, dict) else 0
        print(f'{n} lições na tabela · ' + ', '.join(f'{c} {k}' for c, k in
                                                    sorted(por_cenario.items(), key=lambda x: (-x[1], str(x[0])))))
        for a in avisos:
            print(f'AVISO  {a}')
        for e in erros:
            print(f'ERRO   {e}')
        print(f'{len(erros)} erro(s), {len(avisos)} aviso(s).')
        return 1 if erros else 0
    if pasta:
        erros, avisos = validar_pasta(pasta, ts, so_dart)
        for a in avisos:
            print(f'AVISO  {a}')
        for e in erros:
            print(f'ERRO   {e}')
        print(f'{len(erros)} erro(s), {len(avisos)} aviso(s).')
        return 1 if erros else 0
    if not args:
        print(__doc__, file=sys.stderr)
        return 2
    codigo = 0
    for caminho in args:
        print(f'== {caminho}')
        erros, avisos, stats = validar_arquivo(caminho, ts, so_dart)
        if erros is None:
            print(avisos[0], file=sys.stderr)
            return 2
        imprimir(erros, avisos, stats)
        codigo = max(codigo, 1 if erros else 0)
    return codigo


if __name__ == '__main__':
    sys.exit(main(sys.argv))
