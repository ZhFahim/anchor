// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'note.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

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
  return _then(_self.copyWith(
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

 String get id; String get title; String? get content; bool get isPinned; bool get isArchived; String? get background; NoteState get state; DateTime? get updatedAt; List<String> get tagIds; NotePermission get permission; List<String>? get shareIds; SharedByUser? get sharedBy;// Local only - not serialized
@JsonKey(includeFromJson: false, includeToJson: false) bool get isSynced;
/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoteCopyWith<Note> get copyWith => _$NoteCopyWithImpl<Note>(this as Note, _$identity);

  /// Serializes this Note to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Note&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.background, background) || other.background == background)&&(identical(other.state, state) || other.state == state)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.tagIds, tagIds)&&(identical(other.permission, permission) || other.permission == permission)&&const DeepCollectionEquality().equals(other.shareIds, shareIds)&&(identical(other.sharedBy, sharedBy) || other.sharedBy == sharedBy)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,content,isPinned,isArchived,background,state,updatedAt,const DeepCollectionEquality().hash(tagIds),permission,const DeepCollectionEquality().hash(shareIds),sharedBy,isSynced);

@override
String toString() {
  return 'Note(id: $id, title: $title, content: $content, isPinned: $isPinned, isArchived: $isArchived, background: $background, state: $state, updatedAt: $updatedAt, tagIds: $tagIds, permission: $permission, shareIds: $shareIds, sharedBy: $sharedBy, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class $NoteCopyWith<$Res>  {
  factory $NoteCopyWith(Note value, $Res Function(Note) _then) = _$NoteCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? content, bool isPinned, bool isArchived, String? background, NoteState state, DateTime? updatedAt, List<String> tagIds, NotePermission permission, List<String>? shareIds, SharedByUser? sharedBy,@JsonKey(includeFromJson: false, includeToJson: false) bool isSynced
});


$SharedByUserCopyWith<$Res>? get sharedBy;

}
/// @nodoc
class _$NoteCopyWithImpl<$Res>
    implements $NoteCopyWith<$Res> {
  _$NoteCopyWithImpl(this._self, this._then);

  final Note _self;
  final $Res Function(Note) _then;

/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? content = freezed,Object? isPinned = null,Object? isArchived = null,Object? background = freezed,Object? state = null,Object? updatedAt = freezed,Object? tagIds = null,Object? permission = null,Object? shareIds = freezed,Object? sharedBy = freezed,Object? isSynced = null,}) {
  return _then(_self.copyWith(
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
as SharedByUser?,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? content,  bool isPinned,  bool isArchived,  String? background,  NoteState state,  DateTime? updatedAt,  List<String> tagIds,  NotePermission permission,  List<String>? shareIds,  SharedByUser? sharedBy, @JsonKey(includeFromJson: false, includeToJson: false)  bool isSynced)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Note() when $default != null:
return $default(_that.id,_that.title,_that.content,_that.isPinned,_that.isArchived,_that.background,_that.state,_that.updatedAt,_that.tagIds,_that.permission,_that.shareIds,_that.sharedBy,_that.isSynced);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? content,  bool isPinned,  bool isArchived,  String? background,  NoteState state,  DateTime? updatedAt,  List<String> tagIds,  NotePermission permission,  List<String>? shareIds,  SharedByUser? sharedBy, @JsonKey(includeFromJson: false, includeToJson: false)  bool isSynced)  $default,) {final _that = this;
switch (_that) {
case _Note():
return $default(_that.id,_that.title,_that.content,_that.isPinned,_that.isArchived,_that.background,_that.state,_that.updatedAt,_that.tagIds,_that.permission,_that.shareIds,_that.sharedBy,_that.isSynced);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? content,  bool isPinned,  bool isArchived,  String? background,  NoteState state,  DateTime? updatedAt,  List<String> tagIds,  NotePermission permission,  List<String>? shareIds,  SharedByUser? sharedBy, @JsonKey(includeFromJson: false, includeToJson: false)  bool isSynced)?  $default,) {final _that = this;
switch (_that) {
case _Note() when $default != null:
return $default(_that.id,_that.title,_that.content,_that.isPinned,_that.isArchived,_that.background,_that.state,_that.updatedAt,_that.tagIds,_that.permission,_that.shareIds,_that.sharedBy,_that.isSynced);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Note extends Note {
  const _Note({required this.id, required this.title, this.content, this.isPinned = false, this.isArchived = false, this.background, this.state = NoteState.active, this.updatedAt, final  List<String> tagIds = const [], this.permission = NotePermission.owner, final  List<String>? shareIds, this.sharedBy, @JsonKey(includeFromJson: false, includeToJson: false) this.isSynced = true}): _tagIds = tagIds,_shareIds = shareIds,super._();
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
// Local only - not serialized
@override@JsonKey(includeFromJson: false, includeToJson: false) final  bool isSynced;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Note&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.isPinned, isPinned) || other.isPinned == isPinned)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.background, background) || other.background == background)&&(identical(other.state, state) || other.state == state)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._tagIds, _tagIds)&&(identical(other.permission, permission) || other.permission == permission)&&const DeepCollectionEquality().equals(other._shareIds, _shareIds)&&(identical(other.sharedBy, sharedBy) || other.sharedBy == sharedBy)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,content,isPinned,isArchived,background,state,updatedAt,const DeepCollectionEquality().hash(_tagIds),permission,const DeepCollectionEquality().hash(_shareIds),sharedBy,isSynced);

@override
String toString() {
  return 'Note(id: $id, title: $title, content: $content, isPinned: $isPinned, isArchived: $isArchived, background: $background, state: $state, updatedAt: $updatedAt, tagIds: $tagIds, permission: $permission, shareIds: $shareIds, sharedBy: $sharedBy, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class _$NoteCopyWith<$Res> implements $NoteCopyWith<$Res> {
  factory _$NoteCopyWith(_Note value, $Res Function(_Note) _then) = __$NoteCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? content, bool isPinned, bool isArchived, String? background, NoteState state, DateTime? updatedAt, List<String> tagIds, NotePermission permission, List<String>? shareIds, SharedByUser? sharedBy,@JsonKey(includeFromJson: false, includeToJson: false) bool isSynced
});


@override $SharedByUserCopyWith<$Res>? get sharedBy;

}
/// @nodoc
class __$NoteCopyWithImpl<$Res>
    implements _$NoteCopyWith<$Res> {
  __$NoteCopyWithImpl(this._self, this._then);

  final _Note _self;
  final $Res Function(_Note) _then;

/// Create a copy of Note
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? content = freezed,Object? isPinned = null,Object? isArchived = null,Object? background = freezed,Object? state = null,Object? updatedAt = freezed,Object? tagIds = null,Object? permission = null,Object? shareIds = freezed,Object? sharedBy = freezed,Object? isSynced = null,}) {
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
as SharedByUser?,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
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
}
}

// dart format on
