// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'note.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NoteReminder {

 String get remindAt; ReminderRecurrence get recurrence; int get version;
/// Create a copy of NoteReminder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoteReminderCopyWith<NoteReminder> get copyWith => _$NoteReminderCopyWithImpl<NoteReminder>(this as NoteReminder, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoteReminder&&(identical(other.remindAt, remindAt) || other.remindAt == remindAt)&&(identical(other.recurrence, recurrence) || other.recurrence == recurrence)&&(identical(other.version, version) || other.version == version));
}


@override
int get hashCode => Object.hash(runtimeType,remindAt,recurrence,version);

@override
String toString() {
  return 'NoteReminder(remindAt: $remindAt, recurrence: $recurrence, version: $version)';
}


}

/// @nodoc
abstract mixin class $NoteReminderCopyWith<$Res>  {
  factory $NoteReminderCopyWith(NoteReminder value, $Res Function(NoteReminder) _then) = _$NoteReminderCopyWithImpl;
@useResult
$Res call({
 String remindAt, ReminderRecurrence recurrence, int version
});




}
/// @nodoc
class _$NoteReminderCopyWithImpl<$Res>
    implements $NoteReminderCopyWith<$Res> {
  _$NoteReminderCopyWithImpl(this._self, this._then);

  final NoteReminder _self;
  final $Res Function(NoteReminder) _then;

/// Create a copy of NoteReminder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? remindAt = null,Object? recurrence = null,Object? version = null,}) {
  return _then(NoteReminder(
remindAt: null == remindAt ? _self.remindAt : remindAt // ignore: cast_nullable_to_non_nullable
as String,recurrence: null == recurrence ? _self.recurrence : recurrence // ignore: cast_nullable_to_non_nullable
as ReminderRecurrence,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [NoteReminder].
extension NoteReminderPatterns on NoteReminder {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NoteReminder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NoteReminder() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NoteReminder value)  $default,){
final _that = this;
switch (_that) {
case _NoteReminder():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NoteReminder value)?  $default,){
final _that = this;
switch (_that) {
case _NoteReminder() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String remindAt,  ReminderRecurrence recurrence,  int version)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NoteReminder() when $default != null:
return $default(_that.remindAt,_that.recurrence,_that.version);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String remindAt,  ReminderRecurrence recurrence,  int version)  $default,) {final _that = this;
switch (_that) {
case _NoteReminder():
return $default(_that.remindAt,_that.recurrence,_that.version);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String remindAt,  ReminderRecurrence recurrence,  int version)?  $default,) {final _that = this;
switch (_that) {
case _NoteReminder() when $default != null:
return $default(_that.remindAt,_that.recurrence,_that.version);case _:
  return null;

}
}

}

/// @nodoc


class _NoteReminder extends NoteReminder {
  const _NoteReminder({required this.remindAt, this.recurrence = ReminderRecurrence.none, this.version = 0}): super._();
  

@override final  String remindAt;
@override@JsonKey() final  ReminderRecurrence recurrence;
@override@JsonKey() final  int version;

/// Create a copy of NoteReminder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NoteReminderCopyWith<_NoteReminder> get copyWith => __$NoteReminderCopyWithImpl<_NoteReminder>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NoteReminder&&(identical(other.remindAt, remindAt) || other.remindAt == remindAt)&&(identical(other.recurrence, recurrence) || other.recurrence == recurrence)&&(identical(other.version, version) || other.version == version));
}


@override
int get hashCode => Object.hash(runtimeType,remindAt,recurrence,version);

@override
String toString() {
  return 'NoteReminder(remindAt: $remindAt, recurrence: $recurrence, version: $version)';
}


}

/// @nodoc
abstract mixin class _$NoteReminderCopyWith<$Res> implements $NoteReminderCopyWith<$Res> {
  factory _$NoteReminderCopyWith(_NoteReminder value, $Res Function(_NoteReminder) _then) = __$NoteReminderCopyWithImpl;
@override @useResult
$Res call({
 String remindAt, ReminderRecurrence recurrence, int version
});




}
/// @nodoc
class __$NoteReminderCopyWithImpl<$Res>
    implements _$NoteReminderCopyWith<$Res> {
  __$NoteReminderCopyWithImpl(this._self, this._then);

  final _NoteReminder _self;
  final $Res Function(_NoteReminder) _then;

/// Create a copy of NoteReminder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? remindAt = null,Object? recurrence = null,Object? version = null,}) {
  return _then(_NoteReminder(
remindAt: null == remindAt ? _self.remindAt : remindAt // ignore: cast_nullable_to_non_nullable
as String,recurrence: null == recurrence ? _self.recurrence : recurrence // ignore: cast_nullable_to_non_nullable
as ReminderRecurrence,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$Note {

 String get id; String get title; NoteType get noteType; String? get content; bool get isPinned; bool get isArchived; String? get background; NoteState get state; DateTime? get updatedAt; List<String> get tagIds; NotePermission get permission; List<String>? get shareIds; UserSummary? get sharedBy; NoteReminder? get reminder; bool get isSynced; int? get reminderSlot; List<NoteImagePreview> get imagePreviewData; int get attachmentCount;
/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoteCopyWith<Note> get copyWith => _$NoteCopyWithImpl<Note>(this as Note, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Note&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.noteType, noteType) || other.noteType == noteType)&&(identical(other.content, content) || other.content == content)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.background, background) || other.background == background)&&(identical(other.state, state) || other.state == state)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.tagIds, tagIds)&&(identical(other.permission, permission) || other.permission == permission)&&const DeepCollectionEquality().equals(other.shareIds, shareIds)&&(identical(other.sharedBy, sharedBy) || other.sharedBy == sharedBy)&&(identical(other.reminder, reminder) || other.reminder == reminder)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced)&&(identical(other.reminderSlot, reminderSlot) || other.reminderSlot == reminderSlot)&&const DeepCollectionEquality().equals(other.imagePreviewData, imagePreviewData)&&(identical(other.attachmentCount, attachmentCount) || other.attachmentCount == attachmentCount));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,noteType,content,isPinned,isArchived,background,state,updatedAt,const DeepCollectionEquality().hash(tagIds),permission,const DeepCollectionEquality().hash(shareIds),sharedBy,reminder,isSynced,reminderSlot,const DeepCollectionEquality().hash(imagePreviewData),attachmentCount);

@override
String toString() {
  return 'Note(id: $id, title: $title, noteType: $noteType, content: $content, isPinned: $isPinned, isArchived: $isArchived, background: $background, state: $state, updatedAt: $updatedAt, tagIds: $tagIds, permission: $permission, shareIds: $shareIds, sharedBy: $sharedBy, reminder: $reminder, isSynced: $isSynced, reminderSlot: $reminderSlot, imagePreviewData: $imagePreviewData, attachmentCount: $attachmentCount)';
}


}

/// @nodoc
abstract mixin class $NoteCopyWith<$Res>  {
  factory $NoteCopyWith(Note value, $Res Function(Note) _then) = _$NoteCopyWithImpl;
@useResult
$Res call({
 String id, String title, NoteType noteType, String? content, bool isPinned, bool isArchived, String? background, NoteState state, DateTime? updatedAt, List<String> tagIds, NotePermission permission, List<String>? shareIds, UserSummary? sharedBy, NoteReminder? reminder, bool isSynced, int? reminderSlot, List<NoteImagePreview> imagePreviewData, int attachmentCount
});


$UserSummaryCopyWith<$Res>? get sharedBy;$NoteReminderCopyWith<$Res>? get reminder;

}
/// @nodoc
class _$NoteCopyWithImpl<$Res>
    implements $NoteCopyWith<$Res> {
  _$NoteCopyWithImpl(this._self, this._then);

  final Note _self;
  final $Res Function(Note) _then;

/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? noteType = null,Object? content = freezed,Object? isPinned = null,Object? isArchived = null,Object? background = freezed,Object? state = null,Object? updatedAt = freezed,Object? tagIds = null,Object? permission = null,Object? shareIds = freezed,Object? sharedBy = freezed,Object? reminder = freezed,Object? isSynced = null,Object? reminderSlot = freezed,Object? imagePreviewData = null,Object? attachmentCount = null,}) {
  return _then(Note(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,noteType: null == noteType ? _self.noteType : noteType // ignore: cast_nullable_to_non_nullable
as NoteType,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as NoteState,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,tagIds: null == tagIds ? _self.tagIds : tagIds // ignore: cast_nullable_to_non_nullable
as List<String>,permission: null == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as NotePermission,shareIds: freezed == shareIds ? _self.shareIds : shareIds // ignore: cast_nullable_to_non_nullable
as List<String>?,sharedBy: freezed == sharedBy ? _self.sharedBy : sharedBy // ignore: cast_nullable_to_non_nullable
as UserSummary?,reminder: freezed == reminder ? _self.reminder : reminder // ignore: cast_nullable_to_non_nullable
as NoteReminder?,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,reminderSlot: freezed == reminderSlot ? _self.reminderSlot : reminderSlot // ignore: cast_nullable_to_non_nullable
as int?,imagePreviewData: null == imagePreviewData ? _self.imagePreviewData : imagePreviewData // ignore: cast_nullable_to_non_nullable
as List<NoteImagePreview>,attachmentCount: null == attachmentCount ? _self.attachmentCount : attachmentCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSummaryCopyWith<$Res>? get sharedBy {
    if (_self.sharedBy == null) {
    return null;
  }

  return $UserSummaryCopyWith<$Res>(_self.sharedBy!, (value) {
    return _then(_self.copyWith(sharedBy: value));
  });
}/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NoteReminderCopyWith<$Res>? get reminder {
    if (_self.reminder == null) {
    return null;
  }

  return $NoteReminderCopyWith<$Res>(_self.reminder!, (value) {
    return _then(_self.copyWith(reminder: value));
  });
}
}


/// Adds pattern-matching-related methods to [Note].
extension NotePatterns on Note {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Note value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Note() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Note value)  $default,){
final _that = this;
switch (_that) {
case _Note():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Note value)?  $default,){
final _that = this;
switch (_that) {
case _Note() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  NoteType noteType,  String? content,  bool isPinned,  bool isArchived,  String? background,  NoteState state,  DateTime? updatedAt,  List<String> tagIds,  NotePermission permission,  List<String>? shareIds,  UserSummary? sharedBy,  NoteReminder? reminder,  bool isSynced,  int? reminderSlot,  List<NoteImagePreview> imagePreviewData,  int attachmentCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Note() when $default != null:
return $default(_that.id,_that.title,_that.noteType,_that.content,_that.isPinned,_that.isArchived,_that.background,_that.state,_that.updatedAt,_that.tagIds,_that.permission,_that.shareIds,_that.sharedBy,_that.reminder,_that.isSynced,_that.reminderSlot,_that.imagePreviewData,_that.attachmentCount);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  NoteType noteType,  String? content,  bool isPinned,  bool isArchived,  String? background,  NoteState state,  DateTime? updatedAt,  List<String> tagIds,  NotePermission permission,  List<String>? shareIds,  UserSummary? sharedBy,  NoteReminder? reminder,  bool isSynced,  int? reminderSlot,  List<NoteImagePreview> imagePreviewData,  int attachmentCount)  $default,) {final _that = this;
switch (_that) {
case _Note():
return $default(_that.id,_that.title,_that.noteType,_that.content,_that.isPinned,_that.isArchived,_that.background,_that.state,_that.updatedAt,_that.tagIds,_that.permission,_that.shareIds,_that.sharedBy,_that.reminder,_that.isSynced,_that.reminderSlot,_that.imagePreviewData,_that.attachmentCount);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  NoteType noteType,  String? content,  bool isPinned,  bool isArchived,  String? background,  NoteState state,  DateTime? updatedAt,  List<String> tagIds,  NotePermission permission,  List<String>? shareIds,  UserSummary? sharedBy,  NoteReminder? reminder,  bool isSynced,  int? reminderSlot,  List<NoteImagePreview> imagePreviewData,  int attachmentCount)?  $default,) {final _that = this;
switch (_that) {
case _Note() when $default != null:
return $default(_that.id,_that.title,_that.noteType,_that.content,_that.isPinned,_that.isArchived,_that.background,_that.state,_that.updatedAt,_that.tagIds,_that.permission,_that.shareIds,_that.sharedBy,_that.reminder,_that.isSynced,_that.reminderSlot,_that.imagePreviewData,_that.attachmentCount);case _:
  return null;

}
}

}

/// @nodoc


class _Note extends Note {
  const _Note({required this.id, required this.title, this.noteType = NoteType.note, this.content, this.isPinned = false, this.isArchived = false, this.background, this.state = NoteState.active, this.updatedAt,  List<String> tagIds = const [], this.permission = NotePermission.owner,  List<String>? shareIds, this.sharedBy, this.reminder, this.isSynced = true, this.reminderSlot,  List<NoteImagePreview> imagePreviewData = const [], this.attachmentCount = 0}): _tagIds = tagIds,_shareIds = shareIds,_imagePreviewData = imagePreviewData,super._();
  

@override final  String id;
@override final  String title;
@override@JsonKey() final  NoteType noteType;
@override final  String? content;
@override@JsonKey() final  bool isPinned;
@override@JsonKey() final  bool isArchived;
@override final  String? background;
@override@JsonKey() final  NoteState state;
@override final  DateTime? updatedAt;
 final  List<String> _tagIds;
@override@JsonKey() List<String> get tagIds {
  if (_tagIds is EqualUnmodifiableListView) return _tagIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tagIds);
}

@override@JsonKey() final  NotePermission permission;
 final  List<String>? _shareIds;
@override List<String>? get shareIds {
  final value = _shareIds;
  if (value == null) return null;
  if (_shareIds is EqualUnmodifiableListView) return _shareIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  UserSummary? sharedBy;
@override final  NoteReminder? reminder;
@override@JsonKey() final  bool isSynced;
@override final  int? reminderSlot;
 final  List<NoteImagePreview> _imagePreviewData;
@override@JsonKey() List<NoteImagePreview> get imagePreviewData {
  if (_imagePreviewData is EqualUnmodifiableListView) return _imagePreviewData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_imagePreviewData);
}

@override@JsonKey() final  int attachmentCount;

/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NoteCopyWith<_Note> get copyWith => __$NoteCopyWithImpl<_Note>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Note&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.noteType, noteType) || other.noteType == noteType)&&(identical(other.content, content) || other.content == content)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.background, background) || other.background == background)&&(identical(other.state, state) || other.state == state)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._tagIds, _tagIds)&&(identical(other.permission, permission) || other.permission == permission)&&const DeepCollectionEquality().equals(other._shareIds, _shareIds)&&(identical(other.sharedBy, sharedBy) || other.sharedBy == sharedBy)&&(identical(other.reminder, reminder) || other.reminder == reminder)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced)&&(identical(other.reminderSlot, reminderSlot) || other.reminderSlot == reminderSlot)&&const DeepCollectionEquality().equals(other._imagePreviewData, _imagePreviewData)&&(identical(other.attachmentCount, attachmentCount) || other.attachmentCount == attachmentCount));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,noteType,content,isPinned,isArchived,background,state,updatedAt,const DeepCollectionEquality().hash(_tagIds),permission,const DeepCollectionEquality().hash(_shareIds),sharedBy,reminder,isSynced,reminderSlot,const DeepCollectionEquality().hash(_imagePreviewData),attachmentCount);

@override
String toString() {
  return 'Note(id: $id, title: $title, noteType: $noteType, content: $content, isPinned: $isPinned, isArchived: $isArchived, background: $background, state: $state, updatedAt: $updatedAt, tagIds: $tagIds, permission: $permission, shareIds: $shareIds, sharedBy: $sharedBy, reminder: $reminder, isSynced: $isSynced, reminderSlot: $reminderSlot, imagePreviewData: $imagePreviewData, attachmentCount: $attachmentCount)';
}


}

/// @nodoc
abstract mixin class _$NoteCopyWith<$Res> implements $NoteCopyWith<$Res> {
  factory _$NoteCopyWith(_Note value, $Res Function(_Note) _then) = __$NoteCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, NoteType noteType, String? content, bool isPinned, bool isArchived, String? background, NoteState state, DateTime? updatedAt, List<String> tagIds, NotePermission permission, List<String>? shareIds, UserSummary? sharedBy, NoteReminder? reminder, bool isSynced, int? reminderSlot, List<NoteImagePreview> imagePreviewData, int attachmentCount
});


@override $UserSummaryCopyWith<$Res>? get sharedBy;@override $NoteReminderCopyWith<$Res>? get reminder;

}
/// @nodoc
class __$NoteCopyWithImpl<$Res>
    implements _$NoteCopyWith<$Res> {
  __$NoteCopyWithImpl(this._self, this._then);

  final _Note _self;
  final $Res Function(_Note) _then;

/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? noteType = null,Object? content = freezed,Object? isPinned = null,Object? isArchived = null,Object? background = freezed,Object? state = null,Object? updatedAt = freezed,Object? tagIds = null,Object? permission = null,Object? shareIds = freezed,Object? sharedBy = freezed,Object? reminder = freezed,Object? isSynced = null,Object? reminderSlot = freezed,Object? imagePreviewData = null,Object? attachmentCount = null,}) {
  return _then(_Note(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,noteType: null == noteType ? _self.noteType : noteType // ignore: cast_nullable_to_non_nullable
as NoteType,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as NoteState,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,tagIds: null == tagIds ? _self._tagIds : tagIds // ignore: cast_nullable_to_non_nullable
as List<String>,permission: null == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as NotePermission,shareIds: freezed == shareIds ? _self._shareIds : shareIds // ignore: cast_nullable_to_non_nullable
as List<String>?,sharedBy: freezed == sharedBy ? _self.sharedBy : sharedBy // ignore: cast_nullable_to_non_nullable
as UserSummary?,reminder: freezed == reminder ? _self.reminder : reminder // ignore: cast_nullable_to_non_nullable
as NoteReminder?,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,reminderSlot: freezed == reminderSlot ? _self.reminderSlot : reminderSlot // ignore: cast_nullable_to_non_nullable
as int?,imagePreviewData: null == imagePreviewData ? _self._imagePreviewData : imagePreviewData // ignore: cast_nullable_to_non_nullable
as List<NoteImagePreview>,attachmentCount: null == attachmentCount ? _self.attachmentCount : attachmentCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSummaryCopyWith<$Res>? get sharedBy {
    if (_self.sharedBy == null) {
    return null;
  }

  return $UserSummaryCopyWith<$Res>(_self.sharedBy!, (value) {
    return _then(_self.copyWith(sharedBy: value));
  });
}/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NoteReminderCopyWith<$Res>? get reminder {
    if (_self.reminder == null) {
    return null;
  }

  return $NoteReminderCopyWith<$Res>(_self.reminder!, (value) {
    return _then(_self.copyWith(reminder: value));
  });
}
}

// dart format on
