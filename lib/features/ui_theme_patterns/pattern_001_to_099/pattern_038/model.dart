// Pattern 038: CupertinoPicker
// CupertinoPicker によるスクロール選択。

class Pattern038Result {
  const Pattern038Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern038Result.fromJson(Map<String, dynamic> json) =>
      Pattern038Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern038Result(message: $message)';
}
