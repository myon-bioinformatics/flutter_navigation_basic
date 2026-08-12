// Pattern 052: CupertinoFullscreen
// CupertinoFullscreenDialogTransition。

class Pattern052Result {
  const Pattern052Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern052Result.fromJson(Map<String, dynamic> json) =>
      Pattern052Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern052Result(message: $message)';
}
