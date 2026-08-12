// Pattern 061: CustomThemeBasic
// ThemeData.copyWith によるテーマ拡張。

class Pattern061Result {
  const Pattern061Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern061Result.fromJson(Map<String, dynamic> json) =>
      Pattern061Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern061Result(message: $message)';
}
