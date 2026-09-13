# Photo Studio manual fixtures

Geometry fixtures for PR #62 manual QA (not registered in pubspec / not in production web bundle).

| File | Size | Use |
| --- | --- | --- |
| `test_1_vertical_markers.png` | 1080×1920 | Move/Resize/Frame alignment |
| `test_2_horizontal_color_lines.jpg` | 1920×1080 | Decode load + moiré / AA |
| `test_3_transparent_shapes.png` | 1024×1024 | Alpha stamp overlay + PNG export |

Import into a simulator/device library for manual checks. Automated tests use tiny deterministic bytes instead.
