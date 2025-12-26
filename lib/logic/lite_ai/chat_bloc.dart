import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/pdf_service.dart';
import '../../data/services/llm_service.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final PdfService _pdfService;
  final LlmService _llmService;

  String _cachedText = "";

  ChatBloc(this._pdfService, this._llmService) : super(ChatInitial()) {
    on<LoadDocumentEvent>((event, emit) async {
      emit(ChatLoading());
      try {
        final text = await _pdfService.extractText(event.path);
        _cachedText = text;
        emit(ChatReady(text));
      } catch (e) {
        emit(ChatFailure("Error loading file: $e"));
      }
    });

    on<SearchQueryEvent>((event, emit) async {
      if (_cachedText.isEmpty) return;

      if (event.isAiMode) {
        try {
          emit(
            ChatStreamUpdate(
              "🔍 DEBUG PDF: [${_cachedText.substring(0, _cachedText.length > 50 ? 50 : _cachedText.length)}...]\n\n",
            ),
          );

          final stream = _llmService.generateResponse(_cachedText, event.query);

          await for (final token in stream) {
            emit(ChatStreamUpdate(token));
          }
          emit(const ChatSuccess(results: [], isAi: true));
        } catch (e) {
          emit(ChatFailure("AI Error: $e"));
        }
      } else {
        emit(ChatLoading());

        await Future.delayed(const Duration(milliseconds: 200));

        final results = _performSimpleSearch(_cachedText, event.query);

        emit(ChatSuccess(results: results, isAi: false));
      }
    });
  }

  List<String> _performSimpleSearch(String text, String query) {
    if (query.trim().isEmpty) return [];

    final sentences = text.split(RegExp(r'(?<=[.?!])\s+'));

    return sentences
        .where((s) => s.toLowerCase().contains(query.toLowerCase()))
        .take(10)
        .map((s) => s.trim())
        .toList();
  }

  @override
  Future<void> close() {
    _llmService.dispose();
    return super.close();
  }
}
