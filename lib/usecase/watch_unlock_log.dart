import 'package:bizcomfort_checkin/domain/unlock_record.dart';
import 'package:flutter/foundation.dart';

class WatchUnlockLog {
  const WatchUnlockLog(this._repository);

  final UnlockLogRepository _repository;

  List<UnlockRecord> recordsIn(int year, int month) {
    return _repository.records.where((UnlockRecord record) {
      final DateTime local = record.at.toLocal();
      return local.year == year && local.month == month;
    }).toList();
  }

  Listenable get updates => _repository;

  UnlockRecord? get latest {
    final List<UnlockRecord> records = _repository.records;
    if (records.isEmpty) {
      return null;
    }
    UnlockRecord newest = records.first;
    for (final UnlockRecord record in records.skip(1)) {
      if (record.at.isAfter(newest.at)) {
        newest = record;
      }
    }
    return newest;
  }

  UnlockShot shotFor(UnlockRecord record, {required DateTime now}) {
    return _repository.shotFor(record, now: now);
  }
}
