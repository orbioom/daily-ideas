Keystone — assets

Keystone ships with no external font files and makes zero network requests.
Typography uses a self-contained system font stack defined in styles.css:

  UI text:  "Manrope", system-ui, -apple-system, "Segoe UI", Roboto, sans-serif
  Numbers:  "JetBrains Mono", ui-monospace, "SF Mono", "Roboto Mono", monospace

If Manrope / JetBrains Mono are installed on the viewer's system they are used;
otherwise the app falls back gracefully to the platform's native UI and mono
fonts. This keeps Keystone fully offline and key-free — just open index.html.

This folder is reserved for future self-hosted assets (e.g. bundled .woff2
fonts) without changing the markup.
