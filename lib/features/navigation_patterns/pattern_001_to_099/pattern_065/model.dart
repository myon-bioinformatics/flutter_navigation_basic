// Pattern 065: BottomNavCustom
// カスタムデザインの BottomNavBar。

class Pattern065Result {
  const Pattern065Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern065Result.fromJson(Map<String, dynamic> json) =>
      Pattern065Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern065Result(message: $message)';
}
