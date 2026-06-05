# Cadence — read your cron

A calm cron-expression workbench. Type any standard 5-field cron expression and
Cadence tells you — in plain English — what it means, then plots the **next
seven fire times** on a timeline with relative ("in 3d 4h") and gap annotations.

No "is this `0 0 * * 0` Sunday or Saturday?" guessing, no copy-pasting into a
shell to find out. It's the tool you reach for at 2pm when you're writing a
crontab or a CI schedule and want to be *sure*.

## Why it's solid

The cron engine is a real parser/scheduler, not a regex lookup table:

- `*`, lists `a,b`, ranges `a-b`, steps `*/n` and `a-b/n`
- named months (`jan`) and weekdays (`mon`)
- correct **OR semantics** when both day-of-month and day-of-week are
  restricted (matching Vixie cron)
- range validation with human error messages

It's tested against a battery of expressions (see `cron.js` — runnable under
Node) and the next-run search walks forward minute-by-minute with a one-year
guard, so it never lies about the schedule.

## Run it

Open `index.html`. Tap a preset chip or type your own. Everything runs in the
browser; nothing leaves the page.

## Files

| File | Role |
|---|---|
| `index.html` | UI: editor, plain-English description, timeline, next-runs list |
| `cron.js` | the cron parser + `nextN` scheduler + `describe` (also a Node module) |

Quick check under Node:

```bash
node -e 'const C=require("./cron.js");
console.log(C.describe("0 9 * * 1-5"));
console.log(C.nextN("0 9 * * 1-5",3,new Date()).map(String));'
```
