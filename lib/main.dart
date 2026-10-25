import 'package:bizcomfort_checkin/components/checkin_tabs.dart';
import 'package:bizcomfort_checkin/wire/app_wire.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp(wire: AppWire.memory()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.wire});

  final AppWire? wire;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppWire _wire = widget.wire ?? AppWire.memory();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BIZcomfort Checkin',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: CheckinTabs(
        loadCredentials: _wire.loadCredentials,
        saveCredentials: _wire.saveCredentials,
      ),
    );
  }
}
