---
name: highway-client-facing-styleguide
description: Enforces the Highway client-facing style guide — the support chatbot's reserved corner, approved footer patterns, fixed-UI offsets, and viewport-height discipline. Use when building or reviewing UI on any client-facing Highway property (bridge, website, onboarding, dashboard). Use when a change touches footers, fixed or sticky overlays, toasts, banners, the chatbot embed, or 100dvh/100vh layout math.
---

# Highway Client-Facing Style Guide

## Overview

Every client-facing Highway property (bridge `hway-compose`, website `highway.space`,
onboarding `highwayonboarding.com`, dashboard `hway-fe`) embeds the identical hosted
ChatBotKit support widget: same bot id, `data-position="bottom-right"`, popover layout.
Its geometry is a constant we do not control:

- a **fixed 84 × 84 px frame** anchored at `right: 0; bottom: 0`, visible bubble inset
  ≈ 14 px from each edge;
- `z-index: 2147483647` — it always wins the stacking war; never layer page UI above it
  (keep page chrome at `z-50` or below);
- it floats over whatever the page renders in that corner.

This skill exists because the bridge once didn't follow it (HWAY-320): a thin footer bar
with `justify-between` pushed its links exactly under the launcher.

## When to Use

- Building or restyling a footer on any Highway property
- Adding any `fixed`/`sticky` bottom-layer UI: toasts, cookie/consent banners, FABs,
  "scroll to top" buttons
- Adding or moving the chatbot embed
- Writing `min-h`/`height` from `100dvh`/`100vh` arithmetic
- Reviewing a diff that touches any of the above

## The One Rule: the Reserved Corner

**The bottom-right 96 × 96 px of the viewport (6 rem) is a reserved zone.** No text,
links, buttons, or any interactive page content may render inside it — at any viewport
width, any window height, any locale.

96 px = the 84 px widget frame + breathing room, and it equals the offset the bridge's
toast stack already uses (`md:right-24`). One number to remember.

## Approved Footer Patterns

Pick one; each is live on a Highway property today:

| Pattern | Live example | Notes |
|---|---|---|
| **A — No footer** | Dashboard (`hway-fe`) | Legal & help links live in the user menu (Terms & Privacy, Help & Support) |
| **B — Single muted line** | Onboarding | One short left-anchored text row (`mt-16 text-xs text-muted`); no links pinned right |
| **C — Tall columnar footer** | Website | Logo + copyright anchored left, link columns above the bottom edge; the corner stays empty |
| **D — Thin utility bar with a reserved right edge** | Bridge (target) | Either group all content left, or keep `justify-between` and add `md:pr-24` to the content row |

**Not approved:** a thin bar whose right-aligned content runs to the container edge
(`justify-between` with no reservation) — that is the HWAY-320 collision.

## All Fixed Bottom-Layer UI

- **Toasts / snackbars:** offset the stack left of the zone (`fixed bottom-6 … md:right-24`,
  as in the bridge's ToastProvider). Centered stacks on mobile are fine.
- **Cookie / consent banners:** full-width bottom banners pad their content-end by
  ≥ 96 px, or sit entirely above the zone.
- **FABs / "scroll to top":** bottom-left, or ≥ 96 px above the bottom edge on the right.
  Never a second bubble in the same corner.
- **Modals & sheets:** full-screen overlays may cover the corner (the widget stays on
  top anyway); anchored panels should avoid it.

## Viewport-Height Discipline

A wrong chrome budget in `calc(100dvh − X)` gives every window a permanent phantom
scrollbar (HWAY-320's second bug: `13rem` budgeted vs `14rem + 1px` measured — borders
add height on auto-sized elements).

- Prefer **flex-fill** (`flex-1` on the growing region) over `100dvh`/`100vh` arithmetic.
- If a `calc(100dvh − X)` is unavoidable, derive the subtrahend in a code comment next
  to it (nav + paddings + footer, borders included).
- Acceptance: `document.documentElement.scrollHeight === clientHeight` at 1440×900,
  1280×800, and one mobile size, on a page whose content fits.

## Canonical Widget Embed

One snippet, one bot id, one position — copy verbatim, change only the placeholder copy:

```html
<script
  id="chatbotkit-widget"
  src="https://static.chatbotkit.com/integrations/widget/v2.js"
  data-widget="cmok9bxv8000x08jg9toqewd9"
  data-position="bottom-right"
  data-layout="popover"
  data-open="false"
  data-placeholder="Ask about Highway…"
></script>
```

## Review Guidance (for code reviewers)

When reviewing a diff that touches the surfaces above, categorize violations:

- **Critical** — interactive content (links, buttons) inside the reserved corner; page
  UI layered above the widget; a second floating launcher in the corner.
- **Important** — non-interactive content in the corner; a bottom banner/toast without
  the ≥ 96 px reservation; `100dvh` arithmetic without a derivation comment.
- **Suggestion** — footer pattern drift (e.g. new one-off footer style instead of
  patterns A–D).

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The widget loads async — the corner is usually empty" | It loads on every production visit; headless tests just don't show it. Design for it present. |
| "It fits on my screen" | The zone must hold at every width, height, zoom, and locale — German/Italian strings wrap differently. |
| "We can z-index above the chatbot just this once" | Its z-index is 2147483647. You can't win, and covering support entry points is a product bug. |
| "The dvh calc works on my monitor" | A 1 px budget error is a permanent scrollbar on *every* monitor. Derive it or use flex-fill. |

## Red Flags

- `justify-between` on a footer row whose container reaches the viewport edge
- A new `fixed bottom-* right-*` element with an offset < 96 px
- `calc(100dvh-…)` with a bare magic number and no derivation comment
- A modified chatbot embed snippet (different position, layout, or bot id per property)

## Verification

For any change touching these surfaces, check at 375, 800, 1280, 1440, and 1920 px wide:

- [ ] Nothing renders inside the bottom-right 96 × 96 px zone (test the longest locale)
- [ ] No page scrollbar when content fits the viewport (scrollHeight === clientHeight)
- [ ] Toasts, banners, and FABs clear the zone
- [ ] The launcher opens and its popover is not overlapped by page chrome
