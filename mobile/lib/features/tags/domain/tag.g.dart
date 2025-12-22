// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Tag _$TagFromJson(Map<String, dynamic> json) => _Tag(
  id: json['id'] as String,
  name: json['name'] as String,
  color: json['color'] as String?,
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  count: json['_count'] == null
      ? null
      : TagCount.fromJson(json['_count'] as Map<String, dynamic>),
  isDeleted: json['isDeleted'] as bool? ?? false,
);

Map<String, dynamic> _$TagToJson(_Tag instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'color': instance.color,
  'updatedAt': instance.updatedAt?.toIso8601String(),
  '_count': instance.count,
};

_TagCount _$TagCountFromJson(Map<String, dynamic> json) =>
    _TagCount(notes: (json['notes'] as num).toInt());

Map<String, dynamic> _$TagCountToJson(_TagCount instance) => <String, dynamic>{
  'notes': instance.notes,
};
