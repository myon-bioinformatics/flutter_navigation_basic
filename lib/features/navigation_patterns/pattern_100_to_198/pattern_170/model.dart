// Pattern 170: DropdownMenu
// DropdownMenu による選択 UI。

class Pattern170Result {
  const Pattern170Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern170Result.fromJson(Map<String, dynamic> json) =>
      Pattern170Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern170Result(message: $message)';
}
