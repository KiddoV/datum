import 'dart:ui' as ui;
import 'package:example/bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:datum/datum.dart';
import 'package:example/data/paint/entity/paint_stroke.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================================
// PROVIDERS
// ============================================================================

final paintStrokesStreamProvider =
    StreamProvider.autoDispose.family<List<PaintStroke>, String>(
  (ref, canvasId) async* {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      yield [];
      return;
    }

    yield* Datum.manager<PaintStroke>()
            .watchAll(userId: userId, includeInitialData: true)
            ?.map((allStrokes) => allStrokes
                .where((stroke) =>
                    stroke.canvasId == canvasId && !stroke.isDeleted)
                .toList()
              ..sort((a, b) => a.order.compareTo(b.order))) ??
        const Stream.empty();
  },
  name: 'paintStrokesStreamProvider',
);

class PaintCanvas extends ConsumerStatefulWidget {
  final String canvasId;

  const PaintCanvas({super.key, required this.canvasId});

  @override
  ConsumerState<PaintCanvas> createState() => _PaintCanvasState();
}

class _PaintCanvasState extends ConsumerState<PaintCanvas> {
  final List<PaintStroke> _redoStrokes = [];
  List<Offset> _currentPoints = [];
  Color _selectedColor = Colors.black;
  double _strokeWidth = 2.0;

  void _startStroke(Offset position) {
    setState(() {
      _currentPoints = [position];
    });
  }

  void _updateStroke(Offset position) {
    setState(() {
      _currentPoints.add(position);
    });
  }

  Future<void> _endStroke() async {
    if (_currentPoints.isEmpty) return;

    final userId = await Datum.instance.config.initialUserId?.call();
    if (userId == null) return;

    // Get current strokes count for ordering
    final strokesAsync = ref.read(paintStrokesStreamProvider(widget.canvasId));
    final currentStrokes = strokesAsync.maybeWhen(
      data: (strokes) => strokes,
      orElse: () => <PaintStroke>[],
    );

    final stroke = PaintStroke.create(
      points: List.from(_currentPoints),
      color: _selectedColor,
      strokeWidth: _strokeWidth,
      order: currentStrokes.length,
      canvasId: widget.canvasId,
    );

    setState(() {
      _currentPoints.clear();
      _redoStrokes.clear();
    });

    // Save to Datum - the UI will update reactively
    await Datum.manager<PaintStroke>()
        .push(item: stroke, userId: stroke.userId);
  }

  Future<void> _undo() async {
    final strokesAsync = ref.read(paintStrokesStreamProvider(widget.canvasId));
    final strokes = strokesAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <PaintStroke>[],
    );

    if (strokes.isEmpty) return;

    final lastStroke = strokes.last;

    setState(() {
      _redoStrokes.add(lastStroke);
    });

    // Mark as deleted in Datum - the UI will update reactively
    final deletedStroke = lastStroke.copyWith(isDeleted: true) as PaintStroke;
    await Datum.manager<PaintStroke>()
        .push(item: deletedStroke, userId: deletedStroke.userId);
  }

  Future<void> _redo() async {
    if (_redoStrokes.isEmpty) return;

    final stroke = _redoStrokes.removeLast();

    // Restore by updating isDeleted to false - the UI will update reactively
    final restoredStroke = stroke.copyWith(isDeleted: false) as PaintStroke;
    await Datum.manager<PaintStroke>()
        .push(item: restoredStroke, userId: restoredStroke.userId);
  }

  void _clearCanvas() async {
    final userId = await Datum.instance.config.initialUserId?.call();
    if (userId == null) return;

    final strokesAsync = ref.read(paintStrokesStreamProvider(widget.canvasId));
    final strokes = strokesAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <PaintStroke>[],
    );

    // Mark all strokes as deleted
    for (final stroke in strokes) {
      final deletedStroke = stroke.copyWith(isDeleted: true) as PaintStroke;
      await Datum.manager<PaintStroke>().push(
        item: deletedStroke,
        userId: userId,
      );
    }

    setState(() {
      _redoStrokes.clear();
    });
  }

  Future<void> _syncToRemote() async {
    final userId = await Datum.instance.config.initialUserId?.call();
    if (userId == null) return;

    try {
      // Trigger manual sync for all data
      await Datum.instance.synchronize(userId);
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paint synced to remote successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      talker.error(e);
      // Show error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync: $e'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _createTestStroke() async {
    final userId = await Datum.instance.config.initialUserId?.call();
    if (userId == null) return;

    try {
      // Get current strokes count for ordering
      final strokesAsync =
          ref.read(paintStrokesStreamProvider(widget.canvasId));
      final currentStrokes = strokesAsync.maybeWhen(
        data: (strokes) => strokes,
        orElse: () => <PaintStroke>[],
      );

      // Create a simple test stroke - a diagonal line
      final testPoints = [
        const Offset(100, 100),
        const Offset(150, 150),
        const Offset(200, 200),
      ];

      final stroke = PaintStroke.create(
        points: testPoints,
        color: Colors.purple, // Use a distinctive color for test strokes
        strokeWidth: 5.0,
        order: currentStrokes.length,
        canvasId: widget.canvasId,
      );

      setState(() {
        _redoStrokes.clear();
      });

      // Save to Datum - the UI will update reactively
      await Datum.manager<PaintStroke>().push(
        item: stroke,
        userId: userId,
      );

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test stroke created and saved!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      talker.error('Failed to create test stroke: $e');
      // Show error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create test stroke: $e'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strokesAsync = ref.watch(paintStrokesStreamProvider(widget.canvasId));

    return Column(
      children: [
        // Optimized Scrollable Toolbar
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          color: Colors.grey[200],
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Color picker section
                ...[
                  Colors.black,
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow
                ].map((color) => GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: _selectedColor == color
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                      ),
                    )),
                // Divider
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.grey[400],
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                // Stroke width section
                ...[2.0, 5.0, 10.0].map((width) => GestureDetector(
                      onTap: () => setState(() => _strokeWidth = width),
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: _strokeWidth == width
                              ? Colors.blue
                              : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            width.toInt().toString(),
                            style: TextStyle(
                              color: _strokeWidth == width
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    )),
                // Divider
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.grey[400],
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                // Action buttons section
                strokesAsync.maybeWhen(
                  data: (strokes) => Row(
                    children: [
                      IconButton(
                        onPressed: strokes.isNotEmpty ? _undo : null,
                        icon: Icon(
                          Icons.undo,
                          color: strokes.isNotEmpty
                              ? Colors.black
                              : Colors.grey[400],
                        ),
                        tooltip: 'Undo',
                        iconSize: 24,
                        padding: const EdgeInsets.all(8),
                        constraints:
                            const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                      IconButton(
                        onPressed: _redoStrokes.isNotEmpty ? _redo : null,
                        icon: Icon(
                          Icons.redo,
                          color: _redoStrokes.isNotEmpty
                              ? Colors.black
                              : Colors.grey[400],
                        ),
                        tooltip: 'Redo',
                        iconSize: 24,
                        padding: const EdgeInsets.all(8),
                        constraints:
                            const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                      IconButton(
                        onPressed: strokes.isNotEmpty ? _clearCanvas : null,
                        icon: Icon(
                          Icons.clear,
                          color: strokes.isNotEmpty
                              ? Colors.black
                              : Colors.grey[400],
                        ),
                        tooltip: 'Clear Canvas',
                        iconSize: 24,
                        padding: const EdgeInsets.all(8),
                        constraints:
                            const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                    ],
                  ),
                  orElse: () => const Row(
                    children: [
                      IconButton(
                        onPressed: null,
                        icon: Icon(Icons.undo, color: Colors.grey),
                        tooltip: 'Undo',
                        iconSize: 24,
                        padding: EdgeInsets.all(8),
                        constraints:
                            BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                      IconButton(
                        onPressed: null,
                        icon: Icon(Icons.redo, color: Colors.grey),
                        tooltip: 'Redo',
                        iconSize: 24,
                        padding: EdgeInsets.all(8),
                        constraints:
                            BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                      IconButton(
                        onPressed: null,
                        icon: Icon(Icons.clear, color: Colors.grey),
                        tooltip: 'Clear Canvas',
                        iconSize: 24,
                        padding: EdgeInsets.all(8),
                        constraints:
                            BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _syncToRemote,
                  icon: const Icon(
                    Icons.cloud_upload,
                    color: Colors.blue,
                  ),
                  tooltip: 'Sync to Remote',
                  iconSize: 24,
                  padding: const EdgeInsets.all(8),
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                IconButton(
                  onPressed: _createTestStroke,
                  icon: const Icon(
                    Icons.add_circle,
                    color: Colors.green,
                  ),
                  tooltip: 'Create Test Stroke',
                  iconSize: 24,
                  padding: const EdgeInsets.all(8),
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ),
        ),
        // Canvas
        Expanded(
          child: Container(
            color: Colors.white,
            child: strokesAsync.when(
              data: (strokes) => GestureDetector(
                onPanStart: (details) => _startStroke(details.localPosition),
                onPanUpdate: (details) => _updateStroke(details.localPosition),
                onPanEnd: (details) => _endStroke(),
                child: CustomPaint(
                  painter: _CanvasPainter(
                    strokes: strokes,
                    currentPoints: _currentPoints,
                    currentColor: _selectedColor,
                    currentStrokeWidth: _strokeWidth,
                  ),
                  size: Size.infinite,
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading strokes: $error'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<PaintStroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentStrokeWidth;

  _CanvasPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes
    for (final stroke in strokes.where((s) => !s.isDeleted)) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        canvas.drawPoints(ui.PointMode.points, stroke.points, paint);
      } else {
        final path = Path();
        path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }

    // Draw current stroke being drawn
    if (currentPoints.isNotEmpty) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (currentPoints.length == 1) {
        canvas.drawPoints(ui.PointMode.points, currentPoints, paint);
      } else {
        final path = Path();
        path.moveTo(currentPoints.first.dx, currentPoints.first.dy);
        for (int i = 1; i < currentPoints.length; i++) {
          path.lineTo(currentPoints[i].dx, currentPoints[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CanvasPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentPoints != currentPoints ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.currentStrokeWidth != currentStrokeWidth;
  }
}
