import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/core/utils/amount_input.dart";

/// Riverpod state for amount keypad entry (family arg = initial VND).
class AmountInputNotifier extends Notifier<int> {
  AmountInputNotifier(this._initial);

  final int _initial;

  @override
  int build() => _clamp(_initial);

  String get displayText => formatAmountInput(state);

  String get rawDigits => state == 0 ? "" : state.toString();

  void setValue(int amountVnd) {
    final next = _clamp(amountVnd);
    if (state == next) return;
    state = next;
  }

  void appendDigit(int digit) {
    if (digit < 0 || digit > 9) return;
    if (state > kMaxAmountVnd ~/ 10) return;
    state = state * 10 + digit;
  }

  void appendTripleZero() {
    if (state == 0) return;
    final next = state * 1000;
    state = next > kMaxAmountVnd ? kMaxAmountVnd : next;
  }

  void backspace() {
    state = state ~/ 10;
  }

  void clear() => setValue(0);

  static int _clamp(int v) => v.clamp(0, kMaxAmountVnd);
}

final amountInputProvider = NotifierProvider.autoDispose
    .family<AmountInputNotifier, int, int>(AmountInputNotifier.new);
