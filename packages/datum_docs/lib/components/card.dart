import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

/// A card component for highlighting features, examples, or important content.
///
/// Usage in markdown:
/// <Card title="Feature Title">
/// Content goes here
/// </Card>
class Card extends CustomComponentBase {
  Card();

  @override
  final Pattern pattern = 'Card';

  @override
  Component apply(String name, Map<String, String> attributes, Component? child) {
    final title = attributes['title'];
    return _CardComponent(title: title, child: child);
  }

  @css
  static List<StyleRule> get styles => [
    css('.card', [
      css('&').styles(
        padding: Padding.all(1.5.rem),
        margin: Margin.only(bottom: 1.5.rem),
        border: Border.all(width: 1.px, color: Color('hsl(var(--border))')),
        radius: BorderRadius.circular(0.75.rem),
        backgroundColor: Color('hsl(var(--card))'),
        raw: {
          'position': 'relative',
          'transition': 'all 0.3s ease-in-out',
          'box-shadow': '0 1px 3px hsl(var(--foreground) / 0.1), 0 1px 2px hsl(var(--foreground) / 0.06)',
          'background': 'linear-gradient(135deg, hsl(var(--card)) 0%, hsl(var(--card) / 0.95) 100%)',
        },
      ),
      css('&:hover').styles(
        raw: {
          'transform': 'translateY(-2px)',
          'box-shadow': '0 8px 25px hsl(var(--foreground) / 0.15), 0 4px 12px hsl(var(--foreground) / 0.1)',
        },
      ),
      css('&::before').styles(
        raw: {
          'content': '""',
          'position': 'absolute',
          'top': '0',
          'left': '0',
          'right': '0',
          'height': '3px',
          'background': 'linear-gradient(90deg, hsl(var(--primary)), hsl(var(--primary) / 0.8))',
          'border-radius': '0.75rem 0.75rem 0 0',
        },
      ),
      css('& > .card-title').styles(
        margin: Margin.only(bottom: 0.75.rem),
        color: Color('hsl(var(--foreground))'),
        fontSize: 1.125.rem,
        fontWeight: FontWeight.w600,
        raw: {
          'background': 'linear-gradient(135deg, hsl(var(--foreground)), hsl(var(--foreground) / 0.9))',
          '-webkit-background-clip': 'text',
          '-webkit-text-fill-color': 'transparent',
          'background-clip': 'text',
        },
      ),
      css('& > .card-content').styles(
        color: Color('hsl(var(--foreground))'),
        raw: {'line-height': '1.7'},
      ),
      css('& > .card-content p').styles(
        margin: Margin.only(bottom: 1.rem),
      ),
      css('& > .card-content p:last-child').styles(
        margin: Margin.only(bottom: Unit.zero),
      ),
      css('& > .card-content pre').styles(
        padding: Padding.all(1.rem),
        margin: Margin.symmetric(vertical: 1.rem),
        border: Border.all(width: 1.px, color: Color('hsl(var(--border))')),
        radius: BorderRadius.circular(0.5.rem),
        backgroundColor: Color('hsl(var(--muted))'),
        raw: {'overflow': 'auto', 'box-shadow': 'inset 0 1px 3px hsl(var(--foreground) / 0.1)'},
      ),
      css('& > .card-content code').styles(
        padding: Padding.symmetric(horizontal: 0.375.rem, vertical: 0.125.rem),
        radius: BorderRadius.circular(0.375.rem),
        color: Color('hsl(var(--foreground))'),
        fontSize: 0.875.em,
        backgroundColor: Color('hsl(var(--muted))'),
        raw: {'font-family': 'var(--font-mono)'},
      ),
      css('& > .card-content ul, & > .card-content ol').styles(
        padding: Padding.only(left: 1.5.rem),
        margin: Margin.symmetric(vertical: 0.5.rem),
      ),
      css('& > .card-content li').styles(
        margin: Margin.only(bottom: 0.25.rem),
      ),
      css('& > .card-content li:last-child').styles(
        margin: Margin.only(bottom: Unit.zero),
      ),
    ]),
  ];
}

class _CardComponent extends StatelessComponent {
  const _CardComponent({this.title, required this.child});

  final String? title;
  final Component? child;

  @override
  Component build(BuildContext context) {
    return div(classes: 'card', [
      if (title != null) div(classes: 'card-title', [Component.text(title!)]),
      if (child != null) div(classes: 'card-content', [child!]),
    ]);
  }
}
