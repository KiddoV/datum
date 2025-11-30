import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/components/sidebar_toggle_button.dart';
import 'package:datum_docs/components/enhanced_theme_toggle.dart';

/// A header component with a logo, title, and additional items.
class CustomHeader extends StatelessComponent {
  const CustomHeader({
    required this.logo,
    required this.title,
    this.subtitle,
    this.version = '1.0.2',
    this.leading = const [SidebarToggleButton()],
    this.items = const [],
    super.key,
  });

  /// The src href to render as the site logo.
  final String logo;

  /// The name of the site to render alongside the [logo].
  final String title;

  /// An optional subtitle to render below the [title].
  final String? subtitle;

  /// The current version of the package.
  final String version;

  /// Components to render before the site logo and title.
  ///
  /// If not specified, defaults to a [SidebarToggleButton].
  final List<Component> leading;

  /// Other components to render in the header, such as site section links.
  final List<Component> items;

  @override
  Component build(BuildContext context) {
    return fragment([
      Document.head(
        children: [
          Style(styles: _styles),
          Style(
            styles: [
              css('body').styles(
                padding: Padding.only(bottom: 80.px),
              ),
            ],
          ),
          ThemeScript(),
        ],
      ),
      header(classes: 'header', [
        ...leading,
        a(classes: 'header-title', href: '/', [
          img(src: logo, alt: '$title Logo'),
          div(classes: 'header-title-text', [
            div(classes: 'header-title-row', [
              span(classes: 'header-main-title', [text(title)]),
              span(classes: 'header-version', [text('v$version')]),
            ]),
            if (subtitle != null)
              span(classes: 'header-subtitle', [
                text(subtitle!),
              ]),
          ]),
        ]),
        div(classes: 'header-items', items),
      ]),
    ]);
  }

  static List<StyleRule> get _styles => [
    css('.header', [
      css('&').styles(
        display: Display.flex,
        height: 4.rem,
        maxWidth: 90.rem,
        padding: Padding.symmetric(horizontal: 1.rem, vertical: .25.rem),
        margin: Margin.symmetric(horizontal: Unit.auto),
        border: Border.only(
          bottom: BorderSide(color: Color('#0000000d'), width: 1.px),
        ),
        alignItems: AlignItems.center,
        gap: Gap(column: 1.rem),
        raw: {'backdrop-filter': 'none', 'background-color': 'var(--background) !important'},
      ),
      css('.header-title', [
        css('&').styles(
          display: Display.inlineFlex,
          alignItems: AlignItems.center,
          gap: Gap(column: .75.rem),
          flex: Flex(grow: 1),
          textDecoration: TextDecoration.none,
          raw: {'position': 'relative'},
        ),
        css('img').styles(
          width: Unit.auto,
          height: 3.rem,
        ),
        css('.header-title-text').styles(
          display: Display.flex,
          flexDirection: FlexDirection.column,
          justifyContent: JustifyContent.center,
          fontWeight: FontWeight.bold,
        ),
        css('.header-title-row').styles(
          display: Display.flex,
          alignItems: AlignItems.center,
          gap: Gap(column: 0.5.rem),
        ),
        css('.header-main-title').styles(fontWeight: FontWeight.w700),
        css('.header-version').styles(
          padding: Padding.symmetric(horizontal: 0.375.rem, vertical: 0.125.rem),
          radius: BorderRadius.all(Radius.circular(0.25.rem)),
          color: Color('hsl(var(--foreground) / 0.7)'),
          fontSize: 0.75.rem,
          fontWeight: FontWeight.w500,
          backgroundColor: Color('hsl(var(--muted))'),
        ),
        css('.header-subtitle').styles(
          fontSize: 0.75.rem,
          fontWeight: FontWeight.w400,
        ),
        css('span').styles(fontWeight: FontWeight.w700),
      ]),
      css('.header-items', [
        css('&').styles(
          display: Display.flex,
          gap: Gap(column: 0.0625.rem),
        ),
      ]),
    ]),
    css.media(MediaQuery.all(minWidth: 768.px), [
      css('.header').styles(padding: Padding.symmetric(horizontal: 2.5.rem)),
    ]),
    // Responsive design for mobile
    css.media(MediaQuery.all(maxWidth: 640.px), [
      css('.header', [
        css('&').styles(
          height: 3.5.rem,
          padding: Padding.symmetric(horizontal: 0.75.rem, vertical: 0.2.rem),
          gap: Gap(column: 0.5.rem),
        ),
        css('.header-title', [
          css('&').styles(
            gap: Gap(column: 0.5.rem),
          ),
          css('img').styles(
            height: 2.5.rem,
          ),
          css('.header-version').styles(
            padding: Padding.symmetric(horizontal: 0.25.rem, vertical: 0.0625.rem),
            fontSize: 0.625.rem,
          ),
          css('.header-subtitle').styles(
            raw: {'display': 'none !important'},
          ),
        ]),
        css('.header-items', [
          css('&').styles(
            gap: Gap(column: 0.125.rem),
          ),
          // Home icon responsive sizing
          css('a svg').styles(
            width: 14.px,
            height: 14.px,
          ),
        ]),
      ]),
    ]),
  ];
}
