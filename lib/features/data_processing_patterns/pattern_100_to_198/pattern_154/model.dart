// Pattern 154: GetxBinding
// Bindings による DI と状態管理。

class Pattern154Result {
  const Pattern154Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern154Result.fromJson(Map<String, dynamic> json) =>
      Pattern154Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern154Result(message: $message)';
}
