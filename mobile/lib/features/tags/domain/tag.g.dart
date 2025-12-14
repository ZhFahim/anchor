// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TagImpl _$$TagImplFromJson(Map<String, dynamic> json) => _$TagImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  color: json['color'] as String?,
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  count: json['_count'] == null
      ? null
      : TagCount.fromJson(json['_count'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$TagImplToJson(_$TagImpl instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'color': instance.color,
  'updatedAt': instance.updatedAt?.toIso8601String(),
  '_count': instance.count,
};

_$TagCountImpl _$$TagCountImplFromJson(Map<String, dynamic> json) =>
    _$TagCountImpl(notes: (json['notes'] as num).toInt());

Map<String, dynamic> _$$TagCountImplToJson(_$TagCountImpl instance) =>
    <String, dynamic>{'notes': instance.notes};
