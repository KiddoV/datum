// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:math';

import 'package:datum/datum.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'paint_stroke.dart';

//-- Create paint_canvases table - COMPATIBLE WITH SUPABASE
/*
-- Step 1: Create the table
CREATE TABLE public.paint_canvases (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    thumbnail_stroke_data JSONB,
    stroke_count INTEGER DEFAULT 0,
    is_deleted BOOLEAN DEFAULT FALSE,
    version INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    modified_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 2: Enable Row Level Security
ALTER TABLE public.paint_canvases ENABLE ROW LEVEL SECURITY;

-- Step 3: Create RLS policy
CREATE POLICY "Users can only access their own paint canvases" ON public.paint_canvases
    FOR ALL USING (auth.uid()::text = user_id);

-- Step 4: Create indexes
CREATE INDEX idx_paint_canvases_user_id ON public.paint_canvases(user_id);
CREATE INDEX idx_paint_canvases_modified_at ON public.paint_canvases(modified_at);

-- Step 5: Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.paint_canvases;
*/

class PaintCanvas extends RelationalDatumEntity {
  @override
  final String id;

  @override
  final String userId;

  final String title;

  final String? description;

  final List<Map<String, dynamic>>? thumbnailStrokeData;

  final int strokeCount;

  @override
  final DateTime createdAt;

  @override
  final DateTime modifiedAt;

  @override
  final bool isDeleted;

  @override
  final int version;

  const PaintCanvas({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.thumbnailStrokeData,
    this.strokeCount = 0,
    required this.createdAt,
    required this.modifiedAt,
    this.isDeleted = false,
    this.version = 1,
  });

  PaintCanvas copyWithAll({
    String? id,
    String? userId,
    String? title,
    String? description,
    List<Map<String, dynamic>>? thumbnailStrokeData,
    int? strokeCount,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isDeleted,
    int? version,
  }) {
    final bool hasChanges = id != null ||
        userId != null ||
        title != null ||
        description != null ||
        thumbnailStrokeData != null ||
        strokeCount != null ||
        createdAt != null ||
        modifiedAt != null ||
        isDeleted != null;

    return PaintCanvas(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailStrokeData: thumbnailStrokeData ?? this.thumbnailStrokeData,
      strokeCount: strokeCount ?? this.strokeCount,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: (modifiedAt ?? this.modifiedAt),
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? (hasChanges ? this.version + 1 : this.version),
    );
  }

  @override
  Map<String, dynamic>? diff(covariant DatumEntityInterface oldVersion) {
    final oldCanvas = oldVersion as PaintCanvas;
    final diff = <String, dynamic>{};

    if (title != oldCanvas.title) {
      diff['title'] = title;
    }
    if (description != oldCanvas.description) {
      diff['description'] = description;
    }
    if (thumbnailStrokeData != oldCanvas.thumbnailStrokeData) {
      diff['thumbnailStrokeData'] = thumbnailStrokeData;
    }
    if (strokeCount != oldCanvas.strokeCount) {
      diff['strokeCount'] = strokeCount;
    }
    if (isDeleted != oldCanvas.isDeleted) {
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
      'title': title,
      'description': description,
      'thumbnailStrokeData': thumbnailStrokeData,
      'strokeCount': strokeCount,
      'isDeleted': isDeleted,
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

  factory PaintCanvas.fromMap(Map<String, dynamic> map) {
    return PaintCanvas(
      id: (map['id'] ?? '') as String,
      userId: (map['userId'] ?? map['user_id'] ?? '') as String,
      title: (map['title'] ?? 'Untitled') as String,
      description: map['description'] as String?,
      thumbnailStrokeData: (map['thumbnailStrokeData'] ??
          map['thumbnail_stroke_data']) as List<Map<String, dynamic>>?,
      strokeCount: (map['strokeCount'] ?? map['stroke_count'] ?? 0) is num
          ? (map['strokeCount'] ?? map['stroke_count'] ?? 0).toInt()
          : (map['strokeCount'] ?? map['stroke_count'] ?? 0) as int,
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

  static PaintCanvas create({
    required String title,
    String? description,
  }) {
    final now = DateTime.now();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Cannot create paint canvas: user is not logged in.');
    }
    return PaintCanvas(
      id: '${now.millisecondsSinceEpoch}${Random().nextInt(9999)}',
      userId: userId,
      title: title,
      description: description,
      strokeCount: 0,
      createdAt: now,
      modifiedAt: now,
    );
  }

  String toJson() => json.encode(toDatumMap());

  factory PaintCanvas.fromJson(String source) =>
      PaintCanvas.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PaintCanvas(id: $id, userId: $userId, title: $title, description: $description, strokeCount: $strokeCount, createdAt: $createdAt, modifiedAt: $modifiedAt, isDeleted: $isDeleted, version: $version)';
  }

  @override
  bool operator ==(covariant PaintCanvas other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.description == description &&
        other.strokeCount == strokeCount &&
        other.createdAt == createdAt &&
        other.modifiedAt == modifiedAt &&
        other.isDeleted == isDeleted &&
        other.version == version;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        title.hashCode ^
        description.hashCode ^
        strokeCount.hashCode ^
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
        'strokes': HasMany<PaintStroke>(
          this,
          'canvasId', // The foreign key in PaintStroke that points to this canvas
          cascadeDeleteBehavior: CascadeDeleteBehavior
              .cascade, // Delete strokes when canvas is deleted
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
