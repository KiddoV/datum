import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

/// Component that displays breadcrumb navigation
class Breadcrumb extends StatelessComponent {
  const Breadcrumb({super.key});

  @override
  Component build(BuildContext context) {
    final page = context.page;
    final breadcrumbs = page.data['breadcrumbs'] as List<Map<String, String>>?;

    if (breadcrumbs == null || breadcrumbs.isEmpty) {
      return Component.fragment([]);
    }

    return div(
      styles: Styles(
        margin: Margin.only(bottom: 2.rem),
        color: Color('#6b7280'),
        fontSize: 0.875.rem,
      ),
      [
        // Breadcrumb navigation
        nav(
          attributes: {'aria-label': 'Breadcrumb'},
          [
            ol(
              styles: Styles(
                display: Display.flex,
                padding: Padding.zero,
                margin: Margin.zero,
                flexWrap: FlexWrap.wrap,
                gap: Gap.all(0.5.rem),
                listStyle: ListStyle.none,
              ),
              [
                for (int i = 0; i < breadcrumbs.length; i++) ...[
                  li([
                    if (i < breadcrumbs.length - 1) ...[
                      // Link for non-current pages
                      a(
                        href: breadcrumbs[i]['url']!,
                        styles: Styles(
                          color: Color('#6b7280'),
                        ),
                        [Component.text(breadcrumbs[i]['title']!)],
                      ),
                    ] else ...[
                      // Current page (not a link)
                      span(
                        styles: Styles(
                          color: Color('#374151'),
                          fontWeight: FontWeight.w500,
                        ),
                        [Component.text(breadcrumbs[i]['title']!)],
                      ),
                    ],
                  ]),
                  if (i < breadcrumbs.length - 1) ...[
                    // Separator
                    li(
                      styles: Styles(
                        margin: Margin.symmetric(horizontal: 0.25.rem),
                        color: Color('#9ca3af'),
                      ),
                      [Component.text('/')],
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }
}
