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
          Text(record.locality),
          Text(record.direction.name),
          Text(record.status.label),
          Text(record.url.toString()),
          Text(record.latitude?.toString() ?? ''),
          Text(record.longitude?.toString() ?? ''),
        ],
      ),
    );
  }
}
