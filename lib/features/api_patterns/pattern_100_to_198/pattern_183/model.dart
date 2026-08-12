// Pattern 183: DirectUpload
// 署名付き URL への直接アップロード。

class Pattern183Result {
  const Pattern183Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern183Result.fromJson(Map<String, dynamic> json) =>
      Pattern183Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern183Result(message: $message)';
}
