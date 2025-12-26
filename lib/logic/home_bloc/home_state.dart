import 'package:equatable/equatable.dart';

abstract class HomeState extends Equatable {
  final bool isAiMode;
  final bool isModelDownloaded;
  final String? recentFilePath;
  final String? recentFileName;

  const HomeState({
    this.isAiMode = false,
    this.isModelDownloaded = false,
    this.recentFilePath,
    this.recentFileName,
  });

  @override
  List<Object?> get props => [
    isAiMode,
    isModelDownloaded,
    recentFilePath,
    recentFileName,
  ];

  HomeState copyWith({
    bool? isAiMode,
    bool? isModelDownloaded,
    String? recentFilePath,
    String? recentFileName,
  }) {
    return HomeInitial(
      isAiMode: isAiMode ?? this.isAiMode,
      isModelDownloaded: isModelDownloaded ?? this.isModelDownloaded,
      recentFilePath: recentFilePath ?? this.recentFilePath,
      recentFileName: recentFileName ?? this.recentFileName,
    );
  }
}

class HomeInitial extends HomeState {
  const HomeInitial({
    super.isAiMode,
    super.isModelDownloaded,
    super.recentFilePath,
    super.recentFileName,
  });
}

class HomeDownloading extends HomeState {
  final double progress;

  const HomeDownloading(
    this.progress, {
    super.isAiMode,
    super.isModelDownloaded,
    super.recentFilePath,
    super.recentFileName,
  });

  @override
  List<Object?> get props => [
    progress,
    isAiMode,
    isModelDownloaded,
    recentFilePath,
    recentFileName,
  ];
}

class HomeFilePicking extends HomeState {
  const HomeFilePicking({
    super.isAiMode,
    super.isModelDownloaded,
    super.recentFilePath,
    super.recentFileName,
  });
}

class HomeFilePickedSuccess extends HomeState {
  final String filePath;
  final String fileName;

  const HomeFilePickedSuccess({
    required this.filePath,
    required this.fileName,
    required super.isAiMode,
    required super.isModelDownloaded,
    super.recentFilePath,
    super.recentFileName,
  });

  @override
  List<Object?> get props => [
    filePath,
    fileName,
    isAiMode,
    isModelDownloaded,
    recentFilePath,
    recentFileName,
  ];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(
    this.message, {
    super.isAiMode,
    super.isModelDownloaded,
    super.recentFilePath,
    super.recentFileName,
  });
}
