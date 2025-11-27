import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pikado/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('タスク追加が表示される簡易テスト', (WidgetTester tester) async {
    // アプリ起動
    await tester.pumpWidget(pikado());
    await tester.pumpAndSettle();

    // FAB をタップして追加ダイアログを表示
    final fabFinder = find.byType(FloatingActionButton);
    expect(fabFinder, findsOneWidget);
    await tester.tap(fabFinder);
    await tester.pumpAndSettle();

    // タイトルを入力
    final titleField = find.byType(TextField);
    expect(titleField, findsOneWidget);
    await tester.enterText(titleField, 'テストタスク');

    // 追加ボタンをタップ
    final addButton = find.widgetWithText(ElevatedButton, '追加');
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // 追加されたタスクが表示されるか
    final taskTitle = find.text('テストタスク');
    expect(taskTitle, findsOneWidget);
  });
}
