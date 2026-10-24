import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../ingles/domain/assistir/historia_licao.dart';
import '../../../ingles/presentation/widgets/elenco_ingles.dart';
import '../../domain/historia_turismo.dart';

/// 📺 Os figurantes das historinhas das lições (atendente, recepcionista, dev-novo…): a aparência no palco
/// e o rótulo do chip do balão. Só no palco: o `RostoDaFaixa` do Ouvir e a lição continuam com
/// `ElencoIngles.de` (diferença assumida, plano §14).
///
/// - Os 42 [figurantesConhecidos] têm uma aparência FIXA (tabela `const`), todas distintas entre si e
///   distintas do elenco das lições: dois papéis na mesma lição nunca saem iguais, e a cor do chip (a roupa)
///   não se confunde com a de ninguém.
/// - O gênero de cada papel segue a VOZ que o `tools/ingles/vozes_google.py` sorteou para ele (o mp3 que o
///   Ouvir toca com a boca do personagem): a `guia` fala com voz de homem, a `motorista` com voz de mulher.
///   Os 3 só-mudos (`oficial`, `garcom`, `vendedora`) seguem a palavra.
/// - Uniformes, com o que o desenho sabe fazer: crachá no cordão (`detalhe`) em quem atende (atendente,
///   recepcionista, caixa, vendedor/vendedora, garçom, segurança, oficial), jaleco na farmacêutica e gorro
///   na motorista (o desenho não tem avental nem boné).
/// - Só um papel FORA da tabela (papel novo no currículo) cai na paleta por hash estável (FNV-1a sobre os
///   bytes UTF-8, nunca `String.hashCode`, que muda entre plataformas e execuções).
abstract final class FigurantesHistoria {
  /// Os que não são figurantes: o elenco das lições, os extras do Turismo e quem não tem corpo.
  static const _naoFigurantes = {'max', 'kim', narrador, 'narradora', '', 'placa'};

  /// Não está no elenco das lições nem é max/kim/narrador/''/placa.
  static bool ehFigurante(String quem) => !elencoDasLicoes.contains(quem) && !_naoFigurantes.contains(quem);

  /// A aparência do figurante: a da tabela fixa; papel novo (fora da tabela) → paleta por hash estável.
  static Aparencia de(String quem) => _tabela[quem] ?? _porHash(quem);

  /// O rótulo do chip do balão: o da tabela ('Dev novo', 'Amigo do Ben', 'CFO', 'Farmacêutica'…); senão o
  /// `-` vira espaço e a 1ª letra fica maiúscula.
  static String rotulo(String quem) {
    if (_rotulos[quem] case final r?) return r;
    if (quem.isEmpty) return '';
    final s = quem.replaceAll('-', ' ');
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Os papéis com aparência fixa (= [figurantesConhecidos]; o teste confere).
  @visibleForTesting
  static Iterable<String> get tabelados => _tabela.keys;

  /// FNV-1a de 32 bits sobre os bytes UTF-8 de [s]. Sem multiplicação que passe de 2^53 (igual na web).
  @visibleForTesting
  static int fnv1a(String s) {
    var h = 0x811C9DC5;
    for (final b in utf8.encode(s)) {
      h ^= b;
      // h × 0x01000193 = h × 0x193 + h × 2^24, módulo 2^32 (cada parcela < 2^42)
      h = (h * 0x193 + (h & 0xFF) * 0x1000000) % 0x100000000;
    }
    return h;
  }

  // ───────────────────────── a tabela fixa ─────────────────────────

  static const _clara = Color(0xFFFFDCC4);
  static const _rosada = Color(0xFFFCD3BC);
  static const _morena = Color(0xFFD9A07A);
  static const _marrom = Color(0xFFB57A55);
  static const _amarelada = Color(0xFFF7D9B5);
  static const _escura = Color(0xFF8D5A3B);
  static const _retinta = Color(0xFF6B4226);
  static const _trigueira = Color(0xFFEBB58F);

  static const _cracha = Color(0xFFF2C94C);

  static const Map<String, Aparencia> _tabela = {
    'amigo-do-ben': Aparencia(
        pele: _trigueira, cabelo: Color(0xFF8A5A2B), roupa: Color(0xFF0077B6), estilo: Cabelo.cacheado),
    'atendente': Aparencia(
        pele: _marrom,
        cabelo: Color(0xFF1E1A1A),
        roupa: Color(0xFF1E7B4F),
        estilo: Cabelo.rabo,
        detalhe: _cracha,
        cilios: true,
        brincos: true),
    'caixa': Aparencia(
        pele: _clara,
        cabelo: Color(0xFFC9772E),
        roupa: Color(0xFF9E2A5E),
        estilo: Cabelo.curto,
        detalhe: Color(0xFF1E1E28)),
    'cfo': Aparencia(
        pele: _amarelada, cabelo: Color(0xFF2A2A2A), roupa: Color(0xFF4A4E69), estilo: Cabelo.lateral, oculos: true),
    'cliente': Aparencia(pele: _morena, cabelo: Color(0xFF3B2A22), roupa: Color(0xFFF4A259), estilo: Cabelo.curto),
    'colega': Aparencia(pele: _rosada, cabelo: Color(0xFF7A5230), roupa: Color(0xFF6B705C), estilo: Cabelo.lateral),
    'convidada': Aparencia(
        pele: _retinta,
        cabelo: Color(0xFF1A1110),
        roupa: Color(0xFFF7B2C4),
        estilo: Cabelo.cacheado,
        brincos: true,
        cilios: true),
    'convidado': Aparencia(pele: _escura, cabelo: Color(0xFF1A1110), roupa: Color(0xFF7A4E2D), estilo: Cabelo.curto),
    'corretora': Aparencia(
        pele: _clara,
        cabelo: Color(0xFF8B4513),
        roupa: Color(0xFF8C1C13),
        estilo: Cabelo.bob,
        brincos: true,
        cilios: true),
    'desenvolvedora': Aparencia(
        pele: _amarelada,
        cabelo: Color(0xFF101014),
        roupa: Color(0xFF3D348B),
        estilo: Cabelo.longo,
        oculos: true,
        cilios: true),
    'dev-junior': Aparencia(
        pele: _clara, cabelo: Color(0xFFE3B35A), roupa: Color(0xFFA3D977), estilo: Cabelo.cacheado),
    'dev-nova': Aparencia(
        pele: _marrom, cabelo: Color(0xFF5A2D82), roupa: Color(0xFFFFD6A5), estilo: Cabelo.rabo, cilios: true),
    'dev-novo': Aparencia(
        pele: _morena, cabelo: Color(0xFF241612), roupa: Color(0xFF155E75), estilo: Cabelo.lateral, oculos: true),
    'dev-pleno': Aparencia(
        pele: _trigueira, cabelo: Color(0xFF4A3426), roupa: Color(0xFF5B4B8A), estilo: Cabelo.curto, sardas: true),
    'diretora': Aparencia(
        pele: _escura,
        cabelo: Color(0xFF2E1E1A),
        roupa: Color(0xFF3A0CA3),
        estilo: Cabelo.coque,
        brincos: true,
        cilios: true),
    'engenheira': Aparencia(
        pele: _rosada,
        cabelo: Color(0xFFC0612B),
        roupa: Color(0xFFCDE7B0),
        estilo: Cabelo.rabo,
        oculos: true,
        cilios: true),
    'engenheiro': Aparencia(pele: _retinta, cabelo: Color(0xFF111111), roupa: Color(0xFFE07A1F), estilo: Cabelo.curto),
    'entrevistador': Aparencia(
        pele: _amarelada, cabelo: Color(0xFF6E6E6E), roupa: Color(0xFF37474F), estilo: Cabelo.lateral, oculos: true),
    'estagiaria': Aparencia(
        pele: _morena,
        cabelo: Color(0xFF6B3E26),
        roupa: Color(0xFFB5EAD7),
        estilo: Cabelo.franja,
        cilios: true,
        brincos: true),
    'farmaceutica': Aparencia(
        pele: _clara,
        cabelo: Color(0xFF2B1B17),
        roupa: Color(0xFF3FA7D6),
        estilo: Cabelo.longo,
        jaleco: true,
        cilios: true),
    'gestora': Aparencia(
        pele: _amarelada,
        cabelo: Color(0xFF7A4B2A),
        roupa: Color(0xFF6D2E46),
        estilo: Cabelo.bob,
        oculos: true,
        cilios: true),
    'guia': Aparencia(pele: _marrom, cabelo: Color(0xFF1E1A1A), roupa: Color(0xFF8AB17D), estilo: Cabelo.cacheado),
    'marido': Aparencia(pele: _rosada, cabelo: Color(0xFF3B2A22), roupa: Color(0xFF4361EE), estilo: Cabelo.curto),
    'moradora': Aparencia(
        pele: _marrom,
        cabelo: Color(0xFFA8A8A8),
        roupa: Color(0xFFC9ADA7),
        estilo: Cabelo.coque,
        oculos: true,
        cilios: true),
    'motorista': Aparencia(
        pele: _trigueira,
        cabelo: Color(0xFF2B1E18),
        roupa: Color(0xFF5F0F40),
        estilo: Cabelo.rabo,
        gorro: true,
        cilios: true),
    'participante': Aparencia(
        pele: _amarelada,
        cabelo: Color(0xFF3A2418),
        roupa: Color(0xFF90E0EF),
        estilo: Cabelo.franja,
        cilios: true,
        brincos: true),
    'passageira': Aparencia(
        pele: _rosada,
        cabelo: Color(0xFFE8C07D),
        roupa: Color(0xFF7B2CBF),
        estilo: Cabelo.longo,
        cilios: true,
        brincos: true),
    'passageiro': Aparencia(pele: _morena, cabelo: Color(0xFF1E1A1A), roupa: Color(0xFFE5989B), estilo: Cabelo.lateral),
    'proprietario': Aparencia(
        pele: _clara, cabelo: Color(0xFF9A9A9A), roupa: Color(0xFF5E3023), estilo: Cabelo.curto, oculos: true),
    'recepcionista': Aparencia(
        pele: _morena,
        cabelo: Color(0xFF1E1A1A),
        roupa: Color(0xFF00509D),
        estilo: Cabelo.coque,
        detalhe: Color(0xFFC1121F),
        cilios: true,
        brincos: true),
    'recrutadora': Aparencia(
        pele: _clara,
        cabelo: Color(0xFF4A2C20),
        roupa: Color(0xFF1B4332),
        estilo: Cabelo.longo,
        cilios: true,
        brincos: true),
    'seguranca': Aparencia(
        pele: _retinta,
        cabelo: Color(0xFF111111),
        roupa: Color(0xFF1C1C1C),
        estilo: Cabelo.curto,
        detalhe: Color(0xFF9E9E9E)),
    'stakeholder': Aparencia(
        pele: _amarelada, cabelo: Color(0xFF2A2A2A), roupa: Color(0xFF9C6644), estilo: Cabelo.curto),
    'supervisora': Aparencia(
        pele: _escura, cabelo: Color(0xFF3A2418), roupa: Color(0xFFA4133C), estilo: Cabelo.bob, cilios: true),
    'vendedor': Aparencia(
        pele: _trigueira,
        cabelo: Color(0xFF6B4630),
        roupa: Color(0xFF4F772D),
        estilo: Cabelo.lateral,
        detalhe: _cracha),
    'vizinha': Aparencia(
        pele: _rosada,
        cabelo: Color(0xFFC76B3B),
        roupa: Color(0xFF83C5BE),
        estilo: Cabelo.cacheado,
        sardas: true,
        cilios: true),
    // o conto "Jack Hannaford" (B1): o velho soldado esperto, o fazendeiro e a esposa dele
    'jack': Aparencia(
        pele: _rosada, cabelo: Color(0xFF9A9A9A), roupa: Color(0xFF8E3B46), estilo: Cabelo.lateral, sardas: true),
    'fazendeiro': Aparencia(
        pele: _trigueira, cabelo: Color(0xFF5C3A21), roupa: Color(0xFF6A994E), estilo: Cabelo.curto),
    'esposa': Aparencia(
        pele: _clara, cabelo: Color(0xFF8B5A2B), roupa: Color(0xFFC17C74), estilo: Cabelo.coque, cilios: true),
    // só figurante mudo (D20)
    'oficial': Aparencia(
        pele: _marrom,
        cabelo: Color(0xFF1E1A1A),
        roupa: Color(0xFF1D3557),
        estilo: Cabelo.curto,
        detalhe: Color(0xFFE9C46A)),
    'garcom': Aparencia(
        pele: _clara,
        cabelo: Color(0xFF3B2A22),
        roupa: Color(0xFF3C1518),
        estilo: Cabelo.lateral,
        detalhe: Color(0xFFF5F5F5)),
    'vendedora': Aparencia(
        pele: _amarelada,
        cabelo: Color(0xFF2B1B17),
        roupa: Color(0xFFD00070),
        estilo: Cabelo.rabo,
        detalhe: _cracha,
        cilios: true,
        brincos: true),
  };

  static const _rotulos = {
    'amigo-do-ben': 'Amigo do Ben',
    'cfo': 'CFO',
    'dev-junior': 'Dev júnior',
    'dev-nova': 'Dev nova',
    'dev-novo': 'Dev novo',
    'dev-pleno': 'Dev pleno',
    'estagiaria': 'Estagiária',
    'farmaceutica': 'Farmacêutica',
    'proprietario': 'Proprietário',
    'seguranca': 'Segurança',
    'garcom': 'Garçom',
  };

  // ───────────────────────── papel novo: paleta por hash ─────────────────────────

  static const _peles = [_clara, _rosada, _morena, _marrom, _amarelada, _escura, _retinta, _trigueira];
  static const _cabelos = [
    Color(0xFF1E1A1A), Color(0xFF3B2A22), Color(0xFF6B4630), Color(0xFF8A5A2B),
    Color(0xFFC0612B), Color(0xFFE3B35A), Color(0xFF9A9A9A), Color(0xFF2B1B17),
  ];
  static const _estilosDela = [Cabelo.longo, Cabelo.rabo, Cabelo.coque, Cabelo.bob, Cabelo.franja, Cabelo.cacheado];
  static const _estilosDele = [Cabelo.curto, Cabelo.lateral, Cabelo.cacheado];
  /// Roupas com contraste ≥ 4,5 no chip (texto branco ou escuro), fora das cores da tabela.
  static const _roupas = [
    Color(0xFF264653), Color(0xFFE76F51), Color(0xFF6A4C93), Color(0xFF1565A0),
    Color(0xFF8AC926), Color(0xFFFF595E), Color(0xFF52489C), Color(0xFFF4A261),
    Color(0xFF1F7A3A), Color(0xFFC9184A), Color(0xFF4CC9F0), Color(0xFF7F4F24),
  ];

  /// O mesmo critério de gênero do `vozes_google.py` (papéis e terminações); neutro → pelo hash.
  static const _femininos = {
    'recrutadora', 'diretora', 'moradora', 'engenheira', 'corretora', 'passageira', 'estagiaria', 'gestora',
    'farmaceutica', 'desenvolvedora', 'vizinha', 'esposa', 'mae', 'namorada', 'professora', 'medica',
    'enfermeira', 'chefe-dela', 'convidada', 'dev-nova', 'supervisora', 'recepcionista', 'atendente', 'amiga',
  };
  static const _masculinos = {
    'entrevistador', 'proprietario', 'passageiro', 'vendedor', 'amigo-do-ben', 'convidado', 'marido',
    'engenheiro', 'dev-novo', 'dev-junior', 'pai', 'irmao', 'professor', 'medico',
  };

  static bool _feminino(String quem, int h) {
    if (_femininos.contains(quem) || quem.endsWith('ora') || quem.endsWith('eira') || quem.endsWith('ada') ||
        quem.endsWith('-nova')) {
      return true;
    }
    if (_masculinos.contains(quem) || quem.endsWith('or') || quem.endsWith('eiro')) return false;
    return h & 1 == 1;
  }

  static Aparencia _porHash(String quem) {
    final h = fnv1a(quem);
    final ela = _feminino(quem, h);
    final estilos = ela ? _estilosDela : _estilosDele;
    return Aparencia(
      pele: _peles[(h >> 1) % _peles.length],
      cabelo: _cabelos[(h >> 5) % _cabelos.length],
      roupa: _roupas[(h >> 9) % _roupas.length],
      estilo: estilos[(h >> 14) % estilos.length],
      oculos: (h >> 18) % 4 == 0,
      cilios: ela,
      brincos: ela && (h >> 21) % 2 == 0,
    );
  }
}
