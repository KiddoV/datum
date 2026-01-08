import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example/features/counter/controller/counter_state_pod.dart';
import 'package:example/features/theme_segmented_btn/view/theme_segmented_btn.dart';
import 'package:example/shared/widget/app_locale_popup.dart';
import 'package:example/shared/pods/translation_pod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

@RoutePage(deferredLoading: true)
class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CounterView();
  }
}

class CounterView extends ConsumerWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final count = ref.watch(counterPod);
    final t = ref.watch(translationsPod);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(t.counterAppBarTitle, style: theme.textTheme.h4),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        actions: const [
          AppLocalePopUp(),
          SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShadCard(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Text(
                    'Count',
                    style: theme.textTheme.muted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$count',
                    style: theme.textTheme.h1.copyWith(
                      fontSize: 80,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShadButton.outline(
                  onPressed: () => ref.read(counterPod.notifier).decrement(),
                  width: 56,
                  height: 56,
                  child: const Icon(Icons.remove, size: 24),
                ),
                const SizedBox(width: 24),
                ShadButton(
                  onPressed: () => ref.read(counterPod.notifier).increment(),
                  width: 56,
                  height: 56,
                  child: const Icon(Icons.add, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 48),
            const ThemeSegmentedBtn(),
          ],
        ),
      ),
    );
  }
}
