"""Valida as AULAS DO PROFESSOR do PAC·ENGLISH (🎓 a aula falada, em português, de cada lição — 6 a 10 minutos, de qualquer nível).

Um arquivo por trilha, `assets/ingles/aulas/<slug>.json`:
  {"versao": 2, "trilha": "<slug>", "licoes": {"<Licao.id>": {"titulo": "...", "falas": [FALA, ...]}}}
FALA (exatamente um destes):
  {"pt": "o professor falando em português"}             (+ opcionais, abaixo)
  {"en": "o exemplo em inglês, dito pelo professor", "tr": "a tradução mostrada embaixo"}   (+ "img")
Opcionais:
  "quadro": o que ele escreve na lousa (só na fala "pt")
  "img":    a figura da lousa enquanto ele fala disso: "foto" (a foto da cena da lição, se ela tem) ou 1 a 4
            emojis (sem texto)
  "secao":  o nome da parte da aula que COMEÇA nesta fala (a 1ª fala abre a 1ª parte)
  "pausa":  segundos (2 a 8) de silêncio DEPOIS da fala "pt" — o desafio "como você diria…?" (o aluno pensa)

Uso:
  python3 -I tools/ingles/aulas/validar_aulas.py ARQUIVO.json [...] [--curriculo assets/ingles/curriculo.json]
Sai com 1 se algum arquivo tiver problema (lista todos). Nunca escreve nada.
"""
import argparse
import json
import os
import re
import sys

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
CURRICULO = os.path.join(RAIZ, 'assets', 'ingles', 'curriculo.json')
DICIONARIO = os.path.join(RAIZ, 'assets', 'ingles', 'dicionario.json')

FALAS_MIN, FALAS_MAX = 35, 130
PT_MIN, PT_MAX = 12, 320           # por fala
PT_TOTAL_MIN, PT_TOTAL_MAX = 3500, 8200   # ≈ 14 letras/s: o grosso da aula é o professor em português
MIN_MIN, MIN_MAX = 6.0, 10.5               # duração estimada (a mesma conta do app: AulaLicao.segundos)
EN_MAX, QUADRO_MAX, TITULO_MAX, SECAO_MAX = 140, 90, 60, 40
SECOES_MIN, SECOES_MAX = 5, 10
IMGS_MIN, PAUSAS_MIN, PAUSAS_MAX = 4, 1, 6
FOTOS = os.path.join(RAIZ, 'assets', 'ingles', 'fotos')

# nomes próprios que o professor pode dizer em português
NOMES = {'mike', 'sarah', 'ana', 'ben', 'emma', 'lucas', 'julia', 'lee', 'carlos', 'beto', 'chicago',
         'londres', 'nova', 'york', 'brasil', 'paclingo', 'dash', 'jack', 'hannaford', 'texas', 'ohio', 'austin',
         'michigan', 'califórnia', 'flórida', 'recife', 'boston', 'curitiba', 'toronto', 'seattle', 'denver',
         'miami', 'orlando', 'manchester', 'sydney', 'dublin', 'salvador', 'méxico', 'japão', 'europa',
         'flutter', 'dra', 'portugal', 'canadá', 'austrália', 'irlanda', 'escócia', 'inglaterra', 'shakespeare',
         'google', 'github', 'slack', 'jira', 'zoom', 'linkedin', 'python', 'java', 'javascript', 'dart',
         'android', 'iphone', 'windows', 'linux', 'netflix', 'uber', 'amazon', 'microsoft', 'apple'}
# palavras de inglês que todo brasileiro fala em português e a voz pt-BR diz bem
EMPRESTADAS = {'ok', 'e-mail', 'email', 'online', 'site', 'app', 'apps', 'show', 'shopping', 'hotel', 'internet',
               'chat', 'game', 'games', 'link', 'login', 'web', 'wifi', 'wi-fi', 'pizza', 'sanduíche', 'dev',
               'software', 'bug', 'bugs', 'deploy', 'feedback', 'home', 'office', 'delivery', 'fast', 'food',
               'hamburguer', 'hambúrguer', 'jeans', 'designer', 'tablet', 'laptop', 'notebook', 'mouse', 'café',
               'api', 'apis', 'backend', 'frontend', 'startup', 'marketing', 'podcast', 'streaming', 'commit',
               'commits', 'sprint', 'sprints', 'backlog', 'daily', 'stand-up', 'kanban', 'scrum', 'post',
               'blog', 'youtube', 'ia', 'pix', 'freelancer', 'freela', 'design', 'layout', 'emoji', 'emojis'}

# palavras que existem nos dois idiomas e, numa fala em português, são português (a voz pt-BR lê certo)
PORTUGUES_TAMBEM = {'use', 'uses', 'tire', 'some', 'for', 'compare', 'resume', 'rio', 'costume', 'pare', 'come',
                    'time', 'assume', 'rode', 'mora', 'ate', 'a', 'do', 'no', 'me', 'se', 'nos', 'as', 'pois',
                    'prepare', 'piano', 'popular', 'hospital', 'times', 'normal', 'total', 'final', 'animal'}

_EMOJI = re.compile('[\U0001F000-\U0001FAFF☀-➿⬀-⯿]')
# o que pode haver numa figura de emojis: os emojis, seletor de variação, juntador, tons de pele, bandeiras
_SO_EMOJI = re.compile('^(?:[\U0001F000-\U0001FAFF☀-➿⬀-⯿\u2190-\u21FF\u2300-\u23FF\u2B00-\u2BFF\u3030\u303D\u3297\u3299\u00A9\u00AE\u2122\uFE0F\u200D\U0001F1E6-\U0001F1FF\U0001F3FB-\U0001F3FF\u20E3#*0-9])+$')
_PALAVRA = re.compile(r"[A-Za-zÀ-ÿ][A-Za-zÀ-ÿ'’-]*")


def _palavras(s):
    return [m.group(0) for m in _PALAVRA.finditer(s)]


def carregar_curriculo(caminho):
    with open(caminho, encoding='utf-8') as f:
        trilhas = json.load(f)
    licoes = {}
    for t in trilhas:
        for l in t['licoes']:
            licoes[l['id']] = l
    return trilhas, licoes


def vocabularios(trilhas):
    """(inglês, português): o inglês = dicionário do app + as palavras das frases; o português = as palavras das
    traduções, cenas, resumos e notas (o que aparece nos dois só é inglês se não for português também)."""
    en, pt = set(), set()
    try:
        with open(DICIONARIO, encoding='utf-8') as f:
            en.update(k.lower() for k in json.load(f))
    except OSError:
        pass
    for t in trilhas:
        for l in t['licoes']:
            da_licao = set()
            for tr in l['trechos']:
                ws = {w.lower() for w in _palavras(tr['cod'])}
                en.update(ws)
                da_licao |= ws
                # a tradução às vezes repete um pedaço do inglês (nome, termo): o que está na frase não conta
                pt.update(w.lower() for w in _palavras(tr.get('dica', '')) if w.lower() not in ws)
            # cena e nome da lição citam o inglês dela ("o How's it going"): as palavras da lição não contam
            for txt in (l.get('nome', ''), l.get('cena', '')):
                pt.update(w.lower() for w in _palavras(txt) if w.lower() not in da_licao)
    # o que está no português só por citar o inglês ("o I'm") sai do português, e as palavras que só existem em
    # inglês (sobraram em traduções de jargão dev) também
    pt -= {w for w in en if "'" in w}
    pt -= {'be', 'it', 'for', 'had', 'will', 'us', 'some', 'small', 'happy', 'late', 'may', 'go', 'talk', 'live',
           'miss', 'call', 'add', 'play', 'pull', 'push', 'review', 'request', 'report', 'hour', 'times'}
    return en, pt


def ingles_no_pt(texto, en, pt):
    """Palavras inglesas dentro de uma fala em português (a voz pt-BR as pronunciaria errado)."""
    achadas = []
    for w in _palavras(texto):
        b = w.lower().strip("'’-")
        if not b or b in NOMES or b in EMPRESTADAS or b in PORTUGUES_TAMBEM:
            continue
        if "'" in w or '’' in w:
            achadas.append(w)
        elif b in en and b not in pt and len(b) > 1:
            achadas.append(w)
    return achadas


def validar_arquivo(caminho, trilhas, licoes, en, pt):
    erros = []
    try:
        with open(caminho, encoding='utf-8') as f:
            dados = json.load(f)
    except (OSError, ValueError) as e:
        return [f'não abriu como JSON: {e}']
    if not isinstance(dados, dict):
        return ['a raiz tem de ser um objeto']
    slug = dados.get('trilha')
    if dados.get('versao') != 2:
        erros.append('"versao" tem de ser 2')
    da_trilha = [l['id'] for t in trilhas for l in t['licoes'] if l['id'].split('.')[0] == slug]
    if not da_trilha:
        return erros + [f'trilha "{slug}" não existe no currículo']
    aulas = dados.get('licoes')
    if not isinstance(aulas, dict):
        return erros + ['"licoes" tem de ser um objeto {Licao.id: aula}']
    for falta in [i for i in da_trilha if i not in aulas]:
        erros.append(f'{falta}: falta a aula')
    for sobra in [i for i in aulas if i not in da_trilha]:
        erros.append(f'{sobra}: não é lição desta trilha')
    for lid, aula in aulas.items():
        if lid not in licoes:
            continue
        erros += [f'{lid}: {e}' for e in validar_aula(aula, licoes[lid], en, pt)]
    return erros


def _figura(img, tem_foto):
    """Erro da "img" (None = ok)."""
    if not isinstance(img, str) or not img.strip():
        return '"img" vazia'
    if img == 'foto':
        return None if tem_foto else '"img": "foto" numa lição sem foto (use emojis)'
    if not _SO_EMOJI.match(img.replace(' ', '')):
        return '"img" é "foto" ou só emojis (sem texto)'
    if len(_EMOJI.findall(img)) > 4 + img.count('\u200d') + len(re.findall('[\U0001F1E6-\U0001F1FF]', img)):
        return '"img" com no máximo 4 emojis'
    return None


def minutos(falas):
    """A duração a 1×, igual ao app: 14 letras/s no português, 12 no inglês, meio segundo de respiro e as pausas."""
    t = 0.0
    for f in falas:
        if isinstance(f, dict):
            ingles = 'en' in f
            texto = f.get('en' if ingles else 'pt')
            if isinstance(texto, str):
                t += len(texto.strip()) / (12 if ingles else 14) + .5
            if not ingles and isinstance(f.get('pausa'), int):
                t += min(max(f['pausa'], 0), 10)
    return t / 60


def validar_aula(aula, licao, en, pt):
    erros = []
    if not isinstance(aula, dict) or set(aula) - {'titulo', 'falas'}:
        return ['a aula tem só "titulo" e "falas"']
    titulo = aula.get('titulo')
    if not isinstance(titulo, str) or not titulo.strip() or len(titulo) > TITULO_MAX:
        erros.append(f'"titulo" de 1 a {TITULO_MAX} caracteres')
    falas = aula.get('falas')
    if not isinstance(falas, list) or not (FALAS_MIN <= len(falas) <= FALAS_MAX):
        return erros + [f'"falas": de {FALAS_MIN} a {FALAS_MAX} (veio {len(falas) if isinstance(falas, list) else "?"})']
    tem_foto = os.path.exists(os.path.join(FOTOS, f'{licao["id"]}.jpg'))
    cods = {t['cod'].strip() for t in licao['trechos']}
    ditas = set()
    total_pt, n_en, vistos = 0, 0, set()
    n_secoes, n_imgs, n_pausas, usou_foto = 0, 0, 0, False
    for i, f in enumerate(falas, 1):
        p = f'fala {i}'
        if not isinstance(f, dict):
            erros.append(f'{p}: tem de ser um objeto')
            continue
        chaves = set(f)
        if 'secao' in f:
            n_secoes += 1
            sec = f['secao']
            if not isinstance(sec, str) or not sec.strip() or len(sec) > SECAO_MAX or _EMOJI.search(sec):
                erros.append(f'{p}: "secao" de 1 a {SECAO_MAX} caracteres, sem emoji')
        if 'img' in f:
            n_imgs += 1
            e = _figura(f['img'], tem_foto)
            if e:
                erros.append(f'{p}: {e}')
            usou_foto |= f['img'] == 'foto'
        if 'pt' in f:
            if chaves - {'pt', 'quadro', 'img', 'secao', 'pausa'}:
                erros.append(f'{p}: fala em português aceita "pt", "quadro", "img", "secao" e "pausa" (veio {sorted(chaves)})')
            s = f['pt']
            if not isinstance(s, str) or not (PT_MIN <= len(s.strip()) <= PT_MAX):
                erros.append(f'{p}: "pt" de {PT_MIN} a {PT_MAX} caracteres')
                continue
            total_pt += len(s)
            if _EMOJI.search(s):
                erros.append(f'{p}: sem emoji na fala (a voz lê; a figura vai em "img")')
            if re.search(r'[*_#<>\[\]{}|`]', s):
                erros.append(f'{p}: sem marcação (*, _, #, <>, colchetes) na fala')
            if '"' in s or '“' in s or '”' in s:
                erros.append(f'{p}: sem aspas na fala (o que ficaria entre aspas vai para o "quadro" ou um "en")')
            ing = ingles_no_pt(s, en, pt)
            if ing:
                erros.append(f'{p}: inglês dentro do português ({", ".join(ing)}) — a voz pt-BR fala errado; '
                             'ponha o inglês numa fala "en" ou no "quadro"')
            q = f.get('quadro')
            if q is not None and (not isinstance(q, str) or not q.strip() or len(q) > QUADRO_MAX or _EMOJI.search(q)):
                erros.append(f'{p}: "quadro" de 1 a {QUADRO_MAX} caracteres, sem emoji (a figura vai em "img")')
            if 'pausa' in f:
                n_pausas += 1
                if not isinstance(f['pausa'], int) or isinstance(f['pausa'], bool) or not 2 <= f['pausa'] <= 8:
                    erros.append(f'{p}: "pausa" é um número inteiro de 2 a 8 (segundos)')
            chave = ('pt', s.strip())
        elif 'en' in f:
            if chaves - {'img'} != {'en', 'tr'}:
                erros.append(f'{p}: fala em inglês tem "en" e "tr" (e "img" opcional) (veio {sorted(chaves)})')
            s = f.get('en')
            if not isinstance(s, str) or not s.strip() or len(s) > EN_MAX:
                erros.append(f'{p}: "en" de 1 a {EN_MAX} caracteres')
                continue
            if not all(32 <= ord(c) < 127 for c in s):
                erros.append(f'{p}: "en" só com ASCII digitável (sem ’ “ ” …)')
            tr = f.get('tr')
            if not isinstance(tr, str) or not tr.strip() or len(tr) > EN_MAX:
                erros.append(f'{p}: "tr" (tradução) de 1 a {EN_MAX} caracteres')
            n_en += 1
            if s.strip() in cods:
                ditas.add(s.strip())
            chave = ('en', s.strip())
        else:
            erros.append(f'{p}: precisa de "pt" ou "en"')
            continue
        if chave in vistos and chave[0] == 'pt':
            erros.append(f'{p}: fala repetida')
        vistos.add(chave)
    if falas and isinstance(falas[0], dict):
        if 'pt' not in falas[0]:
            erros.append('a 1ª fala é em português (o professor abre a aula)')
        if 'secao' not in falas[0]:
            erros.append('a 1ª fala abre a 1ª parte ("secao")')
    if falas and isinstance(falas[-1], dict) and 'pt' not in falas[-1]:
        erros.append('a última fala é em português (o professor fecha a aula)')
    if not (PT_TOTAL_MIN <= total_pt <= PT_TOTAL_MAX):
        erros.append(f'português somado {total_pt} caracteres (de {PT_TOTAL_MIN} a {PT_TOTAL_MAX}: ~5 a 10 minutos)')
    m = minutos(falas)
    if not (MIN_MIN <= m <= MIN_MAX):
        erros.append(f'a aula dura ≈ {m:.1f} min (de {MIN_MIN:g} a {MIN_MAX:g}): '
                     + ('aprofunde — mais exemplos, curiosidades, desafios' if m < MIN_MIN else 'enxugue'))
    faltam = sorted(cods - ditas)
    if faltam:
        erros.append(f'frases da lição que a aula não diz (cada uma vira uma fala "en" EXATA): {faltam}')
    if not (SECOES_MIN <= n_secoes <= SECOES_MAX):
        erros.append(f'{n_secoes} partes ("secao"): de {SECOES_MIN} a {SECOES_MAX}')
    if n_imgs < IMGS_MIN:
        erros.append(f'{n_imgs} figuras ("img"): pelo menos {IMGS_MIN}')
    if tem_foto and not usou_foto:
        erros.append('a lição tem foto: mostre-a ("img": "foto") quando contar a cena')
    if not (PAUSAS_MIN <= n_pausas <= PAUSAS_MAX):
        erros.append(f'{n_pausas} desafios ("pausa"): de {PAUSAS_MIN} a {PAUSAS_MAX}')
    return erros


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('arquivos', nargs='+')
    ap.add_argument('--curriculo', default=CURRICULO)
    a = ap.parse_args()
    trilhas, licoes = carregar_curriculo(a.curriculo)
    en, pt = vocabularios(trilhas)
    ruim = False
    for arq in a.arquivos:
        erros = validar_arquivo(arq, trilhas, licoes, en, pt)
        if erros:
            ruim = True
            print(f'✗ {arq}')
            for e in erros:
                print(f'   - {e}')
        else:
            print(f'✓ {arq}')
    sys.exit(1 if ruim else 0)


if __name__ == '__main__':
    main()
