import { readFileSync } from 'node:fs';

const { count } = JSON.parse(readFileSync(0, 'utf8'));
const items = new Array(count).fill(0);
process.stdout.write(JSON.stringify({ length: items.length }) + '\n');
