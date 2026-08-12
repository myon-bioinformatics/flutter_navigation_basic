// Pattern 184: DragReorder
// 長押し+ドラッグによる並び替え。

class Pattern184Result {
  const Pattern184Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern184Result.fromJson(Map<String, dynamic> json) =>
      Pattern184Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern184Result(message: $message)';
}
