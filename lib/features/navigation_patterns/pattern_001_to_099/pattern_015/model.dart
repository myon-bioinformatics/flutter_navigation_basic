// Pattern 015: TabBarView
// TabController + TabBarView による横スクロールタブ。

class Pattern015Result {
  const Pattern015Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern015Result.fromJson(Map<String, dynamic> json) =>
      Pattern015Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern015Result(message: $message)';
}
