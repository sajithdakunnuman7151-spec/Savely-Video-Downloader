// lib/features/browser/browser_screen.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../downloader/download_bottom_sheet.dart';

class BrowserScreen extends StatefulWidget {
  final String url;
  final String siteName;

  const BrowserScreen({super.key, required this.url, required this.siteName});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final WebViewController _controller;
  String _currentUrl = '';
  
  // Loading ප්‍රතිශතය බලාගැනීමට (0 සිට 100 දක්වා)
  int _loadingProgress = 0; 

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    
    // =========================================================
    // WEBVIEW CONTROLLER SETUP
    // =========================================================
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // පේජ් එක ලෝඩ් වෙන ප්‍රතිශතය Update කිරීම
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) setState(() => _currentUrl = url);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _currentUrl = url);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.siteName, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. ප්‍රධාන වෙබ් පිටුව
          WebViewWidget(controller: _controller),
          
          // 2. Loading Progress Bar එක (100% ට අඩු නම් පමණක් පෙන්වයි)
          if (_loadingProgress < 100)
            LinearProgressIndicator(
              value: _loadingProgress / 100.0,
              color: Colors.redAccent,
              backgroundColor: Colors.grey[200],
            ),
        ],
      ),
      
      // =========================================================
      // DOWNLOAD FLOATING BUTTON
      // =========================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_currentUrl.contains('youtube.com') || _currentUrl.contains('youtu.be')) {
            // යූටියුබ් නම් ඩවුන්ලෝඩ් මෙනුව අරිනවා
            DownloadBottomSheet.show(context, _currentUrl);
          } else {
            // වෙන සයිට් එකක් නම් Alert එකක් දෙනවා
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Currently, downloading is only supported for YouTube.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        icon: const Icon(Icons.download_rounded, color: Colors.white),
        label: const Text('Download', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}