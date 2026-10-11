// Dependency-free TypeScript execution proof; no network/filesystem permissions.
type Row = readonly [string, string];
const rows: Row[] = [['tag', 'a'], ['tag', 'b'], ['label', '猫']];
const params = new URLSearchParams(rows.map(([key, value]) => [key, value]));
if (params.getAll('tag').join(',') !== 'a,b' || params.get('label') !== '猫') {
  throw new Error('TypeScript/Web API toolchain smoke failed');
}
console.log(JSON.stringify({schema: 'toolchain-smoke/1', typescript: true, rows: rows.length}));
