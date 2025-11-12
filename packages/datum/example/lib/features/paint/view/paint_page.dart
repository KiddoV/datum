import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example/features/paint/view/paint_canvas.dart';
import 'package:example/features/paint/view/paint_canvas_list.dart';

@RoutePage()
class PaintPage extends ConsumerStatefulWidget {
  const PaintPage({super.key});

  @override
  ConsumerState<PaintPage> createState() => _PaintPageState();
}

class _PaintPageState extends ConsumerState<PaintPage> {
  String? _selectedCanvasId;

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_selectedCanvasId != null ? 'Paint Canvas' : 'My Paintings'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          leading: _selectedCanvasId != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _selectedCanvasId = null),
                )
              : null,
          actions: _selectedCanvasId != null
              ? [
                  IconButton(
                    icon: const Icon(Icons.list),
                    onPressed: () => setState(() => _selectedCanvasId = null),
                    tooltip: 'View All Paintings',
                  ),
                ]
              : null,
        ),
        body: _selectedCanvasId != null
            ? PaintCanvas(canvasId: _selectedCanvasId!)
            : PaintCanvasList(
                onCanvasSelected: (canvasId) =>
                    setState(() => _selectedCanvasId = canvasId),
              ),
      ),
    );
  }
}
