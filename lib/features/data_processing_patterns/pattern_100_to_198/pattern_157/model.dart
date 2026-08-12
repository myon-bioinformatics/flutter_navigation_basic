// Pattern 157: ProviderBasic
// Provider パターンによる状態管理 (擬似実装)。

class Pattern157Result {
  const Pattern157Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern157Result.fromJson(Map<String, dynamic> json) =>
      Pattern157Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern157Result(message: $message)';
}
