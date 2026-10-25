import 'dart:typed_data';

import 'package:bizcomfort_checkin/domain/unlock_record.dart';

class MemoryUnlockLogRepository extends UnlockLogRepository {
  final List<UnlockRecord> _records = [];

  @override
  List<UnlockRecord> get records => List<UnlockRecord>.unmodifiable(_records);

  @override
  void add(UnlockRecord record) {
    _records.insert(0, record);
    notifyListeners();
  }

  @override
  UnlockShot shotFor(UnlockRecord record, {required DateTime now}) {
    if (!shotRetained(record.at, now)) {
      return const UnlockShot.expired();
    }
    final Uint8List? bytes = record.shotBytes;
    if (bytes == null || bytes.isEmpty) {
      return const UnlockShot.missing();
    }
    return UnlockShot.image(bytes);
  }
}
