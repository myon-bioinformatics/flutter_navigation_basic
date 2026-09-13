# Photo Studio manual fixtures

Programmatically generated geometry fixtures for PR #62 manual checks.

| File | Size | Use |
| --- | --- | --- |
| `test_1_vertical_markers.png` | 1080×1920 | Portrait layout, Move/Resize/Frame alignment (10px border, 100px grid, center cross, corner color markers). |
| `test_2_horizontal_color_lines.jpg` | 1920×1080 | Decode load + anti-alias / moiré on concentric 1–2px rings over a blue→orange gradient. |
| `test_3_transparent_shapes.png` | 1024×1024 | Alpha: opaque orange donut + 50% purple square on a fully transparent background; verify stamp overlay and PNG export transparency. |

Import these into a simulator/device photo library or pick them on web during manual QA.
