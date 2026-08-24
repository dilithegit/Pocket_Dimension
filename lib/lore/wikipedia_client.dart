import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// Structured payload representing a fetched Wikipedia article extract.
@immutable
class WikipediaArticle {
  final String title;
  final String extract;
  final String url;

  const WikipediaArticle({
    required this.title,
    required this.extract,
    required this.url,
  });
}

/// Client for querying Wikipedia's public API for plain-text lore extracts.
class WikipediaClient {
  final http.Client _httpClient;

  WikipediaClient({http.Client? client}) : _httpClient = client ?? http.Client();

  /// Search Wikipedia for [topic] and return the top article's plain-text extract and source URL.
  Future<WikipediaArticle?> fetchExtractForTopic(String topic) async {
    final trimmed = topic.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.https('en.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'generator': 'search',
      'gsrsearch': trimmed,
      'gsrlimit': '1',
      'prop': 'extracts',
      'explaintext': '1',
      'format': 'json',
      'origin': '*',
    });

    try {
      final response = await _httpClient.get(
        uri,
        headers: {'User-Agent': 'PocketDimensionRPG/1.0 (LoreIngestion; open-source)'},
      );

      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data = jsonDecode(response.body);
      final query = data['query'] as Map<String, dynamic>?;
      if (query == null) return null;

      final pages = query['pages'] as Map<String, dynamic>?;
      if (pages == null || pages.isEmpty) return null;

      final firstPage = pages.values.first as Map<String, dynamic>;
      final String title = firstPage['title'] as String? ?? trimmed;
      final String extract = firstPage['extract'] as String? ?? '';

      if (extract.trim().isEmpty) return null;

      final String formattedTitle = title.replaceAll(' ', '_');
      final String sourceUrl = 'https://en.wikipedia.org/wiki/${Uri.encodeComponent(formattedTitle)}';

      return WikipediaArticle(
        title: title,
        extract: extract.trim(),
        url: sourceUrl,
      );
    } catch (_) {
      return null;
    }
  }

  /// Splits [text] into ~[targetChunkWords]-word chunks with roughly [overlapWords]-word overlap.
  static List<String> chunkText(
    String text, {
    int targetChunkWords = 200,
    int overlapWords = 20,
  }) {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return [];

    final RegExp wordRegExp = RegExp(r'\s+');
    final List<String> words = cleanText.split(wordRegExp);

    if (words.length <= targetChunkWords) {
      return [cleanText];
    }

    final List<String> chunks = [];
    final int step = (targetChunkWords > overlapWords)
        ? targetChunkWords - overlapWords
        : targetChunkWords;

    for (int i = 0; i < words.length; i += step) {
      int end = i + targetChunkWords;
      if (end > words.length) {
        end = words.length;
      }

      final chunkWords = words.sublist(i, end);
      final chunkString = chunkWords.join(' ').trim();
      if (chunkString.isNotEmpty) {
        chunks.add(chunkString);
      }

      // If we reached the end of the text, stop
      if (end == words.length) {
        break;
      }
    }

    return chunks;
  }
}
