import 'package:example/data/paint/entity/paint_stroke.dart';
import 'package:example/data/user/adapters/supabase_adapter.dart';

class PaintStrokeSupabaseAdapter extends SupabaseRemoteAdapter<PaintStroke> {
  PaintStrokeSupabaseAdapter()
      : super(
          tableName: 'paint_strokes',
          fromMap: PaintStroke.fromMap,
        );
}
