import 'package:bizcomfort_checkin/domain/credentials.dart';
import 'package:bizcomfort_checkin/domain/unlock_record.dart';
import 'package:bizcomfort_checkin/page/scan/login_runner.dart';
import 'package:bizcomfort_checkin/page/scan/unlock_page_text.dart';
import 'package:bizcomfort_checkin/page/scan/unlock_trace.dart';

class GeoFix {
  const GeoFix(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

abstract class CurrentPositionReader {
  Future<GeoFix?> read();
}

abstract class LocalityReader {
  Future<String?> read(GeoFix fix);
}

class UnlockCancelled implements Exception {
  const UnlockCancelled();
}

class UnlockAttempt {
  const UnlockAttempt({required this.failed, this.errorMessage});

  final bool failed;
  final String? errorMessage;
}

class UnlockAndRecord {
  UnlockAndRecord({
    required this.credentials,
    required this.log,
    required this.runner,
    required this.form,
    required this.session,
    required this.readPage,
    required this.position,
    required this.locality,
    required this.now,
    UnlockTrace? trace,
  }) : trace = trace ?? UnlockTrace();

  final CredentialRepository credentials;
  final UnlockLogRepository log;
  final LoginRunner runner;
  final LoginFormTarget form;
  final UnlockSession session;
  final Future<UnlockPageReading> Function() readPage;
  final CurrentPositionReader position;
  final LocalityReader locality;
  final DateTime Function() now;
  final UnlockTrace trace;

  Future<UnlockAttempt?> call({required Uri url, required Future<void> Function() confirm}) async {
    UnlockStatus status = UnlockStatus.success;
    String? errorMessage;
    String siteName = '';
    String doorName = '';
    try {
      await runner.open(
        repository: credentials,
        url: url,
        form: form,
        session: session,
        confirm: confirm,
      );
      trace.add('解錠ページを確認しています');
      final UnlockPageReading reading = await readPage();
      siteName = reading.siteName;
      doorName = reading.doorName;
      trace.add(reading.siteName.isEmpty ? '拠点：取得できませんでした' : '拠点：${reading.siteName}');
      trace.add(reading.doorName.isEmpty ? 'ドア：取得できませんでした' : 'ドア：${reading.doorName}');
      if (!reading.succeeded) {
        status = UnlockStatus.failed;
        errorMessage = reading.errorMessage;
        trace.add(errorMessage == null ? 'エラー：表示されていません' : 'error-message：$errorMessage');
      } else {
        trace.add('エラー：表示されていません');
      }
      trace.add(status == UnlockStatus.failed ? '判定：FAILED' : '判定：SUCCESS');
    } on StateError {
      return null;
    } on UnlockCancelled {
      return null;
    } catch (_) {
      status = UnlockStatus.failed;
      trace.add('判定：FAILED（ページを確認できませんでした）');
    }

    final GeoFix? fix = await position.read();
    final String place = fix == null ? 'NOT_PERMITTED' : (await locality.read(fix)) ?? 'FAILED';
    log.add(
      UnlockRecord(
        url: url,
        at: now(),
        latitude: fix?.latitude,
        longitude: fix?.longitude,
        locality: place,
        status: status,
        siteName: siteName,
        doorName: doorName,
        errorMessage: errorMessage,
      ),
    );
    return UnlockAttempt(failed: status == UnlockStatus.failed, errorMessage: errorMessage);
  }
}
