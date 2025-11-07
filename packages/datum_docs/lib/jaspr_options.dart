// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/jaspr.dart';
import 'package:datum_docs/components/badge.dart' as prefix0;
import 'package:datum_docs/components/cached_github_button.dart' as prefix1;
import 'package:datum_docs/components/card.dart' as prefix2;
import 'package:datum_docs/components/code_block.dart' as prefix3;
import 'package:datum_docs/components/comparison_table.dart' as prefix4;
import 'package:datum_docs/components/custom_image.dart' as prefix5;
import 'package:datum_docs/components/enhanced_theme_toggle.dart' as prefix6;
import 'package:datum_docs/components/steps.dart' as prefix7;
import 'package:datum_docs/components/tip.dart' as prefix8;
import 'package:jaspr_content/components/_internal/code_block_copy_button.dart'
    as prefix9;
import 'package:jaspr_content/components/_internal/tab_bar.dart' as prefix10;
import 'package:jaspr_content/components/_internal/zoomable_image.dart'
    as prefix11;
import 'package:jaspr_content/components/sidebar_toggle_button.dart'
    as prefix12;
import 'package:jaspr_content/components/tabs.dart' as prefix13;

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

    prefix6.EnhancedThemeToggle: ClientTarget<prefix6.EnhancedThemeToggle>(
      'components/enhanced_theme_toggle',
    ),

    prefix9.CodeBlockCopyButton: ClientTarget<prefix9.CodeBlockCopyButton>(
      'jaspr_content:components/_internal/code_block_copy_button',
    ),

    prefix10.TabBar: ClientTarget<prefix10.TabBar>(
      'jaspr_content:components/_internal/tab_bar',
      params: _prefix10TabBar,
    ),

    prefix11.ZoomableImage: ClientTarget<prefix11.ZoomableImage>(
      'jaspr_content:components/_internal/zoomable_image',
      params: _prefix11ZoomableImage,
    ),

    prefix12.SidebarToggleButton: ClientTarget<prefix12.SidebarToggleButton>(
      'jaspr_content:components/sidebar_toggle_button',
    ),
  },
  styles: () => [
    ...prefix0.Badge.styles,
    ...prefix1.CachedGitHubButton.styles,
    ...prefix2.Card.styles,

    ...prefix3.CodeBlock.styles,
    ...prefix4.ComparisonTable.styles,
    ...prefix5.CustomImage.styles,
    ...prefix6.EnhancedThemeToggleState.styles,
    ...prefix7.Steps.styles,
    ...prefix8.Tip.styles,
    ...prefix10.TabBar.styles,
    ...prefix11.ZoomableImage.styles,

    ...prefix13.Tabs.styles,
  ],
);

Map<String, dynamic> _prefix1CachedGitHubButton(prefix1.CachedGitHubButton c) =>
    {'repo': c.repo, 'cacheDurationMinutes': c.cacheDurationMinutes};
Map<String, dynamic> _prefix10TabBar(prefix10.TabBar c) => {
  'initialValue': c.initialValue,
  'items': c.items,
};
Map<String, dynamic> _prefix11ZoomableImage(prefix11.ZoomableImage c) => {
  'src': c.src,
  'alt': c.alt,
  'caption': c.caption,
};
