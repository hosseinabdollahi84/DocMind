import 'dart:async';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'download_service.dart';

class LlmService {
  Llama? _llama;
  final DownloadService _downloadService = DownloadService();

  void dispose() {
    _llama?.dispose();
    _llama = null;
  }

  Stream<String> generateResponse(String context, String query) async* {
    try {
      if (context.trim().isEmpty) {
        yield "Context is empty.";
        return;
      }

      if (_llama == null) {
        final modelPath = await _downloadService.getModelPath();

        _llama = Llama(
          modelPath,
          ModelParams(),
          ContextParams()
            ..nCtx = 2048
            ..nBatch = 256
            ..nThreads = 4
            ..nPredict = 256,
        );
      }

      String cleanContext = context.replaceAll(RegExp(r'\s+'), ' ').trim();

      if (cleanContext.length > 2000) {
        cleanContext = cleanContext.substring(0, 2000);
      }

      final prompt = _buildStrictPrompt(cleanContext, query);

      _llama!.setPrompt(prompt);

      while (true) {
        await Future.delayed(const Duration(milliseconds: 1));
        var (token, done) = _llama!.getNext();

        if (!token.contains("<|im_") && token.trim().isNotEmpty) {
          yield token;
        }

        if (done) break;
      }
    } catch (e) {
      yield "Error: $e";
    }
  }

  String _buildStrictPrompt(String contextText, String userQuery) {
    return """<|im_start|>system
You are a helpful assistant. Answer the question based on the context below. Keep the answer short.
<|im_end|>
<|im_start|>user
Context:
$contextText

Question:
$userQuery
<|im_end|>
<|im_start|>assistant
""";
  }
}
