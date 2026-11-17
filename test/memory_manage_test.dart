// 올린 추억 목록에서 고치고 지우는 흐름.
// 서버 대신 가짜 SettingsApi 로 무엇을 보냈는지만 본다.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/5.%20memory/memory_add_flow.dart';
import 'package:flutter_application_1/services/settings_api.dart';

class _FakeApi extends SettingsApi {
  _FakeApi(this.items);

  final List<MemoryItem> items;
  final List<Map<String, Object?>> updates = [];
  final List<int> deleted = [];

  @override
  Future<MyProfile> myProfile() async => MyProfile.fromJson({
    'protectorId': 1,
    'name': '김지영',
    'users': [
      {'userId': 7, 'name': '박순자', 'deviceId': 3, 'isPrimary': true},
    ],
    'notificationSettings': <String, dynamic>{},
  });

  @override
  Future<List<MemoryItem>> memories(int userId) async =>
      items.where((m) => !deleted.contains(m.memoryId)).toList();

  @override
  Future<MemoryItem> updateMemory(
    int memoryId, {
    String? imageUrl,
    String? originalImageUrl,
    String? title,
    String? period,
    String? description,
  }) async {
    updates.add({
      'id': memoryId,
      'imageUrl': imageUrl,
      'title': title,
      'period': period,
      'description': description,
    });
    return items.firstWhere((m) => m.memoryId == memoryId);
  }

  @override
  Future<void> deleteMemory(int memoryId) async => deleted.add(memoryId);
}

void _usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Widget _wrap(Widget child) => ScreenUtilInit(
  designSize: const Size(390, 844),
  builder: (_, _) => MaterialApp(home: child),
);

List<MemoryItem> _sample() => [
  MemoryItem(memoryId: 1, title: '테스트 추억', period: '1980년대', description: '예전 것'),
  MemoryItem(memoryId: 2, title: '손주 운동회', period: '최근'),
];

void main() {
  testWidgets('목록에 올린 추억이 보인다', (tester) async {
    _usePhoneScreen(tester);
    await tester.pumpWidget(_wrap(MemoryListScreen(api: _FakeApi(_sample()))));
    await tester.pumpAndSettle();
    expect(find.text('테스트 추억'), findsOneWidget);
    expect(find.text('손주 운동회'), findsOneWidget);
  });

  testWidgets('고치면 바꾼 제목을 보내고, 칩을 안 누르면 시기는 그대로 둔다',
      (tester) async {
    _usePhoneScreen(tester);
    final api = _FakeApi(_sample());
    await tester.pumpWidget(_wrap(MemoryListScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('테스트 추억'));
    await tester.pumpAndSettle();
    expect(find.text('추억 고치기'), findsOneWidget);
    // 칩에 없는 시기는 따로 보여준다.
    expect(find.text('지금: 1980년대'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '테스트 추억'), '제주도 신혼여행');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(api.updates, [
      {
        'id': 1,
        'imageUrl': null,
        'title': '제주도 신혼여행',
        'period': null,
        'description': '예전 것',
      },
    ]);
    expect(find.text('올린 추억'), findsOneWidget); // 목록으로 돌아왔다
  });

  testWidgets('빈 제목은 보내지 않는다', (tester) async {
    _usePhoneScreen(tester);
    final api = _FakeApi(_sample());
    await tester.pumpWidget(_wrap(MemoryEditScreen(memory: _sample()[1], api: api)));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '손주 운동회'), '  ');
    await tester.tap(find.text('저장'));
    await tester.pump();
    expect(api.updates, isEmpty);
    expect(find.text('한 줄 제목을 적어주세요.'), findsOneWidget);
  });

  testWidgets('지우기는 한 번 더 묻고, 지우면 목록에서 빠진다', (tester) async {
    _usePhoneScreen(tester);
    final api = _FakeApi(_sample());
    await tester.pumpWidget(_wrap(MemoryListScreen(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('테스트 추억'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('이 추억 지우기'));
    await tester.tap(find.text('이 추억 지우기'));
    await tester.pumpAndSettle();

    // 취소하면 아무것도 안 지운다.
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(api.deleted, isEmpty);

    await tester.tap(find.text('이 추억 지우기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('지우기'));
    await tester.pumpAndSettle();

    expect(api.deleted, [1]);
    expect(find.text('테스트 추억'), findsNothing);
    expect(find.text('손주 운동회'), findsOneWidget);
  });

  testWidgets('기억 추가 화면에서 올린 추억 버튼이 보인다', (tester) async {
    _usePhoneScreen(tester);
    var opened = false;
    await tester.pumpWidget(_wrap(MemoryAddScreen(
      onSave: ({required photo, required title,
                required period, required description}) async {},
      onSelectNewMemory: () {},
      onOpenList: () => opened = true,
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('올린 추억'));
    expect(opened, isTrue);
  });
}
