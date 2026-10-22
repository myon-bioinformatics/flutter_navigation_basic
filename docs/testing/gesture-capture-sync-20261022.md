# Mobile WebKit gesture capture follow-up (#183)

## Scope and finding

This is a capture-harness fix for `/screen171` and `/screen173`, not an app
repaint fix or a claim about physical iOS touch input. Keep
[#183](https://github.com/myon-bioinformatics/flutter_navigation_basic/issues/183#issuecomment-6311487189)
open. Application code, gestures, scrolling assertions, and Photo Studio's dirty
navigation guard are unchanged.

The discrepancy was reproduced with Playwright 1.64.1 / WebKit 27.2, iPhone 13
emulation at 390 × 320 CSS pixels, against deployed source
`571d898077c64f9b3c0a713f3298797a01b29b67`. Both screens reported `順序: B, A, C`
in semantics while their PNGs retained the earlier order or drag feedback.
Repeated 650 ms / two-frame waits and repeated screenshots did not correct
that discrepancy. The stale images could be byte-identical, so stable hashes
alone are not a paint oracle. A real mouse move after release, to the empty
page corner, made the final card order visible without changing app state.

This observation does **not** establish whether the original mouseup-only
staleness originates in the Flutter renderer or WebKit's emulation/compositor.
It is retained as a limitation, not silently declared fixed.

## Evidence contract

Only the two affected mobile-WebKit cases add the following to the existing
`flutter-chrome-audit/1` receipt and ordinary Playwright artifacts:

1. Save the pre-drag short-viewport PNG and the two original card rectangles.
2. Perform the existing mouse drag, including the 700 ms long press for 173,
   and assert the semantic result. Save the ordinary, possibly stale
   `exception-short-after-release.png` before any additional input.
3. Record and send a released `mouse-move` to `(0, 0)`. The receipt explicitly
   calls this `post-release-paint-synchronization`, not a native touch gesture.
4. Require two identical final PNGs **and** exact pixel permutation: the first
   card interior equals the pre-drag second card, and vice versa. Both
   references must be distinct. The existing locked image backend performs
   comparison on the actual saved PNG, with no tolerance or baseline update.

`python/gesture_paint.py` is a saved-evidence oracle, not another browser runner.
The eight-pixel inset removes card shadows/edges but includes their labels and
contents. The narrow mobile-WebKit oracle uses its recorded DPR=3; it does not
assume identical pixel phase on every device profile. Other projects retain
their existing assertions. The final verified after-action PNG is distinguished
from the later scroll PNG; the latter is not independently pixel-certified by
this permutation check.

Reproduction through the existing CLI (an existing URL tests deployed bytes,
not unbuilt local app changes):

```sh
FLUTTER_WEB_BASE_URL=https://myon-bioinformatics.github.io/flutter_navigation_basic/ \
FLUTTER_WEB_LIGHT=1 python python/playwright.py test --project mobile-webkit \
  --grep '/screen(171|173) ' tests/exceptional_chrome.spec.ts
```

The saved-pixel oracle rejected the actual stale images from both fresh
reproductions, including subsequent identical captures, and accepted the
post-move results with zero changed pixels in both card interiors. The two
patched browser cases passed locally. Full exact-head CI results belong in the
PR/run evidence and must not be inferred from these two local passes.

## Remaining separate finding

After the grid swap, one fresh WebKit observation exposed two
`interaction-item-B` identifiers, with texts `B` and `A`, instead of an A/B pair.
The capture oracle deliberately measures fixed pre-drag slots rather than
claiming those identifiers are repaired. Investigate keyed grid child/semantics
identity separately before asserting repeated A-targeted grid gestures work.
