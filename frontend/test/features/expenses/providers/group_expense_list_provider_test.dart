import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/expenses/models/expense_list_model.dart';
import 'package:frontend/features/expenses/providers/expense_repository_provider.dart';
import 'package:frontend/features/expenses/providers/group_expense_list_provider.dart';
import 'package:frontend/features/expenses/repositories/expense_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  const groupId = '660e8400-e29b-41d4-a716-446655440002';
  const paidById = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

  final paidByJson = <String, dynamic>{
    'id': paidById,
    'display_name': 'Ada',
    'avatar_url': null,
  };

  Map<String, dynamic> expenseJson(String expenseId) => <String, dynamic>{
        'id': expenseId,
        'group_id': groupId,
        'paid_by': paidByJson,
        'amount': '10.00',
        'currency': 'BRL',
        'amount_in_group_currency': '10.00',
        'description': 'Test',
        'category': 'geral',
        'expense_date': '2024-01-15',
        'split_method': 'equal',
        'split_count': 2,
        'is_deleted': false,
        'created_at': '2024-01-15T12:00:00.000Z',
      };

  ExpenseListModel expense(String id) =>
      ExpenseListModel.fromJson(expenseJson(id));

  late _MockExpenseRepository mockRepo;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    mockRepo = _MockExpenseRepository();
  });

  test('build loads page 1 with limit 20', () async {
    final p1 = [expense('550e8400-e29b-41d4-a716-446655440001')];
    when(
      () => mockRepo.fetchGroupExpenses(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((invocation) async {
      final page = invocation.namedArguments[#page] as int;
      final limit = invocation.namedArguments[#limit] as int;
      expect(page, 1);
      expect(limit, 20);
      return p1;
    });

    final container = ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);

    final list = await container.read(groupExpenseListProvider(groupId).future);
    expect(list, p1);
    verify(
      () => mockRepo.fetchGroupExpenses(
        groupId,
        page: 1,
        limit: 20,
      ),
    ).called(1);
  });

  test('loadMore appends page 2 without duplicates', () async {
    final p1 = [
      expense('550e8400-e29b-41d4-a716-446655440001'),
    ];
    final p2 = [
      expense('550e8400-e29b-41d4-a716-446655440002'),
    ];
    when(
      () => mockRepo.fetchGroupExpenses(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((invocation) async {
      final page = invocation.namedArguments[#page] as int;
      if (page == 1) return p1;
      if (page == 2) return p2;
      return <ExpenseListModel>[];
    });

    final container = ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(groupExpenseListProvider(groupId).future);
    final notifier =
        container.read(groupExpenseListProvider(groupId).notifier);
    await notifier.loadMore();

    final list = container.read(groupExpenseListProvider(groupId)).value!;
    expect(list.length, 2);
    expect(list.map((e) => e.id).toList(), [
      '550e8400-e29b-41d4-a716-446655440001',
      '550e8400-e29b-41d4-a716-446655440002',
    ]);
  });

  test('empty page 2 sets hasMore false; further loadMore does not fetch', () async {
    final p1 = [expense('550e8400-e29b-41d4-a716-446655440001')];
    var fetchCount = 0;
    when(
      () => mockRepo.fetchGroupExpenses(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((invocation) async {
      fetchCount++;
      final page = invocation.namedArguments[#page] as int;
      if (page == 1) return p1;
      if (page == 2) return <ExpenseListModel>[];
      return <ExpenseListModel>[];
    });

    final container = ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(groupExpenseListProvider(groupId).future);
    expect(fetchCount, 1);

    final notifier =
        container.read(groupExpenseListProvider(groupId).notifier);
    await notifier.loadMore();
    expect(fetchCount, 2);

    await notifier.loadMore();
    expect(fetchCount, 2);
  });

  test('refresh resets to page 1 only', () async {
    final p1 = [expense('550e8400-e29b-41d4-a716-446655440001')];
    final p2 = [expense('550e8400-e29b-41d4-a716-446655440002')];
    when(
      () => mockRepo.fetchGroupExpenses(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((invocation) async {
      final page = invocation.namedArguments[#page] as int;
      if (page == 1) return p1;
      if (page == 2) return p2;
      return <ExpenseListModel>[];
    });

    final container = ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(groupExpenseListProvider(groupId).future);
    final notifier =
        container.read(groupExpenseListProvider(groupId).notifier);
    await notifier.loadMore();

    var list = container.read(groupExpenseListProvider(groupId)).value!;
    expect(list.length, 2);

    await notifier.refresh();
    list = container.read(groupExpenseListProvider(groupId)).value!;
    expect(list, p1);
  });

  test('merge dedupes by expense id (keep first)', () async {
    final dupId = '550e8400-e29b-41d4-a716-446655440099';
    final p1 = [expense(dupId)];
    final p2 = [
      ExpenseListModel.fromJson(
        expenseJson(dupId)
          ..['description'] = 'Duplicate row',
      ),
    ];
    when(
      () => mockRepo.fetchGroupExpenses(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((invocation) async {
      final page = invocation.namedArguments[#page] as int;
      if (page == 1) return p1;
      if (page == 2) return p2;
      return <ExpenseListModel>[];
    });

    final container = ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(groupExpenseListProvider(groupId).future);
    final notifier =
        container.read(groupExpenseListProvider(groupId).notifier);
    await notifier.loadMore();

    final list = container.read(groupExpenseListProvider(groupId)).value!;
    expect(list.length, 1);
    expect(list.single.description, 'Test');
  });
}
