// Pattern 174: UploadProgress
// アップロード進捗表示実装。

class Pattern174Result {
  const Pattern174Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern174Result.fromJson(Map<String, dynamic> json) =>
      Pattern174Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern174Result(message: $message)';
}
