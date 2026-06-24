// lib/features/downloader/downloads_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<FileSystemEntity> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadedFiles();
  }

  // ෆෝන් එකේ Storage එකට ගිහින් අපේ ෆයිල්ස් ටික හොයන Function එක
  Future<void> _loadDownloadedFiles() async {
    setState(() => _isLoading = true);

    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory.existsSync()) {
        // ෆෝල්ඩර් එකේ තියෙන ඔක්කොම ෆයිල්ස් අරන්, අපේ App එකෙන් ආපු ඒවා විතරක් පෙරලා ගන්නවා
        final List<FileSystemEntity> files = directory.listSync().where((file) {
          return file.path.contains('Savely') &&
              (file.path.endsWith('.mp4') || file.path.endsWith('.mp3'));
        }).toList();

        // අලුත්ම ෆයිල් එක උඩින්ම පේන්න ලිස්ට් එක හදනවා (Sort by date)
        files.sort(
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified));

        setState(() {
          _files = files;
        });
      }
    } catch (e) {
      debugPrint("Error loading files: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Loading වෙද්දී පෙනෙන විදිහ
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    // 2. මුකුත්ම ඩවුන්ලෝඩ් කරලා නැත්නම් පෙනෙන විදිහ
    if (_files.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No downloads yet.',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
            Text('Your downloaded videos will appear here.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // 3. ෆයිල්ස් තියෙනවා නම් පෙනෙන විදිහ (Pull to refresh කරන්නත් පුළුවන්)
    return RefreshIndicator(
      color: Colors.red,
      onRefresh: _loadDownloadedFiles,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final file = _files[index];
          final fileName = file.path.split('/').last;
          final isVideo = fileName.endsWith('.mp4');

          // ෆයිල් එකේ සයිස් එක මෙගාබයිට් (MB) වලින් ගණනය කරනවා
          final fileSize =
              (file.statSync().size / (1024 * 1024)).toStringAsFixed(2);

          // අපි දාපු නම ලස්සන කරලා පෙන්නනවා (අර "_Savely" කෑල්ල අයින් කරලා)
          final cleanTitle = fileName
              .replaceAll('_Savely.mp4', '')
              .replaceAll('_Savely.mp3', '')
              .replaceAll('_', ' ');

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 2,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: isVideo
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
                child: Icon(
                  isVideo ? Icons.play_arrow_rounded : Icons.music_note_rounded,
                  color: isVideo ? Colors.red : Colors.blue,
                  size: 30,
                ),
              ),
              title: Text(
                cleanTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                    '$fileSize MB • ${isVideo ? 'MP4 Video' : 'MP3 Audio'}'),
              ),
              trailing:
                  const Icon(Icons.open_in_new_rounded, color: Colors.grey),
              onTap: () {
                // බොත්තම එබුවම ෆෝන් එකේ තියෙන Player එකෙන් ප්ලේ කරනවා
                OpenFilex.open(file.path);
              },
            ),
          );
        },
      ),
    );
  }
}
