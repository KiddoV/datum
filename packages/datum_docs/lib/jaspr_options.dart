// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/jaspr.dart';
import 'package:datum_docs/components/code_block.dart' as prefix0;
import 'package:datum_docs/components/custom_image.dart' as prefix1;
import 'package:jaspr_content/components/_internal/code_block_copy_button.dart'
    as prefix2;
import 'package:jaspr_content/components/_internal/zoomable_image.dart'
    as prefix3;
import 'package:jaspr_content/components/callout.dart' as prefix4;
import 'package:jaspr_content/components/github_button.dart' as prefix5;
import 'package:jaspr_content/components/sidebar_toggle_button.dart' as prefix6;
import 'package:jaspr_content/components/theme_toggle.dart' as prefix7;

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
    prefix2.CodeBlockCopyButton: ClientTarget<prefix2.CodeBlockCopyButton>(
      'jaspr_content:components/_internal/code_block_copy_button',
    ),

    prefix3.ZoomableImage: ClientTarget<prefix3.ZoomableImage>(
      'jaspr_content:components/_internal/zoomable_image',
      params: _prefix3ZoomableImage,
    ),

    prefix5.GitHubButton: ClientTarget<prefix5.GitHubButton>(
      'jaspr_content:components/github_button',
      params: _prefix5GitHubButton,
    ),

    prefix6.SidebarToggleButton: ClientTarget<prefix6.SidebarToggleButton>(
      'jaspr_content:components/sidebar_toggle_button',
    ),

    prefix7.ThemeToggle: ClientTarget<prefix7.ThemeToggle>(
      'jaspr_content:components/theme_toggle',
    ),
  },
  styles: () => [
    ...prefix0.CodeBlock.styles,
    ...prefix1.CustomImage.styles,

    ...prefix3.ZoomableImage.styles,
    ...prefix4.Callout.styles,

    ...prefix5.GitHubButton.styles,

    ...prefix7.ThemeToggleState.styles,
  ],
);

Map<String, dynamic> _prefix3ZoomableImage(prefix3.ZoomableImage c) => {
  'src': c.src,
  'alt': c.alt,
  'caption': c.caption,
};
Map<String, dynamic> _prefix5GitHubButton(prefix5.GitHubButton c) => {
  'repo': c.repo,
};
