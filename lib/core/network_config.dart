/// Centralized network and configuration constants for the application.
/// This class consolidates all external service URLs, timeout durations,
/// retry policies, and other configurable constants in one place.
class NetworkConfig {
  // =========================================================================
  // CORS PROXY CONFIGURATION
  // =========================================================================

  /// Primary CORS proxy for fetching RSS feeds in web environment.
  static const String primaryCorsProxy = 'https://corsproxy.io/?';

  /// Fallback CORS proxy if primary fails.
  static const String fallbackCorsProxy = 'https://api.allorigins.win/raw?url=';

  /// Image proxy for serving thumbnails through a CDN.
  static const String imageProxy = 'https://images.weserv.nl/?url=';

  /// Image proxy parameters for optimal display.
  static const String imageProxyParams = '&w=1200&fit=cover&output=webp';

  /// Whether to use CORS proxies (primarily for web builds).
  static const bool useCorsProxies = true;

  // =========================================================================
  // TIMEOUT CONFIGURATION
  // =========================================================================

  /// Timeout duration for RSS feed fetching requests.
  static const Duration feedFetchTimeout = Duration(seconds: 10);

  /// Timeout duration for image scraping requests.
  static const Duration imageScrapeTimeout = Duration(seconds: 4);

  /// Timeout duration for URL launch attempts.
  static const Duration urlLaunchTimeout = Duration(seconds: 5);

  /// Timeout duration for image loading in palette generation.
  static const Duration imageLoadTimeout = Duration(seconds: 8);

  // =========================================================================
  // RETRY CONFIGURATION
  // =========================================================================

  /// Number of retry attempts for failed feed fetches.
  static const int maxFeedFetchRetries = 2;

  /// Delay between retry attempts (in milliseconds).
  static const int retryDelayMs = 1000;

  /// Number of proxy failovers before giving up.
  static const int maxProxyFailovers = 1;

  // =========================================================================
  // CACHE CONFIGURATION
  // =========================================================================

  /// Maximum number of articles to cache for offline access.
  static const int maxCachedArticles = 100;

  /// Cache key for offline article storage.
  static const String offlineCacheKey = 'offline_cache';

  /// Cache key for viewed stories tracking.
  static const String viewedStoriesKey = 'viewed_stories_v1';

  /// Maximum age for viewed stories (in hours) before auto-cleanup.
  static const int maxViewedStoryAgeHours = 48;

  // =========================================================================
  // PAGINATION CONFIGURATION
  // =========================================================================

  /// Number of articles to load per infinite scroll batch.
  static const int articlesPerPage = 12;

  /// Scroll threshold (pixels from bottom) to trigger preload.
  static const double scrollThreshold = 400.0;

  /// Minimum scroll velocity to trigger load more.
  static const double minScrollVelocity = 0.5;

  // =========================================================================
  // ANALYTICS CONFIGURATION
  // =========================================================================

  /// Analytics storage key in SharedPreferences.
  static const String analyticsKey = 'app_analytics_v1';

  /// Session storage key.
  static const String sessionKey = 'app_session_v1';

  /// Maximum duration for a single session (in minutes).
  static const int maxSessionDurationMinutes = 30;

  /// Minimum session duration to count as meaningful (in seconds).
  static const int minMeaningfulSessionSeconds = 30;

  /// Maximum number of events to store per event type.
  static const int maxAnalyticsEvents = 500;

  /// Auto-cleanup interval for old analytics data (in days).
  static const int analyticsCleanupIntervalDays = 30;

  // =========================================================================
  // UI CONFIGURATION
  // =========================================================================

  /// Minimum touch target size (in logical pixels) for accessibility.
  static const double minTouchTargetSize = 48.0;

  /// Article tile width in desktop mode.
  static const double articleTileWidth = 400.0;

  /// Article tile height in desktop mode.
  static const double articleTileHeight = 610.0;

  /// Maximum article description snippet length.
  static const int descriptionSnippetLength = 85;

  /// Responsive breakpoint for mobile mode.
  static const double mobileBreakpoint = 432.0;

  /// Responsive breakpoint for desktop navigation.
  static const double desktopNavBreakpoint = 500.0;

  /// Maximum content width for desktop layout.
  static const double maxContentWidth = 1754.0;

  // =========================================================================
  // HELPER METHODS
  // =========================================================================

  /// Builds a CORS-proxy-wrapped URL for web requests.
  static String wrapCorsProxy(String url, {bool useFallback = false}) {
    if (!useCorsProxies) return url;
    final proxy = useFallback ? fallbackCorsProxy : primaryCorsProxy;
    return '$proxy${Uri.encodeComponent(url)}';
  }

  /// Builds an image proxy URL for thumbnail display.
  static String wrapImageProxy(String url) {
    if (url.isEmpty || !useCorsProxies) return url;
    return '$imageProxy${Uri.encodeComponent(url)}$imageProxyParams';
  }

  /// Returns all available CORS proxies in priority order.
  static List<String> get corsProxyList => [primaryCorsProxy, fallbackCorsProxy];

  /// Checks if a proxy URL is the primary or fallback.
  static bool isPrimaryProxy(String proxyUrl) => proxyUrl == primaryCorsProxy;
  static bool isFallbackProxy(String proxyUrl) => proxyUrl == fallbackCorsProxy;
}