// Pattern 137: SidePanelNav
// サイドパネル専用 Navigator。

class Pattern137Result {
  const Pattern137Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern137Result.fromJson(Map<String, dynamic> json) =>
      Pattern137Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern137Result(message: $message)';
}
