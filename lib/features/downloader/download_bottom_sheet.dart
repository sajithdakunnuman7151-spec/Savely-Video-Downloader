// lib/features/downloader/download_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'download_provider.dart';
import '../settings/download_location.dart';

class DownloadBottomSheet extends StatefulWidget {
  final String videoUrl;
  const DownloadBottomSheet({super.key, required this.videoUrl});

  static void show(BuildContext context, String url) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DownloadBottomSheet(videoUrl: url),
    );
  }

  @override
  State<DownloadBottomSheet> createState() => _DownloadBottomSheetState();
}

class _DownloadBottomSheetState extends State<DownloadBottomSheet> {
  final YoutubeExplode _yt = YoutubeExplode();
  Video? _video;
  StreamManifest? _manifest;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchVideoDetails(); // UI එක ආව ගමන් Data අදින්න පටන් ගන්නවා (Speed එක වැඩි වෙයි)
  }

  Future<void> _fetchVideoDetails() async {
    try {
    
      var videoId = VideoId(widget.videoUrl); 
      
      var video = await _yt.videos.get(videoId);
      var manifest = await _yt.videos.streamsClient.getManifest(videoId);
      
      if (mounted) {
        setState(() {
          _video = video;
          _manifest = manifest;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { 
          _isLoading = false; 
          
          _error = 'Error: ${e.toString()}'; 
        });
      }
    }
  }

  @override
  void dispose() {
    _yt.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16.0),
      height: MediaQuery.of(context).size.height * 0.7, // Screen එකෙන් 70% ක් උසයි
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 16),
          
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.redAccent)))
          else if (_error.isNotEmpty)
            Expanded(child: Center(child: Text(_error, style: const TextStyle(color: Colors.red))))
          else ...[
            // 1. වීඩියෝවේ නම සහ රූපය
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(_video!.thumbnails.lowResUrl, width: 80, height: 45, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(_video!.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            const Divider(height: 30),

            // 2. Qualities පෙන්වන කොටස (Audio සහ Video වෙන වෙනම)
            Expanded(
              child: ListView(
                children: [
                  const Text('Audio (Music)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent)),
                  const SizedBox(height: 8),
                  ..._manifest!.audioOnly.sortByBitrate().reversed.map((stream) => _buildOption(stream, true)),
                  
                  const Divider(height: 30),
                  const Text('Video', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent)),
                  const SizedBox(height: 8),
                  // Muxed කියන්නේ Audio + Video දෙකම තියෙන ඒවා
                  ..._manifest!.muxed.sortByVideoQuality().reversed.map((stream) => _buildOption(stream, false)),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildOption(StreamInfo stream, bool isAudio) {
    final qualityLabel = isAudio ? '${stream.bitrate.kiloBitsPerSecond.toInt()} kbps' : (stream as VideoStreamInfo).qualityLabel;
    final sizeLabel = '${stream.size.totalMegaBytes.toStringAsFixed(1)} MB';
    final format = stream.container.name.toUpperCase();

    return Consumer(
      builder: (context, ref, child) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(isAudio ? Icons.music_note : Icons.videocam, color: isAudio ? Colors.redAccent : Colors.blueAccent),
          title: Text('$format - $qualityLabel', style: const TextStyle(fontWeight: FontWeight.w500)),
          trailing: ElevatedButton.icon(
            onPressed: () {
              final saveDir = ref.read(downloadLocationProvider);
              // ඩවුන්ලෝඩ් එක පටන් ගන්නවා
              ref.read(downloadProvider.notifier).startDownload(
                _video!.id.value, _video!.title, stream.url.toString(), isAudio, saveDir
              );
              Navigator.pop(context); // මෙනුව වහනවා
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download Started!'), backgroundColor: Colors.green));
            },
            icon: const Icon(Icons.download, size: 18),
            label: Text(sizeLabel),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black87, elevation: 0),
          ),
        );
      }
    );
  }
}