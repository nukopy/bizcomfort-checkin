import 'package:bizcomfort_checkin/constants.dart';
import 'package:bizcomfort_checkin/domain/unlock_record.dart';
import 'package:bizcomfort_checkin/page/log/log_detail_page.dart';
import 'package:bizcomfort_checkin/usecase/watch_unlock_log.dart';
import 'package:flutter/material.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key, required this.watchUnlockLog, required this.now});

  final WatchUnlockLog watchUnlockLog;
  final DateTime now;

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  late DateTime _month = DateTime(widget.now.year, widget.now.month);

  List<DateTime> _months() {
    final DateTime start = DateTime(appReleaseDate.year, appReleaseDate.month);
    final DateTime end = DateTime(widget.now.year, widget.now.month);
    if (end.isBefore(start)) {
      return <DateTime>[end];
    }
    final List<DateTime> months = <DateTime>[];
    DateTime cursor = end;
    while (!cursor.isBefore(start)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month - 1);
    }
    return months;
  }

  Future<void> _pickMonth() async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          children: <Widget>[
            for (final DateTime month in _months())
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, month),
                child: Text(formatMonthHeading(month)),
              ),
          ],
        );
      },
    );
    if (picked == null) {
      return;
    }
    setState(() => _month = picked);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.watchUnlockLog.updates,
      builder: (BuildContext context, Widget? child) {
        final List<UnlockRecord> records = widget.watchUnlockLog.recordsIn(
          _month.year,
          _month.month,
        );
        return Scaffold(
          appBar: AppBar(
            title: Text(formatMonthHeading(_month)),
            actions: [
              IconButton(
                key: const Key('log-search'),
                onPressed: _pickMonth,
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          body: records.isEmpty
              ? const Center(child: Text('記録はまだありません'))
              : ListView(
                  children: [
                    for (final UnlockRecord record in records)
                      ListTile(
                        title: Text(formatUnlockRowDate(record.at)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(record.siteName),
                            Text(record.doorName),
                            Text(record.direction.name),
                            Text(record.status.label),
                          ],
                        ),
                        trailing: IconButton(
                          key: const Key('log-detail'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (BuildContext context) => LogDetailPage(record: record),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
