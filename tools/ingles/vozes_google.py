#!/usr/bin/env python3
"""Gera a voz de cada frase do PAC·ENGLISH com o Google Cloud Text-to-Speech (vozes Chirp 3 HD, inglês americano).

Cada personagem tem SEMPRE a mesma voz (o aluno, Mike, Ana, Sarah…), e os exemplos da teoria têm a voz do narrador.
Toda frase do curso tem a voz do personagem, inclusive as que têm gravação de nativo do Tatoeba (campo "au"): no app
a voz do personagem vence e o Tatoeba fica só de reserva. As falas da história do Turismo ("The Golden Wheel") também
ganham a voz de quem fala (Max, Kim e o narrador da história com vozes próprias).

Saída:
  assets/ingles/voz/<hash>.mp3     um arquivo por (voz, texto); rodar de novo só gera o que falta e apaga os órfãos
  assets/ingles/vozes.json         {texto em inglês: asset} — o app toca isto (o Tatoeba só se faltar)
  assets/ingles/voz_historia/<hash>.mp3   as falas da história (pasta própria: os órfãos de uma pasta não tocam a outra)
  assets/ingles/vozes_historia.json       {"quem|texto": asset}
  tools/ingles/dados/vozes_google.json   quem fala com qual voz (para conferir/regerar)

ATENÇÃO: cada execução apaga os mp3 que não estão no universo dela (curso inteiro + história inteira). Conferir antes:
  python3 tools/ingles/vozes_google.py --gcp music-system-421ee --seco     (só conta; órfãos têm de ser 0)

Uso (rodar DEPOIS do integrar.py, na raiz do projeto; precisa do gcloud logado):
  python3 tools/ingles/vozes_google.py --gcp music-system-421ee
O projeto do Google Cloud só precisa ter a API Text-to-Speech ativa e faturamento (cabe na cota gratuita mensal).
"""
import argparse
import base64
import concurrent.futures as cf
import hashlib
import json
import os
import subprocess
import threading
import time
import urllib.error
import urllib.request

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CURRICULO = os.path.join(RAIZ, 'assets/ingles/curriculo.json')
PASTA = os.path.join(RAIZ, 'assets/ingles/voz')
INDICE = os.path.join(RAIZ, 'assets/ingles/vozes.json')
PASTA_HISTORIA = os.path.join(RAIZ, 'assets/ingles/voz_historia')
INDICE_HISTORIA = os.path.join(RAIZ, 'assets/ingles/vozes_historia.json')
HISTORIA = [os.path.join(RAIZ, f'assets/ingles/turismo_historia_{p}.json') for p in 'abc']
ELENCO_JSON = os.path.join(RAIZ, 'tools/ingles/dados/vozes_google.json')
API = 'https://texttospeech.googleapis.com/v1/text:synthesize'
PREFIXO = 'en-US-Chirp3-HD-'

# o elenco fixo (dono: "pode escolher sortido") — vozes diferentes para quem conversa muito entre si
ELENCO = {
    'voce': 'Orus',      # o aluno (Carlos, dev brasileiro)
    'mike': 'Puck',
    'ben': 'Fenrir',
    'lucas': 'Iapetus',
    'ana': 'Kore',
    'sarah': 'Aoede',
    'emma': 'Leda',
    'julia': 'Zephyr',
    'dra-lee': 'Sulafat',
    'narrador': 'Charon',  # exemplos da teoria e placas
    'narradora': 'Vindemiatrix',  # quem conta os contos (Jack Hannaford): voz feminina calma
    'placa': 'Charon',
}
# a história do Turismo ("The Golden Wheel"): os do curso com a MESMA voz; Max, Kim e o narrador da história com as
# três vozes Chirp 3 HD que ninguém usa (o narrador da história é outro, não o dos exemplos da teoria)
ELENCO_HISTORIA = {**{p: v for p, v in ELENCO.items() if p not in ('narrador', 'placa')},
                   'max': 'Achird', 'kim': 'Gacrux', 'narrador': 'Zubenelgenubi'}
MASCULINAS = ['Achird', 'Algenib', 'Algieba', 'Alnilam', 'Enceladus', 'Rasalgethi', 'Sadachbia', 'Sadaltager',
              'Schedar', 'Umbriel', 'Zubenelgenubi']
FEMININAS = ['Achernar', 'Autonoe', 'Callirrhoe', 'Despina', 'Erinome', 'Gacrux', 'Laomedeia', 'Pulcherrima',
             'Vindemiatrix']
# papéis menores: o gênero vem da palavra em português (recrutadora, diretor…); neutro sorteia pelo hash do papel
FEMININOS = {'recrutadora', 'diretora', 'moradora', 'engenheira', 'corretora', 'passageira', 'estagiaria', 'gestora',
             'farmaceutica', 'desenvolvedora', 'vizinha', 'esposa', 'mae', 'namorada', 'professora', 'medica',
             'enfermeira', 'chefe-dela', 'convidada', 'dev-nova', 'supervisora', 'prima', 'tia', 'presidente',
             'economista', 'advogada', 'pesquisadora', 'consultora'}
MASCULINOS = {'jack', 'entrevistador', 'proprietario', 'passageiro', 'vendedor', 'amigo-do-ben', 'convidado', 'marido',
              'engenheiro', 'dev-novo', 'dev-junior', 'pai', 'irmao', 'professor', 'medico', 'sobrinho', 'socio', 'vizinho'}


def _h(s):
    return int(hashlib.sha1(s.encode()).hexdigest(), 16)


def voz_do_papel(papel):
    if papel in ELENCO:
        return ELENCO[papel]
    if papel in FEMININOS or papel.endswith(('ora', 'eira', 'ada', '-nova')):
        pool = FEMININAS
    elif papel in MASCULINOS or papel.endswith('or') or papel.endswith('eiro'):
        pool = MASCULINAS
    else:
        pool = MASCULINAS + FEMININAS
    return pool[_h(papel) % len(pool)]


class Token:
    """Token do gcloud, renovado a cada 40 min (vale 1 h)."""

    def __init__(self):
        self._t, self._em, self._lock = None, 0, threading.Lock()

    def __call__(self):
        with self._lock:
            if not self._t or time.time() - self._em > 2400:
                self._t = subprocess.check_output(['gcloud', 'auth', 'print-access-token'], text=True).strip()
                self._em = time.time()
            return self._t


def sintetizar(texto, voz, gcp, token):
    corpo = json.dumps({
        'input': {'text': texto},
        'voice': {'languageCode': 'en-US', 'name': PREFIXO + voz},
        'audioConfig': {'audioEncoding': 'MP3'},
    }).encode()
    for tentativa in range(8):
        req = urllib.request.Request(API, data=corpo, headers={
            'Authorization': 'Bearer ' + token(), 'x-goog-user-project': gcp, 'Content-Type': 'application/json'})
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return base64.b64decode(json.load(r)['audioContent'])
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 503) and tentativa < 7:
                time.sleep(min(60, 2 ** tentativa))
                continue
            raise RuntimeError(f'{e.code} {e.read()[:300]!r} em {texto!r}')
        except (urllib.error.URLError, TimeoutError):
            time.sleep(min(60, 2 ** tentativa))
    raise RuntimeError(f'sem resposta para {texto!r}')


def universo_curso():
    """{texto: papel} do curso: toda frase (inclusive as que têm gravação do Tatoeba em "au", que agora ficam só de
    reserva no app) e todo exemplo da teoria. A 1ª fala vale: o mesmo texto não muda de voz.
    Exceção: o índice é só por texto, então frase com gravação do Tatoeba ("au") dita por personagens de vozes
    DIFERENTES fica de fora — segue tocando o Tatoeba para todos (senão o Ben falaria com a voz da Ana)."""
    trilhas = json.load(open(CURRICULO, encoding='utf-8'))
    pedidos, falantes, com_au = {}, {}, set()
    for t in trilhas:
        for l in t['licoes']:
            for f in l['trechos']:
                cod, quem = f['cod'].strip(), f.get('quem') or 'narrador'
                pedidos.setdefault(cod, quem)
                falantes.setdefault(cod, set()).add(quem)
                if f.get('au'):
                    com_au.add(cod)
    fora = {c for c in com_au if len({voz_do_papel(q) for q in falantes[c]}) > 1}
    for c in fora:
        del pedidos[c]
    for t in trilhas:
        for l in t['licoes']:
            for b in l.get('teoria') or []:
                if isinstance(b, dict) and b.get('t') == 'ex':
                    en = b['c'].split('\n')[0].strip()
                    if en and en not in fora:
                        pedidos.setdefault(en, 'narrador')
    return pedidos


def voz_da_historia(quem):
    return ELENCO_HISTORIA.get(quem) or voz_do_papel(quem)


def universo_historia():
    """{"quem|texto": (quem, texto)} de toda fala com texto em inglês da história do Turismo (as 3 partes).
    A chave tem quem fala: na história o mesmo texto pode sair da boca de personagens diferentes ("Copy that!")."""
    pedidos = {}
    for caminho in HISTORIA:
        d = json.load(open(caminho, encoding='utf-8'))
        for cap in d['capitulos']:
            for parte in ('intro', 'fim'):
                cenas = cap.get(parte) or []
                if isinstance(cenas, dict):
                    cenas = [cenas]
                for cena in cenas:
                    for fala in cena.get('falas') or []:
                        en = (fala.get('en') or '').strip()
                        if not en:
                            continue
                        quem = fala.get('quem') or 'narrador'
                        pedidos.setdefault(f'{quem}|{en}', (quem, en))
    return pedidos


def nome_mp3(voz, texto):
    return hashlib.sha1(f'{voz}|{texto}'.encode()).hexdigest()[:14] + '.mp3'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--gcp', required=True, help='projeto do Google Cloud com a API Text-to-Speech ativa')
    ap.add_argument('--paralelo', type=int, default=6)
    ap.add_argument('--limite', type=int, default=0, help='gera só N arquivos (teste; não apaga órfãos)')
    ap.add_argument('--seco', '--dry-run', dest='seco', action='store_true',
                    help='só conta (textos, o que falta, letras, órfãos); não chama a API nem escreve/apaga nada')
    a = ap.parse_args()

    # (pasta, prefixo do asset, índice, {chave: (texto, voz)}) — cada pasta só apaga os órfãos do SEU universo
    try:
        curso = universo_curso()
    except (OSError, ValueError, KeyError) as e:
        print(f'currículo ilegível ({e}): nada a fazer')
        return 1
    try:
        hist = universo_historia()
    except (OSError, ValueError, KeyError) as e:
        print(f'história ilegível ({e}): nada a fazer')
        return 1
    if not curso or not hist:
        print(f'universo vazio (curso {len(curso)}, história {len(hist)}): nada é gerado nem apagado')
        return 1
    papeis = {p: voz_do_papel(p) for p in set(curso.values())}
    papeis.setdefault('narrador', ELENCO['narrador'])
    lotes = [
        ('curso', PASTA, 'assets/ingles/voz/', INDICE,
         {texto: (texto, voz_do_papel(papel)) for texto, papel in curso.items()}),
        ('história', PASTA_HISTORIA, 'assets/ingles/voz_historia/', INDICE_HISTORIA,
         {chave: (texto, voz_da_historia(quem)) for chave, (quem, texto) in hist.items()}),
    ]

    faltam, indices = [], []
    for rotulo, pasta, prefixo, arq, pedidos in lotes:
        indice, falta_aqui = {}, {}
        for chave, (texto, voz) in sorted(pedidos.items()):
            nome = nome_mp3(voz, texto)
            indice[chave] = prefixo + nome
            if not os.path.exists(os.path.join(pasta, nome)):
                falta_aqui[nome] = (texto, voz, pasta, nome)  # 2 chaves com a mesma voz e texto = 1 arquivo
        falta_aqui = list(falta_aqui.values())
        usados = {os.path.basename(p) for p in indice.values()}
        existentes = [n for n in os.listdir(pasta) if n.endswith('.mp3')] if os.path.isdir(pasta) else []
        orfaos = sorted(n for n in existentes if n not in usados)
        letras = sum(len(t) for t, _, _, _ in falta_aqui)
        print(f'{rotulo}: {len(pedidos)} textos · faltam {len(falta_aqui)} ({letras} letras) · {len(orfaos)} órfão(s)')
        if a.seco:
            for n in orfaos[:50]:
                print(f'  órfão {prefixo}{n}')
        faltam += falta_aqui
        indices.append((rotulo, pasta, arq, indice, orfaos))
    if a.seco:
        print(f'total: {len(faltam)} mp3 para gerar, {sum(len(t) for t, _, _, _ in faltam)} letras (nada foi gerado)')
        return 0

    if a.limite:
        faltam = faltam[:a.limite]
    print(f'gerando {len(faltam)} mp3 ({sum(len(t) for t, _, _, _ in faltam)} letras) · {len(papeis)} papéis no curso')

    token, feitos, erros = Token(), [0], []
    lock = threading.Lock()

    def gera(item):
        texto, voz, pasta, nome = item
        try:
            mp3 = sintetizar(texto, voz, a.gcp, token)
            os.makedirs(pasta, exist_ok=True)
            tmp = os.path.join(pasta, nome + '.tmp')
            open(tmp, 'wb').write(mp3)
            os.replace(tmp, os.path.join(pasta, nome))
        except Exception as e:  # noqa: BLE001 — registra e segue; rodar de novo completa
            with lock:
                erros.append(str(e))
        with lock:
            feitos[0] += 1
            if feitos[0] % 100 == 0:
                print(f'  {feitos[0]}/{len(faltam)}', flush=True)

    with cf.ThreadPoolExecutor(a.paralelo) as ex:
        list(ex.map(gera, faltam))

    total = {}
    for rotulo, pasta, arq, indice, orfaos in indices:
        # só entra no índice o que existe em disco; órfãos (texto que saiu do curso/da história) saem
        indice = {k: p for k, p in indice.items() if os.path.exists(os.path.join(RAIZ, p))}
        if not a.limite:
            for n in orfaos:
                os.remove(os.path.join(pasta, n))
        json.dump(dict(sorted(indice.items())), open(arq, 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
        usados = {os.path.basename(p) for p in indice.values()}
        tam = sum(os.path.getsize(os.path.join(pasta, n)) for n in usados)
        total[rotulo] = len(indice)
        print(f'{rotulo}: índice {len(indice)} · {tam / 1e6:.1f} MB'
              + ('' if a.limite else f' · {len(orfaos)} órfão(s) apagado(s)'))
    historia_vozes = {q: PREFIXO + voz_da_historia(q) for q in sorted({q for q, _ in hist.values()})}
    json.dump({'vozes': {p: PREFIXO + v for p, v in sorted(papeis.items())}, 'historia': historia_vozes,
               'gcp_api': 'texttospeech v1', 'total': total['curso'], 'total_historia': total['história']},
              open(ELENCO_JSON, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(f'{len(erros)} erro(s)')
    for e in erros[:10]:
        print('  ERRO', e)
    return 1 if erros else 0


if __name__ == '__main__':
    raise SystemExit(main())
