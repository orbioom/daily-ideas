# Reckon — quiet invoices

A single-file invoice maker for freelancers and small studios. Fill in your
details, add line items, and download a clean PDF via the browser's print
dialog. Everything is stored in `localStorage` — **nothing is ever uploaded**,
no account, no subscription, no network calls.

## Why I'd open it Tuesday at 2pm

End-of-month invoicing is a recurring chore, and most tools want a login and a
monthly fee to produce one PDF. Reckon is the calm middle ground: open the page,
your last invoice is exactly where you left it, change the number and the line
items, hit **Download PDF**. The on-page document *is* the printed document —
the editor panel and buttons simply vanish in print, leaving a typeset invoice.

## Features

- Live two-up editor + true-to-print preview (the preview is the PDF)
- Editable line items with qty × rate, running amounts, tax % and discount
- Currency switch ($ £ € ¥), issue/due dates, notes / payment terms
- Auto-saved to your device; **New** clears it
- Orbioom Liquid-Glass UI, Manrope + JetBrains Mono

## Run it

Open `index.html` in any modern browser. To get a PDF: **Download PDF** →
choose "Save as PDF" as the destination.

No build step, no dependencies (fonts load from Google Fonts; works offline with
system fallbacks).
