#!/usr/bin/env python3
"""Troca o ID do app (hoje com.carlos.paclingo) em TODOS os lugares do projeto.

  python3 tool/trocar_id.py com.outro.paclingo            # aplica
  python3 tool/trocar_id.py com.outro.paclingo --simular  # só mostra o que mudaria

Só mexe em arquivos do projeto; os apps registrados no Firebase NÃO mudam sozinhos (o script
imprime os comandos no fim). Rode ANTES do primeiro upload: depois de publicado o ID é eterno.
"""
import pathlib, re, shutil, sys

raiz = pathlib.Path(__file__).resolve().parent.parent
ANTIGO = 'com.carlos.paclingo'

args = [a for a in sys.argv[1:] if not a.startswith('--')]
simular = '--simular' in sys.argv
if len(args) != 1 or not re.fullmatch(r'[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+', args[0]):
    sys.exit('uso: trocar_id.py <novo.id.do.app>   (minúsculas, letras/números/_, ao menos 2 partes)')
novo = args[0]
if novo == ANTIGO:
    sys.exit('o ID já é esse')

arquivos = [
    'android/app/build.gradle.kts',
    'ios/Runner.xcodeproj/project.pbxproj',
    'lib/firebase_options.dart',
]
for rel in arquivos:
    p = raiz / rel
    s = p.read_text()
    n = s.count(ANTIGO)
    print(f'{rel}: {n} ocorrência(s)')
    if n and not simular:
        p.write_text(s.replace(ANTIGO, novo))

# Kotlin: o pacote do MainActivity acompanha o ID (pasta + linha `package`)
velho_dir = raiz / 'android/app/src/main/kotlin' / pathlib.Path(*ANTIGO.split('.'))
novo_dir = raiz / 'android/app/src/main/kotlin' / pathlib.Path(*novo.split('.'))
if velho_dir.exists():
    print(f'MainActivity.kt: {velho_dir.relative_to(raiz)} -> {novo_dir.relative_to(raiz)}')
    if not simular:
        novo_dir.mkdir(parents=True, exist_ok=True)
        ativ = velho_dir / 'MainActivity.kt'
        destino = novo_dir / 'MainActivity.kt'
        shutil.move(str(ativ), str(destino))
        destino.write_text(destino.read_text().replace(f'package {ANTIGO}', f'package {novo}'))
        # remove as pastas antigas que ficaram vazias
        d = velho_dir
        base = raiz / 'android/app/src/main/kotlin'
        while d != base and d.exists() and not any(d.iterdir()):
            d.rmdir()
            d = d.parent
else:
    print('MainActivity.kt: pasta antiga não encontrada (já trocado?)')

print()
print('Falta (o Firebase guarda o ID de cada app; os apps antigos podem ser apagados no console):')
print(f'  firebase apps:create ANDROID "Paclingo (Android)" --package-name {novo} --project pac-dart')
print(f'  firebase apps:create IOS "Paclingo (iOS)" --bundle-id {novo} --project pac-dart')
print('  firebase apps:list --project pac-dart      # copie o App ID de cada um')
print('  -> troque `appId` (android e ios) em lib/firebase_options.dart; a `apiKey` pode ser a do sdkconfig:')
print('     firebase apps:sdkconfig ANDROID <appId> / IOS <appId> --project pac-dart')
print('  flutter clean && flutter build apk --debug    # confere que compila')
if simular:
    print('\n(simulação: nada foi alterado)')
