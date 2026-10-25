String? extractUnlockError(String html) {
  final RegExp pattern = RegExp(
    '<(?:div|p|li|span)[^>]*(?:alert-danger|errorlist|role="alert")[^>]*>(.*?)</(?:div|p|li|span)>',
    caseSensitive: false,
    dotAll: true,
  );
  final Match? match = pattern.firstMatch(html);
  if (match == null) {
    return null;
  }
  final String text = match
      .group(1)!
      .replaceAll(RegExp('<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .trim();
  if (text.isEmpty) {
    return null;
  }
  return text;
}

bool unlockPageSucceeded(String html) {
  return html.contains('拠点') || html.contains('ドア');
}
