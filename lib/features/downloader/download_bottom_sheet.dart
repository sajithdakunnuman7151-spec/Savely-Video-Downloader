// lib/features/downloader/download_bottom_sheet.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DownloadBottomSheet extends StatefulWidget {
  final String url;
  const DownloadBottomSheet({super.key, required this.url});

  // වෙනත් තැන් වලින් මේ මෙනුව ඕපන් කරන්න පාවිච්චි කරන Function එක
  static void show(BuildContext context, String url) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DownloadBottomSheet(url: url),
    );
  }

  @override
  State<DownloadBottomSheet> createState() => _DownloadBottomSheetState();
}

class _DownloadBottomSheetState extends State<DownloadBottomSheet> {
  final YoutubeExplode _yt = YoutubeExplode();
  final Dio _dio = Dio();

  bool _isLoading = true;
  Video? _video;
  StreamManifest? _manifest;

  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusMessage = 'Getting video details...';

  @override
  void initState() {
    super.initState();
    _fetchVideoDetails();
  }

  @override
  void dispose() {
    _yt.close(); // මතකය ඉතිරි කරගන්න අපි මේක close කරනවා
    super.dispose();
  }

  // 1. අන්තර්ජාලයෙන් වීඩියෝ එකේ විස්තර සහ කොලිටි ටික ගෙනෙනවා
  Future<void> _fetchVideoDetails() async {
    try {
      var videoId = VideoId(widget.url);
      _video = await _yt.videos.get(videoId);
      _manifest = await _yt.videos.streamsClient.getManifest(videoId);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error loading video. Invalid link?';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startDownload(StreamInfo streamInfo, bool isAudio) async {
    // 🌟 වෙබ් එකේදී ඩවුන්ලෝඩ් කරන්න හැදුවොත් Crash වෙන්නේ නැතුව මැසේජ් එකක් දෙනවා
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloads are only supported on Android devices!'),
          backgroundColor: Colors.orange,
        ),
      );
      return; // මීට පල්ලෙහා තියෙන Permission කේත ක්‍රියාත්මක වෙන්නේ නැත
    }

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusMessage = 'Requesting storage permission...';
    });

    
    if (Platform.isAndroid) {
      var status = await Permission.storage.request();
      
      if (!status.isGranted) {
        var manageStatus = await Permission.manageExternalStorage.request();
        if (!manageStatus.isGranted) {
          setState(() {
            _statusMessage = 'Storage Permission Denied!';
            _isDownloading = false;
          });
          return;
        }
      }
    }

    try {
      setState(() {
        _statusMessage = 'Downloading...';
      });

      // ෆයිල් එකේ නම හදාගන්නවා (විශේෂ අකුරු අයින් කරලා)
      String cleanTitle = _video!.title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      String ext = isAudio ? 'mp3' : 'mp4';
      String fileName = '${cleanTitle}_Savely.$ext';

      // සේව් කරන තැන (Android Downloads ෆෝල්ඩරය)
      Directory dir = Directory('/storage/emulated/0/Download');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      String savePath = '${dir.path}/$fileName';

      // Dio Package එක හරහා ෆයිල් එක ඩවුන්ලෝඩ් කරනවා
      await _dio.download(
        streamInfo.url.toString(),
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total; // ප්‍රතිශතය හදනවා
            });
          }
        },
      );

      setState(() {
        _statusMessage = 'Download Complete! 🎉';
        _progress = 1.0;
      });

      // තත්පර 2කින් පස්සේ මෙනුව ඉබේම වැහෙනවා
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });

    } catch (e) {
      setState(() {
        _statusMessage = 'Download failed!';
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.6,
      child: _isLoading 
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.red),
              const SizedBox(height: 16),
              Text(_statusMessage, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          )
        : _isDownloading
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_statusMessage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: _progress,
                  color: Colors.red,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 10),
                Text('${(_progress * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 16)),
              ],
            )
          : _buildOptionsList(),
    );
  }

  // වීඩියෝ විස්තර සහ කොලිටි තෝරන කොටස පෙන්වීම
  Widget _buildOptionsList() {
    if (_video == null || _manifest == null) return const Center(child: Text("Failed to load"));

    // Muxed කියන්නේ Audio+Video දෙකම එකට තියෙන ෆයිල් වලටයි
    var videoStreams = _manifest!.muxed.sortByVideoQuality().toList();
    var audioStream = _manifest!.audioOnly.withHighestBitrate();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(_video!.thumbnails.lowResUrl, height: 60, width: 60, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _video!.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        const Divider(height: 30),
        const Text('Download Video (MP4)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: videoStreams.length,
            itemBuilder: (context, index) {
              var stream = videoStreams[index];
              var sizeStr = stream.size.totalMegaBytes.toStringAsFixed(1);
              return ListTile(
                leading: const Icon(Icons.video_library, color: Colors.red),
                title: Text('${stream.videoQuality.name} Resolution'),
                subtitle: Text('$sizeStr MB'),
                trailing: const Icon(Icons.download),
                onTap: () => _startDownload(stream, false),
              );
            },
          ),
        ),
        const Divider(),
        const Text('Download Audio (MP3)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        ListTile(
          leading: const Icon(Icons.music_note, color: Colors.blue),
          title: const Text('High Quality Audio'),
          subtitle: Text('${audioStream.size.totalMegaBytes.toStringAsFixed(1)} MB'),
          trailing: const Icon(Icons.download),
          onTap: () => _startDownload(audioStream, true),
        ),
      ],
    );
  }
}