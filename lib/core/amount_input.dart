import "package:flutter/foundation.dart";

import "money_format.dart";

/// Maximum storable amount (VND, whole units).
const int kMaxAmountVnd = 999999999999;

/// Display for amount entry fields — same grouping as [formatMoneyDigits].
String formatAmountInput(int amountVnd) => formatMoneyDigits(amountVnd);

/// Parse digits from legacy text controllers or pasted input.
int parseAmountDigits(String text) {
  final raw = text.replaceAll(RegExp(r"[^\d]"), "");
  if (raw.isEmpty) return 0;
  final parsed = int.tryParse(raw) ?? 0;
  return parsed.clamp(0, kMaxAmountVnd);
}

/// Holds raw VND integer; notifies when the user edits via [AmountKeypad].
class AmountInputController extends ChangeNotifier {
  AmountInputController([int initial = 0]) : _value = _clamp(initial);

  int _value;

  int get value => _value;

  String get displayText => formatAmountInput(_value);

  /// Legacy text for dirty snapshots that stored controller text.
  String get rawDigits => _value == 0 ? "" : _value.toString();

  void setValue(int amountVnd) {
    final next = _clamp(amountVnd);
    if (_value == next) return;
    _value = next;
    notifyListeners();
  }

  void appendDigit(int digit) {
    if (digit < 0 || digit > 9) return;
    if (_value > kMaxAmountVnd ~/ 10) return;
    _value = _value * 10 + digit;
    notifyListeners();
  }

  void appendTripleZero() {
    if (_value == 0) return;
    final next = _value * 1000;
    _value = next > kMaxAmountVnd ? kMaxAmountVnd : next;
    notifyListeners();
  }

  void backspace() {
    _value = _value ~/ 10;
    notifyListeners();
  }

  void clear() => setValue(0);

  static int _clamp(int v) => v.clamp(0, kMaxAmountVnd);
}
