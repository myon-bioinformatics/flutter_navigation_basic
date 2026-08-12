// Pattern 011: CheckBox
// Checkbox スタイルと状態管理。

class Pattern011Result {
  const Pattern011Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern011Result.fromJson(Map<String, dynamic> json) =>
      Pattern011Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern011Result(message: $message)';
}
