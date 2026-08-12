// Pattern 120: ThemeExport
// テーマ設定の JSON エクスポート/インポート。

class Pattern120Result {
  const Pattern120Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern120Result.fromJson(Map<String, dynamic> json) =>
      Pattern120Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern120Result(message: $message)';
}
