import 'package:auto_route/auto_route.dart';
import 'package:example/core/router/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example/features/simple_datum/view/sync_dashboard_widget.dart';
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
              width: 220,
              height: 65,
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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.explore, size: 26),
                    SizedBox(width: 8),
                    Text(
                      'Test Features',
                      style: TextStyle(
                        fontSize: 18,
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
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Welcome to Datum Test App',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Test the latest features with real-time sync',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // Animated Test Features Button
                  const AnimatedTestFeaturesButton(),
                  const SizedBox(height: 40),
                  // Sync Dashboard Section
                  if (userId != null) ...[
                    const Text(
                      'Sync Dashboard',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Comprehensive Sync Dashboard
                    SyncDashboardWidget(userId: userId),
                    const SizedBox(height: 40),
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
