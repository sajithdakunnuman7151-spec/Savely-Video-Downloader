// lib/features/home/video_search_delegate.dart
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../downloader/download_bottom_sheet.dart';

class VideoSearchDelegate extends SearchDelegate<String?> {
  final YoutubeExplode _yt = YoutubeExplode();

  // Search Bar එකේ පසුබිම සහ අයිකන් වල වර්ණ ඡායාරූපයේ පරිදි සැකසීම
  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
      ),
    );
  }

  // Clear (X) බොත්තම
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.grey),
          onPressed: () {
            query = ''; // X එබුවම ටයිප් කරපු එක මැකෙනවා
          },
        )
    ];
  }

  // Back (<-) බොත්තම
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null); // Back එබුවම Search එකෙන් අයින් වෙනවා
      },
    );
  }

  // Search කරාට පස්සේ එන ප්‍රතිඵල (Tabs සහ Video List එක)
  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(child: Text('Type something to search.'));
    }

    // ඡායාරූපයේ පරිදි Tabs 4ක් සහිත Controller එකක්
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            labelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.amber, // කහ පාට ඉර
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Playlists'),
              Tab(text: 'Status'),
              Tab(text: 'Users'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // 1. All Tab එකේ තමා අපි Videos ටික පෙන්වන්නේ
                _buildAllResultsTab(),
                
                // අනිත් Tabs වලට දැනට සාමාන්‍ය Text එකක් දාලා තියෙනවා (ඉදිරියට ඕනෙ නම් හදන්න පුළුවන්)
                const Center(child: Text('Playlists search coming soon')),
                const Center(child: Text('Status videos coming soon')),
                const Center(child: Text('Users search coming soon')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // යූටියුබ් වීඩියෝ ලැයිස්තුව (List) පෙන්වන කොටස
  Widget _buildAllResultsTab() {
    return FutureBuilder<VideoSearchList>(
      future: _yt.search.search(query), // යූසර් ගහපු නම search කරනවා
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No results found.'));
        }

        final videos = snapshot.data!.toList();

        return ListView.builder(
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            
            // Duration එක හරියට හදාගන්නවා (05:15 වගේ එන්න)
            final durationString = video.duration != null 
                ? '${video.duration!.inMinutes.toString().padLeft(2, '0')}:${video.duration!.inSeconds.remainder(60).toString().padLeft(2, '0')}'
                : 'Live';

            final isDark = Theme.of(context).brightness == Brightness.dark;

            return InkWell(
              onTap: () {
                // වීඩියෝව මත Click කළත් Download මෙනුව එනවා
                DownloadBottomSheet.show(context, video.url);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // --- 1. වම් පස: Thumbnail රූපය ---
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 140, // ඡායාරූපයේ තරම් පළලට
                        height: 75,
                        child: Image.network(
                          video.thumbnails.lowResUrl, // List එකක් නිසා LowRes දැමීමෙන් Data ඉතුරු වේ, වේගවත් වේ
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                              Container(color: Colors.grey.withValues(alpha: 0.2)),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // --- 2. මැද: Video Title සහ විස්තර ---
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14.5, height: 1.2),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            video.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey, fontSize: 12.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            // ඡායාරූපයේ තිබූ ලෙසටම කාලය (duration) පෙන්වීම
                            durationString,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    
                    // --- 3. දකුණු පස: Download Icon එක ---
                    IconButton(
                      icon: Icon(
                        Icons.file_download_outlined, // ඡායාරූපයේ ඇති ආකාරයේ Arrow down අයිකනය
                        color: isDark ? Colors.white70 : Colors.black87, 
                        size: 28
                      ),
                      onPressed: () {
                        DownloadBottomSheet.show(context, video.url);
                      },
                    ),
                    
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // මුකුත් ටයිප් කරන්න කලින් පෙන්වන කොටස
  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text('Search for videos or music...', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}