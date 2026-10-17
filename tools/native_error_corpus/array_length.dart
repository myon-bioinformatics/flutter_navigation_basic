import 'dart:convert';
import 'dart:io';

void main() {
  final input = jsonDecode(stdin.readLineSync()!) as Map<String, dynamic>;
  final items = List<int>.filled(input['count'] as int, 0);
  print(jsonEncode({'length': items.length}));
}
