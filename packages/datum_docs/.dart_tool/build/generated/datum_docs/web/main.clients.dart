// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/browser.dart';
import 'package:jaspr_content/components/_internal/code_block_copy_button.client.dart'
    deferred as prefix0;
import 'package:jaspr_content/components/_internal/zoomable_image.client.dart'
    deferred as prefix1;
import 'package:jaspr_content/components/github_button.client.dart'
    deferred as prefix2;
import 'package:jaspr_content/components/sidebar_toggle_button.client.dart'
    deferred as prefix3;
import 'package:jaspr_content/components/theme_toggle.client.dart'
    deferred as prefix4;

void main() {
  registerClients({
    'jaspr_content:components/_internal/code_block_copy_button': loadClient(
      prefix0.loadLibrary,
      (p) => prefix0.getComponentForParams(p),
    ),

    'jaspr_content:components/_internal/zoomable_image': loadClient(
      prefix1.loadLibrary,
      (p) => prefix1.getComponentForParams(p),
    ),

    'jaspr_content:components/github_button': loadClient(
      prefix2.loadLibrary,
      (p) => prefix2.getComponentForParams(p),
    ),

    'jaspr_content:components/theme_toggle': loadClient(
      prefix4.loadLibrary,
      (p) => prefix4.getComponentForParams(p),
    ),

    'jaspr_content:components/sidebar_toggle_button': loadClient(
      prefix3.loadLibrary,
      (p) => prefix3.getComponentForParams(p),
    ),
  });
}
