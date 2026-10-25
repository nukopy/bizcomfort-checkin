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
                key: const Key('log-month'),
                tooltip: '月を選ぶ',
                onPressed: _pickMonth,
                icon: const Icon(Icons.calendar_month),
              ),
            ],
          ),
          body: records.isEmpty
              ? const Center(child: Text('記録はまだありません'))
              : ListView.separated(
                  itemCount: records.length,
                  separatorBuilder: (BuildContext context, int index) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    final UnlockRecord record = records[index];
                    return ListTile(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) => LogDetailPage(record: record),
                          ),
                        );
                      },
                      title: Text(formatUnlockRowDate(record.at)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${record.siteName} ${record.doorName} ${record.direction.name}'),
                          Text(record.status.label),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    );
                  },
                ),
        );
      },
    );
  }
}
