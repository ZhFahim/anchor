// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'note_share.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NoteShare {

 String get id; UserSummary get sharedWithUser; NoteSharePermission get permission; String get createdAt; String get updatedAt;
/// Create a copy of NoteShare
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoteShareCopyWith<NoteShare> get copyWith => _$NoteShareCopyWithImpl<NoteShare>(this as NoteShare, _$identity);

  /// Serializes this NoteShare to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NoteShare;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoteShare&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.sharedWithUser, _this.sharedWithUser) || other.sharedWithUser == _this.sharedWithUser)&&(identical(other.permission, _this.permission) || other.permission == _this.permission)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NoteShare;
  return Object.hash(runtimeType,_this.id,_this.sharedWithUser,_this.permission,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as NoteShare;
  return 'NoteShare(id: ${_this.id}, sharedWithUser: ${_this.sharedWithUser}, permission: ${_this.permission}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $NoteShareCopyWith<$Res>  {
  factory $NoteShareCopyWith(NoteShare value, $Res Function(NoteShare) _then) = _$NoteShareCopyWithImpl;
@useResult
$Res call({
 String id, UserSummary sharedWithUser, NoteSharePermission permission, String createdAt, String updatedAt
});


$UserSummaryCopyWith<$Res> get sharedWithUser;

}
/// @nodoc
class _$NoteShareCopyWithImpl<$Res>
    implements $NoteShareCopyWith<$Res> {
  _$NoteShareCopyWithImpl(this._self, this._then);

  final NoteShare _self;
  final $Res Function(NoteShare) _then;

/// Create a copy of NoteShare
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sharedWithUser = null,Object? permission = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(NoteShare(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sharedWithUser: null == sharedWithUser ? _self.sharedWithUser : sharedWithUser // ignore: cast_nullable_to_non_nullable
as UserSummary,permission: null == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as NoteSharePermission,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of NoteShare
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSummaryCopyWith<$Res> get sharedWithUser {
  
  return $UserSummaryCopyWith<$Res>(_self.sharedWithUser, (value) {
    return _then(_self.copyWith(sharedWithUser: value));
  });
}
}


/// Adds pattern-matching-related methods to [NoteShare].
extension NoteSharePatterns on NoteShare {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NoteShare value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NoteShare() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NoteShare value)  $default,){
final _that = this;
switch (_that) {
case _NoteShare():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NoteShare value)?  $default,){
final _that = this;
switch (_that) {
case _NoteShare() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  UserSummary sharedWithUser,  NoteSharePermission permission,  String createdAt,  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NoteShare() when $default != null:
return $default(_that.id,_that.sharedWithUser,_that.permission,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  UserSummary sharedWithUser,  NoteSharePermission permission,  String createdAt,  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _NoteShare():
return $default(_that.id,_that.sharedWithUser,_that.permission,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  UserSummary sharedWithUser,  NoteSharePermission permission,  String createdAt,  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _NoteShare() when $default != null:
return $default(_that.id,_that.sharedWithUser,_that.permission,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NoteShare implements NoteShare {
  const _NoteShare({required this.id, required this.sharedWithUser, required this.permission, required this.createdAt, required this.updatedAt});
  factory _NoteShare.fromJson(Map<String, dynamic> json) => _$NoteShareFromJson(json);

@override final  String id;
@override final  UserSummary sharedWithUser;
@override final  NoteSharePermission permission;
@override final  String createdAt;
@override final  String updatedAt;

/// Create a copy of NoteShare
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NoteShareCopyWith<_NoteShare> get copyWith => __$NoteShareCopyWithImpl<_NoteShare>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NoteShareToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NoteShare&&(identical(other.id, id) || other.id == id)&&(identical(other.sharedWithUser, sharedWithUser) || other.sharedWithUser == sharedWithUser)&&(identical(other.permission, permission) || other.permission == permission)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,sharedWithUser,permission,createdAt,updatedAt);
}

@override
String toString() {
    return 'NoteShare(id: $id, sharedWithUser: $sharedWithUser, permission: $permission, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$NoteShareCopyWith<$Res> implements $NoteShareCopyWith<$Res> {
  factory _$NoteShareCopyWith(_NoteShare value, $Res Function(_NoteShare) _then) = __$NoteShareCopyWithImpl;
@override @useResult
$Res call({
 String id, UserSummary sharedWithUser, NoteSharePermission permission, String createdAt, String updatedAt
});


@override $UserSummaryCopyWith<$Res> get sharedWithUser;

}
/// @nodoc
class __$NoteShareCopyWithImpl<$Res>
    implements _$NoteShareCopyWith<$Res> {
  __$NoteShareCopyWithImpl(this._self, this._then);

  final _NoteShare _self;
  final $Res Function(_NoteShare) _then;

/// Create a copy of NoteShare
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sharedWithUser = null,Object? permission = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_NoteShare(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sharedWithUser: null == sharedWithUser ? _self.sharedWithUser : sharedWithUser // ignore: cast_nullable_to_non_nullable
as UserSummary,permission: null == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as NoteSharePermission,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of NoteShare
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserSummaryCopyWith<$Res> get sharedWithUser {
  
  return $UserSummaryCopyWith<$Res>(_self.sharedWithUser, (value) {
    return _then(_self.copyWith(sharedWithUser: value));
  });
}
}

// dart format on
