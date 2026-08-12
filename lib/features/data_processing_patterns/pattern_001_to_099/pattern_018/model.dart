// Pattern 018: GeoFilter
// 位置情報による近距離フィルタリング (擬似)。

class Pattern018Result {
  const Pattern018Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern018Result.fromJson(Map<String, dynamic> json) =>
      Pattern018Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern018Result(message: $message)';
}
