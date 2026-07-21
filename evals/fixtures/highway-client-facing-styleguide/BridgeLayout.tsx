import { type ReactNode } from 'react';

// Bridge app shell. The support chatbot launcher is mounted into the
// bottom-right corner at runtime (see conventions.md) — it is not part of this
// tree, but its reserved zone must be respected by any fixed or floating chrome
// added to the app.
export function BridgeLayout({ children }: { children: ReactNode }) {
  return (
    <div className="bridge-shell">
      <main className="bridge-main">{children}</main>
      <footer className="bridge-footer">
        <a href="/terms">Terms</a>
        <a href="/privacy">Privacy</a>
        <span>© Highway</span>
      </footer>
    </div>
  );
}
