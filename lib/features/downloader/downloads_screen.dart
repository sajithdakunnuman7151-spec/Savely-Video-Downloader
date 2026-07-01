
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
        _downloadedFiles = dir
            .listSync()
            .where((item) =>
                item.path.endsWith('.mp4') ||
                item.path.endsWith('.m4a') ||
                item.path.endsWith('.mp3'))
            .toList();
      });
    }
  }

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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Files deleted successfully'),
        backgroundColor: Colors.green));
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

  Widget _buildFileTypeIcon(String fileName) {
    if (fileName.endsWith('.mp4')) {
      return const Icon(Icons.video_library, color: Colors.purple, size: 40);
    } else if (fileName.endsWith('.m4a') || fileName.endsWith('.mp3')) {
      return const Icon(Icons.music_note, color: Colors.deepOrange, size: 40);
    } else {
      return const Icon(Icons.insert_drive_file, size: 40);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDownloads = ref
        .watch(downloadProvider)
        .values
        .where((task) => task.status != DownloadStatus.completed)
        .toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            _isSelectionMode ? '${_selectedFiles.length} Selected' : 'My Downloads'),
        actions: [
          if (_isSelectionMode)
            IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: _deleteSelectedFiles)
          else
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadDownloadedFiles)
        ],
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                      _isSelectionMode = false;
                      _selectedFiles.clear();
                    }))
            : null,
      ),
      body: CustomScrollView(
        slivers: [
          // --- 1. ACTIVE DOWNLOADS SECTION ---
          if (activeDownloads.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Active Downloads (${activeDownloads.length})',
                    style: theme.textTheme.titleLarge),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final task = activeDownloads[index];
                  bool isPaused = task.status == DownloadStatus.paused;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: Icon(
                            isPaused
                                ? Icons.pause_circle_filled
                                : Icons.downloading,
                            color: isPaused
                                ? Colors.amber.shade700
                                : theme.colorScheme.primary,
                            size: 40),
                        title: Text(task.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            LinearProgressIndicator(
                              value: task.progress,
                              color: isPaused
                                  ? Colors.amber.shade700
                                  : theme.colorScheme.primary,
                              backgroundColor: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${task.downloadedSize} / ${task.totalSize}',
                                    style: theme.textTheme.bodySmall),
                                Text(
                                    '${(task.progress * 100).toStringAsFixed(1)}%',
                                    style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                  isPaused ? Icons.play_arrow : Icons.pause,
                                  color: isPaused
                                      ? Colors.green.shade600
                                      : Colors.amber.shade800),
                              onPressed: () {
                                if (isPaused) {
                                  ref
                                      .read(downloadProvider.notifier)
                                      .resumeDownload(task.id);
                                } else {
                                  ref
                                      .read(downloadProvider.notifier)
                                      .pauseDownload(task.id);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => ref
                                  .read(downloadProvider.notifier)
                                  .cancelAndDelete(task.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: activeDownloads.length,
              ),
            ),
          ],

          // --- 2. COMPLETED DOWNLOADS SECTION ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('Completed', style: theme.textTheme.titleLarge),
            ),
          ),
          if (_downloadedFiles.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.file_download_off,
                        size: 80, color: Colors.grey),
                    const SizedBox(height: 20),
                    Text('No downloaded files yet.',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  File file = File(_downloadedFiles[index].path);
                  String fileName = file.path.split('/').last;
                  String size =
                      '${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB';
                  bool isSelected = _selectedFiles.contains(file.path);

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    elevation: isSelected ? 8 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onLongPress: () {
                        setState(() => _isSelectionMode = true);
                        _toggleSelection(file.path);
                      },
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleSelection(file.path);
                        } else {
                          // Handle file opening here
                        }
                      },
                      leading: _isSelectionMode
                          ? Checkbox(
                              value: isSelected,
                              onChanged: (val) => _toggleSelection(file.path),
                              activeColor: theme.colorScheme.primary,
                            )
                          : _buildFileTypeIcon(fileName),
                      title: Text(fileName,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(size, style: theme.textTheme.bodySmall),
                    ),
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
