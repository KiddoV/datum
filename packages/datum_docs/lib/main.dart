// The entrypoint for the **server** environment.
//
// The [main] method will only be executed on the server during pre-rendering.
// To run code on the client, use the @client annotation.

// Server-specific jaspr import.
import 'package:datum_docs/components/cached_github_button.dart';
import 'package:datum_docs/components/custom_header.dart';
import 'package:datum_docs/components/custom_image.dart';
import 'package:datum_docs/components/enhanced_theme_toggle.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_content/components/callout.dart';
import 'package:jaspr_content/components/sidebar.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';

// This file is generated automatically by Jaspr, do not remove or edit.
import 'jaspr_options.dart';

import 'components/code_block.dart';

void main() {
  // Initializes the server environment with the generated default options.
  Jaspr.initializeApp(
    options: defaultJasprOptions,
  );

  // Starts the app.
  //
  // [ContentApp] spins up the content rendering pipeline from jaspr_content to render
  // your markdown files in the content/ directory to a beautiful documentation site.
  runApp(
    ContentApp(
      // Enables mustache templating inside the markdown files.
      templateEngine: MustacheTemplateEngine(),

      debugPrint: true,
      parsers: [
        MarkdownParser(),
        HtmlParser(),
      ],
      extensions: [
        // Adds heading anchors to each heading.
        HeadingAnchorsExtension(),
        // Generates a table of contents for each page.
        TableOfContentsExtension(),
      ],
      components: [
        // The <Info> block and other callouts.
        Callout(),
        // Adds syntax highlighting to code blocks.
        CodeBlock(
          defaultLanguage: 'dart',
          grammars: {},
        ),
        // Adds a custom Jaspr component to be used as <Clicker/> in markdown.
        // CustomComponent(
        //   pattern: 'Clicker',
        //   builder: (_, __, ___) => Clicker(),
        // ),
        // Adds zooming and caption support to images.
        CustomImage(zoom: false),
      ],

      layouts: [
        // Out-of-the-box layout for documentation sites.
        DocsLayout(
          header: CustomHeader(
            title: 'Datum',
            subtitle: "Data, Seamlessly Synced",
            logo: '/images/logo.webp',
            items: [
              // Link back to the main marketing site.
              a(
                href: '/',
                target: Target.self,
                styles: Styles.combine([
                  Styles(
                    display: Display.flex,
                    alignItems: AlignItems.center,
                  ),
                  Styles(
                    fontSize: 0.875.rem,
                    fontWeight: FontWeight.w500,
                    textDecoration: TextDecoration.none,
                  ),
                  Styles(
                    padding: Spacing.symmetric(vertical: 0.5.rem, horizontal: 0.75.rem),
                    radius: BorderRadius.all(Radius.circular(6.px)),
                  ),
                ]),
                [
                  HomeIcon(size: 16),
                ],
              ),
              // Enables switching between light and dark mode.
              EnhancedThemeToggle(),
              // Shows github stats.
              CachedGitHubButton(
                repo: 'shreemanarjun/datum',
              ),
            ],
          ),
          sidebar: Sidebar(
            groups: [
              // Adds navigation links to the sidebar.
              SidebarGroup(
                links: [
                  SidebarLink(text: "Overview", href: '/'),
                ],
              ),
              SidebarGroup(
                title: 'Getting Started',
                links: [
                  SidebarLink(text: "Quick Start / Installation", href: '/getting_started/quick_start'),
                  SidebarLink(text: "About", href: '/about'),
                  SidebarLink(text: "Costs and Licensing", href: '/costs_licensing'),
                ],
              ),
              SidebarGroup(
                title: 'Guides',
                links: [
                  SidebarLink(text: "Define Your Entity", href: '/guides/entity_define'),
                  SidebarLink(text: "Initialization & Global API", href: '/guides/initialization'),
                  SidebarLink(text: "Working with Relationships", href: '/guides/relationships'),
                  SidebarLink(text: "Querying Data", href: '/guides/querying'),
                  SidebarLink(text: "Define Your Local Adapter", href: '/guides/local_adapter_implement'),
                  SidebarLink(text: "Define Your Remote Adapter", href: '/guides/remote_adapter_implement'),
                ],
              ),
              SidebarGroup(
                title: 'Custom Adapters',
                links: [
                  SidebarLink(text: "Hive Local Adapter", href: '/guides/custom_adapters/hive_adapter'),
                  SidebarLink(text: "Isar Local Adapter", href: '/guides/custom_adapters/isar_adapter'),
                  SidebarLink(text: "REST API Remote Adapter", href: '/guides/custom_adapters/rest_api_adapter'),
                  SidebarLink(text: "Firebase Remote Adapter", href: '/guides/custom_adapters/firebase_adapter'),
                  SidebarLink(text: "Supabase Remote Adapter", href: '/guides/custom_adapters/supabase_adapter'),
                ],
              ),

              SidebarGroup(
                title: 'Modules',
                links: [
                  SidebarLink(text: "Core", href: '/modules/core'),
                  SidebarLink(text: "Query", href: '/modules/query'),
                  SidebarLink(text: "Migration", href: '/modules/migration'),
                  SidebarLink(text: "Health", href: '/modules/health'),
                  SidebarLink(text: "Observers & Middleware", href: '/modules/observers'),
                  SidebarLink(text: "Adapter", href: '/modules/adapter'),
                  SidebarLink(text: "Configuration", href: '/modules/config'),
                  SidebarLink(text: "Utils", href: '/modules/utils'),
                ],
              ),
            ],
          ),
          footer: Builder(
            builder: (context) {
              return div(
                styles: Styles(
                  position: Position.fixed(bottom: 0.px, left: 24.px, right: 0.px),
                  padding: Spacing.only(left: 8.px, bottom: 24.px),
                  backgroundColor: Color('hsl(var(--background))'),
                  raw: {
                    'transition': 'all 0.3s ease-in-out',
                    //'box-shadow': '0 -2px 10px rgba(0, 0, 0, 0.08)',
                  },
                ),
                [
                  JasprBadge.lightTwoTone(),
                ],
              );
            },
          ),
        ),
      ],

      theme: ContentTheme(
        // Customizes the default theme colors.
        primary: ThemeColor(ThemeColors.blue.$500, dark: ThemeColors.blue.$300),
        background: ThemeColor(ThemeColors.slate.$50, dark: ThemeColors.zinc.$950),
        colors: [
          ContentColors.quoteBorders.apply(ThemeColors.blue.$400),
          ContentColors.preBg.apply(ThemeColor(ThemeColors.slate.$800, dark: ThemeColors.slate.$800)),
        ],
      ),
    ),
  );
}
