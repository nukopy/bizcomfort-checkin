import 'package:bizcomfort_checkin/domain/unlock_record.dart';
import 'package:flutter/material.dart';

class LogDetailPage extends StatelessWidget {
  const LogDetailPage({super.key, required this.record});

  final UnlockRecord record;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('記録')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(formatUnlockRowDate(record.at)),
          const Text('拠点名'),
          Text(record.siteName),
          const Text('ドア名'),
          Text(record.doorName),
          const Text('現在地（市区町村）'),
          Text(record.locality),
          const Text('現在地（GPS）'),
          Text(record.latitude?.toString() ?? ''),
          Text(record.longitude?.toString() ?? ''),
          Text(record.direction.name),
          Text(record.status.label),
          Text(record.url.toString()),
        ],
      ),
    );
  }
}
