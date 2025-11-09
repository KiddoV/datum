import 'package:jaspr_content/jaspr_content.dart';
import 'dart:io';

/// Extension that estimates reading time based on word count in the page content.
class ReadingTimeExtension extends PageExtension {
  ReadingTimeExtension();

  @override
  Future<List<Node>> apply(Page page, List<Node> nodes) async {
    // Count words in text nodes.
    int wordCount = 0;

    void countWords(List<Node> nodes) {
      for (final node in nodes) {
        if (node is TextNode) {
          wordCount += node.text.split(' ').where((word) => word.isNotEmpty).length;
        } else if (node is ElementNode && node.children != null) {
          countWords(node.children!);
        }
      }
    }

    countWords(nodes);

    // Calculate reading time (average 200 words per minute).
    final readingTimeMinutes = (wordCount / 200).ceil();

    // Store reading time in page data.
    page.apply(
      data: {
        'readingTime': '$readingTimeMinutes min read',
      },
    );

    return nodes;
  }
}

/// Extension that adds SEO enhancements like meta tags and structured data.
class SEOEnhancementsExtension extends PageExtension {
  SEOEnhancementsExtension();

  @override
  Future<List<Node>> apply(Page page, List<Node> nodes) async {
    // Extract title from first h1 heading if not already set
    String? title = page.data['title'] as String?;
    title ??= _extractTitle(nodes);

    // Extract description from first paragraph if not already set
    String? description = page.data['description'] as String?;
    description ??= _extractDescription(nodes);

    // Generate structured data for the page
    final structuredData = _generateStructuredData(page, title, description);

    // Apply SEO data to page
    final seoData = <String, dynamic>{
      'seo': {
        'title': title,
        'description': description,
        'structuredData': structuredData,
      },
    };

    page.apply(data: seoData);

    return nodes;
  }

  String? _extractTitle(List<Node> nodes) {
    for (final node in nodes) {
      if (node is ElementNode && node.tag == 'h1') {
        return _extractTextFromNode(node);
      }
      if (node is ElementNode && node.children != null && node.children!.isNotEmpty) {
        final title = _extractTitle(node.children!);
        if (title != null) return title;
      }
    }
    return null;
  }

  String? _extractDescription(List<Node> nodes) {
    for (final node in nodes) {
      if (node is ElementNode && node.tag == 'p') {
        final text = _extractTextFromNode(node);
        if (text != null && text.length > 50) {
          // Truncate to reasonable description length
          return text.length > 160 ? '${text.substring(0, 157)}...' : text;
        }
      }
      if (node is ElementNode && node.children != null && node.children!.isNotEmpty) {
        final desc = _extractDescription(node.children!);
        if (desc != null) return desc;
      }
    }
    return null;
  }

  String? _extractTextFromNode(ElementNode node) {
    final buffer = StringBuffer();
    _collectText(node, buffer);
    final text = buffer.toString().trim();
    return text.isNotEmpty ? text : null;
  }

  void _collectText(Node node, StringBuffer buffer) {
    if (node is TextNode) {
      buffer.write(node.text);
    } else if (node is ElementNode && node.children != null) {
      for (final child in node.children!) {
        _collectText(child, buffer);
      }
    }
  }

  Map<String, dynamic> _generateStructuredData(Page page, String? title, String? description) {
    final url = page.data['url'] as String? ?? '';
    final siteName = 'Datum Documentation';

    return {
      '@context': 'https://schema.org',
      '@type': 'TechArticle',
      'headline': title ?? 'Datum Documentation',
      'description': description ?? 'Documentation for Datum - Data, Seamlessly Synced',
      'url': url,
      'publisher': {
        '@type': 'Organization',
        'name': siteName,
        'url': 'https://datum.shreeman.dev', // Update with actual domain
      },
      'datePublished': page.data['date'] ?? DateTime.now().toIso8601String(),
      'dateModified': page.data['dateModified'] ?? DateTime.now().toIso8601String(),
    };
  }
}

/// Extension that adds last modified date based on file modification time.
class LastModifiedExtension extends PageExtension {
  LastModifiedExtension();

  @override
  Future<List<Node>> apply(Page page, List<Node> nodes) async {
    try {
      // Try to find the file and get its last modified date
      final title = page.data['title'] as String?;
      if (title != null) {
        final filePath = await _findFileByTitle(title);
        if (filePath != null) {
          final file = File(filePath);
          if (await file.exists()) {
            final modified = await file.lastModified();
            final formattedDate = _formatDate(modified);

            page.apply(
              data: {
                'lastModified': formattedDate,
                'lastModifiedIso': modified.toIso8601String(),
              },
            );
          }
        }
      }
    } catch (e) {
      // Silently ignore errors - last modified date is not critical
    }

    return nodes;
  }

  Future<String?> _findFileByTitle(String title) async {
    // Try to construct the most likely file path first
    final possiblePaths = [
      'content/${title.toLowerCase().replaceAll(' ', '_')}.md',
      'content/${title.toLowerCase().replaceAll(' ', '-')}.md',
      'content/${title.toLowerCase()}.md',
    ];

    for (final path in possiblePaths) {
      final file = File(path);
      if (await file.exists()) {
        return path;
      }
    }

    // Fallback: search recursively (slower)
    final contentDir = Directory('content');
    if (!await contentDir.exists()) return null;

    await for (final entity in contentDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.md')) {
        try {
          final content = await entity.readAsString();
          // Check multiple title formats
          if (content.contains('title: $title') ||
              content.contains('title: "$title"') ||
              content.contains("title: '$title'")) {
            return entity.path;
          }
        } catch (e) {
          // Skip files that can't be read
        }
      }
    }
    return null;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
  }
}

/// Extension that generates breadcrumb navigation data.
class BreadcrumbExtension extends PageExtension {
  BreadcrumbExtension();

  @override
  Future<List<Node>> apply(Page page, List<Node> nodes) async {
    // Since URL is not available during extension processing,
    // generate breadcrumbs based on the page title structure
    final title = page.data['title'] as String?;
    if (title == null) {
      return nodes;
    }

    final breadcrumbs = <Map<String, String>>[];

    // Add home
    breadcrumbs.add({
      'title': 'Home',
      'url': '/',
    });

    // For pages with "Module" in the title, assume they're in /modules/
    if (title.contains('Module')) {
      breadcrumbs.add({
        'title': 'Modules',
        'url': '/modules',
      });
    }
    // For pages with "Guide" or other patterns, we could add more logic here

    page.apply(
      data: {
        'breadcrumbs': breadcrumbs,
      },
    );

    return nodes;
  }
}

/// Extension that generates previous/next page navigation.
class PageNavigationExtension extends PageExtension {
  PageNavigationExtension();

  @override
  Future<List<Node>> apply(Page page, List<Node> nodes) async {
    // This would need access to the site structure to determine prev/next pages
    // For now, we'll implement a basic version that could be enhanced

    final _ = page.data['url'] as String? ?? '';

    // This is a simplified implementation - in a real scenario,
    // you'd want to build a proper navigation tree
    final navigation = <String, dynamic>{};

    // You could implement logic here to find previous and next pages
    // based on the site structure, perhaps by maintaining a list of all pages

    page.apply(
      data: {
        'navigation': navigation,
      },
    );

    return nodes;
  }
}
