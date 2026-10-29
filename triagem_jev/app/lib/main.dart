import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/triagem/data/arquivos_triagem.dart';
import 'features/triagem/data/chaves_api.dart';
import 'features/triagem/data/cliente_decisao.dart';
import 'features/triagem/data/cliente_llm.dart';
import 'features/triagem/data/clientes_simulados.dart';
import 'features/triagem/domain/config_triagem.dart';
import 'features/triagem/presentation/triagem_cubit.dart';
import 'features/triagem/presentation/triagem_page.dart';

/// Endereço do Worker que guarda as chaves (ex.: http://localhost:8787 com `wrangler dev`).
/// Vazio = só o modo simulado. Passe com `--dart-define=WORKER_URL=...`.
const workerUrl = String.fromEnvironment('WORKER_URL');

/// Modelos da rodada real (ids do OpenRouter; precisam existir em assets/precos.json).
const modeloDecisao = String.fromEnvironment('MODELO_DECISAO', defaultValue: 'typesafe/jev-1.14');

/// Só se o Worker publicado tiver TOKEN_ACESSO.
const tokenAcesso = String.fromEnvironment('TOKEN_ACESSO');

const modeloLlm = String.fromEnvironment('MODELO_LLM', defaultValue: 'anthropic/claude-haiku-5.5');

(ClienteDecisaoOpenRouter, ClienteLlmOpenRouter) clientesReais(Uri worker, ChavesApi chaves) => (
  ClienteDecisaoOpenRouter(worker: worker, modelo: modeloDecisao, tokenAcesso: tokenAcesso),
  ClienteLlmOpenRouter(worker: worker, modelo: modeloLlm, tokenAcesso: tokenAcesso, chaves: chaves),
);

void main() {
  final worker = workerUrl.isEmpty ? null : Uri.parse(workerUrl);
  runApp(
    BlocProvider(
      create: (_) => TriagemCubit(
        arquivos: ArquivosTriagem(),
        realDisponivel: worker != null,
        config: const ConfigTriagem(modeloDecisao: modeloDecisao, modeloLlm: modeloLlm),
        fabrica: (config, {required real, required chaves}) =>
            real && worker != null ? clientesReais(worker, chaves) : (SimuladoDecisionClient(), SimuladoLlmClient()),
      )..iniciar(),
      child: const AppTriagem(),
    ),
  );
}

class AppTriagem extends StatelessWidget {
  const AppTriagem({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Triagem Jev + LLM',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: const Color(0xFF3949AB), useMaterial3: true),
    home: const TriagemPage(),
  );
}
