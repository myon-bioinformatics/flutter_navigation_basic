// Pattern 031: PaginationBasic
// オフセット方式のページネーション。

class Pattern031Result {
  const Pattern031Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern031Result.fromJson(Map<String, dynamic> json) =>
      Pattern031Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern031Result(message: $message)';
}
