import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/expenses/models/split_model.dart';
import 'package:frontend/features/expenses/utils/nominal_split_amounts.dart';

SplitModel _split({
  required String id,
  String? share,
  String amountOwed = '0.00',
}) {
  return SplitModel(
    id: id,
    userId: 'u-$id',
    displayName: 'User $id',
    avatarUrl: null,
    amountOwed: amountOwed,
    shareValue: share,
    isSettled: false,
  );
}

void main() {
  group('tryComputeNominalShares', () {
    test('equal 3-way 10.00 → 3.34, 3.33, 3.33 (rounding on first)', () {
      final splits = [
        _split(id: '1'),
        _split(id: '2'),
        _split(id: '3'),
      ];
      final nom = tryComputeNominalShares(
        splitMethod: 'equal',
        expenseTotalAmount: '10.00',
        splits: splits,
      );
      expect(nom, isNotNull);
      expect(nom!.length, 3);
      expect(nom[0], Decimal.parse('3.34'));
      expect(nom[1], Decimal.parse('3.33'));
      expect(nom[2], Decimal.parse('3.33'));
      final sum = nom.fold<Decimal>(Decimal.zero, (a, b) => a + b);
      expect(sum, Decimal.parse('10.00'));
    });

    test('equal 2-way 25.00 → 12.50, 12.50', () {
      final nom = tryComputeNominalShares(
        splitMethod: 'equal',
        expenseTotalAmount: '25.00',
        splits: [_split(id: '1'), _split(id: '2')],
      );
      expect(nom, [Decimal.parse('12.50'), Decimal.parse('12.50')]);
    });

    test('percentage 50/50 on 100', () {
      final nom = tryComputeNominalShares(
        splitMethod: 'percentage',
        expenseTotalAmount: '100.00',
        splits: [
          _split(id: '1', share: '50'),
          _split(id: '2', share: '50'),
        ],
      );
      expect(nom, [Decimal.parse('50.00'), Decimal.parse('50.00')]);
    });

    test('shares 2:1:1 on 10 → 5, 2.50, 2.50', () {
      final nom = tryComputeNominalShares(
        splitMethod: 'shares',
        expenseTotalAmount: '10.00',
        splits: [
          _split(id: '1', share: '2'),
          _split(id: '2', share: '1'),
          _split(id: '3', share: '1'),
        ],
      );
      expect(nom, [
        Decimal.parse('5.00'),
        Decimal.parse('2.50'),
        Decimal.parse('2.50'),
      ]);
    });

    test('exact returns null', () {
      expect(
        tryComputeNominalShares(
          splitMethod: 'exact',
          expenseTotalAmount: '10.00',
          splits: [_split(id: '1', amountOwed: '10.00')],
        ),
        isNull,
      );
    });

    test('percentage not summing to 100 returns null', () {
      expect(
        tryComputeNominalShares(
          splitMethod: 'percentage',
          expenseTotalAmount: '100.00',
          splits: [
            _split(id: '1', share: '40'),
            _split(id: '2', share: '40'),
          ],
        ),
        isNull,
      );
    });
  });
}
