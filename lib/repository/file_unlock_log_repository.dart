import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bizcomfort_checkin/domain/unlock_record.dart';

class FileUnlockLogRepository extends UnlockLogRepository {
  FileUnlockLogRepository(this._file) {
    if (!_file.existsSync()) {
      return;
    }
    final Object? decoded = jsonDecode(_file.readAsStringSync());
    if (decoded is! List<Object?>) {
      return;
    }
    for (final Object? item in decoded) {
      if (item is! Map) {
        continue;
      }
      _records.add(_fromJson(Map<Object?, Object?>.from(item)));
    }
    _purge(DateTime.now());
  }

  final File _file;
  final List<UnlockRecord> _records = [];

  @override
  List<UnlockRecord> get records => List<UnlockRecord>.unmodifiable(_records);

  @override
  void add(UnlockRecord record) {
    final String? shotName = _writeShot(record);
    _records.insert(0, _withoutBytes(record, shotName));
    _purge(DateTime.now());
    _write();
    notifyListeners();
  }

  @override
  UnlockShot shotFor(UnlockRecord record, {required DateTime now}) {
    if (!shotRetained(record.at, now)) {
      _deleteShot(record.shotName);
      return const UnlockShot.expired();
    }
    final Uint8List? bytes = _readShot(record.shotName);
    if (bytes == null || bytes.isEmpty) {
      return const UnlockShot.missing();
    }
    return UnlockShot.image(bytes);
  }

  void _write() {
    _file.writeAsStringSync(
      jsonEncode(<Object?>[for (final UnlockRecord stored in _records) _toJson(stored)]),
    );
  }

  String? _writeShot(UnlockRecord record) {
    final Uint8List? bytes = record.shotBytes;
    if (bytes == null || bytes.isEmpty) {
      return null;
    }
    final Directory directory = Directory('${_file.parent.path}/unlock-shots');
    directory.createSync(recursive: true);
    final String name = '${record.at.toUtc().microsecondsSinceEpoch}.jpg';
    File('${directory.path}/$name').writeAsBytesSync(bytes);
    return name;
  }

  Uint8List? _readShot(String? name) {
    final File? file = _shotFile(name);
    if (file == null || !file.existsSync()) {
      return null;
    }
    return file.readAsBytesSync();
  }

  void _deleteShot(String? name) {
    final File? file = _shotFile(name);
    if (file != null && file.existsSync()) {
      file.deleteSync();
    }
  }

  File? _shotFile(String? name) {
    if (name == null || name.isEmpty || name.contains('/') || name.contains('..')) {
      return null;
    }
    return File('${_file.parent.path}/unlock-shots/$name');
  }

  void _purge(DateTime now) {
    for (final UnlockRecord record in _records) {
      if (!shotRetained(record.at, now)) {
        _deleteShot(record.shotName);
      }
    }
  }
}

UnlockRecord _withoutBytes(UnlockRecord record, String? shotName) {
  return UnlockRecord(
    url: record.url,
    at: record.at,
    latitude: record.latitude,
    longitude: record.longitude,
    locality: record.locality,
    status: record.status,
    siteName: record.siteName,
    doorName: record.doorName,
    errorMessage: record.errorMessage,
    shotName: shotName,
  );
}

Map<String, Object?> _toJson(UnlockRecord record) {
  return <String, Object?>{
    'url': record.url.toString(),
    'at': record.at.toUtc().toIso8601String(),
    'latitude': record.latitude,
    'longitude': record.longitude,
    'locality': record.locality,
    'status': record.status.label,
    'siteName': record.siteName,
    'doorName': record.doorName,
    'errorMessage': record.errorMessage,
    'shotName': record.shotName,
  };
}

UnlockRecord _fromJson(Map<Object?, Object?> json) {
  return UnlockRecord(
    url: Uri.parse('${json['url']}'),
    at: DateTime.parse('${json['at']}'),
    latitude: _asDouble(json['latitude']),
    longitude: _asDouble(json['longitude']),
    locality: '${json['locality']}',
    status: UnlockStatus.fromLabel('${json['status']}'),
    siteName: json['siteName'] is String ? json['siteName'] as String : '',
    doorName: json['doorName'] is String ? json['doorName'] as String : '',
    errorMessage: json['errorMessage'] is String ? json['errorMessage'] as String : null,
    shotName: json['shotName'] is String ? json['shotName'] as String : null,
  );
}

double? _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return null;
}
