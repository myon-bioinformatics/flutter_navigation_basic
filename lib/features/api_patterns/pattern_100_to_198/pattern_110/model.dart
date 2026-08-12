// Pattern 110: CsvWrite
// Dart データを CSV 形式に変換。

class Pattern110Result {
  const Pattern110Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern110Result.fromJson(Map<String, dynamic> json) =>
      Pattern110Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern110Result(message: $message)';
}
