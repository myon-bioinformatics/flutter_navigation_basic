import { createHash } from 'node:crypto';

// Stateless choices are independent of worker scheduling, test ordering/retries.
export function choice(seed, route, step, count) {
  if (!Number.isInteger(count) || count < 1) throw new Error('No exploration choices');
  return createHash('sha256').update(JSON.stringify([seed, route, step])).digest().readUInt32BE(0) % count;
}
