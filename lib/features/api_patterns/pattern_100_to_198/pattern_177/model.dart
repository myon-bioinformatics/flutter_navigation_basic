// Pattern 177: DownloadProgress
// ダウンロード進捗表示実装。

class Pattern177Result {
  const Pattern177Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern177Result.fromJson(Map<String, dynamic> json) =>
      Pattern177Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern177Result(message: $message)';
}
