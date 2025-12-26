import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class LoadDocumentEvent extends ChatEvent {
  final String path;

  const LoadDocumentEvent(this.path);

  @override
  List<Object> get props => [path];
}

class SearchQueryEvent extends ChatEvent {
  final String query;
  final bool isAiMode;

  const SearchQueryEvent(this.query, {required this.isAiMode});

  @override
  List<Object> get props => [query, isAiMode];
}
