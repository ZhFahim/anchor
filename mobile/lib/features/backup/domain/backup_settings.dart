class BackupSettings {
  const BackupSettings({
    this.folderUri,
    this.folderName,
    this.automatic = true,
    this.periodDays = 7,
    this.keepFiles = 3,
    this.password,
    this.lastBackupAt,
  });

  static const int minPeriodDays = 1;
  static const int maxPeriodDays = 31;
  static const int minKeepFiles = 1;
  static const int maxKeepFiles = 10;

  final String? folderUri;

  /// The name Android gave the folder, shown in Settings.
  final String? folderName;
  final bool automatic;
  final int periodDays;
  final int keepFiles;
  final String? password;
  final DateTime? lastBackupAt;

  bool get hasFolder => folderUri != null && folderUri!.isNotEmpty;

  /// The folder name to show, from [folderName] or the last part of the URI.
  String? get folderDisplayName =>
      folderName ?? (hasFolder ? nameFromUri(folderUri!) : null);

  /// The last path segment of a document tree URI, decoded.
  static String? nameFromUri(String uri) {
    final parts = Uri.parse(uri).pathSegments;
    if (parts.isEmpty || parts.last.isEmpty) return null;
    return Uri.decodeComponent(parts.last);
  }

  BackupSettings copyWith({
    String? folderUri,
    String? folderName,
    bool? automatic,
    int? periodDays,
    int? keepFiles,
    String? password,
    DateTime? lastBackupAt,
    bool clearFolder = false,
    bool clearPassword = false,
  }) => BackupSettings(
    folderUri: clearFolder ? null : (folderUri ?? this.folderUri),
    folderName: clearFolder ? null : (folderName ?? this.folderName),
    automatic: automatic ?? this.automatic,
    periodDays: periodDays ?? this.periodDays,
    keepFiles: keepFiles ?? this.keepFiles,
    password: clearPassword ? null : (password ?? this.password),
    lastBackupAt: lastBackupAt ?? this.lastBackupAt,
  );
}
