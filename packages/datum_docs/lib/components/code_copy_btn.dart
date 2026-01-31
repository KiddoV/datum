import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_lucide/jaspr_lucide.dart' hide Timer, List;
import 'package:universal_web/web.dart' as web;

@client
class CodeBlockCopyButton extends StatefulComponent {
  const CodeBlockCopyButton({super.key});

  @override
  State<CodeBlockCopyButton> createState() => _CodeBlockCopyButtonState();
}

class _CodeBlockCopyButtonState extends State<CodeBlockCopyButton> {
  bool copied = false;

  void _showToast(String message) {
    print('🔥 _showToast called with: "$message"');

    // Create toast element using DOM API
    final toast = web.document.createElement('div') as web.HTMLElement;
    toast.style.cssText = '''
      position: fixed !important;
      top: 50px !important;
      left: 50% !important;
      transform: translateX(-50%) !important;
      background: #ff0000 !important;
      color: white !important;
      padding: 20px 30px !important;
      border-radius: 8px !important;
      font-size: 18px !important;
      font-weight: bold !important;
      font-family: Arial, sans-serif !important;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.8) !important;
      z-index: 999999 !important;
      border: 3px solid yellow !important;
      text-align: center !important;
      min-width: 250px !important;
      pointer-events: none !important;
    ''';

    toast.textContent = '🚨 ALERT: $message';
    print('📦 Created toast element with content: "${toast.textContent}"');

    // Add to body
    final body = web.document.body;
    if (body != null) {
      body.appendChild(toast);
      print('✅ Toast appended to body');

      // Force a reflow to ensure it's rendered
      final _ = toast.offsetHeight;

      // Remove after 5 seconds
      Timer(const Duration(seconds: 5), () {
        print('⏰ Removing toast after 5 seconds');
        if (toast.parentNode != null) {
          toast.remove();
          print('🗑️ Toast removed');
        }
      });
    } else {
      print('❌ Body not found');
    }
  }

  @override
  Component build(BuildContext context) {
    return button(
      events: {
        'click': (event) {
          print('Copy button clicked!');
          final target = event.currentTarget as web.Element;
          final codeBlock = target.parentElement?.parentElement;
          final content = codeBlock?.querySelector('pre code')?.textContent ?? '';
          print('Content found: "${content.trim()}"');
          if (content.trim().isEmpty) {
            print('No content found to copy');
            return;
          }
          web.window.navigator.clipboard.writeText(content.trim());
          print('Calling showToast');
          // Call the local showToast method
          _showToast('Code copied to clipboard!');
          setState(() {
            copied = true;
          });
          Timer(const Duration(seconds: 2), () {
            setState(() {
              copied = false;
            });
          });
        },
      },
      [
        copied
            ? Check(
                height: 18.px,
                styles: Styles(
                  color: Colors.white,
                ),
              )
            : Copy(
                height: 18.px,
                styles: Styles(
                  color: Colors.white,
                ),
              ),
      ],
    );
  }
}
