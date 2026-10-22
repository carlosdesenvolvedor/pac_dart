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

// Versão do módulo: o Dart (vista_3d_web.dart, `versaoTurismo3d`) confere em
// `window.turismo3d.versao` e, se um módulo velho veio do cache, manda o
// mundo base (`temaBase`) no lugar dos temas 7–26 em vez de pintar Campina.
export const VERSAO = 30;

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
  // ---- 🌍 English Turismo (pistas 11–30 → temas 7–26): um mundo por pista ----
  // Mesmos céus/texturas/modelos de sempre; o que muda é procedural (ver
  // "mundos do English Turismo" mais abaixo). Espelho 2D: AmbienteTurismo.
  7: { hdri: 'campina', chao: 'leafy_grass', repChao: 260, chaoTinta: 0xe6c58a, exposicao: 0.82, sol: [-0.9, 0.16, 0.1], solCor: 0xff8a3d, solForca: 2.0, noturno: false, neblina: 0xf0a46a, densidade: 0.0022,
       ceu: { intensidade: 0.55, rotacao: 1.2, env: 0.75 }, zebras: ['#ff7043', '#fff3e0'], particulas: { tipo: 'vagalumes', qtd: 220 },
       cenario: { modelos: ['shrub_03', 'shrub_04', 'rock_moss_set_01', 'tree_stump_01'], pesos: [7, 3, 1, 1], passo: 16 } },
  8: { hdri: 'campina', chao: 'leafy_grass', repChao: 260, chaoTinta: 0xa9c49a, exposicao: 0.90, sol: [-0.3, 0.5, 0.5], solCor: 0xf4f7ff, solForca: 1.2, noturno: false, neblina: 0xc9d3dc, densidade: 0.0050,
       ceu: { intensidade: 0.7, desfoque: 0.35, env: 0.8 }, pinheiros: { cor: 0x2f5d46, passo: 14 },
       cenario: { modelos: ['shrub_03', 'shrub_04', 'rock_moss_set_01'], pesos: [3, 3, 2], passo: 22 } },
  9: { hdri: 'campina', chao: 'leafy_grass', repChao: 260, chaoTinta: 0xd98a3a, exposicao: 1.0, sol: [0.4, 0.6, -0.3], solCor: 0xffd9a0, solForca: 2.3, noturno: false, neblina: 0xf6d2a6, densidade: 0.0018,
       ceu: { rotacao: 2.4 }, arvoresOutono: { passo: 18, cores: [0xd9531e, 0xf2a03d, 0xb83a1b] }, particulas: { tipo: 'folhas', qtd: 260 },
       cenario: { modelos: ['tree_stump_01', 'dead_tree_trunk'], pesos: [2, 1], passo: 30 } },
  10: { hdri: 'campina', chao: 'leafy_grass', repChao: 260, chaoTinta: 0x6d8f5e, exposicao: 0.70, sol: [0.2, 0.6, 0.3], solCor: 0x9fb0c8, solForca: 0.6, noturno: true, neblina: 0x5d6873, densidade: 0.0042,
       ceu: { intensidade: 0.28, env: 0.35 }, asfalto: { molhado: true }, particulas: { tipo: 'chuva', qtd: 1400 }, relampago: { min: 5, max: 11 },
       cenario: { modelos: ['shrub_03', 'shrub_04'], pesos: [1, 1], passo: 18 } },
  11: { hdri: 'deserto', chao: 'sand_01', repChao: 220, chaoTinta: 0xf1ddb0, exposicao: 1.08, sol: [0.6, 0.55, -0.2], solCor: 0xfff0d0, solForca: 2.6, noturno: false, neblina: 0xcfe6f5, densidade: 0.0012,
       agua: { lados: ['direita'], cor: 0x1f8fb3, dist: 26 }, palmeiras: { passo: 34, lado: 'esquerda' }, zebras: ['#29b6f6', '#ffffff'],
       cenario: { modelos: ['rock_09'], pesos: [1], passo: 48 } },
  12: { hdri: 'campina', chao: 'leafy_grass', repChao: 260, exposicao: 1.05, sol: [-0.4, 0.7, 0.3], solCor: 0xfff1d6, solForca: 2.4, noturno: false, neblina: 0xd6ecff, densidade: 0.0012,
       ceu: { rotacao: 4.0 }, agua: { lados: 'ambos', cor: 0x1b6fa0, dist: 2, plano: true }, pilares: { passo: 40, cor: 0xd0d4d8 } },
  13: { hdri: 'deserto', chao: 'sand_01', repChao: 220, chaoTinta: 0xc8643c, exposicao: 1.0, sol: [0.7, 0.45, 0.1], solCor: 0xffc08a, solForca: 2.5, noturno: false, neblina: 0xe0a070, densidade: 0.0016,
       ceu: { rotacao: 3.1 }, muros: { cor: 0xa0482a, altura: 26, dist: 14 },
       cenario: { modelos: ['namaqualand_boulder_04', 'rock_09'], pesos: [2, 3], passo: 22, tinta: 0xb5583a } },
  14: { hdri: 'deserto', chao: 'sand_01', repChao: 220, exposicao: 0.90, sol: [0.3, 0.5, 0.4], solCor: 0xffd18a, solForca: 1.4, noturno: false, neblina: 0xd9a35c, densidade: 0.0050,
       ceu: { intensidade: 0.6, desfoque: 0.5, env: 0.7 }, particulas: { tipo: 'poeira', qtd: 900, cor: 0xd9a35c },
       cenario: { modelos: ['quiver_tree_02', 'rock_09'], pesos: [1, 3], passo: 22 } },
  15: { hdri: 'deserto', chao: 'sand_01', repChao: 220, chaoTinta: 0x8a7a66, exposicao: 0.80, sol: [-0.3, 0.6, 0.4], solCor: 0x9fb7ff, solForca: 0.35, noturno: true, neblina: 0x10162b, densidade: 0.0016,
       ceu: { procedural: 'estrelas', cores: [0x0b1330, 0x24305e], env: 0.12 }, lampadas: true, luzes: { cor: 0xffb060 },
       agua: { lados: ['esquerda'], cor: 0x0d2a4a, dist: 30, metal: 0.45, rugosidade: 0.2 }, palmeiras: { passo: 50, lado: 'esquerda' },
       astro: { tipo: 'lua', dir: [0.4, 0.5, -1], tam: 60 } },
  16: { hdri: 'campina', chao: 'concrete_floor_02', repChao: 200, exposicao: 1.05, sol: [0.35, 0.8, 0.3], solCor: 0xffffff, solForca: 2.6, noturno: false, neblina: 0xdfe8f0, densidade: 0.0014,
       cidade: true, cidadeDia: true, zebras: ['#ffca28', '#263238'] },
  17: { hdri: 'cidade', chao: 'concrete_floor_02', repChao: 200, exposicao: 0.80, sol: [0.3, 0.7, 0.4], solCor: 0x9fb7ff, solForca: 0.35, noturno: true, neblina: 0x223040, densidade: 0.0032,
       ceu: { intensidade: 0.6, env: 0.45 }, cidade: true, lampadas: true, asfalto: { molhado: true }, particulas: { tipo: 'chuva', qtd: 1600 } },
  18: { hdri: 'cidade', chao: 'concrete_floor_02', repChao: 200, chaoTinta: 0x3a2a4a, exposicao: 0.90, sol: [0.3, 0.7, 0.4], solCor: 0x9fb7ff, solForca: 0.35, noturno: true, neblina: 0x2a0f3a, densidade: 0.0026,
       ceu: { intensidade: 0.35, env: 0.4 }, cidade: true, lampadas: true, neon: { cores: [0xff2fd0, 0x22e6ff] }, zebras: ['#ff2fd0', '#22e6ff'] },
  19: { hdri: 'neve', chao: 'snow_02', repChao: 240, exposicao: 0.95, sol: [-0.3, 0.5, 0.5], solCor: 0xdde8ff, solForca: 1.0, noturno: false, neblina: 0xdfe8f2, densidade: 0.0050,
       ceu: { intensidade: 0.5, desfoque: 0.4, env: 0.7 }, particulas: { tipo: 'neve', qtd: 1800, deriva: 3.5 }, pinheiros: { cor: 0x2b4a3c, passo: 18, neve: true } },
  20: { hdri: 'neve', chao: 'snow_02', repChao: 240, exposicao: 1.05, sol: [-0.4, 0.55, 0.4], solCor: 0xffffff, solForca: 2.2, noturno: false, neblina: 0xeaf3ff, densidade: 0.0016,
       agua: { lados: 'ambos', cor: 0xbfe3ff, dist: 16, gelo: true }, pinheiros: { passo: 26, neve: true }, particulas: { tipo: 'neve', qtd: 300 } },
  21: { hdri: 'neve', chao: 'snow_02', repChao: 240, chaoTinta: 0x9fb4d8, exposicao: 0.85, sol: [-0.2, 0.6, 0.4], solCor: 0x9fc8ff, solForca: 0.4, noturno: true, neblina: 0x0d1830, densidade: 0.0014,
       ceu: { procedural: 'aurora', cores: [0x050a1a, 0x0f2340], aurora: [0x3dffa0, 0x9a6bff], env: 0.12 }, pinheiros: { passo: 22, neve: true }, particulas: { tipo: 'neve', qtd: 200 } },
  22: { hdri: 'vulcao', chao: 'dark_rock', repChao: 200, exposicao: 1.0, sol: [0.7, 0.3, 0.2], solCor: 0xff6a3a, solForca: 1.8, noturno: true, neblina: 0x4a1a10, densidade: 0.0030,
       particulas: { tipo: 'brasas', qtd: 700 }, lava: { lado: 'esquerda', dist: 18, largura: 14, cor: 0xff5a1a }, pulso: { cor: 0xff3a1a, periodo: 2.4 },
       cenario: { modelos: ['moon_rock_01', 'moon_rock_03', 'moon_rock_05'], pesos: [1, 2, 2], passo: 22, tinta: 0x3b2b26 } },
  23: { hdri: 'espaco', chao: 'dark_rock', repChao: 200, chaoTinta: 0xb8b8b8, exposicao: 1.0, sol: [0.6, 0.4, -0.3], solCor: 0xffffff, solForca: 2.8, noturno: true, neblina: 0x05070d, densidade: 0.0006,
       astro: { tipo: 'terra', dir: [-0.4, 0.35, -1], tam: 120 }, zebras: ['#90a4ae', '#eceff1'],
       cenario: { modelos: ['moon_rock_01', 'moon_rock_03', 'moon_rock_05'], pesos: [1, 2, 2], passo: 18 } },
  24: { hdri: 'deserto', chao: 'sand_01', repChao: 220, chaoTinta: 0xb5532d, exposicao: 0.95, sol: [0.5, 0.5, 0.2], solCor: 0xffd2b0, solForca: 1.9, noturno: false, neblina: 0xc0623a, densidade: 0.0030,
       ceu: { procedural: 'marte', cores: [0x8a4a3a, 0xd9926a], env: 0.8 }, particulas: { tipo: 'poeira', qtd: 400, cor: 0xc0623a }, astro: { tipo: 'luas2', dir: [0.5, 0.42, -1], tam: 46 },
       cenario: { modelos: ['moon_rock_01', 'moon_rock_05', 'boulder_01'], pesos: [2, 2, 1], passo: 22, tinta: 0x8a3a22 } },
  25: { hdri: 'espaco', chao: 'metal_plate', repChao: 120, exposicao: 0.90, sol: [0.1, 0.8, 0.3], solCor: 0xc8d8ff, solForca: 0.6, noturno: true, neblina: 0x060a18, densidade: 0.0008,
       neon: { cores: [0x22e6ff, 0xffffff] }, lampadas: true, luzes: { cor: 0x22e6ff }, astro: { tipo: 'terra', dir: [0.25, 0.3, -1], tam: 260 }, zebras: ['#22e6ff', '#0d1b2a'] },
  26: { hdri: 'cidade', chao: 'concrete_floor_02', repChao: 200, exposicao: 0.95, sol: [0.3, 0.7, 0.4], solCor: 0x9fb7ff, solForca: 0.35, noturno: true, neblina: 0x141a28, densidade: 0.0018,
       ceu: { intensidade: 0.5 }, lampadas: true, arquibancadas: { passo: 60, cores: [0xd32f2f, 0xffd54f, 0x1e88e5] }, muretas: { passo: 12 }, fogos: { intervalo: 1.4 }, zebras: ['#ffd54f', '#d32f2f'] },
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
// vigia durante a corrida rebaixam o nível se o frame passar de 25 ms.
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
// ---------- orçamento de pixels ----------
// O custo de preenchimento é largura × altura × dpr². Num ultrawide HiDPI
// (dpr 2) a vista de 1400 px virava ~4,5 Mpx por frame — 8× o que o
// benchmark antigo media em 960×600@1 — e como no Apple Silicon a GPU é
// dividida com o WindowServer, a máquina inteira congelava junto. Agora
// cada nível tem um teto de megapixels e um teto de dpr; o dpr efetivo é o
// menor dos dois (e nunca acima do dpr do dispositivo).
const ORCAMENTO_MPX = { alta: 1.8, leve: 1.1, minima: 0.6 };
const TETO_DPR = { alta: 1.5, leve: 1.25, minima: 1 };
let escalaExtra = 1; // o vigia baixa isso na mínima quando nem ela dá conta
function pixelRatioPara(nivel, w, h) {
  const dev = window.devicePixelRatio || 1;
  const orc = (ORCAMENTO_MPX[nivel] || ORCAMENTO_MPX.alta) * 1e6;
  const porArea = (w > 0 && h > 0) ? Math.sqrt(orc / (w * h)) : 1;
  const dpr = Math.min(dev, TETO_DPR[nivel] || 1.5, porArea) * escalaExtra;
  return Math.max(0.5, Math.round(dpr * 100) / 100);
}
function aplicarTamanho() {
  if (!renderer || !ultimoW || !ultimoH) return;
  congelado = false; // setSize limpa o canvas: redesenha mesmo parado
  const dpr = pixelRatioPara(nivelQualidade, ultimoW, ultimoH);
  renderer.setPixelRatio(dpr);
  renderer.setSize(ultimoW, ultimoH, false);
  api.pixelRatio = dpr;
  api.pixelsMpx = +((ultimoW * ultimoH * dpr * dpr) / 1e6).toFixed(2);
}
// mede o canvas de verdade (o Dart já o dimensionou dentro do platform
// view); se ainda não tem layout, assume uma vista de desktop
function medirCanvas(canvas) {
  let w = 0, h = 0;
  try { const r = canvas.getBoundingClientRect(); w = Math.round(r.width); h = Math.round(r.height); } catch (e) {}
  if (w < 32 || h < 32) { w = Math.min(1400, window.innerWidth || 1280); h = Math.round(w * 9 / 16); }
  return { w, h };
}
// benchmark de ~0,5 s num renderer descartável: 24 esferas de 12k
// triângulos com textura, 3 luzes, sol com sombra PCF 2048 e chão que a
// recebe — renderizado NO TAMANHO REAL do canvas e no dpr que o nível
// "alta" usaria, pra medir o custo que a corrida vai ter de verdade (o
// antigo media 960×600@1, 8× menos pixels que a vista no desktop HiDPI).
// Se isso não roda a 50 fps, a cena de verdade não vai rodar. Decide o
// nível ANTES de baixar céu 2k/texturas 1k.
async function benchmarkGpu(antialias, w, h, dpr) {
  let r = null;
  try {
    const c = document.createElement('canvas');
    r = new THREE.WebGLRenderer({ canvas: c, antialias, powerPreference: 'high-performance' });
    w = w || 960; h = h || 600;
    r.setPixelRatio(dpr || 1);
    r.setSize(w, h, false);
    r.shadowMap.enabled = true;
    r.shadowMap.type = THREE.PCFShadowMap;
    r.toneMapping = THREE.ACESFilmicToneMapping;
    const cena = new THREE.Scene();
    const cam = new THREE.PerspectiveCamera(60, w / h, 0.1, 100);
    cam.position.set(0, 0, 13);
    const geo = new THREE.SphereGeometry(1.25, 96, 64);
    const tex = canvasTex(512, 512, (ctx, w, h) => {
      for (let i = 0; i < 300; i++) { ctx.fillStyle = `hsl(${(i * 37) % 360},60%,50%)`; ctx.fillRect((i * 97) % w, (i * 53) % h, 48, 48); }
    }).tex;
    const mat = new THREE.MeshStandardMaterial({ map: tex, metalness: .4, roughness: .5 });
    for (let i = 0; i < 24; i++) {
      const m = new THREE.Mesh(geo, mat);
      m.position.set((i % 6 - 2.5) * 3.1, (Math.floor(i / 6) - 1.5) * 3.1, 0);
      m.castShadow = true; m.receiveShadow = true;
      cena.add(m);
    }
    const chaoGeo = new THREE.PlaneGeometry(60, 60);
    const chaoMat = new THREE.MeshStandardMaterial({ color: 0x777777, roughness: .9 });
    const chao = new THREE.Mesh(chaoGeo, chaoMat);
    chao.position.z = -2; chao.receiveShadow = true;
    cena.add(chao);
    cena.add(new THREE.HemisphereLight(0xffffff, 0x444444, 1));
    const solB = new THREE.DirectionalLight(0xffffff, 2.5);
    solB.position.set(6, 10, 12); solB.castShadow = true;
    solB.shadow.mapSize.set(2048, 2048);
    solB.shadow.camera.near = 1; solB.shadow.camera.far = 60;
    solB.shadow.camera.left = -14; solB.shadow.camera.right = 14; solB.shadow.camera.top = 14; solB.shadow.camera.bottom = -14;
    cena.add(solB);
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
    geo.dispose(); mat.dispose(); tex.dispose(); chaoGeo.dispose(); chaoMat.dispose();
    if (solB.shadow.map) solB.shadow.map.dispose();
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
  for (const m of extrasCenario) m.castShadow = nivel === 'alta';
  for (const m of lampadasMalhas) m.castShadow = false;
  if (luzCarro) luzCarro.visible = perfilAtual.luzes;
  for (const l of faroisLuz) l.visible = perfilAtual.luzes;
  if (ingles) { for (const l of luzesPool) l.visible = perfilAtual.luzes; } // contagem fixa: ver construirLampadas
  else if (!perfilAtual.luzes) for (const l of luzesPool) l.visible = false;
  if (!renderer) return;
  aplicarTamanho();
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
let vigiaTempos = [], vigiaAte = 0, ultimoQuadroMs = 0, vigiaSomaMs = 0, vigiaLentosSeguidos = 0;
// vigia durante a corrida: junta ~2 s de frames (ou 150, o que vier antes)
// e, se a mediana passar de 25 ms, cai um nível. Frames acima de 500 ms
// NÃO são descartados (eram — e é justamente quando a máquina engasga que
// eles aparecem): entram truncados em 500 ms, e 5 seguidos acima de 100 ms
// rebaixam na hora. Aba oculta e a volta dela não contam.
function vigiarDesempenho() {
  const agora = performance.now();
  if (document.hidden) { ultimoQuadroMs = 0; return; }
  if (!ultimoQuadroMs) { ultimoQuadroMs = agora; return; }
  const dt = Math.min(agora - ultimoQuadroMs, 500);
  ultimoQuadroMs = agora;
  if (!api.pronto || agora < vigiaAte) return;
  vigiaTempos.push(dt);
  vigiaSomaMs += dt;
  vigiaLentosSeguidos = dt > 100 ? vigiaLentosSeguidos + 1 : 0;
  const emergencia = vigiaLentosSeguidos >= 5;
  if (!emergencia && vigiaSomaMs < 2000 && vigiaTempos.length < 150) return;
  const m = emergencia ? mediana(vigiaTempos.slice(-5)) : mediana(vigiaTempos);
  vigiaTempos = []; vigiaSomaMs = 0; vigiaLentosSeguidos = 0;
  api.frameMs = +m.toFixed(1);
  if (m > 25) rebaixar(emergencia ? 'emergência' : 'lento', m);
}
// um degrau por vez: alta → leve → mínima → mínima com menos pixels (até 60%)
function rebaixar(motivo, ms) {
  if (nivelQualidade === 'alta') aplicarQualidade('leve');
  else if (nivelQualidade === 'leve') aplicarQualidade('minima');
  else if (escalaExtra > 0.6) { escalaExtra = Math.max(0.6, +(escalaExtra - 0.2).toFixed(2)); aplicarTamanho(); }
  else return; // já está no chão
  api.rebaixamentos = (api.rebaixamentos || 0) + 1;
  console.info('[turismo3d] vigia:', motivo, Math.round(ms) + ' ms →', nivelQualidade, 'escala', escalaExtra, 'dpr', api.pixelRatio);
  vigiaAte = performance.now() + 6000;
}
// compila os shaders e força os uploads de textura/PMREM antes da largada
// (no Windows o ANGLE traduz GLSL→HLSL: cada material novo custava um
// engasgo no primeiro frame em que aparecia)
async function aquecer() {
  // o que só nascia na 1ª ficha/batida (e compilava shader no meio da
  // corrida): o guardião das faíscas e o 1º sprite "+3 🪙" (invisível; o
  // pool de coletarFicha o reaproveita)
  if (ingles && renderer && scene) {
    guardarProgramaFaiscas();
    if (portais.some((pt) => pt.fichas && pt.fichas.length) && !popups.length) novoPopup();
  }
  try {
    if (renderer.compileAsync) await renderer.compileAsync(scene, camera); else renderer.compile(scene, camera);
  } catch (e) { console.warn('[turismo3d] compile', e); }
  const salvo = [];
  for (const o of obstaculos) { salvo.push(o.visible); o.visible = true; }
  for (const m of cenarioMalhas) m.visible = true;
  for (const m of lampadasMalhas) m.visible = true;
  // os mundos novos também (árvores, muros, arquibancadas…): o quadro() cula de novo
  for (const m of extrasCenario) m.visible = true;
  for (const m of extrasEstrutura) m.visible = true;
  for (const m of extrasLongos) m.visible = true;
  try { for (let i = 0; i < 3; i++) renderer.render(scene, camera); } catch (e) { console.warn('[turismo3d] aquecer', e); }
  obstaculos.forEach((o, i) => { o.visible = salvo[i]; });
  // texturas que só apareceriam depois: placas/fichas do começo e o "+3 🪙"
  if (ingles) {
    subirTexturasAdiante(0, Infinity);
    if (popupTex) { try { renderer.initTexture(popupTex); } catch (e) {} }
  }
}
let camPos = new THREE.Vector3(), camAlvo = new THREE.Vector3();
let tremor = 0;
const api = { pronto: false, erro: null, progresso: 0 };
document.addEventListener('visibilitychange', () => { ultimoQuadroMs = 0; }, { passive: true });

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
// `tinta`: a cor que multiplica a textura (o chão dos mundos novos) — reaplicada
// no onUpdate, que é quem trocava o cinza provisório por branco
function materialPbr(nome, { repU = 1, repV = 1, rough = 1, metal = 0, tinta = null } = {}) {
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
  const corFinal = tinta != null ? tinta : 0xffffff;
  m.map.onUpdate = () => { m.color.set(corFinal); };
  if (m.map.image) m.color.set(corFinal);
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
  // 🌧️ asfalto molhado: espelha os faróis e os postes (o material nasce a cada corrida)
  if (tema.asfalto && tema.asfalto.molhado) { asfalto.roughness = 0.28; asfalto.metalness = 0.05; efeitosAtivos.push('asfalto'); }
  const estrada = new THREE.Mesh(faixaGeometria(-MEIA_PISTA - 0.3, MEIA_PISTA + 0.3, 0, 0, 6), asfalto);
  estrada.receiveShadow = true;
  scene.add(estrada);

  // pintura: linhas de borda e tracejado entre faixas (tile = 8 m); 🌆 neon: nas cores do tema, acesas
  const neon = tema.neon ? tema.neon.cores.map(corCss) : null;
  const pintura = canvasTex(512, 512, (ctx, w, h) => {
    ctx.clearRect(0, 0, w, h);
    ctx.fillStyle = neon ? neon[0] : 'rgba(255,255,255,0.85)';
    ctx.fillRect(w * 0.028, 0, w * 0.012, h);
    ctx.fillRect(w * 0.96, 0, w * 0.012, h);
    if (neon) ctx.fillStyle = neon[1];
    for (const u of [1 / 3, 2 / 3]) {
      for (const v0 of [0.05, 0.55]) ctx.fillRect(w * u - w * 0.006, h * v0, w * 0.012, h * 0.28);
    }
  });
  const tinta = new THREE.MeshStandardMaterial({ map: pintura.tex, transparent: true, roughness: .6, metalness: 0, polygonOffset: true, polygonOffsetFactor: -1 });
  if (neon) { tinta.emissive.set(0xffffff); tinta.emissiveMap = pintura.tex; tinta.emissiveIntensity = 1.4; }
  const linhas = new THREE.Mesh(faixaGeometria(-MEIA_PISTA - 0.3, MEIA_PISTA + 0.3, 0.012, 0.012, 8), tinta);
  scene.add(linhas);

  // zebras vermelhas e brancas nas bordas (tile de 4 m); os mundos novos trocam as cores
  const coresZebra = tema.zebras || neon || ['#e53935', '#f5f5f5'];
  const zebra = canvasTex(64, 256, (ctx, w, h) => {
    ctx.fillStyle = coresZebra[0]; ctx.fillRect(0, 0, w, h / 2);
    ctx.fillStyle = coresZebra[1]; ctx.fillRect(0, h / 2, w, h / 2);
  });
  const zebraMat = new THREE.MeshStandardMaterial({ map: zebra.tex, roughness: .55 });
  for (const lado of [-1, 1]) {
    const z = new THREE.Mesh(faixaGeometria(lado * (MEIA_PISTA + 0.3), lado * (MEIA_PISTA + 0.95), 0.02, 0.06, 4), zebraMat);
    z.receiveShadow = true;
    scene.add(z);
  }

  // chão do mundo
  // 🌉 ponte (`agua.plano`): o chão vira o mar, uns metros abaixo do tabuleiro
  const mar = tema.agua && tema.agua.plano ? tema.agua : null;
  const chao = mar ? materialAgua(mar) : materialPbr(tema.chao, { repU: tema.repChao, repV: tema.repChao, rough: 1, tinta: tema.chaoTinta });
  if (mar) chao.normalMap.repeat.set(4000 / 20, 4000 / 20);
  // faixas de água/lava ficam a 2–7 cm do chão: ele recua na profundidade pra não piscar
  else if (tema.agua || tema.lava) { chao.polygonOffset = true; chao.polygonOffsetFactor = 4; chao.polygonOffsetUnits = 4; }
  const plano = new THREE.Mesh(new THREE.PlaneGeometry(4000, 4000), chao);
  plano.rotation.x = -Math.PI / 2;
  plano.position.y = mar ? NIVEL_MAR_PONTE : -0.04;
  plano.receiveShadow = true;
  plano.userData.tile = mar ? 20 : 4000 / tema.repChao;
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
function pintarPlaca(ctx, w, h, texto, estilo, sub) {
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
  // inglês: a tradução vem numa 2ª linha menor (a palavra sobe e encolhe um pouco)
  const comSub = !!sub && texto !== '✓';
  let tam = comSub ? 78 : 96;
  ctx.font = `800 ${tam}px "JetBrains Mono", "Roboto Mono", monospace`;
  while (ctx.measureText(texto).width > w * 0.84 && tam > 28) { tam -= 6; ctx.font = `800 ${tam}px "JetBrains Mono", "Roboto Mono", monospace`; }
  ctx.fillText(texto, w / 2, comSub ? h / 2 - 16 : h / 2 + 6);
  if (comSub) {
    let ts = 40;
    ctx.font = `700 ${ts}px "Inter", "Roboto", sans-serif`;
    while (ctx.measureText(sub).width > w * 0.84 && ts > 18) { ts -= 3; ctx.font = `700 ${ts}px "Inter", "Roboto", sans-serif`; }
    ctx.fillStyle = estilo === 'bloqueada' || estilo === 'batida' ? cores[2] : '#b8c2cc';
    ctx.fillText(sub, w / 2, h - 40);
  }
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
    if (ingles) texturasAdiante.push({ z: f.z, tex });
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
// um sprite "+3 🪙" novo no pool (a textura é a mesma pra todos)
function novoPopup() {
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
  const sp = new THREE.Sprite(new THREE.SpriteMaterial({ map: popupTex, transparent: true, depthTest: false }));
  sp.renderOrder = 998;
  sp.visible = false;
  scene.add(sp);
  popups.push(sp);
  return sp;
}
function coletarFicha(fx) {
  fx.userData.pega = true;
  fx.userData.baseY = fx.position.y;
  fx.userData.t0 = relogioAnim;
  coletas.push(fx);
  soltarFaiscas(fx.position.clone(), frente(0), 0xffd54f, 40);
  soltarFaiscas(fx.position.clone(), frente(0), 0xffffff, 12);
  let sp = popups.find((x) => !x.visible);
  if (!sp && popups.length < 6) sp = novoPopup();
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

// ⚡ desempenho (22/out): as texturas de canvas das placas (512×176) e das
// fichas (256×256) subiam pra GPU no quadro em que o pórtico entrava na vista
// (3 placas + fichas de uma vez, a ~900 m) ou a ficha chegava a 260 m. Agora
// sobem ADIANTADAS, uma por quadro, quando o pórtico fica a menos de
// ALCANCE_TEXTURAS da posição (os do começo já no aquecer()). Mesma textura,
// mesma memória no fim; só o momento do upload muda.
let texturasAdiante = [], texturasAdianteI = 0; // { z, tex } em ordem de z
const ALCANCE_TEXTURAS = 1400;
function subirTexturasAdiante(posicao, limite) {
  while (limite-- > 0 && texturasAdianteI < texturasAdiante.length && texturasAdiante[texturasAdianteI].z < posicao + ALCANCE_TEXTURAS) {
    try { renderer.initTexture(texturasAdiante[texturasAdianteI].tex); } catch (e) {}
    texturasAdianteI++;
  }
}
function construirPortais() {
  texturasAdiante = []; texturasAdianteI = 0;
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
      const sub = (i >= 0 && p.traducoes && p.traducoes[i]) ? p.traducoes[i] : '';
      const ct = canvasTex(512, 176, (ctx, w, h) => pintarPlaca(ctx, w, h, texto, estilo, sub));
      const mat = new THREE.MeshStandardMaterial({ map: ct.tex, transparent: true, roughness: .5, emissive: 0xffffff, emissiveMap: ct.tex, emissiveIntensity: (cfg.tema.noturno ? 0.9 : 0.35) * (cfg.tema.neon ? 1.4 : 1) });
      const placa = new THREE.Mesh(placaGeo, mat);
      placa.position.set((faixa - 1) * LARGURA_FAIXA, 4.55, 0.22);
      grupo.add(placa);
      placas.push({ ...ct, faixa, texto, sub, estiloAtual: estilo, i });
      if (ingles) texturasAdiante.push({ z: p.z, tex: ct.tex });
    }
    scene.add(grupo);
    const port = { grupo, placas, dados: p };
    construirFichas(port, p);
    portais.push(port);
  }
  if (ingles) texturasAdiante.sort((a, b) => a.z - b.z);
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
  const mat = materialFaisca(cor);
  const pts = new THREE.Points(geo, mat);
  scene.add(pts);
  faiscas.push({ pts, vel, t: 0, dur: .75 });
}
function materialFaisca(cor) {
  return new THREE.PointsMaterial({ color: cor, size: 0.07, transparent: true, opacity: 1, depthWrite: false });
}
// ⚡ desempenho (22/out): cada faísca nasce com material próprio e é
// descartada em 0,75 s; com o último descarte o three.js APAGA o programa
// (usedTimes 0) e a próxima ficha/batida compilava o shader de novo — um
// engasgo a cada moeda. Este material "guardião" (mesmos parâmetros, cor não
// entra na chave) fica na cena invisível do montar ao destruir: o
// compileAsync do aquecer() o compila e o programa nunca morre.
let faiscaGuarda = null;
function guardarProgramaFaiscas() {
  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.BufferAttribute(new Float32Array(3), 3));
  faiscaGuarda = new THREE.Points(geo, materialFaisca(0xffb347));
  faiscaGuarda.visible = false;
  faiscaGuarda.frustumCulled = false;
  scene.add(faiscaGuarda);
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
        const o = ingles ? obstaculoDoCarro.get(k * 8 + i) : obstaculos.find((ob) => ob.userData.portalK === k && ob.userData.carroI === i);
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
        pintarPlaca(placa.ctx, placa.canvas.width, placa.canvas.height, texto, estilo, placa.sub);
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

// carro de tráfego por (portal k, carro i) → chave k·8+i (≤ 3 carros por
// pórtico). Antes era um obstaculos.find() por carro por quadro (a lista
// inteira, 100+ carros, com uma closure nova a cada busca).
let obstaculoDoCarro = new Map();
async function construirObstaculos() {
  obstaculos = [];
  obstaculoDoCarro = new Map();
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
      // o 1º que casa ganha, como o find() de antes
      const chave = modelo.userData.portalK * 8 + modelo.userData.carroI;
      if (ingles && modelo.userData.carroI >= 0 && !obstaculoDoCarro.has(chave)) obstaculoDoCarro.set(chave, modelo);
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
      const lote = { d, lado, afast: MEIA_PISTA + 4.5 + rnd() * (perto ? 9 : 34), giro: rnd() * Math.PI * 2, t: rnd() };
      // mundos novos: nada dentro da água, da lava ou atrás do paredão (os
      // temas 1–6 não têm limite — mesmo sorteio, mesmas peças)
      if (lote.afast <= limiteLado(lado)) lotes[i].push(lote);
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
    // `cen.tinta`: o material de cada malha é clonado UMA vez e tingido (rochas vermelhas, basalto…)
    const tingidos = new Map();
    const materialDe = (m) => {
      if (cen.tinta == null || !m.material || Array.isArray(m.material)) return m.material;
      if (!tingidos.has(m.material.uuid)) {
        const clone = m.material.clone();
        if (clone.color) clone.color.multiply(new THREE.Color(cen.tinta));
        descartar(clone);
        tingidos.set(m.material.uuid, clone);
      }
      return tingidos.get(m.material.uuid);
    };
    for (const { c, metade, lista } of porChunk.values()) {
      for (const m of malhas) {
        const inst = new THREE.InstancedMesh(m.geometry, materialDe(m), lista.length);
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
const LUZES_POOL = 4, INTENSIDADE_POSTE = 18;
// ⚡ desempenho (22/out) só no curso de inglês (`config.ingles` do Dart): com
// `ingles` false (Dart e C#) TODOS os blocos marcados assim ficam desligados e
// o motor se comporta exatamente como antes deles
let ingles = false;
function construirLampadas() {
  const tema = cfg.tema;
  if (!tema.lampadas) return;
  // `luzes.cor` tinge o pool; 🌆 `neon` alterna as duas cores entre os postes (sem luz nova)
  const coresNeon = tema.neon ? tema.neon.cores : null;
  // ⚡ desempenho (22/out): o pool fica SEMPRE com o mesmo número de luzes
  // visíveis — a que sobra é apagada pela intensidade 0, não pelo `visible`.
  // No three.js o nº de PointLights visíveis entra na chave do shader: cada
  // vez que mudava (3 ↔ 4 postes na janela) TODOS os materiais com luz
  // trocavam de programa, e a 1ª vez de cada contagem compilava shader no
  // meio da corrida (o engasgo dos mundos com postes, mesmo no Leve). São 4
  // (não 5): com um poste a cada 60 m e a janela de 200 m de atualizarLuzes
  // nunca cabem 5 — a 5ª luz nunca acendia.
  // (Dart/C#: o pool de antes — 5 luzes, intensidade 18, ligadas por `visible`)
  for (let i = 0; i < (ingles ? LUZES_POOL : 5); i++) {
    const cor = tema.luzes && tema.luzes.cor != null ? tema.luzes.cor : (coresNeon ? coresNeon[i % 2] : 0xffe0a0);
    const luz = new THREE.PointLight(cor, ingles ? 0 : INTENSIDADE_POSTE, 24, 2);
    luz.visible = ingles ? perfilAtual.luzes : false;
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
      // neon sem `luzes.cor`: a luz real que pula pra este poste assume a cor do bulbo dele
      const corPoste = coresNeon && !(tema.luzes && tema.luzes.cor != null) ? coresNeon[k % 2] : null;
      postesLuz.push({ d, pos: bulboPos.clone(), cor: corPoste });
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
    if (coresNeon) {
      const cor = new THREE.Color();
      lotes.forEach((l, k) => bulbos.setColorAt(k, cor.set(coresNeon[k % 2])));
      bulbos.instanceColor.needsUpdate = true;
    }
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
  if (!ingles) {
    // Dart/C#: como antes — os 5 postes mais próximos à frente/atrás ganham luz de verdade
    const perto = postesLuz.filter((p) => p.d > posicao - 40 && p.d < posicao + 160).slice(0, luzesPool.length);
    luzesPool.forEach((luz, i) => {
      const p = perto[i];
      luz.visible = !!p;
      if (p) luz.position.copy(p.pos);
      if (p && p.cor != null) luz.color.setHex(p.cor);
    });
    return;
  }
  // os postes mais próximos à frente/atrás do carro ganham luz de verdade (os
  // primeiros da janela, na ordem da pista); a luz que sobra fica visível com
  // intensidade 0 — ver construirLampadas. Sem filter/slice: nada alocado por quadro.
  let i = 0;
  for (let k = 0; k < postesLuz.length && i < luzesPool.length; k++) {
    const p = postesLuz[k];
    if (!(p.d > posicao - 40 && p.d < posicao + 160)) continue;
    const luz = luzesPool[i++];
    luz.intensity = INTENSIDADE_POSTE;
    luz.position.copy(p.pos);
    if (p.cor != null) luz.color.setHex(p.cor);
  }
  for (; i < luzesPool.length; i++) luzesPool[i].intensity = 0;
}

// ---------- 🌍 mundos do English Turismo (temas 7–26) ----------
// Sistemas opcionais por tema: campo ausente = desligado, então os temas 1–6
// nunca passam por aqui. Sem baixar nada: shader, canvas e geometria. Cada
// sistema monta em montar(), anima em animarMundo() (chamado pelo quadro()),
// entra no culling por trecho (extrasCenario/extrasEstrutura/extrasLongos), no aquecer()
// e é liberado em destruir() (extrasObjs/extrasDescarte).
const NIVEL_MAR_PONTE = -7; // o mar fica 7 m abaixo do tabuleiro da ponte
const FATOR_QTD = { alta: 1, leve: 0.5, minima: 0.2 }; // partículas por nível
const ESTRELAS_POR_NIVEL = { alta: 1500, leve: 800, minima: 300 };
let extrasObjs = [];        // objetos postos na cena (saem em destruir)
let extrasDescarte = [];    // geometrias/materiais/texturas a liberar em destruir
let extrasAnim = [];        // (dt, t, e, px, pz, f) a cada quadro
let extrasCenario = [];     // por trecho, culling do cenário (perfil: alcance, metade, mínima apaga)
let extrasEstrutura = [];   // por trecho, sempre ligados no alcance (arquibancadas)
let extrasLongos = [];      // por trecho, até o far da câmera: paredões e saias da ponte (altos, baratos, não podem "nascer" na névoa)
let ceuSeguir = [];         // esfera do céu, estrelas, aurora e astro: andam com a câmera
let efeitosAtivos = [];     // debug().efeitos
let relampagoEstado = null, pulsoEstado = null;
let hemi = null, hemiBase = null;
let texPonto = null;
let curvDh = [];            // variação do rumo por segmento do centro (rad), p/ o lado de dentro das curvas

// acessibilidade (D18): config do Dart, atualizado a cada estado (tremor desligado conta)
function reduzirMovimento() {
  if (estado && estado.reduzirMovimento != null) return !!estado.reduzirMovimento;
  return !!(cfg && cfg.reduzirMovimento);
}
function descartar(...coisas) { for (const c of coisas) if (c && !extrasDescarte.includes(c)) extrasDescarte.push(c); }
function marcarEfeito(nome) { if (!efeitosAtivos.includes(nome)) efeitosAtivos.push(nome); }
function adicionarExtra(obj, efeito) {
  scene.add(obj);
  extrasObjs.push(obj);
  if (efeito) marcarEfeito(efeito);
  return obj;
}
function rndDe(semente) { let s = semente; return () => { s = (s * 48271) % 2147483647; return s / 2147483647; }; }
function corCss(c) { return typeof c === 'string' ? c : '#' + (c >>> 0).toString(16).padStart(6, '0').slice(-6); }
function cobreLado(spec, lado) {
  if (!spec) return false;
  if (Array.isArray(spec)) return spec.some((s) => cobreLado(s, lado));
  return spec === 'ambos' || (spec === 'esquerda' && lado < 0) || (spec === 'direita' && lado > 0);
}
// até onde dá pra pôr cenário de um lado: antes da água, da lava ou do paredão
function limiteLado(lado) {
  const t = cfg && cfg.tema;
  if (!t) return Infinity;
  let lim = Infinity;
  if (t.agua && !t.agua.plano && cobreLado(t.agua.lados, lado)) lim = Math.min(lim, MEIA_PISTA + t.agua.dist - 1.5);
  if (t.lava && cobreLado(t.lava.lado, lado)) lim = Math.min(lim, MEIA_PISTA + t.lava.dist - 1.5);
  if (t.muros) lim = Math.min(lim, MEIA_PISTA + t.muros.dist - 1.5);
  return lim;
}
// o lado de DENTRO de uma curva fechada não pode ir longe (a faixa dobraria
// por cima da própria pista)
function prepararCurvatura() {
  const n = centro.length;
  curvDh = new Float32Array(n);
  for (let i = 0; i < n - 1; i++) curvDh[i] = centro[i + 1].h - centro[i].h;
}
// h crescendo = curva à direita (lado +1 é o de dentro). Vale a MAIOR
// curvatura do lado de dentro em ±12 pontos: a média se anulava nos S curtos
// (13–29 segmentos) e deixava ~400 m num raio real de 48–82 m (a água dobrava)
function alcanceLateral(i, lado, quer) {
  const n = curvDh.length;
  i = Math.max(0, Math.min(n - 1, i));
  let km = 0;
  for (let j = Math.max(0, i - 12); j <= Math.min(n - 2, i + 12); j++) km = Math.max(km, curvDh[j] * lado);
  if (km <= 0) return quer;
  return Math.max(MEIA_PISTA + 4, Math.min(quer, (L / km) * 0.85));
}
function texturaPonto() {
  if (!texPonto) {
    texPonto = canvasTex(64, 64, (ctx, w, h) => {
      const g = ctx.createRadialGradient(w / 2, h / 2, 0, w / 2, h / 2, w / 2);
      g.addColorStop(0, 'rgba(255,255,255,1)'); g.addColorStop(0.35, 'rgba(255,255,255,0.85)'); g.addColorStop(1, 'rgba(255,255,255,0)');
      ctx.fillStyle = g; ctx.fillRect(0, 0, w, h);
    }).tex;
    descartar(texPonto);
  }
  return texPonto;
}

// faixa ao longo da pista com lateral variável por ponto (água, lava, tabuleiro, neon)
function faixaGeo(latA, latB, yA, yB, repV, uLarg = 1, i0 = 0, i1 = centro.length - 1) {
  const n = i1 - i0 + 1;
  const pos = new Float32Array(n * 6), uv = new Float32Array(n * 4), idx = [];
  for (let k = 0; k < n; k++) {
    const i = i0 + k, p = centro[i], r = direita(p.h);
    const a = typeof latA === 'function' ? latA(i) : latA;
    const b = typeof latB === 'function' ? latB(i) : latB;
    pos.set([p.x + r.x * a, yA, p.z + r.z * a, p.x + r.x * b, yB, p.z + r.z * b], k * 6);
    const v = (i * L) / repV;
    uv.set([0, v, uLarg, v], k * 4);
    if (k < n - 1) { const j = k * 2; idx.push(j, j + 1, j + 2, j + 1, j + 3, j + 2); }
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  g.setAttribute('uv', new THREE.BufferAttribute(uv, 2));
  g.setIndex(idx);
  g.computeVertexNormals();
  return g;
}
// parede ao longo da pista (paredão do cânion, saia do tabuleiro): `linhas`
// faixas na altura, inclinada pra fora e com relevo
function paredeGeo(i0, i1, latFn, lado, y0, altFn, { inclina = 0.25, linhas = 4, relevo = 1.2, tile = 8 } = {}) {
  const cols = i1 - i0 + 1, rows = linhas + 1;
  const pos = new Float32Array(cols * rows * 3), uv = new Float32Array(cols * rows * 2), idx = [];
  for (let c = 0; c < cols; c++) {
    const i = i0 + c, p = centro[i], r = direita(p.h), lat0 = latFn(i), alt = altFn(i);
    for (let k = 0; k < rows; k++) {
      const t = k / linhas, y = y0 + alt * t;
      const jit = (k > 0 && k < linhas) ? Math.sin(i * 1.31 + k * 2.7) * relevo : 0;
      const lat = lat0 + lado * ((y - y0) * inclina + jit);
      const o = c * rows + k;
      pos.set([p.x + r.x * lat, y, p.z + r.z * lat], o * 3);
      uv.set([(i * L) / tile, (y - y0) / tile], o * 2);
      if (c < cols - 1 && k < linhas) idx.push(o, o + rows, o + 1, o + rows, o + rows + 1, o + 1);
    }
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  g.setAttribute('uv', new THREE.BufferAttribute(uv, 2));
  g.setIndex(idx);
  g.computeVertexNormals();
  return g;
}
// vertex colors numa geometria (com `neve`, o que fica acima de `acima` é branco)
function pintarGeo(geo, cor, neve) {
  const c = new THREE.Color(cor), b = neve ? new THREE.Color(neve.cor) : null;
  const n = geo.attributes.position.count, arr = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) {
    const cc = (b && geo.attributes.position.getY(i) >= neve.acima) ? b : c;
    arr[i * 3] = cc.r; arr[i * 3 + 1] = cc.g; arr[i * 3 + 2] = cc.b;
  }
  geo.setAttribute('color', new THREE.BufferAttribute(arr, 3));
  return geo;
}
// funde geometrias (position/normal/color) numa só, não indexada
function fundirCores(geos) {
  const ns = geos.map((g) => (g.index ? g.toNonIndexed() : g));
  let nv = 0;
  for (const g of ns) nv += g.attributes.position.count;
  const pos = new Float32Array(nv * 3), nor = new Float32Array(nv * 3), col = new Float32Array(nv * 3);
  let o = 0;
  for (const g of ns) {
    if (!g.attributes.normal) g.computeVertexNormals();
    pos.set(g.attributes.position.array, o * 3);
    nor.set(g.attributes.normal.array, o * 3);
    if (g.attributes.color) col.set(g.attributes.color.array, o * 3); else col.fill(1, o * 3, (o + g.attributes.position.count) * 3);
    o += g.attributes.position.count;
  }
  for (const g of new Set([...geos, ...ns])) g.dispose();
  const out = new THREE.BufferGeometry();
  out.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  out.setAttribute('normal', new THREE.BufferAttribute(nor, 3));
  out.setAttribute('color', new THREE.BufferAttribute(col, 3));
  return out;
}
// pontos ao longo da pista dos dois lados (ou de um), respeitando água/lava/paredão e o lado de dentro das curvas
function lotesAoLongo(passo, semente, { lados = [-1, 1], perto = 4.5, longe = 36, pular = 0.25 } = {}) {
  const r = rndDe(semente), total = centro.length * L, lotes = [];
  for (let d = 20; d < total - 30; d += passo * (0.6 + r() * 0.8)) {
    for (const lado of lados) {
      if (r() < pular) continue;
      const t = r(), giro = r() * Math.PI * 2;
      let afast = MEIA_PISTA + perto + r() * longe;
      const lim = Math.min(limiteLado(lado), alcanceLateral(Math.floor(d / L), lado, Infinity));
      if (afast > lim) {
        if (lim < MEIA_PISTA + perto + 1) continue;
        afast = MEIA_PISTA + perto + (lim - MEIA_PISTA - perto) * t;
      }
      lotes.push({ d, lado, afast, giro, t });
    }
  }
  return lotes;
}
function ladosDe(spec) { return [-1, 1].filter((l) => !spec || spec === 'ambos' || cobreLado(spec, l)); }
// InstancedMesh por trecho de 160 m (o culling por distância descarta o resto)
function instanciarPorTrecho(geo, mat, lotes, efeito, { estrutura = false, comCor = true, escala = (l) => 0.75 + l.t * 0.6 } = {}) {
  const porChunk = new Map();
  lotes.forEach((l, idx) => {
    const c = Math.floor(l.d / TRECHO), metade = estrutura ? 0 : idx % 2, chave = c * 2 + metade;
    if (!porChunk.has(chave)) porChunk.set(chave, { c, metade, lista: [] });
    porChunk.get(chave).lista.push(l);
  });
  const m4 = new THREE.Matrix4(), q4 = new THREE.Quaternion(), pV = new THREE.Vector3(), eV = new THREE.Vector3(), eu = new THREE.Euler(), cor = new THREE.Color();
  for (const { c, metade, lista } of porChunk.values()) {
    const inst = new THREE.InstancedMesh(geo, mat, lista.length);
    lista.forEach((l, k) => {
      const q = pose(l.d), r = direita(q.h);
      pV.set(q.x + r.x * l.afast * l.lado, l.y || 0, q.z + r.z * l.afast * l.lado);
      eu.set(0, l.giro, 0); q4.setFromEuler(eu);
      const s = escala(l);
      eV.set(s, s * (l.escY || 1), s);
      m4.compose(pV, q4, eV);
      inst.setMatrixAt(k, m4);
      if (comCor && l.cor != null) inst.setColorAt(k, cor.setHex(l.cor));
    });
    inst.instanceMatrix.needsUpdate = true;
    if (inst.instanceColor) inst.instanceColor.needsUpdate = true;
    inst.userData.d = (c + 0.5) * TRECHO;
    inst.userData.metade = metade;
    inst.castShadow = !estrutura && nivelQualidade === 'alta';
    inst.receiveShadow = true;
    inst.visible = false;
    inst.computeBoundingSphere();
    adicionarExtra(inst, efeito);
    (estrutura ? extrasEstrutura : extrasCenario).push(inst);
  }
  descartar(geo, mat);
}

// ---- 🌊 água (mar, lago, gelo): normal map procedural em canvas, rolando ----
function texturaOndas(semente, suave) {
  const ct = canvasTex(256, 256, (ctx, w, h) => {
    const r = rndDe(semente);
    const ondas = [];
    for (let k = 0; k < 6; k++) ondas.push({ fx: 1 + Math.floor(r() * 6), fy: 1 + Math.floor(r() * 6) * (r() < 0.5 ? -1 : 1), fase: r() * 6.283, amp: 1 / (k + 1) });
    const alt = (x, y) => { let s = 0; for (const o of ondas) s += o.amp * Math.sin(6.283 * (o.fx * x / w + o.fy * y / h) + o.fase); return s; };
    const img = ctx.createImageData(w, h), d = img.data, forca = suave ? 0.5 : 2.0;
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        const nx = -(alt(x + 1, y) - alt(x - 1, y)) * forca, ny = -(alt(x, y + 1) - alt(x, y - 1)) * forca;
        const l = Math.hypot(nx, ny, 1), o = (y * w + x) * 4;
        d[o] = (nx / l * 0.5 + 0.5) * 255; d[o + 1] = (ny / l * 0.5 + 0.5) * 255; d[o + 2] = (1 / l * 0.5 + 0.5) * 255; d[o + 3] = 255;
      }
    }
    ctx.putImageData(img, 0, 0);
  });
  ct.tex.colorSpace = THREE.NoColorSpace; // normal map é dado, não cor
  ct.tex.wrapS = ct.tex.wrapT = THREE.RepeatWrapping;
  return ct.tex;
}
function materialAgua(a) {
  const gelo = !!a.gelo;
  const nor = texturaOndas(gelo ? 23 : 7, gelo);
  const m = new THREE.MeshStandardMaterial({
    color: a.cor,
    metalness: a.metal != null ? a.metal : (gelo ? 0.2 : 0.9),
    roughness: a.rugosidade != null ? a.rugosidade : (gelo ? 0.12 : 0.06),
    normalMap: nor,
    normalScale: new THREE.Vector2(gelo ? 0.25 : 0.8, gelo ? 0.25 : 0.8),
    polygonOffset: true, polygonOffsetFactor: 1, polygonOffsetUnits: 1,
  });
  descartar(nor, m);
  marcarEfeito(gelo ? 'gelo' : 'agua');
  // o mar mexe; o gelo fica parado
  if (!gelo) extrasAnim.push((dt) => { nor.offset.x += dt * 0.012; nor.offset.y += dt * 0.02; });
  return m;
}
// traçado sinuoso volta perto de si mesmo: até onde a faixa lateral de cada
// ponto vai sem invadir OUTRO trecho da pista. Para antes da pista vizinha
// menos a margem seca dela; se o lado vizinho também tem água, para no meio
// (duas faixas no mesmo plano dariam z-fighting). Força bruta: ~2 mil
// pontos, ~20 ms uma vez por montagem.
function cortePorOutrosTrechos(lado, margem, quer, aguaDoLado) {
  const n = centro.length, excl = Math.ceil((margem + 40) / L), lim = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    const p = centro[i], nx = Math.cos(p.h) * lado, nz = Math.sin(p.h) * lado;
    const tx = Math.sin(p.h), tz = -Math.cos(p.h);
    let m = quer;
    for (let j = 0; j < n; j++) {
      if (Math.abs(j - i) < excl) continue;
      const q = centro[j], vx = q.x - p.x, vz = q.z - p.z, t = vx * nx + vz * nz;
      if (t <= 0 || Math.min(t / 2, t - margem) >= m) continue;
      const perp = Math.abs(vx * tx + vz * tz);
      if (perp >= margem) continue;
      const ladoViz = (p.x - q.x) * Math.cos(q.h) + (p.z - q.z) * Math.sin(q.h) >= 0 ? 1 : -1;
      const corte = aguaDoLado(ladoViz) ? t / 2 : t - Math.sqrt(margem * margem - perp * perp);
      if (corte < m) m = corte;
    }
    lim[i] = m;
  }
  // mínimo em ±2 pontos: a margem não serrilha
  const out = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    let m = lim[i];
    for (let j = Math.max(0, i - 2); j <= Math.min(n - 1, i + 2); j++) m = Math.min(m, lim[j]);
    out[i] = m;
  }
  return out;
}
function construirAgua(a) {
  if (a.plano) return; // a ponte já trocou o chão pelo mar (construirPista)
  const m = materialAgua(a);
  const ate = MEIA_PISTA + 400, ini = MEIA_PISTA + a.dist;
  for (const lado of [-1, 1]) {
    if (!cobreLado(a.lados, lado)) continue;
    const corte = cortePorOutrosTrechos(lado, ini, ate, (l) => cobreLado(a.lados, l));
    // curva fechada: no mínimo 6 m de água; outro trecho perto: pode zerar
    const longe = (i) => lado * Math.max(ini, Math.min(Math.max(ini + 6, alcanceLateral(i, lado, ate)), corte[i]));
    const geo = lado < 0 ? faixaGeo(longe, -ini, -0.015, -0.015, 20, (ate - ini) / 20) : faixaGeo(ini, longe, -0.015, -0.015, 20, (ate - ini) / 20);
    const mesh = new THREE.Mesh(geo, m);
    mesh.receiveShadow = true;
    adicionarExtra(mesh);
    descartar(geo);
  }
}
// 🌉 tabuleiro da ponte: laje sob a pista (portais e guard-rails apoiados), saias e pilares no mar
function construirPonte(tema) {
  const n = centro.length, meia = MEIA_PISTA + 2.9;
  const concreto = new THREE.MeshStandardMaterial({ color: 0x9aa0a6, roughness: 0.9, polygonOffset: true, polygonOffsetFactor: 2, polygonOffsetUnits: 2 });
  const laje = faixaGeo(-meia, meia, -0.03, -0.03, 8);
  adicionarExtra(new THREE.Mesh(laje, concreto), 'ponte').receiveShadow = true;
  const saiaMat = new THREE.MeshStandardMaterial({ color: 0x80868c, roughness: 0.85, side: THREE.DoubleSide });
  const porTrecho = Math.max(2, Math.round(TRECHO / L));
  for (const lado of [-1, 1]) {
    for (let i0 = 0; i0 < n - 1; i0 += porTrecho) {
      const i1 = Math.min(n - 1, i0 + porTrecho);
      const geo = paredeGeo(i0, i1, () => lado * meia, lado, -1.6, () => 1.57, { inclina: 0, linhas: 1, relevo: 0 });
      const mesh = adicionarExtra(new THREE.Mesh(geo, saiaMat));
      mesh.userData.d = ((i0 + i1) / 2) * L; mesh.userData.metade = 0;
      extrasLongos.push(mesh);
      descartar(geo);
    }
  }
  descartar(laje, concreto, saiaMat);
}
function construirPilares(pl, plano) {
  const base = plano ? NIVEL_MAR_PONTE : -0.04, topo = -1.6, alt = topo - base;
  const total = centro.length * L, estacoes = [];
  for (let d = 30; d < total - 20; d += pl.passo) estacoes.push(d);
  if (!estacoes.length || alt <= 0) return;
  const mat = new THREE.MeshStandardMaterial({ color: pl.cor, roughness: 0.8 });
  const pilarGeo = new THREE.BoxGeometry(1.3, alt, 1.6);
  const vigaGeo = new THREE.BoxGeometry((MEIA_PISTA + 2.9) * 2, 0.9, 1.8);
  const pilares = new THREE.InstancedMesh(pilarGeo, mat, estacoes.length * 2);
  const vigas = new THREE.InstancedMesh(vigaGeo, mat, estacoes.length);
  const m4 = new THREE.Matrix4(), q4 = new THREE.Quaternion(), um = new THREE.Vector3(1, 1, 1), pV = new THREE.Vector3(), eu = new THREE.Euler();
  estacoes.forEach((d, k) => {
    const q = pose(d), r = direita(q.h);
    eu.set(0, -q.h, 0); q4.setFromEuler(eu);
    for (const [j, lado] of [[0, -1], [1, 1]]) {
      const lat = lado * (MEIA_PISTA - 0.5);
      pV.set(q.x + r.x * lat, base + alt / 2, q.z + r.z * lat);
      pilares.setMatrixAt(k * 2 + j, m4.compose(pV, q4, um));
    }
    pV.set(q.x, topo - 0.45, q.z);
    vigas.setMatrixAt(k, m4.compose(pV, q4, um));
  });
  for (const im of [pilares, vigas]) { im.instanceMatrix.needsUpdate = true; im.computeBoundingSphere(); im.receiveShadow = true; adicionarExtra(im, 'pilares'); }
  descartar(mat, pilarGeo, vigaGeo);
}
// ---- 🏜️ paredões do cânion: rocha tingida, em gomos por trecho ----
function construirMuros(mu) {
  const mat = materialPbr('dark_rock', { tinta: mu.cor });
  mat.side = THREE.DoubleSide;
  descartar(mat, mat.map, mat.normalMap, mat.aoMap);
  const n = centro.length, porTrecho = Math.max(2, Math.round(TRECHO / L));
  const ruido = (i, lado) => 0.72 + 0.28 * Math.sin(i * 0.37 + lado * 1.7) * Math.sin(i * 0.113 + lado);
  for (const lado of [-1, 1]) {
    for (let i0 = 0; i0 < n - 1; i0 += porTrecho) {
      const i1 = Math.min(n - 1, i0 + porTrecho);
      const geo = paredeGeo(i0, i1, (i) => lado * alcanceLateral(i, lado, MEIA_PISTA + mu.dist), lado, -0.5, (i) => mu.altura * ruido(i, lado));
      const mesh = adicionarExtra(new THREE.Mesh(geo, mat), 'muros');
      mesh.receiveShadow = true;
      mesh.userData.d = ((i0 + i1) / 2) * L; mesh.userData.metade = 0;
      extrasLongos.push(mesh);
      descartar(geo);
    }
  }
}
// ---- 🌋 rio de lava: faixa emissiva que pulsa ----
function construirLava(lv) {
  const tex = canvasTex(256, 256, (ctx, w, h) => {
    ctx.fillStyle = '#1a0603'; ctx.fillRect(0, 0, w, h);
    const r = rndDe(41);
    ctx.lineCap = 'round';
    for (let k = 0; k < 26; k++) {
      let x = r() * w, y = r() * h;
      ctx.strokeStyle = `rgba(255,${120 + Math.floor(r() * 110)},40,${0.55 + r() * 0.45})`;
      ctx.lineWidth = 3 + r() * 9;
      ctx.beginPath(); ctx.moveTo(x, y);
      for (let s = 0; s < 6; s++) { x += (r() - 0.5) * 70; y += r() * 50; ctx.lineTo(x, y); }
      ctx.stroke();
    }
    const g = ctx.createRadialGradient(w / 2, h / 2, 10, w / 2, h / 2, w * 0.7);
    g.addColorStop(0, 'rgba(255,170,60,0.35)'); g.addColorStop(1, 'rgba(255,90,20,0.05)');
    ctx.fillStyle = g; ctx.fillRect(0, 0, w, h);
  }).tex;
  tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
  const mat = new THREE.MeshStandardMaterial({ color: 0x2a120a, roughness: 0.9, emissive: lv.cor, emissiveMap: tex, emissiveIntensity: 1.2, map: tex, polygonOffset: true, polygonOffsetFactor: -1 });
  descartar(tex, mat);
  for (const lado of [-1, 1]) {
    if (!cobreLado(lv.lado, lado)) continue;
    const a = MEIA_PISTA + lv.dist, b = a + lv.largura;
    const geo = lado < 0 ? faixaGeo(-b, -a, 0.03, 0.03, 16, lv.largura / 16) : faixaGeo(a, b, 0.03, 0.03, 16, lv.largura / 16);
    adicionarExtra(new THREE.Mesh(geo, mat), 'lava');
    descartar(geo);
  }
  extrasAnim.push((dt, t) => {
    mat.emissiveIntensity = 1.2 + 0.4 * Math.sin(t * 2.1) * (reduzirMovimento() ? 0.3 : 1);
    tex.offset.y -= dt * 0.03;
  });
}
// ---- 🌲 pinheiros, 🌴 palmeiras e 🍁 árvores de outono (instanciados, gate do perfil) ----
function geoPinheiro(cor, neve) {
  const partes = [pintarGeo(new THREE.CylinderGeometry(0.18, 0.26, 2.0, 6).translate(0, 1.0, 0), 0x5b3b26)];
  for (const [raio, alt, y] of [[2.6, 4.2, 1.6], [2.0, 3.4, 3.6], [1.3, 2.8, 5.4]]) {
    const cone = new THREE.ConeGeometry(raio, alt, 8, neve ? 3 : 1).translate(0, y + alt / 2, 0);
    partes.push(pintarGeo(cone, cor, neve ? { acima: y + alt * 0.6, cor: 0xf2f7fb } : null));
  }
  return fundirCores(partes);
}
function construirPinheiros(p) {
  if (!perfilAtual.cenario) return;
  const geo = geoPinheiro(p.cor != null ? p.cor : 0x2f5d46, !!p.neve);
  const mat = new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.9, flatShading: true });
  const lotes = lotesAoLongo(p.passo, 61, { perto: 5, longe: 40, pular: 0.15 });
  for (const l of lotes) l.escY = 0.85 + ((l.giro * 7) % 1) * 0.5;
  instanciarPorTrecho(geo, mat, lotes, 'pinheiros', { escala: (l) => 0.7 + l.t * 0.7 });
}
function geoPalmeira() {
  const tronco = new THREE.CylinderGeometry(0.16, 0.27, 7, 7, 8, true).translate(0, 3.5, 0);
  const tp = tronco.attributes.position;
  for (let i = 0; i < tp.count; i++) { const y = tp.getY(i); tp.setX(i, tp.getX(i) + 0.045 * y * y); }
  tronco.computeVertexNormals();
  const partes = [pintarGeo(tronco, 0x8a6a45)];
  const topoX = 0.045 * 49, topoY = 7;
  for (let k = 0; k < 6; k++) {
    const folha = new THREE.PlaneGeometry(0.9, 4.2, 1, 6).translate(0, 2.1, 0);
    const fp = folha.attributes.position;
    for (let i = 0; i < fp.count; i++) { const t = fp.getY(i) / 4.2; fp.setZ(i, -t * t * 1.8); fp.setX(i, fp.getX(i) * (1 - t * 0.75)); }
    folha.rotateX(-Math.PI / 2 + 0.4).rotateY((k * Math.PI * 2) / 6 + 0.3).translate(topoX, topoY, 0);
    folha.computeVertexNormals();
    partes.push(pintarGeo(folha, k % 2 ? 0x2f7d32 : 0x3f8f3a));
  }
  return fundirCores(partes);
}
function construirPalmeiras(p) {
  if (!perfilAtual.cenario) return;
  const mat = new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.8, side: THREE.DoubleSide });
  instanciarPorTrecho(geoPalmeira(), mat, lotesAoLongo(p.passo, 67, { lados: ladosDe(p.lado), perto: 4, longe: 24, pular: 0.1 }), 'palmeiras');
}
function construirArvoresOutono(a) {
  if (!perfilAtual.cenario) return;
  const cores = a.cores && a.cores.length ? a.cores : [0xd9531e, 0xf2a03d, 0xb83a1b];
  const lotes = lotesAoLongo(a.passo, 71, { perto: 5, longe: 38, pular: 0.15 });
  lotes.forEach((l, k) => { l.cor = cores[k % cores.length]; });
  const tronco = new THREE.CylinderGeometry(0.22, 0.34, 3.6, 7).translate(0, 1.8, 0);
  const troncoMat = new THREE.MeshStandardMaterial({ color: 0x5a3a24, roughness: 0.95 });
  const copa = new THREE.IcosahedronGeometry(2.5, 1).translate(0, 5.0, 0);
  const copaMat = new THREE.MeshStandardMaterial({ color: 0xffffff, roughness: 0.85, flatShading: true });
  instanciarPorTrecho(tronco, troncoMat, lotes, 'arvoresOutono', { comCor: false });
  instanciarPorTrecho(copa, copaMat, lotes, 'arvoresOutono');
}
// ---- 🏟️ arquibancadas com público (pontos coloridos) ----
function construirArquibancadas(a) {
  const total = centro.length * L, cores = a.cores && a.cores.length ? a.cores : [0xd32f2f, 0xffd54f, 0x1e88e5];
  const r = rndDe(31), porChunk = new Map();
  const corPublico = [0xffffff, 0xffd54f, 0xe53935, 0x42a5f5, 0x66bb6a, 0xff7043, 0xab47bc];
  let lado = 1;
  for (let d = 120; d < total - 120; d += a.passo) {
    lado = -lado;
    const c = Math.floor(d / TRECHO);
    if (!porChunk.has(c)) porChunk.set(c, { geos: [], pos: [], cor: [] });
    const ch = porChunk.get(c);
    const comp = 34, degraus = 5, alt = 1.1, prof = 1.7, afast = MEIA_PISTA + 10;
    const q = pose(d), rr = direita(q.h);
    const M = new THREE.Matrix4().makeRotationY(-q.h);
    M.setPosition(q.x + rr.x * afast * lado, 0, q.z + rr.z * afast * lado);
    const corAssento = cores[Math.floor(r() * cores.length)];
    for (let k = 0; k < degraus; k++) {
      const bx = new THREE.BoxGeometry(prof, alt * (k + 1), comp).translate(lado * (k * prof + prof / 2), (alt * (k + 1)) / 2, 0);
      ch.geos.push(pintarGeo(bx, k % 2 ? corAssento : 0xb0b6bc).applyMatrix4(M));
      for (let s = 0; s < 34; s++) {
        if (r() < 0.2) continue;
        const v = new THREE.Vector3(lado * (k * prof + prof * 0.45), alt * (k + 1) + 0.45, -comp / 2 + 0.5 + s * ((comp - 1) / 33)).applyMatrix4(M);
        ch.pos.push(v.x, v.y, v.z);
        const cc = new THREE.Color(corPublico[Math.floor(r() * corPublico.length)]);
        ch.cor.push(cc.r, cc.g, cc.b);
      }
    }
    const teto = new THREE.BoxGeometry(degraus * prof + 1.2, 0.35, comp + 1).translate(lado * (degraus * prof) / 2, degraus * alt + 3.2, 0);
    ch.geos.push(pintarGeo(teto, 0x263238).applyMatrix4(M));
    for (const z of [-comp / 2, 0, comp / 2]) {
      const coluna = new THREE.BoxGeometry(0.3, degraus * alt + 3.2, 0.3).translate(lado * (degraus * prof + 0.3), (degraus * alt + 3.2) / 2, z);
      ch.geos.push(pintarGeo(coluna, 0x37474f).applyMatrix4(M));
    }
  }
  const mat = new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.8 });
  const ptMat = new THREE.PointsMaterial({ size: 0.55, vertexColors: true, map: texturaPonto(), transparent: true, alphaTest: 0.3, depthWrite: true });
  descartar(mat, ptMat);
  for (const [c, ch] of porChunk) {
    const geo = fundirCores(ch.geos);
    const mesh = adicionarExtra(new THREE.Mesh(geo, mat), 'arquibancadas');
    mesh.receiveShadow = true; mesh.castShadow = nivelQualidade === 'alta';
    const pg = new THREE.BufferGeometry();
    pg.setAttribute('position', new THREE.BufferAttribute(new Float32Array(ch.pos), 3));
    pg.setAttribute('color', new THREE.BufferAttribute(new Float32Array(ch.cor), 3));
    const publico = adicionarExtra(new THREE.Points(pg, ptMat));
    for (const o of [mesh, publico]) { o.userData.d = (c + 0.5) * TRECHO; o.userData.metade = 0; o.visible = false; extrasEstrutura.push(o); }
    descartar(geo, pg);
  }
}
// ---- 🧱 muretas de concreto (perfil "New Jersey" procedural, 28 triângulos cada) ----
// O modelo do Poly Haven (concrete_road_barrier) tem ~61 mil triângulos POR mureta: com passo de 12 m
// e os dois lados, a pista 30 desenhava 6–10 milhões de triângulos por quadro (contra ~0,4 mi nas outras),
// pesado demais para a máquina fraca. O perfil extrudado tem a mesma silhueta vista do carro.
async function construirMuretas(mu) {
  if (!perfilAtual.cenario) return;
  const perfil = new THREE.Shape();
  perfil.moveTo(-0.30, 0); perfil.lineTo(0.30, 0); perfil.lineTo(0.30, 0.08); perfil.lineTo(0.12, 0.33);
  perfil.lineTo(0.08, 0.81); perfil.lineTo(-0.08, 0.81); perfil.lineTo(-0.12, 0.33); perfil.lineTo(-0.30, 0.08);
  perfil.closePath();
  const geo = new THREE.ExtrudeGeometry(perfil, { depth: 1.55, bevelEnabled: false });
  geo.translate(0, 0, -0.775); // centrada; o comprimento (z) acompanha a pista
  const mat = new THREE.MeshStandardMaterial({ color: 0xbdb8ae, roughness: 0.92, metalness: 0 });
  const malhas = [{ geometry: geo, material: mat, matrixWorld: new THREE.Matrix4() }];
  const esc = 1, giroExtra = 0, caixa = { min: { y: 0 } };
  const lotes = [];
  const total = centro.length * L;
  for (let d = 24; d < total - 24; d += mu.passo) for (const lado of [-1, 1]) lotes.push({ d, lado });
  const porTrecho = new Map();
  for (const l of lotes) { const c = Math.floor(l.d / TRECHO); if (!porTrecho.has(c)) porTrecho.set(c, []); porTrecho.get(c).push(l); }
  const m4 = new THREE.Matrix4(), q4 = new THREE.Quaternion(), pV = new THREE.Vector3(), eV = new THREE.Vector3(esc, esc, esc), eu = new THREE.Euler();
  for (const [c, lista] of porTrecho) {
    for (const m of malhas) {
      const inst = new THREE.InstancedMesh(m.geometry, m.material, lista.length);
      lista.forEach((l, k) => {
        const q = pose(l.d), r = direita(q.h), lat = l.lado * (MEIA_PISTA + 5);
        pV.set(q.x + r.x * lat, -caixa.min.y * esc, q.z + r.z * lat);
        eu.set(0, -q.h + giroExtra, 0); q4.setFromEuler(eu);
        m4.compose(pV, q4, eV).multiply(m.matrixWorld);
        inst.setMatrixAt(k, m4);
      });
      inst.instanceMatrix.needsUpdate = true;
      inst.userData.d = (c + 0.5) * TRECHO; inst.userData.metade = 0;
      inst.castShadow = nivelQualidade === 'alta'; inst.receiveShadow = true; inst.visible = false;
      inst.computeBoundingSphere();
      adicionarExtra(inst, 'muretas');
      extrasCenario.push(inst);
    }
  }
  for (const m of malhas) descartar(m.geometry, m.material);
}
// ---- 🌆 neon: filetes acesos em cima dos guard-rails ----
function construirFiletesNeon(nn) {
  for (const [lado, cor] of [[-1, nn.cores[0]], [1, nn.cores[1] != null ? nn.cores[1] : nn.cores[0]]]) {
    const lat = lado * (MEIA_PISTA + 2.2) - lado * 0.04;
    const geo = faixaGeo(lado < 0 ? lat : lat - 0.02, lado < 0 ? lat + 0.02 : lat, 0.8, 0.94, 8);
    const mat = new THREE.MeshBasicMaterial({ color: cor, side: THREE.DoubleSide });
    adicionarExtra(new THREE.Mesh(geo, mat), 'neon');
    descartar(geo, mat);
  }
}
// ---- ❄️🍁🌧️ partículas numa caixa que anda à frente da câmera ----
const PARTICULAS = {
  chuva: { cor: 0xaab8c8, vel: [-3, -26, 0], linhas: true, opac: 0.45, yMax: 40 },
  neve: { cor: 0xffffff, tam: 0.16, vel: [0, -2.2, 0], deriva: 1.2, opac: 0.9, yMax: 40 },
  folhas: { cores: [0xd9531e, 0xf2a03d, 0xb83a1b, 0xe8c547], tam: 0.34, vel: [0, -1.4, 0], deriva: 1.6, opac: 1, yMax: 22 },
  poeira: { cor: 0xd9a35c, tam: 0.9, vel: [9, -0.3, 0], deriva: 2, opac: 0.28, yMax: 14 },
  brasas: { cor: 0xff7a2a, tam: 0.22, vel: [0, 2.4, 0], deriva: 0.8, opac: 1, aditivo: true, yMax: 30 },
  vagalumes: { cor: 0xd8ff6a, tam: 0.3, vel: [0, 0, 0], deriva: 0.7, opac: 1, aditivo: true, pisca: true, yMax: 4.5, yMin: 0.3 },
};
function construirParticulas(p) {
  const def = PARTICULAS[p.tipo];
  if (!def) { console.warn('[turismo3d] partículas desconhecidas:', p.tipo); return; }
  const max = Math.max(1, Math.round(p.qtd || 500));
  const HX = 70, HZ = 80, yMin = def.yMin || 0, yMax = def.yMax || 40;
  const r = rndDe(13), q0 = pose(0);
  const base = new Float32Array(max * 3), fase = new Float32Array(max);
  for (let i = 0; i < max; i++) {
    base[i * 3] = q0.x + (r() * 2 - 1) * HX; base[i * 3 + 1] = yMin + r() * (yMax - yMin); base[i * 3 + 2] = q0.z + (r() * 2 - 1) * HZ;
    fase[i] = r() * 6.283;
  }
  const geo = new THREE.BufferGeometry();
  const pos = new THREE.BufferAttribute(new Float32Array(max * (def.linhas ? 6 : 3)), 3);
  pos.setUsage(THREE.DynamicDrawUsage);
  geo.setAttribute('position', pos);
  let obj, mat;
  if (def.linhas) {
    mat = new THREE.LineBasicMaterial({ color: p.cor != null ? p.cor : def.cor, transparent: true, opacity: def.opac, depthWrite: false });
    obj = new THREE.LineSegments(geo, mat);
  } else {
    const comCores = !!(def.cores || def.pisca);
    if (comCores) {
      const col = new Float32Array(max * 3), c = new THREE.Color();
      for (let i = 0; i < max; i++) { c.setHex(def.cores ? def.cores[i % def.cores.length] : (p.cor != null ? p.cor : def.cor)); col.set([c.r, c.g, c.b], i * 3); }
      const ca = new THREE.BufferAttribute(col, 3);
      if (def.pisca) ca.setUsage(THREE.DynamicDrawUsage);
      geo.setAttribute('color', ca);
    }
    mat = new THREE.PointsMaterial({
      size: def.tam, color: comCores ? 0xffffff : (p.cor != null ? p.cor : def.cor), vertexColors: comCores,
      map: texturaPonto(), transparent: true, opacity: def.opac, depthWrite: false,
      blending: def.aditivo ? THREE.AdditiveBlending : THREE.NormalBlending,
    });
    obj = new THREE.Points(geo, mat);
  }
  obj.frustumCulled = false;
  adicionarExtra(obj, 'particulas:' + p.tipo);
  descartar(geo, mat);
  const vel = def.vel, deriva = p.deriva != null ? p.deriva : (def.deriva || 0), alturaCaixa = yMax - yMin;
  const corBase = new THREE.Color(p.cor != null ? p.cor : def.cor);
  extrasAnim.push((dt, t, e, px, pz, f) => {
    const n = Math.max(1, Math.floor(max * (FATOR_QTD[nivelQualidade] || 1)));
    geo.setDrawRange(0, def.linhas ? n * 2 : n);
    const ax = px + f.x * 45, az = pz + f.z * 45; // a caixa vai à frente do carro
    const arr = pos.array;
    for (let i = 0; i < n; i++) {
      const o = i * 3, ph = fase[i];
      let x = base[o] + (vel[0] + Math.sin(t * 0.9 + ph) * deriva) * dt;
      let y = base[o + 1] + (vel[1] + (def.pisca ? Math.sin(t * 0.6 + ph * 2) * 0.4 : 0)) * dt;
      let z = base[o + 2] + (vel[2] + Math.cos(t * 0.7 + ph * 1.3) * deriva) * dt;
      while (x < ax - HX) x += 2 * HX; while (x > ax + HX) x -= 2 * HX;
      while (z < az - HZ) z += 2 * HZ; while (z > az + HZ) z -= 2 * HZ;
      if (y < yMin) y += alturaCaixa; else if (y > yMax) y -= alturaCaixa;
      base[o] = x; base[o + 1] = y; base[o + 2] = z;
      if (def.linhas) {
        const k = i * 6;
        arr[k] = x; arr[k + 1] = y; arr[k + 2] = z;
        arr[k + 3] = x - vel[0] * 0.035; arr[k + 4] = y - vel[1] * 0.035; arr[k + 5] = z - vel[2] * 0.035;
      } else { arr[o] = x; arr[o + 1] = y; arr[o + 2] = z; }
    }
    pos.needsUpdate = true;
    if (def.pisca) {
      // vagalumes: cada um acende e apaga no seu ritmo
      const c = geo.attributes.color.array;
      for (let i = 0; i < n; i++) {
        const b = Math.max(0, Math.sin(t * 2.2 + fase[i] * 3)), v = b * b;
        c[i * 3] = corBase.r * v; c[i * 3 + 1] = corBase.g * v; c[i * 3 + 2] = corBase.b * v;
      }
      geo.attributes.color.needsUpdate = true;
    }
  });
}
// ---- ⛈️ relâmpago (≤ 2 flashes/s; com reduzirMovimento, um clarão suave a cada ≥ 8 s) ----
function construirRelampago(rl) {
  const sortear = () => rl.min + Math.random() * Math.max(0, rl.max - rl.min);
  relampagoEstado = { prox: 3 + sortear(), anim: null, suave: false, k: 1 };
  marcarEfeito('relampago');
  extrasAnim.push((dt, t, e) => {
    const R = relampagoEstado;
    if (!R) return;
    if (e.pausado) { R.k = 1; return; }
    R.prox -= dt;
    if (R.anim == null && R.prox <= 0) {
      R.suave = reduzirMovimento();
      R.anim = 0;
      R.prox = R.suave ? Math.max(8, sortear()) : sortear();
      trovao(R.suave ? 0.5 : 1);
    }
    R.k = 1;
    if (R.anim != null) {
      const a = R.anim;
      if (R.suave) { R.k = a < 0.3 ? 1.25 : 1; if (a >= 0.3) R.anim = null; }
      else { R.k = a < 0.09 ? 1.6 : (a < 0.21 ? 1 : (a < 0.27 ? 1.3 : 1)); if (a >= 0.27) R.anim = null; }
      if (R.anim != null) R.anim += dt;
    }
  });
}
// trovão sintetizado: ruído grave, um tempo depois do clarão (respeita o som desligado)
let ruidoTrovao = null;
function trovao(forca) {
  if (!audioCtx || audioCtx.state !== 'running' || (estado && estado.som === false)) return;
  try {
    if (!ruidoTrovao) {
      const sr = audioCtx.sampleRate;
      ruidoTrovao = audioCtx.createBuffer(1, sr * 3, sr);
      const d = ruidoTrovao.getChannelData(0);
      let ult = 0;
      for (let i = 0; i < d.length; i++) { ult = ult * 0.97 + (Math.random() * 2 - 1) * 0.03; d[i] = ult * 9; }
    }
    const t0 = audioCtx.currentTime + 0.6 + Math.random() * 0.9;
    const src = audioCtx.createBufferSource(); src.buffer = ruidoTrovao;
    const filtro = audioCtx.createBiquadFilter(); filtro.type = 'lowpass'; filtro.frequency.value = 180;
    const g = audioCtx.createGain();
    g.gain.setValueAtTime(0, t0); g.gain.linearRampToValueAtTime(0.35 * forca, t0 + 0.12); g.gain.setTargetAtTime(0, t0 + 0.5, 0.6);
    src.connect(filtro); filtro.connect(g); g.connect(audioCtx.destination);
    src.start(t0); src.stop(t0 + 3);
  } catch (e) {}
}
// ---- 🎆 fogos: pool de 6 explosões × 120 pontos aditivos à frente do carro ----
function construirFogos(fg) {
  const N = 6, P = 120, total = N * P;
  const pos = new THREE.BufferAttribute(new Float32Array(total * 3), 3).setUsage(THREE.DynamicDrawUsage);
  const col = new THREE.BufferAttribute(new Float32Array(total * 3), 3).setUsage(THREE.DynamicDrawUsage);
  const vel = new Float32Array(total * 3);
  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', pos); geo.setAttribute('color', col);
  const mat = new THREE.PointsMaterial({ size: 0.9, vertexColors: true, map: texturaPonto(), transparent: true, depthWrite: false, blending: THREE.AdditiveBlending, fog: false });
  const pts = new THREE.Points(geo, mat);
  pts.frustumCulled = false;
  adicionarExtra(pts, 'fogos');
  descartar(geo, mat);
  const PALETA = [0xff3b3b, 0xffd54f, 0x4fc3ff, 0x7dff6a, 0xff6af0, 0xffffff];
  const explosoes = Array.from({ length: N }, () => ({ ativa: false, t: 0, cor: new THREE.Color() }));
  let prox = 1.5;
  extrasAnim.push((dt, t, e, px, pz, f) => {
    if (e.pausado) return;
    prox -= dt;
    if (prox <= 0) {
      prox = fg.intervalo * (reduzirMovimento() ? 2 : 1) * (0.7 + Math.random() * 0.6);
      const b = explosoes.findIndex((x) => !x.ativa);
      if (b >= 0) {
        const ex = explosoes[b];
        ex.ativa = true; ex.t = 0; ex.cor.setHex(PALETA[Math.floor(Math.random() * PALETA.length)]);
        const q = pose((e.posicao || 0) + 90 + Math.random() * 60), r = direita(q.h), lado = Math.random() < 0.5 ? -1 : 1, lat = lado * (15 + Math.random() * 40);
        const cx = q.x + r.x * lat, cy = 28 + Math.random() * 20, cz = q.z + r.z * lat;
        for (let i = 0; i < P; i++) {
          const k = (b * P + i) * 3;
          const u = Math.random() * 2 - 1, a = Math.random() * 6.283, s = Math.sqrt(1 - u * u), v = 9 + Math.random() * 5;
          vel[k] = s * Math.cos(a) * v; vel[k + 1] = u * v; vel[k + 2] = s * Math.sin(a) * v;
          pos.array[k] = cx; pos.array[k + 1] = cy; pos.array[k + 2] = cz;
        }
      }
    }
    for (let b = 0; b < N; b++) {
      const ex = explosoes[b];
      if (!ex.ativa) continue;
      ex.t += dt;
      const p = ex.t / 1.8;
      for (let i = 0; i < P; i++) {
        const k = (b * P + i) * 3;
        if (p >= 1) { col.array[k] = col.array[k + 1] = col.array[k + 2] = 0; continue; }
        vel[k + 1] -= 4.5 * dt;
        const arrasto = 1 - 1.2 * dt;
        vel[k] *= arrasto; vel[k + 1] *= arrasto; vel[k + 2] *= arrasto;
        pos.array[k] += vel[k] * dt; pos.array[k + 1] += vel[k + 1] * dt; pos.array[k + 2] += vel[k + 2] * dt;
        const brilho = Math.pow(1 - p, 1.5) * (0.75 + 0.25 * Math.sin(t * 30 + i));
        col.array[k] = ex.cor.r * brilho; col.array[k + 1] = ex.cor.g * brilho; col.array[k + 2] = ex.cor.b * brilho;
      }
      if (p >= 1) ex.ativa = false;
    }
    pos.needsUpdate = true; col.needsUpdate = true;
  });
}
// ---- 🌌 céu procedural (estrelas, aurora, Marte), estrelas e astro ----
function construirCeuProcedural(ceu) {
  const [topo, horiz] = ceu.cores || [0x0b1330, 0x24305e];
  const geo = new THREE.SphereGeometry(800, 32, 16);
  const mat = new THREE.ShaderMaterial({
    side: THREE.BackSide, depthWrite: false, fog: false,
    uniforms: { topo: { value: new THREE.Color(topo) }, horiz: { value: new THREE.Color(horiz) }, baixo: { value: new THREE.Color(horiz).multiplyScalar(0.55) } },
    vertexShader: 'varying vec3 vDir;\nvoid main() {\n  vDir = normalize(position);\n  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);\n}',
    fragmentShader: 'uniform vec3 topo;\nuniform vec3 horiz;\nuniform vec3 baixo;\nvarying vec3 vDir;\nvoid main() {\n  float h = normalize(vDir).y;\n  vec3 c = h > 0.0 ? mix(horiz, topo, pow(clamp(h, 0.0, 1.0), 0.55)) : mix(horiz, baixo, clamp(-h * 4.0, 0.0, 1.0));\n  gl_FragColor = vec4(c, 1.0);\n  #include <tonemapping_fragment>\n  #include <colorspace_fragment>\n}',
  });
  const esfera = new THREE.Mesh(geo, mat);
  esfera.frustumCulled = false;
  esfera.renderOrder = -2;
  adicionarExtra(esfera, 'ceu:' + ceu.procedural);
  descartar(geo, mat);
  scene.background = null; // a esfera cobre tudo; o environment segue o HDRI (escurecido por `env`)
  ceuSeguir.push((cam) => esfera.position.copy(cam.position));
  if (ceu.procedural !== 'marte') construirEstrelas(ESTRELAS_POR_NIVEL[nivelQualidade] || 800);
  if (ceu.procedural === 'aurora') construirAurora(ceu.aurora || [0x3dffa0, 0x9a6bff]);
}
function construirEstrelas(n) {
  const r = rndDe(77), pos = new Float32Array(n * 3), col = new Float32Array(n * 3), c = new THREE.Color();
  for (let i = 0; i < n; i++) {
    const a = r() * 6.283, y = 0.03 + Math.pow(r(), 0.8) * 0.97, s = Math.sqrt(1 - y * y), rad = 700;
    pos.set([Math.cos(a) * s * rad, y * rad, Math.sin(a) * s * rad], i * 3);
    const brilho = 0.45 + r() * 0.55, tom = r();
    c.setRGB(brilho * (tom < 0.15 ? 1 : 0.9), brilho * 0.92, brilho * (tom > 0.8 ? 1 : 0.85));
    col.set([c.r, c.g, c.b], i * 3);
  }
  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  const mat = new THREE.PointsMaterial({ size: 2.2, sizeAttenuation: false, vertexColors: true, map: texturaPonto(), transparent: true, depthWrite: false, fog: false });
  const pts = new THREE.Points(geo, mat);
  pts.frustumCulled = false;
  pts.renderOrder = -1;
  adicionarExtra(pts, 'estrelas');
  descartar(geo, mat);
  ceuSeguir.push((cam) => pts.position.copy(cam.position));
}
function construirAurora(cores) {
  for (let k = 0; k < 2; k++) {
    const geo = new THREE.PlaneGeometry(900, 160, 96, 1);
    const p = geo.attributes.position;
    for (let i = 0; i < p.count; i++) {
      const x = p.getX(i), y = p.getY(i), ang = (x / 900) * 1.7, rad = 620 - k * 70;
      p.setXYZ(i, Math.sin(ang) * rad + Math.sin(x * 0.012 + k) * 30, 150 + k * 45 + (y + 80) * 0.9 + Math.sin(x * 0.01 + k * 2) * 22, -Math.cos(ang) * rad);
    }
    const mat = new THREE.ShaderMaterial({
      transparent: true, depthWrite: false, side: THREE.DoubleSide, blending: THREE.AdditiveBlending, fog: false,
      uniforms: { tempo: { value: 0 }, corA: { value: new THREE.Color(cores[0]) }, corB: { value: new THREE.Color(cores[1] != null ? cores[1] : cores[0]) }, fase: { value: k * 1.7 } },
      vertexShader: 'varying vec2 vUv;\nvoid main() {\n  vUv = uv;\n  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);\n}',
      fragmentShader: 'uniform float tempo;\nuniform float fase;\nuniform vec3 corA;\nuniform vec3 corB;\nvarying vec2 vUv;\nvoid main() {\n  float faixa = smoothstep(0.0, 0.3, vUv.y) * (1.0 - smoothstep(0.45, 1.0, vUv.y));\n  float cortina = 0.55 + 0.45 * sin(vUv.x * 38.0 + tempo * 0.9 + fase) * sin(vUv.x * 11.0 - tempo * 0.4);\n  float bordas = smoothstep(0.0, 0.12, vUv.x) * (1.0 - smoothstep(0.88, 1.0, vUv.x));\n  vec3 c = mix(corA, corB, vUv.y);\n  gl_FragColor = vec4(c * faixa * cortina * bordas * 0.9, 1.0);\n  #include <colorspace_fragment>\n}',
    });
    const fita = new THREE.Mesh(geo, mat);
    fita.rotation.y = k * 0.9 - 0.3;
    fita.frustumCulled = false;
    fita.renderOrder = -1;
    adicionarExtra(fita, 'aurora');
    descartar(geo, mat);
    ceuSeguir.push((cam) => fita.position.copy(cam.position));
    extrasAnim.push((dt) => { mat.uniforms.tempo.value += dt * (reduzirMovimento() ? 0.3 : 1); });
  }
}
function texturaAstro(tipo) {
  const largo = tipo === 'luas2';
  return canvasTex(largo ? 512 : 256, 256, (ctx, w, h) => {
    ctx.clearRect(0, 0, w, h);
    const r = rndDe(tipo === 'terra' ? 3 : 9);
    const disco = (cx, cy, raio, pintar) => { ctx.save(); ctx.beginPath(); ctx.arc(cx, cy, raio, 0, Math.PI * 2); ctx.clip(); pintar(); ctx.restore(); };
    if (tipo === 'terra') {
      const cx = w / 2, cy = h / 2, raio = w * 0.4;
      const halo = ctx.createRadialGradient(cx, cy, raio * 0.95, cx, cy, raio * 1.22);
      halo.addColorStop(0, 'rgba(120,180,255,0.55)'); halo.addColorStop(1, 'rgba(120,180,255,0)');
      ctx.fillStyle = halo; ctx.fillRect(0, 0, w, h);
      disco(cx, cy, raio, () => {
        ctx.fillStyle = '#1f5fae'; ctx.fillRect(0, 0, w, h);
        for (let k = 0; k < 9; k++) {
          ctx.fillStyle = k % 3 ? '#3f8f4a' : '#a88a52';
          ctx.beginPath(); ctx.ellipse(cx + (r() - 0.5) * raio * 1.6, cy + (r() - 0.5) * raio * 1.5, raio * (0.12 + r() * 0.25), raio * (0.08 + r() * 0.18), r() * 3, 0, Math.PI * 2); ctx.fill();
        }
        ctx.fillStyle = 'rgba(255,255,255,0.75)';
        for (let k = 0; k < 14; k++) { ctx.beginPath(); ctx.ellipse(cx + (r() - 0.5) * raio * 1.8, cy + (r() - 0.5) * raio * 1.8, raio * (0.1 + r() * 0.3), raio * 0.04, r() * 0.6 - 0.3, 0, Math.PI * 2); ctx.fill(); }
        const sombra = ctx.createLinearGradient(cx - raio, cy, cx + raio, cy);
        sombra.addColorStop(0, 'rgba(0,0,10,0)'); sombra.addColorStop(0.62, 'rgba(0,0,10,0.05)'); sombra.addColorStop(1, 'rgba(0,0,10,0.85)');
        ctx.fillStyle = sombra; ctx.fillRect(0, 0, w, h);
      });
    } else {
      const luas = largo ? [[w * 0.3, h * 0.55, h * 0.3], [w * 0.74, h * 0.38, h * 0.16]] : [[w / 2, h / 2, w * 0.42]];
      for (const [cx, cy, raio] of luas) {
        const brilho = ctx.createRadialGradient(cx, cy, raio * 0.9, cx, cy, raio * 1.35);
        brilho.addColorStop(0, largo ? 'rgba(255,200,170,0.25)' : 'rgba(230,240,255,0.45)'); brilho.addColorStop(1, 'rgba(230,240,255,0)');
        ctx.fillStyle = brilho; ctx.fillRect(0, 0, w, h);
        disco(cx, cy, raio, () => {
          const g = ctx.createRadialGradient(cx - raio * 0.3, cy - raio * 0.3, raio * 0.1, cx, cy, raio);
          g.addColorStop(0, largo ? '#c9a48c' : '#f4f4ee'); g.addColorStop(1, largo ? '#6e5446' : '#a9adb3');
          ctx.fillStyle = g; ctx.fillRect(0, 0, w, h);
          for (let k = 0; k < 12; k++) {
            ctx.fillStyle = `rgba(80,80,90,${0.12 + r() * 0.2})`;
            ctx.beginPath(); ctx.arc(cx + (r() - 0.5) * raio * 1.5, cy + (r() - 0.5) * raio * 1.5, raio * (0.05 + r() * 0.16), 0, Math.PI * 2); ctx.fill();
          }
        });
      }
    }
  }).tex;
}
function construirAstro(a) {
  const tex = texturaAstro(a.tipo);
  const mat = new THREE.SpriteMaterial({ map: tex, fog: false, depthWrite: false, transparent: true });
  const sp = new THREE.Sprite(mat);
  const dir = new THREE.Vector3(...(a.dir || [0.3, 0.45, -1])).normalize();
  const tam = a.tam || 60;
  sp.scale.set(a.tipo === 'luas2' ? tam * 2 : tam, tam, 1);
  sp.renderOrder = -1;
  sp.frustumCulled = false;
  adicionarExtra(sp, 'astro:' + a.tipo);
  descartar(tex, mat);
  ceuSeguir.push((cam) => sp.position.copy(cam.position).addScaledVector(dir, 600));
}
function aplicarCeu(tema) {
  const ceu = tema.ceu;
  if (!ceu || !scene) return;
  if (ceu.intensidade != null) scene.backgroundIntensity = ceu.intensidade;
  if (ceu.rotacao != null) {
    if (scene.backgroundRotation) scene.backgroundRotation.set(0, ceu.rotacao, 0);
    if (scene.environmentRotation) scene.environmentRotation.set(0, ceu.rotacao, 0);
  }
  if (ceu.desfoque != null) scene.backgroundBlurriness = ceu.desfoque;
  if (ceu.env != null) scene.environmentIntensity = ceu.env;
  if (ceu.procedural) construirCeuProcedural(ceu);
  marcarEfeito('ceu');
}
// monta o que o tema pedir (síncrono; as muretas entram depois do cenário)
function construirMundo(tema) {
  prepararCurvatura();
  if (tema.agua) construirAgua(tema.agua);
  if (tema.agua && tema.agua.plano) construirPonte(tema);
  if (tema.pilares) construirPilares(tema.pilares, !!(tema.agua && tema.agua.plano));
  if (tema.muros) construirMuros(tema.muros);
  if (tema.lava) construirLava(tema.lava);
  if (tema.neon) construirFiletesNeon(tema.neon);
  if (tema.pinheiros) construirPinheiros(tema.pinheiros);
  if (tema.palmeiras) construirPalmeiras(tema.palmeiras);
  if (tema.arvoresOutono) construirArvoresOutono(tema.arvoresOutono);
  if (tema.arquibancadas) construirArquibancadas(tema.arquibancadas);
  if (tema.particulas) construirParticulas(tema.particulas);
  if (tema.relampago) construirRelampago(tema.relampago);
  if (tema.pulso) { pulsoEstado = { cor: new THREE.Color(tema.pulso.cor), periodo: tema.pulso.periodo || 2.4 }; marcarEfeito('pulso'); }
  if (tema.fogos) construirFogos(tema.fogos);
  if (tema.astro) construirAstro(tema.astro);
  if (tema.cidadeDia) marcarEfeito('cidadeDia');
  if (tema.chaoTinta != null) marcarEfeito('chaoTinta');
  if (tema.cenario && tema.cenario.tinta != null) marcarEfeito('cenarioTinta');
  if (tema.zebras) marcarEfeito('zebras');
  if (tema.luzes) marcarEfeito('luzes');
}
// a cada quadro: anima os sistemas, leva o céu junto com a câmera e aplica relâmpago/pulso na luz
function animarMundo(dt, e, px, pz, f) {
  for (const anim of extrasAnim) anim(dt, relogioAnim, e, px, pz, f);
  if (camera) for (const seguir of ceuSeguir) seguir(camera);
  if (hemi && hemiBase && (relampagoEstado || pulsoEstado)) {
    const kr = relampagoEstado ? relampagoEstado.k : 1;
    let ki = 1;
    hemi.color.copy(hemiBase.cor);
    if (pulsoEstado) {
      const amp = reduzirMovimento() ? 0.3 : 1;
      const s = Math.sin((relogioAnim * Math.PI * 2) / pulsoEstado.periodo);
      ki = 1 + 0.35 * amp * s;
      hemi.color.lerp(pulsoEstado.cor, (0.5 + 0.5 * s) * 0.6 * amp);
    }
    hemi.intensity = hemiBase.int * kr * ki;
    if (renderer) renderer.toneMappingExposure = cfg.tema.exposicao * kr;
  }
}
function destruirMundo() {
  for (const o of extrasObjs) {
    if (o.parent) o.parent.remove(o);
    if (o.isInstancedMesh && o.dispose) { try { o.dispose(); } catch (e) {} }
  }
  for (const d of extrasDescarte) { try { d.dispose(); } catch (e) {} }
  extrasObjs = []; extrasDescarte = []; extrasAnim = []; extrasCenario = []; extrasEstrutura = []; extrasLongos = [];
  ceuSeguir = []; efeitosAtivos = []; relampagoEstado = null; pulsoEstado = null;
  hemi = null; hemiBase = null; texPonto = null; curvDh = [];
}

// ---------- ambiente ----------
function carregarCeu(tema) {
  const cena = scene;
  return new Promise((resolve) => {
    // o `ceu` dos mundos novos vale por cima (também quando o HDRI falha)
    const terminar = () => { if (scene === cena) aplicarCeu(tema); resolve(); };
    new RGBELoader(gerente).load(`assets3d/hdri/${tema.hdri}${qualidadeAlta ? '_2k' : ''}.hdr`, (tex) => {
      tex.mapping = THREE.EquirectangularReflectionMapping;
      scene.background = tex;
      scene.environment = tex;
      scene.backgroundBlurriness = 0.0;
      scene.environmentIntensity = tema.noturno ? 0.6 : 1.0;
      terminar();
    }, undefined, (e) => { console.warn('hdri', e); terminar(); });
  });
}

// ---------- API ----------
const benchMemo = new Map(); // `${gpu}|${w}x${h}@${dpr}` → ms do benchmark (por sessão)
// O 1º atualizar() do Dart só chega com a cena pronta: a carga inteira roda
// com este estado, e o som/🎸 dele vêm do config (`som`, `musicaLigada`;
// antes eram "ligados" por omissão — motor, vento e música tocavam na carga
// mesmo desligados)
let estadoCarga = null;
async function montar(canvas, config) {
  destruir(true); // a corrida anterior sai, mas o contexto fica (pode ser o mesmo canvas)
  cfg = { ...config };
  ingles = !!config.ingles; // liga os blocos "⚡ desempenho (22/out)" (Dart/C#: tudo como antes)
  estadoCarga = { posicao: 0, velocidade: 0, velMax: 30, x: 0, xAlvo: 0, impacto: 0, boost: 0, som: config.som !== false, musica: config.musicaLigada !== false }; // config.musica é a URL da faixa
  // tema que não existe (Dart mais novo que este módulo): cai no mundo base que o Dart mandou
  const temaPedido = TEMAS[config.tema];
  if (!temaPedido) console.warn('[turismo3d] tema', config.tema, 'não existe neste módulo (versão', VERSAO + '); usando o base', config.temaBase);
  api.temaId = temaPedido ? config.tema : (TEMAS[config.temaBase] ? config.temaBase : 1);
  cfg.tema = TEMAS[api.temaId];
  L = config.comprimentoSegmento || 8;
  api.pronto = false;
  api.erro = null;
  api.progresso = 0.05;
  const gpu = sondarGpu();
  api.gpu = gpu.nome;
  api.aviso = gpu.software ? 'software' : null;
  const pref = config.qualidade || 'auto';
  const medida = medirCanvas(canvas);
  api.benchMs = null;
  api.benchEm = null;
  if (pref === 'alta') nivelQualidade = 'alta';
  else if (pref === 'leve') nivelQualidade = 'leve';
  else if (gpu.software) nivelQualidade = 'minima';
  else {
    const dprAlta = pixelRatioPara('alta', medida.w, medida.h);
    // a mesma GPU no mesmo tamanho já foi medida nesta sessão: reaproveita
    // (o teste de estresse custava 0,5–1,5 s de GPU a 100% em toda corrida)
    const chaveBench = `${gpu.nome}|${medida.w}x${medida.h}@${dprAlta}`;
    let ms = benchMemo.get(chaveBench) || 0;
    if (!ms) {
    ms = await benchmarkGpu(true, medida.w, medida.h, dprAlta);
    // resultado ruim pode ser só o momento (aba recém-visível, Flutter ainda
    // desenhando o carregamento): espera meio segundo e mede de novo, e vale
    // o melhor dos dois — um falso "mínima" custa mais que 0,5 s de espera
    if (ms > 19) {
      await new Promise((res) => setTimeout(res, 500));
      const ms2 = await benchmarkGpu(true, medida.w, medida.h, dprAlta);
      console.info('[turismo3d] benchmark repetido:', +ms.toFixed(1), '→', +ms2.toFixed(1), 'ms');
      if (ms2 > 0) ms = Math.min(ms, ms2);
    }
    // só guarda medida boa: uma ruim pode ter sido o momento — a próxima
    // corrida mede de novo, como sempre
    if (ms > 0 && ms <= 19) benchMemo.set(chaveBench, ms);
    }
    api.benchMs = +ms.toFixed(1);
    api.benchEm = { largura: medida.w, altura: medida.h, dpr: dprAlta };
    nivelQualidade = ms > 34 ? 'minima' : (ms > 19 || gpu.fraca || !resolverQualidade('auto')) ? 'leve' : 'alta';
    console.info('[turismo3d] benchmark', api.benchMs, 'ms @', medida.w + '×' + medida.h, 'dpr', dprAlta, '→', nivelQualidade);
  }
  qualidadeAlta = nivelQualidade === 'alta';
  perfilAtual = PERFIS[nivelQualidade];
  api.qualidadeEfetiva = nivelQualidade;
  api.frameMs = null;
  vigiaTempos = []; vigiaAte = 0; ultimoQuadroMs = 0; vigiaSomaMs = 0; vigiaLentosSeguidos = 0;
  escalaExtra = 1; api.rebaixamentos = 0;

  renderer = new THREE.WebGLRenderer({ canvas, antialias: nivelQualidade !== 'minima', powerPreference: 'high-performance' });
  renderer.setPixelRatio(pixelRatioPara(nivelQualidade, medida.w, medida.h));
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
  hemi = new THREE.HemisphereLight(0xffffff, 0x3a3a3a, cfg.tema.noturno ? 0.28 : 0.35);
  hemiBase = { int: hemi.intensity, cor: hemi.color.clone() }; // relâmpago e pulso voltam pra cá
  scene.add(hemi);
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
    construirMundo(cfg.tema); // 🌍 temas 7–26 (nos clássicos não liga nada)
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
    if (cfg.tema.muretas) await construirMuretas(cfg.tema.muretas);
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
  vigiaAte = performance.now() + 3000;
  // medida pro debug(): programas de shader compilados DEPOIS da largada
  // (cada um é um engasgo; o ideal é 0 — só a troca de nível do vigia cria)
  if (ingles) {
    maiorIdPrograma = -1; nProgramasVisto = -1; vigiarProgramas();
    api.programasNaLargada = maiorIdPrograma;
  }
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
  // inglês: a tradução embaixo da palavra (vazio no Dart/C#)
  const traducao = pal.traducao || '';
  const chave = palavra + '|' + n + '|' + rotulo + '|' + (pal.tipo || '') + '|' + (pal.ativa ? 1 : 0) + '|' + traducao;
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
    ctx.fillText(rotulo.split(' ')[0], w / 2, traducao ? 130 : 150);
    ctx.font = traducao ? '700 48px "JetBrains Mono", "Roboto Mono", monospace' : '700 54px "JetBrains Mono", "Roboto Mono", monospace';
    ctx.fillStyle = '#c9d1d9';
    ctx.fillText(palavra, w / 2, traducao ? 240 : 262);
    if (traducao) {
      ctx.font = '600 36px "Inter", "Roboto", sans-serif';
      ctx.fillStyle = '#9aa4ae';
      ctx.fillText(traducao, w / 2, 286);
    }
    ctx.globalAlpha = 1;
    painel.tex.needsUpdate = true;
    return;
  }
  ctx.fillText(rotulo, w / 2, traducao ? 52 : 64);
  const tamMax = traducao ? 120 : 150;
  let tam = tamMax;
  ctx.font = `700 ${tam}px "JetBrains Mono", "Roboto Mono", monospace`;
  while (ctx.measureText(palavra).width > w * 0.86 && tam > 60) { tam -= 8; ctx.font = `700 ${tam}px "JetBrains Mono", "Roboto Mono", monospace`; }
  const total = ctx.measureText(palavra).width;
  let x = w / 2 - total / 2;
  const y = traducao ? 170 : 205;
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
  if (traducao) {
    ctx.textAlign = 'center';
    let ts = 52;
    ctx.font = `600 ${ts}px "Inter", "Roboto", sans-serif`;
    while (ctx.measureText(traducao).width > w * 0.86 && ts > 28) { ts -= 4; ctx.font = `600 ${ts}px "Inter", "Roboto", sans-serif`; }
    ctx.fillStyle = '#9aa4ae';
    ctx.fillText(traducao, w / 2, 268);
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
  // a música obedece ao 🎸 da tela do Turismo (mais pausa e fim), não ao
  // liga/desliga global dos EFEITOS (`som`, o alto-falante do HUD das
  // lições, invisível no arcade): com os efeitos mudos ela tocava na carga
  // e sumia na largada, com o chip dizendo "Rock ligado"
  const ligada = e.musica !== false && !e.pausado && !e.acabou;
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
  aplicarTamanho();
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
  congelado = false;
}

function atualizar(novo) {
  estado = novo;
  if (novo && novo.largura && novo.altura) redimensionar(novo.largura, novo.altura);
}

// ---------- economia de GPU ----------
// (1) Teto de 60 fps em tela rápida (ProMotion 120 Hz, monitor gamer 144 Hz):
//     a cena inteira era desenhada 2× mais vezes sem ganho visível. Só liga
//     com a corrida pronta (a medição da carga continua igual) e quando o
//     rAF mede acima de ~90 Hz — em 60/75 Hz nada muda. Os vsyncs pulados
//     nem chamam quadro(): o vigia só vê os quadros desenhados.
// (2) Quadro congelado quando não há nada a mostrar: pausa, fim (depois de
//     1,5 s, pras faíscas assentarem) e carga (um quadro por etapa) — o
//     overlay do Flutter cobre a cena e a última imagem fica igual.
api.fpsMax = 60; // 0 = sem teto
api.quadros = 0; // contador de renders (diagnóstico/medição)
let proximoQuadroMs = 0, rafAnteriorMs = 0, rafMedioMs = 1000 / 60;
let congelado = false, acabouDesde = 0, progressoDesenhado = -1;
function deveCongelar(e) {
  if (!api.pronto && api.progresso < 0.9) return api.progresso === progressoDesenhado; // aquecer/medição (≥ 0,9) desenham
  if (e.pausado) return true;
  if (e.acabou) {
    const agora = performance.now();
    if (!acabouDesde) acabouDesde = agora;
    return agora - acabouDesde > 1500;
  }
  acabouDesde = 0;
  return false;
}
function pularVsync(t) {
  if (rafAnteriorMs && t > rafAnteriorMs) rafMedioMs += (Math.min(t - rafAnteriorMs, 50) - rafMedioMs) * 0.05;
  rafAnteriorMs = t;
  if (!api.fpsMax || !api.pronto || rafMedioMs > 1000 / 90) { proximoQuadroMs = 0; return false; }
  const passo = 1000 / api.fpsMax;
  if (t + 1 < proximoQuadroMs) return true; // 1 ms de folga pro jitter
  proximoQuadroMs = (t - proximoQuadroMs > passo) ? t + passo : proximoQuadroMs + passo;
  return false;
}

function loop(t) {
  animId = requestAnimationFrame(loop);
  if (pularVsync(typeof t === 'number' ? t : performance.now())) return;
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
// vetores de rascunho da câmera (antes: 2 Vector3 novos por quadro)
const camAlvoPosRasc = new THREE.Vector3(), camOlharRasc = new THREE.Vector3();
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
    alvoPos = camAlvoPosRasc.set(px + f.x * 2.2, 0.95, pz + f.z * 2.2);
    alvoOlhar = camOlharRasc.set(px + f.x * 40, 0.7, pz + f.z * 40);
    fov = fovVertical(88 + v * 14);
    rigida = true; olharRapido = true;
  } else if (modo === 'alta') {
    alvoPos = camAlvoPosRasc.set(px - f.x * 13, 8.5 + v * 1.5, pz - f.z * 13);
    alvoOlhar = camOlharRasc.set(px + f.x * 12, 0.4, pz + f.z * 12);
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
    alvoOlhar = camOlharRasc.set(px + f.x * 1.5, 0.8, pz + f.z * 1.5);
    // teleobjetiva: fecha o zoom quando o carro está longe
    const dist = alvoPos.distanceTo(alvoOlhar);
    const fovAlvo = fovVertical(Math.max(26, Math.min(78, 2000 / (dist + 8))));
    fov = camera.fov + (fovAlvo - camera.fov) * (1 - Math.exp(-dt / 0.35));
    rigida = true; olharRapido = true;
  } else {
    alvoPos = camAlvoPosRasc.set(px - f.x * (7.4 + v * 1.4), 3.0 + v * 0.3, pz - f.z * (7.4 + v * 1.4));
    alvoOlhar = camOlharRasc.set(px + f.x * 9, 1.1, pz + f.z * 9);
    fov = fovVertical(84 + v * 12);
  }
  if (modo !== 'cinema') cinemaPonto = null;
  if (rigida) camPos.copy(alvoPos); else camPos.lerp(alvoPos, 1 - Math.pow(0.001, dt));
  camAlvo.lerp(alvoOlhar, 1 - Math.pow(olharRapido ? 0.000001 : 0.0005, dt));
  const forca = modo === 'cinema' ? 0.04 : (modo === 'capo' ? 0.12 : 0.2);
  // reduzir animações (sistema) também desliga a tremida, como o turismo_tremor
  tremor = (e.tremor === false || reduzirMovimento()) ? 0 : Math.max(0, (e.impacto || 0) * forca);
  camera.position.set(camPos.x + (Math.random() - .5) * tremor, camPos.y + (Math.random() - .5) * tremor, camPos.z + (Math.random() - .5) * tremor);
  camera.lookAt(camAlvo);
  camera.fov = fov;
  camera.updateProjectionMatrix();
}

function quadro() {
  const e = estado || estadoCarga || { posicao: 0, velocidade: 0, velMax: 30, x: 0, xAlvo: 0, impacto: 0, boost: 0 };
  const parar = deveCongelar(e);
  if (parar && congelado) {
    // nada a desenhar: só o áudio segue (o fade até o silêncio) e o tempo
    // parado é descartado — nem a física nem o vigia o veem como quadro lento
    const dtParado = Math.min(relogio.getDelta(), 0.1);
    ultimoQuadroMs = 0;
    const frParado = Math.max(0, Math.min(1, e.velocidade / (e.velMax || 1)));
    atualizarMotorAudio(frParado, e);
    atualizarMusica(e, dtParado);
    atualizarVento(frParado, e);
    return;
  }
  congelado = parar; // desenha 1 quadro completo e congela no próximo
  progressoDesenhado = api.progresso;
  vigiarDesempenho();
  const dt = Math.min(relogio.getDelta(), 0.1);
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
  animarMundo(dt, e, px, pz, f);
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
  // mundos novos: árvores e muretas seguem o cenário; arquibancadas sempre até
  // 600 m (com névoa .0016 ainda aparecem ~40% lá); paredões e saias da ponte
  // até o far da câmera (900): a 380 m um muro de 26 m "nascia" a 69% visível
  if (extrasCenario.length) cularPorDistancia(extrasCenario, e.posicao || 0, perfilAtual.cenario, perfilAtual.cenarioAlcance, perfilAtual.metade);
  if (extrasEstrutura.length) cularPorDistancia(extrasEstrutura, e.posicao || 0, true, Math.max(600, perfilAtual.cenarioAlcance), false);
  if (extrasLongos.length) cularPorDistancia(extrasLongos, e.posicao || 0, true, 900, false);
  // só os carros parados dos próximos portais entram na cena (desempenho)
  for (const o of obstaculos) {
    if (o.userData.arremessado) continue;
    const dz = o.userData.z - e.posicao;
    o.visible = dz > -30 && dz < perfilAtual.trafego;
  }
  atualizarPlacas();
  if (ingles && api.pronto) subirTexturasAdiante(e.posicao || 0, 1);
  api.quadros++;
  renderer.render(scene, camera);
  if (ingles) vigiarProgramas();
}
// diagnóstico (debug().programasNovosNaCorrida): o id dos programas do
// three.js só cresce; guarda o maior visto (varre a lista só quando o
// tamanho dela muda — nascer ou morrer um programa)
let maiorIdPrograma = -1, nProgramasVisto = -1;
function vigiarProgramas() {
  const lista = renderer && renderer.info.programs;
  if (!lista || lista.length === nProgramasVisto) return;
  nProgramasVisto = lista.length;
  for (const pr of lista) if (pr.id > maiorIdPrograma) maiorIdPrograma = pr.id;
}

function destruir(manterContexto) {
  pararAudio();
  destruirMundo(); // geometrias/materiais/texturas dos mundos novos (antes do renderer.dispose)
  if (faiscaGuarda) { faiscaGuarda.geometry.dispose(); faiscaGuarda.material.dispose(); faiscaGuarda = null; }
  texturasAdiante = []; texturasAdianteI = 0;
  obstaculoDoCarro = new Map();
  maiorIdPrograma = -1; nProgramasVisto = -1; api.programasNaLargada = null;
  arremessos = []; faiscas = [];
  if (animId) cancelAnimationFrame(animId);
  animId = 0;
  congelado = false; acabouDesde = 0; progressoDesenhado = -1; proximoQuadroMs = 0;
  if (resizeObs) resizeObs.disconnect();
  resizeObs = null;
  // forceContextLoss: devolve o contexto WebGL na hora (corrida após
  // corrida, o navegador chegava a "Too many active WebGL contexts"). Só
  // quando a vista sai de vez (o Dart chama destruir() no dispose, e cada
  // corrida nova ganha um canvas novo); montar() troca a cena e mantém.
  if (renderer) {
    renderer.dispose();
    if (!manterContexto) { try { renderer.forceContextLoss(); } catch (e) {} }
    renderer = null;
  }
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
    programasNovosNaCorrida: api.programasNaLargada != null ? maiorIdPrograma - api.programasNaLargada : null,
    luzesPostes: { pool: luzesPool.length, visiveis: luzesPool.filter((l) => l.visible).length, acesas: luzesPool.filter((l) => l.visible && l.intensity > 0).length },
    texturasAdiantadas: texturasAdianteI + '/' + texturasAdiante.length,
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
    temaId: api.temaId != null ? api.temaId : null,
    versao: VERSAO,
    efeitos: [...efeitosAtivos],
    reduzirMovimento: reduzirMovimento(),
    pista: cfg ? cfg.distancia : null,
    arremessos: arremessos.length,
  };
}
Object.assign(api, { montar, atualizar, destruir, debug, versao: VERSAO, CARROS: Object.keys(CARROS) });
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
// 🔊 a palavra falada no inglês (o Dart chama ao falar): a música abaixa por `ms` pro volume da
// batida (VOLUME_MUSICA_BATIDA) e volta sozinha; nunca encurta um ducking mais longo já em curso
api.abaixarMusica = (ms) => {
  const ate = performance.now() + Math.max(0, Math.min(5000, +ms || 0));
  if (ate > duckAte) duckAte = ate;
};
// gancho de teste/diagnóstico: turismo3d.forcarQualidade('minima')
api.forcarQualidade = (nivel) => { if (PERFIS[nivel]) aplicarQualidade(nivel); return nivelQualidade; };
// o stub do index.html tinha carregar(); mantém o contrato depois da troca
// (receitas externas fazem `await window.turismo3d.carregar()` sem saber se já carregou)
api.carregar = () => Promise.resolve();
window.turismo3d = api;
