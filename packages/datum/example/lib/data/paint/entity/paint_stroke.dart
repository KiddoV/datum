// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:datum/datum.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'paint_canvas.dart';

//-- Create paint_strokes table - COMPATIBLE WITH SUPABASE
/*
-- Step 1: Create the table
CREATE TABLE public.paint_strokes (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    points JSONB NOT NULL,
    color BIGINT NOT NULL,
    stroke_width REAL NOT NULL,
    "order" INTEGER NOT NULL,
    is_deleted BOOLEAN DEFAULT FALSE,
    version INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    modified_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 2: Enable Row Level Security
ALTER TABLE public.paint_strokes ENABLE ROW LEVEL SECURITY;

-- Step 3: Create RLS policy
CREATE POLICY "Users can only access their own paint strokes" ON public.paint_strokes
    FOR ALL USING (auth.uid()::text = user_id);

-- Step 4: Create indexes
CREATE INDEX idx_paint_strokes_user_id ON public.paint_strokes(user_id);
CREATE INDEX idx_paint_strokes_modified_at ON public.paint_strokes(modified_at);
CREATE INDEX idx_paint_strokes_order ON public.paint_strokes("order");

-- Step 5: Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.paint_strokes;

-- Step 6: Test the table (optional - run after creating)
-- INSERT INTO public.paint_strokes (id, user_id, points, color, stroke_width, "order")
-- VALUES ('test-123', 'user-456', '[{"x": 100, "y": 200}, {"x": 150, "y": 250}]', 4294198070, 5.0, 1);
*/

class PaintStroke extends RelationalDatumEntity {
  @override
  final String id;

  @override
  final String userId;

  final List<Offset> points;

  final Color color;

  final double strokeWidth;

  final int order;

  final String canvasId;

  @override
  final DateTime createdAt;

  @override
  final DateTime modifiedAt;

  @override
  final bool isDeleted;

  @override
  final int version;

  const PaintStroke({
    required this.id,
    required this.userId,
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.order,
    required this.canvasId,
    required this.createdAt,
    required this.modifiedAt,
    this.isDeleted = false,
    this.version = 1,
  });

  PaintStroke copyWithAll({
    String? id,
    String? userId,
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    int? order,
    String? canvasId,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isDeleted,
    int? version,
  }) {
    final bool hasChanges = id != null ||
        userId != null ||
        points != null ||
        color != null ||
        strokeWidth != null ||
        order != null ||
        canvasId != null ||
        createdAt != null ||
        modifiedAt != null ||
        isDeleted != null;

    return PaintStroke(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      order: order ?? this.order,
      canvasId: canvasId ?? this.canvasId,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: (modifiedAt ?? this.modifiedAt),
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? (hasChanges ? this.version + 1 : this.version),
    );
  }

  @override
  Map<String, dynamic>? diff(covariant DatumEntityInterface oldVersion) {
    final oldStroke = oldVersion as PaintStroke;
    final diff = <String, dynamic>{};

    if (points != oldStroke.points) {
      diff['points'] = points.map((p) => {'x': p.dx, 'y': p.dy}).toList();
    }
    if (color != oldStroke.color) {
      diff['color'] = color.toARGB32();
    }
    if (strokeWidth != oldStroke.strokeWidth) {
      diff['strokeWidth'] = strokeWidth;
    }
    if (order != oldStroke.order) {
      diff['order'] = order;
    }
    if (isDeleted != oldStroke.isDeleted) {
      diff['isDeleted'] = isDeleted;
    }

    if (diff.isNotEmpty) {
      diff['modifiedAt'] = modifiedAt.toIso8601String();
      diff['version'] = version;
    }

    return diff.isEmpty ? null : diff;
  }

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) {
    final map = {
      'id': id,
      'userId': userId,
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'order': order,
      'isDeleted': isDeleted,
      'canvasId': canvasId,
      'version': version,
    };

    if (target == MapTarget.remote) {
      map['createdAt'] = createdAt.toIso8601String();
      map['modifiedAt'] = modifiedAt.toIso8601String();
    } else {
      map['createdAt'] = createdAt.millisecondsSinceEpoch;
      map['modifiedAt'] = modifiedAt.millisecondsSinceEpoch;
    }
    return map;
  }

  factory PaintStroke.fromMap(Map<String, dynamic> map) {
    return PaintStroke(
      id: (map['id'] ?? '') as String,
      userId: (map['userId'] ?? map['user_id'] ?? '') as String,
      points: ((map['points'] ?? []) as List<dynamic>)
          .map((p) =>
              Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
          .toList(),
      color: Color((map['color'] ?? 0xFF000000) as int),
      strokeWidth: (map['strokeWidth'] ?? 2.0) is int
          ? (map['strokeWidth'] as int).toDouble()
          : (map['strokeWidth'] ?? 2.0) as double,
      order: (map['order'] ?? 0) as int,
      canvasId: (map['canvasId'] ?? map['canvas_id'] ?? '') as String,
      createdAt: _parseDate(map['createdAt'] ?? map['created_at']),
      modifiedAt: _parseDate(map['modifiedAt'] ?? map['modified_at']),
      isDeleted: (map['isDeleted'] ?? map['is_deleted'] ?? false) as bool,
      version: (map['version'] ?? 1) as int,
    );
  }

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateValue);
    }
    if (dateValue is String) {
      return DateTime.tryParse(dateValue) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static PaintStroke create({
    required List<Offset> points,
    required Color color,
    required double strokeWidth,
    required int order,
    required String canvasId,
  }) {
    final now = DateTime.now();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Cannot create paint stroke: user is not logged in.');
    }
    return PaintStroke(
      id: '${now.millisecondsSinceEpoch}${Random().nextInt(9999)}',
      userId: userId,
      points: points,
      color: color,
      strokeWidth: strokeWidth,
      order: order,
      canvasId: canvasId,
      createdAt: now,
      modifiedAt: now,
    );
  }

  String toJson() => json.encode(toDatumMap());

  factory PaintStroke.fromJson(String source) =>
      PaintStroke.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PaintStroke(id: $id, userId: $userId, points: ${points.length} points, color: $color, strokeWidth: $strokeWidth, order: $order, createdAt: $createdAt, modifiedAt: $modifiedAt, isDeleted: $isDeleted, version: $version)';
  }

  @override
  bool operator ==(covariant PaintStroke other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.userId == userId &&
        _listEquals(other.points, points) &&
        other.color == color &&
        other.strokeWidth == strokeWidth &&
        other.order == order &&
        other.createdAt == createdAt &&
        other.modifiedAt == modifiedAt &&
        other.isDeleted == isDeleted &&
        other.version == version;
  }

  bool _listEquals(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        points.hashCode ^
        color.hashCode ^
        strokeWidth.hashCode ^
        order.hashCode ^
        createdAt.hashCode ^
        modifiedAt.hashCode ^
        isDeleted.hashCode ^
        version.hashCode;
  }

  @override
  bool? get stringify => true;

  @override
  List<Object?> get props => [];

  @override
  Map<String, Relation> get relations => {
        'canvas': BelongsTo<PaintCanvas>(
          this,
          'canvasId', // The foreign key in this entity that points to the canvas
        ),
      };

  @override
  RelationalDatumEntity copyWith({
    DateTime? modifiedAt,
    int? version,
    bool? isDeleted,
  }) {
    return copyWithAll(
      modifiedAt: modifiedAt,
      version: version,
      isDeleted: isDeleted,
    );
  }
}
