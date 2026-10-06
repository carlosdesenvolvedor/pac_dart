// busca no TSV do Tatoeba: node tt.js "<regex en>" [maxPalavras] [limite]
const fs=require('fs');
const T='/private/tmp/claude-501/-Users-fazplay-pac-dart/8078ca22-ddb5-420e-8bff-f430c79360e9/scratchpad/ingles/pesquisa/fontes07/tatoeba_candidatas_en_ptbr.tsv';
if(!global.L){global.L=fs.readFileSync(T,'utf8').split('\n').slice(1).filter(Boolean).map(l=>l.split('\t'));}
const re=new RegExp(process.argv[2],'i'); const max=+(process.argv[3]||9); const lim=+(process.argv[4]||40);
let n=0; const seen=new Set();
for(const c of L){ if(+c[7]>max) continue; if(!re.test(c[2])) continue; const k=c[1]; if(seen.has(k)) {continue;} seen.add(k);
  console.log(`${c[0]} | ${c[1]} | ${c[2]} | ${c[3]} | ${c[4]} | ${c[5]} | ${c[6]}`); if(++n>=lim) break; }
