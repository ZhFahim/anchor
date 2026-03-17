// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_attachment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NoteAttachment _$NoteAttachmentFromJson(Map<String, dynamic> json) =>
    _NoteAttachment(
      id: json['id'] as String,
      noteId: json['noteId'] as String,
      type: $enumDecode(_$AttachmentTypeEnumMap, json['type']),
      originalFilename: json['originalFilename'] as String,
      mimeType: json['mimeType'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      position: (json['position'] as num?)?.toInt() ?? 0,
      uploadedByUserId: json['uploadedByUserId'] as String?,
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$NoteAttachmentToJson(_NoteAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'noteId': instance.noteId,
      'type': _$AttachmentTypeEnumMap[instance.type]!,
      'originalFilename': instance.originalFilename,
      'mimeType': instance.mimeType,
      'fileSize': instance.fileSize,
      'position': instance.position,
      'uploadedByUserId': instance.uploadedByUserId,
      'createdAt': instance.createdAt,
    };

const _$AttachmentTypeEnumMap = {
  AttachmentType.image: 'image',
  AttachmentType.audio: 'audio',
};
