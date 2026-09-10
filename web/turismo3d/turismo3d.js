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
  1: { hdri: 'campina', chao: 'leafy_grass', repChao: 260, exposicao: 1.0, sol: [-0.5, 0.75, 0.35], solCor: 0xfff1d6, solForca: 2.4, noturno: false, neblina: 0xdbe9ff, densidade: 0.0016 },
  2: { hdri: 'deserto', chao: 'sand_01', repChao: 220, exposicao: 1.05, sol: [0.55, 0.6, -0.3], solCor: 0xffe6c0, solForca: 2.6, noturno: false, neblina: 0xf3dcb4, densidade: 0.0014 },
  3: { hdri: 'cidade', chao: 'concrete_floor_02', repChao: 200, exposicao: 0.85, sol: [0.3, 0.7, 0.4], solCor: 0x9fb7ff, solForca: 0.35, noturno: true, neblina: 0x141a28, densidade: 0.0022, lampadas: true, cidade: true },
  4: { hdri: 'neve', chao: 'snow_02', repChao: 240, exposicao: 1.0, sol: [-0.35, 0.65, 0.5], solCor: 0xffffff, solForca: 2.0, noturno: false, neblina: 0xeaf3ff, densidade: 0.0020 },
  5: { hdri: 'vulcao', chao: 'dark_rock', repChao: 200, exposicao: 1.05, sol: [0.7, 0.35, 0.2], solCor: 0xff9a6a, solForca: 1.6, noturno: true, neblina: 0x3a1c14, densidade: 0.0024 },
  6: { hdri: 'espaco', chao: 'dark_rock', repChao: 200, exposicao: 0.95, sol: [0.1, 0.8, 0.3], solCor: 0xc8d8ff, solForca: 0.5, noturno: true, neblina: 0x0a0e1e, densidade: 0.0015 },
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

let renderer, scene, camera, sol, relogio, luzCarro = null;
let cfg = null, estado = null, animId = 0, resizeObs = null;
let centro = [], L = 8;
let carro = null, faroisLuz = [];
let portais = []; // { grupo, placas:[{tex, ctx, canvas, faixa, estiloAtual}], flags }
let obstaculos = [];
let modelosCache = {};
let texLoader = new THREE.TextureLoader();
let gltfLoader = null;
let camPos = new THREE.Vector3(), camAlvo = new THREE.Vector3();
let tremor = 0;
const api = { pronto: false, erro: null, progresso: 0 };

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
  return t;
}
function materialPbr(nome, { repU = 1, repV = 1, rough = 1, metal = 0 } = {}) {
  const base = `assets3d/tex/${nome}/`;
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
  scene.add(plano);

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

function construirPortais() {
  const posteGeo = new THREE.CylinderGeometry(0.14, 0.16, 5.8, 12);
  const posteMat = new THREE.MeshStandardMaterial({ color: 0xdfe4e9, roughness: .4, metalness: .7 });
  const vigaGeo = new THREE.BoxGeometry(MEIA_PISTA * 2 + 2.4, 0.4, 0.4);
  const vigaMat = new THREE.MeshStandardMaterial({ color: 0x2a2f38, roughness: .5, metalness: .6 });
  const placaGeo = new THREE.PlaneGeometry(3.1, 1.05);
  portais = [];
  for (const p of cfg.portais) {
    const grupo = new THREE.Group();
    const q = pose(p.z);
    grupo.position.set(q.x, 0, q.z);
    grupo.rotation.y = -q.h;
    for (const lado of [-1, 1]) {
      const poste = new THREE.Mesh(posteGeo, posteMat);
      poste.position.set(lado * (MEIA_PISTA + 1.1), 2.9, 0);
      poste.castShadow = true;
      grupo.add(poste);
    }
    const viga = new THREE.Mesh(vigaGeo, vigaMat);
    viga.position.set(0, 5.6, 0);
    viga.castShadow = true;
    grupo.add(viga);
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
    const k = flags.indice != null ? flags.indice : j;
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
        if (fx && flags.fichas[i] && !fx.userData.pega) {
          fx.userData.pega = true;
          fx.visible = false;
          soltarFaiscas(fx.position.clone(), frente(0), 0xffd54f, 24);
        }
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
  modelosCache[id] = envolt;
  return envolt;
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
// Prédios procedurais dos dois lados da pista, seguindo as curvas: caixas
// instanciadas (3 faixas de altura, pra janela não esticar) com fachada de
// janelas pintada em canvas; à noite as janelas acendem (emissivo).
let predios = [];
function texturaFachada(andares, colunas, semente) {
  let s = semente;
  const rnd = () => { s = (s * 16807) % 2147483647; return s / 2147483647; };
  const w = 256, h = 512;
  const cw = w / colunas, ch = h / andares;
  const base = canvasTex(w, h, (ctx) => {
    const tom = 44 + Math.floor(rnd() * 50);
    ctx.fillStyle = `rgb(${tom},${tom + 4},${tom + 12})`;
    ctx.fillRect(0, 0, w, h);
    for (let a = 0; a < andares; a++) {
      for (let c = 0; c < colunas; c++) {
        ctx.fillStyle = 'rgba(120,140,170,0.55)';
        ctx.fillRect(c * cw + cw * .18, a * ch + ch * .2, cw * .64, ch * .56);
      }
    }
    // faixa mais escura entre andares
    ctx.fillStyle = 'rgba(0,0,0,0.25)';
    for (let a = 0; a < andares; a++) ctx.fillRect(0, a * ch, w, ch * .06);
  });
  const luz = canvasTex(w, h, (ctx) => {
    ctx.fillStyle = '#000';
    ctx.fillRect(0, 0, w, h);
    for (let a = 0; a < andares; a++) {
      for (let c = 0; c < colunas; c++) {
        if (rnd() < 0.42) {
          const q = rnd();
          ctx.fillStyle = q < .5 ? '#ffd88a' : (q < .8 ? '#fff4d6' : '#9fc4ff');
          ctx.fillRect(c * cw + cw * .18, a * ch + ch * .2, cw * .64, ch * .56);
        }
      }
    }
  });
  return { mapa: base.tex, luz: luz.tex };
}
function construirCidade() {
  const bandas = [
    { andares: 4, colunas: 5, hMin: 11, hMax: 16 },
    { andares: 9, colunas: 6, hMin: 20, hMax: 34 },
    { andares: 16, colunas: 7, hMin: 38, hMax: 64 },
  ];
  const noturno = cfg.tema.noturno;
  const geo = new THREE.BoxGeometry(1, 1, 1);
  geo.translate(0, 0.5, 0); // base no chão
  let s = 7;
  const rnd = () => { s = (s * 48271) % 2147483647; return s / 2147483647; };
  const lotes = [];
  const total = centro.length * L;
  for (let d = 30; d < total - 40; d += 26) {
    for (const lado of [-1, 1]) {
      if (rnd() < 0.12) continue; // um terreno vazio de vez em quando
      const r1 = rnd();
      const bandaI = r1 < .45 ? 0 : (r1 < .8 ? 1 : 2);
      const banda = bandas[bandaI];
      const larg = 14 + rnd() * 10, prof = 14 + rnd() * 10;
      const alt = banda.hMin + rnd() * (banda.hMax - banda.hMin);
      const q = pose(d + rnd() * 6);
      const r = direita(q.h);
      const afast = MEIA_PISTA + 9 + prof / 2 + rnd() * 4;
      const m = new THREE.Matrix4().makeRotationY(-q.h);
      m.multiply(new THREE.Matrix4().makeScale(larg, alt, prof));
      m.setPosition(q.x + r.x * afast * lado, 0, q.z + r.z * afast * lado);
      lotes.push({ bandaI, m });
    }
  }
  bandas.forEach((banda, i) => {
    const meus = lotes.filter((l) => l.bandaI === i);
    if (!meus.length) return;
    const tex = texturaFachada(banda.andares, banda.colunas, 11 + i * 97);
    const fachada = new THREE.MeshStandardMaterial({ map: tex.mapa, roughness: .7, metalness: .1, emissive: 0xffffff, emissiveMap: tex.luz, emissiveIntensity: noturno ? 1.1 : 0.06 });
    const telhado = new THREE.MeshStandardMaterial({ color: 0x2a2d33, roughness: .95 });
    const inst = new THREE.InstancedMesh(geo, [fachada, fachada, telhado, telhado, fachada, fachada], meus.length);
    meus.forEach((l, k) => inst.setMatrixAt(k, l.m));
    inst.instanceMatrix.needsUpdate = true;
    scene.add(inst);
    predios.push(inst);
  });
  // calçadas de concreto dos dois lados, entre o guard-rail e os prédios
  const concreto = new THREE.MeshStandardMaterial({ color: 0x8d8d8d, roughness: .95 });
  for (const lado of [-1, 1]) {
    const a = lado * (MEIA_PISTA + 2.6), b = lado * (MEIA_PISTA + 8.5);
    const calcada = new THREE.Mesh(faixaGeometria(Math.min(a, b), Math.max(a, b), 0.14, 0.14, 4), concreto);
    calcada.receiveShadow = true;
    scene.add(calcada);
  }
  console.info('[turismo3d] cidade:', lotes.length, 'prédios');
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
  gltfLoader.load('assets3d/modelos/street_lamp_01/street_lamp_01.gltf', (gltf) => {
    const base = gltf.scene;
    base.traverse((o) => {
      if (o.isMesh) {
        o.castShadow = false;
        if (o.material && o.material.emissive) { o.material = o.material.clone(); }
      }
    });
    const n = Math.floor(cfg.distancia / 60);
    for (let k = 0; k < n; k++) {
      const d = 30 + k * 60;
      const q = pose(d);
      const lado = k % 2 ? 1 : -1;
      const r = direita(q.h);
      const lat = lado * (MEIA_PISTA + 3.2);
      const lamp = base.clone();
      lamp.position.set(q.x + r.x * lat, 0, q.z + r.z * lat);
      lamp.rotation.y = -q.h + (lado > 0 ? Math.PI : 0);
      scene.add(lamp);
      // bulbo emissivo: brilha mesmo sem luz real
      const bulbo = new THREE.Mesh(new THREE.SphereGeometry(0.18, 10, 8), new THREE.MeshBasicMaterial({ color: 0xfff1c0 }));
      bulbo.position.set(q.x + r.x * (lat - lado * 1.4), 4.6, q.z + r.z * (lat - lado * 1.4));
      scene.add(bulbo);
      postesLuz.push({ d, pos: bulbo.position.clone() });
    }
  }, undefined, (e) => console.warn('lampadas', e));
}
function atualizarLuzes(posicao) {
  if (!luzesPool.length || !postesLuz.length) return;
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
    new RGBELoader().load(`assets3d/hdri/${tema.hdri}.hdr`, (tex) => {
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

  renderer = new THREE.WebGLRenderer({ canvas, antialias: true, powerPreference: 'high-performance' });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFShadowMap;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = cfg.tema.exposicao;

  scene = new THREE.Scene();
  scene.fog = new THREE.FogExp2(cfg.tema.neblina, cfg.tema.densidade);
  camera = new THREE.PerspectiveCamera(62, 1, 0.3, 900);
  relogio = new THREE.Timer ? { getDelta: (() => { const tm = new THREE.Timer(); return () => { tm.update(); return tm.getDelta(); }; })() } : new THREE.Clock();

  sol = new THREE.DirectionalLight(cfg.tema.solCor, cfg.tema.solForca);
  sol.castShadow = true;
  sol.shadow.mapSize.set(1536, 1536);
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
  gltfLoader = new GLTFLoader();
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
  if (audioCtx) { if (cfg.musica) carregarMusica(cfg.musica); ligarVento(); }
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
    api.progresso = 0.85;
    api.pronto = true;
  } catch (e) {
    console.error('carro', e);
    api.erro = String(e);
  }
  await construirObstaculos();
  api.progresso = 1;
}

// ---------- painéis das palavras no cenário ----------
// Cada palavra flutua SOBRE A FAIXA pra onde ela leva (esquerda, meio ou
// direita), uns metros à frente do carro: quem lê já sabe pra que lado vai.
// Com duas saídas há dois painéis; combustível fica na faixa atual.
let paineis = [];
function construirPainel() {
  paineis = [];
  for (let k = 0; k < 2; k++) {
    const ct = canvasTex(1024, 320, (ctx, w, h) => ctx.clearRect(0, 0, w, h));
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
  const altura = modo === 'capo' ? 1.7 : (modo === 'alta' ? 2.6 : 2.05);
  const q = pose((e.posicao || 0) + aFrente);
  const r = direita(q.h);
  for (let k = 0; k < paineis.length; k++) {
    const painel = paineis[k];
    const pal = lista[k];
    if (!pal || !pal.texto) { painel.mesh.visible = false; continue; }
    const faixa = pal.faixa == null ? 1 : pal.faixa;
    const lat = (faixa - 1) * LARGURA_FAIXA;
    painel.mesh.visible = true;
    painel.mesh.position.set(q.x + r.x * lat, altura, q.z + r.z * lat);
    painel.mesh.quaternion.copy(camera.quaternion);
    pintarPainel(painel, pal);
  }
}

// ---------- áudio do carro (amostras reais) ----------
// Motor: um loop gravado com o tom (playbackRate) e o volume seguindo a
// velocidade; batida: amostra curta. O AudioContext nasce no 1º gesto.
let audioCtx = null, motorFonte = null, motorGanho = null, motorFiltro = null, buffers = {}, audioPedido = false;
// 🎸 música da fase (loop) com ducking na batida; 🌬️ vento = ruído filtrado
let musicaFonte = null, musicaGanho = null, musicaUrl = null, musicasCache = {}, duckAte = 0;
let ventoFonte = null, ventoGanho = null, ventoFiltro = null;
function carregarMusica(url) {
  if (!audioCtx || !url || musicaUrl === url) return;
  musicaUrl = url;
  const tocar = (buf) => {
    if (musicaUrl !== url || musicaFonte) return;
    musicaFonte = audioCtx.createBufferSource();
    musicaFonte.buffer = buf;
    musicaFonte.loop = true;
    musicaGanho = audioCtx.createGain();
    musicaGanho.gain.value = 0;
    musicaFonte.connect(musicaGanho); musicaGanho.connect(audioCtx.destination);
    musicaFonte.start();
  };
  if (musicasCache[url]) { tocar(musicasCache[url]); return; }
  fetch(url).then((r) => r.arrayBuffer()).then((b) => audioCtx.decodeAudioData(b))
    .then((buf) => { musicasCache[url] = buf; tocar(buf); })
    .catch((e) => console.warn('[turismo3d] música', e));
}
function atualizarMusica(e) {
  if (!musicaGanho || !audioCtx) return;
  const t = audioCtx.currentTime;
  const ligada = e.som !== false && e.musica !== false && !e.pausado && !e.acabou;
  const alvo = !ligada ? 0 : (t < duckAte ? 0.09 : 0.28);
  musicaGanho.gain.setTargetAtTime(alvo, t, ligada ? .5 : .15);
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
  ventoGanho.gain.setTargetAtTime(ligado ? fracao * fracao * 0.16 : 0, t, .2);
  ventoFiltro.frequency.setTargetAtTime(300 + fracao * 1100, t, .3);
}
function prepararAudio() {
  if (audioPedido) return;
  audioPedido = true;
  const iniciar = () => {
    if (!audioCtx) {
      try { audioCtx = new (window.AudioContext || window.webkitAudioContext)(); } catch (e) { return; }
      for (const [nome, url] of Object.entries({ motor: 'assets3d/som/motor.m4a', batida: 'assets3d/som/batida.m4a' })) {
        fetch(url).then((r) => r.arrayBuffer()).then((b) => audioCtx.decodeAudioData(b)).then((buf) => { buffers[nome] = buf; if (nome === 'motor') ligarMotor(); }).catch((e) => console.warn('[turismo3d] som', nome, e));
      }
      if (cfg && cfg.musica) carregarMusica(cfg.musica);
      ligarVento();
    }
    if (audioCtx.state === 'suspended') audioCtx.resume();
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
  motorGanho.gain.setTargetAtTime(ligado ? 0.10 + fracao * 0.22 : 0, t, .1);
}
function tocarBatida() {
  if (!audioCtx || !buffers.batida || (estado && estado.som === false)) return;
  duckAte = audioCtx.currentTime + 1.8;
  const src = audioCtx.createBufferSource();
  src.buffer = buffers.batida;
  const g = audioCtx.createGain();
  g.gain.value = .9;
  src.connect(g); g.connect(audioCtx.destination);
  src.start();
}
function pararAudio() {
  try { if (motorGanho && audioCtx) motorGanho.gain.setTargetAtTime(0, audioCtx.currentTime, .05); } catch (e) {}
  try { if (motorFonte) { const f = motorFonte; setTimeout(() => { try { f.stop(); } catch (e) {} }, 300); } } catch (e) {}
  motorFonte = null; motorGanho = null; motorFiltro = null;
  try { if (musicaGanho && audioCtx) musicaGanho.gain.setTargetAtTime(0, audioCtx.currentTime, .1); } catch (e) {}
  try { if (musicaFonte) { const f = musicaFonte; setTimeout(() => { try { f.stop(); } catch (e) {} }, 500); } } catch (e) {}
  musicaFonte = null; musicaGanho = null; musicaUrl = null;
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
function posicionarCamera(e, f, px, pz, fracao, dt) {
  const modo = e.camera || 'perseguicao';
  let alvoPos, alvoOlhar, fov, rigida = false, olharRapido = false;
  if (modo === 'capo') {
    alvoPos = new THREE.Vector3(px + f.x * 2.2, 0.95, pz + f.z * 2.2);
    alvoOlhar = new THREE.Vector3(px + f.x * 40, 0.7, pz + f.z * 40);
    fov = 66 + fracao * 16 + (e.boost || 0) * 4;
    rigida = true; olharRapido = true;
  } else if (modo === 'alta') {
    alvoPos = new THREE.Vector3(px - f.x * 13, 8.5 + fracao * 1.5, pz - f.z * 13);
    alvoOlhar = new THREE.Vector3(px + f.x * 12, 0.4, pz + f.z * 12);
    fov = 50 + fracao * 8;
  } else if (modo === 'cinema') {
    const zc = e.posicao || 0;
    if (!cinemaPonto || zc > cinemaPonto.z + 14 || zc < cinemaPonto.z - 90) {
      // novo ponto de TV: 48 m à frente, na beira da pista, do outro lado
      cinemaLado = -cinemaLado;
      const zp = zc + 48;
      const qp = pose(zp), rp = direita(qp.h);
      cinemaPonto = { z: zp, pos: new THREE.Vector3(qp.x + rp.x * 9.5 * cinemaLado, 3.4, qp.z + rp.z * 9.5 * cinemaLado) };
      camPos.copy(cinemaPonto.pos);
      camAlvo.set(px, 0.8, pz);
    }
    alvoPos = cinemaPonto.pos;
    alvoOlhar = new THREE.Vector3(px + f.x * 1.5, 0.8, pz + f.z * 1.5);
    // teleobjetiva: fecha o zoom quando o carro está longe
    const dist = alvoPos.distanceTo(alvoOlhar);
    fov = Math.max(20, Math.min(58, 1500 / (dist + 8)));
    rigida = true; olharRapido = true;
  } else {
    alvoPos = new THREE.Vector3(px - f.x * (7.2 + fracao * 1.8), 2.9 + fracao * 0.35, pz - f.z * (7.2 + fracao * 1.8));
    alvoOlhar = new THREE.Vector3(px + f.x * 9, 1.1, pz + f.z * 9);
    fov = 62 + fracao * 14 + (e.boost || 0) * 4;
  }
  if (modo !== 'cinema') cinemaPonto = null;
  if (rigida) camPos.copy(alvoPos); else camPos.lerp(alvoPos, 1 - Math.pow(0.001, dt));
  camAlvo.lerp(alvoOlhar, 1 - Math.pow(olharRapido ? 0.000001 : 0.0005, dt));
  const forca = modo === 'cinema' ? 0.04 : (modo === 'capo' ? 0.16 : 0.28);
  tremor = e.tremor === false ? 0 : Math.max(0, (e.impacto || 0) * forca);
  camera.position.set(camPos.x + (Math.random() - .5) * tremor, camPos.y + (Math.random() - .5) * tremor, camPos.z + (Math.random() - .5) * tremor);
  camera.lookAt(camAlvo);
  camera.fov = fov;
  camera.updateProjectionMatrix();
}

function quadro() {
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
  // as palavras flutuam sobre a faixa pra onde levam, à frente do carro
  posicionarPaineis(e);
  posicionarCamera(e, f, px, pz, fracao, dt);

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
  atualizarMotorAudio(fracao, e);
  atualizarMusica(e);
  atualizarVento(fracao, e);
  // só os carros parados dos próximos portais entram na cena (desempenho)
  for (const o of obstaculos) {
    if (o.userData.arremessado) continue;
    const dz = o.userData.z - e.posicao;
    o.visible = dz > -30 && dz < 320;
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
  predios = [];
}

function debug() {
  const e = estado || {};
  return {
    pronto: api.pronto, erro: api.erro,
    carro: carro ? { pos: carro.position.toArray().map((v) => +v.toFixed(2)), caixa: carro.userData.caixa, visiveis: (() => { let n = 0; carro.traverse((o) => { if (o.isMesh && o.visible) n++; }); return n; })() } : null,
    camera: camera ? camera.position.toArray().map((v) => +v.toFixed(2)) : null,
    modoCamera: estado ? estado.camera : null,
    musica: musicaUrl, predios: predios.reduce((n, p) => n + p.count, 0),
    estado: { posicao: e.posicao, velocidade: e.velocidade, x: e.x },
    obstaculos: obstaculos.length,
    audio: { ctx: !!audioCtx, motor: !!buffers.motor, batida: !!buffers.batida, fonte: !!motorFonte, estado: audioCtx && audioCtx.state },
    tema: cfg && cfg.tema ? cfg.tema.hdri : null,
    pista: cfg ? cfg.distancia : null,
    arremessos: arremessos.length,
  };
}
Object.assign(api, { montar, atualizar, destruir, debug, CARROS: Object.keys(CARROS) });
window.turismo3d = api;
