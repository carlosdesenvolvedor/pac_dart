campos = {
 "play_pt_titulo": ("Paclingo: aprenda digitando", 30),
 "play_pt_curta": ("Inglês, Dart e C# digitando: treino do dia, ouvir, jogos e conversa com IA.", 80),
 "play_en_titulo": ("Paclingo: learn by typing", 30),
 "play_en_curta": ("Learn English, Dart and C# by typing. Daily practice, listening, games, AI chat.", 80),
 "as_pt_sub": ("Inglês e código digitando", 30),
 "as_en_sub": ("Learn English by typing", 30),
 "as_pt_promo": ("Novo: Treino do dia, 🎧 Ouvir com setlists, conversa com IA e palavras teimosas que voltam até grudar. Digite, ouça, fale — e fixe de vez.", 170),
 "as_en_promo": ("New: daily practice, 🎧 listening playlists, AI conversation and stubborn words that come back until they stick. Type, listen, speak.", 170),
 "as_pt_kw": ("inglês,digitação,programação,vocabulário,idiomas,curso,código,frases,pronúncia,ouvir,conversa,teclado", 100),
 "as_en_kw": ("english,typing,learn,programming,vocabulary,coding,phrases,listening,flashcards,keyboard,portuguese", 100),
}
for k,(t,m) in campos.items():
    print(f"{k}: {len(t)}/{m} {'OK' if len(t)<=m else 'ESTOURA'}")
