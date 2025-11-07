// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/jaspr.dart';
import 'package:datum_docs/components/badge.dart' as prefix0;
import 'package:datum_docs/components/cached_github_button.dart' as prefix1;
import 'package:datum_docs/components/card.dart' as prefix2;
import 'package:datum_docs/components/code_block.dart' as prefix3;
import 'package:datum_docs/components/custom_image.dart' as prefix4;
import 'package:datum_docs/components/enhanced_theme_toggle.dart' as prefix5;
import 'package:datum_docs/components/steps.dart' as prefix6;
import 'package:datum_docs/components/tip.dart' as prefix7;
import 'package:jaspr_content/components/_internal/code_block_copy_button.dart'
    as prefix8;
import 'package:jaspr_content/components/_internal/zoomable_image.dart'
    as prefix9;
import 'package:jaspr_content/components/callout.dart' as prefix10;
import 'package:jaspr_content/components/sidebar_toggle_button.dart'
    as prefix11;

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
    prefix1.CachedGitHubButton: ClientTarget<prefix1.CachedGitHubButton>(
      'components/cached_github_button',
      params: _prefix1CachedGitHubButton,
    ),

    prefix5.EnhancedThemeToggle: ClientTarget<prefix5.EnhancedThemeToggle>(
      'components/enhanced_theme_toggle',
    ),

    prefix8.CodeBlockCopyButton: ClientTarget<prefix8.CodeBlockCopyButton>(
      'jaspr_content:components/_internal/code_block_copy_button',
    ),

    prefix9.ZoomableImage: ClientTarget<prefix9.ZoomableImage>(
      'jaspr_content:components/_internal/zoomable_image',
      params: _prefix9ZoomableImage,
    ),

    prefix11.SidebarToggleButton: ClientTarget<prefix11.SidebarToggleButton>(
      'jaspr_content:components/sidebar_toggle_button',
    ),
  },
  styles: () => [
    ...prefix0.Badge.styles,
    ...prefix1.CachedGitHubButton.styles,
    ...prefix2.Card.styles,

    ...prefix3.CodeBlock.styles,
    ...prefix4.CustomImage.styles,
    ...prefix5.EnhancedThemeToggleState.styles,
    ...prefix6.Steps.styles,
    ...prefix7.Tip.styles,

    ...prefix9.ZoomableImage.styles,
    ...prefix10.Callout.styles,
  ],
);

Map<String, dynamic> _prefix1CachedGitHubButton(prefix1.CachedGitHubButton c) =>
    {'repo': c.repo, 'cacheDurationMinutes': c.cacheDurationMinutes};
Map<String, dynamic> _prefix9ZoomableImage(prefix9.ZoomableImage c) => {
  'src': c.src,
  'alt': c.alt,
  'caption': c.caption,
};
