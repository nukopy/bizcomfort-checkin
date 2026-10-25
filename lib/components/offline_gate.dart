import 'dart:async';

import 'package:bizcomfort_checkin/domain/network_connection.dart';
import 'package:flutter/material.dart';

class OfflineGate extends StatefulWidget {
  const OfflineGate({super.key, required this.connection, required this.child});

  final NetworkConnection connection;
  final Widget child;

  @override
  State<OfflineGate> createState() => _OfflineGateState();
}

class _OfflineGateState extends State<OfflineGate> {
  StreamSubscription<bool>? _subscription;
  bool? _online;

  @override
  void initState() {
    super.initState();
    _subscription = widget.connection.online.listen(
      _onOnline,
      onError: (Object _) => _onOnline(false),
    );
  }

  void _onOnline(bool online) {
    if (!mounted || _online == online) {
      return;
    }
    setState(() => _online = online);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [widget.child, if (_online == false) const _OfflineCover()],
    );
  }
}

class _OfflineCover extends StatelessWidget {
  const _OfflineCover();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        ModalBarrier(dismissible: false, color: Colors.black54),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(16)),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Text(
                  'ネットワークに接続されていません',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black, fontSize: 16, height: 1.4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
