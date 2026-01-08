import 'package:flutter/material.dart';

class AnimatedCountdownWidget extends StatefulWidget {
  final Duration? duration;
  final TextStyle? style;

  const AnimatedCountdownWidget({
    super.key,
    required this.duration,
    this.style,
  });

  @override
  State<AnimatedCountdownWidget> createState() =>
      _AnimatedCountdownWidgetState();
}

class _AnimatedCountdownWidgetState extends State<AnimatedCountdownWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _colorController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey[600],
      end: Colors.blue[600],
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(AnimatedCountdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger animation when duration changes (every second)
    if (widget.duration != oldWidget.duration && widget.duration != null) {
      _scaleController.forward().then((_) => _scaleController.reverse());

      // Change color based on remaining time
      final minutes = widget.duration!.inMinutes;
      if (minutes <= 1) {
        // Red for less than 1 minute
        _colorAnimation = ColorTween(
          begin: _colorAnimation.value,
          end: Colors.red[600],
        ).animate(CurvedAnimation(
          parent: _colorController,
          curve: Curves.easeInOut,
        ));
      } else if (minutes <= 5) {
        // Orange for less than 5 minutes
        _colorAnimation = ColorTween(
          begin: _colorAnimation.value,
          end: Colors.orange[600],
        ).animate(CurvedAnimation(
          parent: _colorController,
          curve: Curves.easeInOut,
        ));
      } else {
        // Blue for more than 5 minutes
        _colorAnimation = ColorTween(
          begin: _colorAnimation.value,
          end: Colors.blue[600],
        ).animate(CurvedAnimation(
          parent: _colorController,
          curve: Curves.easeInOut,
        ));
      }
      _colorController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.duration == null) {
      return Text(
        'Not scheduled',
        style: widget.style ?? Theme.of(context).textTheme.bodyMedium,
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _colorAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Text(
            _formatDuration(widget.duration!),
            style: (widget.style ?? Theme.of(context).textTheme.bodyMedium)
                ?.copyWith(
              color: _colorAnimation.value,
              fontWeight: FontWeight.w600,
              fontFeatures: [
                const FontFeature.tabularFigures()
              ], // Monospace numbers
            ),
          ),
        );
      },
    );
  }
}
