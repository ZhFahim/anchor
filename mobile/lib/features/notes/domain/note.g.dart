// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NoteReminder _$NoteReminderFromJson(Map<String, dynamic> json) =>
    _NoteReminder(
      remindAt: json['remindAt'] as String,
      recurrence:
          $enumDecodeNullable(
            _$ReminderRecurrenceEnumMap,
            json['recurrence'],
          ) ??
          ReminderRecurrence.none,
      version: (json['version'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$NoteReminderToJson(_NoteReminder instance) =>
    <String, dynamic>{
      'remindAt': instance.remindAt,
      'recurrence': _$ReminderRecurrenceEnumMap[instance.recurrence]!,
      'version': instance.version,
    };

const _$ReminderRecurrenceEnumMap = {
  ReminderRecurrence.none: 'none',
  ReminderRecurrence.daily: 'daily',
  ReminderRecurrence.weekly: 'weekly',
  ReminderRecurrence.monthly: 'monthly',
  ReminderRecurrence.yearly: 'yearly',
};

_SharedByUser _$SharedByUserFromJson(Map<String, dynamic> json) =>
    _SharedByUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      profileImage: json['profileImage'] as String?,
    );

Map<String, dynamic> _$SharedByUserToJson(_SharedByUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'profileImage': instance.profileImage,
    };

_Note _$NoteFromJson(Map<String, dynamic> json) => _Note(
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
  permission:
      $enumDecodeNullable(_$NotePermissionEnumMap, json['permission']) ??
      NotePermission.owner,
  shareIds: (json['shareIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  sharedBy: json['sharedBy'] == null
      ? null
      : SharedByUser.fromJson(json['sharedBy'] as Map<String, dynamic>),
  reminder: json['reminder'] == null
      ? null
      : NoteReminder.fromJson(json['reminder'] as Map<String, dynamic>),
);

Map<String, dynamic> _$NoteToJson(_Note instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'content': instance.content,
  'isPinned': instance.isPinned,
  'isArchived': instance.isArchived,
  'background': instance.background,
  'state': _$NoteStateEnumMap[instance.state]!,
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'tagIds': instance.tagIds,
  'permission': _$NotePermissionEnumMap[instance.permission]!,
  'shareIds': instance.shareIds,
  'sharedBy': instance.sharedBy,
  'reminder': instance.reminder,
};

const _$NoteStateEnumMap = {
  NoteState.active: 'active',
  NoteState.trashed: 'trashed',
  NoteState.deleted: 'deleted',
};

const _$NotePermissionEnumMap = {
  NotePermission.owner: 'owner',
  NotePermission.viewer: 'viewer',
  NotePermission.editor: 'editor',
};
