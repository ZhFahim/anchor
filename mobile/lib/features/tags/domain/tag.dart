import 'dart:math';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag.freezed.dart';
part 'tag.g.dart';

/// Curated list of pleasant tag colors (standard hex format for cross-platform)
const List<String> _tagColors = [
  '#E57373', // Red 300
  '#F06292', // Pink 300
  '#BA68C8', // Purple 300
  '#9575CD', // Deep Purple 300
  '#7986CB', // Indigo 300
  '#64B5F6', // Blue 300
  '#4FC3F7', // Light Blue 300
  '#4DD0E1', // Cyan 300
  '#4DB6AC', // Teal 300
  '#81C784', // Green 300
  '#AED581', // Light Green 300
  '#DCE775', // Lime 300
  '#FFD54F', // Amber 300
  '#FFB74D', // Orange 300
  '#FF8A65', // Deep Orange 300
  '#A1887F', // Brown 300
  '#90A4AE', // Blue Grey 300
];

/// Generates a random tag color as a standard hex string (#RRGGBB)
String generateRandomTagColor() {
  final random = Random();
  return _tagColors[random.nextInt(_tagColors.length)];
}

/// Parses a hex color string to Flutter Color
/// Supports: #RGB, #RRGGBB, #AARRGGBB, 0xAARRGGBB
Color parseTagColor(String? hexColor, {Color fallback = Colors.grey}) {
  if (hexColor == null || hexColor.isEmpty) return fallback;

  String hex = hexColor.replaceAll('#', '').replaceAll('0x', '');

  // Handle short format #RGB -> #RRGGBB
  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join();
  }

  // Add alpha if not present (6 chars -> 8 chars)
  if (hex.length == 6) {
    hex = 'FF$hex';
  }

  try {
    return Color(int.parse(hex, radix: 16));
  } catch (_) {
    return fallback;
  }
}

@freezed
abstract class Tag with _$Tag {
  const Tag._();

  const factory Tag({
    required String id,
    required String name,
    String? color,
    DateTime? updatedAt,
    // Note count from server (optional, not stored locally)
    @JsonKey(name: '_count') TagCount? count,
    // Local only - not serialized
    @Default(true)
    @JsonKey(includeFromJson: false, includeToJson: false)
    bool isSynced,
    @Default(false)
    @JsonKey(includeFromJson: false, includeToJson: false)
    bool isDeleted,
  }) = _Tag;

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);

  int get noteCount => count?.notes ?? 0;
}

@freezed
abstract class TagCount with _$TagCount {
  const factory TagCount({required int notes}) = _TagCount;

  factory TagCount.fromJson(Map<String, dynamic> json) =>
      _$TagCountFromJson(json);
}
