#!/bin/bash
# Validação final do currículo PAC·C# antes de integrar no app.
#  1. roda o laboratório (sem --fix) em todas as trilhas e desafios → tudo tem que dar OK
#  2. integra (integrar.py) em assets/csharp/curriculo.json
#  3. paridade app↔lab do botão "copiar" no currículo inteiro
# uso: bash validar_tudo.sh [--so-relatorio]
set -u
SCR=$(cd "$(dirname "$0")" && pwd)
export DOTNET_ROOT=/opt/homebrew/opt/dotnet/libexec
L="$DOTNET_ROOT/dotnet $SCR/lab/bin/lab/Lab.dll"
mkdir -p "$SCR/trabalho/_final" && cd "$SCR/trabalho/_final" || exit 1

falhas=0
for f in "$SCR"/trilhas/[0-9][0-9]-*.json; do
  n=$(basename "$f")
  if $L trilha "$f" > "log-$n.txt" 2>&1; then echo "ok    trilha   $n"; else echo "FALHA trilha   $n"; falhas=$((falhas+1)); fi
  d="$SCR/desafios/$n"
  if [ -e "$d" ]; then
    if $L desafios "$d" > "log-d-$n.txt" 2>&1; then echo "ok    desafios $n"; else echo "FALHA desafios $n"; falhas=$((falhas+1)); fi
  else
    echo "FALTA desafios $n"; falhas=$((falhas+1))
  fi
done
echo "== falhas: $falhas"
[ "${1:-}" = "--so-relatorio" ] && exit $falhas

python3 "$SCR/integrar.py" || exit 1
python3 - <<'EOF'
import json
d=json.load(open('/Users/fazplay/pac_dart/assets/csharp/curriculo.json'))
json.dump(d,open('curriculo_final.json','w'),ensure_ascii=False)
EOF
$L montar-lote curriculo_final.json lab_programas.json
cp /Users/fazplay/pac_dart/lib/core/util/programa_csharp.dart "$SCR/paridade/lib_programa_csharp.dart"
(cd "$SCR/paridade" && dart run bin/paridade.dart "$SCR/trabalho/_final/curriculo_final.json" "$SCR/trabalho/_final/lab_programas.json")
