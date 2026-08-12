// Pattern 172: MultipartUpload
// Multipart Form Data 形式アップロード。

class Pattern172Result {
  const Pattern172Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern172Result.fromJson(Map<String, dynamic> json) =>
      Pattern172Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern172Result(message: $message)';
}
