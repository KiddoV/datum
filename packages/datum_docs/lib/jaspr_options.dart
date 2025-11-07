// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/jaspr.dart';
import 'package:datum_docs/components/cached_github_button.dart' as prefix0;
import 'package:datum_docs/components/code_block.dart' as prefix1;
import 'package:datum_docs/components/custom_image.dart' as prefix2;
import 'package:datum_docs/components/enhanced_theme_toggle.dart' as prefix3;
import 'package:jaspr_content/components/_internal/code_block_copy_button.dart'
    as prefix4;
import 'package:jaspr_content/components/_internal/zoomable_image.dart'
    as prefix5;
import 'package:jaspr_content/components/callout.dart' as prefix6;
import 'package:jaspr_content/components/sidebar_toggle_button.dart' as prefix7;

/// Default [JasprOptions] for use with your jaspr project.
///
/// Use this to initialize jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'jaspr_options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultJasprOptions,
///   );
///
///   runApp(...);
/// }
/// ```
JasprOptions get defaultJasprOptions => JasprOptions(
  clients: {
    prefix0.CachedGitHubButton: ClientTarget<prefix0.CachedGitHubButton>(
      'components/cached_github_button',
      params: _prefix0CachedGitHubButton,
    ),

    prefix3.EnhancedThemeToggle: ClientTarget<prefix3.EnhancedThemeToggle>(
      'components/enhanced_theme_toggle',
    ),

    prefix4.CodeBlockCopyButton: ClientTarget<prefix4.CodeBlockCopyButton>(
      'jaspr_content:components/_internal/code_block_copy_button',
    ),

    prefix5.ZoomableImage: ClientTarget<prefix5.ZoomableImage>(
      'jaspr_content:components/_internal/zoomable_image',
      params: _prefix5ZoomableImage,
    ),

    prefix7.SidebarToggleButton: ClientTarget<prefix7.SidebarToggleButton>(
      'jaspr_content:components/sidebar_toggle_button',
    ),
  },
  styles: () => [
    ...prefix0.CachedGitHubButton.styles,

    ...prefix1.CodeBlock.styles,
    ...prefix2.CustomImage.styles,
    ...prefix3.EnhancedThemeToggleState.styles,

    ...prefix5.ZoomableImage.styles,
    ...prefix6.Callout.styles,
  ],
);

Map<String, dynamic> _prefix0CachedGitHubButton(prefix0.CachedGitHubButton c) =>
    {'repo': c.repo, 'cacheDurationMinutes': c.cacheDurationMinutes};
Map<String, dynamic> _prefix5ZoomableImage(prefix5.ZoomableImage c) => {
  'src': c.src,
  'alt': c.alt,
  'caption': c.caption,
};
