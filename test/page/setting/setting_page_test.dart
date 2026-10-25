import 'package:bizcomfort_checkin/domain/credentials.dart';
import 'package:bizcomfort_checkin/page/setting/setting_page.dart';
import 'package:bizcomfort_checkin/repository/memory_credential_repository.dart';
import 'package:bizcomfort_checkin/usecase/load_credentials.dart';
import 'package:bizcomfort_checkin/usecase/save_credentials.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('保存すると repository に残る', (WidgetTester tester) async {
    final MemoryCredentialRepository repository = MemoryCredentialRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingPage(
          loadCredentials: LoadCredentials(repository),
          saveCredentials: SaveCredentials(repository),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('email')), 'member@example.com');
    await tester.enterText(find.byKey(const Key('password')), 'secret');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(
      await repository.read(),
      const Credentials(email: 'member@example.com', password: 'secret'),
    );
  });
}
