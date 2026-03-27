import 'package:decimal/decimal.dart';

import 'package:frontend/features/expenses/models/split_model.dart';

/// Divide two decimals and round to cents (matches Django `quantize(0.01)` on quotients).
Decimal _divideRoundToCent(Decimal numerator, Decimal denominator) {
  return (numerator / denominator).toDecimal(
    scaleOnInfinitePrecision: 2,
    toBigInt: (v) => v.round(),
  );
}

/// Quantize to 2 decimal places (matches Django `quantize(Decimal("0.01"))`).
Decimal quantizeCent(Decimal x) {
  final cents = (x * Decimal.fromInt(100)).round(scale: 0);
  return (cents / Decimal.fromInt(100)).toDecimal();
}

/// Nominal per-row split amounts mirroring [SplitService.compute_splits] in
/// `backend/apps/expenses/services.py`.
///
/// Returns `null` for `exact` splits or when inputs are invalid — caller should
/// use each split's [SplitModel.amountOwed].
List<Decimal>? tryComputeNominalShares({
  required String splitMethod,
  required String expenseTotalAmount,
  required List<SplitModel> splits,
}) {
  if (splits.isEmpty) {
    return null;
  }

  final total = quantizeCent(Decimal.parse(expenseTotalAmount.trim()));

  switch (splitMethod) {
    case 'equal':
      return _computeEqual(splits.length, total);
    case 'percentage':
      return _computePercentage(splits, total);
    case 'shares':
      return _computeShares(splits, total);
    case 'exact':
      return null;
    default:
      return null;
  }
}

List<Decimal> _computeEqual(int participantCount, Decimal total) {
  if (participantCount <= 0) {
    return [];
  }
  final base = _divideRoundToCent(total, Decimal.fromInt(participantCount));
  final out = List<Decimal>.generate(participantCount, (_) => base);
  final computedTotal =
      out.fold<Decimal>(Decimal.zero, (a, b) => quantizeCent(a + b));
  final roundingAdjustment = quantizeCent(total - computedTotal);
  out[0] = quantizeCent(out[0] + roundingAdjustment);
  return out;
}

final Decimal _hundred = Decimal.fromInt(100);
final Decimal _tolerance = Decimal.parse('0.01');

List<Decimal>? _computePercentage(List<SplitModel> splits, Decimal total) {
  final values = <Decimal>[];
  for (final s in splits) {
    final raw = s.shareValue?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final v = Decimal.tryParse(raw.replaceAll(',', '.'));
    if (v == null || v < Decimal.zero) {
      return null;
    }
    values.add(v);
  }
  final sumPct = values.fold<Decimal>(Decimal.zero, (a, b) => a + b);
  if ((sumPct - _hundred).abs() > _tolerance) {
    return null;
  }

  final out = <Decimal>[];
  for (final v in values) {
    out.add(_divideRoundToCent(total * v, _hundred));
  }
  final computedTotal =
      out.fold<Decimal>(Decimal.zero, (a, b) => quantizeCent(a + b));
  final roundingAdjustment = quantizeCent(total - computedTotal);
  out[0] = quantizeCent(out[0] + roundingAdjustment);
  return out;
}

List<Decimal>? _computeShares(List<SplitModel> splits, Decimal total) {
  final shareValues = <Decimal>[];
  for (final s in splits) {
    final raw = s.shareValue?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final v = Decimal.tryParse(raw.replaceAll(',', '.'));
    if (v == null || v <= Decimal.zero) {
      return null;
    }
    shareValues.add(v);
  }
  final totalShares =
      shareValues.fold<Decimal>(Decimal.zero, (a, b) => a + b);
  if (totalShares <= Decimal.zero) {
    return null;
  }

  final out = <Decimal>[];
  for (final v in shareValues) {
    out.add(_divideRoundToCent(total * v, totalShares));
  }
  final computedTotal =
      out.fold<Decimal>(Decimal.zero, (a, b) => quantizeCent(a + b));
  final roundingAdjustment = quantizeCent(total - computedTotal);
  out[0] = quantizeCent(out[0] + roundingAdjustment);
  return out;
}
