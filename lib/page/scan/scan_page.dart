import 'dart:async';

import 'package:bizcomfort_checkin/page/scan/unlock_url.dart';
import 'package:flutter/material.dart';

abstract class QrScanSource {
  Stream<String> get codes;

  Widget buildView();
}

class ListQrScanSource implements QrScanSource {
  ListQrScanSource(this.values);

  final List<String> values;

  @override
  Stream<String> get codes => Stream<String>.fromIterable(values);

  @override
  Widget buildView() => const SizedBox.shrink();
}

class ScanPage extends StatefulWidget {
  const ScanPage({super.key, required this.source, required this.onUnlockUrl});

  final QrScanSource source;
  final ValueChanged<Uri> onUnlockUrl;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  StreamSubscription<String>? _subscription;
  String? _lastAccepted;

  @override
  void initState() {
    super.initState();
    _subscription = widget.source.codes.listen(_onCode);
  }

  void _onCode(String raw) {
    final Uri? uri = Uri.tryParse(raw);
    if (uri == null || !isBizcomfortUnlockUrl(uri)) {
      return;
    }
    final String value = uri.toString();
    if (value == _lastAccepted) {
      return;
    }
    _lastAccepted = value;
    widget.onUnlockUrl(uri);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: KeyedSubtree(key: const Key('qr-scanner'), child: widget.source.buildView()),
        ),
        const Padding(padding: EdgeInsets.all(16), child: Text('QRコードをかざす')),
      ],
    );
  }
}
