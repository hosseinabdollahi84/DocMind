import 'package:equatable/equatable.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatReady extends ChatState {
  final String fullText;
  const ChatReady(this.fullText);
}

class ChatStreamUpdate extends ChatState {
  final String token;
  const ChatStreamUpdate(this.token);

  @override
  List<Object?> get props => [token, DateTime.now()];
}

class ChatSuccess extends ChatState {
  final List<String> results;
  final bool isAi;

  const ChatSuccess({required this.results, this.isAi = false});

  @override
  List<Object?> get props => [results, isAi];
}

class ChatFailure extends ChatState {
  final String error;
  const ChatFailure(this.error);

  @override
  List<Object?> get props => [error];
}
