import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard එක කියවන්න
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../settings/settings_screen.dart';
import '../downloader/download_bottom_sheet.dart';
import '../downloader/downloads_screen.dart';
import 'video_search_delegate.dart';

import 'package:flutter/foundation.dart' show kIsWeb;


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// "with WidgetsBindingObserver" කෑල්ලෙන් App එක minimize/resume වෙන එක අඳුරගන්නවා
class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  String _lastCopiedLink = ''; // එකම ලින්ක් එක දෙපාරක් එන එක නවත්වන්න

  final List<Widget> _screens = [
    const _TrendingFeed(),
    const DownloadsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkClipboard(); // App එක මුලින්ම ඕපන් වෙද්දිත් ලින්ක් එකක් තියෙනවද බලනවා
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // App එක Background එකේ ඉඳන් ආයෙත් ඕපන් වෙද්දී මේක වැඩ කරනවා
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  /// Copy කරපු දේවල් කියවලා ඒක ලින්ක් එකක්ද කියලා බලන Function එක
  Future<void> _checkClipboard() async {
    // 🌟 වෙබ් බ්‍රව්සර් එකේදී ඉබේම Clipboard එක කියවන්න බැරි නිසා, මෙතනින් කෝඩ් එක නවත්වනවා.
    if (kIsWeb) return; 

    // ෆෝන් එකේ කොපි කරලා තියෙන දේ ගන්නවා (මේක වැඩ කරන්නේ Android/iOS වල විතරයි දැන්)
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);

    if (data != null && data.text != null) {
      String copiedText = data.text!;

      // ඒක ඇත්තටම YouTube හරි TikTok ලින්ක් එකක්ද, සහ කලින් දාපු එකමද කියලා බලනවා
      if ((copiedText.contains('youtube.com') ||
              copiedText.contains('youtu.be') ||
              copiedText.contains('tiktok.com')) &&
          copiedText != _lastCopiedLink) {
        setState(() {
          _lastCopiedLink =
              copiedText; // ආයෙත් මේකම එන එක නවත්වන්න සේව් කරගන්නවා
        });

        // App එකේ UI එක ලෝඩ් වෙන්න පොඩි වෙලාවක් (තත්පර භාගයක්) දීලා මෙනුව උඩට ගන්නවා
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Link Detected! Ready to download.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            // කෙළින්ම Download Bottom Sheet එකට ලින්ක් එක යවනවා
            DownloadBottomSheet.show(context, copiedText);
          }
        });
      }
    }
  }


  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text(
          'Savely',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // මේකෙන් අර අපි හදපු ලස්සන Search Screen එක උඩට එනවා
              showSearch(
                context: context,
                delegate: VideoSearchDelegate(),
              );
            },
          )
        ],
      ),

      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.download), label: 'Downloads'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------
/// ඇත්තම YouTube දත්ත ගෙනෙන Trending Feed කොටස (කලින් කෝඩ් එකමයි)
/// ---------------------------------------------------------
class _TrendingFeed extends StatefulWidget {
  const _TrendingFeed();

  @override
  State<_TrendingFeed> createState() => _TrendingFeedState();
}

class _TrendingFeedState extends State<_TrendingFeed> {
  final YoutubeExplode _yt = YoutubeExplode();
  List<Video> _videos = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTrendingVideos();
  }

  Future<void> _fetchTrendingVideos() async {
    try {
      var searchResults = await _yt.search.search('trending music sri lanka');
      setState(() {
        _videos = searchResults.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load videos. Please check your internet.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _yt.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _fetchTrendingVideos();
              },
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        final durationString = video.duration != null
            ? '${video.duration!.inMinutes}:${video.duration!.inSeconds.remainder(60).toString().padLeft(2, '0')}'
            : 'Live';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  video.thumbnails.highResUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: Colors.grey),
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.all(12),
                title: Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('${video.author} • $durationString'),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.download_rounded,
                      color: Colors.red, size: 30),
                  onPressed: () {
                    DownloadBottomSheet.show(context, video.url);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
