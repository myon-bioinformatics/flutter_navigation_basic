import { workerBudget } from './browser_execution.mjs';

// Flutter's software-rendered five-engine/video lane needs more headroom than
// the light published-page observation lane. Keep generic budgeting upstream.
export function flutterWorkerBudget({
  light = process.env.FLUTTER_WEB_LIGHT === '1',
  override = process.env.FLUTTER_WEB_WORKERS,
  ...resources
} = {}) {
  const budget = workerBudget({ ...resources, override });
  return override !== undefined || light ? budget : Math.min(2, budget);
}
