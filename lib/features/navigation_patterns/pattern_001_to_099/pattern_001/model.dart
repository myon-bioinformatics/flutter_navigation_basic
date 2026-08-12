// Pattern 001: BasicPush
// 最も基本的な画面プッシュ遷移。Navigator.push/Get.to。

class Pattern001Result {
  const Pattern001Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern001Result.fromJson(Map<String, dynamic> json) =>
      Pattern001Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern001Result(message: $message)';
}
