import 'dart:convert';
import 'dart:io';

void main() {
  final input = jsonDecode(stdin.readLineSync()!) as Map<String, dynamic>;
  Object? result;
  switch (input['operation']) {
    case 'array_length':
      result = {'length': List<int>.filled(input['count'] as int, 0).length};
    case 'bounds':
      result = {'value': <int>[1][input['index'] as int]};
    case 'null_assert':
      final Object? value = input['value'];
      result = {'value': value!.toString()};
    case 'bad_cast':
      result = {'value': input['value'] as int};
    case 'invalid_integer':
      result = {'value': int.parse(input['value'] as String)};
    case 'invalid_json':
      result = {'value': jsonDecode(input['value'] as String)};
    case 'divide_zero':
      result = {'value': 1 ~/ (input['value'] as int)};
    default:
      throw ArgumentError('unsupported operation');
  }
  print(jsonEncode(result));
}
