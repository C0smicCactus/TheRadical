import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_colors.dart';
import '../core/network_config.dart';
import '../models/article.dart';
import '../widgets/article_tile.dart';
import '../widgets/story_bar.dart';

class DashboardContentView extends StatelessWidget {
  final int tabIndex, visibleCount, totalSources, completedSources;
  final bool isLoading, isLoadingMore, showLoadMoreButton;
  final double width;
  final Color primaryColor;
  final List<Article> displayList, allArticles;
  final Set<String> viewedStoryLinks;
  final Function(String) onStoryViewed;
  final Future<void> Function(String) onArticleOpen;
  final ScrollController scrollController;
  final String statusMessage;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;

  const DashboardContentView({
    super.key, 
    required this.tabIndex, 
    required this.isLoading, 
    required this.isLoadingMore,
    required this.showLoadMoreButton,
    required this.onLoadMore,
    required this.width, 
    required this.primaryColor,
    required this.displayList, 
    required this.allArticles, 
    required this.viewedStoryLinks, 
    required this.onStoryViewed,
    required this.onArticleOpen,
    required this.visibleCount, 
    required this.scrollController, 
    required this.totalSources, 
    required this.completedSources,
    required this.statusMessage, 
    required this.onRefresh
  });

  @override
  Widget build(BuildContext context) {
    if (tabIndex == 1) return _videoPlaceholder();
    if (isLoading) return _loader();
    return RefreshIndicator(
      onRefresh: onRefresh, 
      color: primaryColor, 
      backgroundColor: AppColors.appSurface, 
      child: Column(
        children: [
          Expanded(
            child: displayList.isEmpty 
              ? _emptyState() 
              : _mainScrollArea(),
          ),
          // Load More button fallback
          if (showLoadMoreButton && displayList.isNotEmpty) _loadMoreButton(),
          // Loading more indicator
          if (isLoadingMore) _loadingMoreIndicator(),
        ],
      ),
    );
  }

  Widget _mainScrollArea() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Handle scroll end for better infinite scroll detection
        if (notification is ScrollEndNotification && !isLoadingMore && !isLoading) {
          final position = scrollController.position;
          final threshold = position.maxScrollExtent - NetworkConfig.scrollThreshold;
          if (position.pixels >= threshold && visibleCount < displayList.length) {
            onLoadMore();
          }
        }
        return false;
      },
      child: ListView(
        controller: scrollController, 
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (tabIndex == 0) StoryBar(
            allArticles: allArticles, 
            viewedStoryLinks: viewedStoryLinks, 
            onStoryViewed: onStoryViewed, 
            primaryColor: primaryColor
          ),
          Center(child: Container(constraints: const BoxConstraints(maxWidth: 1754), padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), child: Column(children: [
            Center(child: Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: displayList.take(visibleCount).map((a) {
              if (width < 432) return FittedBox(key: ValueKey(a.link), fit: BoxFit.scaleDown, child: ArticleTile(article: a, primaryColor: primaryColor, onArticleOpen: onArticleOpen));
              return ArticleTile(key: ValueKey(a.link), article: a, primaryColor: primaryColor, onArticleOpen: onArticleOpen);
            }).toList())),
          ]))),
        ],
      ),
    );
  }

  Widget _loadMoreButton() => Padding(
    padding: const EdgeInsets.all(16),
    child: Center(
      child: ElevatedButton.icon(
        onPressed: isLoadingMore ? null : onLoadMore,
        icon: const Icon(Icons.refresh),
        label: const Text("LOAD MORE"),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        ),
      ),
    ),
  );

  Widget _loadingMoreIndicator() => Padding(
    padding: const EdgeInsets.all(12),
    child: Center(
      child: SizedBox(
        width: 24, 
        height: 24, 
        child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor.withValues(alpha: 0.6)),
      ),
    ),
  );

  Widget _videoPlaceholder() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [FaIcon(FontAwesomeIcons.videoSlash, size: 40, color: primaryColor.withValues(alpha: 0.3)), const SizedBox(height: 20), Text("VIDEO SIGNALS OFFLINE", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, letterSpacing: 2)), const Text("Future feature currently in development.", style: TextStyle(color: AppColors.textMuted, fontSize: 10))]));
  Widget _loader() {
    double progress = totalSources > 0 ? completedSources / totalSources : 0;
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(value: (progress == 0) ? null : progress, color: primaryColor, strokeWidth: 6), const SizedBox(height: 30), Text("${(progress * 100).toInt()}%", style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text("RECEIVING SIGNALS...", style: TextStyle(color: primaryColor, fontSize: 10, letterSpacing: 4)), const SizedBox(height: 20), Text(statusMessage.toUpperCase(), style: const TextStyle(color: AppColors.textSubtle, fontSize: 9, letterSpacing: 1))]));
  }
  Widget _emptyState() => const Center(child: Text("NO SIGNALS FOUND"));
}