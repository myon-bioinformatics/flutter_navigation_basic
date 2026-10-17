import { readFileSync } from 'node:fs';
const request = JSON.parse(readFileSync(0, 'utf8'));
let result;
switch (request.operation ?? 'array_length') {
  case 'array_length': result = { length: new Array(request.count).fill(0).length }; break;
  case 'bounds': result = { value: new DataView(new ArrayBuffer(1)).getInt8(request.index) }; break;
  case 'null_assert': result = { value: request.value.toString() }; break;
  case 'bad_cast':
    if (!Number.isInteger(request.value)) throw new TypeError('integer cast requires an integer');
    result = { value: request.value }; break;
  case 'invalid_integer': result = { value: String(BigInt(request.value)) }; break;
  case 'invalid_json': result = { value: JSON.parse(request.value) }; break;
  case 'divide_zero': result = { value: String(1n / BigInt(request.value)) }; break;
  default: throw new Error('unsupported operation');
}
process.stdout.write(JSON.stringify(result) + '\n');
