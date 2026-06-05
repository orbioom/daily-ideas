# Polyphonic Text

Prose rendered as a musical score — each sentence a phrase, each word a note, pitch determined by
word length, rhythm by sentence complexity.

## The Idea

Every piece of writing has a hidden musical structure: the rhythm of short and long words, the
rests of punctuation, the rising pitch of a question, the accent of an exclamation. Polyphonic Text
makes that structure audible and visible.

Each sentence is rendered as a horizontal staff. Words become note bars:
- **Height** (pitch) = word length (longer words = higher pitch)
- **Width** (duration) = word length (longer words = longer notes)
- **Color**: statements are dark ink, questions end with a rising green note, exclamations get gold accents
- **Rests**: punctuation creates vertical tick marks (rests)

Click **play text** to hear the piece played as sine-wave tones through the Web Audio API.

## How to Run

Open `index.html` in any browser. No install required.

1. Paste any prose into the sidebar textarea
2. Click **Render score** to visualize
3. Click **play text** to hear it

**Note:** The Web Audio API requires a user gesture before playback. Click **play text** directly.

## Why It's Interesting

This reveals writing rhythm in a completely new register. Hemingway's short declarative sentences
produce a staccato score with narrow, evenly-spaced bars. Faulkner's flowing compound sentences
produce a dense, varied score with sweeping long notes. Poetry scans differently than prose.

Writers can use this as a revision tool: if the score looks monotonous (all the same bar width),
vary sentence length. If it looks jagged and chaotic, look for rhythm.

## Technical Notes

- **Web Audio API**: OscillatorNode → GainNode → destination. Sine waves for statements,
  triangle waves for questions. ADSR envelope with fast attack, exponential decay.
- **Canvas 2D**: one canvas per sentence, redrawn on resize. Playhead highlight via
  setTimeout-scheduled redraws synchronized with audio scheduler time.
- **No external dependencies**: vanilla JS, no libraries.

## Orbioom Feeling

Mist background, glass panels for each sentence measure. The score lives inside Liquid Glass cards.
Playing state uses the live green accent sparingly: only the currently-playing note and the question
cadence. The sidebar uses raised glass. Dark, musical, quiet.
