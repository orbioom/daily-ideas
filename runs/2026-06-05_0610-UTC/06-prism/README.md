# Prism — see your CSV

Drop a CSV and get a clean chart in one second. Prism parses the file in the
browser, detects which columns are numeric vs. categorical, picks sensible
defaults, and draws a bar / line / scatter / histogram on a crisp canvas — then
lets you **Save PNG**. No upload, no account, no spreadsheet gymnastics.

## Why I'd open it Tuesday at 2pm

You export a CSV from somewhere — a query result, an analytics dashboard, a
sensor log — and you just want to *look at it*. Opening a spreadsheet, selecting
ranges, and fighting the chart wizard is friction. Prism is the fast path:
drag the file in, the first useful chart is already on screen, change the axis
or the chart type, save the picture, done.

## Features

- Robust CSV parser (quoted fields, embedded commas, escaped quotes, CRLF)
- Automatic column **type inference** (numeric vs categorical)
- Four chart types: **bar, line, scatter, histogram**
- Aggregation for bar/line: **sum / average / count** grouped by a category
- Auto-binned histogram for any numeric column
- High-resolution canvas export to **PNG**
- Orbioom Liquid-Glass UI; a sample sales dataset is preloaded

## Run it

Open `index.html`. Use **Load sample**, paste CSV, drag a `.csv` onto the drop
zone, or click to choose a file. Everything runs locally.

No build step, no dependencies.
