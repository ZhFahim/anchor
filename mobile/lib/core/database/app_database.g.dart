// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _backgroundMeta = const VerificationMeta(
    'background',
  );
  @override
  late final GeneratedColumn<String> background = GeneratedColumn<String>(
    'background',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _permissionMeta = const VerificationMeta(
    'permission',
  );
  @override
  late final GeneratedColumn<String> permission = GeneratedColumn<String>(
    'permission',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('owner'),
  );
  static const VerificationMeta _shareIdsMeta = const VerificationMeta(
    'shareIds',
  );
  @override
  late final GeneratedColumn<String> shareIds = GeneratedColumn<String>(
    'share_ids',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sharedByIdMeta = const VerificationMeta(
    'sharedById',
  );
  @override
  late final GeneratedColumn<String> sharedById = GeneratedColumn<String>(
    'shared_by_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sharedByNameMeta = const VerificationMeta(
    'sharedByName',
  );
  @override
  late final GeneratedColumn<String> sharedByName = GeneratedColumn<String>(
    'shared_by_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sharedByEmailMeta = const VerificationMeta(
    'sharedByEmail',
  );
  @override
  late final GeneratedColumn<String> sharedByEmail = GeneratedColumn<String>(
    'shared_by_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sharedByProfileImageMeta =
      const VerificationMeta('sharedByProfileImage');
  @override
  late final GeneratedColumn<String> sharedByProfileImage =
      GeneratedColumn<String>(
        'shared_by_profile_image',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    content,
    isPinned,
    isArchived,
    background,
    state,
    updatedAt,
    isSynced,
    permission,
    shareIds,
    sharedById,
    sharedByName,
    sharedByEmail,
    sharedByProfileImage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('background')) {
      context.handle(
        _backgroundMeta,
        background.isAcceptableOrUnknown(data['background']!, _backgroundMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('permission')) {
      context.handle(
        _permissionMeta,
        permission.isAcceptableOrUnknown(data['permission']!, _permissionMeta),
      );
    }
    if (data.containsKey('share_ids')) {
      context.handle(
        _shareIdsMeta,
        shareIds.isAcceptableOrUnknown(data['share_ids']!, _shareIdsMeta),
      );
    }
    if (data.containsKey('shared_by_id')) {
      context.handle(
        _sharedByIdMeta,
        sharedById.isAcceptableOrUnknown(
          data['shared_by_id']!,
          _sharedByIdMeta,
        ),
      );
    }
    if (data.containsKey('shared_by_name')) {
      context.handle(
        _sharedByNameMeta,
        sharedByName.isAcceptableOrUnknown(
          data['shared_by_name']!,
          _sharedByNameMeta,
        ),
      );
    }
    if (data.containsKey('shared_by_email')) {
      context.handle(
        _sharedByEmailMeta,
        sharedByEmail.isAcceptableOrUnknown(
          data['shared_by_email']!,
          _sharedByEmailMeta,
        ),
      );
    }
    if (data.containsKey('shared_by_profile_image')) {
      context.handle(
        _sharedByProfileImageMeta,
        sharedByProfileImage.isAcceptableOrUnknown(
          data['shared_by_profile_image']!,
          _sharedByProfileImageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      background: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}background'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      permission: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}permission'],
      )!,
      shareIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}share_ids'],
      ),
      sharedById: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shared_by_id'],
      ),
      sharedByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shared_by_name'],
      ),
      sharedByEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shared_by_email'],
      ),
      sharedByProfileImage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shared_by_profile_image'],
      ),
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final String id;
  final String title;
  final String? content;
  final bool isPinned;
  final bool isArchived;
  final String? background;
  final String state;
  final DateTime? updatedAt;
  final bool isSynced;
  final String permission;
  final String? shareIds;
  final String? sharedById;
  final String? sharedByName;
  final String? sharedByEmail;
  final String? sharedByProfileImage;
  const Note({
    required this.id,
    required this.title,
    this.content,
    required this.isPinned,
    required this.isArchived,
    this.background,
    required this.state,
    this.updatedAt,
    required this.isSynced,
    required this.permission,
    this.shareIds,
    this.sharedById,
    this.sharedByName,
    this.sharedByEmail,
    this.sharedByProfileImage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    map['is_pinned'] = Variable<bool>(isPinned);
    map['is_archived'] = Variable<bool>(isArchived);
    if (!nullToAbsent || background != null) {
      map['background'] = Variable<String>(background);
    }
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['permission'] = Variable<String>(permission);
    if (!nullToAbsent || shareIds != null) {
      map['share_ids'] = Variable<String>(shareIds);
    }
    if (!nullToAbsent || sharedById != null) {
      map['shared_by_id'] = Variable<String>(sharedById);
    }
    if (!nullToAbsent || sharedByName != null) {
      map['shared_by_name'] = Variable<String>(sharedByName);
    }
    if (!nullToAbsent || sharedByEmail != null) {
      map['shared_by_email'] = Variable<String>(sharedByEmail);
    }
    if (!nullToAbsent || sharedByProfileImage != null) {
      map['shared_by_profile_image'] = Variable<String>(sharedByProfileImage);
    }
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      title: Value(title),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      isPinned: Value(isPinned),
      isArchived: Value(isArchived),
      background: background == null && nullToAbsent
          ? const Value.absent()
          : Value(background),
      state: Value(state),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isSynced: Value(isSynced),
      permission: Value(permission),
      shareIds: shareIds == null && nullToAbsent
          ? const Value.absent()
          : Value(shareIds),
      sharedById: sharedById == null && nullToAbsent
          ? const Value.absent()
          : Value(sharedById),
      sharedByName: sharedByName == null && nullToAbsent
          ? const Value.absent()
          : Value(sharedByName),
      sharedByEmail: sharedByEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(sharedByEmail),
      sharedByProfileImage: sharedByProfileImage == null && nullToAbsent
          ? const Value.absent()
          : Value(sharedByProfileImage),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String?>(json['content']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      background: serializer.fromJson<String?>(json['background']),
      state: serializer.fromJson<String>(json['state']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      permission: serializer.fromJson<String>(json['permission']),
      shareIds: serializer.fromJson<String?>(json['shareIds']),
      sharedById: serializer.fromJson<String?>(json['sharedById']),
      sharedByName: serializer.fromJson<String?>(json['sharedByName']),
      sharedByEmail: serializer.fromJson<String?>(json['sharedByEmail']),
      sharedByProfileImage: serializer.fromJson<String?>(
        json['sharedByProfileImage'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String?>(content),
      'isPinned': serializer.toJson<bool>(isPinned),
      'isArchived': serializer.toJson<bool>(isArchived),
      'background': serializer.toJson<String?>(background),
      'state': serializer.toJson<String>(state),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
      'permission': serializer.toJson<String>(permission),
      'shareIds': serializer.toJson<String?>(shareIds),
      'sharedById': serializer.toJson<String?>(sharedById),
      'sharedByName': serializer.toJson<String?>(sharedByName),
      'sharedByEmail': serializer.toJson<String?>(sharedByEmail),
      'sharedByProfileImage': serializer.toJson<String?>(sharedByProfileImage),
    };
  }

  Note copyWith({
    String? id,
    String? title,
    Value<String?> content = const Value.absent(),
    bool? isPinned,
    bool? isArchived,
    Value<String?> background = const Value.absent(),
    String? state,
    Value<DateTime?> updatedAt = const Value.absent(),
    bool? isSynced,
    String? permission,
    Value<String?> shareIds = const Value.absent(),
    Value<String?> sharedById = const Value.absent(),
    Value<String?> sharedByName = const Value.absent(),
    Value<String?> sharedByEmail = const Value.absent(),
    Value<String?> sharedByProfileImage = const Value.absent(),
  }) => Note(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content.present ? content.value : this.content,
    isPinned: isPinned ?? this.isPinned,
    isArchived: isArchived ?? this.isArchived,
    background: background.present ? background.value : this.background,
    state: state ?? this.state,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    isSynced: isSynced ?? this.isSynced,
    permission: permission ?? this.permission,
    shareIds: shareIds.present ? shareIds.value : this.shareIds,
    sharedById: sharedById.present ? sharedById.value : this.sharedById,
    sharedByName: sharedByName.present ? sharedByName.value : this.sharedByName,
    sharedByEmail: sharedByEmail.present
        ? sharedByEmail.value
        : this.sharedByEmail,
    sharedByProfileImage: sharedByProfileImage.present
        ? sharedByProfileImage.value
        : this.sharedByProfileImage,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      background: data.background.present
          ? data.background.value
          : this.background,
      state: data.state.present ? data.state.value : this.state,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      permission: data.permission.present
          ? data.permission.value
          : this.permission,
      shareIds: data.shareIds.present ? data.shareIds.value : this.shareIds,
      sharedById: data.sharedById.present
          ? data.sharedById.value
          : this.sharedById,
      sharedByName: data.sharedByName.present
          ? data.sharedByName.value
          : this.sharedByName,
      sharedByEmail: data.sharedByEmail.present
          ? data.sharedByEmail.value
          : this.sharedByEmail,
      sharedByProfileImage: data.sharedByProfileImage.present
          ? data.sharedByProfileImage.value
          : this.sharedByProfileImage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('isPinned: $isPinned, ')
          ..write('isArchived: $isArchived, ')
          ..write('background: $background, ')
          ..write('state: $state, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('permission: $permission, ')
          ..write('shareIds: $shareIds, ')
          ..write('sharedById: $sharedById, ')
          ..write('sharedByName: $sharedByName, ')
          ..write('sharedByEmail: $sharedByEmail, ')
          ..write('sharedByProfileImage: $sharedByProfileImage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    content,
    isPinned,
    isArchived,
    background,
    state,
    updatedAt,
    isSynced,
    permission,
    shareIds,
    sharedById,
    sharedByName,
    sharedByEmail,
    sharedByProfileImage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.isPinned == this.isPinned &&
          other.isArchived == this.isArchived &&
          other.background == this.background &&
          other.state == this.state &&
          other.updatedAt == this.updatedAt &&
          other.isSynced == this.isSynced &&
          other.permission == this.permission &&
          other.shareIds == this.shareIds &&
          other.sharedById == this.sharedById &&
          other.sharedByName == this.sharedByName &&
          other.sharedByEmail == this.sharedByEmail &&
          other.sharedByProfileImage == this.sharedByProfileImage);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> content;
  final Value<bool> isPinned;
  final Value<bool> isArchived;
  final Value<String?> background;
  final Value<String> state;
  final Value<DateTime?> updatedAt;
  final Value<bool> isSynced;
  final Value<String> permission;
  final Value<String?> shareIds;
  final Value<String?> sharedById;
  final Value<String?> sharedByName;
  final Value<String?> sharedByEmail;
  final Value<String?> sharedByProfileImage;
  final Value<int> rowid;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.background = const Value.absent(),
    this.state = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.permission = const Value.absent(),
    this.shareIds = const Value.absent(),
    this.sharedById = const Value.absent(),
    this.sharedByName = const Value.absent(),
    this.sharedByEmail = const Value.absent(),
    this.sharedByProfileImage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String id,
    required String title,
    this.content = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.background = const Value.absent(),
    this.state = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.permission = const Value.absent(),
    this.shareIds = const Value.absent(),
    this.sharedById = const Value.absent(),
    this.sharedByName = const Value.absent(),
    this.sharedByEmail = const Value.absent(),
    this.sharedByProfileImage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title);
  static Insertable<Note> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<bool>? isPinned,
    Expression<bool>? isArchived,
    Expression<String>? background,
    Expression<String>? state,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isSynced,
    Expression<String>? permission,
    Expression<String>? shareIds,
    Expression<String>? sharedById,
    Expression<String>? sharedByName,
    Expression<String>? sharedByEmail,
    Expression<String>? sharedByProfileImage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (isPinned != null) 'is_pinned': isPinned,
      if (isArchived != null) 'is_archived': isArchived,
      if (background != null) 'background': background,
      if (state != null) 'state': state,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (permission != null) 'permission': permission,
      if (shareIds != null) 'share_ids': shareIds,
      if (sharedById != null) 'shared_by_id': sharedById,
      if (sharedByName != null) 'shared_by_name': sharedByName,
      if (sharedByEmail != null) 'shared_by_email': sharedByEmail,
      if (sharedByProfileImage != null)
        'shared_by_profile_image': sharedByProfileImage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? content,
    Value<bool>? isPinned,
    Value<bool>? isArchived,
    Value<String?>? background,
    Value<String>? state,
    Value<DateTime?>? updatedAt,
    Value<bool>? isSynced,
    Value<String>? permission,
    Value<String?>? shareIds,
    Value<String?>? sharedById,
    Value<String?>? sharedByName,
    Value<String?>? sharedByEmail,
    Value<String?>? sharedByProfileImage,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      background: background ?? this.background,
      state: state ?? this.state,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      permission: permission ?? this.permission,
      shareIds: shareIds ?? this.shareIds,
      sharedById: sharedById ?? this.sharedById,
      sharedByName: sharedByName ?? this.sharedByName,
      sharedByEmail: sharedByEmail ?? this.sharedByEmail,
      sharedByProfileImage: sharedByProfileImage ?? this.sharedByProfileImage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (background.present) {
      map['background'] = Variable<String>(background.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (permission.present) {
      map['permission'] = Variable<String>(permission.value);
    }
    if (shareIds.present) {
      map['share_ids'] = Variable<String>(shareIds.value);
    }
    if (sharedById.present) {
      map['shared_by_id'] = Variable<String>(sharedById.value);
    }
    if (sharedByName.present) {
      map['shared_by_name'] = Variable<String>(sharedByName.value);
    }
    if (sharedByEmail.present) {
      map['shared_by_email'] = Variable<String>(sharedByEmail.value);
    }
    if (sharedByProfileImage.present) {
      map['shared_by_profile_image'] = Variable<String>(
        sharedByProfileImage.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('isPinned: $isPinned, ')
          ..write('isArchived: $isArchived, ')
          ..write('background: $background, ')
          ..write('state: $state, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('permission: $permission, ')
          ..write('shareIds: $shareIds, ')
          ..write('sharedById: $sharedById, ')
          ..write('sharedByName: $sharedByName, ')
          ..write('sharedByEmail: $sharedByEmail, ')
          ..write('sharedByProfileImage: $sharedByProfileImage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    color,
    updatedAt,
    isSynced,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final String id;
  final String name;
  final String? color;
  final DateTime? updatedAt;
  final bool isSynced;
  final bool isDeleted;
  const Tag({
    required this.id,
    required this.name,
    this.color,
    this.updatedAt,
    required this.isSynced,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isSynced: Value(isSynced),
      isDeleted: Value(isDeleted),
    );
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String?>(color),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Tag copyWith({
    String? id,
    String? name,
    Value<String?> color = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    bool? isSynced,
    bool? isDeleted,
  }) => Tag(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color.present ? color.value : this.color,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    isSynced: isSynced ?? this.isSynced,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, color, updatedAt, isSynced, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.updatedAt == this.updatedAt &&
          other.isSynced == this.isSynced &&
          other.isDeleted == this.isDeleted);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> color;
  final Value<DateTime?> updatedAt;
  final Value<bool> isSynced;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String name,
    this.color = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Tag> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? color,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isSynced,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? color,
    Value<DateTime?>? updatedAt,
    Value<bool>? isSynced,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NoteTagsTable extends NoteTags with TableInfo<$NoteTagsTable, NoteTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [noteId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {noteId, tagId};
  @override
  NoteTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteTag(
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $NoteTagsTable createAlias(String alias) {
    return $NoteTagsTable(attachedDatabase, alias);
  }
}

class NoteTag extends DataClass implements Insertable<NoteTag> {
  final String noteId;
  final String tagId;
  const NoteTag({required this.noteId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['note_id'] = Variable<String>(noteId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  NoteTagsCompanion toCompanion(bool nullToAbsent) {
    return NoteTagsCompanion(noteId: Value(noteId), tagId: Value(tagId));
  }

  factory NoteTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteTag(
      noteId: serializer.fromJson<String>(json['noteId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'noteId': serializer.toJson<String>(noteId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  NoteTag copyWith({String? noteId, String? tagId}) =>
      NoteTag(noteId: noteId ?? this.noteId, tagId: tagId ?? this.tagId);
  NoteTag copyWithCompanion(NoteTagsCompanion data) {
    return NoteTag(
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteTag(')
          ..write('noteId: $noteId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(noteId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteTag &&
          other.noteId == this.noteId &&
          other.tagId == this.tagId);
}

class NoteTagsCompanion extends UpdateCompanion<NoteTag> {
  final Value<String> noteId;
  final Value<String> tagId;
  final Value<int> rowid;
  const NoteTagsCompanion({
    this.noteId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoteTagsCompanion.insert({
    required String noteId,
    required String tagId,
    this.rowid = const Value.absent(),
  }) : noteId = Value(noteId),
       tagId = Value(tagId);
  static Insertable<NoteTag> custom({
    Expression<String>? noteId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (noteId != null) 'note_id': noteId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoteTagsCompanion copyWith({
    Value<String>? noteId,
    Value<String>? tagId,
    Value<int>? rowid,
  }) {
    return NoteTagsCompanion(
      noteId: noteId ?? this.noteId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteTagsCompanion(')
          ..write('noteId: $noteId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NoteAttachmentsTable extends NoteAttachments
    with TableInfo<$NoteAttachmentsTable, NoteAttachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteAttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalFilenameMeta = const VerificationMeta(
    'originalFilename',
  );
  @override
  late final GeneratedColumn<String> originalFilename = GeneratedColumn<String>(
    'original_filename',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _serverAttachmentIdMeta =
      const VerificationMeta('serverAttachmentId');
  @override
  late final GeneratedColumn<String> serverAttachmentId =
      GeneratedColumn<String>(
        'server_attachment_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _uploadedByUserIdMeta = const VerificationMeta(
    'uploadedByUserId',
  );
  @override
  late final GeneratedColumn<String> uploadedByUserId = GeneratedColumn<String>(
    'uploaded_by_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    noteId,
    type,
    originalFilename,
    mimeType,
    fileSize,
    position,
    localPath,
    syncStatus,
    serverAttachmentId,
    uploadedByUserId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteAttachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('original_filename')) {
      context.handle(
        _originalFilenameMeta,
        originalFilename.isAcceptableOrUnknown(
          data['original_filename']!,
          _originalFilenameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalFilenameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('server_attachment_id')) {
      context.handle(
        _serverAttachmentIdMeta,
        serverAttachmentId.isAcceptableOrUnknown(
          data['server_attachment_id']!,
          _serverAttachmentIdMeta,
        ),
      );
    }
    if (data.containsKey('uploaded_by_user_id')) {
      context.handle(
        _uploadedByUserIdMeta,
        uploadedByUserId.isAcceptableOrUnknown(
          data['uploaded_by_user_id']!,
          _uploadedByUserIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteAttachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteAttachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      originalFilename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_filename'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      serverAttachmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_attachment_id'],
      ),
      uploadedByUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uploaded_by_user_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $NoteAttachmentsTable createAlias(String alias) {
    return $NoteAttachmentsTable(attachedDatabase, alias);
  }
}

class NoteAttachment extends DataClass implements Insertable<NoteAttachment> {
  final String id;
  final String noteId;
  final String type;
  final String originalFilename;
  final String mimeType;
  final int fileSize;
  final int position;
  final String? localPath;
  final String syncStatus;
  final String? serverAttachmentId;
  final String? uploadedByUserId;
  final DateTime createdAt;
  const NoteAttachment({
    required this.id,
    required this.noteId,
    required this.type,
    required this.originalFilename,
    required this.mimeType,
    required this.fileSize,
    required this.position,
    this.localPath,
    required this.syncStatus,
    this.serverAttachmentId,
    this.uploadedByUserId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['note_id'] = Variable<String>(noteId);
    map['type'] = Variable<String>(type);
    map['original_filename'] = Variable<String>(originalFilename);
    map['mime_type'] = Variable<String>(mimeType);
    map['file_size'] = Variable<int>(fileSize);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || serverAttachmentId != null) {
      map['server_attachment_id'] = Variable<String>(serverAttachmentId);
    }
    if (!nullToAbsent || uploadedByUserId != null) {
      map['uploaded_by_user_id'] = Variable<String>(uploadedByUserId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  NoteAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return NoteAttachmentsCompanion(
      id: Value(id),
      noteId: Value(noteId),
      type: Value(type),
      originalFilename: Value(originalFilename),
      mimeType: Value(mimeType),
      fileSize: Value(fileSize),
      position: Value(position),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      syncStatus: Value(syncStatus),
      serverAttachmentId: serverAttachmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverAttachmentId),
      uploadedByUserId: uploadedByUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadedByUserId),
      createdAt: Value(createdAt),
    );
  }

  factory NoteAttachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteAttachment(
      id: serializer.fromJson<String>(json['id']),
      noteId: serializer.fromJson<String>(json['noteId']),
      type: serializer.fromJson<String>(json['type']),
      originalFilename: serializer.fromJson<String>(json['originalFilename']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      position: serializer.fromJson<int>(json['position']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      serverAttachmentId: serializer.fromJson<String?>(
        json['serverAttachmentId'],
      ),
      uploadedByUserId: serializer.fromJson<String?>(json['uploadedByUserId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'noteId': serializer.toJson<String>(noteId),
      'type': serializer.toJson<String>(type),
      'originalFilename': serializer.toJson<String>(originalFilename),
      'mimeType': serializer.toJson<String>(mimeType),
      'fileSize': serializer.toJson<int>(fileSize),
      'position': serializer.toJson<int>(position),
      'localPath': serializer.toJson<String?>(localPath),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'serverAttachmentId': serializer.toJson<String?>(serverAttachmentId),
      'uploadedByUserId': serializer.toJson<String?>(uploadedByUserId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  NoteAttachment copyWith({
    String? id,
    String? noteId,
    String? type,
    String? originalFilename,
    String? mimeType,
    int? fileSize,
    int? position,
    Value<String?> localPath = const Value.absent(),
    String? syncStatus,
    Value<String?> serverAttachmentId = const Value.absent(),
    Value<String?> uploadedByUserId = const Value.absent(),
    DateTime? createdAt,
  }) => NoteAttachment(
    id: id ?? this.id,
    noteId: noteId ?? this.noteId,
    type: type ?? this.type,
    originalFilename: originalFilename ?? this.originalFilename,
    mimeType: mimeType ?? this.mimeType,
    fileSize: fileSize ?? this.fileSize,
    position: position ?? this.position,
    localPath: localPath.present ? localPath.value : this.localPath,
    syncStatus: syncStatus ?? this.syncStatus,
    serverAttachmentId: serverAttachmentId.present
        ? serverAttachmentId.value
        : this.serverAttachmentId,
    uploadedByUserId: uploadedByUserId.present
        ? uploadedByUserId.value
        : this.uploadedByUserId,
    createdAt: createdAt ?? this.createdAt,
  );
  NoteAttachment copyWithCompanion(NoteAttachmentsCompanion data) {
    return NoteAttachment(
      id: data.id.present ? data.id.value : this.id,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      type: data.type.present ? data.type.value : this.type,
      originalFilename: data.originalFilename.present
          ? data.originalFilename.value
          : this.originalFilename,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      position: data.position.present ? data.position.value : this.position,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      serverAttachmentId: data.serverAttachmentId.present
          ? data.serverAttachmentId.value
          : this.serverAttachmentId,
      uploadedByUserId: data.uploadedByUserId.present
          ? data.uploadedByUserId.value
          : this.uploadedByUserId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteAttachment(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('type: $type, ')
          ..write('originalFilename: $originalFilename, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileSize: $fileSize, ')
          ..write('position: $position, ')
          ..write('localPath: $localPath, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverAttachmentId: $serverAttachmentId, ')
          ..write('uploadedByUserId: $uploadedByUserId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    noteId,
    type,
    originalFilename,
    mimeType,
    fileSize,
    position,
    localPath,
    syncStatus,
    serverAttachmentId,
    uploadedByUserId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteAttachment &&
          other.id == this.id &&
          other.noteId == this.noteId &&
          other.type == this.type &&
          other.originalFilename == this.originalFilename &&
          other.mimeType == this.mimeType &&
          other.fileSize == this.fileSize &&
          other.position == this.position &&
          other.localPath == this.localPath &&
          other.syncStatus == this.syncStatus &&
          other.serverAttachmentId == this.serverAttachmentId &&
          other.uploadedByUserId == this.uploadedByUserId &&
          other.createdAt == this.createdAt);
}

class NoteAttachmentsCompanion extends UpdateCompanion<NoteAttachment> {
  final Value<String> id;
  final Value<String> noteId;
  final Value<String> type;
  final Value<String> originalFilename;
  final Value<String> mimeType;
  final Value<int> fileSize;
  final Value<int> position;
  final Value<String?> localPath;
  final Value<String> syncStatus;
  final Value<String?> serverAttachmentId;
  final Value<String?> uploadedByUserId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const NoteAttachmentsCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.type = const Value.absent(),
    this.originalFilename = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.position = const Value.absent(),
    this.localPath = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverAttachmentId = const Value.absent(),
    this.uploadedByUserId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoteAttachmentsCompanion.insert({
    required String id,
    required String noteId,
    required String type,
    required String originalFilename,
    required String mimeType,
    required int fileSize,
    this.position = const Value.absent(),
    this.localPath = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverAttachmentId = const Value.absent(),
    this.uploadedByUserId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       noteId = Value(noteId),
       type = Value(type),
       originalFilename = Value(originalFilename),
       mimeType = Value(mimeType),
       fileSize = Value(fileSize);
  static Insertable<NoteAttachment> custom({
    Expression<String>? id,
    Expression<String>? noteId,
    Expression<String>? type,
    Expression<String>? originalFilename,
    Expression<String>? mimeType,
    Expression<int>? fileSize,
    Expression<int>? position,
    Expression<String>? localPath,
    Expression<String>? syncStatus,
    Expression<String>? serverAttachmentId,
    Expression<String>? uploadedByUserId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (noteId != null) 'note_id': noteId,
      if (type != null) 'type': type,
      if (originalFilename != null) 'original_filename': originalFilename,
      if (mimeType != null) 'mime_type': mimeType,
      if (fileSize != null) 'file_size': fileSize,
      if (position != null) 'position': position,
      if (localPath != null) 'local_path': localPath,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverAttachmentId != null)
        'server_attachment_id': serverAttachmentId,
      if (uploadedByUserId != null) 'uploaded_by_user_id': uploadedByUserId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoteAttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? noteId,
    Value<String>? type,
    Value<String>? originalFilename,
    Value<String>? mimeType,
    Value<int>? fileSize,
    Value<int>? position,
    Value<String?>? localPath,
    Value<String>? syncStatus,
    Value<String?>? serverAttachmentId,
    Value<String?>? uploadedByUserId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return NoteAttachmentsCompanion(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      type: type ?? this.type,
      originalFilename: originalFilename ?? this.originalFilename,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      position: position ?? this.position,
      localPath: localPath ?? this.localPath,
      syncStatus: syncStatus ?? this.syncStatus,
      serverAttachmentId: serverAttachmentId ?? this.serverAttachmentId,
      uploadedByUserId: uploadedByUserId ?? this.uploadedByUserId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (originalFilename.present) {
      map['original_filename'] = Variable<String>(originalFilename.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverAttachmentId.present) {
      map['server_attachment_id'] = Variable<String>(serverAttachmentId.value);
    }
    if (uploadedByUserId.present) {
      map['uploaded_by_user_id'] = Variable<String>(uploadedByUserId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteAttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('type: $type, ')
          ..write('originalFilename: $originalFilename, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileSize: $fileSize, ')
          ..write('position: $position, ')
          ..write('localPath: $localPath, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverAttachmentId: $serverAttachmentId, ')
          ..write('uploadedByUserId: $uploadedByUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $NoteTagsTable noteTags = $NoteTagsTable(this);
  late final $NoteAttachmentsTable noteAttachments = $NoteAttachmentsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    notes,
    tags,
    noteTags,
    noteAttachments,
  ];
}

typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      required String id,
      required String title,
      Value<String?> content,
      Value<bool> isPinned,
      Value<bool> isArchived,
      Value<String?> background,
      Value<String> state,
      Value<DateTime?> updatedAt,
      Value<bool> isSynced,
      Value<String> permission,
      Value<String?> shareIds,
      Value<String?> sharedById,
      Value<String?> sharedByName,
      Value<String?> sharedByEmail,
      Value<String?> sharedByProfileImage,
      Value<int> rowid,
    });
typedef $$NotesTableUpdateCompanionBuilder =
    NotesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> content,
      Value<bool> isPinned,
      Value<bool> isArchived,
      Value<String?> background,
      Value<String> state,
      Value<DateTime?> updatedAt,
      Value<bool> isSynced,
      Value<String> permission,
      Value<String?> shareIds,
      Value<String?> sharedById,
      Value<String?> sharedByName,
      Value<String?> sharedByEmail,
      Value<String?> sharedByProfileImage,
      Value<int> rowid,
    });

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get background => $composableBuilder(
    column: $table.background,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get permission => $composableBuilder(
    column: $table.permission,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shareIds => $composableBuilder(
    column: $table.shareIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sharedById => $composableBuilder(
    column: $table.sharedById,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sharedByName => $composableBuilder(
    column: $table.sharedByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sharedByEmail => $composableBuilder(
    column: $table.sharedByEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sharedByProfileImage => $composableBuilder(
    column: $table.sharedByProfileImage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get background => $composableBuilder(
    column: $table.background,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permission => $composableBuilder(
    column: $table.permission,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shareIds => $composableBuilder(
    column: $table.shareIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sharedById => $composableBuilder(
    column: $table.sharedById,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sharedByName => $composableBuilder(
    column: $table.sharedByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sharedByEmail => $composableBuilder(
    column: $table.sharedByEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sharedByProfileImage => $composableBuilder(
    column: $table.sharedByProfileImage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<String> get background => $composableBuilder(
    column: $table.background,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<String> get permission => $composableBuilder(
    column: $table.permission,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shareIds =>
      $composableBuilder(column: $table.shareIds, builder: (column) => column);

  GeneratedColumn<String> get sharedById => $composableBuilder(
    column: $table.sharedById,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sharedByName => $composableBuilder(
    column: $table.sharedByName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sharedByEmail => $composableBuilder(
    column: $table.sharedByEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sharedByProfileImage => $composableBuilder(
    column: $table.sharedByProfileImage,
    builder: (column) => column,
  );
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
          Note,
          PrefetchHooks Function()
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String?> background = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String> permission = const Value.absent(),
                Value<String?> shareIds = const Value.absent(),
                Value<String?> sharedById = const Value.absent(),
                Value<String?> sharedByName = const Value.absent(),
                Value<String?> sharedByEmail = const Value.absent(),
                Value<String?> sharedByProfileImage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                title: title,
                content: content,
                isPinned: isPinned,
                isArchived: isArchived,
                background: background,
                state: state,
                updatedAt: updatedAt,
                isSynced: isSynced,
                permission: permission,
                shareIds: shareIds,
                sharedById: sharedById,
                sharedByName: sharedByName,
                sharedByEmail: sharedByEmail,
                sharedByProfileImage: sharedByProfileImage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> content = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String?> background = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<String> permission = const Value.absent(),
                Value<String?> shareIds = const Value.absent(),
                Value<String?> sharedById = const Value.absent(),
                Value<String?> sharedByName = const Value.absent(),
                Value<String?> sharedByEmail = const Value.absent(),
                Value<String?> sharedByProfileImage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                title: title,
                content: content,
                isPinned: isPinned,
                isArchived: isArchived,
                background: background,
                state: state,
                updatedAt: updatedAt,
                isSynced: isSynced,
                permission: permission,
                shareIds: shareIds,
                sharedById: sharedById,
                sharedByName: sharedByName,
                sharedByEmail: sharedByEmail,
                sharedByProfileImage: sharedByProfileImage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
      Note,
      PrefetchHooks Function()
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      required String id,
      required String name,
      Value<String?> color,
      Value<DateTime?> updatedAt,
      Value<bool> isSynced,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> color,
      Value<DateTime?> updatedAt,
      Value<bool> isSynced,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
          Tag,
          PrefetchHooks Function()
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                name: name,
                color: color,
                updatedAt: updatedAt,
                isSynced: isSynced,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> color = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                name: name,
                color: color,
                updatedAt: updatedAt,
                isSynced: isSynced,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
      Tag,
      PrefetchHooks Function()
    >;
typedef $$NoteTagsTableCreateCompanionBuilder =
    NoteTagsCompanion Function({
      required String noteId,
      required String tagId,
      Value<int> rowid,
    });
typedef $$NoteTagsTableUpdateCompanionBuilder =
    NoteTagsCompanion Function({
      Value<String> noteId,
      Value<String> tagId,
      Value<int> rowid,
    });

class $$NoteTagsTableFilterComposer
    extends Composer<_$AppDatabase, $NoteTagsTable> {
  $$NoteTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NoteTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $NoteTagsTable> {
  $$NoteTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NoteTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NoteTagsTable> {
  $$NoteTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<String> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);
}

class $$NoteTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NoteTagsTable,
          NoteTag,
          $$NoteTagsTableFilterComposer,
          $$NoteTagsTableOrderingComposer,
          $$NoteTagsTableAnnotationComposer,
          $$NoteTagsTableCreateCompanionBuilder,
          $$NoteTagsTableUpdateCompanionBuilder,
          (NoteTag, BaseReferences<_$AppDatabase, $NoteTagsTable, NoteTag>),
          NoteTag,
          PrefetchHooks Function()
        > {
  $$NoteTagsTableTableManager(_$AppDatabase db, $NoteTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoteTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoteTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoteTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> noteId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  NoteTagsCompanion(noteId: noteId, tagId: tagId, rowid: rowid),
          createCompanionCallback:
              ({
                required String noteId,
                required String tagId,
                Value<int> rowid = const Value.absent(),
              }) => NoteTagsCompanion.insert(
                noteId: noteId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NoteTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NoteTagsTable,
      NoteTag,
      $$NoteTagsTableFilterComposer,
      $$NoteTagsTableOrderingComposer,
      $$NoteTagsTableAnnotationComposer,
      $$NoteTagsTableCreateCompanionBuilder,
      $$NoteTagsTableUpdateCompanionBuilder,
      (NoteTag, BaseReferences<_$AppDatabase, $NoteTagsTable, NoteTag>),
      NoteTag,
      PrefetchHooks Function()
    >;
typedef $$NoteAttachmentsTableCreateCompanionBuilder =
    NoteAttachmentsCompanion Function({
      required String id,
      required String noteId,
      required String type,
      required String originalFilename,
      required String mimeType,
      required int fileSize,
      Value<int> position,
      Value<String?> localPath,
      Value<String> syncStatus,
      Value<String?> serverAttachmentId,
      Value<String?> uploadedByUserId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$NoteAttachmentsTableUpdateCompanionBuilder =
    NoteAttachmentsCompanion Function({
      Value<String> id,
      Value<String> noteId,
      Value<String> type,
      Value<String> originalFilename,
      Value<String> mimeType,
      Value<int> fileSize,
      Value<int> position,
      Value<String?> localPath,
      Value<String> syncStatus,
      Value<String?> serverAttachmentId,
      Value<String?> uploadedByUserId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$NoteAttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $NoteAttachmentsTable> {
  $$NoteAttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalFilename => $composableBuilder(
    column: $table.originalFilename,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverAttachmentId => $composableBuilder(
    column: $table.serverAttachmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadedByUserId => $composableBuilder(
    column: $table.uploadedByUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NoteAttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $NoteAttachmentsTable> {
  $$NoteAttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalFilename => $composableBuilder(
    column: $table.originalFilename,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverAttachmentId => $composableBuilder(
    column: $table.serverAttachmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadedByUserId => $composableBuilder(
    column: $table.uploadedByUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NoteAttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NoteAttachmentsTable> {
  $$NoteAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get originalFilename => $composableBuilder(
    column: $table.originalFilename,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverAttachmentId => $composableBuilder(
    column: $table.serverAttachmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadedByUserId => $composableBuilder(
    column: $table.uploadedByUserId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$NoteAttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NoteAttachmentsTable,
          NoteAttachment,
          $$NoteAttachmentsTableFilterComposer,
          $$NoteAttachmentsTableOrderingComposer,
          $$NoteAttachmentsTableAnnotationComposer,
          $$NoteAttachmentsTableCreateCompanionBuilder,
          $$NoteAttachmentsTableUpdateCompanionBuilder,
          (
            NoteAttachment,
            BaseReferences<
              _$AppDatabase,
              $NoteAttachmentsTable,
              NoteAttachment
            >,
          ),
          NoteAttachment,
          PrefetchHooks Function()
        > {
  $$NoteAttachmentsTableTableManager(
    _$AppDatabase db,
    $NoteAttachmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoteAttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoteAttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoteAttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> noteId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> originalFilename = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> serverAttachmentId = const Value.absent(),
                Value<String?> uploadedByUserId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NoteAttachmentsCompanion(
                id: id,
                noteId: noteId,
                type: type,
                originalFilename: originalFilename,
                mimeType: mimeType,
                fileSize: fileSize,
                position: position,
                localPath: localPath,
                syncStatus: syncStatus,
                serverAttachmentId: serverAttachmentId,
                uploadedByUserId: uploadedByUserId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String noteId,
                required String type,
                required String originalFilename,
                required String mimeType,
                required int fileSize,
                Value<int> position = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> serverAttachmentId = const Value.absent(),
                Value<String?> uploadedByUserId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NoteAttachmentsCompanion.insert(
                id: id,
                noteId: noteId,
                type: type,
                originalFilename: originalFilename,
                mimeType: mimeType,
                fileSize: fileSize,
                position: position,
                localPath: localPath,
                syncStatus: syncStatus,
                serverAttachmentId: serverAttachmentId,
                uploadedByUserId: uploadedByUserId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NoteAttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NoteAttachmentsTable,
      NoteAttachment,
      $$NoteAttachmentsTableFilterComposer,
      $$NoteAttachmentsTableOrderingComposer,
      $$NoteAttachmentsTableAnnotationComposer,
      $$NoteAttachmentsTableCreateCompanionBuilder,
      $$NoteAttachmentsTableUpdateCompanionBuilder,
      (
        NoteAttachment,
        BaseReferences<_$AppDatabase, $NoteAttachmentsTable, NoteAttachment>,
      ),
      NoteAttachment,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$NoteTagsTableTableManager get noteTags =>
      $$NoteTagsTableTableManager(_db, _db.noteTags);
  $$NoteAttachmentsTableTableManager get noteAttachments =>
      $$NoteAttachmentsTableTableManager(_db, _db.noteAttachments);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appDatabase)
const appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  const AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'96746ce39122382a13563ce0219aa76e1cbe202d';
