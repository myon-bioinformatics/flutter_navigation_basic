// Pattern 151: PlatformView
// PlatformView によるネイティブ UI 埋め込み (擬似)。

class Pattern151Result {
  const Pattern151Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern151Result.fromJson(Map<String, dynamic> json) =>
      Pattern151Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern151Result(message: $message)';
}
