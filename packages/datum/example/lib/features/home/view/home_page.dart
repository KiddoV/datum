import 'package:auto_route/auto_route.dart';
import 'package:example/core/router/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example/features/simple_datum/view/sync_dashboard_widget.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Animated test features button with entrance and interaction animations
class AnimatedTestFeaturesButton extends StatefulWidget {
  const AnimatedTestFeaturesButton({super.key});

  @override
  State<AnimatedTestFeaturesButton> createState() =>
      _AnimatedTestFeaturesButtonState();
}

class _AnimatedTestFeaturesButtonState extends State<AnimatedTestFeaturesButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Start the entrance animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: SizedBox(
              width: ResponsiveValue<double>(
                context,
                conditionalValues: [
                  const Condition.equals(name: MOBILE, value: 200),
                  const Condition.equals(name: TABLET, value: 240),
                  const Condition.equals(name: DESKTOP, value: 280),
                  const Condition.equals(name: '4K', value: 320),
                ],
                defaultValue: 220,
              ).value,
              height: ResponsiveValue<double>(
                context,
                conditionalValues: [
                  const Condition.equals(name: MOBILE, value: 55),
                  const Condition.equals(name: TABLET, value: 65),
                  const Condition.equals(name: DESKTOP, value: 75),
                  const Condition.equals(name: '4K', value: 85),
                ],
                defaultValue: 65,
              ).value,
              child: ElevatedButton(
                onPressed: () {
                  // Add press animation
                  _animationController.reverse().then((_) {
                    AutoRouter.of(context).push(const FeatureSelectionRoute());
                    _animationController.forward();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: Colors.blue.withValues(alpha: 0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.explore,
                      size: ResponsiveValue<double>(
                        context,
                        conditionalValues: [
                          const Condition.equals(name: MOBILE, value: 20),
                          const Condition.equals(name: TABLET, value: 24),
                          const Condition.equals(name: DESKTOP, value: 28),
                          const Condition.equals(name: '4K', value: 32),
                        ],
                        defaultValue: 26,
                      ).value,
                    ),
                    SizedBox(
                      width: ResponsiveValue<double>(
                        context,
                        conditionalValues: [
                          const Condition.equals(name: MOBILE, value: 6),
                          const Condition.equals(name: TABLET, value: 8),
                          const Condition.equals(name: DESKTOP, value: 10),
                          const Condition.equals(name: '4K', value: 12),
                        ],
                        defaultValue: 8,
                      ).value,
                    ),
                    Text(
                      'Test Features',
                      style: TextStyle(
                        fontSize: ResponsiveValue<double>(
                          context,
                          conditionalValues: [
                            const Condition.equals(name: MOBILE, value: 14),
                            const Condition.equals(name: TABLET, value: 16),
                            const Condition.equals(name: DESKTOP, value: 20),
                            const Condition.equals(name: '4K', value: 24),
                          ],
                          defaultValue: 18,
                        ).value,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

@RoutePage()
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home Page'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              ResponsiveValue<double>(
                context,
                conditionalValues: [
                  const Condition.equals(name: MOBILE, value: 12),
                  const Condition.equals(name: TABLET, value: 16),
                  const Condition.equals(name: DESKTOP, value: 24),
                  const Condition.equals(name: '4K', value: 32),
                ],
                defaultValue: 16,
              ).value,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome to Datum Test App',
                    style: TextStyle(
                      fontSize: ResponsiveValue<double>(
                        context,
                        conditionalValues: [
                          const Condition.equals(name: MOBILE, value: 24),
                          const Condition.equals(name: TABLET, value: 28),
                          const Condition.equals(name: DESKTOP, value: 36),
                          const Condition.equals(name: '4K', value: 48),
                        ],
                        defaultValue: 28,
                      ).value,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveValue<double>(
                      context,
                      conditionalValues: [
                        const Condition.equals(name: MOBILE, value: 16),
                        const Condition.equals(name: TABLET, value: 20),
                        const Condition.equals(name: DESKTOP, value: 24),
                        const Condition.equals(name: '4K', value: 32),
                      ],
                      defaultValue: 20,
                    ).value,
                  ),
                  Text(
                    'Test the latest features with real-time sync',
                    style: TextStyle(
                      fontSize: ResponsiveValue<double>(
                        context,
                        conditionalValues: [
                          const Condition.equals(name: MOBILE, value: 14),
                          const Condition.equals(name: TABLET, value: 16),
                          const Condition.equals(name: DESKTOP, value: 18),
                          const Condition.equals(name: '4K', value: 22),
                        ],
                        defaultValue: 16,
                      ).value,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: ResponsiveValue<double>(
                      context,
                      conditionalValues: [
                        const Condition.equals(name: MOBILE, value: 32),
                        const Condition.equals(name: TABLET, value: 40),
                        const Condition.equals(name: DESKTOP, value: 48),
                        const Condition.equals(name: '4K', value: 64),
                      ],
                      defaultValue: 40,
                    ).value,
                  ),
                  // Animated Test Features Button
                  const AnimatedTestFeaturesButton(),
                  SizedBox(
                    height: ResponsiveValue<double>(
                      context,
                      conditionalValues: [
                        const Condition.equals(name: MOBILE, value: 32),
                        const Condition.equals(name: TABLET, value: 40),
                        const Condition.equals(name: DESKTOP, value: 48),
                        const Condition.equals(name: '4K', value: 64),
                      ],
                      defaultValue: 40,
                    ).value,
                  ),
                  // Sync Dashboard Section
                  if (userId != null) ...[
                    Text(
                      'Sync Dashboard',
                      style: TextStyle(
                        fontSize: ResponsiveValue<double>(
                          context,
                          conditionalValues: [
                            const Condition.equals(name: MOBILE, value: 16),
                            const Condition.equals(name: TABLET, value: 18),
                            const Condition.equals(name: DESKTOP, value: 22),
                            const Condition.equals(name: '4K', value: 28),
                          ],
                          defaultValue: 18,
                        ).value,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveValue<double>(
                        context,
                        conditionalValues: [
                          const Condition.equals(name: MOBILE, value: 12),
                          const Condition.equals(name: TABLET, value: 16),
                          const Condition.equals(name: DESKTOP, value: 20),
                          const Condition.equals(name: '4K', value: 24),
                        ],
                        defaultValue: 16,
                      ).value,
                    ),
                    // Comprehensive Sync Dashboard
                    SyncDashboardWidget(userId: userId),
                    SizedBox(
                      height: ResponsiveValue<double>(
                        context,
                        conditionalValues: [
                          const Condition.equals(name: MOBILE, value: 32),
                          const Condition.equals(name: TABLET, value: 40),
                          const Condition.equals(name: DESKTOP, value: 48),
                          const Condition.equals(name: '4K', value: 64),
                        ],
                        defaultValue: 40,
                      ).value,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
