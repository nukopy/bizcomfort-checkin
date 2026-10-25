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
}
