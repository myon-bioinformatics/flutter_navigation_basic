// Pattern 164: DesktopIcon
// デスクトップアプリアイコン設定 (擬似)。

class Pattern164Result {
  const Pattern164Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern164Result.fromJson(Map<String, dynamic> json) =>
      Pattern164Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern164Result(message: $message)';
}
