import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parseFragment;
import '../models/article.dart';
import '../core/app_config.dart';
import '../core/network_config.dart';
import '../core/feed_filter_rules.dart';

class FeedParser {
  static List<Article> parse(String rawXml, String sourceName) {
    final List<Article> results = [];
    final itemRegex = RegExp(r'<item>(.*?)</item>', dotAll: true);
    final atomRegex = RegExp(r'<entry>(.*?)</entry>', dotAll: true);

    Iterable<RegExpMatch> items = itemRegex.allMatches(rawXml);
    if (items.isEmpty) items = atomRegex.allMatches(rawXml);

    for (var match in items) {
      final content = match.group(1) ?? '';

      String title = cleanHtml(RegExp(r'<title[^>]*>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</title>', dotAll: true).firstMatch(content)?.group(1) ?? 'Untitled');

      if (AppConfig.globalSources.values.contains(sourceName)) {
        bool isRelevant = AppConfig.auKeywords.any((k) {
          final pattern = r'\b' + k.toLowerCase() + r'\b';
          return RegExp(pattern).hasMatch(title.toLowerCase());
        });
        if (!isRelevant) continue;
      }

      String link = RegExp(r'<link>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</link>', dotAll: true).firstMatch(content)?.group(1) ?? 
                    RegExp(r"""<link[^>]+href=["']([^"']+)["']""").firstMatch(content)?.group(1) ?? '';
      String pubDateStr = RegExp(r'<pubDate>(.*?)</pubDate>', dotAll: true).firstMatch(content)?.group(1) ?? 
                          RegExp(r'<published>(.*?)</published>', dotAll: true).firstMatch(content)?.group(1) ?? '';

      String summary = RegExp(r'<summary.*?>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</summary>', dotAll: true).firstMatch(content)?.group(1) ?? '';
      String description = RegExp(r'<description>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</description>', dotAll: true).firstMatch(content)?.group(1) ?? '';
      String bestDesc = summary.isNotEmpty ? summary : description;

      // Extract author from various feed formats (BEFORE cleaning):
      // RSS 2.0: <author> or <dc:creator>
      // Atom: <author><name>...</name></author>
      String author = RegExp(r'<author[^>]*>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</author>', dotAll: true).firstMatch(content)?.group(1) ?? '';
      if (author.isEmpty) {
        author = RegExp(r'<dc:creator[^>]*>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</dc:creator>', dotAll: true).firstMatch(content)?.group(1) ?? '';
      }
      if (author.isEmpty) {
        final atomNameMatch = RegExp(r'<author[^>]*>.*?<name[^>]*>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</name>', dotAll: true).firstMatch(content);
        if (atomNameMatch != null) author = atomNameMatch.group(1) ?? '';
      }
      
      // Fallback: Extract author from "by [Name]" patterns in the raw content
      // This catches patterns like "by John Smith", "By Jane Doe", etc.
      if (author.isEmpty) {
        // Use the raw content (before HTML cleaning) to find "by [Name]" patterns
        // Match 2-4 word names like "John Smith", "Mary Jane Watson", etc.
        final byMatch = RegExp(r'\bby\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+){1,3})\b', caseSensitive: false).firstMatch(content);
        if (byMatch != null) {
          author = byMatch.group(1)?.trim() ?? '';
        }
        
        // If still no author, try the title
        if (author.isEmpty) {
          final titleByMatch = RegExp(r'\bby\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+){1,3})\b', caseSensitive: false).firstMatch(title);
          if (titleByMatch != null) {
            author = titleByMatch.group(1)?.trim() ?? '';
          }
        }
      }
      
      author = author.trim();

      List<String> tags = [];
      bool isTheory = AppConfig.theoryKeywords.any((k) => "$title $bestDesc".toLowerCase().contains(k.toLowerCase()));
      if (isTheory) tags.add("THEORY/REVIEW");

      // Weighted topic scoring system
      final textLower = "$title $bestDesc".toLowerCase();
      final titleLower = title.toLowerCase();
      
      for (final topic in AppConfig.topics) {
        double score = 0.0;
        
        for (final kw in topic.keywords) {
          final kwLower = kw.keyword.toLowerCase();
          final isMultiWord = kwLower.contains(' ');
          
          // Title matches get 3x weight bonus
          if (titleLower.contains(kwLower)) {
            score += kw.weight * 3.0;
            if (isMultiWord) score += 1.0; // Multi-word phrase bonus in title
          }
          
          // Description matches get 1x weight
          if (textLower.contains(kwLower)) {
            score += kw.weight * 1.0;
            if (isMultiWord) score += 0.5; // Multi-word phrase bonus in text
          }
        }
        
        // Check exclusion keywords
        bool hasExclusion = topic.exclusions.any((excl) => textLower.contains(excl.toLowerCase()));
        
        // Only tag if score meets threshold AND no exclusions
        if (score >= topic.threshold && !hasExclusion) {
          tags.add(topic.name);
        }
      }

      // Apply feed-specific filtering rules
      final article = Article(
        title: title,
        link: link.trim(),
        source: sourceName,
        topics: tags,
        description: cleanHtml(bestDesc),
        thumbnail: wrapProxy(scrapeImage(content + bestDesc)),
        parsedDate: parseDate(pubDateStr),
        author: author.isEmpty ? null : author,
      );

      if (!FeedFilterRules.shouldExcludeArticle(article)) {
        results.add(article);
      }
    }
    return results;
  }

  /// Scrapes the first image from a URL's OG meta tag.
  /// Uses centralized [NetworkConfig] for proxy URLs and timeouts.
  static Future<String> scrapeUrlForImage(String url) async {
    if (url.isEmpty) return "";
    try {
      final String finalUrl = kIsWeb ? NetworkConfig.wrapCorsProxy(url) : url;
      final response = await http.get(Uri.parse(finalUrl)).timeout(NetworkConfig.imageScrapeTimeout);
      if (response.statusCode == 200) {
        final ogMatch = RegExp(r"""<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']""").firstMatch(response.body);
        return ogMatch?.group(1) ?? "";
      }
    } catch (_) {}
    return "";
  }

  static DateTime parseDate(String s) {
    if (s.isEmpty) return DateTime.now();
    DateTime? r = DateTime.tryParse(s);
    if (r != null) return r;
    try {
      String c = s.split(' +').first.split(' -').first;
      return DateFormat("E, d MMM yyyy HH:mm:ss").parse(c);
    } catch (_) { return DateTime.now(); }
  }

  /// AGGRESSIVE RECURSIVE CLEANER
  static String cleanHtml(String input) {
    if (input.isEmpty) return "";

    // 1. Pre-emptive strike on specific broken patterns
    String result = input
        .replaceAll(RegExp(r'<!\[CDATA\[|\]\]>'), '')
        .replaceAll('amp;nbsp', ' ')
        .replaceAll('&nbsp;', ' ');

    // 2. Recursive Decoding
    // Some feeds encode things 2 or 3 times. We keep decoding until 
    // the string stops changing or no entities remain.
    String previous;
    int limit = 0;
    do {
      previous = result;
      result = parseFragment(result).text ?? "";
      limit++;
    } while (result != previous && limit < 3);

    // 3. Final Regular Expression sweep
    // This removes literal strings like "<p>" if they survived as text
    result = result
        .replaceAll(RegExp(r'<[^>]*>', dotAll: true), '') 
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return result;
  }

  static String scrapeImage(String h) => RegExp(r"""<img[^>]+src=["']([^"']+)["']""", caseSensitive: false).firstMatch(h)?.group(1) ?? '';

  /// Wraps an image URL with the centralized image proxy.
  static String wrapProxy(String u) {
    return NetworkConfig.wrapImageProxy(u);
  }
}
