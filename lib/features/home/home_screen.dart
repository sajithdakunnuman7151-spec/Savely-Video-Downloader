// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_screen.dart';
import '../downloader/download_bottom_sheet.dart';
import '../downloader/downloads_screen.dart';
import 'video_search_delegate.dart';
import '../browser/browser_screen.dart';
import 'quick_links_provider.dart'; 

// =========================================================
// 1. HOME SCREEN (ප්‍රධාන තිරය)
// =========================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  String _lastCopiedLink = '';

  final List<Widget> _screens = [
    const _HomeTabContent(),
    const DownloadsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkClipboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  Future<void> _checkClipboard() async {
    if (kIsWeb) return;

    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      String copiedText = data.text!;
      if ((copiedText.contains('youtube.com') ||
              copiedText.contains('youtu.be') ||
              copiedText.contains('tiktok.com')) &&
          copiedText != _lastCopiedLink) {
        setState(() {
          _lastCopiedLink = copiedText;
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Link Detected! Ready to download.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            DownloadBottomSheet.show(context, copiedText);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.redAccent, // වර්ණය වෙනස් කළා
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.download_for_offline), label: 'My Files'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// =========================================================
// 2. HOME TAB CONTENT
// =========================================================
class _HomeTabContent extends StatelessWidget {
  const _HomeTabContent();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          title: _buildSearchBar(context),
          bottom: const TabBar(
            labelColor: Colors.redAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.redAccent,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'For You'),
              Tab(text: 'Trending'),
              Tab(text: 'Music'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ForYouTab(),
            Center(child: Text('Trending Videos will appear here')),
            Center(child: Text('Music content will appear here')),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        showSearch(context: context, delegate: VideoSearchDelegate());
      },
      child: Container(
        height: 45,

        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(25),
        ),
      
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Row(
          children: [
            Icon(Icons.search, color: Colors.grey),
            SizedBox(width: 10),
            Text('Search YouTube videos...', style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// 3. FOR YOU TAB (Shortcuts & Beautiful Video Grid)
// =========================================================
class _ForYouTab extends ConsumerStatefulWidget {
  const _ForYouTab();

  @override
  ConsumerState<_ForYouTab> createState() => _ForYouTabState();
}

class _ForYouTabState extends ConsumerState<_ForYouTab> {
  final YoutubeExplode _yt = YoutubeExplode();
  List<Video> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    try {
      // මෙතන තියෙන නම වෙනස් කරලා ඕනෑම දෙයක් Search කරවන්න පුළුවන්
      var searchResults = await _yt.search.search('trending music sri lanka');
      if (mounted) {
        setState(() {
          _videos = searchResults.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _yt.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchVideos,
      color: Colors.redAccent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickLinks(context, ref),
            
            const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 12.0),
              child: Text(
                'Recommended For You', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
            ),
            
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0), 
                      child: CircularProgressIndicator(color: Colors.redAccent)
                    )
                  )
                : _buildVideoGrid(),
          ],
        ),
      ),
    );
  }

  // --- SHORTCUTS SECTION ---
  Widget _buildQuickLinks(BuildContext context, WidgetRef ref) {
    final links = ref.watch(quickLinksProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 12,
        runSpacing: 16,
        children: [
          ...links.map((link) {
            return GestureDetector(
              onTap: () {
                if (kIsWeb) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Web browsing limited in preview.')));
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BrowserScreen(url: link.url, siteName: link.name)),
                );
              },
              onLongPress: () {
                _showEditDeleteDialog(context, ref, link);
              },
              child: SizedBox(
                width: 75,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(link.colorValue).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(IconData(link.iconCode, fontFamily: 'MaterialIcons'), color: Color(link.colorValue), size: 30),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      link.name,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: () => _showAddLinkDialog(context, ref),
            child: SizedBox(
              width: 75,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.grey, size: 30),
                  ),
                  const SizedBox(height: 6),
                  const Text('Add New', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW BEAUTIFUL VIDEO GRID WITH DOWNLOAD BUTTON ---
  Widget _buildVideoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,         // තීරු 2යි
        crossAxisSpacing: 12.0,    // හරස් අතට පරතරය
        mainAxisSpacing: 16.0,     // දිග අතට පරතරය
        childAspectRatio: 0.72,    // කොටුවේ උස වෙනස් කළා Download button එකට ඉඩ දෙන්න
      ),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        final durationString = video.duration != null
            ? '${video.duration!.inMinutes}:${video.duration!.inSeconds.remainder(60).toString().padLeft(2, '0')}'
            : 'Live';

        return GestureDetector(
          onTap: () {
            // Video එක උඩ Click කලත් Download මෙනුව එනවා
            DownloadBottomSheet.show(context, video.url);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Thumbnail එක සහ Duration එක
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        video.thumbnails.highResUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6, right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(6)
                      ),
                      child: Text(durationString, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // 2. Video Title එක, Channel නම සහ Download Button එක
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // වම් පැත්ත: Title එක සහ Author
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title, 
                            maxLines: 2, 
                            overflow: TextOverflow.ellipsis, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, height: 1.2)
                          ),
                          const SizedBox(height: 4),
                          Text(
                            video.author, 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis, 
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)
                          ),
                        ],
                      ),
                    ),
                    
                    // දකුණු පැත්ත: Download Icon Button එක
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.download_rounded, color: Colors.redAccent, size: 26),
                      onPressed: () {
                        // Download Icon එක එබුවම කෙළින්ම Bottom sheet එක අරිනවා
                        DownloadBottomSheet.show(context, video.url);
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- ADD / EDIT DIALOGS (මීට පෙර තිබූ ලෙසම) ---
  void _showAddLinkDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final urlController = TextEditingController(text: 'https://');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Shortcut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Site Name')),
            TextField(controller: urlController, decoration: const InputDecoration(labelText: 'URL')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && urlController.text.isNotEmpty) {
                ref.read(quickLinksProvider.notifier).addLink(nameController.text, urlController.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDeleteDialog(BuildContext context, WidgetRef ref, QuickLink link) {
    final nameController = TextEditingController(text: link.name);
    final urlController = TextEditingController(text: link.url);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Shortcut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Site Name')),
            TextField(controller: urlController, decoration: const InputDecoration(labelText: 'URL')),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () {
              ref.read(quickLinksProvider.notifier).deleteLink(link.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty && urlController.text.isNotEmpty) {
                    ref.read(quickLinksProvider.notifier).editLink(link.id, nameController.text, urlController.text);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}