class SyncOpRequest {
  final String clientOpId;
  final String entityType;
  final String entityId;
  final String op;
  final String? baseSyncVersion;
  final Map<String, dynamic>? payload;

  const SyncOpRequest({
    required this.clientOpId,
    required this.entityType,
    required this.entityId,
    required this.op,
    this.baseSyncVersion,
    this.payload,
  });

  Map<String, dynamic> toJson() => {
    'clientOpId': clientOpId,
    'entityType': entityType,
    'entityId': entityId,
    'op': op,
    if (baseSyncVersion != null) 'baseSyncVersion': baseSyncVersion,
    if (payload != null) 'payload': payload,
  };
}

class SyncRequest {
  final String? cursor;
  final List<SyncOpRequest> ops;

  const SyncRequest({this.cursor, this.ops = const []});

  Map<String, dynamic> toJson() => {
    if (cursor != null) 'cursor': cursor,
    'ops': ops.map((o) => o.toJson()).toList(),
  };
}

enum SyncOpStatus { applied, noop, rejected }

SyncOpStatus _parseStatus(String s) {
  switch (s) {
    case 'applied':
      return SyncOpStatus.applied;
    case 'noop':
      return SyncOpStatus.noop;
    case 'rejected':
      return SyncOpStatus.rejected;
    default:
      return SyncOpStatus.rejected;
  }
}

class SyncOpResult {
  final String clientOpId;
  final SyncOpStatus status;
  final String entityId;
  final String? syncVersion;
  final Map<String, dynamic>? serverRow;
  final bool serverWon;
  final String? reason;

  const SyncOpResult({
    required this.clientOpId,
    required this.status,
    required this.entityId,
    this.syncVersion,
    this.serverRow,
    this.serverWon = false,
    this.reason,
  });

  factory SyncOpResult.fromJson(Map<String, dynamic> json) => SyncOpResult(
    clientOpId: json['clientOpId'] as String,
    status: _parseStatus(json['status'] as String),
    entityId: json['entityId'] as String,
    syncVersion: json['syncVersion'] as String?,
    serverRow: json['serverRow'] as Map<String, dynamic>?,
    serverWon: (json['serverWon'] as bool?) ?? false,
    reason: json['reason'] as String?,
  );
}

class SyncServerChange {
  final String entityType;
  final String syncVersion;
  final Map<String, dynamic> data;
  final bool isDeleted;

  const SyncServerChange({
    required this.entityType,
    required this.syncVersion,
    required this.data,
    this.isDeleted = false,
  });

  factory SyncServerChange.fromJson(Map<String, dynamic> json) =>
      SyncServerChange(
        entityType: json['entityType'] as String,
        syncVersion: json['syncVersion'] as String,
        data: json['data'] as Map<String, dynamic>,
        isDeleted: (json['isDeleted'] as bool?) ?? false,
      );
}

class SyncResponse {
  final List<SyncOpResult> results;
  final List<SyncServerChange> serverChanges;
  final List<String> revokedSharedNoteIds;
  final String newCursor;
  final bool hasMore;

  const SyncResponse({
    required this.results,
    required this.serverChanges,
    required this.revokedSharedNoteIds,
    required this.newCursor,
    required this.hasMore,
  });

  factory SyncResponse.fromJson(Map<String, dynamic> json) => SyncResponse(
    results: ((json['results'] as List?) ?? const [])
        .map((e) => SyncOpResult.fromJson(e as Map<String, dynamic>))
        .toList(),
    serverChanges: ((json['serverChanges'] as List?) ?? const [])
        .map((e) => SyncServerChange.fromJson(e as Map<String, dynamic>))
        .toList(),
    revokedSharedNoteIds:
        ((json['revokedSharedNoteIds'] as List?) ?? const []).cast<String>(),
    newCursor: json['newCursor'] as String,
    hasMore: (json['hasMore'] as bool?) ?? false,
  );
}
