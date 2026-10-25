import 'dart:async';

import 'package:bizcomfort_checkin/page/scan/unlock_url.dart';
import 'package:flutter/foundation.dart';
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
  const ScanPage({
    super.key,
    required this.source,
    required this.onUnlockUrl,
    this.footer,
    this.cameraOpen,
  });

  final QrScanSource source;
  final ValueChanged<Uri> onUnlockUrl;
  final Widget? footer;
  final ValueListenable<bool>? cameraOpen;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  static const Duration _rescanAfter = Duration(milliseconds: 1500);

  StreamSubscription<String>? _subscription;
  Timer? _release;
  String? _lastAccepted;
  late bool _closed = widget.cameraOpen?.value == false;

  @override
  void initState() {
    super.initState();
    widget.cameraOpen?.addListener(_syncCamera);
    _subscription = widget.source.codes.listen(_onCode);
  }

  @override
  void didUpdateWidget(ScanPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cameraOpen != widget.cameraOpen) {
      oldWidget.cameraOpen?.removeListener(_syncCamera);
      widget.cameraOpen?.addListener(_syncCamera);
      _syncCamera();
    }
  }

  void _syncCamera() {
    final bool open = widget.cameraOpen?.value ?? true;
    setState(() => _closed = !open);
    if (open) {
      _scheduleRelease();
    } else {
      _release?.cancel();
    }
  }

  void _scheduleRelease() {
    _release?.cancel();
    if (_closed || _lastAccepted == null) {
      return;
    }
    _release = Timer(_rescanAfter, () {
      if (!mounted || _closed) {
        return;
      }
      _lastAccepted = null;
    });
  }

  void _onCode(String raw) {
    if (_closed) {
      return;
    }
    final Uri? uri = Uri.tryParse(raw);
    if (uri == null || !isBizcomfortUnlockUrl(uri)) {
      return;
    }
    final String value = uri.toString();
    if (value == _lastAccepted) {
      _scheduleRelease();
      return;
    }
    _release?.cancel();
    _lastAccepted = value;
    widget.onUnlockUrl(uri);
  }

  @override
  void dispose() {
    widget.cameraOpen?.removeListener(_syncCamera);
    _release?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  Widget _acceptedMessage(BuildContext context) {
    final String? url = _lastAccepted;
    if (url == null) {
      return const SizedBox.expand();
    }
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'QRコードの読み取りができました',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: 12),
            Text(
              url,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _closed
              ? ColoredBox(
                  key: const Key('qr-scanner-closed'),
                  color: Theme.of(context).colorScheme.surface,
                  child: _acceptedMessage(context),
                )
              : KeyedSubtree(key: const Key('qr-scanner'), child: widget.source.buildView()),
        ),
        if (widget.footer != null)
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: widget.footer)
        else if (!_closed)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('QRコードをかざす', textAlign: TextAlign.center),
          ),
      ],
    );
  }
}
