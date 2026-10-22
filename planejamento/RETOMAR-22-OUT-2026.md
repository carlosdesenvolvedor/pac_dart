# Retomar daqui (22/out/2026)

## No main
- Tudo o que o `ESTADO-DO-PROJETO.md` descreve está juntado no `main` (último merge `e2cb03e`), inclusive as rodadas 16–19:
  📺 Escutar assistindo, 📺 na lição, as 121 trilhas com história escrita, a 2ª leva de arte, travadas do Turismo 3D no Leve,
  retoques dos mundos 3D, pergunta de compreensão e retoques do 📺.
- Deploy: até a rodada 16 está no ar; 17–19 estão no main — publicar com o deploy de sempre (confirmar o último deploy).
- Regra do dono: só o curso de **inglês** muda; Dart e C# ficam como estão. Código compartilhado (Arcade/Turismo 3D) só muda no
  inglês (`Linguagem.atual`, chave `ingles` do config do 3D).
- Resumo e links: seção "📌 Estado atual" no topo do `ESTADO-DO-PROJETO.md`.

## O que falta (só na máquina/contas do dono)
1. **Vozes por personagem** — branch `lote-vozes-wip` (fora do main). Precisa de `gcloud` logado no projeto `music-system-421ee`,
   Rhubarb e ffmpeg. Plano: `planejamento/historias-licoes/PLANO-VOZES.md`. ⚠️ `tools/ingles/vozes_google.py` apaga mp3 órfãos:
   rodar a simulação antes; depois revisar, rodar os testes e conferir no navegador antes de juntar.
2. **Claude na Conversa (Fase 11)** — publicar o Worker `workers/conversa-claude/` (passos no `LEIA-ME.md` dele) e ligar em
   `config/tutor` (`provedorConversa = "claude"` + `urlConversa`). Até lá a Conversa usa o Gemini; apagar `provedorConversa` volta.
3. **Lojas** — seção "📲 Lojas" do ESTADO, `branding/lojas/CHECKLIST.md` e `planejamento/lojas-pendente/PLANO-LOJAS.md`.
4. **Provas em aparelho de verdade** — o "conferir no aparelho" de cada seção (📺, Turismo no Leve, 🎧 Ouvir, 💬 Conversa, lembrete…).
5. **Regras do Firestore** — confirmar que o `firestore.rules` do main está publicado (`firebase deploy --only firestore:rules`, antes do hosting).

Testes: ≈ 3.250; 6 falhas conhecidas — as 5 de `test/csharp_curriculo_test.dart` (C# incompleto, fora do escopo) e "o motor digita
toda frase…" de `test/ingles_curriculo_test.dart` (estoura 30 s em máquina lenta).
Em andamento: branches `claude/arte-historias-2` e `claude/desempenho-2`.

## Planos
📺 `planejamento/historias-licoes/PLANO.md` (+ `PLANO-VOZES.md`, `PEDIDOS-DE-ARTE.md`); fases em `planejamento/FASE-*.md`;
sessão na nuvem: `planejamento/PROMPT-NUVEM.md` e `planejamento/RELATORIO-NUVEM.md`.
