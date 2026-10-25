bool isBizcomfortUnlockUrl(Uri uri) {
  if (uri.scheme != 'https' || uri.host != 'mypage.bizcomfort.jp') {
    return false;
  }
  final List<String> segments = uri.pathSegments.where((String s) => s.isNotEmpty).toList();
  if (segments.length != 3 || segments.first != 'unlock') {
    return false;
  }
  return segments[1] == 'entry' || segments[1] == 'exit';
}
