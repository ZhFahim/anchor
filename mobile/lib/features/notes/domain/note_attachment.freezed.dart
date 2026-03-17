// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'note_attachment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NoteAttachment {

 String get id; String get noteId; AttachmentType get type; String get originalFilename; String get mimeType; int get fileSize; int get position; String? get uploadedByUserId;// Local only - not from server
@JsonKey(includeFromJson: false, includeToJson: false) String? get localPath;@JsonKey(includeFromJson: false, includeToJson: false) bool get isPendingUpload; String? get createdAt;
/// Create a copy of NoteAttachment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoteAttachmentCopyWith<NoteAttachment> get copyWith => _$NoteAttachmentCopyWithImpl<NoteAttachment>(this as NoteAttachment, _$identity);

  /// Serializes this NoteAttachment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoteAttachment&&(identical(other.id, id) || other.id == id)&&(identical(other.noteId, noteId) || other.noteId == noteId)&&(identical(other.type, type) || other.type == type)&&(identical(other.originalFilename, originalFilename) || other.originalFilename == originalFilename)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.position, position) || other.position == position)&&(identical(other.uploadedByUserId, uploadedByUserId) || other.uploadedByUserId == uploadedByUserId)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.isPendingUpload, isPendingUpload) || other.isPendingUpload == isPendingUpload)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,noteId,type,originalFilename,mimeType,fileSize,position,uploadedByUserId,localPath,isPendingUpload,createdAt);

@override
String toString() {
  return 'NoteAttachment(id: $id, noteId: $noteId, type: $type, originalFilename: $originalFilename, mimeType: $mimeType, fileSize: $fileSize, position: $position, uploadedByUserId: $uploadedByUserId, localPath: $localPath, isPendingUpload: $isPendingUpload, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $NoteAttachmentCopyWith<$Res>  {
  factory $NoteAttachmentCopyWith(NoteAttachment value, $Res Function(NoteAttachment) _then) = _$NoteAttachmentCopyWithImpl;
@useResult
$Res call({
 String id, String noteId, AttachmentType type, String originalFilename, String mimeType, int fileSize, int position, String? uploadedByUserId,@JsonKey(includeFromJson: false, includeToJson: false) String? localPath,@JsonKey(includeFromJson: false, includeToJson: false) bool isPendingUpload, String? createdAt
});




}
/// @nodoc
class _$NoteAttachmentCopyWithImpl<$Res>
    implements $NoteAttachmentCopyWith<$Res> {
  _$NoteAttachmentCopyWithImpl(this._self, this._then);

  final NoteAttachment _self;
  final $Res Function(NoteAttachment) _then;

/// Create a copy of NoteAttachment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? noteId = null,Object? type = null,Object? originalFilename = null,Object? mimeType = null,Object? fileSize = null,Object? position = null,Object? uploadedByUserId = freezed,Object? localPath = freezed,Object? isPendingUpload = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,noteId: null == noteId ? _self.noteId : noteId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AttachmentType,originalFilename: null == originalFilename ? _self.originalFilename : originalFilename // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,fileSize: null == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,uploadedByUserId: freezed == uploadedByUserId ? _self.uploadedByUserId : uploadedByUserId // ignore: cast_nullable_to_non_nullable
as String?,localPath: freezed == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String?,isPendingUpload: null == isPendingUpload ? _self.isPendingUpload : isPendingUpload // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NoteAttachment].
extension NoteAttachmentPatterns on NoteAttachment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NoteAttachment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NoteAttachment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NoteAttachment value)  $default,){
final _that = this;
switch (_that) {
case _NoteAttachment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NoteAttachment value)?  $default,){
final _that = this;
switch (_that) {
case _NoteAttachment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String noteId,  AttachmentType type,  String originalFilename,  String mimeType,  int fileSize,  int position,  String? uploadedByUserId, @JsonKey(includeFromJson: false, includeToJson: false)  String? localPath, @JsonKey(includeFromJson: false, includeToJson: false)  bool isPendingUpload,  String? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NoteAttachment() when $default != null:
return $default(_that.id,_that.noteId,_that.type,_that.originalFilename,_that.mimeType,_that.fileSize,_that.position,_that.uploadedByUserId,_that.localPath,_that.isPendingUpload,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String noteId,  AttachmentType type,  String originalFilename,  String mimeType,  int fileSize,  int position,  String? uploadedByUserId, @JsonKey(includeFromJson: false, includeToJson: false)  String? localPath, @JsonKey(includeFromJson: false, includeToJson: false)  bool isPendingUpload,  String? createdAt)  $default,) {final _that = this;
switch (_that) {
case _NoteAttachment():
return $default(_that.id,_that.noteId,_that.type,_that.originalFilename,_that.mimeType,_that.fileSize,_that.position,_that.uploadedByUserId,_that.localPath,_that.isPendingUpload,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String noteId,  AttachmentType type,  String originalFilename,  String mimeType,  int fileSize,  int position,  String? uploadedByUserId, @JsonKey(includeFromJson: false, includeToJson: false)  String? localPath, @JsonKey(includeFromJson: false, includeToJson: false)  bool isPendingUpload,  String? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _NoteAttachment() when $default != null:
return $default(_that.id,_that.noteId,_that.type,_that.originalFilename,_that.mimeType,_that.fileSize,_that.position,_that.uploadedByUserId,_that.localPath,_that.isPendingUpload,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NoteAttachment extends NoteAttachment {
  const _NoteAttachment({required this.id, required this.noteId, required this.type, required this.originalFilename, required this.mimeType, required this.fileSize, this.position = 0, this.uploadedByUserId, @JsonKey(includeFromJson: false, includeToJson: false) this.localPath, @JsonKey(includeFromJson: false, includeToJson: false) this.isPendingUpload = false, this.createdAt}): super._();
  factory _NoteAttachment.fromJson(Map<String, dynamic> json) => _$NoteAttachmentFromJson(json);

@override final  String id;
@override final  String noteId;
@override final  AttachmentType type;
@override final  String originalFilename;
@override final  String mimeType;
@override final  int fileSize;
@override@JsonKey() final  int position;
@override final  String? uploadedByUserId;
// Local only - not from server
@override@JsonKey(includeFromJson: false, includeToJson: false) final  String? localPath;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  bool isPendingUpload;
@override final  String? createdAt;

/// Create a copy of NoteAttachment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NoteAttachmentCopyWith<_NoteAttachment> get copyWith => __$NoteAttachmentCopyWithImpl<_NoteAttachment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NoteAttachmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NoteAttachment&&(identical(other.id, id) || other.id == id)&&(identical(other.noteId, noteId) || other.noteId == noteId)&&(identical(other.type, type) || other.type == type)&&(identical(other.originalFilename, originalFilename) || other.originalFilename == originalFilename)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.position, position) || other.position == position)&&(identical(other.uploadedByUserId, uploadedByUserId) || other.uploadedByUserId == uploadedByUserId)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.isPendingUpload, isPendingUpload) || other.isPendingUpload == isPendingUpload)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,noteId,type,originalFilename,mimeType,fileSize,position,uploadedByUserId,localPath,isPendingUpload,createdAt);

@override
String toString() {
  return 'NoteAttachment(id: $id, noteId: $noteId, type: $type, originalFilename: $originalFilename, mimeType: $mimeType, fileSize: $fileSize, position: $position, uploadedByUserId: $uploadedByUserId, localPath: $localPath, isPendingUpload: $isPendingUpload, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$NoteAttachmentCopyWith<$Res> implements $NoteAttachmentCopyWith<$Res> {
  factory _$NoteAttachmentCopyWith(_NoteAttachment value, $Res Function(_NoteAttachment) _then) = __$NoteAttachmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String noteId, AttachmentType type, String originalFilename, String mimeType, int fileSize, int position, String? uploadedByUserId,@JsonKey(includeFromJson: false, includeToJson: false) String? localPath,@JsonKey(includeFromJson: false, includeToJson: false) bool isPendingUpload, String? createdAt
});




}
/// @nodoc
class __$NoteAttachmentCopyWithImpl<$Res>
    implements _$NoteAttachmentCopyWith<$Res> {
  __$NoteAttachmentCopyWithImpl(this._self, this._then);

  final _NoteAttachment _self;
  final $Res Function(_NoteAttachment) _then;

/// Create a copy of NoteAttachment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? noteId = null,Object? type = null,Object? originalFilename = null,Object? mimeType = null,Object? fileSize = null,Object? position = null,Object? uploadedByUserId = freezed,Object? localPath = freezed,Object? isPendingUpload = null,Object? createdAt = freezed,}) {
  return _then(_NoteAttachment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,noteId: null == noteId ? _self.noteId : noteId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AttachmentType,originalFilename: null == originalFilename ? _self.originalFilename : originalFilename // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,fileSize: null == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,uploadedByUserId: freezed == uploadedByUserId ? _self.uploadedByUserId : uploadedByUserId // ignore: cast_nullable_to_non_nullable
as String?,localPath: freezed == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String?,isPendingUpload: null == isPendingUpload ? _self.isPendingUpload : isPendingUpload // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
