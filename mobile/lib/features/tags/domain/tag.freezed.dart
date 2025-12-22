// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tag.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Tag {

 String get id; String get name; String? get color; DateTime? get updatedAt;// Note count from server (optional, not stored locally)
@JsonKey(name: '_count') TagCount? get count;// Local only - not serialized
@JsonKey(includeFromJson: false, includeToJson: false) bool get isSynced;@JsonKey(includeFromJson: true, includeToJson: false) bool get isDeleted;
/// Create a copy of Tag
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TagCopyWith<Tag> get copyWith => _$TagCopyWithImpl<Tag>(this as Tag, _$identity);

  /// Serializes this Tag to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Tag&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.count, count) || other.count == count)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,color,updatedAt,count,isSynced,isDeleted);

@override
String toString() {
  return 'Tag(id: $id, name: $name, color: $color, updatedAt: $updatedAt, count: $count, isSynced: $isSynced, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class $TagCopyWith<$Res>  {
  factory $TagCopyWith(Tag value, $Res Function(Tag) _then) = _$TagCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? color, DateTime? updatedAt,@JsonKey(name: '_count') TagCount? count,@JsonKey(includeFromJson: false, includeToJson: false) bool isSynced,@JsonKey(includeFromJson: true, includeToJson: false) bool isDeleted
});


$TagCountCopyWith<$Res>? get count;

}
/// @nodoc
class _$TagCopyWithImpl<$Res>
    implements $TagCopyWith<$Res> {
  _$TagCopyWithImpl(this._self, this._then);

  final Tag _self;
  final $Res Function(Tag) _then;

/// Create a copy of Tag
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? color = freezed,Object? updatedAt = freezed,Object? count = freezed,Object? isSynced = null,Object? isDeleted = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,count: freezed == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as TagCount?,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Tag
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TagCountCopyWith<$Res>? get count {
    if (_self.count == null) {
    return null;
  }

  return $TagCountCopyWith<$Res>(_self.count!, (value) {
    return _then(_self.copyWith(count: value));
  });
}
}


/// Adds pattern-matching-related methods to [Tag].
extension TagPatterns on Tag {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Tag value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Tag() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Tag value)  $default,){
final _that = this;
switch (_that) {
case _Tag():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Tag value)?  $default,){
final _that = this;
switch (_that) {
case _Tag() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? color,  DateTime? updatedAt, @JsonKey(name: '_count')  TagCount? count, @JsonKey(includeFromJson: false, includeToJson: false)  bool isSynced, @JsonKey(includeFromJson: true, includeToJson: false)  bool isDeleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Tag() when $default != null:
return $default(_that.id,_that.name,_that.color,_that.updatedAt,_that.count,_that.isSynced,_that.isDeleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? color,  DateTime? updatedAt, @JsonKey(name: '_count')  TagCount? count, @JsonKey(includeFromJson: false, includeToJson: false)  bool isSynced, @JsonKey(includeFromJson: true, includeToJson: false)  bool isDeleted)  $default,) {final _that = this;
switch (_that) {
case _Tag():
return $default(_that.id,_that.name,_that.color,_that.updatedAt,_that.count,_that.isSynced,_that.isDeleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? color,  DateTime? updatedAt, @JsonKey(name: '_count')  TagCount? count, @JsonKey(includeFromJson: false, includeToJson: false)  bool isSynced, @JsonKey(includeFromJson: true, includeToJson: false)  bool isDeleted)?  $default,) {final _that = this;
switch (_that) {
case _Tag() when $default != null:
return $default(_that.id,_that.name,_that.color,_that.updatedAt,_that.count,_that.isSynced,_that.isDeleted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Tag extends Tag {
  const _Tag({required this.id, required this.name, this.color, this.updatedAt, @JsonKey(name: '_count') this.count, @JsonKey(includeFromJson: false, includeToJson: false) this.isSynced = true, @JsonKey(includeFromJson: true, includeToJson: false) this.isDeleted = false}): super._();
  factory _Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? color;
@override final  DateTime? updatedAt;
// Note count from server (optional, not stored locally)
@override@JsonKey(name: '_count') final  TagCount? count;
// Local only - not serialized
@override@JsonKey(includeFromJson: false, includeToJson: false) final  bool isSynced;
@override@JsonKey(includeFromJson: true, includeToJson: false) final  bool isDeleted;

/// Create a copy of Tag
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TagCopyWith<_Tag> get copyWith => __$TagCopyWithImpl<_Tag>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TagToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Tag&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.count, count) || other.count == count)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,color,updatedAt,count,isSynced,isDeleted);

@override
String toString() {
  return 'Tag(id: $id, name: $name, color: $color, updatedAt: $updatedAt, count: $count, isSynced: $isSynced, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class _$TagCopyWith<$Res> implements $TagCopyWith<$Res> {
  factory _$TagCopyWith(_Tag value, $Res Function(_Tag) _then) = __$TagCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? color, DateTime? updatedAt,@JsonKey(name: '_count') TagCount? count,@JsonKey(includeFromJson: false, includeToJson: false) bool isSynced,@JsonKey(includeFromJson: true, includeToJson: false) bool isDeleted
});


@override $TagCountCopyWith<$Res>? get count;

}
/// @nodoc
class __$TagCopyWithImpl<$Res>
    implements _$TagCopyWith<$Res> {
  __$TagCopyWithImpl(this._self, this._then);

  final _Tag _self;
  final $Res Function(_Tag) _then;

/// Create a copy of Tag
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? color = freezed,Object? updatedAt = freezed,Object? count = freezed,Object? isSynced = null,Object? isDeleted = null,}) {
  return _then(_Tag(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,count: freezed == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as TagCount?,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Tag
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TagCountCopyWith<$Res>? get count {
    if (_self.count == null) {
    return null;
  }

  return $TagCountCopyWith<$Res>(_self.count!, (value) {
    return _then(_self.copyWith(count: value));
  });
}
}


/// @nodoc
mixin _$TagCount {

 int get notes;
/// Create a copy of TagCount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TagCountCopyWith<TagCount> get copyWith => _$TagCountCopyWithImpl<TagCount>(this as TagCount, _$identity);

  /// Serializes this TagCount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TagCount&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notes);

@override
String toString() {
  return 'TagCount(notes: $notes)';
}


}

/// @nodoc
abstract mixin class $TagCountCopyWith<$Res>  {
  factory $TagCountCopyWith(TagCount value, $Res Function(TagCount) _then) = _$TagCountCopyWithImpl;
@useResult
$Res call({
 int notes
});




}
/// @nodoc
class _$TagCountCopyWithImpl<$Res>
    implements $TagCountCopyWith<$Res> {
  _$TagCountCopyWithImpl(this._self, this._then);

  final TagCount _self;
  final $Res Function(TagCount) _then;

/// Create a copy of TagCount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notes = null,}) {
  return _then(_self.copyWith(
notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TagCount].
extension TagCountPatterns on TagCount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TagCount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TagCount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TagCount value)  $default,){
final _that = this;
switch (_that) {
case _TagCount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TagCount value)?  $default,){
final _that = this;
switch (_that) {
case _TagCount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TagCount() when $default != null:
return $default(_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int notes)  $default,) {final _that = this;
switch (_that) {
case _TagCount():
return $default(_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int notes)?  $default,) {final _that = this;
switch (_that) {
case _TagCount() when $default != null:
return $default(_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TagCount implements TagCount {
  const _TagCount({required this.notes});
  factory _TagCount.fromJson(Map<String, dynamic> json) => _$TagCountFromJson(json);

@override final  int notes;

/// Create a copy of TagCount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TagCountCopyWith<_TagCount> get copyWith => __$TagCountCopyWithImpl<_TagCount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TagCountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TagCount&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notes);

@override
String toString() {
  return 'TagCount(notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$TagCountCopyWith<$Res> implements $TagCountCopyWith<$Res> {
  factory _$TagCountCopyWith(_TagCount value, $Res Function(_TagCount) _then) = __$TagCountCopyWithImpl;
@override @useResult
$Res call({
 int notes
});




}
/// @nodoc
class __$TagCountCopyWithImpl<$Res>
    implements _$TagCountCopyWith<$Res> {
  __$TagCountCopyWithImpl(this._self, this._then);

  final _TagCount _self;
  final $Res Function(_TagCount) _then;

/// Create a copy of TagCount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? notes = null,}) {
  return _then(_TagCount(
notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
