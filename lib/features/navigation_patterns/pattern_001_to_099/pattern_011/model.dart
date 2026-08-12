// Pattern 011: WillPopScope
// WillPopScope で遷移キャンセルを制御。

class Pattern011Result {
  const Pattern011Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern011Result.fromJson(Map<String, dynamic> json) =>
      Pattern011Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern011Result(message: $message)';
}
