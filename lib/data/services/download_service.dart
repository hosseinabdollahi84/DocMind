import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  static const String _modelUrl =
      "https://huggingface.co/Qwen/Qwen1.5-0.5B-Chat-GGUF/resolve/main/qwen1_5-0_5b-chat-q4_k_m.gguf";

  static const String _fileName = "qwen0_5b_chat.gguf";

  Future<bool> isModelDownloaded() async {
    final path = await getModelPath();
    final file = File(path);

    if (!await file.exists()) return false;

    final size = await file.length();
    if (size < (300 * 1024 * 1024)) {
      return false;
    }

    return true;
  }

  Future<String> getModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return "${dir.path}/$_fileName";
  }

  Future<void> downloadModel(Function(double) onProgress) async {
    try {
      final path = await getModelPath();
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }

      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(_modelUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception("HTTP Error: ${response.statusCode}");
      }

      final sink = file.openWrite();
      final totalBytes = response.contentLength;
      int receivedBytes = 0;

      await response
          .listen(
            (List<int> chunk) {
              receivedBytes += chunk.length;
              sink.add(chunk);

              if (totalBytes != -1) {
                final progress = receivedBytes / totalBytes;
                onProgress(progress);
              }
            },
            onDone: () async {
              await sink.flush();
              await sink.close();
            },
            onError: (e) {
              sink.close();
              if (file.existsSync()) {
                file.deleteSync();
              }
              throw e;
            },
            cancelOnError: true,
          )
          .asFuture();
    } catch (e) {
      rethrow;
    }
  }
}
