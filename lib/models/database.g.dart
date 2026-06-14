// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 255,
    ),
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _reminderAtMeta = const VerificationMeta(
    'reminderAt',
  );
  @override
  late final GeneratedColumn<DateTime> reminderAt = GeneratedColumn<DateTime>(
    'reminder_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>?, String>
  imagePaths = GeneratedColumn<String>(
    'image_paths',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<List<String>?>($NotesTable.$converterimagePathsn);
  static const VerificationMeta _isChecklistMeta = const VerificationMeta(
    'isChecklist',
  );
  @override
  late final GeneratedColumn<bool> isChecklist = GeneratedColumn<bool>(
    'is_checklist',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_checklist" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<ChecklistItem>?, String>
  checklistItems = GeneratedColumn<String>(
    'checklist_items',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<List<ChecklistItem>?>($NotesTable.$converterchecklistItemsn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    content,
    color,
    createdAt,
    modifiedAt,
    orderIndex,
    isPinned,
    reminderAt,
    imagePaths,
    isChecklist,
    checklistItems,
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
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('reminder_at')) {
      context.handle(
        _reminderAtMeta,
        reminderAt.isAcceptableOrUnknown(data['reminder_at']!, _reminderAtMeta),
      );
    }
    if (data.containsKey('is_checklist')) {
      context.handle(
        _isChecklistMeta,
        isChecklist.isAcceptableOrUnknown(
          data['is_checklist']!,
          _isChecklistMeta,
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
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      reminderAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reminder_at'],
      ),
      imagePaths: $NotesTable.$converterimagePathsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}image_paths'],
        ),
      ),
      isChecklist: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_checklist'],
      )!,
      checklistItems: $NotesTable.$converterchecklistItemsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}checklist_items'],
        ),
      ),
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterimagePaths =
      const StringListConverter();
  static TypeConverter<List<String>?, String?> $converterimagePathsn =
      NullAwareTypeConverter.wrap($converterimagePaths);
  static TypeConverter<List<ChecklistItem>, String> $converterchecklistItems =
      const ChecklistConverter();
  static TypeConverter<List<ChecklistItem>?, String?>
  $converterchecklistItemsn = NullAwareTypeConverter.wrap(
    $converterchecklistItems,
  );
}

class Note extends DataClass implements Insertable<Note> {
  final int id;
  final String title;
  final String content;
  final int? color;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final int orderIndex;
  final bool isPinned;
  final DateTime? reminderAt;
  final List<String>? imagePaths;
  final bool isChecklist;
  final List<ChecklistItem>? checklistItems;
  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.color,
    required this.createdAt,
    required this.modifiedAt,
    required this.orderIndex,
    required this.isPinned,
    this.reminderAt,
    this.imagePaths,
    required this.isChecklist,
    this.checklistItems,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    map['order_index'] = Variable<int>(orderIndex);
    map['is_pinned'] = Variable<bool>(isPinned);
    if (!nullToAbsent || reminderAt != null) {
      map['reminder_at'] = Variable<DateTime>(reminderAt);
    }
    if (!nullToAbsent || imagePaths != null) {
      map['image_paths'] = Variable<String>(
        $NotesTable.$converterimagePathsn.toSql(imagePaths),
      );
    }
    map['is_checklist'] = Variable<bool>(isChecklist);
    if (!nullToAbsent || checklistItems != null) {
      map['checklist_items'] = Variable<String>(
        $NotesTable.$converterchecklistItemsn.toSql(checklistItems),
      );
    }
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      title: Value(title),
      content: Value(content),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
      orderIndex: Value(orderIndex),
      isPinned: Value(isPinned),
      reminderAt: reminderAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderAt),
      imagePaths: imagePaths == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePaths),
      isChecklist: Value(isChecklist),
      checklistItems: checklistItems == null && nullToAbsent
          ? const Value.absent()
          : Value(checklistItems),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      color: serializer.fromJson<int?>(json['color']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      reminderAt: serializer.fromJson<DateTime?>(json['reminderAt']),
      imagePaths: serializer.fromJson<List<String>?>(json['imagePaths']),
      isChecklist: serializer.fromJson<bool>(json['isChecklist']),
      checklistItems: serializer.fromJson<List<ChecklistItem>?>(
        json['checklistItems'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'color': serializer.toJson<int?>(color),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'isPinned': serializer.toJson<bool>(isPinned),
      'reminderAt': serializer.toJson<DateTime?>(reminderAt),
      'imagePaths': serializer.toJson<List<String>?>(imagePaths),
      'isChecklist': serializer.toJson<bool>(isChecklist),
      'checklistItems': serializer.toJson<List<ChecklistItem>?>(checklistItems),
    };
  }

  Note copyWith({
    int? id,
    String? title,
    String? content,
    Value<int?> color = const Value.absent(),
    DateTime? createdAt,
    DateTime? modifiedAt,
    int? orderIndex,
    bool? isPinned,
    Value<DateTime?> reminderAt = const Value.absent(),
    Value<List<String>?> imagePaths = const Value.absent(),
    bool? isChecklist,
    Value<List<ChecklistItem>?> checklistItems = const Value.absent(),
  }) => Note(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    color: color.present ? color.value : this.color,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    orderIndex: orderIndex ?? this.orderIndex,
    isPinned: isPinned ?? this.isPinned,
    reminderAt: reminderAt.present ? reminderAt.value : this.reminderAt,
    imagePaths: imagePaths.present ? imagePaths.value : this.imagePaths,
    isChecklist: isChecklist ?? this.isChecklist,
    checklistItems: checklistItems.present
        ? checklistItems.value
        : this.checklistItems,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      color: data.color.present ? data.color.value : this.color,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      reminderAt: data.reminderAt.present
          ? data.reminderAt.value
          : this.reminderAt,
      imagePaths: data.imagePaths.present
          ? data.imagePaths.value
          : this.imagePaths,
      isChecklist: data.isChecklist.present
          ? data.isChecklist.value
          : this.isChecklist,
      checklistItems: data.checklistItems.present
          ? data.checklistItems.value
          : this.checklistItems,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('isPinned: $isPinned, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('imagePaths: $imagePaths, ')
          ..write('isChecklist: $isChecklist, ')
          ..write('checklistItems: $checklistItems')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    content,
    color,
    createdAt,
    modifiedAt,
    orderIndex,
    isPinned,
    reminderAt,
    imagePaths,
    isChecklist,
    checklistItems,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.color == this.color &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt &&
          other.orderIndex == this.orderIndex &&
          other.isPinned == this.isPinned &&
          other.reminderAt == this.reminderAt &&
          other.imagePaths == this.imagePaths &&
          other.isChecklist == this.isChecklist &&
          other.checklistItems == this.checklistItems);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> content;
  final Value<int?> color;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<int> orderIndex;
  final Value<bool> isPinned;
  final Value<DateTime?> reminderAt;
  final Value<List<String>?> imagePaths;
  final Value<bool> isChecklist;
  final Value<List<ChecklistItem>?> checklistItems;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.imagePaths = const Value.absent(),
    this.isChecklist = const Value.absent(),
    this.checklistItems = const Value.absent(),
  });
  NotesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String content,
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.imagePaths = const Value.absent(),
    this.isChecklist = const Value.absent(),
    this.checklistItems = const Value.absent(),
  }) : title = Value(title),
       content = Value(content);
  static Insertable<Note> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<int>? color,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<int>? orderIndex,
    Expression<bool>? isPinned,
    Expression<DateTime>? reminderAt,
    Expression<String>? imagePaths,
    Expression<bool>? isChecklist,
    Expression<String>? checklistItems,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (color != null) 'color': color,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (orderIndex != null) 'order_index': orderIndex,
      if (isPinned != null) 'is_pinned': isPinned,
      if (reminderAt != null) 'reminder_at': reminderAt,
      if (imagePaths != null) 'image_paths': imagePaths,
      if (isChecklist != null) 'is_checklist': isChecklist,
      if (checklistItems != null) 'checklist_items': checklistItems,
    });
  }

  NotesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? content,
    Value<int?>? color,
    Value<DateTime>? createdAt,
    Value<DateTime>? modifiedAt,
    Value<int>? orderIndex,
    Value<bool>? isPinned,
    Value<DateTime?>? reminderAt,
    Value<List<String>?>? imagePaths,
    Value<bool>? isChecklist,
    Value<List<ChecklistItem>?>? checklistItems,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      orderIndex: orderIndex ?? this.orderIndex,
      isPinned: isPinned ?? this.isPinned,
      reminderAt: reminderAt ?? this.reminderAt,
      imagePaths: imagePaths ?? this.imagePaths,
      isChecklist: isChecklist ?? this.isChecklist,
      checklistItems: checklistItems ?? this.checklistItems,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (reminderAt.present) {
      map['reminder_at'] = Variable<DateTime>(reminderAt.value);
    }
    if (imagePaths.present) {
      map['image_paths'] = Variable<String>(
        $NotesTable.$converterimagePathsn.toSql(imagePaths.value),
      );
    }
    if (isChecklist.present) {
      map['is_checklist'] = Variable<bool>(isChecklist.value);
    }
    if (checklistItems.present) {
      map['checklist_items'] = Variable<String>(
        $NotesTable.$converterchecklistItemsn.toSql(checklistItems.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('isPinned: $isPinned, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('imagePaths: $imagePaths, ')
          ..write('isChecklist: $isChecklist, ')
          ..write('checklistItems: $checklistItems')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NotesTable notes = $NotesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [notes];
}

typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      Value<int> id,
      required String title,
      required String content,
      Value<int?> color,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<int> orderIndex,
      Value<bool> isPinned,
      Value<DateTime?> reminderAt,
      Value<List<String>?> imagePaths,
      Value<bool> isChecklist,
      Value<List<ChecklistItem>?> checklistItems,
    });
typedef $$NotesTableUpdateCompanionBuilder =
    NotesCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> content,
      Value<int?> color,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<int> orderIndex,
      Value<bool> isPinned,
      Value<DateTime?> reminderAt,
      Value<List<String>?> imagePaths,
      Value<bool> isChecklist,
      Value<List<ChecklistItem>?> checklistItems,
    });

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
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

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>?, List<String>, String>
  get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isChecklist => $composableBuilder(
    column: $table.isChecklist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    List<ChecklistItem>?,
    List<ChecklistItem>,
    String
  >
  get checklistItems => $composableBuilder(
    column: $table.checklistItems,
    builder: (column) => ColumnWithTypeConverterFilters(column),
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
  ColumnOrderings<int> get id => $composableBuilder(
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

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isChecklist => $composableBuilder(
    column: $table.isChecklist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checklistItems => $composableBuilder(
    column: $table.checklistItems,
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
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<DateTime> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>?, String> get imagePaths =>
      $composableBuilder(
        column: $table.imagePaths,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get isChecklist => $composableBuilder(
    column: $table.isChecklist,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<ChecklistItem>?, String>
  get checklistItems => $composableBuilder(
    column: $table.checklistItems,
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
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<DateTime?> reminderAt = const Value.absent(),
                Value<List<String>?> imagePaths = const Value.absent(),
                Value<bool> isChecklist = const Value.absent(),
                Value<List<ChecklistItem>?> checklistItems =
                    const Value.absent(),
              }) => NotesCompanion(
                id: id,
                title: title,
                content: content,
                color: color,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                orderIndex: orderIndex,
                isPinned: isPinned,
                reminderAt: reminderAt,
                imagePaths: imagePaths,
                isChecklist: isChecklist,
                checklistItems: checklistItems,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String content,
                Value<int?> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<DateTime?> reminderAt = const Value.absent(),
                Value<List<String>?> imagePaths = const Value.absent(),
                Value<bool> isChecklist = const Value.absent(),
                Value<List<ChecklistItem>?> checklistItems =
                    const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                title: title,
                content: content,
                color: color,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                orderIndex: orderIndex,
                isPinned: isPinned,
                reminderAt: reminderAt,
                imagePaths: imagePaths,
                isChecklist: isChecklist,
                checklistItems: checklistItems,
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
}
