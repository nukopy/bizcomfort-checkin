import 'dart:convert';
import 'dart:io';

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
  }

  final File _file;
  final List<UnlockRecord> _records = [];

  @override
  List<UnlockRecord> get records => List<UnlockRecord>.unmodifiable(_records);

  @override
  void add(UnlockRecord record) {
    _records.insert(0, record);
    _file.writeAsStringSync(
      jsonEncode(<Object?>[for (final UnlockRecord stored in _records) _toJson(stored)]),
    );
    notifyListeners();
  }
}

Map<String, Object?> _toJson(UnlockRecord record) {
  return <String, Object?>{
    'url': record.url.toString(),
    'at': record.at.toUtc().toIso8601String(),
    'latitude': record.latitude,
    'longitude': record.longitude,
    'locality': record.locality,
    'status': record.status.label,
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
  );
}

double? _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return null;
}
