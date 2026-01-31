import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as html;

/// A cached version of GitHubButton that stores API responses to reduce calls.
@client
final class CachedGitHubButton extends StatefulComponent {
  /// Create a new [CachedGitHubButton] component that links to the specified GitHub [repo]
  /// and shows the amount of stars and forks it has.
  ///
  /// The [cacheDurationMinutes] specifies how long to cache the API response in minutes.
  /// Default is 5 minutes.
  const CachedGitHubButton({
    required this.repo,
    this.cacheDurationMinutes = 5,
    super.key,
  });

  /// The ID of the GitHub repository,
  /// in the form `<organization or user name>/<repository name>`.
  final String repo;

  /// How long to cache the GitHub API response in minutes.
  final int cacheDurationMinutes;

  @override
  State<CachedGitHubButton> createState() => _CachedGitHubButtonState();

  @css
  static List<StyleRule> get styles => [
    css('.github-button', [
      css('&').styles(
        display: Display.flex,
        padding: Padding.symmetric(horizontal: 0.7.rem, vertical: 0.4.rem),
        radius: BorderRadius.circular(8.px),
        alignItems: AlignItems.center,
        gap: Gap(column: .5.rem),
        fontSize: 0.7.rem,
        textDecoration: TextDecoration.none,
        lineHeight: 1.2.em,
      ),
      css('&:hover').styles(backgroundColor: Color('color-mix(in srgb, currentColor 5%, transparent)')),
      css('& *').styles(
        transition: Transition('opacity', duration: 200.ms, curve: Curve.easeInOut),
      ),
      css('&:hover *').styles(raw: {'opacity': '1 !important'}),
      css('.github-icon').styles(width: 1.2.rem),
      css('.github-info', [
        css('&').styles(display: Display.flex, flexDirection: FlexDirection.column),
        css('& > span:first-child').styles(
          margin: Margin.only(bottom: 2.px),
          opacity: 0.9,
          fontFamily: FontFamily.list([FontFamilies.monospace]),
        ),
        css('& > span:last-child', [
          css('&').styles(
            display: Display.flex,
            opacity: 0.7,
            alignItems: AlignItems.center,
            gap: Gap(column: .3.em),
            fontSize: 0.9.em,
            fontWeight: FontWeight.w800,
          ),
          css('span').styles(fontWeight: FontWeight.w500),
        ]),
      ]),
    ]),
    // Responsive design for mobile
    css('@media (max-width: 640px)', [
      css('.github-button', [
        css('&').styles(
          padding: Padding.symmetric(horizontal: 2.rem, vertical: 0.3.rem),
          gap: Gap(column: .3.rem),
          fontSize: 0.65.rem,
        ),
        css('.github-icon').styles(width: 1.0.rem),
        css('.github-info', [
          css('& > span:first-child').styles(
            fontSize: 0.8.em,
          ),
          css('& > span:last-child').styles(
            gap: Gap(column: .2.em),
            fontSize: 0.8.em,
          ),
        ]),
      ]),
    ]),
  ];
}

class _CachedGitHubButtonState extends State<CachedGitHubButton> with PreloadStateMixin<CachedGitHubButton> {
  int? _stars;
  int? _forks;

  bool get loaded => _stars != null;

  @override
  Future<void> preloadState() async {
    if (!kGenerateMode && kReleaseMode) {
      await loadRepositoryData();
    }
  }

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      loadRepositoryData().then((_) {
        setState(() {});
      });
    }
  }

  Future<void> loadRepositoryData() async {
    final cacheManager = CacheManager();
    final cachedData = cacheManager.getCachedData(component.repo);

    if (cachedData != null && !cacheManager.isExpired(cachedData, Duration(minutes: component.cacheDurationMinutes))) {
      // Use cached data
      _stars = cachedData['stars'] as int;
      _forks = cachedData['forks'] as int;
      return;
    }

    // Fetch new data
    final response = await http.get(Uri.https('api.github.com', '/repos/${component.repo}'));
    if (response.statusCode != 200) {
      return;
    }
    final data = jsonDecode(response.body) as Map<String, Object?>;
    final {'stargazers_count': stars as int, 'forks_count': forks as int} = data;

    _stars = stars;
    _forks = forks;

    // Cache the data
    cacheManager.cacheData(component.repo, stars, forks);
  }

  @override
  Component build(BuildContext _) {
    return a(href: 'https://github.com/${component.repo}', target: Target.blank, classes: 'github-button not-content', [
      div(classes: 'github-icon', const [_GitHubIcon()]),
      div(classes: 'github-info', [
        span([Component.text(component.repo)]),
        span([
          Component.text('★'),
          span(styles: !loaded ? const Styles(opacity: 0) : null, [Component.text('${_stars ?? 9999}')]),
          span([]),
          Component.text('⑂'),
          span(styles: !loaded ? const Styles(opacity: 0) : null, [Component.text('${_forks ?? 99}')]),
        ]),
      ]),
    ]);
  }
}

/// Internal cache manager for GitHub repository data.
class CacheManager {
  // Private constructor
  CacheManager._privateConstructor();

  // Singleton instance
  static final CacheManager _instance = CacheManager._privateConstructor();

  // Factory constructor to return the singleton instance
  factory CacheManager() {
    return _instance;
  }

  static const String _storageKey = 'github_cache';

  /// Get cached data for a repository.
  Map<String, dynamic>? getCachedData(String repo) {
    try {
      final storage = html.window.localStorage;
      final storageData = storage.getItem(_storageKey);
      if (storageData == null) {
        print('CacheManager: No cached data found in localStorage');
        return null;
      }

      final Map<String, dynamic> allCache = jsonDecode(storageData);
      final data = allCache[repo];

      print('CacheManager: Getting cached data for repo "$repo" - ${data != null ? 'found' : 'not found'}');
      return data;
    } catch (e) {
      print('CacheManager: Error reading from localStorage: $e');
      return null;
    }
  }

  /// Cache data for a repository.
  void cacheData(String repo, int stars, int forks) {
    try {
      final storage = html.window.localStorage;
      final storageData = storage.getItem(_storageKey);
      final Map<String, dynamic> allCache = storageData != null ? jsonDecode(storageData) : {};

      allCache[repo] = {
        'stars': stars,
        'forks': forks,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      storage.setItem(_storageKey, jsonEncode(allCache));
      print('CacheManager: Cached data for repo "$repo" - stars: $stars, forks: $forks');
    } catch (e) {
      print('CacheManager: Error writing to localStorage: $e');
    }
  }

  /// Check if cached data is expired.
  bool isExpired(Map<String, dynamic> cachedData, Duration cacheDuration) {
    final timestamp = cachedData['timestamp'] as int;
    final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final expired = now.difference(cachedTime) > cacheDuration;
    print(
      'CacheManager: Checking expiration for cached data - age: ${now.difference(cachedTime)}, duration: $cacheDuration, expired: $expired',
    );
    return expired;
  }
}

class _GitHubIcon extends StatelessComponent {
  const _GitHubIcon();

  @override
  Component build(BuildContext _) {
    return svg(
      viewBox: '0 0 24 24',
      attributes: {'fill': 'currentColor'},
      [
        path(
          d:
              r'M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.0'
              '15-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.2'
              '05.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-'
              '1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1'
              '.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.8'
              '4 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 '
              '.315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12',
          [],
        ),
      ],
    );
  }
}
