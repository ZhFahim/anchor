// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tag.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Tag _$TagFromJson(Map<String, dynamic> json) {
  return _Tag.fromJson(json);
}

/// @nodoc
mixin _$Tag {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get color => throw _privateConstructorUsedError;
  DateTime? get updatedAt =>
      throw _privateConstructorUsedError; // Note count from server (optional, not stored locally)
  @JsonKey(name: '_count')
  TagCount? get count => throw _privateConstructorUsedError; // Local only - not serialized
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get isSynced => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get isDeleted => throw _privateConstructorUsedError;

  /// Serializes this Tag to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Tag
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TagCopyWith<Tag> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TagCopyWith<$Res> {
  factory $TagCopyWith(Tag value, $Res Function(Tag) then) =
      _$TagCopyWithImpl<$Res, Tag>;
  @useResult
  $Res call({
    String id,
    String name,
    String? color,
    DateTime? updatedAt,
    @JsonKey(name: '_count') TagCount? count,
    @JsonKey(includeFromJson: false, includeToJson: false) bool isSynced,
    @JsonKey(includeFromJson: false, includeToJson: false) bool isDeleted,
  });

  $TagCountCopyWith<$Res>? get count;
}

/// @nodoc
class _$TagCopyWithImpl<$Res, $Val extends Tag> implements $TagCopyWith<$Res> {
  _$TagCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Tag
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? color = freezed,
    Object? updatedAt = freezed,
    Object? count = freezed,
    Object? isSynced = null,
    Object? isDeleted = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            color: freezed == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                      as String?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            count: freezed == count
                ? _value.count
                : count // ignore: cast_nullable_to_non_nullable
                      as TagCount?,
            isSynced: null == isSynced
                ? _value.isSynced
                : isSynced // ignore: cast_nullable_to_non_nullable
                      as bool,
            isDeleted: null == isDeleted
                ? _value.isDeleted
                : isDeleted // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of Tag
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TagCountCopyWith<$Res>? get count {
    if (_value.count == null) {
      return null;
    }

    return $TagCountCopyWith<$Res>(_value.count!, (value) {
      return _then(_value.copyWith(count: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TagImplCopyWith<$Res> implements $TagCopyWith<$Res> {
  factory _$$TagImplCopyWith(_$TagImpl value, $Res Function(_$TagImpl) then) =
      __$$TagImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? color,
    DateTime? updatedAt,
    @JsonKey(name: '_count') TagCount? count,
    @JsonKey(includeFromJson: false, includeToJson: false) bool isSynced,
    @JsonKey(includeFromJson: false, includeToJson: false) bool isDeleted,
  });

  @override
  $TagCountCopyWith<$Res>? get count;
}

/// @nodoc
class __$$TagImplCopyWithImpl<$Res> extends _$TagCopyWithImpl<$Res, _$TagImpl>
    implements _$$TagImplCopyWith<$Res> {
  __$$TagImplCopyWithImpl(_$TagImpl _value, $Res Function(_$TagImpl) _then)
    : super(_value, _then);

  /// Create a copy of Tag
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? color = freezed,
    Object? updatedAt = freezed,
    Object? count = freezed,
    Object? isSynced = null,
    Object? isDeleted = null,
  }) {
    return _then(
      _$TagImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        color: freezed == color
            ? _value.color
            : color // ignore: cast_nullable_to_non_nullable
                  as String?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        count: freezed == count
            ? _value.count
            : count // ignore: cast_nullable_to_non_nullable
                  as TagCount?,
        isSynced: null == isSynced
            ? _value.isSynced
            : isSynced // ignore: cast_nullable_to_non_nullable
                  as bool,
        isDeleted: null == isDeleted
            ? _value.isDeleted
            : isDeleted // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TagImpl extends _Tag {
  const _$TagImpl({
    required this.id,
    required this.name,
    this.color,
    this.updatedAt,
    @JsonKey(name: '_count') this.count,
    @JsonKey(includeFromJson: false, includeToJson: false) this.isSynced = true,
    @JsonKey(includeFromJson: false, includeToJson: false)
    this.isDeleted = false,
  }) : super._();

  factory _$TagImpl.fromJson(Map<String, dynamic> json) =>
      _$$TagImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? color;
  @override
  final DateTime? updatedAt;
  // Note count from server (optional, not stored locally)
  @override
  @JsonKey(name: '_count')
  final TagCount? count;
  // Local only - not serialized
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isSynced;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isDeleted;

  @override
  String toString() {
    return 'Tag(id: $id, name: $name, color: $color, updatedAt: $updatedAt, count: $count, isSynced: $isSynced, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TagImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    color,
    updatedAt,
    count,
    isSynced,
    isDeleted,
  );

  /// Create a copy of Tag
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TagImplCopyWith<_$TagImpl> get copyWith =>
      __$$TagImplCopyWithImpl<_$TagImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TagImplToJson(this);
  }
}

abstract class _Tag extends Tag {
  const factory _Tag({
    required final String id,
    required final String name,
    final String? color,
    final DateTime? updatedAt,
    @JsonKey(name: '_count') final TagCount? count,
    @JsonKey(includeFromJson: false, includeToJson: false) final bool isSynced,
    @JsonKey(includeFromJson: false, includeToJson: false) final bool isDeleted,
  }) = _$TagImpl;
  const _Tag._() : super._();

  factory _Tag.fromJson(Map<String, dynamic> json) = _$TagImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get color;
  @override
  DateTime? get updatedAt; // Note count from server (optional, not stored locally)
  @override
  @JsonKey(name: '_count')
  TagCount? get count; // Local only - not serialized
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get isSynced;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get isDeleted;

  /// Create a copy of Tag
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TagImplCopyWith<_$TagImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TagCount _$TagCountFromJson(Map<String, dynamic> json) {
  return _TagCount.fromJson(json);
}

/// @nodoc
mixin _$TagCount {
  int get notes => throw _privateConstructorUsedError;

  /// Serializes this TagCount to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TagCount
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TagCountCopyWith<TagCount> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TagCountCopyWith<$Res> {
  factory $TagCountCopyWith(TagCount value, $Res Function(TagCount) then) =
      _$TagCountCopyWithImpl<$Res, TagCount>;
  @useResult
  $Res call({int notes});
}

/// @nodoc
class _$TagCountCopyWithImpl<$Res, $Val extends TagCount>
    implements $TagCountCopyWith<$Res> {
  _$TagCountCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TagCount
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? notes = null}) {
    return _then(
      _value.copyWith(
            notes: null == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TagCountImplCopyWith<$Res>
    implements $TagCountCopyWith<$Res> {
  factory _$$TagCountImplCopyWith(
    _$TagCountImpl value,
    $Res Function(_$TagCountImpl) then,
  ) = __$$TagCountImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int notes});
}

/// @nodoc
class __$$TagCountImplCopyWithImpl<$Res>
    extends _$TagCountCopyWithImpl<$Res, _$TagCountImpl>
    implements _$$TagCountImplCopyWith<$Res> {
  __$$TagCountImplCopyWithImpl(
    _$TagCountImpl _value,
    $Res Function(_$TagCountImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TagCount
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? notes = null}) {
    return _then(
      _$TagCountImpl(
        notes: null == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TagCountImpl implements _TagCount {
  const _$TagCountImpl({required this.notes});

  factory _$TagCountImpl.fromJson(Map<String, dynamic> json) =>
      _$$TagCountImplFromJson(json);

  @override
  final int notes;

  @override
  String toString() {
    return 'TagCount(notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TagCountImpl &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, notes);

  /// Create a copy of TagCount
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TagCountImplCopyWith<_$TagCountImpl> get copyWith =>
      __$$TagCountImplCopyWithImpl<_$TagCountImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TagCountImplToJson(this);
  }
}

abstract class _TagCount implements TagCount {
  const factory _TagCount({required final int notes}) = _$TagCountImpl;

  factory _TagCount.fromJson(Map<String, dynamic> json) =
      _$TagCountImpl.fromJson;

  @override
  int get notes;

  /// Create a copy of TagCount
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TagCountImplCopyWith<_$TagCountImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
