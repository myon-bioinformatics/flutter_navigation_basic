// Pattern 179: BannerWidget
// MaterialBanner によるバナー表示。

class Pattern179Result {
  const Pattern179Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern179Result.fromJson(Map<String, dynamic> json) =>
      Pattern179Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern179Result(message: $message)';
}
