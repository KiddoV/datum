import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:example/features/paint/view/paint_canvas.dart';

@RoutePage()
class PaintPage extends StatelessWidget {
  const PaintPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Paint Canvas'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const PaintCanvas(),
      ),
    );
  }
}
