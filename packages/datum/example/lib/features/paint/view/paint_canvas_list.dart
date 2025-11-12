import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:datum/datum.dart';
import 'package:example/data/paint/entity/paint_canvas.dart';
import 'package:example/bootstrap.dart';

class PaintCanvasList extends ConsumerStatefulWidget {
  final Function(String) onCanvasSelected;

  const PaintCanvasList({super.key, required this.onCanvasSelected});

  @override
  ConsumerState<PaintCanvasList> createState() => _PaintCanvasListState();
}

class _PaintCanvasListState extends ConsumerState<PaintCanvasList> {
  List<PaintCanvas> _canvases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCanvases();
  }

  Future<void> _loadCanvases() async {
    setState(() => _isLoading = true);
    try {
      final canvases = await Datum.manager<PaintCanvas>().readAll();
      setState(() {
        _canvases = canvases.where((c) => !c.isDeleted).toList()
          ..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
        _isLoading = false;
      });
    } catch (e) {
      talker.error('Failed to load canvases: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createNewCanvas() async {
    final titleController = TextEditingController(text: 'New Painting');
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Painting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter painting title',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Enter painting description',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && titleController.text.isNotEmpty) {
      try {
        final canvas = PaintCanvas.create(
          title: titleController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
        );

        await Datum.manager<PaintCanvas>().push(item: canvas, userId: canvas.userId);

        setState(() {
          _canvases.insert(0, canvas);
        });

        widget.onCanvasSelected(canvas.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Created "${canvas.title}"'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        talker.error('Failed to create canvas: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create painting: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteCanvas(PaintCanvas canvas) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Painting'),
        content: Text('Are you sure you want to delete "${canvas.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final deletedCanvas = canvas.copyWith(isDeleted: true) as PaintCanvas;
        await Datum.manager<PaintCanvas>().push(item: deletedCanvas, userId: deletedCanvas.userId);

        setState(() {
          _canvases.removeWhere((c) => c.id == canvas.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "${canvas.title}"'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        talker.error('Failed to delete canvas: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete painting: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_canvases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.palette,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No paintings yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first painting to get started!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNewCanvas,
              icon: const Icon(Icons.add),
              label: const Text('Create New Painting'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${_canvases.length} Painting${_canvases.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _createNewCanvas,
                icon: const Icon(Icons.add),
                label: const Text('New'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _canvases.length,
            itemBuilder: (context, index) {
              final canvas = _canvases[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.palette,
                      color: Colors.blue,
                    ),
                  ),
                  title: Text(
                    canvas.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (canvas.description != null && canvas.description!.isNotEmpty)
                        Text(
                          canvas.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        '${canvas.strokeCount} stroke${canvas.strokeCount == 1 ? '' : 's'} • Modified ${canvas.modifiedAt.toString().split(' ')[0]}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteCanvas(canvas);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () => widget.onCanvasSelected(canvas.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
