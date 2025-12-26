import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/download_service.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final DownloadService _downloadService = DownloadService();

  HomeBloc() : super(const HomeInitial()) {
    on<LoadRecentFileEvent>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('recent_path');
      final name = prefs.getString('recent_name');

      if (path != null && name != null) {
        emit(state.copyWith(recentFilePath: path, recentFileName: name));
      }
    });

    on<OpenRecentFileEvent>((event, emit) {
      if (state.recentFilePath != null && state.recentFileName != null) {
        emit(
          HomeFilePickedSuccess(
            filePath: state.recentFilePath!,
            fileName: state.recentFileName!,
            isAiMode: state.isAiMode,
            isModelDownloaded: state.isModelDownloaded,
            recentFilePath: state.recentFilePath,
            recentFileName: state.recentFileName,
          ),
        );
      }
    });

    on<CheckModelStatusEvent>((event, emit) async {
      final exists = await _downloadService.isModelDownloaded();
      emit(state.copyWith(isModelDownloaded: exists));
    });

    on<StartDownloadModelEvent>((event, emit) async {
      emit(
        HomeDownloading(
          0.0,
          isAiMode: true,
          isModelDownloaded: false,
          recentFilePath: state.recentFilePath,
          recentFileName: state.recentFileName,
        ),
      );

      try {
        await _downloadService.downloadModel((progress) {
          if (!isClosed) {
            emit(
              HomeDownloading(
                progress,
                isAiMode: true,
                isModelDownloaded: false,
                recentFilePath: state.recentFilePath,
                recentFileName: state.recentFileName,
              ),
            );
          }
        });

        if (!isClosed) {
          emit(
            HomeInitial(
              isAiMode: true,
              isModelDownloaded: true,
              recentFilePath: state.recentFilePath,
              recentFileName: state.recentFileName,
            ),
          );
        }
      } catch (e) {
        if (!isClosed) {
          emit(
            HomeError(
              "Download failed: $e",
              isAiMode: true,
              isModelDownloaded: false,
              recentFilePath: state.recentFilePath,
              recentFileName: state.recentFileName,
            ),
          );
        }
      }
    });

    on<ToggleModeEvent>((event, emit) async {
      emit(state.copyWith(isAiMode: event.isAiMode));
    });

    on<PickFileEvent>((event, emit) async {
      final currentMode = state.isAiMode;
      final downloaded = state.isModelDownloaded;
      final oldPath = state.recentFilePath;
      final oldName = state.recentFileName;

      emit(
        HomeFilePicking(
          isAiMode: currentMode,
          isModelDownloaded: downloaded,
          recentFilePath: oldPath,
          recentFileName: oldName,
        ),
      );

      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'png', 'txt'],
        );

        if (result != null && result.files.single.path != null) {
          final newPath = result.files.single.path!;
          final newName = result.files.single.name;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('recent_path', newPath);
          await prefs.setString('recent_name', newName);

          emit(
            HomeFilePickedSuccess(
              filePath: newPath,
              fileName: newName,
              isAiMode: currentMode,
              isModelDownloaded: downloaded,
              recentFilePath: newPath,
              recentFileName: newName,
            ),
          );
        } else {
          emit(
            HomeInitial(
              isAiMode: currentMode,
              isModelDownloaded: downloaded,
              recentFilePath: oldPath,
              recentFileName: oldName,
            ),
          );
        }
      } catch (e) {
        emit(
          HomeError(
            "error: $e",
            isAiMode: currentMode,
            isModelDownloaded: downloaded,
            recentFilePath: oldPath,
            recentFileName: oldName,
          ),
        );
      }
    });
  }
}
