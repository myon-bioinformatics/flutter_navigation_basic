// Pattern 152: GetxObservable
// Rx 変数による Observable 状態管理。

class Pattern152Result {
  const Pattern152Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern152Result.fromJson(Map<String, dynamic> json) =>
      Pattern152Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern152Result(message: $message)';
}
