// lib/features/downloader/download_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloadService {
  static final YoutubeExplode _yt = YoutubeExplode();
  static final Dio _dio = Dio(); // File එක download කරන්න පාවිච්චි කරන්නේ මේක

  /// වීඩියෝ එකේ ලින්ක් එක සහ කොලිටි එක දුන්නම Download එක පටන් ගන්නා ප්‍රධාන Function එක
  static Future<void> startDownload({
    required String videoUrl,
    required String quality,
    required Function(int progress) onProgress, // Progress එක UI එකට යවන්න
    required Function(String message) onComplete, // ඉවර වුණාම කියන්න
  }) async {
    try {
      // 1. Storage Permission ගන්නවා
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        onComplete("Storage permission denied!");
        return;
      }

      // 2. වීඩියෝවේ විස්තර (Manifest) YouTube එකෙන් ගන්නවා
      var manifest = await _yt.videos.streamsClient.getManifest(videoUrl);
      var video = await _yt.videos.get(videoUrl);
      
      // ෆයිල් එකට දාන්න හොඳ නමක් හදාගන්නවා (හිස්තැන් සහ විශේෂ අකුරු අයින් කරලා)
      String cleanTitle = video.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      
      StreamInfo streamInfo;
      String fileExtension;

      // 3. Quality එක අනුව MP3 ද MP4 ද කියලා තෝරනවා
      if (quality == 'MP3') {
        // MP3 නම් audio විතරක් තියෙන හොඳම quality එක ගන්නවා
        streamInfo = manifest.audioOnly.withHighestBitrate();
        fileExtension = '.mp3';
      } else {
        // Video නම් audio+video දෙකම තියෙන (Muxed) හොඳම එක ගන්නවා
        streamInfo = manifest.muxed.bestQuality;
        fileExtension = '.mp4';
      }

      // 4. Save කරන තැන (Downloads folder එක) හොයාගන්නවා
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      String savePath = '${directory.path}/${cleanTitle}_Savely$fileExtension';

      // 5. ඇත්තම Stream URL එක අරගෙන Download එක පටන් ගන්නවා
      String actualDownloadUrl = streamInfo.url.toString();
      
      await _dio.download(
        actualDownloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // ප්‍රතිශතය (Percentage) ගණනය කරලා UI එකට යවනවා
            int progress = ((received / total) * 100).toInt();
            onProgress(progress);
          }
        },
      );

      onComplete("Download Finished: Saved to Downloads folder!");

    } catch (e) {
      onComplete("Download Failed: ${e.toString()}");
    }
  }
}