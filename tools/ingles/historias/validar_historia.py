#!/usr/bin/env python3
"""Validador offline da história do English Turismo ("The Golden Wheel").

Cópia de $SP/historia/validar_historia.py (só os caminhos padrão mudaram: agora relativos ao repo). O
validar_historias_licoes.py importa daqui o motor da cena (ler_dart, Regras, estado_inicial, aplicar).

Uso:
    python3 -I validar_historia.py parte_a.json [parte_b.json parte_c.json] [--dart CAMINHO] [--resumo]

Lê os enums e as consts de lib/features/arcade/domain/historia_turismo.dart por regex (sem cópia manual) e
aplica as regras da seção 11.4 do plano, incluindo a simulação de posições (espelho de SimulacaoCena).
Em divergência, O DART MANDA: o teste de conteúdo roda HistoriaTurismo.dasPartes(estrito: true).validar().

Saída: relatório de palavras por fala (ou só por capítulo com --resumo), avisos e erros.
Código de saída: 0 sem erros, 1 com erros, 2 uso/arquivo inválido.
"""
import json
import os
import re
import sys

# Caminhos padrão: relativos ao repo quando este arquivo está em <repo>/tools/ingles/historias/ (depois da
# integração); senão, o projeto em /Users/fazplay/pac_dart (o scratchpad do lote).
_AQUI = os.path.dirname(os.path.abspath(__file__))
_REPO = os.path.normpath(os.path.join(_AQUI, '..', '..', '..'))
if not os.path.isfile(os.path.join(_REPO, 'lib', 'features', 'arcade', 'domain', 'historia_turismo.dart')):
    _REPO = '/Users/fazplay/pac_dart'
DART_PADRAO = os.path.join(_REPO, 'lib', 'features', 'arcade', 'domain', 'historia_turismo.dart')
VOZES_PADRAO = os.path.join(_REPO, 'assets', 'ingles', 'vozes.json')


# ───────────────────────────── leitura do Dart ─────────────────────────────

def _strings(trecho):
    r = []
    for m in re.finditer(r"'((?:[^'\\]|\\.)*)'|\"((?:[^\"\\]|\\.)*)\"", trecho):
        s = m.group(1) if m.group(1) is not None else m.group(2)
        r.append(s.replace("\\'", "'").replace('\\"', '"'))
    return r


def _sem_comentarios(src):
    return re.sub(r'//[^\n]*', '', src)


def ler_dart(caminho):
    src = open(caminho, encoding='utf-8').read()
    limpo = _sem_comentarios(src)
    d = {}

    def enum(nome):
        m = re.search(r'enum\s+' + nome + r'\s*\{([^}]*)\}', limpo)
        if not m:
            raise SystemExit(f'enum {nome} não encontrado em {caminho}')
        corpo = m.group(1).split(';')[0]
        return [v.strip() for v in corpo.split(',') if v.strip()]

    for nome in ['NivelIngles', 'ParteDoCapitulo', 'PosicaoPalco', 'ViaRemota', 'AcaoAtor', 'CenarioHistoria',
                 'HoraHistoria', 'ClimaHistoria', 'EfeitoHistoria', 'PropHistoria', 'AcaoObjeto', 'CameraHistoria']:
        d[nome] = enum(nome)
    # Expressao mora no domínio do inglês
    exp = os.path.join(os.path.dirname(caminho), '..', '..', 'ingles', 'domain', 'expressao.dart')
    m = re.search(r'enum\s+Expressao\s*\{([^}]*)\}', _sem_comentarios(open(exp, encoding='utf-8').read()))
    d['Expressao'] = [v.strip() for v in m.group(1).split(',') if v.strip()]

    def bloco(nome, abre='{', fecha='}'):
        m = re.search(r'const\s+[^=;]*\b' + nome + r'\s*=\s*' + re.escape(abre) + r'(.*?)' + re.escape(fecha) + r'\s*;',
                      limpo, re.S)
        if not m:
            raise SystemExit(f'const {nome} não encontrada em {caminho}')
        return m.group(1)

    d['personagens'] = set(_strings(bloco('personagensHistoria')))
    d['narrador'] = re.search(r"const\s+narrador\s*=\s*'([^']+)'", limpo).group(1)
    d['interiores'] = set(re.findall(r'CenarioHistoria\.(\w+)', bloco('interioresHistoria')))
    d['espaciais'] = set(re.findall(r'CenarioHistoria\.(\w+)', bloco('espaciaisHistoria')))
    d['mundo'] = {int(n): c for n, c in re.findall(r'(\d+)\s*:\s*CenarioHistoria\.(\w+)', bloco('cenarioDaPista'))}
    d['titulos'] = _strings(bloco('_titulosEn', '[', ']'))
    d['reacao'] = set(re.findall(r'AcaoAtor\.(\w+)', bloco('acoesDeReacao')))
    pares = bloco('paresDeInterferencia', '[', ']')
    d['pares'] = [tuple(_strings(t)) for t in re.findall(r'\(([^()]*)\)', pares)]
    d['termos'] = _strings(bloco('termosProibidos', '[', ']'))
    d['nomesProprios'] = set(_strings(bloco('_nomesProprios')))
    m = re.search(r'maxPalavras\s*=>\s*const\s*\[([^\]]*)\]', limpo)
    maxp = [int(x) for x in m.group(1).split(',')]
    fi = re.search(r'faixaIntro\s*=>\s*const\s*\[(.*?)\]\s*\[index\]', limpo, re.S).group(1)
    ff = re.search(r'faixaFim\s*=>\s*const\s*\[(.*?)\]\s*\[index\]', limpo, re.S).group(1)
    tup = lambda s: [(int(a), int(b)) for a, b in re.findall(r'\((\d+)\s*,\s*(\d+)\)', s)]
    d['nivel'] = {n.upper(): (maxp[i], tup(fi)[i], tup(ff)[i]) for i, n in enumerate(d['NivelIngles'])}
    a, b = re.search(r'faixaFimFinal\s*=\s*\((\d+)\s*,\s*(\d+)\)', limpo).groups()
    d['faixaFimFinal'] = (int(a), int(b))
    # conferências mínimas do que foi lido
    assert len(d['mundo']) == 30 and len(d['titulos']) == 30, 'cenarioDaPista/_titulosEn incompletos'
    assert all(len(p) == 2 for p in d['pares']), 'paresDeInterferencia malformado'
    return d


# ───────────────────────────── parse (estrito) ─────────────────────────────

class Pular(Exception):
    pass


CH_KEYS = {'pista', 'nivel', 'titulo', 'resumo', 'palavras', 'intro', 'fim', 'gancho'}
CENA_KEYS = {'cenario', 'hora', 'clima', 'elenco', 'objetos', 'falas'}
ATOR_KEYS = {'quem', 'pos', 'visivel', 'remoto', 'segura', 'emocao', 'noCarro'}
OBJ_KEYS = {'prop', 'pos', 'visivel'}
FALA_KEYS = {'quem', 'en', 'pt', 'pt_f', 'mudo', 'emocao', 'acao', 'alvo', 'para', 'camera', 'efeito', 'clima',
             'segura', 'cenario', 'hora', 'reacoes', 'objetos'}
REAC_KEYS = {'quem', 'emocao', 'acao', 'efeito', 'segura'}
MOV_KEYS = {'prop', 'acao', 'pos', 'de'}
BIL_KEYS = {'en', 'pt'}
FEMININOS = {'emocao', 'acao', 'hora', 'camera', 'pos', 'para'}


class Leitor:
    def __init__(self, D, erros):
        self.D = D
        self.erros = erros

    def falha(self, ctx, msg, fatal=False):
        self.erros.append(f'{ctx}: {msg}')
        if fatal:
            raise Pular()

    def chaves(self, j, validas, ctx):
        if not isinstance(j, dict):
            self.falha(ctx, 'esperava um objeto JSON', True)
        for k in j:
            if k not in validas:
                self.falha(ctx, f"chave '{k}' desconhecida")

    def texto(self, j, campo, ctx, obrigatorio=True):
        v = j.get(campo)
        if v is None:
            if obrigatorio:
                self.falha(ctx, f"'{campo}' ausente ou não é texto", True)
            return None
        if not isinstance(v, str):
            self.falha(ctx, f"'{campo}' não é texto", obrigatorio)
            return None
        return v

    def booleano(self, j, campo, padrao, ctx):
        v = j.get(campo)
        if v is None:
            return padrao
        if isinstance(v, bool):
            return v
        self.falha(ctx, f"'{campo}' não é true/false")
        return padrao

    def enum(self, nome_enum, j, campo, ctx, obrigatorio=False, padrao=None):
        v = j.get(campo)
        if v is None:
            if obrigatorio and padrao is None:
                self.falha(ctx, f"'{campo}' ausente", True)
            return padrao
        if v in self.D[nome_enum]:
            return v
        g = 'inválida' if campo in FEMININOS else 'inválido'
        self.falha(ctx, f"{campo} '{v}' {g}", obrigatorio and padrao is None)
        return padrao

    def lista(self, j, campo, ctx, obrigatorio=False):
        v = j.get(campo)
        if v is None:
            if obrigatorio:
                self.falha(ctx, f"'{campo}' ausente", True)
            return []
        if not isinstance(v, list):
            self.falha(ctx, f"'{campo}' não é uma lista", True)
        return v

    def bilingue(self, j, ctx):
        self.chaves(j, BIL_KEYS, ctx)
        return {'en': self.texto(j, 'en', ctx), 'pt': self.texto(j, 'pt', ctx)}

    def climas(self, lista, ctx):
        r = []
        for v in lista:
            if v in self.D['ClimaHistoria']:
                r.append(v)
            else:
                self.falha(ctx, f"clima '{v}' inválido")
        return r

    def ator(self, j, ctx):
        self.chaves(j, ATOR_KEYS, ctx)
        return {
            'quem': self.texto(j, 'quem', ctx),
            'pos': self.enum('PosicaoPalco', j, 'pos', ctx),
            'visivel': self.booleano(j, 'visivel', True, ctx),
            'remoto': self.enum('ViaRemota', j, 'remoto', ctx),
            'segura': self.enum('PropHistoria', j, 'segura', ctx),
            'emocao': self.enum('Expressao', j, 'emocao', ctx, padrao='neutro'),
            'noCarro': self.booleano(j, 'noCarro', False, ctx),
        }

    def objeto(self, j, ctx):
        self.chaves(j, OBJ_KEYS, ctx)
        return {
            'prop': self.enum('PropHistoria', j, 'prop', ctx, obrigatorio=True),
            'pos': self.enum('PosicaoPalco', j, 'pos', ctx, obrigatorio=True),
            'visivel': self.booleano(j, 'visivel', True, ctx),
        }

    def reacao(self, j, ctx):
        self.chaves(j, REAC_KEYS, ctx)
        return {
            'quem': self.texto(j, 'quem', ctx),
            'emocao': self.enum('Expressao', j, 'emocao', ctx),
            'acao': self.enum('AcaoAtor', j, 'acao', ctx),
            'efeito': self.enum('EfeitoHistoria', j, 'efeito', ctx),
            'segura': self.enum('PropHistoria', j, 'segura', ctx),
        }

    def movimento(self, j, ctx):
        self.chaves(j, MOV_KEYS, ctx)
        return {
            'prop': self.enum('PropHistoria', j, 'prop', ctx, obrigatorio=True),
            'acao': self.enum('AcaoObjeto', j, 'acao', ctx, obrigatorio=True),
            'pos': self.enum('PosicaoPalco', j, 'pos', ctx),
            'de': self.texto(j, 'de', ctx, obrigatorio=False),
        }

    def fala(self, j, ctx):
        self.chaves(j, FALA_KEYS, ctx)
        reacoes = self.lista(j, 'reacoes', ctx)
        objetos = self.lista(j, 'objetos', ctx)
        return {
            'quem': self.texto(j, 'quem', ctx),
            'en': self.texto(j, 'en', ctx, False),
            'pt': self.texto(j, 'pt', ctx, False),
            'ptF': self.texto(j, 'pt_f', ctx, False),
            'mudo': self.booleano(j, 'mudo', False, ctx),
            'emocao': self.enum('Expressao', j, 'emocao', ctx),
            'acao': self.enum('AcaoAtor', j, 'acao', ctx, padrao='parado'),
            'alvo': self.texto(j, 'alvo', ctx, False),
            'para': self.enum('PosicaoPalco', j, 'para', ctx),
            'camera': self.enum('CameraHistoria', j, 'camera', ctx),
            'efeito': self.enum('EfeitoHistoria', j, 'efeito', ctx),
            'clima': None if j.get('clima') is None else self.climas(self.lista(j, 'clima', ctx), ctx),
            'segura': self.enum('PropHistoria', j, 'segura', ctx),
            'cenario': self.enum('CenarioHistoria', j, 'cenario', ctx),
            'hora': self.enum('HoraHistoria', j, 'hora', ctx),
            'reacoes': [self.reacao(r, f'{ctx} reacoes[{i}]') for i, r in enumerate(reacoes)],
            'objetos': [self.movimento(m, f'{ctx} objetos[{i}]') for i, m in enumerate(objetos)],
        }

    def cena(self, j, ctx):
        self.chaves(j, CENA_KEYS, ctx)
        elenco = self.lista(j, 'elenco', ctx)
        objetos = self.lista(j, 'objetos', ctx)
        falas = self.lista(j, 'falas', ctx, obrigatorio=True)
        return {
            'cenario': self.enum('CenarioHistoria', j, 'cenario', ctx, obrigatorio=True),
            'hora': self.enum('HoraHistoria', j, 'hora', ctx, obrigatorio=True),
            'clima': self.climas(self.lista(j, 'clima', ctx), ctx),
            'elenco': [self.ator(a, f'{ctx} elenco[{i}]') for i, a in enumerate(elenco)],
            'objetos': [self.objeto(o, f'{ctx} objetos[{i}]') for i, o in enumerate(objetos)],
            'falas': [self.fala(f, f'{ctx} fala {i + 1}') for i, f in enumerate(falas)],
        }

    def capitulo(self, j, ctx):
        self.chaves(j, CH_KEYS, ctx)
        pista = j.get('pista')
        if not isinstance(pista, int) or isinstance(pista, bool):
            self.falha(ctx, "'pista' ausente ou não é inteiro", True)
        c = f'cap {pista}'
        nivel = j.get('nivel')
        if nivel not in self.D['nivel']:
            self.falha(c, f"nivel '{nivel}' inválido", True)
        palavras = self.lista(j, 'palavras', c, True)
        intro = self.lista(j, 'intro', c, True)
        fim = self.lista(j, 'fim', c, True)
        cap = {
            'pista': pista,
            'nivel': nivel,
            'titulo': self.bilingue(j.get('titulo') or {}, f'{c} titulo'),
            'resumo': self.texto(j, 'resumo', c),
            'palavras': [],
            'intro': [self.cena(x, f'{c} intro[{i}]') for i, x in enumerate(intro)],
            'fim': [self.cena(x, f'{c} fim[{i}]') for i, x in enumerate(fim)],
            'gancho': None if j.get('gancho') is None else self.bilingue(j['gancho'], f'{c} gancho'),
        }
        for i, p in enumerate(palavras):
            pc = f'{c} palavras[{i}]'
            self.chaves(p, BIL_KEYS, pc)
            cap['palavras'].append({'en': self.texto(p, 'en', pc), 'pt': self.texto(p, 'pt', pc)})
        return cap


# ───────────────────────────── regras (espelho do Dart) ─────────────────────────────

class Regras:
    def __init__(self, D):
        self.D = D
        self.re_termos = [(t, re.compile(r'(?<![^\W_])' + re.escape(t) + r'(?![^\W_])', re.I)) for t in D['termos']]

    def horas(self, c):
        return {'noite'} if c in self.D['espaciais'] else set(self.D['HoraHistoria'])

    def clima_ok(self, cl, c, h):
        D = self.D
        if cl in ('estrelas', 'aurora') and h != 'noite':
            return False
        if c == 'estacao':
            return cl in ('estrelas', 'neon')
        if c in D['interiores']:
            return cl in ('chuva', 'neve')
        if c in ('espaco', 'lua'):
            return cl == 'estrelas'
        if c == 'marte' and cl not in ('areia', 'vento', 'estrelas'):
            return False
        if cl == 'arcoIris':
            return h in ('dia', 'tarde') and c != 'marte'
        if cl == 'neon':
            return c in ('cidade', 'estacao', 'autodromo', 'podio')
        return True

    @staticmethod
    def nivel_da_pista(p):
        return 'A1' if p <= 8 else 'A2' if p <= 16 else 'B1' if p <= 24 else 'B2'


POS_IDX = None  # preenchido em main (ordem do enum PosicaoPalco)


def olha_para_o_centro(pos):
    return pos is not None and POS_IDX[pos] > POS_IDX['centro']


def carro_de(quem):
    return 'carroRival' if quem == 'max' else 'carro'


def estado_inicial(cena):
    atores = {}
    for a in cena['elenco']:
        rem = a['remoto']
        atores[a['quem']] = {
            'pos': None if rem else a['pos'],
            'visivel': (not rem) and a['visivel'],
            'remoto': rem,
            'emocao': a['emocao'],
            'segura': None if a['segura'] == 'nada' else a['segura'],
            'noCarro': (not rem) and a['noCarro'],
            'sentado': False,
            'dormindo': False,
            'esq': olha_para_o_centro(a['pos']),
        }
    return {
        'cenario': cena['cenario'], 'hora': cena['hora'], 'clima': list(cena['clima']), 'camera': 'geral',
        'atores': atores,
        'objetos': [{'prop': o['prop'], 'pos': o['pos'], 'visivel': o['visivel'], 'abs': None} for o in cena['objetos']],
    }


def copia(e):
    return {
        'cenario': e['cenario'], 'hora': e['hora'], 'clima': list(e['clima']), 'camera': e['camera'],
        'atores': {k: dict(v) for k, v in e['atores'].items()},
        'objetos': [dict(o) for o in e['objetos']],
    }


def no_palco(a):
    return a['remoto'] is None and a['visivel']


def estados_da_acao(a, acao):
    if acao == 'senta':
        a['sentado'] = True
    if acao in ('pula', 'comemora', 'anda', 'corre', 'sai', 'entra', 'danca'):
        a['sentado'] = False
    if acao == 'dorme':
        a['dormindo'] = True
    elif acao != 'parado':
        a['dormindo'] = False


def aplicar(R, antes, f):
    """Espelho de SimulacaoCena.aplicar: (depois, erros do passo sem prefixo)."""
    D = R.D
    e = copia(antes)
    erros = []
    quem = f['quem']
    narr = quem == D['narrador']
    ator = None if narr else e['atores'].get(quem)

    if f['mudo']:
        if f['en'] is not None or f['pt'] is not None or f['ptF'] is not None:
            erros.append('passo mudo não leva en/pt')
        if narr or ator is None or ator['remoto']:
            erros.append('passo mudo exige um ator presente')
        if (f['acao'] == 'parado' and f['efeito'] is None and f['emocao'] is None and f['segura'] is None
                and not f['objetos'] and not f['reacoes']):
            erros.append('passo mudo sem nada acontecendo (acao, efeito, emocao, segura, objetos ou reacoes)')
    else:
        if not (f['en'] or '').strip():
            erros.append("'en' obrigatório (ou \"mudo\": true)")
        if not (f['pt'] or '').strip():
            erros.append("'pt' obrigatório (ou \"mudo\": true)")
    if f['ptF'] is not None and f['pt'] is None:
        erros.append("'pt_f' só junto com 'pt'")
    if not narr and ator is None:
        erros.append(f"'{quem}' não está no elenco da cena")

    # 1. cenário / hora / clima
    if f['cenario'] is not None:
        e['cenario'] = f['cenario']
    if f['hora'] is not None:
        e['hora'] = f['hora']
    if f['clima'] is not None:
        if len(set(f['clima'])) != len(f['clima']):
            erros.append('clima repetido')
        e['clima'] = list(f['clima'])
    if f['cenario'] is not None or f['hora'] is not None or f['clima'] is not None:
        if e['hora'] not in R.horas(e['cenario']):
            erros.append(f"hora '{e['hora']}' não combina com '{e['cenario']}'")
        for cl in e['clima']:
            if not R.clima_ok(cl, e['cenario'], e['hora']):
                erros.append(f"clima '{cl}' não combina com '{e['cenario']}'/'{e['hora']}'")
    if f['camera'] is not None:
        e['camera'] = f['camera']

    palco = [a for a in e['atores'].values() if no_palco(a)]
    if narr:
        if f['acao'] != 'parado':
            erros.append('o narrador não faz ação')
        if f['segura'] is not None:
            erros.append('o narrador não segura nada')
    elif ator is not None:
        if ator['remoto']:
            if f['acao'] != 'parado':
                erros.append(f"'{quem}' é remoto: só acao parado")
            if f['segura'] is not None:
                erros.append(f"'{quem}' é remoto: não segura nada")
            if ator['remoto'] == 'radio':
                if not any(a['segura'] == 'radio' or a['noCarro'] for a in palco):
                    erros.append(f"'{quem}' fala pelo rádio, mas ninguém no palco segura radio nem está no carro")
            elif not any(a['segura'] == 'celular' for a in palco):
                erros.append(f"'{quem}' fala pelo celular, mas ninguém no palco segura celular")
        elif not ator['visivel'] and f['acao'] != 'entra':
            erros.append(f"'{quem}' não está visível (use acao entra)")

    alvo = f['alvo']
    pos_alvo = None
    alvo_ator = alvo_prop = False
    if alvo is not None:
        a = e['atores'].get(alvo)
        if a is not None:
            alvo_ator = True
            if not no_palco(a) or alvo == quem:
                erros.append(f"alvo '{alvo}' tem de ser outro ator presente e visível")
            pos_alvo = a['pos']
        else:
            objs = [o for o in e['objetos'] if o['visivel'] and o['prop'] == alvo] if alvo in D['PropHistoria'] else []
            if not objs:
                erros.append(f"alvo '{alvo}' não é ator presente nem objeto visível")
            else:
                alvo_prop = True
                pos_alvo = objs[0]['pos']
    if f['acao'] in ('abraca', 'arremessa', 'olha') and alvo is None:
        erros.append(f"acao '{f['acao']}' exige alvo")
    if f['camera'] == 'dupla' and not alvo_ator:
        erros.append('camera dupla exige alvo ator')
    desloca = f['acao'] in ('anda', 'corre')
    if desloca and f['para'] is None:
        erros.append(f"acao '{f['acao']}' exige para")
    if f['para'] is not None and not desloca and f['acao'] != 'entra':
        erros.append("'para' só em anda, corre ou entra")

    # 2. ação do falante
    if ator is not None and not ator['remoto']:
        segura_no_passo = f['segura'] is not None and f['segura'] != 'nada'
        acao = f['acao']
        if acao == 'entra':
            if ator['visivel']:
                erros.append(f"'{quem}' já está visível (entra)")
            ator['visivel'] = True
            if f['para'] is not None:
                ator['pos'] = f['para']
            ator['esq'] = olha_para_o_centro(ator['pos'])
        elif acao == 'sai':
            if not ator['visivel']:
                erros.append(f"'{quem}' já saiu (sai)")
            ator['visivel'] = False
            ator['noCarro'] = False
        elif desloca:
            if f['para'] is not None:
                if ator['pos'] is not None and f['para'] != ator['pos']:
                    ator['esq'] = POS_IDX[f['para']] < POS_IDX[ator['pos']]
                ator['pos'] = f['para']
        elif acao == 'dirige':
            if ator['noCarro']:
                erros.append(f"'{quem}' já está no carro (dirige)")
            else:
                ator['noCarro'] = True
                for o in e['objetos']:
                    if o['visivel'] and o['pos'] == ator['pos'] and o['prop'] in ('carro', 'carroRival'):
                        o['visivel'] = False
                        o['abs'] = quem
                        break
        elif acao == 'desce':
            if not ator['noCarro']:
                erros.append(f"'{quem}' não está no carro (desce)")
            else:
                ator['noCarro'] = False
                o = next((o for o in e['objetos'] if o['abs'] == quem), None)
                if o is not None:
                    o.update(abs=None, visivel=True, pos=ator['pos'])
                else:
                    e['objetos'].append({'prop': carro_de(quem), 'pos': ator['pos'], 'visivel': True, 'abs': None})
        elif acao == 'mostra':
            if ator['segura'] is None and not segura_no_passo:
                erros.append(f"'{quem}' mostra sem nada na mão")
        elif acao == 'escreve':
            if ator['segura'] is None and not segura_no_passo and not alvo_prop:
                erros.append(f"'{quem}' escreve sem prop na mão nem alvo objeto")
        estados_da_acao(ator, acao)
        if pos_alvo is not None and ator['pos'] is not None and pos_alvo != ator['pos'] and not desloca and acao != 'entra':
            ator['esq'] = POS_IDX[pos_alvo] < POS_IDX[ator['pos']]

    # 3. segura e 4. emoção
    if ator is not None and not ator['remoto'] and f['segura'] is not None:
        ator['segura'] = None if f['segura'] == 'nada' else f['segura']
    if ator is not None and f['emocao'] is not None:
        ator['emocao'] = f['emocao']

    # 5. reações
    if len(f['reacoes']) > 4:
        erros.append(f"{len(f['reacoes'])} reações (máx. 4)")
    for r in f['reacoes']:
        ra = e['atores'].get(r['quem'])
        if ra is None:
            erros.append(f"reação de '{r['quem']}', que não está no elenco")
            continue
        if r['quem'] == quem:
            erros.append(f"'{r['quem']}' não reage à própria fala")
        if r['emocao'] is None and r['acao'] is None and r['efeito'] is None and r['segura'] is None:
            erros.append(f"reação de '{r['quem']}' vazia")
        if ra['remoto']:
            if r['acao'] is not None or r['efeito'] is not None or r['segura'] is not None:
                erros.append(f"'{r['quem']}' é remoto: a reação só leva emocao")
            if r['emocao'] is not None:
                ra['emocao'] = r['emocao']
            continue
        if not ra['visivel']:
            erros.append(f"reação de '{r['quem']}', que não está visível")
        if r['segura'] is not None:
            ra['segura'] = None if r['segura'] == 'nada' else r['segura']
        acao = r['acao']
        if acao is not None:
            if acao not in D['reacao']:
                erros.append(f"acao '{acao}' não vale numa reação")
            else:
                if acao in ('mostra', 'escreve') and ra['segura'] is None:
                    erros.append(f"reação '{acao}' de '{r['quem']}' sem nada na mão")
                estados_da_acao(ra, acao)
                pf = ator['pos'] if ator is not None else None
                if acao == 'olha' and pf is not None and ra['pos'] is not None and pf != ra['pos']:
                    ra['esq'] = POS_IDX[pf] < POS_IDX[ra['pos']]
        if r['emocao'] is not None:
            ra['emocao'] = r['emocao']

    # 6. objetos
    if len(f['objetos']) > 3:
        erros.append(f"{len(f['objetos'])} movimentos de objeto (máx. 3)")
    for m in f['objetos']:
        movimento(e, m, erros)

    vistos = set()
    for a in e['atores'].values():
        if no_palco(a) and a['pos'] is not None:
            if a['pos'] in vistos:
                erros.append(f"dois atores em '{a['pos']}'")
            vistos.add(a['pos'])
    vistos = set()
    for o in e['objetos']:
        if o['visivel'] and o['pos'] is not None:
            if o['pos'] in vistos:
                erros.append(f"dois objetos em '{o['pos']}'")
            vistos.add(o['pos'])
    return e, erros


def movimento(e, m, erros):
    nome = f"'{m['prop']}' ({m['acao']})"
    if m['prop'] == 'nada':
        erros.append("objeto 'nada' não se mexe")
    if m['acao'] in ('aparece', 'entra') and m['pos'] is None:
        erros.append(f'{nome} exige pos')
    if m['acao'] == 'passa' and m['pos'] is not None:
        erros.append(f'{nome} não leva pos')
    dono = None
    de = m['de']
    if de is not None:
        a = e['atores'].get(de)
        if a is None or not no_palco(a):
            erros.append(f"{nome}: de '{de}' tem de ser um ator presente e visível")
        elif a['segura'] != m['prop']:
            erros.append(f"{nome}: '{de}' não segura '{m['prop']}'")
        else:
            dono = a
            a['segura'] = None
    vis = [o for o in e['objetos'] if o['visivel'] and o['prop'] == m['prop']]
    if m['acao'] in ('aparece', 'entra'):
        if m['pos'] is None:
            return
        guardado = None if de is not None else next(
            (o for o in e['objetos'] if not o['visivel'] and o['abs'] is None and o['prop'] == m['prop']), None)
        if guardado is not None:
            guardado.update(visivel=True, pos=m['pos'])
        else:
            e['objetos'].append({'prop': m['prop'], 'pos': m['pos'], 'visivel': True, 'abs': None})
    elif m['acao'] == 'passa':
        pass
    elif m['acao'] in ('some', 'sai', 'voa'):
        if de is not None:
            return
        if len(vis) != 1:
            erros.append(f'{nome}: precisa de exatamente 1 objeto visível com esse prop (há {len(vis)})')
        else:
            vis[0]['visivel'] = False
    else:  # roda, treme
        if de is not None:
            if dono is not None:
                e['objetos'].append({'prop': m['prop'], 'pos': m['pos'] or dono['pos'], 'visivel': True, 'abs': None})
            return
        if len(vis) != 1:
            erros.append(f'{nome}: precisa de exatamente 1 objeto visível com esse prop (há {len(vis)})')


def validar_texto(R, ctx, en, pt, ptF, erros, maxp=None):
    e = (en or '').strip()
    if not e:
        erros.append(f'{ctx}: en vazio')
    else:
        if not re.search(r'[.!?…]$', e):
            erros.append(f"{ctx}: en tem de terminar com . ! ? ou … ('{e}')")
        if '...' in e or '—' in e or '–' in e or '"' in e:
            erros.append(f"{ctx}: pontuação proibida no en (... — – ou aspas duplas) ('{e}')")
        if any(ord(ch) > 127 and ch != '…' for ch in e):
            erros.append(f"{ctx}: en só em ASCII, sem acento nem emoji ('{e}')")
        if re.search(r'\b(gonna|wanna|kinda)\b', e, re.I):
            erros.append(f"{ctx}: gonna/wanna/kinda são proibidos ('{e}')")
        if maxp is not None:
            n = len(e.split())
            if n > maxp:
                erros.append(f"{ctx}: {n} palavras no en (máx. {maxp}) ('{e}')")
    if not (pt or '').strip():
        erros.append(f'{ctx}: pt vazio')
    if ptF is not None and not ptF.strip():
        erros.append(f'{ctx}: pt_f vazio')
    for termo, rx in R.re_termos:
        for s in (en, pt, ptF):
            if s is not None and rx.search(s):
                erros.append(f"{ctx}: termo proibido '{termo}' ('{s}')")
                break


def validar_cena(R, ctx, cena, cap, nivel, erros, relatorio, avisos, vozes):
    D = R.D
    if cena['hora'] not in R.horas(cena['cenario']):
        erros.append(f"{ctx}: hora '{cena['hora']}' não combina com '{cena['cenario']}'")
    if len(set(cena['clima'])) != len(cena['clima']):
        erros.append(f'{ctx}: clima repetido')
    for cl in cena['clima']:
        if not R.clima_ok(cl, cena['cenario'], cena['hora']):
            erros.append(f"{ctx}: clima '{cl}' não combina com '{cena['cenario']}'/'{cena['hora']}'")
    ids = set()
    presentes = remotos = 0
    posicoes = set()
    for a in cena['elenco']:
        if a['quem'] == D['narrador']:
            erros.append(f'{ctx}: o narrador não entra no elenco')
        elif a['quem'] not in D['personagens']:
            erros.append(f"{ctx}: personagem '{a['quem']}' desconhecido")
        if a['quem'] in ids:
            erros.append(f"{ctx}: '{a['quem']}' repetido no elenco")
        ids.add(a['quem'])
        if a['segura'] == 'nada':
            erros.append(f"{ctx}: '{a['quem']}' com segura 'nada' no elenco")
        if a['remoto']:
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
    po = set()
    for o in cena['objetos']:
        if o['prop'] == 'nada':
            erros.append(f"{ctx}: objeto 'nada'")
        if o['pos'] in po:
            erros.append(f"{ctx}: dois objetos em '{o['pos']}'")
        po.add(o['pos'])
    if not cena['falas']:
        erros.append(f'{ctx}: cena sem falas')
        return [estado_inicial(cena)]
    mudas = seguidas = 0
    linha = [estado_inicial(cena)]
    maxp = D['nivel'][nivel][0]
    for i, f in enumerate(cena['falas']):
        fc = f'{ctx} fala {i + 1}'
        if f['mudo']:
            mudas += 1
            seguidas += 1
            if seguidas == 3:
                erros.append(f'{fc}: mais de 2 passos mudos seguidos')
            relatorio.append(f'  {fc} [{f["quem"]}] (mudo: {f["acao"]})')
        else:
            seguidas = 0
            if f['en'] is not None or f['pt'] is not None:
                validar_texto(R, fc, f['en'], f['pt'], f['ptF'], erros, maxp)
            if f['quem'] in ('lucas', 'julia') and cap['pista'] < 15:
                erros.append(f"{fc}: '{f['quem']}' só fala a partir do capítulo 15")
            n = len((f['en'] or '').split())
            relatorio.append(f'  {fc} [{f["quem"]}] {n}/{maxp}: {f["en"]}')
            # avisos
            if f['en'] in vozes:
                avisos.append(f'{fc}: fala idêntica a uma chave de vozes.json (vai soar com o mp3 do curso se tocar sem perfil): {f["en"]}')
            if f['quem'] == 'voce' and f['ptF'] is None and f['pt'] and RE_GENERO.search(f['pt']):
                avisos.append(f"{fc}: pt do 'voce' com forma que muda no feminino e sem pt_f: {f['pt']}")
        if f['quem'] == D['narrador'] and f['camera'] == 'close':
            avisos.append(f'{fc}: câmera close no narrador')
        depois, errs = aplicar(R, linha[-1], f)
        erros.extend(f'{fc}: {x}' for x in errs)
        linha.append(depois)
    if mudas > 3:
        erros.append(f'{ctx}: {mudas} passos mudos (máx. 3)')
    return linha


RE_GENERO = re.compile(r'\b(obrigado|cansado|pronto|nervoso|animado|preocupado|sozinho|perdido|assustado|orgulhoso|'
                       r'ocupado|atrasado|confuso|curioso|sentado|acordado|molhado|piloto|brasileiro|novato|'
                       r'apaixonado|feliz demais|tímido|ansioso|empolgado|calmo|pronto)\b', re.I)


def validar_capitulo(R, cap, erros, relatorio, avisos, vozes):
    D = R.D
    c = f"cap {cap['pista']}"
    mundo = D['mundo'].get(cap['pista'])
    if mundo is None:
        erros.append(f'{c}: pista fora de 1..30')
        return
    nivel = R.nivel_da_pista(cap['pista'])
    if cap['nivel'] != nivel:
        erros.append(f"{c}: nivel {cap['nivel']} (esperava {nivel})")
    t = D['titulos'][cap['pista'] - 1]
    if cap['titulo']['en'] != t:
        erros.append(f"{c}: titulo '{cap['titulo']['en']}' (esperava '{t}')")
    if not cap['titulo']['pt'].strip():
        erros.append(f'{c}: titulo sem pt')
    r = len(cap['resumo'].strip())
    if r < 20 or r > 200:
        erros.append(f'{c}: resumo com {r} caracteres (20–200)')
    if not 3 <= len(cap['palavras']) <= 6:
        erros.append(f"{c}: {len(cap['palavras'])} palavras (3–6)")
    ens = set()
    for p in cap['palavras']:
        if not p['en'].strip() or not p['pt'].strip():
            erros.append(f'{c}: palavra sem en/pt')
        for w in p['en'].split():
            if w != w.lower() and w not in D['nomesProprios']:
                erros.append(f"{c}: palavra '{p['en']}' fora de minúsculas")
        ens.add(p['en'].strip().lower())
    for a, b in D['pares']:
        if a in ens and b in ens:
            erros.append(f'{c}: par de interferência {a}/{b} nas palavras')
    if not 1 <= len(cap['intro']) <= 3:
        erros.append(f"{c}: intro com {len(cap['intro'])} cenas (1–3)")
    max_fim = 4 if cap['pista'] == 30 else 2
    if not 1 <= len(cap['fim']) <= max_fim:
        erros.append(f"{c}: fim com {len(cap['fim'])} cenas (1–{max_fim})")
    if cap['pista'] < 30 and cap['gancho'] is None:
        erros.append(f'{c}: gancho obrigatório')
    if cap['pista'] == 30 and cap['gancho'] is not None:
        erros.append(f'{c}: o capítulo 30 não tem gancho')
    if cap['gancho'] is not None:
        validar_texto(R, f'{c} gancho', cap['gancho']['en'], cap['gancho']['pt'], None, erros)

    mundo_ok = False
    contagem = {}
    for parte in ('intro', 'fim'):
        cenas = cap[parte]
        com_texto = 0
        for i, cena in enumerate(cenas):
            linha = validar_cena(R, f'{c} {parte}[{i}]', cena, cap, nivel, erros, relatorio, avisos, vozes)
            com_texto += sum(1 for f in cena['falas'] if not f['mudo'])
            if parte == 'intro' and len(linha) > 1:
                if i == 0 and linha[1]['cenario'] == mundo:
                    mundo_ok = True
                if i == len(cenas) - 1 and linha[-1]['cenario'] == mundo:
                    mundo_ok = True
        if parte == 'intro':
            lo, hi = D['nivel'][nivel][1]
        elif cap['pista'] == 30:
            lo, hi = D['faixaFimFinal']
        else:
            lo, hi = D['nivel'][nivel][2]
        contagem[parte] = (com_texto, lo, hi)
        if not lo <= com_texto <= hi:
            erros.append(f'{c}: {parte} com {com_texto} falas com texto ({lo}–{hi})')
        if cenas and cenas[-1]['falas'] and cenas[-1]['falas'][-1]['mudo']:
            erros.append(f'{c}: a {parte} termina num passo mudo (feche com uma fala)')
    if not mundo_ok:
        erros.append(f"{c}: V-mundo: nem a 1ª nem a última fala da intro acontecem em '{mundo}'")
    return contagem


# ───────────────────────────── main ─────────────────────────────

def main(argv):
    global POS_IDX
    dart = DART_PADRAO
    resumo = False
    arquivos = []
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == '--dart':
            dart = argv[i + 1]
            i += 2
            continue
        if a == '--resumo':
            resumo = True
        else:
            arquivos.append(a)
        i += 1
    if not arquivos:
        print(__doc__)
        return 2
    D = ler_dart(dart)
    POS_IDX = {p: k for k, p in enumerate(D['PosicaoPalco'])}
    R = Regras(D)
    try:
        vozes = set(json.load(open(VOZES_PADRAO, encoding='utf-8')).keys())
    except OSError:
        vozes = set()

    erros, avisos = [], []
    L = Leitor(D, erros)
    faixas = {'a': (1, 10), 'b': (11, 20), 'c': (21, 30)}
    titulo = None
    partes = set()
    caps = {}
    for arq in arquivos:
        try:
            j = json.load(open(arq, encoding='utf-8'))
        except (OSError, ValueError) as e:
            print(f'{arq}: não deu para ler ({e})')
            return 2
        ctx = f"parte {j.get('parte', os.path.basename(arq))}"
        try:
            L.chaves(j, {'versao', 'parte', 'titulo', 'capitulos'}, ctx)
            if j.get('versao') != 2:
                L.falha(ctx, f"versao '{j.get('versao')}' (esperava 2)")
            faixa = faixas.get(j.get('parte'))
            if faixa is None:
                L.falha(ctx, f"parte '{j.get('parte')}' inválida (a, b ou c)")
            else:
                partes.add(j['parte'])
            t = L.bilingue(j.get('titulo') or {}, f'{ctx} titulo')
            if titulo is None:
                titulo = t
            elif t != titulo:
                L.falha(ctx, 'titulo diferente das outras partes')
            lista = L.lista(j, 'capitulos', ctx, True)
        except Pular:
            continue
        for k, bruto in enumerate(lista):
            pista = bruto.get('pista') if isinstance(bruto, dict) else None
            cctx = f'cap {pista}' if isinstance(pista, int) else f'{ctx} capitulos[{k}]'
            try:
                cap = L.capitulo(bruto, cctx)
            except Pular:
                erros.append(f'{cctx}: capítulo não pôde ser lido (erro estrutural acima)')
                continue
            if faixa is not None and not faixa[0] <= cap['pista'] <= faixa[1]:
                erros.append(f'{cctx}: fora da faixa da {ctx} ({faixa[0]}–{faixa[1]})')
            if cap['pista'] in caps:
                erros.append(f'{cctx}: capítulo repetido')
                continue
            caps[cap['pista']] = cap

    # V-arquivo: cobertura (só quando as 3 partes vieram juntas)
    if partes == {'a', 'b', 'c'}:
        for n in range(1, 31):
            if n not in caps:
                erros.append(f'cap {n}: ausente')
    for n in caps:
        if not 1 <= n <= 30:
            erros.append(f'cap {n}: fora de 1..30')

    relatorio = []
    linhas_resumo = []
    for n in sorted(caps):
        cap = caps[n]
        rel = []
        cont = validar_capitulo(R, cap, erros, rel, avisos, vozes)
        maior = max((len((f['en'] or '').split()) for c in cap['intro'] + cap['fim'] for f in c['falas'] if not f['mudo']),
                    default=0)
        lim = D['nivel'].get(R.nivel_da_pista(n), (0,))[0]
        if cont:
            ci, cf = cont['intro'], cont['fim']
            linhas_resumo.append(f"cap {n} ({cap['nivel']}): intro {ci[0]} ({ci[1]}–{ci[2]}) · fim {cf[0]} "
                                 f"({cf[1]}–{cf[2]}) falas com texto · maior en {maior}/{lim} palavras")
        relatorio.append(f"cap {n} · {cap['titulo']['en']}")
        relatorio.extend(rel)

    if not resumo:
        print('── palavras por fala ──')
        print('\n'.join(relatorio))
        print()
    print('── resumo por capítulo ──')
    print('\n'.join(linhas_resumo))
    if partes != {'a', 'b', 'c'}:
        print(f"(cobertura 1..30 não conferida: partes lidas = {sorted(partes) or '-'})")
    print()
    if avisos:
        print(f'AVISOS ({len(avisos)}):')
        for a in avisos:
            print(' ~', a)
        print()
    if erros:
        print(f'ERROS ({len(erros)}):')
        for e in erros:
            print(' -', e)
        return 1
    print(f'SEM ERROS ({len(caps)} capítulos)')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
