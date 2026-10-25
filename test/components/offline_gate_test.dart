import 'dart:async';

import 'package:bizcomfort_checkin/components/offline_gate.dart';
import 'package:bizcomfort_checkin/domain/network_connection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('切れると操作できず、戻ると元の画面', (WidgetTester tester) async {
    final StreamController<bool> events = StreamController<bool>();
    addTearDown(events.close);
    int taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: OfflineGate(
          connection: _ScriptedConnection(events.stream),
          child: Scaffold(
            body: TextButton(onPressed: () => taps += 1, child: const Text('読み取り')),
          ),
        ),
      ),
    );

    expect(find.text('ネットワークに接続されていません'), findsNothing);
    await tester.tap(find.text('読み取り'));
    expect(taps, 1);

    events.add(false);
    await tester.pump();

    expect(find.text('ネットワークに接続されていません'), findsOneWidget);
    expect(find.text('読み取り'), findsOneWidget);
    await tester.tap(find.text('読み取り'), warnIfMissed: false);
    expect(taps, 1);

    events.add(true);
    await tester.pump();

    expect(find.text('ネットワークに接続されていません'), findsNothing);
    expect(find.text('読み取り'), findsOneWidget);
    await tester.tap(find.text('読み取り'));
    expect(taps, 2);
  });
}

class _ScriptedConnection implements NetworkConnection {
  _ScriptedConnection(this.online);

  @override
  final Stream<bool> online;
}
