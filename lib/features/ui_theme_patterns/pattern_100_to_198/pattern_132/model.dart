// Pattern 132: TabletLayout
// タブレット向けマスター/詳細レイアウト。

class Pattern132Result {
  const Pattern132Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern132Result.fromJson(Map<String, dynamic> json) =>
      Pattern132Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern132Result(message: $message)';
}
