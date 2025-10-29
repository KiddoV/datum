// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/browser.dart';
import 'package:jaspr_content/components/_internal/tab_bar.dart' as prefix0;

Component getComponentForParams(Map<String, dynamic> p) {
  return prefix0.TabBar(
      initialValue: p['initialValue'], items: (p['items'] as Map<String, dynamic>).cast<String, String>());
}
