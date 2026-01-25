import 'package:freezed_annotation/freezed_annotation.dart';
import 'note_share_permission.dart';

part 'note_share.freezed.dart';
part 'note_share.g.dart';

@freezed
abstract class SharedUser with _$SharedUser {
  const factory SharedUser({
    required String id,
    required String name,
    required String email,
    String? profileImage,
  }) = _SharedUser;

  factory SharedUser.fromJson(Map<String, dynamic> json) =>
      _$SharedUserFromJson(json);
}

@freezed
abstract class NoteShare with _$NoteShare {
  const factory NoteShare({
    required String id,
    required SharedUser sharedWithUser,
    required NoteSharePermission permission,
    required String createdAt,
    required String updatedAt,
  }) = _NoteShare;

  factory NoteShare.fromJson(Map<String, dynamic> json) =>
      _$NoteShareFromJson(json);
}
