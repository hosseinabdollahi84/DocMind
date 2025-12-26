import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class CheckModelStatusEvent extends HomeEvent {}

class StartDownloadModelEvent extends HomeEvent {}

class LoadRecentFileEvent extends HomeEvent {}

class OpenRecentFileEvent extends HomeEvent {}

class ToggleModeEvent extends HomeEvent {
  final bool isAiMode;
  ToggleModeEvent(this.isAiMode);
  @override
  List<Object> get props => [isAiMode];
}

class PickFileEvent extends HomeEvent {}
