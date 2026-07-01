// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../settings/settings_screen.dart';
import '../downloader/download_bottom_sheet.dart';
import '../downloader/downloads_screen.dart';
import 'video_search_delegate.dart';
import '../browser/browser_screen.dart';

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
        selectedItemColor: Colors.amber[700],
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

class _HomeTabContent extends StatelessWidget {
  const _HomeTabContent();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: _buildSearchBar(context),
          actions: [
            IconButton(icon: const Icon(Icons.music_note, color: Colors.black54), onPressed: () {}),
            IconButton(icon: const Icon(Icons.download_rounded, color: Colors.lightBlue), onPressed: () {}),
          ],
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.amber,
            tabs: [
              Tab(text: 'For You'),
              Tab(text: 'Trending'),
              Tab(text: 'Channels'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ForYouTab(),
            Center(child: Text('Trending Tab Content')),
            Center(child: Text('Channels Tab Content')),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showSearch(context: context, delegate: VideoSearchDelegate());
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Row(
          children: [
            Icon(Icons.search, color: Colors.grey),
            SizedBox(width: 8),
            Text('Search YouTube', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _ForYouTab extends StatefulWidget {
  const _ForYouTab();

  @override
  State<_ForYouTab> createState() => _ForYouTabState();
}

class _ForYouTabState extends State<_ForYouTab> {
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickLinks(),
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
            child: Text('Recommended', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _isLoading
              ? const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()))
              : _buildVideoGrid(),
        ],
      ),
    );
  }

  Widget _buildQuickLinks() {
    final links = [
      {'icon': Icons.play_circle_filled, 'color': Colors.red, 'name': 'YouTube', 'url': 'https://m.youtube.com'},
      {'icon': Icons.facebook, 'color': Colors.blue, 'name': 'Facebook', 'url': 'https://m.facebook.com'},
      {'icon': Icons.camera_alt, 'color': Colors.purple, 'name': 'Instagram', 'url': 'https://www.instagram.com'},
      {'icon': Icons.music_note, 'color': Colors.black, 'name': 'Free MP3', 'url': 'https://pixabay.com/music/'},
      {'icon': Icons.video_library, 'color': Colors.blueAccent, 'name': 'Dailymotion', 'url': 'https://www.dailymotion.com'},
      {'icon': Icons.shop, 'color': Colors.pink, 'name': 'Great Apps', 'url': 'https://play.google.com'},
      {'icon': Icons.cloud, 'color': Colors.orange, 'name': 'SoundCloud', 'url': 'https://soundcloud.com'},
      {'icon': Icons.more_horiz, 'color': Colors.amber, 'name': 'More', 'url': 'https://google.com'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 15,
        runSpacing: 15,
        children: links.map((link) {
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              if (kIsWeb) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${link['name']} browsing is only supported in the Android App due to browser security.'),
                    backgroundColor: Colors.blue,
                  ),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BrowserScreen(
                    url: link['url'] as String,
                    siteName: link['name'] as String,
                  ),
                ),
              );
            },
            child: SizedBox(
              width: 70,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: link['color'] as Color,
                    child: Icon(link['icon'] as IconData, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    link['name'] as String,
                    style: const TextStyle(fontSize: 11),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVideoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 0.85,
      ),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        final durationString = video.duration != null
            ? '${video.duration!.inMinutes}:${video.duration!.inSeconds.remainder(60).toString().padLeft(2, '0')}'
            : 'Live';

        return GestureDetector(
          onTap: () {
            DownloadBottomSheet.show(context, video.url);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        video.thumbnails.highResUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          // මෙහිදී withOpacity වෙනුවට withValues(alpha: ...) භාවිතා කර ඇත
                          color: Colors.grey.withValues(alpha: 0.2)
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4, right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                      child: Text(durationString, style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(video.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        );
      },
    );
  }
}