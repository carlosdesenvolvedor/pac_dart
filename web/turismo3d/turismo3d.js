// 🏎️ Dart Turismo — renderizador 3D REAL (Three.js) da corrida.
// A lógica do jogo vive em Dart (TurismoEngine); este módulo só desenha:
// pista curva em geometria de verdade, asfalto/grama PBR (Poly Haven, CC0),
// céu HDRI por mundo, guard-rails, zebras, pórticos com placas, carros glTF
// (Sketchfab, CC-BY) com sombra e reflexo, faróis à noite e câmera de
// perseguição. API: window.turismo3d.{montar, atualizar, pronto, destruir}.
import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { RGBELoader } from 'three/addons/loaders/RGBELoader.js';
import { DRACOLoader } from 'three/addons/loaders/DRACOLoader.js';

const TEMAS = {
  1: { hdri: 'campina', chao: 'leafy_grass', repChao: 260, exposicao: 1.0, sol: [-0.5, 0.75, 0.35], solCor: 0xfff1d6, solForca: 2.4, noturno: false, neblina: 0xdbe9ff, densidade: 0.0016,
       cenario: { modelos: ['shrub_03', 'shrub_04', 'rock_moss_set_01', 'tree_stump_01'], pesos: [7, 3, 1, 1], passo: 16 } },
  2: { hdri: 'deserto', chao: 'sand_01', repChao: 220, exposicao: 1.05, sol: [0.55, 0.6, -0.3], solCor: 0xffe6c0, solForca: 2.6, noturno: false, neblina: 0xf3dcb4, densidade: 0.0014,
       cenario: { modelos: ['namaqualand_boulder_04', 'rock_09', 'quiver_tree_02'], pesos: [2, 5, 1], passo: 20 } },
  3: { hdri: 'cidade', chao: 'concrete_floor_02', repChao: 200, exposicao: 0.85, sol: [0.3, 0.7, 0.4], solCor: 0x9fb7ff, solForca: 0.35, noturno: true, neblina: 0x141a28, densidade: 0.0022, lampadas: true, cidade: true },
  4: { hdri: 'neve', chao: 'snow_02', repChao: 240, exposicao: 1.0, sol: [-0.35, 0.65, 0.5], solCor: 0xffffff, solForca: 2.0, noturno: false, neblina: 0xeaf3ff, densidade: 0.0020,
       cenario: { modelos: ['boulder_01', 'rock_09', 'dead_tree_trunk'], pesos: [1, 5, 1], passo: 26 } },
  5: { hdri: 'vulcao', chao: 'dark_rock', repChao: 200, exposicao: 1.05, sol: [0.7, 0.35, 0.2], solCor: 0xff9a6a, solForca: 1.6, noturno: true, neblina: 0x3a1c14, densidade: 0.0024,
       cenario: { modelos: ['moon_rock_01', 'moon_rock_03', 'moon_rock_05'], pesos: [1, 2, 2], passo: 22 } },
  6: { hdri: 'espaco', chao: 'dark_rock', repChao: 200, exposicao: 0.95, sol: [0.1, 0.8, 0.3], solCor: 0xc8d8ff, solForca: 0.5, noturno: true, neblina: 0x0a0e1e, densidade: 0.0015,
       cenario: { modelos: ['moon_rock_01', 'moon_rock_03', 'moon_rock_05'], pesos: [1, 2, 2], passo: 30 } },
};

// Carros (Sketchfab, CC Attribution — créditos no jogo). `giro` alinha a
// frente do modelo com −z; `comprimento` em metros.
const CARROS = {
  porsche_930: { arquivo: 'assets3d/carros/porsche_930/scene.gltf', comprimento: 4.3, giro: Math.PI },
  skyline_r34: { arquivo: 'assets3d/carros/skyline_r34/scene.gltf', comprimento: 4.6, giro: Math.PI },
  honda_nsx: { arquivo: 'assets3d/carros/honda_nsx/scene.gltf', comprimento: 4.4, giro: Math.PI },
  mazda_miata: { arquivo: 'assets3d/carros/mazda_miata/scene.gltf', comprimento: 3.95, giro: Math.PI },
  toyota_ae86: { arquivo: 'assets3d/carros/toyota_ae86/scene.gltf', comprimento: 4.2, giro: Math.PI },
};

const LARGURA_FAIXA = 3.7;
const MEIA_PISTA = LARGURA_FAIXA * 1.5;
const CURVA_RAD = 0.028; // curva 6 → raio ≈ 48 m; curva 1,5 → ≈ 190 m (segmentos de 8 m)

let renderer, scene, camera, sol, relogio, luzCarro = null, chaoPlano = null;
let cfg = null, estado = null, animId = 0, resizeObs = null;
let centro = [], L = 8;
let carro = null, faroisLuz = [], fantasma = null;
let portais = []; // { grupo, placas:[{tex, ctx, canvas, faixa, estiloAtual}], flags }
let obstaculos = [];
let modelosCache = {};
// Um LoadingManager só: dá pra ESPERAR tudo (texturas, glTF, HDRI) antes da
// largada — e é isso que evita os engasgos dos primeiros segundos
// (cada textura que chega é um upload pra GPU no meio da corrida).
const gerente = new THREE.LoadingManager();
let carregando = false, esperandoCarga = [];
gerente.onStart = () => { carregando = true; };
gerente.onLoad = () => { carregando = false; for (const r of esperandoCarga.splice(0)) r(); };
gerente.onError = (url) => console.warn('[turismo3d] falhou:', url);
function esperarCarregamento(ms) {
  if (!carregando) return Promise.resolve();
  return new Promise((res) => {
    esperandoCarga.push(res);
    setTimeout(res, ms);
  });
}
let texLoader = new THREE.TextureLoader(gerente);
let gltfLoader = null;

// ---------- GPU e qualidade adaptativa ----------
// Sonda a GPU num contexto descartável ANTES de criar o renderer: sem
// aceleração (SwiftShader) ou GPU integrada fraca começa em nível mais leve;
// depois uma medição real (mediana de 24 frames com a cena pronta) e um
// vigia durante a corrida rebaixam o nível se o frame passar de ~26 ms.
function sondarGpu() {
  try {
    const c = document.createElement('canvas');
    const gl = c.getContext('webgl2') || c.getContext('webgl');
    if (!gl) return { nome: '', software: false, fraca: false };
    const ext = gl.getExtension('WEBGL_debug_renderer_info');
    const nome = String(ext ? gl.getParameter(ext.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER));
    const l = gl.getExtension('WEBGL_lose_context');
    if (l) l.loseContext();
    const software = /swiftshader|software|llvmpipe|basic render|microsoft basic/i.test(nome);
    const fraca = software || /intel\(r\) (hd|uhd) graphics|intel hd|intel uhd|mali-|adreno [1-5]|powervr/i.test(nome);
    return { nome, software, fraca };
  } catch (e) {
    return { nome: '', software: false, fraca: false };
  }
}
let nivelQualidade = 'alta'; // alta · leve · minima
// o que cada nível liga: cenário instanciado (arbustos com alpha = overdraw
// caro em GPU fraca), luzes dinâmicas (faróis, luz de acompanhamento,
// postes) e até onde o tráfego é desenhado
const PERFIS = {
  alta: { cenario: true, cenarioAlcance: 420, metade: false, luzes: true, trafego: 220 },
  leve: { cenario: true, cenarioAlcance: 240, metade: true, luzes: true, trafego: 170 },
  minima: { cenario: false, cenarioAlcance: 0, metade: true, luzes: false, trafego: 150 },
};
// cenário e postes: trechos de 160 m ligados por distância a cada frame
const TRECHO = 160;
let lampadasMalhas = [];
function cularPorDistancia(lista, pos, ligado, alcance, soMetade) {
  for (const m of lista) {
    const dz = m.userData.d - pos;
    m.visible = ligado && dz > -(TRECHO / 2 + 60) && dz < alcance + TRECHO / 2 && (!soMetade || m.userData.metade === 0);
  }
}
let perfilAtual = PERFIS.alta;
// benchmark de ~0,3 s num renderer descartável: 24 esferas de 12k
// triângulos com textura e 3 luzes — se isso não roda a 50 fps, a cena de
// verdade não vai rodar. Decide o nível ANTES de baixar céu 2k/texturas 1k.
async function benchmarkGpu(antialias) {
  let r = null;
  try {
    const c = document.createElement('canvas');
    r = new THREE.WebGLRenderer({ canvas: c, antialias, powerPreference: 'high-performance' });
    r.setPixelRatio(1);
    r.setSize(960, 600, false);
    const cena = new THREE.Scene();
    const cam = new THREE.PerspectiveCamera(60, 1.6, 0.1, 100);
    cam.position.set(0, 0, 13);
    const geo = new THREE.SphereGeometry(1.25, 96, 64);
    const tex = canvasTex(512, 512, (ctx, w, h) => {
      for (let i = 0; i < 300; i++) { ctx.fillStyle = `hsl(${(i * 37) % 360},60%,50%)`; ctx.fillRect((i * 97) % w, (i * 53) % h, 48, 48); }
    }).tex;
    const mat = new THREE.MeshStandardMaterial({ map: tex, metalness: .4, roughness: .5 });
    for (let i = 0; i < 24; i++) {
      const m = new THREE.Mesh(geo, mat);
      m.position.set((i % 6 - 2.5) * 3.1, (Math.floor(i / 6) - 1.5) * 3.1, 0);
      cena.add(m);
    }
    cena.add(new THREE.HemisphereLight(0xffffff, 0x444444, 1));
    for (let i = 0; i < 3; i++) { const l = new THREE.PointLight(0xffffff, 40, 50); l.position.set(i * 6 - 6, 4, 7); cena.add(l); }
    r.render(cena, cam); // compila os shaders fora da medição
    await new Promise((res) => requestAnimationFrame(res));
    const ts = [];
    let ultimo = performance.now();
    for (let i = 0; i < 16; i++) {
      await new Promise((res) => requestAnimationFrame(res));
      r.render(cena, cam);
      const t = performance.now();
      ts.push(t - ultimo);
      ultimo = t;
    }
    geo.dispose(); mat.dispose(); tex.dispose();
    r.dispose();
    try { r.forceContextLoss(); } catch (e) {}
    return mediana(ts.slice(3));
  } catch (e) {
    console.warn('[turismo3d] benchmark', e);
    try { if (r) r.dispose(); } catch (e2) {}
    return 0;
  }
}
function aplicarQualidade(nivel) {
  nivelQualidade = nivel;
  perfilAtual = PERFIS[nivel] || PERFIS.alta;
  api.qualidadeEfetiva = nivel;
  for (const m of cenarioMalhas) m.castShadow = nivel === 'alta';
  for (const m of lampadasMalhas) m.castShadow = false;
  if (luzCarro) luzCarro.visible = perfilAtual.luzes;
  for (const l of faroisLuz) l.visible = perfilAtual.luzes;
  if (!perfilAtual.luzes) for (const l of luzesPool) l.visible = false;
  if (!renderer) return;
  const dpr = window.devicePixelRatio || 1;
  // mínima renderiza a 75% da resolução: em GPU fraca o gargalo é o preenchimento
  renderer.setPixelRatio(nivel === 'alta' ? Math.min(dpr, 2) : (nivel === 'leve' ? Math.min(dpr, 1.25) : 0.75));
  if (ultimoW && ultimoH) renderer.setSize(ultimoW, ultimoH, false);
  const sombras = nivel !== 'minima';
  renderer.shadowMap.enabled = sombras;
  if (sol) {
    sol.castShadow = sombras;
    const n = nivel === 'alta' ? 2048 : 1024;
    if (sol.shadow.mapSize.x !== n) {
      sol.shadow.mapSize.set(n, n);
      if (sol.shadow.map) { sol.shadow.map.dispose(); sol.shadow.map = null; }
    }
  }
  console.info('[turismo3d] qualidade:', nivel);
}
function medirFrames(n) {
  return new Promise((res) => {
    const ts = [];
    let ultimo = performance.now();
    const f = () => {
      const t = performance.now();
      ts.push(t - ultimo);
      ultimo = t;
      if (ts.length < n) requestAnimationFrame(f); else res(ts);
    };
    requestAnimationFrame(f);
  });
}
function mediana(lista) {
  const o = [...lista].sort((a, b) => a - b);
  return o.length ? o[Math.floor(o.length / 2)] : 0;
}
async function medirDesempenho() {
  const ts = await medirFrames(30);
  const m = mediana(ts.slice(6));
  api.frameMs = +m.toFixed(1);
  if (m > 40 && nivelQualidade !== 'minima') aplicarQualidade('minima');
  else if (m > 24 && nivelQualidade === 'alta') aplicarQualidade('leve');
}
let vigiaTempos = [], vigiaAte = 0, ultimoQuadroMs = 0;
function vigiarDesempenho() {
  const agora = performance.now();
  const dt = ultimoQuadroMs ? agora - ultimoQuadroMs : 16;
  ultimoQuadroMs = agora;
  if (!api.pronto || agora < vigiaAte || dt > 500) return;
  vigiaTempos.push(dt);
  if (vigiaTempos.length < 150) return;
  const m = mediana(vigiaTempos);
  vigiaTempos = [];
  api.frameMs = +m.toFixed(1);
  if (m > 26 && nivelQualidade !== 'minima') {
    aplicarQualidade(nivelQualidade === 'alta' ? 'leve' : 'minima');
    vigiaAte = agora + 6000;
  }
}
// compila os shaders e força os uploads de textura/PMREM antes da largada
// (no Windows o ANGLE traduz GLSL→HLSL: cada material novo custava um
// engasgo no primeiro frame em que aparecia)
async function aquecer() {
  try {
    if (renderer.compileAsync) await renderer.compileAsync(scene, camera); else renderer.compile(scene, camera);
  } catch (e) { console.warn('[turismo3d] compile', e); }
  const salvo = [];
  for (const o of obstaculos) { salvo.push(o.visible); o.visible = true; }
  for (const m of cenarioMalhas) m.visible = true;
  for (const m of lampadasMalhas) m.visible = true;
  try { for (let i = 0; i < 3; i++) renderer.render(scene, camera); } catch (e) { console.warn('[turismo3d] aquecer', e); }
  obstaculos.forEach((o, i) => { o.visible = salvo[i]; });
}
let camPos = new THREE.Vector3(), camAlvo = new THREE.Vector3();
let tremor = 0;
const api = { pronto: false, erro: null, progresso: 0 };

// ---------- qualidade ----------
// 'alta': HDRI 2k, texturas 1k, sombra 2048, pixel ratio ≤ 2, anisotropia 16
// 'leve': HDRI 1k, texturas 512, sombra 1024, pixel ratio ≤ 1.5
// 'auto': leve em tela de toque pequena, alta no resto. (O usuário topou
// carregamento mais longo em troca de qualidade.)
let qualidadeAlta = true;
function resolverQualidade(pref) {
  if (pref === 'alta') return true;
  if (pref === 'leve') return false;
  const toque = (navigator.maxTouchPoints || 0) > 0;
  const pequena = Math.min(window.innerWidth, window.innerHeight) < 700;
  return !(toque && pequena);
}

function pose(d) {
  const n = centro.length - 1;
  const f = Math.max(0, Math.min(d / L, n - 0.0001));
  const i = Math.floor(f), t = f - i;
  const a = centro[i], b = centro[Math.min(i + 1, n)];
  return {
    x: a.x + (b.x - a.x) * t,
    z: a.z + (b.z - a.z) * t,
    h: a.h + (b.h - a.h) * t,
  };
}
function frente(h) { return new THREE.Vector3(Math.sin(h), 0, -Math.cos(h)); }
function direita(h) { return new THREE.Vector3(Math.cos(h), 0, Math.sin(h)); }

function construirCentro(segmentos) {
  centro = [];
  let x = 0, z = 0, h = 0;
  for (let i = 0; i < segmentos.length; i++) {
    centro.push({ x, z, h });
    h += segmentos[i] * CURVA_RAD;
    x += Math.sin(h) * L;
    z -= Math.cos(h) * L;
  }
  centro.push({ x, z, h });
}

// ---------- texturas ----------
function textura(url, { srgb = false, rep = 1 } = {}) {
  const t = texLoader.load(url);
  t.wrapS = t.wrapT = THREE.RepeatWrapping;
  t.repeat.set(rep, rep);
  if (srgb) t.colorSpace = THREE.SRGBColorSpace;
  t.anisotropy = 8;
  if (t.anisotropy !== undefined) t.anisotropy = qualidadeAlta ? 16 : 8;
  return t;
}
function materialPbr(nome, { repU = 1, repV = 1, rough = 1, metal = 0 } = {}) {
  const base = `assets3d/${qualidadeAlta ? 'tex1k' : 'tex'}/${nome}/`;
  const arm = textura(base + 'arm.jpg');
  const m = new THREE.MeshStandardMaterial({
    map: textura(base + 'diff.jpg', { srgb: true }),
    normalMap: textura(base + 'nor.jpg'),
    aoMap: arm,
    roughnessMap: arm,
    metalnessMap: metal > 0 ? arm : null,
    roughness: rough,
    metalness: metal,
    color: 0x9a9a9a, // cinza até a textura chegar (nada de preto)
  });
  m.map.onUpdate = () => { m.color.set(0xffffff); };
  if (m.map.image) m.color.set(0xffffff);
  for (const t of [m.map, m.normalMap, m.aoMap]) t.repeat.set(repU, repV);
  return m;
}

function canvasTex(w, h, pintar) {
  const c = document.createElement('canvas');
  c.width = w; c.height = h;
  const ctx = c.getContext('2d');
  pintar(ctx, w, h);
  const t = new THREE.CanvasTexture(c);
  t.colorSpace = THREE.SRGBColorSpace;
  t.anisotropy = 8;
  return { tex: t, ctx, canvas: c };
}

// ---------- pista ----------
function faixaGeometria(lateralA, lateralB, alturaA = 0, alturaB = 0, repV = 8) {
  const n = centro.length;
  const pos = new Float32Array(n * 2 * 3);
  const uv = new Float32Array(n * 2 * 2);
  const idx = [];
  for (let i = 0; i < n; i++) {
    const p = centro[i];
    const r = direita(p.h);
    const ax = p.x + r.x * lateralA, az = p.z + r.z * lateralA;
    const bx = p.x + r.x * lateralB, bz = p.z + r.z * lateralB;
    pos.set([ax, alturaA, az, bx, alturaB, bz], i * 6);
    const v = (i * L) / repV;
    uv.set([0, v, 1, v], i * 4);
    if (i < n - 1) {
      const k = i * 2;
      idx.push(k, k + 1, k + 2, k + 1, k + 3, k + 2); // anti-horário visto de cima → normal +y
    }
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  g.setAttribute('uv', new THREE.BufferAttribute(uv, 2));
  g.setAttribute('uv2', new THREE.BufferAttribute(uv, 2));
  g.setIndex(idx);
  g.computeVertexNormals();
  return g;
}

function construirPista(tema) {
  // asfalto (3 faixas + acostamento curto)
  const asfalto = materialPbr('asphalt_track', { repU: 1.6, repV: 1, rough: 1 });
  const estrada = new THREE.Mesh(faixaGeometria(-MEIA_PISTA - 0.3, MEIA_PISTA + 0.3, 0, 0, 6), asfalto);
  estrada.receiveShadow = true;
  scene.add(estrada);

  // pintura: linhas de borda e tracejado entre faixas (tile = 8 m)
  const pintura = canvasTex(512, 512, (ctx, w, h) => {
    ctx.clearRect(0, 0, w, h);
    ctx.fillStyle = 'rgba(255,255,255,0.85)';
    ctx.fillRect(w * 0.028, 0, w * 0.012, h);
    ctx.fillRect(w * 0.96, 0, w * 0.012, h);
    for (const u of [1 / 3, 2 / 3]) {
      for (const v0 of [0.05, 0.55]) ctx.fillRect(w * u - w * 0.006, h * v0, w * 0.012, h * 0.28);
    }
  });
  const tinta = new THREE.MeshStandardMaterial({ map: pintura.tex, transparent: true, roughness: .6, metalness: 0, polygonOffset: true, polygonOffsetFactor: -1 });
  const linhas = new THREE.Mesh(faixaGeometria(-MEIA_PISTA - 0.3, MEIA_PISTA + 0.3, 0.012, 0.012, 8), tinta);
  scene.add(linhas);

  // zebras vermelhas e brancas nas bordas (tile de 4 m)
  const zebra = canvasTex(64, 256, (ctx, w, h) => {
    ctx.fillStyle = '#e53935'; ctx.fillRect(0, 0, w, h / 2);
    ctx.fillStyle = '#f5f5f5'; ctx.fillRect(0, h / 2, w, h / 2);
  });
  const zebraMat = new THREE.MeshStandardMaterial({ map: zebra.tex, roughness: .55 });
  for (const lado of [-1, 1]) {
    const z = new THREE.Mesh(faixaGeometria(lado * (MEIA_PISTA + 0.3), lado * (MEIA_PISTA + 0.95), 0.02, 0.06, 4), zebraMat);
    z.receiveShadow = true;
    scene.add(z);
  }

  // chão do mundo
  const chao = materialPbr(tema.chao, { repU: tema.repChao, repV: tema.repChao, rough: 1 });
  const plano = new THREE.Mesh(new THREE.PlaneGeometry(4000, 4000), chao);
  plano.rotation.x = -Math.PI / 2;
  plano.position.y = -0.04;
  plano.receiveShadow = true;
  plano.userData.tile = 4000 / tema.repChao;
  scene.add(plano);
  chaoPlano = plano;

  // guard-rails: lâmina metálica + postes
  const metal = materialPbr('metal_plate', { repU: 1, repV: 1, rough: .5, metal: 1 });
  for (const lado of [-1, 1]) {
    const lat = lado * (MEIA_PISTA + 2.2);
    const lamina = new THREE.Mesh(faixaGeometria(lat, lat + lado * 0.02, 0.42, 0.78, 4), metal);
    lamina.material.side = THREE.DoubleSide;
    lamina.castShadow = true;
    scene.add(lamina);
    const n = Math.floor(centro.length / 2);
    const postes = new THREE.InstancedMesh(new THREE.BoxGeometry(0.08, 0.75, 0.08), new THREE.MeshStandardMaterial({ color: 0x8a96a3, roughness: .6, metalness: .6 }), n);
    const m = new THREE.Matrix4();
    for (let k = 0; k < n; k++) {
      const p = centro[k * 2];
      const r = direita(p.h);
      m.makeRotationY(-p.h);
      m.setPosition(p.x + r.x * lat, 0.37, p.z + r.z * lat);
      postes.setMatrixAt(k, m);
    }
    postes.castShadow = true;
    scene.add(postes);
  }

  // largada e chegada quadriculadas
  const xadrez = canvasTex(256, 64, (ctx, w, h) => {
    const lado = 32;
    for (let i = 0; i < w / lado; i++) for (let j = 0; j < h / lado; j++) {
      ctx.fillStyle = (i + j) % 2 ? '#111' : '#fafafa';
      ctx.fillRect(i * lado, j * lado, lado, lado);
    }
  });
  const xadrezMat = new THREE.MeshStandardMaterial({ map: xadrez.tex, roughness: .7, polygonOffset: true, polygonOffsetFactor: -2 });
  for (const d of [16, cfg.distancia]) {
    const linha = new THREE.Mesh(new THREE.PlaneGeometry(MEIA_PISTA * 2 + 0.6, 2.4), xadrezMat);
    const p = pose(d);
    linha.rotation.x = -Math.PI / 2;
    linha.rotation.z = -p.h;
    linha.position.set(p.x, 0.02, p.z);
    scene.add(linha);
  }
  construirPortalDeChegada();
}

// ---------- pórticos ----------
function pintarPlaca(ctx, w, h, texto, estilo) {
  const cores = {
    livre: ['#10131a', '#57c765', '#ffffff'],
    travada: ['#10131a', '#ffc73b', '#ffffff'],
    digitada: ['#1b5e20', '#57c765', '#9ce99c'],
    bloqueada: ['#b3261e', '#ff8a80', '#ffffff'],
    batida: ['#5a0f0f', '#ff5252', '#ffb3b3'],
    chegada: ['#10131a', '#ffc73b', '#ffc73b'],
  }[estilo] || ['#10131a', '#57c765', '#fff'];
  ctx.clearRect(0, 0, w, h);
  ctx.fillStyle = cores[0];
  ctx.beginPath(); ctx.roundRect(4, 4, w - 8, h - 8, 22); ctx.fill();
  ctx.lineWidth = 12; ctx.strokeStyle = cores[1]; ctx.stroke();
  ctx.fillStyle = cores[2];
  ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
  let tam = 96;
  ctx.font = `800 ${tam}px "JetBrains Mono", "Roboto Mono", monospace`;
  while (ctx.measureText(texto).width > w * 0.84 && tam > 28) { tam -= 6; ctx.font = `800 ${tam}px "JetBrains Mono", "Roboto Mono", monospace`; }
  ctx.fillText(texto, w / 2, h / 2 + 6);
}

// ---------- fichas (moedas de programação) ----------
function texturaFicha(texto) {
  const ct = canvasTex(256, 256, (ctx, w, h) => {
    const g = ctx.createRadialGradient(w * .4, h * .35, 10, w / 2, h / 2, w / 2);
    g.addColorStop(0, '#fff2b0'); g.addColorStop(.6, '#ffc73b'); g.addColorStop(1, '#b8860b');
    ctx.fillStyle = g;
    ctx.beginPath(); ctx.arc(w / 2, h / 2, w / 2 - 4, 0, Math.PI * 2); ctx.fill();
    ctx.lineWidth = 10; ctx.strokeStyle = '#8a6508';
    ctx.beginPath(); ctx.arc(w / 2, h / 2, w / 2 - 12, 0, Math.PI * 2); ctx.stroke();
    ctx.fillStyle = '#3b2a00';
    ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    let tam = 110;
    ctx.font = `800 ${tam}px "JetBrains Mono", "Roboto Mono", monospace`;
    while (ctx.measureText(texto).width > w * .7 && tam > 40) { tam -= 6; ctx.font = `800 ${tam}px "JetBrains Mono", "Roboto Mono", monospace`; }
    ctx.fillText(texto, w / 2, h / 2 + 6);
  });
  return ct.tex;
}
function construirFichas(port, p) {
  port.fichas = [];
  if (!p.fichas) return;
  for (const f of p.fichas) {
    const tex = texturaFicha(f.texto);
    const mat = new THREE.MeshStandardMaterial({ map: tex, emissive: 0xffc73b, emissiveMap: tex, emissiveIntensity: .35, metalness: .6, roughness: .35, side: THREE.DoubleSide, transparent: true });
    const moeda = new THREE.Mesh(new THREE.CircleGeometry(0.62, 32), mat);
    const q = pose(f.z);
    const r = direita(q.h);
    const lat = (f.faixa - 1) * LARGURA_FAIXA;
    moeda.position.set(q.x + r.x * lat, 1.0, q.z + r.z * lat);
    moeda.userData.z = f.z;
    moeda.userData.fase = Math.random() * Math.PI * 2;
    moeda.castShadow = true;
    scene.add(moeda);
    port.fichas.push(moeda);
  }
}
function animarFichas(t, posicao) {
  for (const port of portais) {
    if (!port.fichas) continue;
    for (const m of port.fichas) {
      if (m.userData.pega) continue;
      const dz = m.userData.z - posicao;
      m.visible = dz > -20 && dz < 260;
      if (!m.visible) continue;
      m.rotation.y = t * 2.2 + m.userData.fase;
      m.position.y = 1.0 + Math.sin(t * 2.5 + m.userData.fase) * 0.12;
    }
  }
}
// 🪙 pegou a ficha: ela voa pra cima girando, cresce e some num brilho,
// e um "+3 🪙" sobe do lugar (pool de 6 sprites)
let coletas = [], popups = [], popupTex = null;
function coletarFicha(fx) {
  fx.userData.pega = true;
  fx.userData.baseY = fx.position.y;
  fx.userData.t0 = relogioAnim;
  coletas.push(fx);
  soltarFaiscas(fx.position.clone(), frente(0), 0xffd54f, 40);
  soltarFaiscas(fx.position.clone(), frente(0), 0xffffff, 12);
  if (!popupTex) {
    popupTex = canvasTex(256, 128, (ctx, w, h) => {
      ctx.clearRect(0, 0, w, h);
      ctx.font = '900 84px "Inter", "Roboto", sans-serif';
      ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
      ctx.lineWidth = 10; ctx.strokeStyle = 'rgba(0,0,0,0.75)';
      ctx.strokeText('+3 🪙', w / 2, h / 2);
      ctx.fillStyle = '#ffd54f';
      ctx.fillText('+3 🪙', w / 2, h / 2);
    }).tex;
  }
  let sp = popups.find((x) => !x.visible);
  if (!sp && popups.length < 6) {
    sp = new THREE.Sprite(new THREE.SpriteMaterial({ map: popupTex, transparent: true, depthTest: false }));
    sp.renderOrder = 998;
    scene.add(sp);
    popups.push(sp);
  }
  if (sp) {
    sp.visible = true;
    sp.position.copy(fx.position);
    sp.position.y += 0.6;
    sp.userData.t0 = relogioAnim;
    sp.material.opacity = 1;
  }
}
function animarColetas(t) {
  for (let i = coletas.length - 1; i >= 0; i--) {
    const m = coletas[i];
    const p = (t - m.userData.t0) / 0.55;
    if (p >= 1) { m.visible = false; coletas.splice(i, 1); continue; }
    m.visible = true;
    m.position.y = m.userData.baseY + 2.4 * p;
    m.rotation.y += 0.45;
    const esc = 1 + 1.1 * Math.sin(p * Math.PI) * (1 - p * 0.5);
    m.scale.setScalar(Math.max(0.01, esc * (1 - p * p)));
  }
  for (const sp of popups) {
    if (!sp.visible) continue;
    const p = (t - sp.userData.t0) / 0.95;
    if (p >= 1) { sp.visible = false; continue; }
    sp.position.y += 0.05;
    sp.material.opacity = p < 0.6 ? 1 : 1 - (p - 0.6) / 0.4;
    // tamanho constante na tela: escala com a distância da câmera
    const dist = camera ? camera.position.distanceTo(sp.position) : 10;
    const k = dist * 0.065 * (1 + 0.35 * Math.min(1, p * 3));
    sp.scale.set(2 * k, 1 * k, 1);
  }
}

function construirPortais() {
  const posteGeo = new THREE.CylinderGeometry(0.14, 0.16, 5.8, 12);
  const posteMat = new THREE.MeshStandardMaterial({ color: 0xdfe4e9, roughness: .4, metalness: .7 });
  const vigaGeo = new THREE.BoxGeometry(MEIA_PISTA * 2 + 2.4, 0.4, 0.4);
  const vigaMat = new THREE.MeshStandardMaterial({ color: 0x2a2f38, roughness: .5, metalness: .6 });
  const placaGeo = new THREE.PlaneGeometry(3.1, 1.05);
  portais = [];
  // postes e vigas de todos os pórticos viram UMA malha cada (2 draw calls
  // pra pista inteira em vez de 3 por pórtico)
  const postesGeos = [], vigasGeos = [];
  for (const p of cfg.portais) {
    const grupo = new THREE.Group();
    const q = pose(p.z);
    grupo.position.set(q.x, 0, q.z);
    grupo.rotation.y = -q.h;
    const M = new THREE.Matrix4().makeRotationY(-q.h);
    M.setPosition(q.x, 0, q.z);
    for (const lado of [-1, 1]) {
      postesGeos.push(posteGeo.clone().translate(lado * (MEIA_PISTA + 1.1), 2.9, 0).applyMatrix4(M));
    }
    vigasGeos.push(vigaGeo.clone().translate(0, 5.6, 0).applyMatrix4(M));
    const placas = [];
    for (let faixa = 0; faixa < 3; faixa++) {
      const i = p.faixas.indexOf(faixa);
      const texto = i >= 0 ? p.palavras[i] : '✕';
      const estilo = i >= 0 ? 'livre' : 'bloqueada';
      const ct = canvasTex(512, 176, (ctx, w, h) => pintarPlaca(ctx, w, h, texto, estilo));
      const mat = new THREE.MeshStandardMaterial({ map: ct.tex, transparent: true, roughness: .5, emissive: 0xffffff, emissiveMap: ct.tex, emissiveIntensity: cfg.tema.noturno ? 0.9 : 0.35 });
      const placa = new THREE.Mesh(placaGeo, mat);
      placa.position.set((faixa - 1) * LARGURA_FAIXA, 4.55, 0.22);
      grupo.add(placa);
      placas.push({ ...ct, faixa, texto, estiloAtual: estilo, i });
    }
    scene.add(grupo);
    const port = { grupo, placas, dados: p };
    construirFichas(port, p);
    portais.push(port);
  }
  if (postesGeos.length) {
    const postes = new THREE.Mesh(fundir(postesGeos), posteMat);
    postes.castShadow = true;
    scene.add(postes);
    const vigas = new THREE.Mesh(fundir(vigasGeos), vigaMat);
    vigas.castShadow = true;
    scene.add(vigas);
  }
}

function construirPortalDeChegada() {
  const q = pose(cfg.distancia);
  const grupo = new THREE.Group();
  grupo.position.set(q.x, 0, q.z);
  grupo.rotation.y = -q.h;
  const posteMat = new THREE.MeshStandardMaterial({ color: 0xdfe4e9, roughness: .4, metalness: .7 });
  for (const lado of [-1, 1]) {
    const poste = new THREE.Mesh(new THREE.CylinderGeometry(0.16, 0.18, 6.4, 12), posteMat);
    poste.position.set(lado * (MEIA_PISTA + 1.3), 3.2, 0);
    poste.castShadow = true;
    grupo.add(poste);
  }
  const faixa = canvasTex(1024, 192, (ctx, w, h) => pintarPlaca(ctx, w, h, '🏁 CHEGADA', 'chegada'));
  const banner = new THREE.Mesh(new THREE.PlaneGeometry(MEIA_PISTA * 2 + 2.2, 1.35), new THREE.MeshStandardMaterial({ map: faixa.tex, transparent: true, emissive: 0xffffff, emissiveMap: faixa.tex, emissiveIntensity: .5 }));
  banner.position.set(0, 5.7, 0);
  grupo.add(banner);
  scene.add(grupo);
}

// ---------- batida física ----------
// O carro parado da faixa é arremessado: gira, capota de leve, desliza pra
// fora da pista e some; faíscas saltam do ponto do impacto.
let arremessos = [];
let faiscas = [];
let relogioAnim = 0;
function bater(port, faixaJogador, zCarro) {
  const alvo = obstaculos.find((o) => o.userData.portal === port.dados.indice && o.userData.faixa === faixaJogador);
  const q = pose(zCarro != null ? zCarro : port.dados.z + 2.6);
  const f = frente(q.h), r = direita(q.h);
  const ladoFora = faixaJogador === 0 ? -1 : faixaJogador === 2 ? 1 : (Math.random() < .5 ? -1 : 1);
  if (alvo) {
    alvo.visible = true;
    alvo.userData.arremessado = true;
    arremessos.push({
      obj: alvo, t: 0, dur: 1.6,
      vel: new THREE.Vector3(f.x * 13 + r.x * ladoFora * 7, 5.5, f.z * 13 + r.z * ladoFora * 7),
      giro: (2.5 + Math.random() * 2) * (Math.random() < .5 ? -1 : 1),
      rolo: ladoFora * (1.2 + Math.random()),
    });
  }
  const ponto = new THREE.Vector3(q.x + r.x * (faixaJogador - 1) * LARGURA_FAIXA - f.x * 2.2, 0.5, q.z + r.z * (faixaJogador - 1) * LARGURA_FAIXA - f.z * 2.2);
  soltarFaiscas(ponto, f);
  tocarBatida();
}
function animarArremessos(dt) {
  for (const a of arremessos) {
    a.t += dt;
    const o = a.obj;
    o.position.addScaledVector(a.vel, dt);
    a.vel.y -= 14 * dt;
    if (o.position.y < 0) { o.position.y = 0; a.vel.y = Math.abs(a.vel.y) * .35; a.vel.x *= .8; a.vel.z *= .8; }
    o.rotation.y += a.giro * dt;
    o.rotation.z += a.rolo * dt * (1 - a.t / a.dur);
    if (a.t >= a.dur) { o.visible = false; o.userData.sumiu = true; }
  }
  arremessos = arremessos.filter((a) => a.t < a.dur);
}
function soltarFaiscas(ponto, f, cor = 0xffb347, n = 46) {
  const pos = new Float32Array(n * 3);
  const vel = [];
  for (let i = 0; i < n; i++) {
    pos.set([ponto.x, ponto.y, ponto.z], i * 3);
    vel.push(new THREE.Vector3((Math.random() - .5) * 9 - f.x * 4, 2 + Math.random() * 6, (Math.random() - .5) * 9 - f.z * 4));
  }
  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  const mat = new THREE.PointsMaterial({ color: cor, size: 0.07, transparent: true, opacity: 1, depthWrite: false });
  const pts = new THREE.Points(geo, mat);
  scene.add(pts);
  faiscas.push({ pts, vel, t: 0, dur: .75 });
}
function animarFaiscas(dt) {
  for (const fx of faiscas) {
    fx.t += dt;
    const arr = fx.pts.geometry.attributes.position.array;
    for (let i = 0; i < fx.vel.length; i++) {
      const v = fx.vel[i];
      v.y -= 22 * dt;
      arr[i * 3] += v.x * dt; arr[i * 3 + 1] += v.y * dt; arr[i * 3 + 2] += v.z * dt;
      if (arr[i * 3 + 1] < 0.02) { arr[i * 3 + 1] = 0.02; v.y = Math.abs(v.y) * .3; }
    }
    fx.pts.geometry.attributes.position.needsUpdate = true;
    fx.pts.material.opacity = 1 - fx.t / fx.dur;
    if (fx.t >= fx.dur) { scene.remove(fx.pts); fx.pts.geometry.dispose(); fx.pts.material.dispose(); }
  }
  faiscas = faiscas.filter((f) => f.t < f.dur);
}

function atualizarPlacas() {
  if (!estado || !estado.portais) return;
  for (let j = 0; j < estado.portais.length; j++) {
    const flags = estado.portais[j];
    if (!flags) continue;
    // `k` = posição no array (o Dart manda só uma janela de portais)
    const k = flags.k != null ? flags.k : j;
    const port = portais[k];
    if (!port) continue;
    // carros de tráfego: seguem a posição do motor; batido → arremesso
    if (flags.carros) {
      for (let i = 0; i < flags.carros.length; i++) {
        const fc = flags.carros[i];
        const o = obstaculos.find((ob) => ob.userData.portalK === k && ob.userData.carroI === i);
        if (!o) continue;
        if (fc.batido && !o.userData.arremessado) {
          bater(port, o.userData.faixa, fc.z);
          continue;
        }
        if (o.userData.arremessado) continue;
        const q = pose(fc.z);
        const r = direita(q.h);
        const lat = (o.userData.faixa - 1) * LARGURA_FAIXA;
        o.position.set(q.x + r.x * lat, 0, q.z + r.z * lat);
        o.rotation.y = -q.h;
        o.userData.z = fc.z;
      }
    }
    // fichas coletadas somem com um brilho
    if (flags.fichas && port.fichas) {
      for (let i = 0; i < flags.fichas.length; i++) {
        const fx = port.fichas[i];
        if (fx && flags.fichas[i] && !fx.userData.pega) coletarFicha(fx);
      }
    }
    for (const placa of port.placas) {
      let estilo, texto = placa.texto;
      if (placa.i < 0) estilo = flags.batido ? 'batida' : 'bloqueada';
      else if (flags.digitado === placa.i) { estilo = 'digitada'; texto = '✓'; }
      else if (flags.travada === placa.i) estilo = 'travada';
      else estilo = 'livre';
      if (estilo !== placa.estiloAtual) {
        placa.estiloAtual = estilo;
        pintarPlaca(placa.ctx, placa.canvas.width, placa.canvas.height, texto, estilo);
        placa.tex.needsUpdate = true;
      }
    }
  }
}

// ---------- modelos ----------
async function carregarCarro(id) {
  if (modelosCache[id]) return modelosCache[id];
  const c = CARROS[id];
  const gltf = await gltfLoader.loadAsync(c.arquivo);
  const raiz = gltf.scene;
  raiz.updateMatrixWorld(true);
  // modelos do Sketchfab às vezes trazem um plano de chão/sombra enorme e
  // achatado: esconde o que é plano E muito maior que as peças do carro
  const malhas = [];
  raiz.traverse((o) => { if (o.isMesh) malhas.push(o); });
  const medidas = malhas.map((o) => {
    const b = new THREE.Box3().setFromObject(o);
    const t = b.getSize(new THREE.Vector3());
    return { o, b, maior: Math.max(t.x, t.y, t.z), menor: Math.min(t.x, t.y, t.z), nome: o.name || '' };
  });
  const ordenado = medidas.map((m) => m.maior).sort((a, b) => a - b);
  const mediana = ordenado[Math.floor(ordenado.length / 2)] || 1;
  for (const m of medidas) {
    const nome = (m.nome + ' ' + (m.o.material && m.o.material.name || '')).toLowerCase();
    const achatado = m.menor < m.maior * 0.03;
    const gigante = m.maior > mediana * 2.2;
    if ((achatado && gigante) || /shadow|sombra|floor|ground|plane_material/.test(nome)) {
      m.o.visible = false;
    }
  }
  // normaliza: comprimento em metros, frente pra −z, chão em y=0
  const caixa = new THREE.Box3();
  for (const m of medidas) if (m.o.visible) caixa.union(m.b);
  const tam = caixa.getSize(new THREE.Vector3());
  const maior = Math.max(tam.x, tam.z);
  const escala = c.comprimento / maior;
  const envolt = new THREE.Group();
  raiz.scale.setScalar(escala);
  if (tam.x > tam.z) raiz.rotation.y = Math.PI / 2; // eixo comprido em x → alinha com z
  raiz.rotation.y += c.giro;
  envolt.add(raiz);
  envolt.updateMatrixWorld(true);
  const caixa2 = new THREE.Box3();
  envolt.traverse((o) => { if (o.isMesh && o.visible) caixa2.union(new THREE.Box3().setFromObject(o)); });
  const centro2 = caixa2.getCenter(new THREE.Vector3());
  raiz.position.set(-centro2.x, -caixa2.min.y, -centro2.z);
  envolt.userData.caixa = caixa2.getSize(new THREE.Vector3()).toArray().map((v) => +v.toFixed(2));
  console.info('[turismo3d] carro', id, 'caixa', envolt.userData.caixa, 'escala', +escala.toFixed(4), 'malhas ocultas', medidas.filter((m) => !m.o.visible).length);
  envolt.traverse((o) => {
    if (o.isMesh) {
      o.castShadow = true;
      o.receiveShadow = true;
      if (o.material && o.material.map) o.material.map.anisotropy = 8;
    }
  });
  fundirPorMaterial(envolt);
  modelosCache[id] = envolt;
  return envolt;
}
// Modelos do Sketchfab vêm em dezenas de malhas que compartilham material:
// funde por material (só position/normal/uv, sem índice) e esconde as
// originais — cada carro de tráfego custa a metade dos draw calls.
function fundirNaoIndexadas(geos) {
  let nv = 0;
  for (const g of geos) nv += g.attributes.position.count;
  const pos = new Float32Array(nv * 3), nor = new Float32Array(nv * 3), uv = new Float32Array(nv * 2);
  let ov = 0;
  for (const g of geos) {
    pos.set(g.attributes.position.array, ov * 3);
    nor.set(g.attributes.normal.array, ov * 3);
    uv.set(g.attributes.uv.array, ov * 2);
    ov += g.attributes.position.count;
  }
  const out = new THREE.BufferGeometry();
  out.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  out.setAttribute('normal', new THREE.BufferAttribute(nor, 3));
  out.setAttribute('uv', new THREE.BufferAttribute(uv, 2));
  return out;
}
function fundirPorMaterial(envolt) {
  envolt.updateMatrixWorld(true);
  const grupos = new Map();
  const originais = [];
  envolt.traverse((o) => {
    if (!o.isMesh || !o.visible || o.isSkinnedMesh || Array.isArray(o.material)) return;
    if (o.geometry.morphAttributes && Object.keys(o.geometry.morphAttributes).length) return;
    let g = o.geometry.clone();
    if (g.index) g = g.toNonIndexed();
    if (!g.attributes.normal) g.computeVertexNormals();
    if (!g.attributes.uv) g.setAttribute('uv', new THREE.BufferAttribute(new Float32Array(g.attributes.position.count * 2), 2));
    for (const nome of Object.keys(g.attributes)) if (!['position', 'normal', 'uv'].includes(nome)) g.deleteAttribute(nome);
    g.applyMatrix4(o.matrixWorld);
    const chave = o.material.uuid;
    if (!grupos.has(chave)) grupos.set(chave, { material: o.material, geos: [] });
    grupos.get(chave).geos.push(g);
    originais.push(o);
  });
  if (originais.length <= grupos.size) return; // nada a ganhar
  for (const o of originais) o.visible = false;
  for (const { material, geos } of grupos.values()) {
    material.vertexColors = false;
    const m = new THREE.Mesh(fundirNaoIndexadas(geos), material);
    m.castShadow = true;
    m.receiveShadow = true;
    envolt.add(m);
  }
  console.info('[turismo3d] carro fundido:', originais.length, 'malhas →', grupos.size);
}

async function construirObstaculos() {
  obstaculos = [];
  const ids = (cfg.trafego || []).filter((id) => CARROS[id]);
  const modelos = [];
  for (const id of ids) {
    try { modelos.push(await carregarCarro(id)); } catch (e) { console.warn('trafego', id, e); }
  }
  if (!modelos.length) return;
  let k = 0;
  for (const p of cfg.portais) {
    for (let faixa = 0; faixa < 3; faixa++) {
      if (p.faixas.includes(faixa)) continue;
      const modelo = modelos[k++ % modelos.length].clone();
      // carro de tráfego: começa parado no pórtico e ANDA na faixa dele —
      // a posição real vem do motor em Dart a cada frame
      const q = pose(p.z + 2.6);
      const r = direita(q.h);
      const lat = (faixa - 1) * LARGURA_FAIXA;
      modelo.position.set(q.x + r.x * lat, 0, q.z + r.z * lat);
      modelo.rotation.y = -q.h;
      modelo.userData.z = p.z;
      modelo.userData.faixa = faixa;
      modelo.userData.portal = p.indice;
      modelo.userData.portalK = cfg.portais.indexOf(p);
      modelo.userData.carroI = p.carros ? p.carros.findIndex((c) => c.faixa === faixa) : -1;
      modelo.visible = false;
      scene.add(modelo);
      obstaculos.push(modelo);
    }
  }
}

// Postes de luz (cidade): o modelo é clonado ao longo da pista, mas só um
// PUNHADO de luzes reais existe — elas pulam pros postes mais próximos do
// carro a cada frame (dezenas de PointLights travariam a GPU).
// ---------- cidade construída ----------
// Prédios dos dois lados da pista seguindo as curvas, com FACHADAS
// FOTOGRÁFICAS PBR (ambientCG, CC0: cor + normal + rugosidade + janelas
// acesas no mapa de emissão). Cada prédio vira 4 paredes com UV em METROS
// (tile = tamanho real da foto) e tudo de uma mesma fachada é fundido numa
// geometria só: 5 fachadas + telhados = 6 draw calls pra cidade inteira.
const FACHADAS = [
  { id: 'facade002', tile: 24, alta: false },
  { id: 'facade004', tile: 24, alta: false },
  { id: 'facade018a', tile: 16, alta: false },
  { id: 'facade008', tile: 64, alta: true },
  { id: 'facade011', tile: 48, alta: true },
];
let predios = [], nPredios = 0;
function materialFachada(f, noturno) {
  const base = `assets3d/fachadas/${qualidadeAlta ? '1k' : '512'}/${f.id}/`;
  const m = new THREE.MeshStandardMaterial({
    map: textura(base + 'color.jpg', { srgb: true }),
    normalMap: textura(base + 'nor.jpg'),
    roughnessMap: textura(base + 'rough.jpg'),
    emissive: 0xffffff,
    emissiveMap: textura(base + 'emis.jpg', { srgb: true }),
    emissiveIntensity: noturno ? 1.6 : 0.12,
    roughness: 1,
    metalness: 0.05,
    color: 0x6a6f78, // até a foto chegar
  });
  m.map.onUpdate = () => { m.color.set(0xffffff); };
  return m;
}
// parede: um plano com UV em metros (tile = tamanho real da foto) e um
// deslocamento por prédio, pra dois vizinhos não acenderem as mesmas janelas
function parede(w, h, tile, offU, offV) {
  const g = new THREE.PlaneGeometry(w, h);
  const uv = g.attributes.uv;
  for (let i = 0; i < uv.count; i++) uv.setXY(i, uv.getX(i) * (w / tile) + offU, uv.getY(i) * (h / tile) + offV);
  return g;
}
// funde geometrias indexadas (position/normal/uv) numa só
function fundir(geos) {
  let nv = 0, ni = 0;
  for (const g of geos) { nv += g.attributes.position.count; ni += g.index.count; }
  const pos = new Float32Array(nv * 3), nor = new Float32Array(nv * 3), uv = new Float32Array(nv * 2), idx = new Uint32Array(ni);
  let ov = 0, oi = 0;
  for (const g of geos) {
    pos.set(g.attributes.position.array, ov * 3);
    nor.set(g.attributes.normal.array, ov * 3);
    uv.set(g.attributes.uv.array, ov * 2);
    const ia = g.index.array;
    for (let k = 0; k < ia.length; k++) idx[oi + k] = ia[k] + ov;
    ov += g.attributes.position.count;
    oi += ia.length;
  }
  const out = new THREE.BufferGeometry();
  out.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  out.setAttribute('normal', new THREE.BufferAttribute(nor, 3));
  out.setAttribute('uv', new THREE.BufferAttribute(uv, 2));
  out.setIndex(new THREE.BufferAttribute(idx, 1));
  return out;
}
function construirCidade() {
  const noturno = cfg.tema.noturno;
  let s = 7;
  const rnd = () => { s = (s * 48271) % 2147483647; return s / 2147483647; };
  const total = centro.length * L;
  const porFachada = FACHADAS.map(() => []);
  const telhados = [];
  nPredios = 0;
  for (let d = 30; d < total - 40; d += 26) {
    for (const lado of [-1, 1]) {
      if (rnd() < 0.12) continue; // um terreno vazio de vez em quando
      const fi = Math.floor(rnd() * FACHADAS.length);
      const f = FACHADAS[fi];
      const larg = 14 + rnd() * 12, prof = 14 + rnd() * 10;
      const r1 = rnd();
      // as fotos de arranha-céu (tile grande) viram torres; as outras, prédios médios
      const alt = f.alta ? 40 + rnd() * 42 : (r1 < .5 ? 12 + rnd() * 10 : 22 + rnd() * 28);
      const q = pose(d + rnd() * 6), r = direita(q.h);
      const afast = MEIA_PISTA + 9 + prof / 2 + rnd() * 4;
      const M = new THREE.Matrix4().makeRotationY(-q.h);
      M.setPosition(q.x + r.x * afast * lado, 0, q.z + r.z * afast * lado);
      const offU = Math.floor(rnd() * 8), offV = Math.floor(rnd() * 4);
      const paredes = [
        parede(larg, alt, f.tile, offU, offV).translate(0, alt / 2, prof / 2),
        parede(larg, alt, f.tile, offU + 3, offV).rotateY(Math.PI).translate(0, alt / 2, -prof / 2),
        parede(prof, alt, f.tile, offU + 5, offV).rotateY(Math.PI / 2).translate(larg / 2, alt / 2, 0),
        parede(prof, alt, f.tile, offU + 7, offV).rotateY(-Math.PI / 2).translate(-larg / 2, alt / 2, 0),
      ];
      for (const pg of paredes) porFachada[fi].push(pg.applyMatrix4(M));
      telhados.push(new THREE.PlaneGeometry(larg, prof).rotateX(-Math.PI / 2).translate(0, alt, 0).applyMatrix4(M));
      nPredios++;
    }
  }
  FACHADAS.forEach((f, i) => {
    if (!porFachada[i].length) return;
    const mesh = new THREE.Mesh(fundir(porFachada[i]), materialFachada(f, noturno));
    mesh.receiveShadow = true;
    scene.add(mesh);
    predios.push(mesh);
  });
  if (telhados.length) {
    const telhado = new THREE.Mesh(fundir(telhados), new THREE.MeshStandardMaterial({ color: 0x23262c, roughness: .95 }));
    scene.add(telhado);
    predios.push(telhado);
  }
  // calçadas de concreto dos dois lados, entre o guard-rail e os prédios
  const concreto = new THREE.MeshStandardMaterial({ color: 0x8d8d8d, roughness: .95 });
  for (const lado of [-1, 1]) {
    const a = lado * (MEIA_PISTA + 2.6), b = lado * (MEIA_PISTA + 8.5);
    const calcada = new THREE.Mesh(faixaGeometria(Math.min(a, b), Math.max(a, b), 0.14, 0.14, 4), concreto);
    calcada.receiveShadow = true;
    scene.add(calcada);
  }
  console.info('[turismo3d] cidade:', nPredios, 'prédios em', predios.length, 'draw calls');
}

// ---------- cenário por tema (modelos reais, CC0 do Poly Haven) ----------
// Arbustos, rochas, tocos e árvores instanciados ao longo da pista. Cada
// modelo é normalizado pelo maior lado e sorteado dentro de `tam` (metros);
// as instâncias são agrupadas por trecho de 320 m pra o frustum culling
// descartar o que está longe (senão um InstancedMesh da pista inteira
// desenha tudo, sempre).
const CENARIO_MODELOS = {
  shrub_03: { tam: [1.0, 1.9] }, shrub_04: { tam: [1.0, 1.9] }, rock_moss_set_01: { tam: [1.2, 2.6] }, tree_stump_01: { tam: [0.9, 1.4] },
  namaqualand_boulder_04: { tam: [2.0, 5.0] }, rock_09: { tam: [1.2, 3.0] }, quiver_tree_02: { tam: [3.5, 6.5] },
  boulder_01: { tam: [2.0, 4.5] }, dead_tree_trunk: { tam: [3.0, 6.0] },
  moon_rock_01: { tam: [1.0, 3.5] }, moon_rock_03: { tam: [1.0, 3.5] }, moon_rock_05: { tam: [1.5, 4.5] },
};
let cenarioMalhas = [], nCenario = 0;
async function construirCenario() {
  const cen = cfg.tema.cenario;
  if (!cen || !gltfLoader || !perfilAtual.cenario) return;
  const total = centro.length * L;
  let s = 99;
  const rnd = () => { s = (s * 48271) % 2147483647; return s / 2147483647; };
  const lotes = cen.modelos.map(() => []);
  const somaPesos = cen.pesos.reduce((a, b) => a + b, 0);
  for (let d = 20; d < total - 30; d += cen.passo * (0.6 + rnd() * 0.8)) {
    for (const lado of [-1, 1]) {
      if (rnd() < 0.3) continue;
      let r = rnd() * somaPesos, i = 0;
      while (i < cen.pesos.length - 1 && r > cen.pesos[i]) { r -= cen.pesos[i]; i++; }
      const perto = rnd() < 0.55; // mais da metade fica na beira da pista
      lotes[i].push({ d, lado, afast: MEIA_PISTA + 4.5 + rnd() * (perto ? 9 : 34), giro: rnd() * Math.PI * 2, t: rnd() });
    }
  }
  nCenario = lotes.reduce((n, l) => n + l.length, 0);
  const CHUNK = TRECHO;
  for (let i = 0; i < cen.modelos.length; i++) {
    const nome = cen.modelos[i];
    const info = CENARIO_MODELOS[nome] || { tam: [1, 2] };
    let gltf;
    try {
      gltf = await new Promise((res, rej) => gltfLoader.load(`assets3d/modelos/${nome}/${nome}.gltf`, res, undefined, rej));
    } catch (e) { console.warn('[turismo3d] cenário', nome, e); continue; }
    const raiz = gltf.scene;
    raiz.updateMatrixWorld(true);
    const caixa = new THREE.Box3().setFromObject(raiz);
    const maior = Math.max(caixa.max.x - caixa.min.x, caixa.max.y - caixa.min.y, caixa.max.z - caixa.min.z) || 1;
    const baseY = caixa.min.y;
    const malhas = [];
    raiz.traverse((o) => { if (o.isMesh) malhas.push(o); });
    // por trecho de 160 m e em duas metades (A/B): o nível leve mostra só a A
    const porChunk = new Map();
    lotes[i].forEach((l, idx) => {
      const c = Math.floor(l.d / CHUNK), metade = idx % 2;
      const chave = c * 2 + metade;
      if (!porChunk.has(chave)) porChunk.set(chave, { c, metade, lista: [] });
      porChunk.get(chave).lista.push(l);
    });
    for (const { c, metade, lista } of porChunk.values()) {
      for (const m of malhas) {
        const inst = new THREE.InstancedMesh(m.geometry, m.material, lista.length);
        inst.userData.d = (c + 0.5) * CHUNK;
        inst.userData.metade = metade;
        const mat = new THREE.Matrix4();
        const posV = new THREE.Vector3(), quat = new THREE.Quaternion(), escV = new THREE.Vector3();
        lista.forEach((l, k) => {
          const q = pose(l.d), r = direita(q.h);
          const esc = (info.tam[0] + (info.tam[1] - info.tam[0]) * l.t) / maior;
          posV.set(q.x + r.x * l.afast * l.lado, -baseY * esc, q.z + r.z * l.afast * l.lado);
          quat.setFromEuler(new THREE.Euler(0, l.giro, 0));
          escV.set(esc, esc, esc);
          mat.compose(posV, quat, escV);
          mat.multiply(m.matrixWorld);
          inst.setMatrixAt(k, mat);
        });
        inst.instanceMatrix.needsUpdate = true;
        inst.castShadow = nivelQualidade === 'alta';
        inst.receiveShadow = true;
        inst.visible = false;
        if (inst.computeBoundingSphere) inst.computeBoundingSphere();
        scene.add(inst);
        cenarioMalhas.push(inst);
      }
    }
  }
  console.info('[turismo3d] cenário:', nCenario, 'peças em', cenarioMalhas.length, 'lotes');
}

let postesLuz = [];
let luzesPool = [];
function construirLampadas() {
  const tema = cfg.tema;
  if (!tema.lampadas) return;
  for (let i = 0; i < 5; i++) {
    const luz = new THREE.PointLight(0xffe0a0, 18, 24, 2);
    luz.visible = false;
    scene.add(luz);
    luzesPool.push(luz);
  }
  const montarPostes = (base) => {
    base.updateMatrixWorld(true);
    const malhas = [];
    base.traverse((o) => { if (o.isMesh) malhas.push(o); });
    const n = Math.floor(cfg.distancia / 60);
    const lotes = [];
    for (let k = 0; k < n; k++) {
      const d = 30 + k * 60;
      const q = pose(d);
      const lado = k % 2 ? 1 : -1;
      const r = direita(q.h);
      const lat = lado * (MEIA_PISTA + 3.2);
      const bulboPos = new THREE.Vector3(q.x + r.x * (lat - lado * 1.4), 4.6, q.z + r.z * (lat - lado * 1.4));
      lotes.push({ d, pos: new THREE.Vector3(q.x + r.x * lat, 0, q.z + r.z * lat), rot: -q.h + (lado > 0 ? Math.PI : 0), bulboPos });
      postesLuz.push({ d, pos: bulboPos.clone() });
    }
    // postes: um InstancedMesh por malha do modelo e por trecho de 160 m
    // (o modelo tem 30k triângulos — 93 clones era meio milhão por frame)
    const porTrecho = new Map();
    for (const l of lotes) { const c = Math.floor(l.d / TRECHO); if (!porTrecho.has(c)) porTrecho.set(c, []); porTrecho.get(c).push(l); }
    const mat4 = new THREE.Matrix4(), quat = new THREE.Quaternion(), um = new THREE.Vector3(1, 1, 1);
    for (const [c, lista] of porTrecho) {
      for (const m of malhas) {
        const inst = new THREE.InstancedMesh(m.geometry, m.material, lista.length);
        lista.forEach((l, k) => {
          quat.setFromEuler(new THREE.Euler(0, l.rot, 0));
          mat4.compose(l.pos, quat, um);
          mat4.multiply(m.matrixWorld);
          inst.setMatrixAt(k, mat4);
        });
        inst.instanceMatrix.needsUpdate = true;
        inst.userData.d = (c + 0.5) * TRECHO;
        inst.userData.metade = 0;
        inst.visible = false;
        if (inst.computeBoundingSphere) inst.computeBoundingSphere();
        scene.add(inst);
        lampadasMalhas.push(inst);
      }
    }
    // bulbos emissivos (brilham mesmo sem luz real): um InstancedMesh só
    const bulbos = new THREE.InstancedMesh(new THREE.SphereGeometry(0.18, 10, 8), new THREE.MeshBasicMaterial({ color: 0xfff1c0 }), lotes.length);
    lotes.forEach((l, k) => { mat4.makeTranslation(l.bulboPos.x, l.bulboPos.y, l.bulboPos.z); bulbos.setMatrixAt(k, mat4); });
    bulbos.instanceMatrix.needsUpdate = true;
    if (bulbos.computeBoundingSphere) bulbos.computeBoundingSphere();
    scene.add(bulbos);
  };
  if (nivelQualidade === 'alta') {
    gltfLoader.load('assets3d/modelos/street_lamp_01/street_lamp_01.gltf', (gltf) => {
      const base = gltf.scene;
      base.traverse((o) => { if (o.isMesh) { o.castShadow = false; if (o.material && o.material.emissive) o.material = o.material.clone(); } });
      montarPostes(base);
    }, undefined, (e) => console.warn('lampadas', e));
  } else {
    // poste procedural de ~150 triângulos (o modelo do Poly Haven tem 30k)
    const base = new THREE.Group();
    const metal = new THREE.MeshStandardMaterial({ color: 0x555b63, roughness: .6, metalness: .6 });
    const haste = new THREE.Mesh(new THREE.CylinderGeometry(0.07, 0.11, 6.0, 8), metal);
    haste.position.y = 3.0;
    const braco = new THREE.Mesh(new THREE.BoxGeometry(1.5, 0.08, 0.08), metal);
    braco.position.set(-0.7, 5.9, 0);
    const cabeca = new THREE.Mesh(new THREE.BoxGeometry(0.5, 0.14, 0.26), metal);
    cabeca.position.set(-1.4, 5.85, 0);
    base.add(haste, braco, cabeca);
    montarPostes(base);
  }
}
function atualizarLuzes(posicao) {
  if (!luzesPool.length || !postesLuz.length || !perfilAtual.luzes) return;
  // os 5 postes mais próximos à frente/atrás do carro ganham luz de verdade
  const perto = postesLuz.filter((p) => p.d > posicao - 40 && p.d < posicao + 160).slice(0, luzesPool.length);
  luzesPool.forEach((luz, i) => {
    const p = perto[i];
    luz.visible = !!p;
    if (p) luz.position.copy(p.pos);
  });
}

// ---------- ambiente ----------
function carregarCeu(tema) {
  return new Promise((resolve) => {
    new RGBELoader(gerente).load(`assets3d/hdri/${tema.hdri}${qualidadeAlta ? '_2k' : ''}.hdr`, (tex) => {
      tex.mapping = THREE.EquirectangularReflectionMapping;
      scene.background = tex;
      scene.environment = tex;
      scene.backgroundBlurriness = 0.0;
      scene.environmentIntensity = tema.noturno ? 0.6 : 1.0;
      resolve();
    }, undefined, (e) => { console.warn('hdri', e); resolve(); });
  });
}

// ---------- API ----------
async function montar(canvas, config) {
  destruir();
  cfg = { ...config };
  cfg.tema = TEMAS[config.tema] || TEMAS[1];
  L = config.comprimentoSegmento || 8;
  api.pronto = false;
  api.erro = null;
  api.progresso = 0.05;
  const gpu = sondarGpu();
  api.gpu = gpu.nome;
  api.aviso = gpu.software ? 'software' : null;
  const pref = config.qualidade || 'auto';
  api.benchMs = null;
  if (pref === 'alta') nivelQualidade = 'alta';
  else if (pref === 'leve') nivelQualidade = 'leve';
  else if (gpu.software) nivelQualidade = 'minima';
  else {
    const ms = await benchmarkGpu(true);
    api.benchMs = +ms.toFixed(1);
    nivelQualidade = ms > 34 ? 'minima' : (ms > 19 || gpu.fraca || !resolverQualidade('auto')) ? 'leve' : 'alta';
    console.info('[turismo3d] benchmark', api.benchMs, 'ms →', nivelQualidade);
  }
  qualidadeAlta = nivelQualidade === 'alta';
  perfilAtual = PERFIS[nivelQualidade];
  api.qualidadeEfetiva = nivelQualidade;
  api.frameMs = null;
  vigiaTempos = []; vigiaAte = 0; ultimoQuadroMs = 0;

  renderer = new THREE.WebGLRenderer({ canvas, antialias: nivelQualidade !== 'minima', powerPreference: 'high-performance' });
  renderer.setPixelRatio(nivelQualidade === 'alta' ? Math.min(window.devicePixelRatio, 2) : (nivelQualidade === 'leve' ? Math.min(window.devicePixelRatio, 1.25) : 1));
  renderer.shadowMap.enabled = nivelQualidade !== 'minima';
  renderer.shadowMap.type = THREE.PCFShadowMap;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = cfg.tema.exposicao;

  scene = new THREE.Scene();
  scene.fog = new THREE.FogExp2(cfg.tema.neblina, cfg.tema.densidade);
  camera = new THREE.PerspectiveCamera(62, 1, 0.3, 900);
  relogio = new THREE.Timer ? { getDelta: (() => { const tm = new THREE.Timer(); return () => { tm.update(); return tm.getDelta(); }; })() } : new THREE.Clock();

  sol = new THREE.DirectionalLight(cfg.tema.solCor, cfg.tema.solForca);
  sol.castShadow = true;
  sol.shadow.mapSize.set(qualidadeAlta ? 2048 : 1024, qualidadeAlta ? 2048 : 1024);
  sol.castShadow = nivelQualidade !== 'minima';
  sol.shadow.camera.near = 1; sol.shadow.camera.far = 160;
  sol.shadow.camera.left = -30; sol.shadow.camera.right = 30;
  sol.shadow.camera.top = 40; sol.shadow.camera.bottom = -40;
  sol.shadow.bias = -0.0006;
  scene.add(sol);
  scene.add(sol.target);
  scene.add(new THREE.HemisphereLight(0xffffff, 0x3a3a3a, cfg.tema.noturno ? 0.28 : 0.35));
  // luz de acompanhamento (como a "luz de câmera" dos jogos de corrida):
  // fica atrás/acima do carro e garante que ele nunca some no escuro
  luzCarro = new THREE.PointLight(0xdfe8ff, cfg.tema.noturno ? 26 : 6, 22, 1.6);
  scene.add(luzCarro);

  const draco = new DRACOLoader();
  draco.setDecoderPath('lib3d/addons/libs/draco/gltf/');
  gltfLoader = new GLTFLoader(gerente);
  gltfLoader.setDRACOLoader(draco);

  try {
    construirCentro(config.segmentos);
    construirPista(cfg.tema);
    if (cfg.tema.cidade) construirCidade();
    construirPortais();
    construirLampadas();
  } catch (e) {
    api.erro = 'cena: ' + (e && e.message ? e.message : e);
    console.error('[turismo3d] cena', e);
    throw e;
  }
  construirPainel();
  prepararAudio();
  if (audioCtx && buffers.motor && !motorFonte) ligarMotor(); // corrida nova: motor volta a roncar
  prepararMusica(cfg.musica);
  if (audioCtx) { if (audioCtx.state === 'running') { ligarVento(); tocarMusica(); } }
  console.info('[turismo3d] cena montada:', centro.length, 'pontos,', cfg.portais.length, 'portais');

  // tamanho: o Dart manda a medida do widget em `atualizar` (fonte
  // confiável dentro do platform view); o ResizeObserver é o plano B
  tamanhoCanvas = canvas;
  const ajustar = () => {
    const rect = canvas.getBoundingClientRect();
    redimensionar(rect.width, rect.height);
  };
  ajustar();
  resizeObs = new ResizeObserver(ajustar);
  resizeObs.observe(canvas);

  const q0 = pose(0);
  camPos.set(q0.x, 2.6, q0.z + 7);
  loop();

  api.progresso = 0.2;
  await carregarCeu(cfg.tema);
  api.progresso = 0.45;
  console.info('[turismo3d] céu ok');
  try {
    carro = (await carregarCarro(config.carro || 'porsche_930')).clone();
    console.info('[turismo3d] carro ok');
    // 👻 o fantasma da melhor volta: o mesmo carro, translúcido, sem sombra
    // (clonado ANTES das lanternas e dos faróis — luz clonada é luz a mais)
    if (cfg.fantasma && cfg.fantasma.length >= 4) {
      fantasma = carro.clone();
      fantasma.traverse((o) => {
        if (o.isMesh) {
          o.material = Array.isArray(o.material) ? o.material.map((m) => m.clone()) : o.material.clone();
          for (const m of (Array.isArray(o.material) ? o.material : [o.material])) {
            // holograma azulado: some a textura, brilha por conta própria
            m.transparent = true; m.opacity = 0.55; m.depthWrite = false;
            m.map = null; m.metalness = 0; m.roughness = 1;
            m.color.set(0x8fb6ff);
            if (m.emissive) m.emissive.set(0x3b7cff);
            m.emissiveMap = null;
            m.emissiveIntensity = 0.9;
            m.needsUpdate = true;
          }
          o.castShadow = false; o.receiveShadow = false;
        }
      });
      fantasma.visible = false;
      scene.add(fantasma);
    }
    // lanternas traseiras e faróis dianteiros emissivos: o carro é visto de
    // longe mesmo no escuro
    const caixa = carro.userData.caixa || [1.8, 1.3, 4.3];
    const lampMat = (cor) => new THREE.MeshBasicMaterial({ color: cor });
    for (const lado of [-1, 1]) {
      // na altura das lanternas de verdade, meio embutidas na carroceria
      const lanterna = new THREE.Mesh(new THREE.BoxGeometry(0.22, 0.07, 0.03), lampMat(0xff2a2a));
      lanterna.position.set(lado * caixa[0] * 0.30, caixa[1] * 0.52, caixa[2] * 0.5 - 0.05);
      carro.add(lanterna);
      const farol = new THREE.Mesh(new THREE.BoxGeometry(0.2, 0.1, 0.03), lampMat(0xfff6d5));
      farol.position.set(lado * caixa[0] * 0.32, caixa[1] * 0.5, -caixa[2] * 0.5 + 0.05);
      carro.add(farol);
    }
    scene.add(carro);
    if (cfg.tema.noturno) {
      for (const lado of [-1, 1]) {
        const farol = new THREE.SpotLight(0xfff2cc, 40, 70, 0.42, 0.55, 1.4);
        farol.position.set(lado * 0.72, 0.72, -1.9);
        const alvo = new THREE.Object3D();
        alvo.position.set(lado * 1.2, 0.2, -30);
        carro.add(alvo);
        farol.target = alvo;
        carro.add(farol);
        faroisLuz.push(farol);
      }
    }
    api.progresso = 0.62;
    await construirCenario();
    api.progresso = 0.72;
  } catch (e) {
    console.error('carro', e);
    api.erro = String(e);
  }
  // TUDO que a corrida usa entra ANTES da largada: tráfego, texturas,
  // shaders compilados e uma medição de desempenho — senão os primeiros
  // segundos engasgam enquanto o resto chega (pior no Windows/ANGLE)
  try { await construirObstaculos(); } catch (e) { console.warn('[turismo3d] tráfego', e); }
  api.progresso = 0.82;
  await esperarCarregamento(30000);
  await Promise.race([carregarAmostras(), new Promise((r) => setTimeout(r, 8000))]);
  api.progresso = 0.9;
  await aquecer();
  api.progresso = 0.96;
  await medirDesempenho();
  api.progresso = 1;
  api.pronto = true;
}

// ---------- painéis das palavras no cenário ----------
// Cada palavra flutua SOBRE A FAIXA pra onde ela leva (esquerda, meio ou
// direita), uns metros à frente do carro: quem lê já sabe pra que lado vai.
// Com duas saídas há dois painéis; combustível fica na faixa atual.
let paineis = [];
function construirPainel() {
  paineis = [];
  for (let k = 0; k < 2; k++) {
    // 768×240 físicos pintados em coordenadas lógicas de 1024×320: 44% menos
    // bytes por upload a cada tecla digitada
    const ct = canvasTex(768, 240, (ctx, w, h) => ctx.clearRect(0, 0, w, h));
    const mat = new THREE.MeshBasicMaterial({ map: ct.tex, transparent: true, depthTest: false, depthWrite: false });
    const mesh = new THREE.Mesh(new THREE.PlaneGeometry(4.4, 1.375), mat);
    mesh.renderOrder = 999;
    mesh.visible = false;
    scene.add(mesh);
    paineis.push({ mesh, ctx: ct.ctx, tex: ct.tex, chave: '' });
  }
}
function pintarPainel(painel, pal) {
  const palavra = pal.texto || '';
  const n = pal.digitadas || 0;
  const rotulo = pal.rotulo || '';
  const chave = palavra + '|' + n + '|' + rotulo + '|' + (pal.tipo || '') + '|' + (pal.ativa ? 1 : 0);
  if (chave === painel.chave) return;
  painel.chave = chave;
  const ctx = painel.ctx, w = 1024, h = 320;
  ctx.setTransform(0.75, 0, 0, 0.75, 0, 0);
  ctx.clearRect(0, 0, w, h);
  if (!palavra) { painel.tex.needsUpdate = true; return; }
  const gas = pal.tipo === 'gas';
  ctx.globalAlpha = pal.ativa === false ? 0.45 : 1;
  ctx.fillStyle = 'rgba(8,10,16,0.66)';
  ctx.beginPath(); ctx.roundRect(8, 8, w - 16, h - 16, 40); ctx.fill();
  ctx.lineWidth = 7; ctx.strokeStyle = gas ? 'rgba(87,199,101,0.95)' : 'rgba(255,199,59,0.95)'; ctx.stroke();
  ctx.font = '800 46px "Inter", "Roboto", sans-serif';
  ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
  ctx.fillStyle = gas ? '#57c765' : '#ffc73b';
  if (pal.tipo === 'seta') {
    // modo setas: a direção é o que importa; a palavra fica como legenda
    ctx.font = '900 190px "Inter", "Roboto", sans-serif';
    ctx.fillText(rotulo.split(' ')[0], w / 2, 150);
    ctx.font = '700 54px "JetBrains Mono", "Roboto Mono", monospace';
    ctx.fillStyle = '#c9d1d9';
    ctx.fillText(palavra, w / 2, 262);
    ctx.globalAlpha = 1;
    painel.tex.needsUpdate = true;
    return;
  }
  ctx.fillText(rotulo, w / 2, 64);
  let tam = 150;
  ctx.font = `700 ${tam}px "JetBrains Mono", "Roboto Mono", monospace`;
  while (ctx.measureText(palavra).width > w * 0.86 && tam > 60) { tam -= 8; ctx.font = `700 ${tam}px "JetBrains Mono", "Roboto Mono", monospace`; }
  const total = ctx.measureText(palavra).width;
  let x = w / 2 - total / 2;
  const y = 205;
  ctx.textAlign = 'left';
  for (let i = 0; i < palavra.length; i++) {
    const ch = palavra[i];
    const larg = ctx.measureText(ch).width;
    if (i === n) {
      ctx.fillStyle = gas ? 'rgba(87,199,101,0.95)' : 'rgba(255,199,59,0.95)';
      ctx.beginPath(); ctx.roundRect(x - 6, y - tam * 0.62, larg + 12, tam * 1.2, 14); ctx.fill();
      ctx.fillStyle = '#10131a';
    } else {
      ctx.fillStyle = i < n ? (gas ? '#57c765' : '#ffc73b') : '#c9d1d9';
    }
    ctx.fillText(ch, x, y);
    x += larg;
  }
  ctx.globalAlpha = 1;
  painel.tex.needsUpdate = true;
}
function posicionarPaineis(e) {
  if (!paineis.length) return;
  const lista = (e.palavras && e.palavras.length) ? e.palavras : [];
  // na câmera do capô (rente ao chão) as placas ficam mais à frente e mais
  // baixas pra caberem no quadro; no helicóptero, mais altas
  const modo = e.camera || 'perseguicao';
  const aFrente = modo === 'capo' ? 16 : (modo === 'alta' ? 8 : 5);
  const altura = modo === 'capo' ? 1.9 : (modo === 'alta' ? 3.4 : 3.0);
  const q = pose((e.posicao || 0) + aFrente);
  const r = direita(q.h);
  // tamanho CONSTANTE na tela: a placa ocupa ~1/3 da largura da vista, seja
  // qual for a câmera, o FOV ou a proporção da janela (em tela larga e
  // baixa ela ficava minúscula — "muito pequeno de ler")
  const ativos = lista.filter((pal) => pal && pal.texto).length;
  const fracao = ativos > 1 ? 0.31 : 0.36;
  const tanMeio = Math.tan(THREE.MathUtils.degToRad(camera.fov) / 2);
  const ancora = new THREE.Vector3(q.x, altura, q.z);
  const dist = Math.max(3, camera.position.distanceTo(ancora));
  const visW = 2 * dist * tanMeio * (camera.aspect || 1.5);
  const esc = THREE.MathUtils.clamp((visW * fracao) / 4.4, 0.9, 7);
  const larg = 4.4 * esc;
  // duas placas vizinhas grandes demais pra 3,7 m: afasta cada uma pro seu lado
  const faixas = lista.map((pal) => (pal && pal.texto) ? (pal.faixa == null ? 1 : pal.faixa) : null);
  let centroLat = 0, sep = 0;
  if (ativos > 1) {
    const fa = faixas.filter((f) => f !== null);
    centroLat = ((fa[0] - 1) + (fa[1] - 1)) * LARGURA_FAIXA / 2;
    sep = Math.max(Math.abs(fa[0] - fa[1]) * LARGURA_FAIXA, larg + 0.4);
  }
  for (let k = 0; k < paineis.length; k++) {
    const painel = paineis[k];
    const pal = lista[k];
    if (!pal || !pal.texto) { painel.mesh.visible = false; continue; }
    const faixa = pal.faixa == null ? 1 : pal.faixa;
    let lat = (faixa - 1) * LARGURA_FAIXA;
    if (ativos > 1) {
      const outra = faixas.find((f, j) => f !== null && j !== k);
      lat = centroLat + (faixa <= outra ? -1 : 1) * sep / 2;
    }
    painel.mesh.visible = true;
    painel.mesh.scale.setScalar(esc);
    // sobe junto com o tamanho pra base não entrar no asfalto
    painel.mesh.position.set(q.x + r.x * lat, altura + (esc - 1) * 0.8, q.z + r.z * lat);
    painel.mesh.quaternion.copy(camera.quaternion);
    pintarPainel(painel, pal);
  }
}

// ---------- áudio do carro (amostras reais) ----------
// Motor: um loop gravado com o tom (playbackRate) e o volume seguindo a
// velocidade; batida: amostra curta. O AudioContext nasce no 1º gesto.
let audioCtx = null, motorFonte = null, motorGanho = null, motorFiltro = null, buffers = {}, audioPedido = false;
// 🎸 música da fase: um <audio> em STREAMING com loop (o mp3 de 3–5 min
// decodificado em buffer ocupava ~80 MB de RAM por faixa e engasgava a
// máquina); ducking na batida e fade no pause. 🌬️ vento = ruído filtrado.
let musicaEl = null, musicaUrl = null, musicaVol = 0, musicaQuerTocar = false, duckAte = 0;
let ventoFonte = null, ventoGanho = null, ventoFiltro = null;
const VOLUME_MUSICA = 0.6, VOLUME_MUSICA_BATIDA = 0.22;
function prepararMusica(url) {
  if (!url) return;
  if (musicaEl) { try { musicaEl.pause(); musicaEl.src = ''; } catch (e) {} }
  musicaUrl = url;
  musicaEl = new Audio(url);
  musicaEl.loop = true;
  musicaEl.preload = 'auto';
  musicaEl.volume = 0;
  musicaVol = 0;
  musicaQuerTocar = false;
  try { musicaEl.load(); } catch (e) {}
}
function tocarMusica() {
  if (!musicaEl || musicaQuerTocar) return;
  musicaQuerTocar = true;
  const p = musicaEl.play();
  if (p && p.catch) p.catch(() => { musicaQuerTocar = false; });
}
function atualizarMusica(e, dt) {
  if (!musicaEl) return;
  const ligada = e.som !== false && e.musica !== false && !e.pausado && !e.acabou;
  const alvo = !ligada ? 0 : (performance.now() < duckAte ? VOLUME_MUSICA_BATIDA : VOLUME_MUSICA);
  musicaVol += (alvo - musicaVol) * Math.min(1, (dt || 0.016) * (alvo > musicaVol ? 1.6 : 4));
  const v = Math.max(0, Math.min(1, musicaVol));
  if (Math.abs(musicaEl.volume - v) > 0.004) musicaEl.volume = v;
  if (ligada && !musicaQuerTocar && audioCtx && audioCtx.state === 'running') tocarMusica();
}
function ligarVento() {
  if (!audioCtx || ventoFonte) return;
  const sr = audioCtx.sampleRate, buf = audioCtx.createBuffer(1, sr * 2, sr), d = buf.getChannelData(0);
  for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
  ventoFonte = audioCtx.createBufferSource();
  ventoFonte.buffer = buf;
  ventoFonte.loop = true;
  ventoFiltro = audioCtx.createBiquadFilter();
  ventoFiltro.type = 'bandpass';
  ventoFiltro.frequency.value = 420;
  ventoFiltro.Q.value = 0.6;
  ventoGanho = audioCtx.createGain();
  ventoGanho.gain.value = 0;
  ventoFonte.connect(ventoFiltro); ventoFiltro.connect(ventoGanho); ventoGanho.connect(audioCtx.destination);
  ventoFonte.start();
}
function atualizarVento(fracao, e) {
  if (!ventoGanho || !audioCtx) return;
  const t = audioCtx.currentTime;
  const ligado = e.som !== false && !e.pausado && !e.acabou;
  ventoGanho.gain.setTargetAtTime(ligado ? fracao * fracao * 0.08 : 0, t, .2);
  ventoFiltro.frequency.setTargetAtTime(300 + fracao * 1100, t, .3);
}
// As amostras curtas (motor, batida, pneu) são decodificadas na tela de
// carga — o AudioContext pode nascer suspenso e acorda no 1º gesto. Antes,
// tudo era baixado e decodificado no meio da corrida (engasgo garantido).
let amostrasPromessa = null;
function carregarAmostras() {
  if (amostrasPromessa) return amostrasPromessa;
  try { if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)(); } catch (e) { return Promise.resolve(); }
  const lista = Object.entries({ motor: 'assets3d/som/motor.m4a', batida: 'assets3d/som/batida.m4a', derrapagem: 'assets3d/som/derrapagem.m4a' });
  amostrasPromessa = Promise.all(lista.map(([nome, url]) =>
    fetch(url).then((r) => r.arrayBuffer()).then((b) => audioCtx.decodeAudioData(b))
      .then((buf) => { buffers[nome] = buf; })
      .catch((e) => console.warn('[turismo3d] som', nome, e))));
  return amostrasPromessa;
}
function prepararAudio() {
  if (audioPedido) return;
  audioPedido = true;
  const iniciar = () => {
    if (!audioCtx) carregarAmostras();
    if (audioCtx && audioCtx.state === 'suspended') audioCtx.resume();
    if (audioCtx && buffers.motor && !motorFonte) ligarMotor();
    ligarVento();
    tocarMusica();
  };
  for (const ev of ['keydown', 'pointerdown', 'touchstart']) window.addEventListener(ev, iniciar, { passive: true });
}
function ligarMotor() {
  if (!audioCtx || !buffers.motor || motorFonte) return;
  motorFonte = audioCtx.createBufferSource();
  motorFonte.buffer = buffers.motor;
  motorFonte.loop = true;
  motorFiltro = audioCtx.createBiquadFilter();
  motorFiltro.type = 'lowpass';
  motorFiltro.frequency.value = 1200;
  motorGanho = audioCtx.createGain();
  motorGanho.gain.value = 0;
  motorFonte.connect(motorFiltro); motorFiltro.connect(motorGanho); motorGanho.connect(audioCtx.destination);
  motorFonte.start();
}
function atualizarMotorAudio(fracao, e) {
  if (!motorFonte || !audioCtx) return;
  const t = audioCtx.currentTime;
  const ligado = e.som !== false && !e.pausado && !e.acabou;
  // marcha lenta em 0,55×, giro máximo em 1,9×
  motorFonte.playbackRate.setTargetAtTime(0.55 + fracao * 1.35, t, .12);
  motorFiltro.frequency.setTargetAtTime(700 + fracao * 3800, t, .15);
  // motor bem mais baixo que a música (era o contrário)
  motorGanho.gain.setTargetAtTime(ligado ? 0.045 + fracao * 0.10 : 0, t, .1);
}
function tocarBatida() {
  if (!audioCtx || !buffers.batida || (estado && estado.som === false)) return;
  duckAte = performance.now() + 1800;
  const src = audioCtx.createBufferSource();
  src.buffer = buffers.batida;
  const g = audioCtx.createGain();
  g.gain.value = .9;
  src.connect(g); g.connect(audioCtx.destination);
  src.start();
}
// 🛞 um pedaço do loop de pneu cantando a cada troca de faixa (mais alto
// quanto mais rápido); sem áudio ou parado, nada
let ultimaFaixaSom = null;
function tocarDerrapagem(fracao) {
  if (!audioCtx || !buffers.derrapagem || (estado && estado.som === false) || fracao < 0.12) return;
  const src = audioCtx.createBufferSource();
  src.buffer = buffers.derrapagem;
  const g = audioCtx.createGain();
  const t = audioCtx.currentTime;
  g.gain.setValueAtTime(0.05 + fracao * 0.4, t);
  g.gain.setTargetAtTime(0, t + 0.28, 0.08);
  src.connect(g); g.connect(audioCtx.destination);
  const dur = buffers.derrapagem.duration;
  src.start(t, Math.random() * Math.max(0, dur - 0.6), 0.6);
}
function pararAudio() {
  try { if (motorGanho && audioCtx) motorGanho.gain.setTargetAtTime(0, audioCtx.currentTime, .05); } catch (e) {}
  try { if (motorFonte) { const f = motorFonte; setTimeout(() => { try { f.stop(); } catch (e) {} }, 300); } } catch (e) {}
  motorFonte = null; motorGanho = null; motorFiltro = null;
  try { if (musicaEl) { musicaEl.pause(); musicaEl.src = ''; } } catch (e) {}
  musicaEl = null; musicaUrl = null; musicaVol = 0; musicaQuerTocar = false;
  try { if (ventoGanho && audioCtx) ventoGanho.gain.setTargetAtTime(0, audioCtx.currentTime, .05); } catch (e) {}
  try { if (ventoFonte) { const f = ventoFonte; setTimeout(() => { try { f.stop(); } catch (e) {} }, 300); } } catch (e) {}
  ventoFonte = null; ventoGanho = null; ventoFiltro = null;
}

let tamanhoCanvas = null, ultimoW = 0, ultimoH = 0;
function redimensionar(w, h) {
  w = Math.round(w); h = Math.round(h);
  if (!renderer || w < 32 || h < 32 || (w === ultimoW && h === ultimoH)) return;
  ultimoW = w; ultimoH = h;
  renderer.setSize(w, h, false);
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
}

function atualizar(novo) {
  estado = novo;
  if (novo && novo.largura && novo.altura) redimensionar(novo.largura, novo.altura);
}

function loop() {
  animId = requestAnimationFrame(loop);
  try {
    quadro();
  } catch (e) {
    api.erro = 'loop: ' + (e && e.message ? e.message : e);
    console.error('[turismo3d] loop', e);
    cancelAnimationFrame(animId);
    animId = 0;
  }
}

// ---------- câmeras ----------
// perseguicao: atrás do carro, com atraso suave (a padrão)
// capo: no para-choque, rente ao chão — a mais rápida
// cinema: câmera de TV parada na beira da pista; o carro passa e ela pula
//         pra um ponto mais à frente, alternando os lados
// alta: helicóptero, alta e atrás
let cinemaPonto = null, cinemaLado = 1;
// a câmera segue a velocidade SUAVIZADA: cada palavra completada dá um
// impulso e a instantânea sobe e desce o tempo todo — o zoom, a distância
// e a altura mudavam a cada 2–3 s ("muita mudança de câmera")
let fracaoSuave = 0;
// FOV definido pela HORIZONTAL (graus) → vertical conforme a proporção da
// janela: 83° horizontais = 62° verticais numa vista 3:2, mas só ~50° numa
// tela larga e baixa — o carro e as placas param de encolher
function fovVertical(horizontal) {
  const a = (camera && camera.aspect) || 1.5;
  const v = 2 * Math.atan(Math.tan(THREE.MathUtils.degToRad(horizontal) / 2) / a) * 180 / Math.PI;
  return THREE.MathUtils.clamp(v, 40, 82);
}
function posicionarCamera(e, f, px, pz, fracao, dt) {
  const modo = e.camera || 'perseguicao';
  fracaoSuave += (fracao - fracaoSuave) * (1 - Math.exp(-dt / 1.8));
  const v = fracaoSuave;
  let alvoPos, alvoOlhar, fov, rigida = false, olharRapido = false;
  if (modo === 'capo') {
    alvoPos = new THREE.Vector3(px + f.x * 2.2, 0.95, pz + f.z * 2.2);
    alvoOlhar = new THREE.Vector3(px + f.x * 40, 0.7, pz + f.z * 40);
    fov = fovVertical(88 + v * 14);
    rigida = true; olharRapido = true;
  } else if (modo === 'alta') {
    alvoPos = new THREE.Vector3(px - f.x * 13, 8.5 + v * 1.5, pz - f.z * 13);
    alvoOlhar = new THREE.Vector3(px + f.x * 12, 0.4, pz + f.z * 12);
    fov = fovVertical(69 + v * 8);
  } else if (modo === 'cinema') {
    const zc = e.posicao || 0;
    // corta só quando o carro já passou 45 m do ponto (a câmera acompanha
    // ele se afastando): um corte a cada ~140 m, não a cada 60
    if (!cinemaPonto || zc > cinemaPonto.z + 45 || zc < cinemaPonto.z - 160) {
      cinemaLado = -cinemaLado;
      const zp = zc + 95;
      const qp = pose(zp), rp = direita(qp.h);
      cinemaPonto = { z: zp, pos: new THREE.Vector3(qp.x + rp.x * 9.5 * cinemaLado, 3.4, qp.z + rp.z * 9.5 * cinemaLado) };
      camPos.copy(cinemaPonto.pos);
      camAlvo.set(px, 0.8, pz);
    }
    alvoPos = cinemaPonto.pos;
    alvoOlhar = new THREE.Vector3(px + f.x * 1.5, 0.8, pz + f.z * 1.5);
    // teleobjetiva: fecha o zoom quando o carro está longe
    const dist = alvoPos.distanceTo(alvoOlhar);
    const fovAlvo = fovVertical(Math.max(26, Math.min(78, 2000 / (dist + 8))));
    fov = camera.fov + (fovAlvo - camera.fov) * (1 - Math.exp(-dt / 0.35));
    rigida = true; olharRapido = true;
  } else {
    alvoPos = new THREE.Vector3(px - f.x * (7.4 + v * 1.4), 3.0 + v * 0.3, pz - f.z * (7.4 + v * 1.4));
    alvoOlhar = new THREE.Vector3(px + f.x * 9, 1.1, pz + f.z * 9);
    fov = fovVertical(84 + v * 12);
  }
  if (modo !== 'cinema') cinemaPonto = null;
  if (rigida) camPos.copy(alvoPos); else camPos.lerp(alvoPos, 1 - Math.pow(0.001, dt));
  camAlvo.lerp(alvoOlhar, 1 - Math.pow(olharRapido ? 0.000001 : 0.0005, dt));
  const forca = modo === 'cinema' ? 0.04 : (modo === 'capo' ? 0.12 : 0.2);
  tremor = e.tremor === false ? 0 : Math.max(0, (e.impacto || 0) * forca);
  camera.position.set(camPos.x + (Math.random() - .5) * tremor, camPos.y + (Math.random() - .5) * tremor, camPos.z + (Math.random() - .5) * tremor);
  camera.lookAt(camAlvo);
  camera.fov = fov;
  camera.updateProjectionMatrix();
}

function quadro() {
  vigiarDesempenho();
  const dt = Math.min(relogio.getDelta(), 0.1);
  const e = estado || { posicao: 0, velocidade: 0, velMax: 30, x: 0, xAlvo: 0, impacto: 0, boost: 0 };
  const q = pose(e.posicao);
  const f = frente(q.h), r = direita(q.h);
  const lat = e.x || 0;
  const px = q.x + r.x * lat, pz = q.z + r.z * lat;
  const guinada = ((e.xAlvo || 0) - lat) * 0.09;
  const fracao = Math.max(0, Math.min(1, e.velocidade / (e.velMax || 1)));

  if (carro) {
    carro.position.set(px, 0, pz);
    carro.rotation.set(-fracao * 0.012 - (e.boost || 0) * 0.02, -q.h - guinada, guinada * 0.6);
  }
  // 👻 o fantasma segue a volta gravada pelo relógio da corrida
  if (fantasma) {
    const g = cfg.fantasma, passo = cfg.fantasmaPasso || 0.25, n = g.length / 2;
    const t = Math.max(0, e.tempo || 0), i = t / passo;
    const a = Math.min(n - 1, Math.floor(i)), b = Math.min(n - 1, a + 1), fr = Math.min(1, i - a);
    const pg = g[a * 2] + (g[b * 2] - g[a * 2]) * fr, xg = g[a * 2 + 1] + (g[b * 2 + 1] - g[a * 2 + 1]) * fr;
    const qg = pose(pg), rg = direita(qg.h);
    fantasma.position.set(qg.x + rg.x * xg, 0.02, qg.z + rg.z * xg);
    fantasma.rotation.set(0, -qg.h, 0);
    fantasma.visible = t > 0.05 && !e.acabou && Math.abs(pg - (e.posicao || 0)) < 260;
  }
  // as palavras flutuam sobre a faixa pra onde levam, à frente do carro
  posicionarPaineis(e);
  posicionarCamera(e, f, px, pz, fracao, dt);

  // o chão (4 km) acompanha o carro de tile em tile — as pistas têm até 12 km
  if (chaoPlano) {
    const tile = chaoPlano.userData.tile || 20;
    chaoPlano.position.x = Math.round(px / tile) * tile;
    chaoPlano.position.z = Math.round(pz / tile) * tile;
  }
  // a luz de acompanhamento vai junto (atrás e acima do carro)
  if (luzCarro) luzCarro.position.set(px - f.x * 3.2, 3.4, pz - f.z * 3.2);
  // o sol e a sombra acompanham o carro
  const s = cfg.tema.sol;
  sol.position.set(px + s[0] * 80, s[1] * 80, pz + s[2] * 80);
  sol.target.position.set(px, 0, pz);

  atualizarLuzes(e.posicao || 0);
  animarArremessos(dt);
  animarFaiscas(dt);
  relogioAnim += dt;
  animarFichas(relogioAnim, e.posicao || 0);
  animarColetas(relogioAnim);
  atualizarMotorAudio(fracao, e);
  if (ultimaFaixaSom !== null && e.faixa !== undefined && e.faixa !== ultimaFaixaSom) tocarDerrapagem(fracao);
  if (e.faixa !== undefined) ultimaFaixaSom = e.faixa;
  atualizarMusica(e, dt);
  atualizarVento(fracao, e);
  // cenário e postes: só os trechos perto do carro; metade no nível leve
  cularPorDistancia(cenarioMalhas, e.posicao || 0, perfilAtual.cenario, perfilAtual.cenarioAlcance, perfilAtual.metade);
  cularPorDistancia(lampadasMalhas, e.posicao || 0, perfilAtual.cenario || perfilAtual.luzes, Math.max(260, perfilAtual.cenarioAlcance), false);
  // só os carros parados dos próximos portais entram na cena (desempenho)
  for (const o of obstaculos) {
    if (o.userData.arremessado) continue;
    const dz = o.userData.z - e.posicao;
    o.visible = dz > -30 && dz < perfilAtual.trafego;
  }
  atualizarPlacas();
  renderer.render(scene, camera);
}

function destruir() {
  pararAudio();
  arremessos = []; faiscas = [];
  if (animId) cancelAnimationFrame(animId);
  animId = 0;
  if (resizeObs) resizeObs.disconnect();
  resizeObs = null;
  if (renderer) { renderer.dispose(); renderer = null; }
  scene = null; carro = null; luzCarro = null; portais = []; obstaculos = []; faroisLuz = []; estado = null;
  paineis = [];
  postesLuz = []; luzesPool = [];
  ultimoW = 0; ultimoH = 0;
  api.pronto = false;
  api.progresso = 0;
  cinemaPonto = null;
  fracaoSuave = 0;
  chaoPlano = null;
  fantasma = null;
  coletas = []; popups = []; popupTex = null;
  predios = []; nPredios = 0;
  cenarioMalhas = []; nCenario = 0; lampadasMalhas = [];
  ultimaFaixaSom = null;
}

function debug() {
  const e = estado || {};
  return {
    pronto: api.pronto, erro: api.erro,
    carro: carro ? { pos: carro.position.toArray().map((v) => +v.toFixed(2)), caixa: carro.userData.caixa, visiveis: (() => { let n = 0; carro.traverse((o) => { if (o.isMesh && o.visible) n++; }); return n; })() } : null,
    camera: camera ? camera.position.toArray().map((v) => +v.toFixed(2)) : null,
    modoCamera: estado ? estado.camera : null,
    musica: musicaUrl, musicaEl: musicaEl ? { tocando: !musicaEl.paused, volume: +musicaEl.volume.toFixed(2), t: +musicaEl.currentTime.toFixed(1), pronta: musicaEl.readyState } : null,
    benchMs: api.benchMs, perfil: perfilAtual, predios: nPredios, cenario: nCenario, lotesCenario: cenarioMalhas.length,
    render: renderer ? { calls: renderer.info.render.calls, triangulos: renderer.info.render.triangles, texturas: renderer.info.memory.textures, geometrias: renderer.info.memory.geometries, programas: renderer.info.programs ? renderer.info.programs.length : null } : null,
    malhasCarro: carro ? (() => { let n = 0, mats = new Set(); carro.traverse((o) => { if (o.isMesh && o.visible) { n++; (Array.isArray(o.material) ? o.material : [o.material]).forEach((m) => mats.add(m.uuid)); } }); return { malhas: n, materiais: mats.size }; })() : null,
    obstaculosVisiveis: obstaculos.filter((o) => o.visible).length,
    qualidade: nivelQualidade, gpu: api.gpu, frameMs: api.frameMs, aviso: api.aviso, tremor: estado ? estado.tremor : null,
    fantasma: fantasma ? { visivel: fantasma.visible, pos: fantasma.position.toArray().map((v) => +v.toFixed(1)) } : null,
    coletas: coletas.length, popups: popups.filter((sp) => sp.visible).length,
    fichasPegasJs: portais.reduce((n, pt) => n + (pt.fichas || []).filter((f) => f.userData.pega).length, 0),
    flagsFichas: estado && estado.portais ? estado.portais.map((fl) => [fl.k, (fl.fichas || []).filter(Boolean).length, (fl.fichas || []).length]) : null,
    trafegoAndando: obstaculos.filter((o) => o.visible && !o.userData.arremessado && Math.abs(o.userData.z - (estado ? estado.posicao : 0)) < 120).map((o) => +o.userData.z.toFixed(1)).slice(0, 4),
    fichasJs: portais.slice(0, 3).map((pt) => (pt.fichas || []).length),
    placas: paineis.filter((pn) => pn.mesh.visible).map((pn) => +pn.mesh.scale.x.toFixed(2)), fov: camera ? +camera.fov.toFixed(1) : null,
    estado: { posicao: e.posicao, velocidade: e.velocidade, x: e.x },
    obstaculos: obstaculos.length,
    audio: { ctx: !!audioCtx, motor: !!buffers.motor, batida: !!buffers.batida, fonte: !!motorFonte, estado: audioCtx && audioCtx.state },
    tema: cfg && cfg.tema ? cfg.tema.hdri : null,
    pista: cfg ? cfg.distancia : null,
    arremessos: arremessos.length,
  };
}
Object.assign(api, { montar, atualizar, destruir, debug, CARROS: Object.keys(CARROS) });
// diagnóstico: o que está sendo desenhado, por categoria
api.composicao = () => {
  if (!scene || !camera) return null;
  const frustum = new THREE.Frustum();
  const m = new THREE.Matrix4().multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse);
  frustum.setFromProjectionMatrix(m);
  const cat = {};
  const conta = (nome, o) => { const c = cat[nome] || (cat[nome] = { objetos: 0, noFrustum: 0, tris: 0 }); c.objetos++; if (!o.geometry) return; let t = 0; const g = o.geometry; t = g.index ? g.index.count / 3 : (g.attributes.position ? g.attributes.position.count / 3 : 0); if (o.isInstancedMesh) t *= o.count; if (!o.frustumCulled || (o.geometry.boundingSphere && frustum.intersectsObject(o))) { c.noFrustum++; c.tris += t; } };
  const emCarro = new Set(); if (carro) carro.traverse((o) => emCarro.add(o));
  const emObst = new Set(); for (const ob of obstaculos) ob.traverse((o) => emObst.add(o));
  const emCen = new Set(cenarioMalhas);
  const emFant = new Set(); if (fantasma) fantasma.traverse((o) => emFant.add(o));
  const emPredio = new Set(predios);
  scene.traverse((o) => {
    if (!(o.isMesh || o.isPoints || o.isSprite)) return;
    if (!o.visible) return;
    let pai = o, oculto = false; while (pai) { if (!pai.visible) { oculto = true; break; } pai = pai.parent; }
    if (oculto) return;
    const nome = emCarro.has(o) ? 'carro' : emObst.has(o) ? 'trafego' : emCen.has(o) ? 'cenario' : emFant.has(o) ? 'fantasma' : emPredio.has(o) ? 'predios' : (o.isPoints ? 'faiscas' : (o.isSprite ? 'sprites' : 'outros'));
    conta(nome, o);
  });
  return cat;
};
// gancho de teste/diagnóstico: turismo3d.forcarQualidade('minima')
api.forcarQualidade = (nivel) => { if (PERFIS[nivel]) aplicarQualidade(nivel); return nivelQualidade; };
window.turismo3d = api;
