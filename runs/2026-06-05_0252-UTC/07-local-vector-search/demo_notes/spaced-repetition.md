# Spaced Repetition

Spaced repetition is a learning technique that schedules review of material at increasing intervals,
exploiting the psychological spacing effect to maximize long-term retention with minimum study time.

## The Forgetting Curve

Hermann Ebbinghaus showed in 1885 that memory decays exponentially after learning. A new fact is
forgotten rapidly within the first day, then more slowly afterward. Each review resets the curve
and extends the interval before the next review is needed.

## Algorithms

**SM-2** (SuperMemo 2): the original algorithm, still used in Anki. Calculates the next review
interval based on a difficulty grade (0–5) given by the learner.

**FSRS** (Free Spaced Repetition Scheduler): modern algorithm using a differential equation model
of memory. More accurate than SM-2, especially for difficult material.

## Applications Beyond Flashcards

Spaced repetition is typically applied to vocabulary and factual recall, but the underlying
principle applies to any practiced skill: music, language speaking, mathematical procedures, design patterns.

The key insight is that **optimal forgetting** — letting material decay to near-forgotten before
reviewing — produces stronger memories than constant repetition.
