// Pattern 012: SortCustom
// カスタムコンパレータによるソート。

class Pattern012Result {
  const Pattern012Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern012Result.fromJson(Map<String, dynamic> json) =>
      Pattern012Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern012Result(message: $message)';
}
