// Pattern 030: TimePickerM3
// M3 タイムピッカーの実装。

class Pattern030Result {
  const Pattern030Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern030Result.fromJson(Map<String, dynamic> json) =>
      Pattern030Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern030Result(message: $message)';
}
