// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'note_revision.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NoteRevisionAuthor {

 String get id; String get name; String get email; String? get profileImage;
/// Create a copy of NoteRevisionAuthor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoteRevisionAuthorCopyWith<NoteRevisionAuthor> get copyWith => _$NoteRevisionAuthorCopyWithImpl<NoteRevisionAuthor>(this as NoteRevisionAuthor, _$identity);

  /// Serializes this NoteRevisionAuthor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoteRevisionAuthor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.profileImage, profileImage) || other.profileImage == profileImage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email,profileImage);

@override
String toString() {
  return 'NoteRevisionAuthor(id: $id, name: $name, email: $email, profileImage: $profileImage)';
}


}

/// @nodoc
abstract mixin class $NoteRevisionAuthorCopyWith<$Res>  {
  factory $NoteRevisionAuthorCopyWith(NoteRevisionAuthor value, $Res Function(NoteRevisionAuthor) _then) = _$NoteRevisionAuthorCopyWithImpl;
@useResult
$Res call({
 String id, String name, String email, String? profileImage
});




}
/// @nodoc
class _$NoteRevisionAuthorCopyWithImpl<$Res>
    implements $NoteRevisionAuthorCopyWith<$Res> {
  _$NoteRevisionAuthorCopyWithImpl(this._self, this._then);

  final NoteRevisionAuthor _self;
  final $Res Function(NoteRevisionAuthor) _then;

/// Create a copy of NoteRevisionAuthor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? email = null,Object? profileImage = freezed,}) {
  return _then(NoteRevisionAuthor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,profileImage: freezed == profileImage ? _self.profileImage : profileImage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NoteRevisionAuthor].
extension NoteRevisionAuthorPatterns on NoteRevisionAuthor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NoteRevisionAuthor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NoteRevisionAuthor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NoteRevisionAuthor value)  $default,){
final _that = this;
switch (_that) {
case _NoteRevisionAuthor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NoteRevisionAuthor value)?  $default,){
final _that = this;
switch (_that) {
case _NoteRevisionAuthor() when $default != null:
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
case _NoteRevisionAuthor() when $default != null:
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
case _NoteRevisionAuthor():
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
case _NoteRevisionAuthor() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.profileImage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NoteRevisionAuthor implements NoteRevisionAuthor {
  const _NoteRevisionAuthor({required this.id, required this.name, required this.email, this.profileImage});
  factory _NoteRevisionAuthor.fromJson(Map<String, dynamic> json) => _$NoteRevisionAuthorFromJson(json);

@override final  String id;
@override final  String name;
@override final  String email;
@override final  String? profileImage;

/// Create a copy of NoteRevisionAuthor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NoteRevisionAuthorCopyWith<_NoteRevisionAuthor> get copyWith => __$NoteRevisionAuthorCopyWithImpl<_NoteRevisionAuthor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NoteRevisionAuthorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NoteRevisionAuthor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.profileImage, profileImage) || other.profileImage == profileImage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email,profileImage);

@override
String toString() {
  return 'NoteRevisionAuthor(id: $id, name: $name, email: $email, profileImage: $profileImage)';
}


}

/// @nodoc
abstract mixin class _$NoteRevisionAuthorCopyWith<$Res> implements $NoteRevisionAuthorCopyWith<$Res> {
  factory _$NoteRevisionAuthorCopyWith(_NoteRevisionAuthor value, $Res Function(_NoteRevisionAuthor) _then) = __$NoteRevisionAuthorCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String email, String? profileImage
});




}
/// @nodoc
class __$NoteRevisionAuthorCopyWithImpl<$Res>
    implements _$NoteRevisionAuthorCopyWith<$Res> {
  __$NoteRevisionAuthorCopyWithImpl(this._self, this._then);

  final _NoteRevisionAuthor _self;
  final $Res Function(_NoteRevisionAuthor) _then;

/// Create a copy of NoteRevisionAuthor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? email = null,Object? profileImage = freezed,}) {
  return _then(_NoteRevisionAuthor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,profileImage: freezed == profileImage ? _self.profileImage : profileImage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$NoteRevision {

 String get id; String get noteId; int get version; String get title;@JsonKey(unknownEnumValue: RevisionCause.edit) RevisionCause get cause; DateTime get createdAt; NoteRevisionAuthor? get author; String? get content;
/// Create a copy of NoteRevision
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoteRevisionCopyWith<NoteRevision> get copyWith => _$NoteRevisionCopyWithImpl<NoteRevision>(this as NoteRevision, _$identity);

  /// Serializes this NoteRevision to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoteRevision&&(identical(other.id, id) || other.id == id)&&(identical(other.noteId, noteId) || other.noteId == noteId)&&(identical(other.version, version) || other.version == version)&&(identical(other.title, title) || other.title == title)&&(identical(other.cause, cause) || other.cause == cause)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.author, author) || other.author == author)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,noteId,version,title,cause,createdAt,author,content);

@override
String toString() {
  return 'NoteRevision(id: $id, noteId: $noteId, version: $version, title: $title, cause: $cause, createdAt: $createdAt, author: $author, content: $content)';
}


}

/// @nodoc
abstract mixin class $NoteRevisionCopyWith<$Res>  {
  factory $NoteRevisionCopyWith(NoteRevision value, $Res Function(NoteRevision) _then) = _$NoteRevisionCopyWithImpl;
@useResult
$Res call({
 String id, String noteId, int version, String title,@JsonKey(unknownEnumValue: RevisionCause.edit) RevisionCause cause, DateTime createdAt, NoteRevisionAuthor? author, String? content
});


$NoteRevisionAuthorCopyWith<$Res>? get author;

}
/// @nodoc
class _$NoteRevisionCopyWithImpl<$Res>
    implements $NoteRevisionCopyWith<$Res> {
  _$NoteRevisionCopyWithImpl(this._self, this._then);

  final NoteRevision _self;
  final $Res Function(NoteRevision) _then;

/// Create a copy of NoteRevision
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? noteId = null,Object? version = null,Object? title = null,Object? cause = null,Object? createdAt = null,Object? author = freezed,Object? content = freezed,}) {
  return _then(NoteRevision(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,noteId: null == noteId ? _self.noteId : noteId // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cause: null == cause ? _self.cause : cause // ignore: cast_nullable_to_non_nullable
as RevisionCause,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as NoteRevisionAuthor?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of NoteRevision
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NoteRevisionAuthorCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $NoteRevisionAuthorCopyWith<$Res>(_self.author!, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// Adds pattern-matching-related methods to [NoteRevision].
extension NoteRevisionPatterns on NoteRevision {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NoteRevision value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NoteRevision() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NoteRevision value)  $default,){
final _that = this;
switch (_that) {
case _NoteRevision():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NoteRevision value)?  $default,){
final _that = this;
switch (_that) {
case _NoteRevision() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String noteId,  int version,  String title, @JsonKey(unknownEnumValue: RevisionCause.edit)  RevisionCause cause,  DateTime createdAt,  NoteRevisionAuthor? author,  String? content)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NoteRevision() when $default != null:
return $default(_that.id,_that.noteId,_that.version,_that.title,_that.cause,_that.createdAt,_that.author,_that.content);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String noteId,  int version,  String title, @JsonKey(unknownEnumValue: RevisionCause.edit)  RevisionCause cause,  DateTime createdAt,  NoteRevisionAuthor? author,  String? content)  $default,) {final _that = this;
switch (_that) {
case _NoteRevision():
return $default(_that.id,_that.noteId,_that.version,_that.title,_that.cause,_that.createdAt,_that.author,_that.content);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String noteId,  int version,  String title, @JsonKey(unknownEnumValue: RevisionCause.edit)  RevisionCause cause,  DateTime createdAt,  NoteRevisionAuthor? author,  String? content)?  $default,) {final _that = this;
switch (_that) {
case _NoteRevision() when $default != null:
return $default(_that.id,_that.noteId,_that.version,_that.title,_that.cause,_that.createdAt,_that.author,_that.content);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NoteRevision extends NoteRevision {
  const _NoteRevision({required this.id, required this.noteId, required this.version, required this.title, @JsonKey(unknownEnumValue: RevisionCause.edit) required this.cause, required this.createdAt, this.author, this.content}): super._();
  factory _NoteRevision.fromJson(Map<String, dynamic> json) => _$NoteRevisionFromJson(json);

@override final  String id;
@override final  String noteId;
@override final  int version;
@override final  String title;
@override@JsonKey(unknownEnumValue: RevisionCause.edit) final  RevisionCause cause;
@override final  DateTime createdAt;
@override final  NoteRevisionAuthor? author;
@override final  String? content;

/// Create a copy of NoteRevision
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NoteRevisionCopyWith<_NoteRevision> get copyWith => __$NoteRevisionCopyWithImpl<_NoteRevision>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NoteRevisionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NoteRevision&&(identical(other.id, id) || other.id == id)&&(identical(other.noteId, noteId) || other.noteId == noteId)&&(identical(other.version, version) || other.version == version)&&(identical(other.title, title) || other.title == title)&&(identical(other.cause, cause) || other.cause == cause)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.author, author) || other.author == author)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,noteId,version,title,cause,createdAt,author,content);

@override
String toString() {
  return 'NoteRevision(id: $id, noteId: $noteId, version: $version, title: $title, cause: $cause, createdAt: $createdAt, author: $author, content: $content)';
}


}

/// @nodoc
abstract mixin class _$NoteRevisionCopyWith<$Res> implements $NoteRevisionCopyWith<$Res> {
  factory _$NoteRevisionCopyWith(_NoteRevision value, $Res Function(_NoteRevision) _then) = __$NoteRevisionCopyWithImpl;
@override @useResult
$Res call({
 String id, String noteId, int version, String title,@JsonKey(unknownEnumValue: RevisionCause.edit) RevisionCause cause, DateTime createdAt, NoteRevisionAuthor? author, String? content
});


@override $NoteRevisionAuthorCopyWith<$Res>? get author;

}
/// @nodoc
class __$NoteRevisionCopyWithImpl<$Res>
    implements _$NoteRevisionCopyWith<$Res> {
  __$NoteRevisionCopyWithImpl(this._self, this._then);

  final _NoteRevision _self;
  final $Res Function(_NoteRevision) _then;

/// Create a copy of NoteRevision
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? noteId = null,Object? version = null,Object? title = null,Object? cause = null,Object? createdAt = null,Object? author = freezed,Object? content = freezed,}) {
  return _then(_NoteRevision(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,noteId: null == noteId ? _self.noteId : noteId // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cause: null == cause ? _self.cause : cause // ignore: cast_nullable_to_non_nullable
as RevisionCause,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as NoteRevisionAuthor?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of NoteRevision
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NoteRevisionAuthorCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $NoteRevisionAuthorCopyWith<$Res>(_self.author!, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// @nodoc
mixin _$NoteRevisionPage {

 List<NoteRevision> get revisions; String? get nextCursor;
/// Create a copy of NoteRevisionPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoteRevisionPageCopyWith<NoteRevisionPage> get copyWith => _$NoteRevisionPageCopyWithImpl<NoteRevisionPage>(this as NoteRevisionPage, _$identity);

  /// Serializes this NoteRevisionPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoteRevisionPage&&const DeepCollectionEquality().equals(other.revisions, revisions)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(revisions),nextCursor);

@override
String toString() {
  return 'NoteRevisionPage(revisions: $revisions, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $NoteRevisionPageCopyWith<$Res>  {
  factory $NoteRevisionPageCopyWith(NoteRevisionPage value, $Res Function(NoteRevisionPage) _then) = _$NoteRevisionPageCopyWithImpl;
@useResult
$Res call({
 List<NoteRevision> revisions, String? nextCursor
});




}
/// @nodoc
class _$NoteRevisionPageCopyWithImpl<$Res>
    implements $NoteRevisionPageCopyWith<$Res> {
  _$NoteRevisionPageCopyWithImpl(this._self, this._then);

  final NoteRevisionPage _self;
  final $Res Function(NoteRevisionPage) _then;

/// Create a copy of NoteRevisionPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? revisions = null,Object? nextCursor = freezed,}) {
  return _then(NoteRevisionPage(
revisions: null == revisions ? _self.revisions : revisions // ignore: cast_nullable_to_non_nullable
as List<NoteRevision>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NoteRevisionPage].
extension NoteRevisionPagePatterns on NoteRevisionPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NoteRevisionPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NoteRevisionPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NoteRevisionPage value)  $default,){
final _that = this;
switch (_that) {
case _NoteRevisionPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NoteRevisionPage value)?  $default,){
final _that = this;
switch (_that) {
case _NoteRevisionPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<NoteRevision> revisions,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NoteRevisionPage() when $default != null:
return $default(_that.revisions,_that.nextCursor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<NoteRevision> revisions,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _NoteRevisionPage():
return $default(_that.revisions,_that.nextCursor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<NoteRevision> revisions,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _NoteRevisionPage() when $default != null:
return $default(_that.revisions,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NoteRevisionPage implements NoteRevisionPage {
  const _NoteRevisionPage({ List<NoteRevision> revisions = const <NoteRevision>[], this.nextCursor}): _revisions = revisions;
  factory _NoteRevisionPage.fromJson(Map<String, dynamic> json) => _$NoteRevisionPageFromJson(json);

 final  List<NoteRevision> _revisions;
@override@JsonKey() List<NoteRevision> get revisions {
  if (_revisions is EqualUnmodifiableListView) return _revisions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_revisions);
}

@override final  String? nextCursor;

/// Create a copy of NoteRevisionPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NoteRevisionPageCopyWith<_NoteRevisionPage> get copyWith => __$NoteRevisionPageCopyWithImpl<_NoteRevisionPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NoteRevisionPageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NoteRevisionPage&&const DeepCollectionEquality().equals(other._revisions, _revisions)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_revisions),nextCursor);

@override
String toString() {
  return 'NoteRevisionPage(revisions: $revisions, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$NoteRevisionPageCopyWith<$Res> implements $NoteRevisionPageCopyWith<$Res> {
  factory _$NoteRevisionPageCopyWith(_NoteRevisionPage value, $Res Function(_NoteRevisionPage) _then) = __$NoteRevisionPageCopyWithImpl;
@override @useResult
$Res call({
 List<NoteRevision> revisions, String? nextCursor
});




}
/// @nodoc
class __$NoteRevisionPageCopyWithImpl<$Res>
    implements _$NoteRevisionPageCopyWith<$Res> {
  __$NoteRevisionPageCopyWithImpl(this._self, this._then);

  final _NoteRevisionPage _self;
  final $Res Function(_NoteRevisionPage) _then;

/// Create a copy of NoteRevisionPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? revisions = null,Object? nextCursor = freezed,}) {
  return _then(_NoteRevisionPage(
revisions: null == revisions ? _self._revisions : revisions // ignore: cast_nullable_to_non_nullable
as List<NoteRevision>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
