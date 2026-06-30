// lib/features/downloader/download_provider.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

enum DownloadStatus { downloading, paused, completed, failed }

class DownloadTask {
  final String id;
  final String title;
  final String url; // Resume කරන්න URL එක ඕනේ
  final String savePath; 
  final double progress;
  final String downloadedSize;
  final String totalSize;
  final DownloadStatus status;
  final CancelToken? cancelToken;

  DownloadTask({
    required this.id, required this.title, required this.url, required this.savePath,
    this.progress = 0.0, this.downloadedSize = '0.0 MB', this.totalSize = '0.0 MB',
    this.status = DownloadStatus.downloading, this.cancelToken,
  });

  DownloadTask copyWith({
    double? progress, String? downloadedSize, String? totalSize, DownloadStatus? status, CancelToken? cancelToken,
  }) {
    return DownloadTask(
      id: id, title: title, url: url, savePath: savePath,
      progress: progress ?? this.progress, downloadedSize: downloadedSize ?? this.downloadedSize,
      totalSize: totalSize ?? this.totalSize, status: status ?? this.status, cancelToken: cancelToken ?? this.cancelToken,
    );
  }
}

class DownloadNotifier extends StateNotifier<Map<String, DownloadTask>> {
  DownloadNotifier() : super({});
  final Dio _dio = Dio();

  Future<bool> _requestPermissions() async {
    if (!Platform.isAndroid) return true;
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage, Permission.manageExternalStorage, Permission.videos, Permission.audio,
    ].request();
    return statuses.values.any((status) => status.isGranted);
  }

  Future<void> startDownload(String videoId, String title, String url, bool isAudio, String saveDirectory) async {
    if (!await _requestPermissions()) return;

    String ext = isAudio ? 'm4a' : 'mp4';
    String fileName = '${title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_')}_Savely.$ext';
    Directory dir = Directory(saveDirectory);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    String savePath = '${dir.path}/$fileName';

    final cancelToken = CancelToken();
    state = { ...state, videoId: DownloadTask(id: videoId, title: title, url: url, savePath: savePath, cancelToken: cancelToken) };
    
    _downloadFile(videoId, url, savePath, cancelToken, false);
  }

  Future<void> _downloadFile(String videoId, String url, String savePath, CancelToken cancelToken, bool isResume) async {
    try {
      int downloadedBytes = 0;
      Options options = Options();

      // Resume කරනවා නම් කලින් නවත්තපු තැනින් (byte range) පටන් ගන්නවා
      if (isResume) {
        File file = File(savePath);
        if (file.existsSync()) {
          downloadedBytes = file.lengthSync();
          options = Options(headers: {'range': 'bytes=$downloadedBytes-'});
        }
      }

      await _dio.download(
        url, savePath, cancelToken: cancelToken, options: options,
        deleteOnError: false, // Error ආවොත් ෆයිල් එක මකන්න එපා (Resume කරන්න ඕනේ නිසා)
        onReceiveProgress: (received, total) {
          int actualReceived = received + downloadedBytes;
          int actualTotal = total != -1 ? total + downloadedBytes : -1;
          
          if (actualTotal != -1) {
            state = {
              ...state,
              videoId: state[videoId]!.copyWith(
                progress: actualReceived / actualTotal,
                downloadedSize: '${(actualReceived / (1024 * 1024)).toStringAsFixed(1)} MB',
                totalSize: '${(actualTotal / (1024 * 1024)).toStringAsFixed(1)} MB',
                status: DownloadStatus.downloading,
              ),
            };
          }
        },
      );

      state = { ...state, videoId: state[videoId]!.copyWith(progress: 1.0, status: DownloadStatus.completed) };
      
    } catch (e) {
      // අලුත් කේතය: e යනු DioException එකක් දැයි මුලින්ම පරීක්ෂා කරයි
      if (e is DioException && CancelToken.isCancel(e)) {
        state = { ...state, videoId: state[videoId]!.copyWith(status: DownloadStatus.paused) };
      } else {
        state = { ...state, videoId: state[videoId]!.copyWith(status: DownloadStatus.failed) };
      }
    }
  }

  void pauseDownload(String videoId) {
    state[videoId]?.cancelToken?.cancel();
  }

  void resumeDownload(String videoId) {
    final task = state[videoId];
    if (task != null) {
      final newCancelToken = CancelToken();
      state = { ...state, videoId: task.copyWith(cancelToken: newCancelToken, status: DownloadStatus.downloading) };
      _downloadFile(videoId, task.url, task.savePath, newCancelToken, true);
    }
  }

  void cancelAndDelete(String videoId) {
    final task = state[videoId];
    if (task != null) {
      task.cancelToken?.cancel();
      File file = File(task.savePath);
      if (file.existsSync()) file.deleteSync(); // බාගෙට ඩවුන්ලෝඩ් වෙච්ච ෆයිල් එක මකනවා
      
      var newState = Map<String, DownloadTask>.from(state);
      newState.remove(videoId);
      state = newState;
    }
  }
}

final downloadProvider = StateNotifierProvider<DownloadNotifier, Map<String, DownloadTask>>((ref) => DownloadNotifier());