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

  /// Serializes this NoteReminder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoteReminder&&(identical(other.remindAt, remindAt) || other.remindAt == remindAt)&&(identical(other.recurrence, recurrence) || other.recurrence == recurrence)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
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
@JsonSerializable()

class _NoteReminder extends NoteReminder {
  const _NoteReminder({required this.remindAt, this.recurrence = ReminderRecurrence.none, this.version = 0}): super._();
  factory _NoteReminder.fromJson(Map<String, dynamic> json) => _$NoteReminderFromJson(json);

@override final  String remindAt;
@override@JsonKey() final  ReminderRecurrence recurrence;
@override@JsonKey() final  int version;

/// Create a copy of NoteReminder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NoteReminderCopyWith<_NoteReminder> get copyWith => __$NoteReminderCopyWithImpl<_NoteReminder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NoteReminderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NoteReminder&&(identical(other.remindAt, remindAt) || other.remindAt == remindAt)&&(identical(other.recurrence, recurrence) || other.recurrence == recurrence)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
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
mixin _$SharedByUser {

 String get id; String get name; String get email; String? get profileImage;
/// Create a copy of SharedByUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SharedByUserCopyWith<SharedByUser> get copyWith => _$SharedByUserCopyWithImpl<SharedByUser>(this as SharedByUser, _$identity);

  /// Serializes this SharedByUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SharedByUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.profileImage, profileImage) || other.profileImage == profileImage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email,profileImage);

@override
String toString() {
  return 'SharedByUser(id: $id, name: $name, email: $email, profileImage: $profileImage)';
}


}

/// @nodoc
abstract mixin class $SharedByUserCopyWith<$Res>  {
  factory $SharedByUserCopyWith(SharedByUser value, $Res Function(SharedByUser) _then) = _$SharedByUserCopyWithImpl;
@useResult
$Res call({
 String id, String name, String email, String? profileImage
});




}
/// @nodoc
class _$SharedByUserCopyWithImpl<$Res>
    implements $SharedByUserCopyWith<$Res> {
  _$SharedByUserCopyWithImpl(this._self, this._then);

  final SharedByUser _self;
  final $Res Function(SharedByUser) _then;

/// Create a copy of SharedByUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? email = null,Object? profileImage = freezed,}) {
  return _then(SharedByUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,profileImage: freezed == profileImage ? _self.profileImage : profileImage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SharedByUser].
extension SharedByUserPatterns on SharedByUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SharedByUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SharedByUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SharedByUser value)  $default,){
final _that = this;
switch (_that) {
case _SharedByUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SharedByUser value)?  $default,){
final _that = this;
switch (_that) {
case _SharedByUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String email,  String? profileImage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SharedByUser() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.profileImage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String email,  String? profileImage)  $default,) {final _that = this;
switch (_that) {
case _SharedByUser():
return $default(_that.id,_that.name,_that.email,_that.profileImage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String email,  String? profileImage)?  $default,) {final _that = this;
switch (_that) {
case _SharedByUser() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.profileImage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SharedByUser implements SharedByUser {
  const _SharedByUser({required this.id, required this.name, required this.email, this.profileImage});
  factory _SharedByUser.fromJson(Map<String, dynamic> json) => _$SharedByUserFromJson(json);

@override final  String id;
@override final  String name;
@override final  String email;
@override final  String? profileImage;

/// Create a copy of SharedByUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SharedByUserCopyWith<_SharedByUser> get copyWith => __$SharedByUserCopyWithImpl<_SharedByUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SharedByUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SharedByUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.profileImage, profileImage) || other.profileImage == profileImage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email,profileImage);

@override
String toString() {
  return 'SharedByUser(id: $id, name: $name, email: $email, profileImage: $profileImage)';
}


}

/// @nodoc
abstract mixin class _$SharedByUserCopyWith<$Res> implements $SharedByUserCopyWith<$Res> {
  factory _$SharedByUserCopyWith(_SharedByUser value, $Res Function(_SharedByUser) _then) = __$SharedByUserCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String email, String? profileImage
});




}
/// @nodoc
class __$SharedByUserCopyWithImpl<$Res>
    implements _$SharedByUserCopyWith<$Res> {
  __$SharedByUserCopyWithImpl(this._self, this._then);

  final _SharedByUser _self;
  final $Res Function(_SharedByUser) _then;

/// Create a copy of SharedByUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? email = null,Object? profileImage = freezed,}) {
  return _then(_SharedByUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,profileImage: freezed == profileImage ? _self.profileImage : profileImage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Note {

 String get id; String get title; String? get content; bool get isPinned; bool get isArchived; String? get background; NoteState get state; DateTime? get updatedAt; List<String> get tagIds; NotePermission get permission; List<String>? get shareIds; SharedByUser? get sharedBy; NoteReminder? get reminder;@JsonKey(includeFromJson: false, includeToJson: false) bool get isSynced;@JsonKey(includeFromJson: false, includeToJson: false) int? get reminderSlot;@JsonKey(includeFromJson: false, includeToJson: false) List<NoteImagePreview> get imagePreviewData;
/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoteCopyWith<Note> get copyWith => _$NoteCopyWithImpl<Note>(this as Note, _$identity);

  /// Serializes this Note to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Note&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.background, background) || other.background == background)&&(identical(other.state, state) || other.state == state)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.tagIds, tagIds)&&(identical(other.permission, permission) || other.permission == permission)&&const DeepCollectionEquality().equals(other.shareIds, shareIds)&&(identical(other.sharedBy, sharedBy) || other.sharedBy == sharedBy)&&(identical(other.reminder, reminder) || other.reminder == reminder)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced)&&(identical(other.reminderSlot, reminderSlot) || other.reminderSlot == reminderSlot)&&const DeepCollectionEquality().equals(other.imagePreviewData, imagePreviewData));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,content,isPinned,isArchived,background,state,updatedAt,const DeepCollectionEquality().hash(tagIds),permission,const DeepCollectionEquality().hash(shareIds),sharedBy,reminder,isSynced,reminderSlot,const DeepCollectionEquality().hash(imagePreviewData));

@override
String toString() {
  return 'Note(id: $id, title: $title, content: $content, isPinned: $isPinned, isArchived: $isArchived, background: $background, state: $state, updatedAt: $updatedAt, tagIds: $tagIds, permission: $permission, shareIds: $shareIds, sharedBy: $sharedBy, reminder: $reminder, isSynced: $isSynced, reminderSlot: $reminderSlot, imagePreviewData: $imagePreviewData)';
}


}

/// @nodoc
abstract mixin class $NoteCopyWith<$Res>  {
  factory $NoteCopyWith(Note value, $Res Function(Note) _then) = _$NoteCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? content, bool isPinned, bool isArchived, String? background, NoteState state, DateTime? updatedAt, List<String> tagIds, NotePermission permission, List<String>? shareIds, SharedByUser? sharedBy, NoteReminder? reminder,@JsonKey(includeFromJson: false, includeToJson: false) bool isSynced,@JsonKey(includeFromJson: false, includeToJson: false) int? reminderSlot,@JsonKey(includeFromJson: false, includeToJson: false) List<NoteImagePreview> imagePreviewData
});


$SharedByUserCopyWith<$Res>? get sharedBy;$NoteReminderCopyWith<$Res>? get reminder;

}
/// @nodoc
class _$NoteCopyWithImpl<$Res>
    implements $NoteCopyWith<$Res> {
  _$NoteCopyWithImpl(this._self, this._then);

  final Note _self;
  final $Res Function(Note) _then;

/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? content = freezed,Object? isPinned = null,Object? isArchived = null,Object? background = freezed,Object? state = null,Object? updatedAt = freezed,Object? tagIds = null,Object? permission = null,Object? shareIds = freezed,Object? sharedBy = freezed,Object? reminder = freezed,Object? isSynced = null,Object? reminderSlot = freezed,Object? imagePreviewData = null,}) {
  return _then(Note(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as NoteState,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,tagIds: null == tagIds ? _self.tagIds : tagIds // ignore: cast_nullable_to_non_nullable
as List<String>,permission: null == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as NotePermission,shareIds: freezed == shareIds ? _self.shareIds : shareIds // ignore: cast_nullable_to_non_nullable
as List<String>?,sharedBy: freezed == sharedBy ? _self.sharedBy : sharedBy // ignore: cast_nullable_to_non_nullable
as SharedByUser?,reminder: freezed == reminder ? _self.reminder : reminder // ignore: cast_nullable_to_non_nullable
as NoteReminder?,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,reminderSlot: freezed == reminderSlot ? _self.reminderSlot : reminderSlot // ignore: cast_nullable_to_non_nullable
as int?,imagePreviewData: null == imagePreviewData ? _self.imagePreviewData : imagePreviewData // ignore: cast_nullable_to_non_nullable
as List<NoteImagePreview>,
  ));
}
/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SharedByUserCopyWith<$Res>? get sharedBy {
    if (_self.sharedBy == null) {
    return null;
  }

  return $SharedByUserCopyWith<$Res>(_self.sharedBy!, (value) {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? content,  bool isPinned,  bool isArchived,  String? background,  NoteState state,  DateTime? updatedAt,  List<String> tagIds,  NotePermission permission,  List<String>? shareIds,  SharedByUser? sharedBy,  NoteReminder? reminder, @JsonKey(includeFromJson: false, includeToJson: false)  bool isSynced, @JsonKey(includeFromJson: false, includeToJson: false)  int? reminderSlot, @JsonKey(includeFromJson: false, includeToJson: false)  List<NoteImagePreview> imagePreviewData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Note() when $default != null:
return $default(_that.id,_that.title,_that.content,_that.isPinned,_that.isArchived,_that.background,_that.state,_that.updatedAt,_that.tagIds,_that.permission,_that.shareIds,_that.sharedBy,_that.reminder,_that.isSynced,_that.reminderSlot,_that.imagePreviewData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? content,  bool isPinned,  bool isArchived,  String? background,  NoteState state,  DateTime? updatedAt,  List<String> tagIds,  NotePermission permission,  List<String>? shareIds,  SharedByUser? sharedBy,  NoteReminder? reminder, @JsonKey(includeFromJson: false, includeToJson: false)  bool isSynced, @JsonKey(includeFromJson: false, includeToJson: false)  int? reminderSlot, @JsonKey(includeFromJson: false, includeToJson: false)  List<NoteImagePreview> imagePreviewData)  $default,) {final _that = this;
switch (_that) {
case _Note():
return $default(_that.id,_that.title,_that.content,_that.isPinned,_that.isArchived,_that.background,_that.state,_that.updatedAt,_that.tagIds,_that.permission,_that.shareIds,_that.sharedBy,_that.reminder,_that.isSynced,_that.reminderSlot,_that.imagePreviewData);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? content,  bool isPinned,  bool isArchived,  String? background,  NoteState state,  DateTime? updatedAt,  List<String> tagIds,  NotePermission permission,  List<String>? shareIds,  SharedByUser? sharedBy,  NoteReminder? reminder, @JsonKey(includeFromJson: false, includeToJson: false)  bool isSynced, @JsonKey(includeFromJson: false, includeToJson: false)  int? reminderSlot, @JsonKey(includeFromJson: false, includeToJson: false)  List<NoteImagePreview> imagePreviewData)?  $default,) {final _that = this;
switch (_that) {
case _Note() when $default != null:
return $default(_that.id,_that.title,_that.content,_that.isPinned,_that.isArchived,_that.background,_that.state,_that.updatedAt,_that.tagIds,_that.permission,_that.shareIds,_that.sharedBy,_that.reminder,_that.isSynced,_that.reminderSlot,_that.imagePreviewData);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Note extends Note {
  const _Note({required this.id, required this.title, this.content, this.isPinned = false, this.isArchived = false, this.background, this.state = NoteState.active, this.updatedAt,  List<String> tagIds = const [], this.permission = NotePermission.owner,  List<String>? shareIds, this.sharedBy, this.reminder, @JsonKey(includeFromJson: false, includeToJson: false) this.isSynced = true, @JsonKey(includeFromJson: false, includeToJson: false) this.reminderSlot, @JsonKey(includeFromJson: false, includeToJson: false)  List<NoteImagePreview> imagePreviewData = const []}): _tagIds = tagIds,_shareIds = shareIds,_imagePreviewData = imagePreviewData,super._();
  factory _Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);

@override final  String id;
@override final  String title;
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

@override final  SharedByUser? sharedBy;
@override final  NoteReminder? reminder;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  bool isSynced;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  int? reminderSlot;
 final  List<NoteImagePreview> _imagePreviewData;
@override@JsonKey(includeFromJson: false, includeToJson: false) List<NoteImagePreview> get imagePreviewData {
  if (_imagePreviewData is EqualUnmodifiableListView) return _imagePreviewData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_imagePreviewData);
}


/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NoteCopyWith<_Note> get copyWith => __$NoteCopyWithImpl<_Note>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NoteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Note&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.background, background) || other.background == background)&&(identical(other.state, state) || other.state == state)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._tagIds, _tagIds)&&(identical(other.permission, permission) || other.permission == permission)&&const DeepCollectionEquality().equals(other._shareIds, _shareIds)&&(identical(other.sharedBy, sharedBy) || other.sharedBy == sharedBy)&&(identical(other.reminder, reminder) || other.reminder == reminder)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced)&&(identical(other.reminderSlot, reminderSlot) || other.reminderSlot == reminderSlot)&&const DeepCollectionEquality().equals(other._imagePreviewData, _imagePreviewData));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,content,isPinned,isArchived,background,state,updatedAt,const DeepCollectionEquality().hash(_tagIds),permission,const DeepCollectionEquality().hash(_shareIds),sharedBy,reminder,isSynced,reminderSlot,const DeepCollectionEquality().hash(_imagePreviewData));

@override
String toString() {
  return 'Note(id: $id, title: $title, content: $content, isPinned: $isPinned, isArchived: $isArchived, background: $background, state: $state, updatedAt: $updatedAt, tagIds: $tagIds, permission: $permission, shareIds: $shareIds, sharedBy: $sharedBy, reminder: $reminder, isSynced: $isSynced, reminderSlot: $reminderSlot, imagePreviewData: $imagePreviewData)';
}


}

/// @nodoc
abstract mixin class _$NoteCopyWith<$Res> implements $NoteCopyWith<$Res> {
  factory _$NoteCopyWith(_Note value, $Res Function(_Note) _then) = __$NoteCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? content, bool isPinned, bool isArchived, String? background, NoteState state, DateTime? updatedAt, List<String> tagIds, NotePermission permission, List<String>? shareIds, SharedByUser? sharedBy, NoteReminder? reminder,@JsonKey(includeFromJson: false, includeToJson: false) bool isSynced,@JsonKey(includeFromJson: false, includeToJson: false) int? reminderSlot,@JsonKey(includeFromJson: false, includeToJson: false) List<NoteImagePreview> imagePreviewData
});


@override $SharedByUserCopyWith<$Res>? get sharedBy;@override $NoteReminderCopyWith<$Res>? get reminder;

}
/// @nodoc
class __$NoteCopyWithImpl<$Res>
    implements _$NoteCopyWith<$Res> {
  __$NoteCopyWithImpl(this._self, this._then);

  final _Note _self;
  final $Res Function(_Note) _then;

/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? content = freezed,Object? isPinned = null,Object? isArchived = null,Object? background = freezed,Object? state = null,Object? updatedAt = freezed,Object? tagIds = null,Object? permission = null,Object? shareIds = freezed,Object? sharedBy = freezed,Object? reminder = freezed,Object? isSynced = null,Object? reminderSlot = freezed,Object? imagePreviewData = null,}) {
  return _then(_Note(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,isPinned: null == isPinned ? _self.isPinned : isPinned // ignore: cast_nullable_to_non_nullable
as bool,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as NoteState,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,tagIds: null == tagIds ? _self._tagIds : tagIds // ignore: cast_nullable_to_non_nullable
as List<String>,permission: null == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as NotePermission,shareIds: freezed == shareIds ? _self._shareIds : shareIds // ignore: cast_nullable_to_non_nullable
as List<String>?,sharedBy: freezed == sharedBy ? _self.sharedBy : sharedBy // ignore: cast_nullable_to_non_nullable
as SharedByUser?,reminder: freezed == reminder ? _self.reminder : reminder // ignore: cast_nullable_to_non_nullable
as NoteReminder?,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,reminderSlot: freezed == reminderSlot ? _self.reminderSlot : reminderSlot // ignore: cast_nullable_to_non_nullable
as int?,imagePreviewData: null == imagePreviewData ? _self._imagePreviewData : imagePreviewData // ignore: cast_nullable_to_non_nullable
as List<NoteImagePreview>,
  ));
}

/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SharedByUserCopyWith<$Res>? get sharedBy {
    if (_self.sharedBy == null) {
    return null;
  }

  return $SharedByUserCopyWith<$Res>(_self.sharedBy!, (value) {
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
