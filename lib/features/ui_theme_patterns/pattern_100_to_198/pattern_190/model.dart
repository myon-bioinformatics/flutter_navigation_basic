// Pattern 190: AccessibilityInspect
// アクセシビリティ検査ツール表示 (擬似)。

class Pattern190Result {
  const Pattern190Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern190Result.fromJson(Map<String, dynamic> json) =>
      Pattern190Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern190Result(message: $message)';
}
