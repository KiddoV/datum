import 'package:example/bootstrap.dart';
import 'package:example/data/paint/entity/paint_stroke.dart';
import 'package:example/features/auth/data/adapters/supabase_adapter.dart';

class PaintStrokeSupabaseAdapter extends SupabaseRemoteAdapter<PaintStroke> {
  PaintStrokeSupabaseAdapter()
      : super(
          tableName: 'paint_strokes',
          fromMap: PaintStrokeFactory.fromMap,
        );

  @override
  Future<void> initialize() async {
    talker.info(
        "🎨 Initializing PaintStrokeSupabaseAdapter for table: paint_strokes");
    await super.initialize();
    talker.info("✅ PaintStrokeSupabaseAdapter initialized successfully");
  }
}
