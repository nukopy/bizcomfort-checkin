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
}
