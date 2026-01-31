import 'package:datum/datum.dart';
import 'package:datum_generator/annotations.dart';

part 'advanced_types_example.g.dart';

/// Example entity demonstrating advanced type support
@DatumSerializable(tableName: 'advanced_examples', generateMixin: true)
class AdvancedTypesExample extends DatumEntity
    with _$AdvancedTypesExampleMixin {
  @override
  final String id;

  @override
  final String userId;

  // Enum support
  final Priority priority;
  final Status? status;

  // Duration support
  final Duration timeout;
  final Duration? optionalDuration;

  // Uri support
  final Uri websiteUrl;
  final Uri? profilePictureUrl;

  // BigInt support
  final BigInt largeNumber;
  final BigInt? optionalLargeNumber;

  @override
  final DateTime createdAt;

  @override
  final DateTime modifiedAt;

  @override
  final int version;

  @override
  final bool isDeleted;

  const AdvancedTypesExample({
    required this.id,
    required this.userId,
    required this.priority,
    this.status,
    required this.timeout,
    this.optionalDuration,
    required this.websiteUrl,
    this.profilePictureUrl,
    required this.largeNumber,
    this.optionalLargeNumber,
    required this.createdAt,
    required this.modifiedAt,
    this.version = 1,
    this.isDeleted = false,
  });

  // Factory using the generated extension
  factory AdvancedTypesExample.fromMap(Map<String, dynamic> map) {
    return AdvancedTypesExampleFactory.fromMap(map);
  }
}

/// Example enum for priority levels
enum Priority {
  low,
  medium,
  high,
  critical,
}

/// Example enum for status (nullable)
enum Status {
  pending,
  active,
  completed,
  cancelled,
}
