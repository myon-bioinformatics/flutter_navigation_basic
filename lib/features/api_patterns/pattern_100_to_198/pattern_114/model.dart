// Pattern 114: MessagePack
// MessagePack バイナリ形式 (擬似実装)。

class Pattern114Result {
  const Pattern114Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern114Result.fromJson(Map<String, dynamic> json) =>
      Pattern114Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern114Result(message: $message)';
}
