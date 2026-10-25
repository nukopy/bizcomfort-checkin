import 'package:bizcomfort_checkin/page/log/log_page.dart';
import 'package:bizcomfort_checkin/page/scan/scan_page.dart';
import 'package:bizcomfort_checkin/page/setting/setting_page.dart';
import 'package:bizcomfort_checkin/usecase/load_credentials.dart';
import 'package:bizcomfort_checkin/usecase/save_credentials.dart';
import 'package:flutter/material.dart';

class CheckinTabs extends StatefulWidget {
  const CheckinTabs({super.key, required this.loadCredentials, required this.saveCredentials});

  final LoadCredentials loadCredentials;
  final SaveCredentials saveCredentials;

  @override
  State<CheckinTabs> createState() => _CheckinTabsState();
}

class _CheckinTabsState extends State<CheckinTabs> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      const ScanPage(),
      const LogPage(),
      SettingPage(loadCredentials: widget.loadCredentials, saveCredentials: widget.saveCredentials),
    ];
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'QRコード読み取り'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'ログ'),
          NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }
}
