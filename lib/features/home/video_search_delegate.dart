// lib/features/home/video_search_delegate.dart
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../downloader/download_bottom_sheet.dart';

class VideoSearchDelegate extends SearchDelegate<String?> {
  // Search කරන හැමවෙලාවෙම අලුත් YouTube connection එකක් හදාගන්නවා
  final YoutubeExplode _yt = YoutubeExplode();

  // Search Bar එකේ දකුණු පැත්තේ තියෙන බොත්තම් (උදා: Clear (X) බොත්තම)
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = ''; // X එබුවම ටයිප් කරපු එක මැකෙනවා
        },
      )
    ];
  }

  // Search Bar එකේ වම් පැත්තේ තියෙන බොත්තම (උදා: Back arrow එක)
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null); // Back එබුවම Search එකෙන් අයින් වෙනවා
      },
    );
  }

  // Search කරාට පස්සේ එන ප්‍රතිඵල පෙන්වන කොටස
  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(child: Text('Type something to search.'));
    }

    // FutureBuilder එකෙන් අන්තර්ජාලයෙන් දත්ත එනකන් බලාගෙන ඉන්නවා
    return FutureBuilder<VideoSearchList>(
      future: _yt.search.search(query), // යූසර් ගහපු නම search කරනවා
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No results found.'));
        }

        final videos = snapshot.data!.toList();

        // ප්‍රතිඵල ලැයිස්තුව ලස්සනට පෙන්වනවා (කලින් Home Screen එකේ වගේමයි)
        return ListView.builder(
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
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
                          Container(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('${video.author} • $durationString'),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.download_rounded, color: Colors.red, size: 30),
                      onPressed: () {
                        // මේකෙන් කෙළින්ම Download Bottom Sheet එක ඕපන් වෙනවා
                        DownloadBottomSheet.show(context, video.url);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // මුකුත් ටයිප් කරන්න කලින් (Suggestions) පෙන්වන කොටස
  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Search for any YouTube video or song', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}