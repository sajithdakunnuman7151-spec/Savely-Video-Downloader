// lib/features/downloader/downloads_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'download_provider.dart';
import '../settings/download_location.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  List<FileSystemEntity> _downloadedFiles = [];
  final Set<String> _selectedFiles = {}; 
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadDownloadedFiles());
  }

  Future<void> _loadDownloadedFiles() async {
    if (kIsWeb) return;
    final currentSaveLocation = ref.read(downloadLocationProvider);
    if (currentSaveLocation.isEmpty) return;

    Directory dir = Directory(currentSaveLocation);
    if (dir.existsSync()) {
      setState(() {
        _downloadedFiles = dir.listSync()
            .where((item) => item.path.endsWith('.mp4') || item.path.endsWith('.m4a') || item.path.endsWith('.mp3'))
            .toList();
      });
    }
  }

  // තෝරගත්තු ෆයිල්ස් මකන Function එක
  void _deleteSelectedFiles() {
    for (String path in _selectedFiles) {
      File file = File(path);
      if (file.existsSync()) file.deleteSync();
    }
    setState(() {
      _selectedFiles.clear();
      _isSelectionMode = false;
    });
    _loadDownloadedFiles();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Files deleted successfully')));
  }

  void _toggleSelection(String path) {
    setState(() {
      if (_selectedFiles.contains(path)) {
        _selectedFiles.remove(path);
        if (_selectedFiles.isEmpty) _isSelectionMode = false;
      } else {
        _selectedFiles.add(path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeDownloads = ref.watch(downloadProvider).values.where((task) => task.status != DownloadStatus.completed).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? '${_selectedFiles.length} Selected' : 'My Downloads'),
        actions: [
          if (_isSelectionMode)
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _deleteSelectedFiles)
          else
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDownloadedFiles)
        ],
        leading: _isSelectionMode 
            ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() { _isSelectionMode = false; _selectedFiles.clear(); }))
            : null,
      ),
      body: CustomScrollView(
        slivers: [
          // --- 1. DOWNLOADING / PAUSED SECTION ---
          if (activeDownloads.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Active Downloads (${activeDownloads.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final task = activeDownloads[index];
                  bool isPaused = task.status == DownloadStatus.paused;
                  
                  return ListTile(
                    leading: Icon(isPaused ? Icons.pause_circle_filled : Icons.downloading, color: isPaused ? Colors.orange : Colors.blue, size: 40),
                    title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        LinearProgressIndicator(value: task.progress, color: isPaused ? Colors.orange : Colors.blue),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${task.downloadedSize} / ${task.totalSize}'),
                            Text('${(task.progress * 100).toStringAsFixed(1)}%'),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pause / Resume Button
                        IconButton(
                          icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: isPaused ? Colors.green : Colors.orange),
                          onPressed: () {
                            if (isPaused) {
                              ref.read(downloadProvider.notifier).resumeDownload(task.id);
                            } else {
                              ref.read(downloadProvider.notifier).pauseDownload(task.id);
                            }
                          },
                        ),
                        // Cancel Button
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => ref.read(downloadProvider.notifier).cancelAndDelete(task.id),
                        ),
                      ],
                    ),
                  );
                },
                childCount: activeDownloads.length,
              ),
            ),
          ],

          // --- 2. COMPLETED SECTION (Long Press to Select & Delete) ---
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Completed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          
          if (_downloadedFiles.isEmpty)
            const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('No downloaded files yet.', style: TextStyle(color: Colors.grey)))))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  File file = File(_downloadedFiles[index].path);
                  String fileName = file.path.split('/').last;
                  String size = '${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB';
                  bool isSelected = _selectedFiles.contains(file.path);

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: Colors.redAccent.withValues(alpha: 0.1),
                    onLongPress: () {
                      setState(() => _isSelectionMode = true);
                      _toggleSelection(file.path);
                    },
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleSelection(file.path);
                      } else {
                        // ප්ලේ කරන්න පුළුවන් දේවල් ඉදිරියේදී මෙතනට දාන්න
                      }
                    },
                    leading: _isSelectionMode 
                        ? Checkbox(value: isSelected, onChanged: (val) => _toggleSelection(file.path), activeColor: Colors.redAccent)
                        : Icon(fileName.endsWith('.mp4') ? Icons.video_file : Icons.audio_file, color: Colors.green, size: 40),
                    title: Text(fileName, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(size),
                  );
                },
                childCount: _downloadedFiles.length,
              ),
            ),
        ],
      ),
    );
  }
}