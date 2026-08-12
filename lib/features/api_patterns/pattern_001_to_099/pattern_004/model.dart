// Pattern 004: HttpDelete
// リソース削除の DELETE リクエスト。

class Pattern004Result {
  const Pattern004Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern004Result.fromJson(Map<String, dynamic> json) =>
      Pattern004Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern004Result(message: $message)';
}
