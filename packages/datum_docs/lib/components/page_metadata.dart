import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

/// Component that displays page metadata including reading time and SEO information
class PageMetadata extends StatelessComponent {
  const PageMetadata({super.key});

  @override
  Component build(BuildContext context) {
    final page = context.page;

    // Access reading time data
    final readingTime = page.data['readingTime'] as String?;

    // Access last modified data
    final lastModified = page.data['lastModified'] as String?;

    // Access SEO data
    final seoData = page.data['seo'] as Map<String, dynamic>?;
    final _ = seoData?['title'] as String?;
    final _ = seoData?['description'] as String?;
    final _ = seoData?['structuredData'] as Map<String, dynamic>?;

    return Component.fragment([
      // Display reading time if available
      if (readingTime != null)
        div(
          styles: Styles(
            padding: Spacing.symmetric(vertical: 1.rem, horizontal: 0.rem),
            color: Color('#6b7280'),
            fontSize: 0.875.rem, // gray-500
            fontStyle: FontStyle.italic,
          ),
          [
            Component.text('📖 $readingTime'),
          ],
        ),

      // Display last modified date if available
      if (lastModified != null)
        div(
          styles: Styles(
            padding: Spacing.symmetric(vertical: 0.5.rem, horizontal: 0.rem),
            color: Color('#9ca3af'), // gray-400
            fontSize: 0.75.rem,
            fontStyle: FontStyle.italic,
          ),
          [
            Component.text('📅 Last updated $lastModified'),
          ],
        ),
    ]);
  }
}
