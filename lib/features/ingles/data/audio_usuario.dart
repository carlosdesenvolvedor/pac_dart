import 'package:flutter/foundation.dart';

import '../domain/audio_usuario.dart';
import '../domain/revisao.dart';
import 'audio_usuario_repository.dart';

/// O registro dos áudios que o aluno anexou às frases — o mesmo papel do
/// [AudioNativo] (frase em inglês → o que tocar), mas com os bytes do aluno e na
/// frente de tudo: a [VozIngles] consulta aqui ANTES da gravação do curso, da voz
/// gerada e da voz do aparelho. Quem só tem o texto da frase não precisa saber.
///
/// O índice (que frases têm áudio) vem numa leitura só; o áudio em si só é
/// baixado na 1ª vez que toca e fica em memória.
class AudioUsuario {
  AudioUsuario._();

  static AudioUsuarioRepository? _repo;
  static Map<String, InfoAudio> _indice = {};
  static final Map<String, ClipeAudio> _cache = {};

  /// Muda a cada anexo/remoção: as telas refazem o selo de "tem áudio seu".
  static final ValueNotifier<int> versao = ValueNotifier(0);

  /// Há onde guardar? (Sem repositório — outro curso, teste sem Firebase — o botão some.)
  static bool get disponivel => _repo != null;

  /// Liga o registro a [repo] e carrega o índice. Troca de conta = chamar de novo.
  static Future<void> iniciar(AudioUsuarioRepository repo) async {
    _repo = repo;
    _indice = {};
    _cache.clear();
    versao.value++;
    try {
      final indice = await repo.indice();
      if (identical(_repo, repo)) {
        _indice = indice;
        versao.value++;
      }
    } catch (_) {} // sem o índice: tudo toca como antes
  }

  /// A chave de uma frase (a mesma da revisão).
  static String chaveDe(String frase) => Revisao.chave(frase.trim());

  static bool tem(String frase) => _indice.containsKey(chaveDe(frase));

  static InfoAudio? infoDe(String frase) => _indice[chaveDe(frase)];

  /// O áudio do aluno para [frase] (baixa na 1ª vez), ou null.
  static Future<ClipeAudio?> clipeDe(String frase) async {
    final k = chaveDe(frase);
    if (!_indice.containsKey(k)) return null;
    final guardado = _cache[k];
    if (guardado != null) return guardado;
    final repo = _repo;
    if (repo == null) return null;
    try {
      final clipe = await repo.carregar(k);
      if (clipe != null) _cache[k] = clipe;
      return clipe;
    } catch (_) {
      return null;
    }
  }

  /// Anexa (ou troca) o áudio de [frase]. Devolve a mensagem de erro, ou null se deu certo.
  static Future<String?> adicionar(String frase, Uint8List bytes) async {
    final repo = _repo;
    if (repo == null) return 'O áudio do aluno não está disponível agora.';
    final erro = FormatosAudio.validar(bytes);
    if (erro != null) return erro;
    final clipe = ClipeAudio(bytes, FormatosAudio.detectar(bytes)!);
    final k = chaveDe(frase);
    try {
      await repo.salvar(k, clipe);
    } catch (_) {
      return 'Não consegui guardar o áudio. Confira a internet e tente de novo.';
    }
    _indice = {..._indice, k: InfoAudio(clipe.mime, clipe.tamanho)};
    _cache[k] = clipe;
    versao.value++;
    return null;
  }

  /// Tira o áudio de [frase]: ela volta à gravação do curso ou à voz do aparelho.
  static Future<String?> remover(String frase) async {
    final repo = _repo;
    if (repo == null) return 'O áudio do aluno não está disponível agora.';
    final k = chaveDe(frase);
    try {
      await repo.remover(k);
    } catch (_) {
      return 'Não consegui remover o áudio. Confira a internet e tente de novo.';
    }
    _indice = {..._indice}..remove(k);
    _cache.remove(k);
    versao.value++;
    return null;
  }

  /// Só para testes.
  static void limpar() {
    _repo = null;
    _indice = {};
    _cache.clear();
    versao.value++;
  }
}
