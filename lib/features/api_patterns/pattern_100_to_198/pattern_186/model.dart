// Pattern 186: BatchDownload
// 複数ファイルの一括ダウンロード。

class Pattern186Result {
  const Pattern186Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern186Result.fromJson(Map<String, dynamic> json) =>
      Pattern186Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern186Result(message: $message)';
}
