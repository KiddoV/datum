import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Algolia DocSearch v4 component for documentation sites.
/// This component integrates the official Algolia DocSearch JavaScript library.
class AlgoliaDocSearch extends StatelessComponent {
  /// Algolia Application ID
  final String appId;

  /// Algolia Index name
  final String indexName;

  /// Algolia Search API Key
  final String apiKey;

  /// Algolia Assistant ID for Ask AI functionality (optional)
  final String? askAi;

  /// Container ID for the search element
  final String containerId;

  /// Placeholder text for the search input
  final String placeholder;

  /// Search parameters for filtering
  final Map<String, dynamic>? searchParameters;

  /// Whether to enable insights/analytics
  final bool insights;

  const AlgoliaDocSearch({
    required this.appId,
    required this.indexName,
    required this.apiKey,
    this.askAi,
    this.containerId = 'docsearch',
    this.placeholder = 'Search documentation...',
    this.searchParameters,
    this.insights = false,
    super.key,
  });

  /// Create an instance using the Datum documentation Algolia index
  factory AlgoliaDocSearch.datum({
    String containerId = 'docsearch',
    String placeholder = 'Search documentation...',
  }) {
    return AlgoliaDocSearch(
      appId: 'AYCJLERAMC',
      indexName: 'datum documentation',
      apiKey: 'ded44b72bcf56b2677d8709840d5199d',
      // askAi: 'YOUR_ALGOLIA_ASSISTANT_ID', // TODO: Add when assistant is created
      containerId: containerId,
      placeholder: placeholder,
    );
  }

  /// Create a demo instance using Algolia's demo credentials
  factory AlgoliaDocSearch.demo({
    String containerId = 'docsearch',
    String placeholder = 'Search documentation...',
  }) {
    return AlgoliaDocSearch(
      appId: 'PMZUYBQDAK',
      indexName: 'docsearch',
      apiKey: '24b09689d5b4223813d9b8e48563c8f6',
      askAi: 'askAIDemo',
      containerId: containerId,
      placeholder: placeholder,
    );
  }

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      // Add DocSearch CSS and JS to the document head
      Document.head(
        children: [
          // DocSearch CSS
          link(
            rel: 'stylesheet',
            href: 'https://cdn.jsdelivr.net/npm/@docsearch/css@4',
          ),
          // Preconnect for performance
          link(
            rel: 'preconnect',
            href: 'https://$appId-dsn.algolia.net',
            attributes: {'crossorigin': ''},
          ),
          // DocSearch JavaScript
          script(
            src: 'https://cdn.jsdelivr.net/npm/@docsearch/js@4',
            attributes: {'defer': ''},
          ),
          // Initialization script
          script(
            content: _generateInitScript(),
          ),
        ],
      ),

      // Container element for DocSearch
      div(
        id: containerId,
        styles: Styles.combine([
          Styles(display: Display.flex, alignItems: AlignItems.center),
        ]),
        [],
      ),
    ]);
  }

  String _generateInitScript() {
    final config = {
      'container': '#$containerId',
      'appId': appId,
      'indexName': indexName,
      'apiKey': apiKey,
      if (askAi != null) 'askAi': askAi,
      if (searchParameters != null) 'searchParameters': searchParameters,
      if (insights) 'insights': true,
    };

    return '''
(function() {
  var attempts = 0;
  var maxAttempts = 100; // 10 seconds max wait (100 * 100ms)
  var container;

  // Wait for DOM to be ready
  function initWhenReady() {
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', startInitialization);
    } else {
      startInitialization();
    }
  }

  function startInitialization() {
    container = document.getElementById('$containerId');

    // Show loading state initially
    if (container) {
      container.innerHTML = '<div style="padding: 8px 12px; color: #999; font-size: 14px;">Loading search...</div>';
    }

    initDocSearch();
  }

  // Wait for DocSearch to load
  function initDocSearch() {
    if (typeof docsearch !== 'undefined') {
      try {
        // Clear loading state
        if (container) {
          container.innerHTML = '';
        }
        docsearch(${_jsonEncode(config)});
      } catch (error) {
        console.warn('Failed to initialize DocSearch:', error);
        showSearchFallback();
      }
    } else if (attempts < maxAttempts) {
      attempts++;
      setTimeout(initDocSearch, 100);
    } else {
      console.warn('DocSearch library failed to load within timeout');
      showSearchFallback();
    }
  }

  function showSearchFallback() {
    if (container) {
      container.innerHTML = '<div style="padding: 8px 12px; color: #666; font-size: 14px; border: 1px solid #ddd; border-radius: 4px; background: #f9f9f9;">Search temporarily unavailable</div>';
    }
  }

  initWhenReady();
})();
    ''';
  }

  String _jsonEncode(Map<String, dynamic> data) {
    // Simple JSON encoding for the config
    final entries = data.entries
        .map((e) {
          final key = '"${e.key}"';
          final value = _encodeValue(e.value);
          return '$key:$value';
        })
        .join(',');

    return '{$entries}';
  }

  String _encodeValue(dynamic value) {
    if (value is String) {
      return '"$value"';
    } else if (value is bool) {
      return value.toString();
    } else if (value is Map<String, dynamic>) {
      return _jsonEncode(value);
    } else {
      return value.toString();
    }
  }
}
