import 'package:ai_pdf/logic/lite_ai/chat_event.dart';
import 'package:ai_pdf/logic/lite_ai/chat_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/llm_service.dart';
import '../../data/services/pdf_service.dart';
import '../../logic/lite_ai/chat_bloc.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0,
        end: 10,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_animations[index].value),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  final bool isAiMode;
  final String filePath;
  final String fileName;

  const ChatScreen({
    super.key,
    required this.isAiMode,
    required this.filePath,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ChatBloc(PdfService(), LlmService())
            ..add(LoadDocumentEvent(filePath)),
      child: ChatView(fileName: fileName, isAiMode: isAiMode),
    );
  }
}

class ChatView extends StatefulWidget {
  final String fileName;
  final bool isAiMode;

  const ChatView({super.key, required this.fileName, required this.isAiMode});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];

  bool _isTyping = false;
  String _streamingResponse = "";

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _textController.clear();

      if (widget.isAiMode) {
        _isTyping = true;
        _streamingResponse = "";
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    FocusScope.of(context).unfocus();

    context.read<ChatBloc>().add(
      SearchQueryEvent(text, isAiMode: widget.isAiMode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context, widget.isAiMode, widget.fileName),
      body: BlocListener<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatStreamUpdate) {
            setState(() {
              _isTyping = false;
              _streamingResponse += state.token;
            });
            _scrollToBottom();
          } else if (state is ChatSuccess) {
            setState(() {
              _isTyping = false;

              if (widget.isAiMode) {
                if (_streamingResponse.isEmpty && state.results.isNotEmpty) {
                  _messages.add({
                    "role": "ai",
                    "text": state.results.join("\n"),
                  });
                } else {
                  _messages.add({"role": "ai", "text": _streamingResponse});
                }
                _streamingResponse = "";
              } else {
                if (state.results.isEmpty) {
                  _messages.add({
                    "role": "system",
                    "text": "No matches found.",
                  });
                } else {
                  for (var result in state.results) {
                    _messages.add({"role": "search_result", "text": result});
                  }
                }
              }
            });
            _scrollToBottom();
          } else if (state is ChatFailure) {
            setState(() {
              _isTyping = false;
              _messages.add({"role": "error", "text": state.error});
            });
          }
        },
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty && !_isTyping
                  ? _buildEmptyState(widget.isAiMode)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),

                      itemCount:
                          _messages.length +
                          (_isTyping || _streamingResponse.isNotEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length) {
                          if (_isTyping) {
                            return const Align(
                              alignment: Alignment.centerLeft,
                              child: TypingIndicator(),
                            );
                          } else {
                            return _buildAiMessageBubble(
                              _streamingResponse,
                              isStreaming: true,
                            );
                          }
                        }

                        final msg = _messages[index];
                        if (msg['role'] == 'user') {
                          return _buildUserMessageBubble(msg['text']);
                        } else if (msg['role'] == 'ai') {
                          return _buildAiMessageBubble(msg['text']);
                        } else if (msg['role'] == 'search_result') {
                          return _buildSearchResultCard(msg['text']);
                        } else {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                msg['text'],
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          );
                        }
                      },
                    ),
            ),
            _buildInputBar(widget.isAiMode),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMessageBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: widget.isAiMode ? Colors.deepPurple : Colors.blueAccent,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildAiMessageBubble(String text, {bool isStreaming = false}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          border: isStreaming
              ? Border.all(color: Colors.deepPurple.withOpacity(0.3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isStreaming)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: Colors.deepPurple),
                  SizedBox(width: 4),
                  Text(
                    "AI is typing...",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            if (isStreaming) SizedBox(height: 6),

            Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(String text) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.find_in_page_rounded, size: 16, color: Colors.blue),
                SizedBox(width: 6),
                Text(
                  "Found in document:",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(text, style: TextStyle(fontSize: 14, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isAiMode) {
    final primaryColor = isAiMode ? Colors.deepPurple : Colors.blueAccent;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(0.1),
            ),
            child: Icon(
              isAiMode ? Icons.auto_awesome : Icons.search,
              size: 40,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Start a conversation",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAiMode
                ? "Ask questions about the PDF content"
                : "Search for specific keywords",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isAiMode,
    String fileName,
  ) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fileName,
            style: const TextStyle(color: Colors.black, fontSize: 16),
          ),
          Text(
            isAiMode ? "AI Analyst Mode" : "Keyword Search Mode",
            style: TextStyle(
              color: isAiMode ? Colors.deepPurple : Colors.blue,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isAiMode) {
    final primaryColor = isAiMode ? Colors.deepPurple : Colors.blueAccent;
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: isAiMode ? "Ask AI..." : "Search text...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: primaryColor,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
