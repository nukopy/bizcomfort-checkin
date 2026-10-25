class UnlockPageReading {
  const UnlockPageReading({
    required this.succeeded,
    this.errorMessage,
    this.siteName = '',
    this.doorName = '',
  });

  final bool succeeded;
  final String? errorMessage;
  final String siteName;
  final String doorName;
}

UnlockPageReading readUnlockPage(String html) {
  final String? errorMessage = _visibleErrorMessage(html);
  final ({String siteName, String doorName}) place = _placeNames(html);
  return UnlockPageReading(
    succeeded: errorMessage == null,
    errorMessage: errorMessage,
    siteName: place.siteName,
    doorName: place.doorName,
  );
}

String? _visibleErrorMessage(String html) {
  final RegExp pattern = RegExp(
    '<p\\b([^>]*\\bid=["\']error-message["\'][^>]*)>(.*?)</p>',
    caseSensitive: false,
    dotAll: true,
  );
  final Match? match = pattern.firstMatch(html);
  if (match == null || _isHidden(match.group(1)!)) {
    return null;
  }
  final String text = _plain(match.group(2)!);
  if (text.isEmpty) {
    return null;
  }
  return text;
}

({String siteName, String doorName}) _placeNames(String html) {
  final RegExp block = RegExp(
    '<div\\b([^>]*\\bclass=["\'][^"\']*unlock-select-block[^"\']*["\'][^>]*)>(.*?)</div>',
    caseSensitive: false,
    dotAll: true,
  );
  final Match? match = block.firstMatch(html);
  if (match == null) {
    return (siteName: '', doorName: '');
  }
  String siteName = '';
  String doorName = '';
  final RegExp pair = RegExp(
    '<p\\b[^>]*class=["\'][^"\']*unlock-select-title[^"\']*["\'][^>]*>(.*?)</p>\\s*'
    '<p\\b[^>]*class=["\'][^"\']*unlock-select-text[^"\']*["\'][^>]*>(.*?)</p>',
    caseSensitive: false,
    dotAll: true,
  );
  for (final Match found in pair.allMatches(match.group(2)!)) {
    final String title = _plain(found.group(1)!);
    final String value = _plain(found.group(2)!);
    if (title == '拠点') {
      siteName = value;
    } else if (title == 'ドア') {
      doorName = value;
    }
  }
  return (siteName: siteName, doorName: doorName);
}

bool _isHidden(String openingTag) {
  return RegExp('display\\s*:\\s*none', caseSensitive: false).hasMatch(openingTag);
}

String _plain(String html) {
  return html.replaceAll(RegExp('<[^>]+>'), '').replaceAll('&nbsp;', ' ').trim();
}

bool unlockObservationSettled({
  required bool errorShown,
  required bool busy,
  required Duration elapsed,
  required bool repeatedQuiet,
}) {
  if (errorShown) {
    return true;
  }
  if (busy || !repeatedQuiet) {
    return false;
  }
  return elapsed >= const Duration(seconds: 8);
}
