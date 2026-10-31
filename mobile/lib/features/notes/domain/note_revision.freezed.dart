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
mixin _$NoteRevision {

 String get id; String get noteId; int get version; String get title;@JsonKey(unknownEnumValue: RevisionCause.edit) RevisionCause get cause; DateTime get createdAt; UserSummary? get author; String? get content;
/// Create a copy of NoteRevision
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoteRevisionCopyWith<NoteRevision> get copyWith => _$NoteRevisionCopyWithImpl<NoteRevision>(this as NoteRevision, _$identity);

  /// Serializes this NoteRevision to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NoteRevision;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoteRevision&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.noteId, _this.noteId) || other.noteId == _this.noteId)&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.cause, _this.cause) || other.cause == _this.cause)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.author, _this.author) || other.author == _this.author)&&(identical(other.content, _this.content) || other.content == _this.content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NoteRevision;
  return Object.hash(runtimeType,_this.id,_this.noteId,_this.version,_this.title,_this.cause,_this.createdAt,_this.author,_this.content);
}

@override
String toString() {
  final _this = this as NoteRevision;
  return 'NoteRevision(id: ${_this.id}, noteId: ${_this.noteId}, version: ${_this.version}, title: ${_this.title}, cause: ${_this.cause}, createdAt: ${_this.createdAt}, author: ${_this.author}, content: ${_this.content})';
}


}

/// @nodoc
abstract mixin class $NoteRevisionCopyWith<$Res>  {
  factory $NoteRevisionCopyWith(NoteRevision value, $Res Function(NoteRevision) _then) = _$NoteRevisionCopyWithImpl;
@useResult
$Res call({
 String id, String noteId, int version, String title,@JsonKey(unknownEnumValue: RevisionCause.edit) RevisionCause cause, DateTime createdAt, UserSummary? author, String? content
});


$UserSummaryCopyWith<$Res>? get author;

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
as UserSummary?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of NoteRevision
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSummaryCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $UserSummaryCopyWith<$Res>(_self.author!, (value) {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String noteId,  int version,  String title, @JsonKey(unknownEnumValue: RevisionCause.edit)  RevisionCause cause,  DateTime createdAt,  UserSummary? author,  String? content)?  $default,{required TResult orElse(),}) {final _that = this;
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String noteId,  int version,  String title, @JsonKey(unknownEnumValue: RevisionCause.edit)  RevisionCause cause,  DateTime createdAt,  UserSummary? author,  String? content)  $default,) {final _that = this;
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String noteId,  int version,  String title, @JsonKey(unknownEnumValue: RevisionCause.edit)  RevisionCause cause,  DateTime createdAt,  UserSummary? author,  String? content)?  $default,) {final _that = this;
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
@override final  UserSummary? author;
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
int get hashCode {
    return Object.hash(runtimeType,id,noteId,version,title,cause,createdAt,author,content);
}

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
 String id, String noteId, int version, String title,@JsonKey(unknownEnumValue: RevisionCause.edit) RevisionCause cause, DateTime createdAt, UserSummary? author, String? content
});


@override $UserSummaryCopyWith<$Res>? get author;

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
as UserSummary?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of NoteRevision
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSummaryCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $UserSummaryCopyWith<$Res>(_self.author!, (value) {
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
  final _this = this as NoteRevisionPage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoteRevisionPage&&const DeepCollectionEquality().equals(other.revisions, _this.revisions)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NoteRevisionPage;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.revisions),_this.nextCursor);
}

@override
String toString() {
  final _this = this as NoteRevisionPage;
  return 'NoteRevisionPage(revisions: ${_this.revisions}, nextCursor: ${_this.nextCursor})';
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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NoteRevisionPage&&const DeepCollectionEquality().equals(other.revisions, _revisions)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_revisions),nextCursor);
}

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
