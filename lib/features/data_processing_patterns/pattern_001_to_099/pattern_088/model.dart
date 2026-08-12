// Pattern 088: SnapshotCache
// スナップショットキャッシュパターン。

class Pattern088Result {
  const Pattern088Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern088Result.fromJson(Map<String, dynamic> json) =>
      Pattern088Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern088Result(message: $message)';
}
