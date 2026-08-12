// Pattern 057: CertPin
// 証明書ピニング (擬似実装)。

class Pattern057Result {
  const Pattern057Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern057Result.fromJson(Map<String, dynamic> json) =>
      Pattern057Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern057Result(message: $message)';
}
