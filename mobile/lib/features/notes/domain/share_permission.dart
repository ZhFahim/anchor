import 'package:json_annotation/json_annotation.dart';

/// Permission levels for note sharing
@JsonEnum(valueField: 'name')
enum NoteSharePermission {
  viewer('viewer'),
  editor('editor');

  const NoteSharePermission(this.name);
  final String name;

  static NoteSharePermission fromString(String value) {
    return NoteSharePermission.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NoteSharePermission.viewer,
    );
  }
}
