// Pattern 193: PinchZoom
// ピンチズームジェスチャー実装。

class Pattern193Result {
  const Pattern193Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern193Result.fromJson(Map<String, dynamic> json) =>
      Pattern193Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern193Result(message: $message)';
}
