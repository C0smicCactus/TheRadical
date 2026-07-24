import '../models/article.dart';

/// Defines a filtering rule for a specific RSS feed.
///
/// Use this class to define rules that clean up or filter articles from
/// specific feeds. Each rule specifies:
/// - `feedIdentifier`: The feed's display name (must match the display name used in the app)
/// - `shouldExclude`: A predicate that returns true if the article should be excluded
///
/// Example:
/// ```dart
/// FeedFilterRule(
///   feedIdentifier: "GREEN LEFT",
///   shouldExclude: (article) => article.title.startsWith("Green Left Radio"),
/// )
/// ```
class FeedFilterRule {
  /// The feed's display name this rule applies to. Must match the display name
  /// used in AppConfig.coreSources, globalSources, or extendedSources maps.
  final String feedIdentifier;

  /// Predicate that determines if an article should be excluded from this feed.
  /// Return `true` to exclude the article, `false` to keep it.
  final bool Function(Article article) shouldExclude;

  const FeedFilterRule({
    required this.feedIdentifier,
    required this.shouldExclude,
  });
}

/// Centralized feed filtering rules.
///
/// Add, modify, or remove rules here to clean up specific feeds.
/// Rules are evaluated in order, and any article matching ANY rule for
/// its feed will be excluded from the app.
class FeedFilterRules {
  /// List of all feed-specific filtering rules.
  ///
  /// Add new rules here following the pattern:
  /// FeedFilterRule(
  ///   feedIdentifier: "https://example.com/feed.xml",
  ///   shouldExclude: (article) => /* your condition */,
  /// )
  static final List<FeedFilterRule> rules = [
    // Green Left: Exclude podcast items (titles start with "Green Left Radio")
    FeedFilterRule(
      feedIdentifier: "GREEN LEFT",
      shouldExclude: (article) => article.title.startsWith("Green Left Radio"),
    ),

    // Green Left: Exclude podcast items (titles start with "On The Street")
    FeedFilterRule(
      feedIdentifier: "GREEN LEFT",
      shouldExclude: (article) => article.title.startsWith("On The Street"),
    ),

    // ============================================================
    // Add your own rules below
    // ============================================================
    // Example: Exclude items with "Podcast" in the title from a specific feed
    // FeedFilterRule(
    //   feedIdentifier: "FEED DISPLAY NAME",
    //   shouldExclude: (article) => article.title.contains("Podcast"),
    // ),

    // Example: Exclude articles from a specific date range
    // FeedFilterRule(
    //   feedIdentifier: "FEED DISPLAY NAME",
    //   shouldExclude: (article) => article.parsedDate.isBefore(DateTime(2024, 1, 1)),
    // ),

    // Example: Exclude articles by a specific author
    // FeedFilterRule(
    //   feedIdentifier: "FEED DISPLAY NAME",
    //   shouldExclude: (article) => article.author == "Unwanted Author",
    // ),

    // Example: Exclude articles containing specific keywords in the description
    // FeedFilterRule(
    //   feedIdentifier: "FEED DISPLAY NAME",
    //   shouldExclude: (article) => article.description.toLowerCase().contains("unwanted keyword"),
    // ),

    // Example: Exclude articles from a specific feed entirely (empty predicate = exclude all)
    // FeedFilterRule(
    //   feedIdentifier: "FEED DISPLAY NAME",
    //   shouldExclude: (article) => true,
    // ),
  ];

  /// Checks if an article should be excluded based on its feed's rules.
  ///
  /// Returns `true` if the article should be excluded, `false` if it should be kept.
  /// If no rules exist for the article's feed, returns `false` (keep the article).
  static bool shouldExcludeArticle(Article article) {
    for (final rule in rules) {
      if (rule.feedIdentifier == article.source) {
        if (rule.shouldExclude(article)) {
          return true;
        }
      }
    }
    return false;
  }
}