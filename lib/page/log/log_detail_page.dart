import 'package:bizcomfort_checkin/domain/unlock_record.dart';
import 'package:flutter/material.dart';

class LogDetailPage extends StatelessWidget {
  const LogDetailPage({super.key, required this.record});

  final UnlockRecord record;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodyLarge;
    return Scaffold(
      appBar: AppBar(title: const Text('記録')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('・解錠時刻：${formatUnlockRowDate(record.at)}', style: style),
          Text('・拠点名：${record.siteName}', style: style),
          Text('・ドア名：${record.doorName}', style: style),
          Text('・現在地（市区町村）：${record.locality}', style: style),
          Text('・現在地（GPS）：${formatGps(record.latitude, record.longitude)}', style: style),
        ],
      ),
    );
  }
}
