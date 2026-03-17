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
}

/// Sync status for attachments (stored in DB as text).
/// Values match DB column: 'synced', 'pending_upload', 'pending_delete'.
enum AttachmentSyncStatus {
  synced('synced'),
  pendingUpload('pending_upload'),
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
    // Local only - not from server
    @JsonKey(includeFromJson: false, includeToJson: false) String? localPath,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(false)
    bool isPendingUpload,
    String? createdAt,
  }) = _NoteAttachment;

  factory NoteAttachment.fromJson(Map<String, dynamic> json) =>
      _$NoteAttachmentFromJson(json);

  bool get isImage => type == AttachmentType.image;
  bool get isAudio => type == AttachmentType.audio;
}
