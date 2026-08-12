// Pattern 053: IpWhitelist
// IP ホワイトリスト確認 (擬似実装)。

class Pattern053Result {
  const Pattern053Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern053Result.fromJson(Map<String, dynamic> json) =>
      Pattern053Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern053Result(message: $message)';
}
