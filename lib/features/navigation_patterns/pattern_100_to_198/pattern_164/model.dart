// Pattern 164: BottomSheetBasic
// 基本的な BottomSheet 実装。

class Pattern164Result {
  const Pattern164Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern164Result.fromJson(Map<String, dynamic> json) =>
      Pattern164Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern164Result(message: $message)';
}
