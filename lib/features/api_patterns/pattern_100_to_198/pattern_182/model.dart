// Pattern 182: FilePreview
// アップロード前のプレビュー表示。

class Pattern182Result {
  const Pattern182Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern182Result.fromJson(Map<String, dynamic> json) =>
      Pattern182Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern182Result(message: $message)';
}
