import 'package:bizcomfort_checkin/domain/credentials.dart';
import 'package:bizcomfort_checkin/domain/unlock_record.dart';
import 'package:bizcomfort_checkin/page/scan/login_runner.dart';
import 'package:bizcomfort_checkin/page/scan/unlock_page_text.dart';

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
  const UnlockAndRecord({
    required this.credentials,
    required this.log,
    required this.runner,
    required this.form,
    required this.session,
    required this.pageHtml,
    required this.position,
    required this.locality,
    required this.now,
  });

  final CredentialRepository credentials;
  final UnlockLogRepository log;
  final LoginRunner runner;
  final LoginFormTarget form;
  final UnlockSession session;
  final Future<String> Function() pageHtml;
  final CurrentPositionReader position;
  final LocalityReader locality;
  final DateTime Function() now;

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
      final String html = await pageHtml();
      final UnlockPageReading reading = readUnlockPage(html);
      siteName = reading.siteName;
      doorName = reading.doorName;
      if (!reading.succeeded) {
        status = UnlockStatus.failed;
        errorMessage = reading.errorMessage;
      }
    } on StateError {
      return null;
    } on UnlockCancelled {
      return null;
    } catch (_) {
      status = UnlockStatus.failed;
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
