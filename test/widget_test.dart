import 'package:bizcomfort_checkin/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('起動直後はQRコード読み取りタブ', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    final NavigationBar bar = tester.widget(find.byType(NavigationBar));
    expect(bar.selectedIndex, 0);
    expect(find.text('QRコードをかざす'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets('ログと設定に切り替えられる', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('ログ'));
    await tester.pumpAndSettle();
    expect(find.text('記録はまだありません'), findsOneWidget);

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    expect(find.text('メールアドレスとパスワード'), findsOneWidget);
  });
}
