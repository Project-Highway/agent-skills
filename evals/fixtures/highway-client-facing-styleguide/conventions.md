# Highway client-facing layout conventions

- The support chatbot launcher occupies a reserved **96×96px zone in the
  bottom-right corner** of every client-facing surface (bridge, website,
  onboarding, dashboard).
- Any fixed or floating chrome (buttons, toasts, banners) must not land in that
  zone. Offset it by at least 96px, or dock it elsewhere — never straddle the
  corner.
- Footers are static and full-width; they must not overlap the launcher zone.
- Verify placement at multiple viewport widths (narrow phones through wide
  desktops), not a single screen.
- Use `100dvh`, not `100vh`, for full-height math so mobile browser chrome does
  not clip fixed elements.

The bridge app currently mounts the chatbot launcher bottom-right and renders a
static footer (see `BridgeLayout.tsx`). New floating controls have to coexist
with both.
