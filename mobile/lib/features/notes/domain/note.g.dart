// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NoteImpl _$$NoteImplFromJson(Map<String, dynamic> json) => _$NoteImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  content: json['content'] as String?,
  isPinned: json['isPinned'] as bool? ?? false,
  isArchived: json['isArchived'] as bool? ?? false,
  background: json['background'] as String?,
  state:
      $enumDecodeNullable(_$NoteStateEnumMap, json['state']) ??
      NoteState.active,
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  tagIds:
      (json['tagIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$$NoteImplToJson(_$NoteImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'isPinned': instance.isPinned,
      'isArchived': instance.isArchived,
      'background': instance.background,
      'state': _$NoteStateEnumMap[instance.state]!,
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'tagIds': instance.tagIds,
    };

const _$NoteStateEnumMap = {
  NoteState.active: 'active',
  NoteState.trashed: 'trashed',
  NoteState.deleted: 'deleted',
};
