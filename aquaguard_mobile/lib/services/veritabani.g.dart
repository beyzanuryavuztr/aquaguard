// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'veritabani.dart';

// ignore_for_file: type=lint
class $SensorOkumalariTable extends SensorOkumalari
    with TableInfo<$SensorOkumalariTable, SensorOkumalariData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SensorOkumalariTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _zoneMeta = const VerificationMeta('zone');
  @override
  late final GeneratedColumn<int> zone = GeneratedColumn<int>(
    'zone',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zamanMillisMeta = const VerificationMeta(
    'zamanMillis',
  );
  @override
  late final GeneratedColumn<int> zamanMillis = GeneratedColumn<int>(
    'zaman_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonVeriMeta = const VerificationMeta(
    'jsonVeri',
  );
  @override
  late final GeneratedColumn<String> jsonVeri = GeneratedColumn<String>(
    'json_veri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, zone, zamanMillis, jsonVeri];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sensor_okumalari';
  @override
  VerificationContext validateIntegrity(
    Insertable<SensorOkumalariData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('zone')) {
      context.handle(
        _zoneMeta,
        zone.isAcceptableOrUnknown(data['zone']!, _zoneMeta),
      );
    } else if (isInserting) {
      context.missing(_zoneMeta);
    }
    if (data.containsKey('zaman_millis')) {
      context.handle(
        _zamanMillisMeta,
        zamanMillis.isAcceptableOrUnknown(
          data['zaman_millis']!,
          _zamanMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_zamanMillisMeta);
    }
    if (data.containsKey('json_veri')) {
      context.handle(
        _jsonVeriMeta,
        jsonVeri.isAcceptableOrUnknown(data['json_veri']!, _jsonVeriMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonVeriMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SensorOkumalariData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SensorOkumalariData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      zone: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}zone'],
      )!,
      zamanMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}zaman_millis'],
      )!,
      jsonVeri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_veri'],
      )!,
    );
  }

  @override
  $SensorOkumalariTable createAlias(String alias) {
    return $SensorOkumalariTable(attachedDatabase, alias);
  }
}

class SensorOkumalariData extends DataClass
    implements Insertable<SensorOkumalariData> {
  final int id;
  final int zone;
  final int zamanMillis;
  final String jsonVeri;
  const SensorOkumalariData({
    required this.id,
    required this.zone,
    required this.zamanMillis,
    required this.jsonVeri,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['zone'] = Variable<int>(zone);
    map['zaman_millis'] = Variable<int>(zamanMillis);
    map['json_veri'] = Variable<String>(jsonVeri);
    return map;
  }

  SensorOkumalariCompanion toCompanion(bool nullToAbsent) {
    return SensorOkumalariCompanion(
      id: Value(id),
      zone: Value(zone),
      zamanMillis: Value(zamanMillis),
      jsonVeri: Value(jsonVeri),
    );
  }

  factory SensorOkumalariData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SensorOkumalariData(
      id: serializer.fromJson<int>(json['id']),
      zone: serializer.fromJson<int>(json['zone']),
      zamanMillis: serializer.fromJson<int>(json['zamanMillis']),
      jsonVeri: serializer.fromJson<String>(json['jsonVeri']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'zone': serializer.toJson<int>(zone),
      'zamanMillis': serializer.toJson<int>(zamanMillis),
      'jsonVeri': serializer.toJson<String>(jsonVeri),
    };
  }

  SensorOkumalariData copyWith({
    int? id,
    int? zone,
    int? zamanMillis,
    String? jsonVeri,
  }) => SensorOkumalariData(
    id: id ?? this.id,
    zone: zone ?? this.zone,
    zamanMillis: zamanMillis ?? this.zamanMillis,
    jsonVeri: jsonVeri ?? this.jsonVeri,
  );
  SensorOkumalariData copyWithCompanion(SensorOkumalariCompanion data) {
    return SensorOkumalariData(
      id: data.id.present ? data.id.value : this.id,
      zone: data.zone.present ? data.zone.value : this.zone,
      zamanMillis: data.zamanMillis.present
          ? data.zamanMillis.value
          : this.zamanMillis,
      jsonVeri: data.jsonVeri.present ? data.jsonVeri.value : this.jsonVeri,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SensorOkumalariData(')
          ..write('id: $id, ')
          ..write('zone: $zone, ')
          ..write('zamanMillis: $zamanMillis, ')
          ..write('jsonVeri: $jsonVeri')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, zone, zamanMillis, jsonVeri);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SensorOkumalariData &&
          other.id == this.id &&
          other.zone == this.zone &&
          other.zamanMillis == this.zamanMillis &&
          other.jsonVeri == this.jsonVeri);
}

class SensorOkumalariCompanion extends UpdateCompanion<SensorOkumalariData> {
  final Value<int> id;
  final Value<int> zone;
  final Value<int> zamanMillis;
  final Value<String> jsonVeri;
  const SensorOkumalariCompanion({
    this.id = const Value.absent(),
    this.zone = const Value.absent(),
    this.zamanMillis = const Value.absent(),
    this.jsonVeri = const Value.absent(),
  });
  SensorOkumalariCompanion.insert({
    this.id = const Value.absent(),
    required int zone,
    required int zamanMillis,
    required String jsonVeri,
  }) : zone = Value(zone),
       zamanMillis = Value(zamanMillis),
       jsonVeri = Value(jsonVeri);
  static Insertable<SensorOkumalariData> custom({
    Expression<int>? id,
    Expression<int>? zone,
    Expression<int>? zamanMillis,
    Expression<String>? jsonVeri,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (zone != null) 'zone': zone,
      if (zamanMillis != null) 'zaman_millis': zamanMillis,
      if (jsonVeri != null) 'json_veri': jsonVeri,
    });
  }

  SensorOkumalariCompanion copyWith({
    Value<int>? id,
    Value<int>? zone,
    Value<int>? zamanMillis,
    Value<String>? jsonVeri,
  }) {
    return SensorOkumalariCompanion(
      id: id ?? this.id,
      zone: zone ?? this.zone,
      zamanMillis: zamanMillis ?? this.zamanMillis,
      jsonVeri: jsonVeri ?? this.jsonVeri,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (zone.present) {
      map['zone'] = Variable<int>(zone.value);
    }
    if (zamanMillis.present) {
      map['zaman_millis'] = Variable<int>(zamanMillis.value);
    }
    if (jsonVeri.present) {
      map['json_veri'] = Variable<String>(jsonVeri.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SensorOkumalariCompanion(')
          ..write('id: $id, ')
          ..write('zone: $zone, ')
          ..write('zamanMillis: $zamanMillis, ')
          ..write('jsonVeri: $jsonVeri')
          ..write(')'))
        .toString();
  }
}

class $SonOkumalarTable extends SonOkumalar
    with TableInfo<$SonOkumalarTable, SonOkumalarData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SonOkumalarTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _zoneMeta = const VerificationMeta('zone');
  @override
  late final GeneratedColumn<int> zone = GeneratedColumn<int>(
    'zone',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsonVeriMeta = const VerificationMeta(
    'jsonVeri',
  );
  @override
  late final GeneratedColumn<String> jsonVeri = GeneratedColumn<String>(
    'json_veri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [zone, jsonVeri];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'son_okumalar';
  @override
  VerificationContext validateIntegrity(
    Insertable<SonOkumalarData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('zone')) {
      context.handle(
        _zoneMeta,
        zone.isAcceptableOrUnknown(data['zone']!, _zoneMeta),
      );
    }
    if (data.containsKey('json_veri')) {
      context.handle(
        _jsonVeriMeta,
        jsonVeri.isAcceptableOrUnknown(data['json_veri']!, _jsonVeriMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonVeriMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {zone};
  @override
  SonOkumalarData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SonOkumalarData(
      zone: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}zone'],
      )!,
      jsonVeri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_veri'],
      )!,
    );
  }

  @override
  $SonOkumalarTable createAlias(String alias) {
    return $SonOkumalarTable(attachedDatabase, alias);
  }
}

class SonOkumalarData extends DataClass implements Insertable<SonOkumalarData> {
  final int zone;
  final String jsonVeri;
  const SonOkumalarData({required this.zone, required this.jsonVeri});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['zone'] = Variable<int>(zone);
    map['json_veri'] = Variable<String>(jsonVeri);
    return map;
  }

  SonOkumalarCompanion toCompanion(bool nullToAbsent) {
    return SonOkumalarCompanion(zone: Value(zone), jsonVeri: Value(jsonVeri));
  }

  factory SonOkumalarData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SonOkumalarData(
      zone: serializer.fromJson<int>(json['zone']),
      jsonVeri: serializer.fromJson<String>(json['jsonVeri']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'zone': serializer.toJson<int>(zone),
      'jsonVeri': serializer.toJson<String>(jsonVeri),
    };
  }

  SonOkumalarData copyWith({int? zone, String? jsonVeri}) => SonOkumalarData(
    zone: zone ?? this.zone,
    jsonVeri: jsonVeri ?? this.jsonVeri,
  );
  SonOkumalarData copyWithCompanion(SonOkumalarCompanion data) {
    return SonOkumalarData(
      zone: data.zone.present ? data.zone.value : this.zone,
      jsonVeri: data.jsonVeri.present ? data.jsonVeri.value : this.jsonVeri,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SonOkumalarData(')
          ..write('zone: $zone, ')
          ..write('jsonVeri: $jsonVeri')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(zone, jsonVeri);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SonOkumalarData &&
          other.zone == this.zone &&
          other.jsonVeri == this.jsonVeri);
}

class SonOkumalarCompanion extends UpdateCompanion<SonOkumalarData> {
  final Value<int> zone;
  final Value<String> jsonVeri;
  const SonOkumalarCompanion({
    this.zone = const Value.absent(),
    this.jsonVeri = const Value.absent(),
  });
  SonOkumalarCompanion.insert({
    this.zone = const Value.absent(),
    required String jsonVeri,
  }) : jsonVeri = Value(jsonVeri);
  static Insertable<SonOkumalarData> custom({
    Expression<int>? zone,
    Expression<String>? jsonVeri,
  }) {
    return RawValuesInsertable({
      if (zone != null) 'zone': zone,
      if (jsonVeri != null) 'json_veri': jsonVeri,
    });
  }

  SonOkumalarCompanion copyWith({Value<int>? zone, Value<String>? jsonVeri}) {
    return SonOkumalarCompanion(
      zone: zone ?? this.zone,
      jsonVeri: jsonVeri ?? this.jsonVeri,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (zone.present) {
      map['zone'] = Variable<int>(zone.value);
    }
    if (jsonVeri.present) {
      map['json_veri'] = Variable<String>(jsonVeri.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SonOkumalarCompanion(')
          ..write('zone: $zone, ')
          ..write('jsonVeri: $jsonVeri')
          ..write(')'))
        .toString();
  }
}

class $AktiviteKayitlariTable extends AktiviteKayitlari
    with TableInfo<$AktiviteKayitlariTable, AktiviteKayitlariData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AktiviteKayitlariTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _zamanMillisMeta = const VerificationMeta(
    'zamanMillis',
  );
  @override
  late final GeneratedColumn<int> zamanMillis = GeneratedColumn<int>(
    'zaman_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonVeriMeta = const VerificationMeta(
    'jsonVeri',
  );
  @override
  late final GeneratedColumn<String> jsonVeri = GeneratedColumn<String>(
    'json_veri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, zamanMillis, jsonVeri];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'aktivite_kayitlari';
  @override
  VerificationContext validateIntegrity(
    Insertable<AktiviteKayitlariData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('zaman_millis')) {
      context.handle(
        _zamanMillisMeta,
        zamanMillis.isAcceptableOrUnknown(
          data['zaman_millis']!,
          _zamanMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_zamanMillisMeta);
    }
    if (data.containsKey('json_veri')) {
      context.handle(
        _jsonVeriMeta,
        jsonVeri.isAcceptableOrUnknown(data['json_veri']!, _jsonVeriMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonVeriMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AktiviteKayitlariData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AktiviteKayitlariData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      zamanMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}zaman_millis'],
      )!,
      jsonVeri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_veri'],
      )!,
    );
  }

  @override
  $AktiviteKayitlariTable createAlias(String alias) {
    return $AktiviteKayitlariTable(attachedDatabase, alias);
  }
}

class AktiviteKayitlariData extends DataClass
    implements Insertable<AktiviteKayitlariData> {
  final int id;
  final int zamanMillis;
  final String jsonVeri;
  const AktiviteKayitlariData({
    required this.id,
    required this.zamanMillis,
    required this.jsonVeri,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['zaman_millis'] = Variable<int>(zamanMillis);
    map['json_veri'] = Variable<String>(jsonVeri);
    return map;
  }

  AktiviteKayitlariCompanion toCompanion(bool nullToAbsent) {
    return AktiviteKayitlariCompanion(
      id: Value(id),
      zamanMillis: Value(zamanMillis),
      jsonVeri: Value(jsonVeri),
    );
  }

  factory AktiviteKayitlariData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AktiviteKayitlariData(
      id: serializer.fromJson<int>(json['id']),
      zamanMillis: serializer.fromJson<int>(json['zamanMillis']),
      jsonVeri: serializer.fromJson<String>(json['jsonVeri']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'zamanMillis': serializer.toJson<int>(zamanMillis),
      'jsonVeri': serializer.toJson<String>(jsonVeri),
    };
  }

  AktiviteKayitlariData copyWith({
    int? id,
    int? zamanMillis,
    String? jsonVeri,
  }) => AktiviteKayitlariData(
    id: id ?? this.id,
    zamanMillis: zamanMillis ?? this.zamanMillis,
    jsonVeri: jsonVeri ?? this.jsonVeri,
  );
  AktiviteKayitlariData copyWithCompanion(AktiviteKayitlariCompanion data) {
    return AktiviteKayitlariData(
      id: data.id.present ? data.id.value : this.id,
      zamanMillis: data.zamanMillis.present
          ? data.zamanMillis.value
          : this.zamanMillis,
      jsonVeri: data.jsonVeri.present ? data.jsonVeri.value : this.jsonVeri,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AktiviteKayitlariData(')
          ..write('id: $id, ')
          ..write('zamanMillis: $zamanMillis, ')
          ..write('jsonVeri: $jsonVeri')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, zamanMillis, jsonVeri);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AktiviteKayitlariData &&
          other.id == this.id &&
          other.zamanMillis == this.zamanMillis &&
          other.jsonVeri == this.jsonVeri);
}

class AktiviteKayitlariCompanion
    extends UpdateCompanion<AktiviteKayitlariData> {
  final Value<int> id;
  final Value<int> zamanMillis;
  final Value<String> jsonVeri;
  const AktiviteKayitlariCompanion({
    this.id = const Value.absent(),
    this.zamanMillis = const Value.absent(),
    this.jsonVeri = const Value.absent(),
  });
  AktiviteKayitlariCompanion.insert({
    this.id = const Value.absent(),
    required int zamanMillis,
    required String jsonVeri,
  }) : zamanMillis = Value(zamanMillis),
       jsonVeri = Value(jsonVeri);
  static Insertable<AktiviteKayitlariData> custom({
    Expression<int>? id,
    Expression<int>? zamanMillis,
    Expression<String>? jsonVeri,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (zamanMillis != null) 'zaman_millis': zamanMillis,
      if (jsonVeri != null) 'json_veri': jsonVeri,
    });
  }

  AktiviteKayitlariCompanion copyWith({
    Value<int>? id,
    Value<int>? zamanMillis,
    Value<String>? jsonVeri,
  }) {
    return AktiviteKayitlariCompanion(
      id: id ?? this.id,
      zamanMillis: zamanMillis ?? this.zamanMillis,
      jsonVeri: jsonVeri ?? this.jsonVeri,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (zamanMillis.present) {
      map['zaman_millis'] = Variable<int>(zamanMillis.value);
    }
    if (jsonVeri.present) {
      map['json_veri'] = Variable<String>(jsonVeri.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AktiviteKayitlariCompanion(')
          ..write('id: $id, ')
          ..write('zamanMillis: $zamanMillis, ')
          ..write('jsonVeri: $jsonVeri')
          ..write(')'))
        .toString();
  }
}

class $BildirimGecmisiTable extends BildirimGecmisi
    with TableInfo<$BildirimGecmisiTable, BildirimGecmisiData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BildirimGecmisiTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _zamanMillisMeta = const VerificationMeta(
    'zamanMillis',
  );
  @override
  late final GeneratedColumn<int> zamanMillis = GeneratedColumn<int>(
    'zaman_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonVeriMeta = const VerificationMeta(
    'jsonVeri',
  );
  @override
  late final GeneratedColumn<String> jsonVeri = GeneratedColumn<String>(
    'json_veri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, zamanMillis, jsonVeri];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bildirim_gecmisi';
  @override
  VerificationContext validateIntegrity(
    Insertable<BildirimGecmisiData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('zaman_millis')) {
      context.handle(
        _zamanMillisMeta,
        zamanMillis.isAcceptableOrUnknown(
          data['zaman_millis']!,
          _zamanMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_zamanMillisMeta);
    }
    if (data.containsKey('json_veri')) {
      context.handle(
        _jsonVeriMeta,
        jsonVeri.isAcceptableOrUnknown(data['json_veri']!, _jsonVeriMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonVeriMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BildirimGecmisiData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BildirimGecmisiData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      zamanMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}zaman_millis'],
      )!,
      jsonVeri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_veri'],
      )!,
    );
  }

  @override
  $BildirimGecmisiTable createAlias(String alias) {
    return $BildirimGecmisiTable(attachedDatabase, alias);
  }
}

class BildirimGecmisiData extends DataClass
    implements Insertable<BildirimGecmisiData> {
  final int id;
  final int zamanMillis;
  final String jsonVeri;
  const BildirimGecmisiData({
    required this.id,
    required this.zamanMillis,
    required this.jsonVeri,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['zaman_millis'] = Variable<int>(zamanMillis);
    map['json_veri'] = Variable<String>(jsonVeri);
    return map;
  }

  BildirimGecmisiCompanion toCompanion(bool nullToAbsent) {
    return BildirimGecmisiCompanion(
      id: Value(id),
      zamanMillis: Value(zamanMillis),
      jsonVeri: Value(jsonVeri),
    );
  }

  factory BildirimGecmisiData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BildirimGecmisiData(
      id: serializer.fromJson<int>(json['id']),
      zamanMillis: serializer.fromJson<int>(json['zamanMillis']),
      jsonVeri: serializer.fromJson<String>(json['jsonVeri']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'zamanMillis': serializer.toJson<int>(zamanMillis),
      'jsonVeri': serializer.toJson<String>(jsonVeri),
    };
  }

  BildirimGecmisiData copyWith({int? id, int? zamanMillis, String? jsonVeri}) =>
      BildirimGecmisiData(
        id: id ?? this.id,
        zamanMillis: zamanMillis ?? this.zamanMillis,
        jsonVeri: jsonVeri ?? this.jsonVeri,
      );
  BildirimGecmisiData copyWithCompanion(BildirimGecmisiCompanion data) {
    return BildirimGecmisiData(
      id: data.id.present ? data.id.value : this.id,
      zamanMillis: data.zamanMillis.present
          ? data.zamanMillis.value
          : this.zamanMillis,
      jsonVeri: data.jsonVeri.present ? data.jsonVeri.value : this.jsonVeri,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BildirimGecmisiData(')
          ..write('id: $id, ')
          ..write('zamanMillis: $zamanMillis, ')
          ..write('jsonVeri: $jsonVeri')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, zamanMillis, jsonVeri);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BildirimGecmisiData &&
          other.id == this.id &&
          other.zamanMillis == this.zamanMillis &&
          other.jsonVeri == this.jsonVeri);
}

class BildirimGecmisiCompanion extends UpdateCompanion<BildirimGecmisiData> {
  final Value<int> id;
  final Value<int> zamanMillis;
  final Value<String> jsonVeri;
  const BildirimGecmisiCompanion({
    this.id = const Value.absent(),
    this.zamanMillis = const Value.absent(),
    this.jsonVeri = const Value.absent(),
  });
  BildirimGecmisiCompanion.insert({
    this.id = const Value.absent(),
    required int zamanMillis,
    required String jsonVeri,
  }) : zamanMillis = Value(zamanMillis),
       jsonVeri = Value(jsonVeri);
  static Insertable<BildirimGecmisiData> custom({
    Expression<int>? id,
    Expression<int>? zamanMillis,
    Expression<String>? jsonVeri,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (zamanMillis != null) 'zaman_millis': zamanMillis,
      if (jsonVeri != null) 'json_veri': jsonVeri,
    });
  }

  BildirimGecmisiCompanion copyWith({
    Value<int>? id,
    Value<int>? zamanMillis,
    Value<String>? jsonVeri,
  }) {
    return BildirimGecmisiCompanion(
      id: id ?? this.id,
      zamanMillis: zamanMillis ?? this.zamanMillis,
      jsonVeri: jsonVeri ?? this.jsonVeri,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (zamanMillis.present) {
      map['zaman_millis'] = Variable<int>(zamanMillis.value);
    }
    if (jsonVeri.present) {
      map['json_veri'] = Variable<String>(jsonVeri.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BildirimGecmisiCompanion(')
          ..write('id: $id, ')
          ..write('zamanMillis: $zamanMillis, ')
          ..write('jsonVeri: $jsonVeri')
          ..write(')'))
        .toString();
  }
}

class $TarlaNotlariTable extends TarlaNotlari
    with TableInfo<$TarlaNotlariTable, TarlaNotlariData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TarlaNotlariTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tarlaIdMeta = const VerificationMeta(
    'tarlaId',
  );
  @override
  late final GeneratedColumn<String> tarlaId = GeneratedColumn<String>(
    'tarla_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zamanMillisMeta = const VerificationMeta(
    'zamanMillis',
  );
  @override
  late final GeneratedColumn<int> zamanMillis = GeneratedColumn<int>(
    'zaman_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonVeriMeta = const VerificationMeta(
    'jsonVeri',
  );
  @override
  late final GeneratedColumn<String> jsonVeri = GeneratedColumn<String>(
    'json_veri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, tarlaId, zamanMillis, jsonVeri];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tarla_notlari';
  @override
  VerificationContext validateIntegrity(
    Insertable<TarlaNotlariData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tarla_id')) {
      context.handle(
        _tarlaIdMeta,
        tarlaId.isAcceptableOrUnknown(data['tarla_id']!, _tarlaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tarlaIdMeta);
    }
    if (data.containsKey('zaman_millis')) {
      context.handle(
        _zamanMillisMeta,
        zamanMillis.isAcceptableOrUnknown(
          data['zaman_millis']!,
          _zamanMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_zamanMillisMeta);
    }
    if (data.containsKey('json_veri')) {
      context.handle(
        _jsonVeriMeta,
        jsonVeri.isAcceptableOrUnknown(data['json_veri']!, _jsonVeriMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonVeriMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TarlaNotlariData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TarlaNotlariData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tarlaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tarla_id'],
      )!,
      zamanMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}zaman_millis'],
      )!,
      jsonVeri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_veri'],
      )!,
    );
  }

  @override
  $TarlaNotlariTable createAlias(String alias) {
    return $TarlaNotlariTable(attachedDatabase, alias);
  }
}

class TarlaNotlariData extends DataClass
    implements Insertable<TarlaNotlariData> {
  final String id;
  final String tarlaId;
  final int zamanMillis;
  final String jsonVeri;
  const TarlaNotlariData({
    required this.id,
    required this.tarlaId,
    required this.zamanMillis,
    required this.jsonVeri,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tarla_id'] = Variable<String>(tarlaId);
    map['zaman_millis'] = Variable<int>(zamanMillis);
    map['json_veri'] = Variable<String>(jsonVeri);
    return map;
  }

  TarlaNotlariCompanion toCompanion(bool nullToAbsent) {
    return TarlaNotlariCompanion(
      id: Value(id),
      tarlaId: Value(tarlaId),
      zamanMillis: Value(zamanMillis),
      jsonVeri: Value(jsonVeri),
    );
  }

  factory TarlaNotlariData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TarlaNotlariData(
      id: serializer.fromJson<String>(json['id']),
      tarlaId: serializer.fromJson<String>(json['tarlaId']),
      zamanMillis: serializer.fromJson<int>(json['zamanMillis']),
      jsonVeri: serializer.fromJson<String>(json['jsonVeri']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tarlaId': serializer.toJson<String>(tarlaId),
      'zamanMillis': serializer.toJson<int>(zamanMillis),
      'jsonVeri': serializer.toJson<String>(jsonVeri),
    };
  }

  TarlaNotlariData copyWith({
    String? id,
    String? tarlaId,
    int? zamanMillis,
    String? jsonVeri,
  }) => TarlaNotlariData(
    id: id ?? this.id,
    tarlaId: tarlaId ?? this.tarlaId,
    zamanMillis: zamanMillis ?? this.zamanMillis,
    jsonVeri: jsonVeri ?? this.jsonVeri,
  );
  TarlaNotlariData copyWithCompanion(TarlaNotlariCompanion data) {
    return TarlaNotlariData(
      id: data.id.present ? data.id.value : this.id,
      tarlaId: data.tarlaId.present ? data.tarlaId.value : this.tarlaId,
      zamanMillis: data.zamanMillis.present
          ? data.zamanMillis.value
          : this.zamanMillis,
      jsonVeri: data.jsonVeri.present ? data.jsonVeri.value : this.jsonVeri,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TarlaNotlariData(')
          ..write('id: $id, ')
          ..write('tarlaId: $tarlaId, ')
          ..write('zamanMillis: $zamanMillis, ')
          ..write('jsonVeri: $jsonVeri')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tarlaId, zamanMillis, jsonVeri);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TarlaNotlariData &&
          other.id == this.id &&
          other.tarlaId == this.tarlaId &&
          other.zamanMillis == this.zamanMillis &&
          other.jsonVeri == this.jsonVeri);
}

class TarlaNotlariCompanion extends UpdateCompanion<TarlaNotlariData> {
  final Value<String> id;
  final Value<String> tarlaId;
  final Value<int> zamanMillis;
  final Value<String> jsonVeri;
  final Value<int> rowid;
  const TarlaNotlariCompanion({
    this.id = const Value.absent(),
    this.tarlaId = const Value.absent(),
    this.zamanMillis = const Value.absent(),
    this.jsonVeri = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TarlaNotlariCompanion.insert({
    required String id,
    required String tarlaId,
    required int zamanMillis,
    required String jsonVeri,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tarlaId = Value(tarlaId),
       zamanMillis = Value(zamanMillis),
       jsonVeri = Value(jsonVeri);
  static Insertable<TarlaNotlariData> custom({
    Expression<String>? id,
    Expression<String>? tarlaId,
    Expression<int>? zamanMillis,
    Expression<String>? jsonVeri,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tarlaId != null) 'tarla_id': tarlaId,
      if (zamanMillis != null) 'zaman_millis': zamanMillis,
      if (jsonVeri != null) 'json_veri': jsonVeri,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TarlaNotlariCompanion copyWith({
    Value<String>? id,
    Value<String>? tarlaId,
    Value<int>? zamanMillis,
    Value<String>? jsonVeri,
    Value<int>? rowid,
  }) {
    return TarlaNotlariCompanion(
      id: id ?? this.id,
      tarlaId: tarlaId ?? this.tarlaId,
      zamanMillis: zamanMillis ?? this.zamanMillis,
      jsonVeri: jsonVeri ?? this.jsonVeri,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tarlaId.present) {
      map['tarla_id'] = Variable<String>(tarlaId.value);
    }
    if (zamanMillis.present) {
      map['zaman_millis'] = Variable<int>(zamanMillis.value);
    }
    if (jsonVeri.present) {
      map['json_veri'] = Variable<String>(jsonVeri.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TarlaNotlariCompanion(')
          ..write('id: $id, ')
          ..write('tarlaId: $tarlaId, ')
          ..write('zamanMillis: $zamanMillis, ')
          ..write('jsonVeri: $jsonVeri, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AquaGuardVeritabani extends GeneratedDatabase {
  _$AquaGuardVeritabani(QueryExecutor e) : super(e);
  $AquaGuardVeritabaniManager get managers => $AquaGuardVeritabaniManager(this);
  late final $SensorOkumalariTable sensorOkumalari = $SensorOkumalariTable(
    this,
  );
  late final $SonOkumalarTable sonOkumalar = $SonOkumalarTable(this);
  late final $AktiviteKayitlariTable aktiviteKayitlari =
      $AktiviteKayitlariTable(this);
  late final $BildirimGecmisiTable bildirimGecmisi = $BildirimGecmisiTable(
    this,
  );
  late final $TarlaNotlariTable tarlaNotlari = $TarlaNotlariTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sensorOkumalari,
    sonOkumalar,
    aktiviteKayitlari,
    bildirimGecmisi,
    tarlaNotlari,
  ];
}

typedef $$SensorOkumalariTableCreateCompanionBuilder =
    SensorOkumalariCompanion Function({
      Value<int> id,
      required int zone,
      required int zamanMillis,
      required String jsonVeri,
    });
typedef $$SensorOkumalariTableUpdateCompanionBuilder =
    SensorOkumalariCompanion Function({
      Value<int> id,
      Value<int> zone,
      Value<int> zamanMillis,
      Value<String> jsonVeri,
    });

class $$SensorOkumalariTableFilterComposer
    extends Composer<_$AquaGuardVeritabani, $SensorOkumalariTable> {
  $$SensorOkumalariTableFilterComposer({
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

  ColumnFilters<int> get zone => $composableBuilder(
    column: $table.zone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get zamanMillis => $composableBuilder(
    column: $table.zamanMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonVeri => $composableBuilder(
    column: $table.jsonVeri,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SensorOkumalariTableOrderingComposer
    extends Composer<_$AquaGuardVeritabani, $SensorOkumalariTable> {
  $$SensorOkumalariTableOrderingComposer({
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

  ColumnOrderings<int> get zone => $composableBuilder(
    column: $table.zone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get zamanMillis => $composableBuilder(
    column: $table.zamanMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonVeri => $composableBuilder(
    column: $table.jsonVeri,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SensorOkumalariTableAnnotationComposer
    extends Composer<_$AquaGuardVeritabani, $SensorOkumalariTable> {
  $$SensorOkumalariTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get zone =>
      $composableBuilder(column: $table.zone, builder: (column) => column);

  GeneratedColumn<int> get zamanMillis => $composableBuilder(
    column: $table.zamanMillis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jsonVeri =>
      $composableBuilder(column: $table.jsonVeri, builder: (column) => column);
}

class $$SensorOkumalariTableTableManager
    extends
        RootTableManager<
          _$AquaGuardVeritabani,
          $SensorOkumalariTable,
          SensorOkumalariData,
          $$SensorOkumalariTableFilterComposer,
          $$SensorOkumalariTableOrderingComposer,
          $$SensorOkumalariTableAnnotationComposer,
          $$SensorOkumalariTableCreateCompanionBuilder,
          $$SensorOkumalariTableUpdateCompanionBuilder,
          (
            SensorOkumalariData,
            BaseReferences<
              _$AquaGuardVeritabani,
              $SensorOkumalariTable,
              SensorOkumalariData
            >,
          ),
          SensorOkumalariData,
          PrefetchHooks Function()
        > {
  $$SensorOkumalariTableTableManager(
    _$AquaGuardVeritabani db,
    $SensorOkumalariTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SensorOkumalariTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SensorOkumalariTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SensorOkumalariTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> zone = const Value.absent(),
                Value<int> zamanMillis = const Value.absent(),
                Value<String> jsonVeri = const Value.absent(),
              }) => SensorOkumalariCompanion(
                id: id,
                zone: zone,
                zamanMillis: zamanMillis,
                jsonVeri: jsonVeri,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int zone,
                required int zamanMillis,
                required String jsonVeri,
              }) => SensorOkumalariCompanion.insert(
                id: id,
                zone: zone,
                zamanMillis: zamanMillis,
                jsonVeri: jsonVeri,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SensorOkumalariTable, SensorOkumalariData>(
                    table,
                  ),
                  BaseReferences<
                    _$AquaGuardVeritabani,
                    $SensorOkumalariTable,
                    SensorOkumalariData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SensorOkumalariTableProcessedTableManager =
    ProcessedTableManager<
      _$AquaGuardVeritabani,
      $SensorOkumalariTable,
      SensorOkumalariData,
      $$SensorOkumalariTableFilterComposer,
      $$SensorOkumalariTableOrderingComposer,
      $$SensorOkumalariTableAnnotationComposer,
      $$SensorOkumalariTableCreateCompanionBuilder,
      $$SensorOkumalariTableUpdateCompanionBuilder,
      (
        SensorOkumalariData,
        BaseReferences<
          _$AquaGuardVeritabani,
          $SensorOkumalariTable,
          SensorOkumalariData
        >,
      ),
      SensorOkumalariData,
      PrefetchHooks Function()
    >;
typedef $$SonOkumalarTableCreateCompanionBuilder =
    SonOkumalarCompanion Function({Value<int> zone, required String jsonVeri});
typedef $$SonOkumalarTableUpdateCompanionBuilder =
    SonOkumalarCompanion Function({Value<int> zone, Value<String> jsonVeri});

class $$SonOkumalarTableFilterComposer
    extends Composer<_$AquaGuardVeritabani, $SonOkumalarTable> {
  $$SonOkumalarTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get zone => $composableBuilder(
    column: $table.zone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonVeri => $composableBuilder(
    column: $table.jsonVeri,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SonOkumalarTableOrderingComposer
    extends Composer<_$AquaGuardVeritabani, $SonOkumalarTable> {
  $$SonOkumalarTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get zone => $composableBuilder(
    column: $table.zone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonVeri => $composableBuilder(
    column: $table.jsonVeri,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SonOkumalarTableAnnotationComposer
    extends Composer<_$AquaGuardVeritabani, $SonOkumalarTable> {
  $$SonOkumalarTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get zone =>
      $composableBuilder(column: $table.zone, builder: (column) => column);

  GeneratedColumn<String> get jsonVeri =>
      $composableBuilder(column: $table.jsonVeri, builder: (column) => column);
}

class $$SonOkumalarTableTableManager
    extends
        RootTableManager<
          _$AquaGuardVeritabani,
          $SonOkumalarTable,
          SonOkumalarData,
          $$SonOkumalarTableFilterComposer,
          $$SonOkumalarTableOrderingComposer,
          $$SonOkumalarTableAnnotationComposer,
          $$SonOkumalarTableCreateCompanionBuilder,
          $$SonOkumalarTableUpdateCompanionBuilder,
          (
            SonOkumalarData,
            BaseReferences<
              _$AquaGuardVeritabani,
              $SonOkumalarTable,
              SonOkumalarData
            >,
          ),
          SonOkumalarData,
          PrefetchHooks Function()
        > {
  $$SonOkumalarTableTableManager(
    _$AquaGuardVeritabani db,
    $SonOkumalarTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SonOkumalarTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SonOkumalarTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SonOkumalarTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> zone = const Value.absent(),
                Value<String> jsonVeri = const Value.absent(),
              }) => SonOkumalarCompanion(zone: zone, jsonVeri: jsonVeri),
          createCompanionCallback:
              ({
                Value<int> zone = const Value.absent(),
                required String jsonVeri,
              }) => SonOkumalarCompanion.insert(zone: zone, jsonVeri: jsonVeri),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SonOkumalarTable, SonOkumalarData>(table),
                  BaseReferences<
                    _$AquaGuardVeritabani,
                    $SonOkumalarTable,
                    SonOkumalarData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SonOkumalarTableProcessedTableManager =
    ProcessedTableManager<
      _$AquaGuardVeritabani,
      $SonOkumalarTable,
      SonOkumalarData,
      $$SonOkumalarTableFilterComposer,
      $$SonOkumalarTableOrderingComposer,
      $$SonOkumalarTableAnnotationComposer,
      $$SonOkumalarTableCreateCompanionBuilder,
      $$SonOkumalarTableUpdateCompanionBuilder,
      (
        SonOkumalarData,
        BaseReferences<
          _$AquaGuardVeritabani,
          $SonOkumalarTable,
          SonOkumalarData
        >,
      ),
      SonOkumalarData,
      PrefetchHooks Function()
    >;
typedef $$AktiviteKayitlariTableCreateCompanionBuilder =
    AktiviteKayitlariCompanion Function({
      Value<int> id,
      required int zamanMillis,
      required String jsonVeri,
    });
typedef $$AktiviteKayitlariTableUpdateCompanionBuilder =
    AktiviteKayitlariCompanion Function({
      Value<int> id,
      Value<int> zamanMillis,
      Value<String> jsonVeri,
    });

class $$AktiviteKayitlariTableFilterComposer
    extends Composer<_$AquaGuardVeritabani, $AktiviteKayitlariTable> {
  $$AktiviteKayitlariTableFilterComposer({
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

  ColumnFilters<int> get zamanMillis => $composableBuilder(
    column: $table.zamanMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonVeri => $composableBuilder(
    column: $table.jsonVeri,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AktiviteKayitlariTableOrderingComposer
    extends Composer<_$AquaGuardVeritabani, $AktiviteKayitlariTable> {
  $$AktiviteKayitlariTableOrderingComposer({
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

  ColumnOrderings<int> get zamanMillis => $composableBuilder(
    column: $table.zamanMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonVeri => $composableBuilder(
    column: $table.jsonVeri,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AktiviteKayitlariTableAnnotationComposer
    extends Composer<_$AquaGuardVeritabani, $AktiviteKayitlariTable> {
  $$AktiviteKayitlariTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get zamanMillis => $composableBuilder(
    column: $table.zamanMillis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jsonVeri =>
      $composableBuilder(column: $table.jsonVeri, builder: (column) => column);
}

class $$AktiviteKayitlariTableTableManager
    extends
        RootTableManager<
          _$AquaGuardVeritabani,
          $AktiviteKayitlariTable,
          AktiviteKayitlariData,
          $$AktiviteKayitlariTableFilterComposer,
          $$AktiviteKayitlariTableOrderingComposer,
          $$AktiviteKayitlariTableAnnotationComposer,
          $$AktiviteKayitlariTableCreateCompanionBuilder,
          $$AktiviteKayitlariTableUpdateCompanionBuilder,
          (
            AktiviteKayitlariData,
            BaseReferences<
              _$AquaGuardVeritabani,
              $AktiviteKayitlariTable,
              AktiviteKayitlariData
            >,
          ),
          AktiviteKayitlariData,
          PrefetchHooks Function()
        > {
  $$AktiviteKayitlariTableTableManager(
    _$AquaGuardVeritabani db,
    $AktiviteKayitlariTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AktiviteKayitlariTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AktiviteKayitlariTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AktiviteKayitlariTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> zamanMillis = const Value.absent(),
                Value<String> jsonVeri = const Value.absent(),
              }) => AktiviteKayitlariCompanion(
                id: id,
                zamanMillis: zamanMillis,
                jsonVeri: jsonVeri,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int zamanMillis,
                required String jsonVeri,
              }) => AktiviteKayitlariCompanion.insert(
                id: id,
                zamanMillis: zamanMillis,
                jsonVeri: jsonVeri,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AktiviteKayitlariTable, AktiviteKayitlariData>(
                    table,
                  ),
                  BaseReferences<
                    _$AquaGuardVeritabani,
                    $AktiviteKayitlariTable,
                    AktiviteKayitlariData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AktiviteKayitlariTableProcessedTableManager =
    ProcessedTableManager<
      _$AquaGuardVeritabani,
      $AktiviteKayitlariTable,
      AktiviteKayitlariData,
      $$AktiviteKayitlariTableFilterComposer,
      $$AktiviteKayitlariTableOrderingComposer,
      $$AktiviteKayitlariTableAnnotationComposer,
      $$AktiviteKayitlariTableCreateCompanionBuilder,
      $$AktiviteKayitlariTableUpdateCompanionBuilder,
      (
        AktiviteKayitlariData,
        BaseReferences<
          _$AquaGuardVeritabani,
          $AktiviteKayitlariTable,
          AktiviteKayitlariData
        >,
      ),
      AktiviteKayitlariData,
      PrefetchHooks Function()
    >;
typedef $$BildirimGecmisiTableCreateCompanionBuilder =
    BildirimGecmisiCompanion Function({
      Value<int> id,
      required int zamanMillis,
      required String jsonVeri,
    });
typedef $$BildirimGecmisiTableUpdateCompanionBuilder =
    BildirimGecmisiCompanion Function({
      Value<int> id,
      Value<int> zamanMillis,
      Value<String> jsonVeri,
    });

class $$BildirimGecmisiTableFilterComposer
    extends Composer<_$AquaGuardVeritabani, $BildirimGecmisiTable> {
  $$BildirimGecmisiTableFilterComposer({
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

  ColumnFilters<int> get zamanMillis => $composableBuilder(
    column: $table.zamanMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonVeri => $composableBuilder(
    column: $table.jsonVeri,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BildirimGecmisiTableOrderingComposer
    extends Composer<_$AquaGuardVeritabani, $BildirimGecmisiTable> {
  $$BildirimGecmisiTableOrderingComposer({
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

  ColumnOrderings<int> get zamanMillis => $composableBuilder(
    column: $table.zamanMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonVeri => $composableBuilder(
    column: $table.jsonVeri,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BildirimGecmisiTableAnnotationComposer
    extends Composer<_$AquaGuardVeritabani, $BildirimGecmisiTable> {
  $$BildirimGecmisiTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get zamanMillis => $composableBuilder(
    column: $table.zamanMillis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jsonVeri =>
      $composableBuilder(column: $table.jsonVeri, builder: (column) => column);
}

class $$BildirimGecmisiTableTableManager
    extends
        RootTableManager<
          _$AquaGuardVeritabani,
          $BildirimGecmisiTable,
          BildirimGecmisiData,
          $$BildirimGecmisiTableFilterComposer,
          $$BildirimGecmisiTableOrderingComposer,
          $$BildirimGecmisiTableAnnotationComposer,
          $$BildirimGecmisiTableCreateCompanionBuilder,
          $$BildirimGecmisiTableUpdateCompanionBuilder,
          (
            BildirimGecmisiData,
            BaseReferences<
              _$AquaGuardVeritabani,
              $BildirimGecmisiTable,
              BildirimGecmisiData
            >,
          ),
          BildirimGecmisiData,
          PrefetchHooks Function()
        > {
  $$BildirimGecmisiTableTableManager(
    _$AquaGuardVeritabani db,
    $BildirimGecmisiTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BildirimGecmisiTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BildirimGecmisiTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BildirimGecmisiTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> zamanMillis = const Value.absent(),
                Value<String> jsonVeri = const Value.absent(),
              }) => BildirimGecmisiCompanion(
                id: id,
                zamanMillis: zamanMillis,
                jsonVeri: jsonVeri,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int zamanMillis,
                required String jsonVeri,
              }) => BildirimGecmisiCompanion.insert(
                id: id,
                zamanMillis: zamanMillis,
                jsonVeri: jsonVeri,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BildirimGecmisiTable, BildirimGecmisiData>(
                    table,
                  ),
                  BaseReferences<
                    _$AquaGuardVeritabani,
                    $BildirimGecmisiTable,
                    BildirimGecmisiData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BildirimGecmisiTableProcessedTableManager =
    ProcessedTableManager<
      _$AquaGuardVeritabani,
      $BildirimGecmisiTable,
      BildirimGecmisiData,
      $$BildirimGecmisiTableFilterComposer,
      $$BildirimGecmisiTableOrderingComposer,
      $$BildirimGecmisiTableAnnotationComposer,
      $$BildirimGecmisiTableCreateCompanionBuilder,
      $$BildirimGecmisiTableUpdateCompanionBuilder,
      (
        BildirimGecmisiData,
        BaseReferences<
          _$AquaGuardVeritabani,
          $BildirimGecmisiTable,
          BildirimGecmisiData
        >,
      ),
      BildirimGecmisiData,
      PrefetchHooks Function()
    >;
typedef $$TarlaNotlariTableCreateCompanionBuilder =
    TarlaNotlariCompanion Function({
      required String id,
      required String tarlaId,
      required int zamanMillis,
      required String jsonVeri,
      Value<int> rowid,
    });
typedef $$TarlaNotlariTableUpdateCompanionBuilder =
    TarlaNotlariCompanion Function({
      Value<String> id,
      Value<String> tarlaId,
      Value<int> zamanMillis,
      Value<String> jsonVeri,
      Value<int> rowid,
    });

class $$TarlaNotlariTableFilterComposer
    extends Composer<_$AquaGuardVeritabani, $TarlaNotlariTable> {
  $$TarlaNotlariTableFilterComposer({
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

  ColumnFilters<String> get tarlaId => $composableBuilder(
    column: $table.tarlaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get zamanMillis => $composableBuilder(
    column: $table.zamanMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonVeri => $composableBuilder(
    column: $table.jsonVeri,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TarlaNotlariTableOrderingComposer
    extends Composer<_$AquaGuardVeritabani, $TarlaNotlariTable> {
  $$TarlaNotlariTableOrderingComposer({
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

  ColumnOrderings<String> get tarlaId => $composableBuilder(
    column: $table.tarlaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get zamanMillis => $composableBuilder(
    column: $table.zamanMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonVeri => $composableBuilder(
    column: $table.jsonVeri,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TarlaNotlariTableAnnotationComposer
    extends Composer<_$AquaGuardVeritabani, $TarlaNotlariTable> {
  $$TarlaNotlariTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tarlaId =>
      $composableBuilder(column: $table.tarlaId, builder: (column) => column);

  GeneratedColumn<int> get zamanMillis => $composableBuilder(
    column: $table.zamanMillis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jsonVeri =>
      $composableBuilder(column: $table.jsonVeri, builder: (column) => column);
}

class $$TarlaNotlariTableTableManager
    extends
        RootTableManager<
          _$AquaGuardVeritabani,
          $TarlaNotlariTable,
          TarlaNotlariData,
          $$TarlaNotlariTableFilterComposer,
          $$TarlaNotlariTableOrderingComposer,
          $$TarlaNotlariTableAnnotationComposer,
          $$TarlaNotlariTableCreateCompanionBuilder,
          $$TarlaNotlariTableUpdateCompanionBuilder,
          (
            TarlaNotlariData,
            BaseReferences<
              _$AquaGuardVeritabani,
              $TarlaNotlariTable,
              TarlaNotlariData
            >,
          ),
          TarlaNotlariData,
          PrefetchHooks Function()
        > {
  $$TarlaNotlariTableTableManager(
    _$AquaGuardVeritabani db,
    $TarlaNotlariTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TarlaNotlariTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TarlaNotlariTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TarlaNotlariTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tarlaId = const Value.absent(),
                Value<int> zamanMillis = const Value.absent(),
                Value<String> jsonVeri = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TarlaNotlariCompanion(
                id: id,
                tarlaId: tarlaId,
                zamanMillis: zamanMillis,
                jsonVeri: jsonVeri,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tarlaId,
                required int zamanMillis,
                required String jsonVeri,
                Value<int> rowid = const Value.absent(),
              }) => TarlaNotlariCompanion.insert(
                id: id,
                tarlaId: tarlaId,
                zamanMillis: zamanMillis,
                jsonVeri: jsonVeri,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TarlaNotlariTable, TarlaNotlariData>(table),
                  BaseReferences<
                    _$AquaGuardVeritabani,
                    $TarlaNotlariTable,
                    TarlaNotlariData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TarlaNotlariTableProcessedTableManager =
    ProcessedTableManager<
      _$AquaGuardVeritabani,
      $TarlaNotlariTable,
      TarlaNotlariData,
      $$TarlaNotlariTableFilterComposer,
      $$TarlaNotlariTableOrderingComposer,
      $$TarlaNotlariTableAnnotationComposer,
      $$TarlaNotlariTableCreateCompanionBuilder,
      $$TarlaNotlariTableUpdateCompanionBuilder,
      (
        TarlaNotlariData,
        BaseReferences<
          _$AquaGuardVeritabani,
          $TarlaNotlariTable,
          TarlaNotlariData
        >,
      ),
      TarlaNotlariData,
      PrefetchHooks Function()
    >;

class $AquaGuardVeritabaniManager {
  final _$AquaGuardVeritabani _db;
  $AquaGuardVeritabaniManager(this._db);
  $$SensorOkumalariTableTableManager get sensorOkumalari =>
      $$SensorOkumalariTableTableManager(_db, _db.sensorOkumalari);
  $$SonOkumalarTableTableManager get sonOkumalar =>
      $$SonOkumalarTableTableManager(_db, _db.sonOkumalar);
  $$AktiviteKayitlariTableTableManager get aktiviteKayitlari =>
      $$AktiviteKayitlariTableTableManager(_db, _db.aktiviteKayitlari);
  $$BildirimGecmisiTableTableManager get bildirimGecmisi =>
      $$BildirimGecmisiTableTableManager(_db, _db.bildirimGecmisi);
  $$TarlaNotlariTableTableManager get tarlaNotlari =>
      $$TarlaNotlariTableTableManager(_db, _db.tarlaNotlari);
}
