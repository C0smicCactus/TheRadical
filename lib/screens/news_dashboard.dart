import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_colors.dart';
import '../core/app_config.dart';
import '../core/network_config.dart';
import '../models/article.dart';
import '../services/feed_parser.dart';

import 'dashboard_header.dart';
import 'dashboard_drawer.dart';
import 'dashboard_content_view.dart';
import 'dashboard_dialogs.dart';

class NewsDashboard extends StatefulWidget {
  final Color primaryColor;
  final Function(Color) onThemeChanged;
  const NewsDashboard({super.key, required this.primaryColor, required this.onThemeChanged});
  @override
  State<NewsDashboard> createState() => _NewsDashboardState();
}

class _NewsDashboardState extends State<NewsDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Article> _allArticles = [], _displayList = [];
  Map<String, String> _viewedStoryMap = {}; // Link -> ISO Timestamp
  int _visibleCount = NetworkConfig.articlesPerPage, _tabIndex = 0, _totalSources = 0, _completedSources = 0;
  bool _isLoading = true, _extendedMode = false, _hideTheory = true;
  String _activeFilter = "ALL", _statusMessage = "Ready";
  bool _allSourcesEnabled = true;
  Set<String> _enabledSources = {};
  
  // Infinite scroll state
  bool _isLoadingMore = false;
  bool _showLoadMoreButton = false;

  @override
  void initState() {
    super.initState();
    // Use ScrollNotification for better infinite scroll detection
    _scrollController.addListener(_onScroll);
    _bootSequence();
  }

  /// Improved infinite scroll detection using ScrollNotification.
  void _onScroll() {
    if (_isLoadingMore || _visibleCount >= _displayList.length || _isLoading) return;
    
    final position = _scrollController.position;
    final threshold = position.maxScrollExtent - NetworkConfig.scrollThreshold;
    
    // Trigger when scrolling velocity indicates user is approaching bottom
    if (position.pixels >= threshold) {
      _loadMoreArticles();
    }
  }

  /// Load more articles when user approaches bottom or clicks button.
  Future<void> _loadMoreArticles() async {
    if (_isLoadingMore || _visibleCount >= _displayList.length) return;
    
    setState(() {
      _isLoadingMore = true;
      _showLoadMoreButton = false;
    });

    // Small delay to prevent rapid-fire triggers
    await Future.delayed(const Duration(milliseconds: 300));
    
    final newVisibleCount = _visibleCount + NetworkConfig.articlesPerPage;
    setState(() {
      _visibleCount = newVisibleCount.clamp(0, _displayList.length);
      _isLoadingMore = false;
    });

    // Show load more button if there are more articles but scroll didn't trigger
    if (_visibleCount < _displayList.length && !_isLoadingMore) {
      setState(() => _showLoadMoreButton = true);
    }
  }

  Future<void> _bootSequence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _extendedMode = prefs.getBool('extended_coverage') ?? false;
      _hideTheory = prefs.getBool('hide_theory') ?? true;
      _allSourcesEnabled = prefs.getBool('all_sources_enabled') ?? true;
      
      final String? viewedJson = prefs.getString(NetworkConfig.viewedStoriesKey);
      if (viewedJson != null) {
        _viewedStoryMap = Map<String, String>.from(jsonDecode(viewedJson));
        _cleanupOldStories();
      }

      final List<String>? savedSources = prefs.getStringList('enabled_sources');
      if (savedSources != null) {
        _enabledSources = savedSources.toSet();
      } else {
        // Default to all core + global if no prefs saved
        _enabledSources = {
          ...AppConfig.coreSources.values,
          ...AppConfig.globalSources.values
        };
      }

      final String? cachedJson = prefs.getString(NetworkConfig.offlineCacheKey);
      if (cachedJson != null) {
        final List decoded = jsonDecode(cachedJson);
        setState(() { 
          _allArticles = decoded.map((m) => Article.fromMap(m)).toList(); 
          _isLoading = false; 
          _applyLogic(); 
        });
      }
    } catch (_) {}
    _fetchNews(isBackground: _allArticles.isNotEmpty);
  }

  Future<void> _cleanupOldStories() async {
    final now = DateTime.now();
    bool changed = false;
    _viewedStoryMap.removeWhere((link, timestamp) {
      final date = DateTime.tryParse(timestamp) ?? now;
      if (now.difference(date).inHours > NetworkConfig.maxViewedStoryAgeHours) {
        changed = true;
        return true;
      }
      return false;
    });
    if (changed) _persistViewedStories();
  }

  void _markStoryViewed(String link) async {
    if (!_viewedStoryMap.containsKey(link)) {
      setState(() => _viewedStoryMap[link] = DateTime.now().toIso8601String());
      await _persistViewedStories();
    }
  }

  Future<void> _persistViewedStories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(NetworkConfig.viewedStoriesKey, jsonEncode(_viewedStoryMap));
  }

  Future<void> _fetchNews({bool isBackground = false}) async {
    if (!mounted) return;

    // Determine current target sources
    final Map<String, String> sources = Map.from(AppConfig.coreSources)..addAll(AppConfig.globalSources);
    if (_extendedMode) sources.addAll(AppConfig.extendedSources);
    
    // Background fetch doesn't care about manual source toggles (it gets everything available)
    // but foreground fetch respects the 'Signal Sources' dialog
    if (!_allSourcesEnabled) {
      sources.removeWhere((url, name) => !_enabledSources.contains(name));
    }

    if (!isBackground) {
      setState(() {
        _isLoading = true;
        _totalSources = sources.length;
        _completedSources = 0;
        _statusMessage = "Fetching...";
      });
    }

    List<Article> freshBatch = [];

    for (var entry in sources.entries) {
      if (!mounted) break;
      if (!isBackground) setState(() => _statusMessage = "Receiving: ${entry.value}");
      try {
        // Use centralized NetworkConfig for proxy URLs and timeouts
        final String fetchUrl = kIsWeb 
            ? NetworkConfig.wrapCorsProxy(entry.key) 
            : entry.key;
        final response = await http.get(Uri.parse(fetchUrl)).timeout(NetworkConfig.feedFetchTimeout);
        if (response.statusCode == 200) {
          freshBatch.addAll(FeedParser.parse(utf8.decode(response.bodyBytes, allowMalformed: true), entry.value));
        }
      } catch (_) {} finally { 
        if (mounted) setState(() => _completedSources++); 
      }
    }
    if (mounted) _processFetchedArticles(freshBatch);
  }

  void _processFetchedArticles(List<Article> freshBatch) {
    setState(() {
      final Map<String, Article> deduplicated = {};
      for (var a in _allArticles) { deduplicated[a.link.toLowerCase()] = a; }
      for (var a in freshBatch) { deduplicated[a.link.toLowerCase()] = a; }
      _allArticles = deduplicated.values.toList()..sort((a, b) => b.parsedDate.compareTo(a.parsedDate));
      _isLoading = false;
      _applyLogic();
    });
    _saveToCache();
  }

  /// THE FIX: Logic now filters the master list based on all active toggles
  void _applyLogic() {
    setState(() {
      Iterable<Article> filtered = _allArticles;

      // 1. Topic Filter (Sidebar)
      if (_activeFilter != "ALL") {
        filtered = filtered.where((a) => a.topics.contains(_activeFilter));
      }

      // 2. Theory Filter (Sidebar Toggle)
      if (_hideTheory) {
        filtered = filtered.where((a) => !a.topics.contains("THEORY/REVIEW"));
      }

      // 3. Extended Coverage Filter (The Fix)
      // If extended mode is OFF, hide anything that belongs specifically to the extended list
      if (!_extendedMode) {
        final Set<String> extendedNames = AppConfig.extendedSources.values.toSet();
        filtered = filtered.where((a) => !extendedNames.contains(a.source));
      }

      // 4. Manual Source Filter (Signal Sources Dialog)
      if (!_allSourcesEnabled) {
        filtered = filtered.where((a) => _enabledSources.contains(a.source));
      }

      _displayList = filtered.toList();
      _visibleCount = NetworkConfig.articlesPerPage;
      _showLoadMoreButton = false;
    });
  }

  Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(NetworkConfig.offlineCacheKey, jsonEncode(_allArticles.take(NetworkConfig.maxCachedArticles).map((a) => a.toMap()).toList()));
  }

  Future<void> _onFilterChanged(String filter) async {
    setState(() => _activeFilter = filter);
    _applyLogic();
    Navigator.pop(context);
  }

  Future<void> _onSearch(String query) async {
    setState(() {
      _displayList = _allArticles.where((a) => a.title.toLowerCase().contains(query.toLowerCase())).toList();
      _visibleCount = NetworkConfig.articlesPerPage;
    });
  }

  Future<void> _onArticleOpen(String title) async {}

  Future<void> _onSettingsOpen() async {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  /// Reset feed cache while preserving user settings.
  Future<void> _resetFeed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clear cached articles
      await prefs.remove(NetworkConfig.offlineCacheKey);
      // Clear viewed stories tracking
      await prefs.remove(NetworkConfig.viewedStoriesKey);
      // Reset internal state
      setState(() {
        _allArticles.clear();
        _displayList.clear();
        _viewedStoryMap.clear();
        _visibleCount = NetworkConfig.articlesPerPage;
        _isLoading = true;
        _showLoadMoreButton = false;
      });
      // Trigger fresh feed fetch
      await _fetchNews();
    } catch (e) {
      debugPrint("Reset Feed Error: $e");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: DashboardDrawer(
        primaryColor: widget.primaryColor, 
        onThemeChanged: widget.onThemeChanged,
        extendedMode: _extendedMode, 
        onResetFeed: _resetFeed,
        onExtendedModeChanged: (v) async { 
          final p = await SharedPreferences.getInstance(); 
          p.setBool('extended_coverage', v); 
          setState(() => _extendedMode = v); 
          // Re-apply logic immediately to hide/show extended articles already in cache
          _applyLogic();
          // Then fetch to ensure we have the latest if turning ON
          if (v) _fetchNews(); 
        },
        hideTheory: _hideTheory, 
        onHideTheoryChanged: (v) async { 
          final p = await SharedPreferences.getInstance(); 
          p.setBool('hide_theory', v); 
          setState(() => _hideTheory = v); 
          _applyLogic(); 
        },
        activeFilter: _activeFilter, 
        onFilterChanged: _onFilterChanged,
        onShowSources: () { 
          _onSettingsOpen();
          DashboardDialogs.showSourcesDialog(
            context: context, 
            primaryColor: widget.primaryColor, 
            extendedMode: _extendedMode, 
            allSourcesEnabled: _allSourcesEnabled, 
            enabledSources: _enabledSources, 
            onSaved: (all, set) async { 
              setState(() { 
                _allSourcesEnabled = all; 
                _enabledSources = set; 
              }); 
              final p = await SharedPreferences.getInstance(); 
              p.setBool('all_sources_enabled', all); 
              p.setStringList('enabled_sources', set.toList()); 
              _applyLogic();
              _fetchNews(); 
            }
          ); 
        },
        onShowAbout: () { 
          _scaffoldKey.currentState?.openEndDrawer();
          DashboardDialogs.showAboutDialog(context, widget.primaryColor); 
        },
        onShowGitHub: () async { 
          final url = Uri.parse('https://github.com/C0smicCactus/TheRadical');
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex, 
        onTap: (i) { 
          setState(() => _tabIndex = i); 
          if (i == 0) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
            }
          }
        }, 
        backgroundColor: AppColors.appBackground, 
        selectedItemColor: widget.primaryColor, 
        unselectedItemColor: Colors.white24, 
        type: BottomNavigationBarType.fixed, 
        items: const [
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.house, size: 18), label: "Home"), 
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.play, size: 18), label: "Videos")
        ]
      ),
      body: Column(children: [
        DashboardHeader(
          width: MediaQuery.of(context).size.width, 
          primaryColor: widget.primaryColor, 
          searchController: _searchController, 
          onSearchChanged: _onSearch,
          onLogoTap: () { 
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              );
            }
            setState(() {
              _activeFilter = "ALL"; 
              _applyLogic();
            }); 
          }, 
          onOpenSettings: _onSettingsOpen
        ),
        Expanded(child: DashboardContentView(
          tabIndex: _tabIndex, 
          isLoading: _isLoading, 
          isLoadingMore: _isLoadingMore,
          showLoadMoreButton: _showLoadMoreButton,
          onLoadMore: _loadMoreArticles,
          width: MediaQuery.of(context).size.width, 
          primaryColor: widget.primaryColor, 
          displayList: _displayList, 
          allArticles: _displayList, // Changed to displayList to keep stories consistent with feed
          viewedStoryLinks: _viewedStoryMap.keys.toSet(),
          onStoryViewed: _markStoryViewed,
          onArticleOpen: _onArticleOpen,
          visibleCount: _visibleCount, 
          scrollController: _scrollController, 
          totalSources: _totalSources, 
          completedSources: _completedSources, 
          statusMessage: _statusMessage, 
          onRefresh: () => _fetchNews()
        )),
      ]),
    );
  }
}