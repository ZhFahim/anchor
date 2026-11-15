import 'package:freezed_annotation/freezed_annotation.dart';

part 'note_attachment.freezed.dart';
part 'note_attachment.g.dart';

enum AttachmentType {
  image,
  audio;

  static AttachmentType fromString(String value) {
    return AttachmentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AttachmentType.image,
    );
  }

  static AttachmentType fromMimeType(String mimeType) =>
      mimeType.startsWith('image/')
      ? AttachmentType.image
      : AttachmentType.audio;
}

const recordingFilePrefix = 'recording_';

enum AttachmentKind {
  picture,
  voiceNote,
  audioFile;

  static AttachmentKind of({
    required String mimeType,
    required String filename,
  }) => switch (AttachmentType.fromMimeType(mimeType)) {
    AttachmentType.image => AttachmentKind.picture,
    AttachmentType.audio when filename.startsWith(recordingFilePrefix) =>
      AttachmentKind.voiceNote,
    AttachmentType.audio => AttachmentKind.audioFile,
  };
}

/// Must match the server's limit.
const maxAttachmentBytes = 50 * 1024 * 1024;

class AttachmentTooBigException implements Exception {
  const AttachmentTooBigException();
}

enum AttachmentSyncStatus {
  synced('synced'),
  pendingUpload('pending_upload'),
  uploadFailed('upload_failed'),
  pendingDelete('pending_delete');

  const AttachmentSyncStatus(this.dbValue);
  final String dbValue;

  static AttachmentSyncStatus fromString(String value) {
    return AttachmentSyncStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => AttachmentSyncStatus.synced,
    );
  }
}

/// Tracks local image compression state before upload.
enum AttachmentCompressionStatus {
  none('none'),
  queued('queued'),
  compressing('compressing'),
  ready('ready'),
  failed('failed');

  const AttachmentCompressionStatus(this.dbValue);
  final String dbValue;

  static AttachmentCompressionStatus fromString(String value) {
    return AttachmentCompressionStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => AttachmentCompressionStatus.none,
    );
  }
}

@freezed
abstract class NoteAttachment with _$NoteAttachment {
  const NoteAttachment._();

  const factory NoteAttachment({
    required String id,
    required String noteId,
    required AttachmentType type,
    required String originalFilename,
    required String mimeType,
    required int fileSize,
    @Default(0) int position,
    String? uploadedByUserId,
    @JsonKey(includeFromJson: false, includeToJson: false) String? localPath,
    @JsonKey(includeFromJson: false, includeToJson: false) String? compressedPath,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(AttachmentCompressionStatus.none)
    AttachmentCompressionStatus compressionStatus,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(false)
    bool isPendingUpload,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(false)
    bool isUploadFailed,
    String? createdAt,
  }) = _NoteAttachment;

  factory NoteAttachment.fromJson(Map<String, dynamic> json) =>
      _$NoteAttachmentFromJson(json);

  bool get isImage => type == AttachmentType.image;
  bool get isAudio => type == AttachmentType.audio;

  AttachmentKind get kind =>
      AttachmentKind.of(mimeType: mimeType, filename: originalFilename);
}
