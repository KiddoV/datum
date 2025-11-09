import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

/// A comparison table component for displaying feature comparisons.
///
/// Usage in markdown:
/// <ComparisonTable>
///   <TableHeader>Feature|Approach1|Approach2|Approach3</TableHeader>
///   <TableRow>Use Case|Value1|Value2|Value3</TableRow>
///   <TableRow>Complexity|Low|High|Medium</TableRow>
/// </ComparisonTable>
class ComparisonTable extends CustomComponentBase {
  ComparisonTable();

  @override
  final Pattern pattern = RegExp(r'ComparisonTable|TableHeader|TableRow');

  @override
  Component apply(String name, Map<String, String> attributes, Component? child) {
    switch (name) {
      case 'ComparisonTable':
        return _ComparisonTableComponent(child: child);
      case 'TableHeader':
        return _TableHeaderComponent(child: child);
      case 'TableRow':
        return _TableRowComponent(child: child);
      default:
        return text('');
    }
  }

  @css
  static List<StyleRule> get styles => [
    css('.comparison-table', [
      css('&').styles(
        width: 100.percent,
        margin: Margin.only(bottom: 1.5.rem),
        border: Border(width: 1.px, color: Color('hsl(var(--border))')),
        radius: BorderRadius.circular(0.75.rem),
        backgroundColor: Color('hsl(var(--card))'),
        raw: {
          'overflow': 'hidden',
          'box-shadow': '0 4px 6px hsl(var(--foreground) / 0.07), 0 1px 3px hsl(var(--foreground) / 0.1)',
        },
      ),
      css('& table').styles(
        width: 100.percent,
        raw: {'border-collapse': 'collapse'},
      ),
      css('& thead').styles(
        backgroundColor: Color('hsl(var(--muted))'),
      ),
      css('& th').styles(
        padding: Padding.symmetric(vertical: 1.rem, horizontal: 1.25.rem),
        border: Border(width: 1.px, color: Color('hsl(var(--border))')),
        color: Color('hsl(var(--foreground))'),
        textAlign: TextAlign.left,
        fontSize: 0.875.rem,
        fontWeight: FontWeight.w600,
        raw: {'text-transform': 'uppercase', 'letter-spacing': '0.05em'},
      ),
      css('& td').styles(
        padding: Padding.symmetric(vertical: 1.rem, horizontal: 1.25.rem),
        border: Border(width: 1.px, color: Color('hsl(var(--border))')),
        color: Color('hsl(var(--foreground))'),
        raw: {'line-height': '1.5'},
      ),
      css('& tbody tr').styles(
        raw: {
          'transition': 'background-color 0.2s ease',
        },
      ),
      css('& tbody tr:nth-child(even)').styles(
        backgroundColor: Color('hsl(var(--muted) / 0.3)'),
      ),
      css('& tbody tr:hover').styles(
        backgroundColor: Color('hsl(var(--accent) / 0.5)'),
      ),
      // Status badges
      css('& .status-success').styles(
        display: Display.inlineBlock,
        padding: Padding.symmetric(horizontal: 0.5.rem, vertical: 0.25.rem),
        border: Border(width: 1.px, color: Color('hsl(142 76% 36% / 0.2)')),
        radius: BorderRadius.circular(9999.px),
        color: Color('hsl(142 76% 36%)'),
        fontSize: 0.75.rem,
        fontWeight: FontWeight.w600,
        backgroundColor: Color('hsl(142 76% 36% / 0.1)'),
      ),
      css('& .status-warning').styles(
        display: Display.inlineBlock,
        padding: Padding.symmetric(horizontal: 0.5.rem, vertical: 0.25.rem),
        border: Border(width: 1.px, color: Color('hsl(38 92% 50% / 0.2)')),
        radius: BorderRadius.circular(9999.px),
        color: Color('hsl(38 92% 50%)'),
        fontSize: 0.75.rem,
        fontWeight: FontWeight.w600,
        backgroundColor: Color('hsl(38 92% 50% / 0.1)'),
      ),
      css('& .status-info').styles(
        display: Display.inlineBlock,
        padding: Padding.symmetric(horizontal: 0.5.rem, vertical: 0.25.rem),
        border: Border(width: 1.px, color: Color('hsl(199 89% 48% / 0.2)')),
        radius: BorderRadius.circular(9999.px),
        color: Color('hsl(199 89% 48%)'),
        fontSize: 0.75.rem,
        fontWeight: FontWeight.w600,
        backgroundColor: Color('hsl(199 89% 48% / 0.1)'),
      ),
      // Icons and symbols
      css('& .icon-check').styles(
        color: Color('hsl(142 76% 36%)'),
        fontWeight: FontWeight.w600,
      ),
      css('& .icon-cross').styles(
        color: Color('hsl(0 84% 60%)'),
        fontWeight: FontWeight.w600,
      ),
      css('& .icon-manual').styles(
        color: Color('hsl(38 92% 50%)'),
        fontWeight: FontWeight.w600,
      ),
      css('& .icon-dot').styles(
        color: Color('hsl(var(--muted-foreground))'),
      ),
      css('& .icon-circle').styles(
        color: Color('hsl(var(--muted-foreground))'),
      ),
      css('& .icon-green').styles(
        color: Color('hsl(142 76% 36%)'),
      ),
      css('& .icon-yellow').styles(
        color: Color('hsl(38 92% 50%)'),
      ),
      css('& .icon-blue').styles(
        color: Color('hsl(199 89% 48%)'),
      ),
    ]),
  ];
}

class _ComparisonTableComponent extends StatelessComponent {
  const _ComparisonTableComponent({required this.child});

  final Component? child;

  @override
  Component build(BuildContext context) {
    return div(classes: 'comparison-table', [
      table([child ?? text('')]),
    ]);
  }
}

class _TableHeaderComponent extends StatelessComponent {
  const _TableHeaderComponent({required this.child});

  final Component? child;

  @override
  Component build(BuildContext context) {
    if (child is Text) {
      final textChild = child as Text;
      final columns = textChild.text.split('|');
      return thead([
        tr(columns.map((col) => th([text(col.trim())])).toList()),
      ]);
    }
    return thead([
      tr([
        th([child ?? text('')]),
      ]),
    ]);
  }
}

class _TableRowComponent extends StatelessComponent {
  const _TableRowComponent({required this.child});

  final Component? child;

  @override
  Component build(BuildContext context) {
    if (child is Text) {
      final textChild = child as Text;
      final columns = textChild.text.split('|');
      return tr(columns.map((col) => td([_parseCellContent(col.trim())])).toList());
    }
    return tr([
      td([child ?? text('')]),
    ]);
  }

  Component _parseCellContent(String content) {
    // Handle special status badges
    if (content.contains('<Badge variant="success">')) {
      final match = RegExp(r'<Badge variant="success">(.*?)</Badge>').firstMatch(content);
      if (match != null) {
        return span(classes: 'status-success', [text(match.group(1)!)]);
      }
    }
    if (content.contains('<Badge variant="warning">')) {
      final match = RegExp(r'<Badge variant="warning">(.*?)</Badge>').firstMatch(content);
      if (match != null) {
        return span(classes: 'status-warning', [text(match.group(1)!)]);
      }
    }
    if (content.contains('<Badge variant="info">')) {
      final match = RegExp(r'<Badge variant="info">(.*?)</Badge>').firstMatch(content);
      if (match != null) {
        return span(classes: 'status-info', [text(match.group(1)!)]);
      }
    }

    // Handle icons and symbols
    if (content == '✅') return span(classes: 'icon-check', [text('✓')]);
    if (content == '❌') return span(classes: 'icon-cross', [text('✗')]);
    if (content == '🔧') return span(classes: 'icon-manual', [text('🔧')]);
    if (content == '⚪') return span(classes: 'icon-circle', [text('○')]);
    if (content == '🟡') return span(classes: 'icon-yellow', [text('●')]);
    if (content == '🟢') return span(classes: 'icon-green', [text('●')]);

    // Handle bold text
    if (content.startsWith('<b>') && content.endsWith('</b>')) {
      final textContent = content.substring(3, content.length - 4);
      return b([text(textContent)]);
    }

    return text(content);
  }
}
