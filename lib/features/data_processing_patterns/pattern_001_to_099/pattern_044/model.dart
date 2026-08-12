// Pattern 044: BidirectionalScroll
// 双方向無限スクロール実装。

class Pattern044Result {
  const Pattern044Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern044Result.fromJson(Map<String, dynamic> json) =>
      Pattern044Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern044Result(message: $message)';
}
