// Pattern 085: DataCompression
// データ圧縮 (gzip 相当、擬似実装)。

class Pattern085Result {
  const Pattern085Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern085Result.fromJson(Map<String, dynamic> json) =>
      Pattern085Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern085Result(message: $message)';
}
