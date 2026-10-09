#!/usr/bin/env python3
"""Voz nativa do Tatoeba para as frases do PAC·ENGLISH (no lugar da voz sintética do navegador).

    python3 tools/ingles/audio_nativo.py [--cache DIR] [--sem-baixar]

1. Baixa (uma vez) os exports oficiais do Tatoeba para --cache (padrão: <tmp>/pac_dart_tatoeba — dado bruto
   NUNCA entra no projeto): sentences_with_audio.tar.bz2 (sentence_id, audio_id, username, license,
   attribution_url) e per_language/eng/eng_sentences.tsv.bz2 (id, eng, texto).
2. Para cada frase do curso (todas as trilhas do esboço, não só as que vieram do Tatoeba) procura uma frase
   inglesa do Tatoeba COM áudio e as MESMAS palavras: minúsculas, só letras/dígitos/apóstrofo (’ = '),
   pontuação e maiúsculas podem diferir, mas pergunta casa só com pergunta (a entonação muda); contração ≠
   forma longa. Frases com campo da ficha ({nome}, {cidade}…) ficam de fora — o texto muda por aluno.
3. Só áudio com licença conhecida (CC …); sem licença = fora. Várias gravações: CK (inglês americano, a voz
   principal do Tatoeba) primeiro, depois quem mais gravou em inglês, depois o menor audio_id — determinístico.
4. Baixa o mp3 DAQUELA gravação (https://tatoeba.org/audio/download/<audio_id>, conferindo o nome
   "<sentence_id>-<audio_id>.mp3" que o servidor devolve; frase com uma gravação só vem do URL rápido por
   sentence_id, que não tem outra para trazer) SEM alterar os bytes (há licença ND: nada de obra
   derivada) para assets/ingles/audio/<sentence_id>-<audio_id>.mp3 — no máximo 3 conexões, com pausa. O
   audio_id no nome é a prova de QUAL gravação está no disco: arquivo que já existe não é baixado de novo, e
   gravação nova (outro audio_id) é outro arquivo. mp3 que nenhuma frase usa mais é apagado.
5. Escreve tools/ingles/dados/audio_nativo.json = {cod: {id, audio, autor, licenca, url_atribuicao, texto}} só
   com o que tem o mp3 DAQUELA gravação na pasta (crédito e áudio sempre batem); a escolha mudou e o mp3 novo
   não veio (--sem-baixar, falha de rede)? Fica a gravação anterior, com o crédito dela. O integrar.py lê esse
   arquivo e grava "au"/"au_cred" no trecho.
"""
import bz2, collections, json, os, re, sys, tarfile, tempfile, time, urllib.request
from concurrent.futures import ThreadPoolExecutor

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
TRILHAS = os.path.join(RAIZ, 'tools/ingles/dados/trilhas')
ESBOCO = os.path.join(RAIZ, 'tools/ingles/dados/esboco.json')
SAIDA = os.path.join(RAIZ, 'tools/ingles/dados/audio_nativo.json')
PASTA_AUDIO = os.path.join(RAIZ, 'assets/ingles/audio')

EXPORT_AUDIO = 'https://downloads.tatoeba.org/exports/sentences_with_audio.tar.bz2'
EXPORT_ENG = 'https://downloads.tatoeba.org/exports/per_language/eng/eng_sentences.tsv.bz2'
# por audio_id: sempre AQUELA gravação (o servidor confirma no nome do arquivo), mas leva ~5 s cada;
# por sentence_id: rápido, mas traz a gravação que o servidor quiser — só para frase com UMA gravação
URL_GRAVACAO = 'https://tatoeba.org/en/audio/download/{audio}'
URL_FRASE = 'https://audio.tatoeba.org/sentences/eng/{id}.mp3'
AGENTE = 'PAC-DART (curso de ingles gratuito; tools/ingles/audio_nativo.py)'
# educação com o servidor do Tatoeba (que às vezes leva 5–20 s por arquivo): poucas conexões e uma pausa
CONEXOES = 3
PAUSA = .5

# a voz preferida: CK (Tom), inglês americano, ~835 mil gravações
PREFERIDO = 'CK'


def baixar(url):
    req = urllib.request.Request(url, headers={'User-Agent': AGENTE})
    with urllib.request.urlopen(req, timeout=120) as r:
        dados = r.read()
        return dados, r.headers


def exports(cache):
    """Garante os dois exports no cache e devolve (csv do áudio, tsv do inglês)."""
    os.makedirs(cache, exist_ok=True)
    tar_audio = os.path.join(cache, 'sentences_with_audio.tar.bz2')
    csv_audio = os.path.join(cache, 'sentences_with_audio.csv')
    tsv_eng = os.path.join(cache, 'eng_sentences.tsv')
    if not os.path.exists(csv_audio):
        if not os.path.exists(tar_audio):
            print('baixando', EXPORT_AUDIO)
            dados, _ = baixar(EXPORT_AUDIO)
            open(tar_audio, 'wb').write(dados)
        with tarfile.open(tar_audio, 'r:bz2') as tar:
            membro = next(m for m in tar.getmembers() if m.isfile() and m.name.endswith('sentences_with_audio.csv'))
            open(csv_audio, 'wb').write(tar.extractfile(membro).read())  # só o csv, sem caminhos do tar
    if not os.path.exists(tsv_eng):
        arq_bz = os.path.join(cache, 'eng_sentences.tsv.bz2')
        if not os.path.exists(arq_bz):
            print('baixando', EXPORT_ENG)
            dados, _ = baixar(EXPORT_ENG)
            open(arq_bz, 'wb').write(dados)
        open(tsv_eng, 'wb').write(bz2.decompress(open(arq_bz, 'rb').read()))
    return csv_audio, tsv_eng


def arquivo(v):
    """O mp3 de uma entrada do mapa: sentence_id E audio_id no nome (o arquivo prova qual gravação é)."""
    return f"{v['id']}-{v['audio']}.mp3"


def migrar_nomes_antigos(antes, pasta=PASTA_AUDIO):
    """mp3 do formato antigo (<sentence_id>.mp3, sem o audio_id) → <sentence_id>-<audio_id>.mp3, com o
    audio_id que o JSON da rodada anterior registrou para ele. Idempotente."""
    n = 0
    for v in antes.values():
        velho, novo = os.path.join(pasta, f"{v['id']}.mp3"), os.path.join(pasta, arquivo(v))
        if os.path.exists(velho) and not os.path.exists(novo):
            os.replace(velho, novo)
            n += 1
    return n


def mapa_final(mapa, antes, existe):
    """O que vai para o JSON: cada frase com o mp3 DA gravação creditada. Sem o mp3 da escolha nova, fica a
    gravação anterior da mesma frase (se o mp3 dela ainda está lá); sem nenhum dos dois, a frase sai (voz
    sintética). Nunca grava o crédito de uma gravação cujo arquivo não está na pasta."""
    final = {}
    for cod, v in mapa.items():
        if existe(arquivo(v)):
            final[cod] = v
        elif cod in antes and existe(arquivo(antes[cod])):
            final[cod] = antes[cod]
    return final


def palavras(s):
    """A chave do casamento: as palavras em minúsculas (’ = '), sem pontuação."""
    s = s.replace('’', "'").replace('‘', "'").lower()
    return ' '.join(re.findall(r"[a-z0-9']+", s))


def pergunta(s):
    return s.rstrip().rstrip('"').endswith('?')


def frases_do_curso():
    """Os cods das trilhas do esboço, sem as frases da ficha do aluno ({nome}…)."""
    esboco = json.load(open(ESBOCO, encoding='utf-8'))
    cods, pulas = [], 0
    for t in sorted(esboco['trilhas'], key=lambda x: x['ordem']):
        dir_t = os.path.join(TRILHAS, t['id'])
        if not os.path.isdir(dir_t):
            continue
        for a in sorted(os.listdir(dir_t)):
            if not re.match(r'^\d\d\.json$', a):
                continue
            for f in json.load(open(os.path.join(dir_t, a), encoding='utf-8'))['trechos']:
                if '{' in f['cod']:
                    pulas += 1
                elif f['cod'] not in cods:
                    cods.append(f['cod'])
    return cods, pulas


def main():
    args = sys.argv[1:]
    cache = os.path.join(tempfile.gettempdir(), 'pac_dart_tatoeba')
    if '--cache' in args:
        i = args.index('--cache'); cache = args[i + 1]; del args[i:i + 2]
    sem_baixar = '--sem-baixar' in args

    csv_audio, tsv_eng = exports(cache)
    eng = {}
    for linha in open(tsv_eng, encoding='utf-8'):
        p = linha.rstrip('\n').split('\t', 2)
        if len(p) == 3:
            eng[p[0]] = p[2]
    # gravações em inglês com licença conhecida: sentence_id → [(audio_id, autor, licença, url)]
    gravacoes = collections.defaultdict(list)
    por_autor = collections.Counter()
    n_gravacoes = collections.Counter()  # TODAS as gravações da frase, com ou sem licença
    for linha in open(csv_audio, encoding='utf-8'):
        p = linha.rstrip('\n').split('\t')
        if len(p) < 4 or p[0] not in eng:
            continue
        n_gravacoes[p[0]] += 1
        licenca = p[3].strip()
        if not licenca.startswith('CC'):  # vazio ou \N = sem licença declarada → fora
            continue
        url = p[4].strip() if len(p) > 4 and p[4].strip() not in ('', '\\N') else ''
        gravacoes[p[0]].append((int(p[1]), p[2], licenca, url))
        por_autor[p[2]] += 1
    indice = collections.defaultdict(list)
    for sid in gravacoes:
        indice[palavras(eng[sid])].append(sid)

    def melhor_gravacao(sid):
        return min(gravacoes[sid], key=lambda g: (g[1] != PREFERIDO, -por_autor[g[1]], g[0]))

    cods, pulas = frases_do_curso()
    mapa, unicas = {}, {}
    for cod in cods:
        cand = [s for s in indice.get(palavras(cod), []) if pergunta(eng[s]) == pergunta(cod)]
        if not cand:
            continue
        # o texto idêntico primeiro, depois a voz preferida, depois o menor id
        sid = min(cand, key=lambda s: (eng[s] != cod, melhor_gravacao(s)[1] != PREFERIDO, int(s)))
        audio, autor, licenca, url = melhor_gravacao(sid)
        mapa[cod] = {'id': int(sid), 'audio': audio, 'autor': autor, 'licenca': licenca,
                     'url_atribuicao': url or f'https://tatoeba.org/user/profile/{autor}', 'texto': eng[sid]}
        unicas[int(sid)] = n_gravacoes[sid] == 1

    print(f'{len(cods)} frases do curso (+{pulas} com campo da ficha, puladas) · {len(mapa)} com voz nativa '
          f'({sum(unicas.values())} com uma gravação só)', flush=True)
    for (autor, lic), n in collections.Counter((v['autor'], v['licenca']) for v in mapa.values()).most_common():
        print(f'  {autor} · {lic}: {n}')

    # a rodada anterior: {cod: entrada}, cada uma com o mp3 daquela gravação
    antes = json.load(open(SAIDA, encoding='utf-8')) if os.path.exists(SAIDA) else {}
    os.makedirs(PASTA_AUDIO, exist_ok=True)
    migrados = migrar_nomes_antigos(antes)
    if migrados:
        print(f'{migrados} mp3 renomeados para <sentence_id>-<audio_id>.mp3')

    def existe(nome):
        return os.path.exists(os.path.join(PASTA_AUDIO, nome))

    if not sem_baixar:
        falhas = []
        # o nome já diz a gravação: só baixa a que ainda não está na pasta
        novos = list({arquivo(v): v for v in mapa.values() if not existe(arquivo(v))}.values())
        feitos = [0]

        def baixar_gravacao(v):
            destino = os.path.join(PASTA_AUDIO, arquivo(v))
            try:
                if unicas[v['id']]:
                    dados, cab = baixar(URL_FRASE.format(id=v['id']))
                else:
                    dados, cab = baixar(URL_GRAVACAO.format(audio=v['audio']))
                    nome = re.search(r'filename="?([^";]+)', cab.get('Content-Disposition', '') or '')
                    esperado = f"{v['id']}-{v['audio']}.mp3"
                    if not nome or nome.group(1) != esperado:  # garante que é ESTA gravação
                        raise ValueError(f'arquivo {nome and nome.group(1)} ≠ {esperado}')
                if 'audio/mpeg' not in (cab.get('Content-Type') or ''):
                    raise ValueError(f"tipo {cab.get('Content-Type')}")
                if not (dados[:3] == b'ID3' or dados[:1] == b'\xff'):
                    raise ValueError('não parece mp3')
                tmp = destino + '.parcial'
                open(tmp, 'wb').write(dados)  # os bytes como vieram (licença ND)
                os.replace(tmp, destino)
            except Exception as e:  # noqa: BLE001 — fica a gravação anterior (ou a voz sintética)
                falhas.append(v['id'])
                print(f"  falhou {v['id']} ({v['texto']}): {e}", flush=True)
            feitos[0] += 1
            if feitos[0] % 50 == 0:
                print(f'  {feitos[0]}/{len(novos)} mp3', flush=True)
            time.sleep(PAUSA)

        with ThreadPoolExecutor(CONEXOES) as pool:
            list(pool.map(baixar_gravacao, novos))
        usados = {arquivo(v) for v in mapa_final(mapa, antes, existe).values()}
        # mp3 que nenhuma frase usa mais e restos de download interrompido (a pasta inteira vai pro app)
        sobras = [a for a in os.listdir(PASTA_AUDIO) if a not in usados]
        for a in sobras:
            os.remove(os.path.join(PASTA_AUDIO, a))
        total = sum(os.path.getsize(os.path.join(PASTA_AUDIO, a)) for a in os.listdir(PASTA_AUDIO) if a.endswith('.mp3'))
        print(f'{len(novos) - len(falhas)} mp3 novos, {len(falhas)} falhas, {len(sobras)} apagados · '
              f'{len(usados)} na pasta, {total / 1024 / 1024:.2f} MB')

    # só entra no JSON a gravação cujo mp3 está na pasta — também no --sem-baixar (o integrar confere de novo)
    trocadas = sum(1 for c, v in mapa.items() if not existe(arquivo(v)) and c in antes and existe(arquivo(antes[c])))
    mapa = mapa_final(mapa, antes, existe)
    if trocadas:
        print(f'{trocadas} frases ficam com a gravação anterior (o mp3 da escolha nova não está na pasta)')
    with open(SAIDA, 'w', encoding='utf-8') as arq:
        json.dump(dict(sorted(mapa.items())), arq, ensure_ascii=False, indent=1)
        arq.write('\n')
    print(f'{len(mapa)} frases → {os.path.relpath(SAIDA, RAIZ)}')


if __name__ == '__main__':
    main()
